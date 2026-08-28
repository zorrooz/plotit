#' Layout transforms for relational graphs
#'
#' Layout transforms compute node coordinates from graph topology and bake
#' them into the graph tables (`x`/`y` on nodes; `x`, `y`, `xend`, `yend` on
#' edges).  They follow the Vega discipline: layouts are data transforms,
#' not layers -- positions are computed once and consumed by ordinary marks
#' through automatic geometry binding.
#'
#' Engines are idempotent: previously computed geometry columns are stripped
#' before each run, so chaining two layouts is equivalent to applying only
#' the last one.  Stochastic engines accept a `seed` for reproducibility.
#'
#' @include class.R graph.R
#' @name layout-internal
#' @noRd
#' @keywords internal
NULL

# Strip computed geometry so every engine recomputes purely from topology.
._graph_topology <- function(g) {
  drop <- function(df, cols) df[, setdiff(names(df), intersect(cols, names(df))), drop = FALSE]
  list(
    nodes = drop(g$nodes, c(
      "x", "y", "r", "xc", "yc",
      "xmin", "xmax", "ymin", "ymax"
    )),
    edges = drop(g$edges, c("x", "y", "xend", "yend"))
  )
}

# Fill edge x/y/xend/yend from node coordinates by id lookup.
._map_edge_coords <- function(nodes, edges) {
  x_of <- stats::setNames(nodes$x, nodes$id)
  y_of <- stats::setNames(nodes$y, nodes$id)
  edges$x <- unname(x_of[edges$source])
  edges$y <- unname(y_of[edges$source])
  edges$xend <- unname(x_of[edges$target])
  edges$yend <- unname(y_of[edges$target])
  edges
}

._new_graph_from_parts <- function(t, directed) {
  ._new_graph(list(nodes = t$nodes, edges = t$edges), directed = directed)
}

# ---- engines ---------------------------------------------------------------

# Shared children lookup for hierarchy engines: named list of child id
# vectors, ordered by the merge side when present (.side from hclust).
._hierarchy_children <- function(t) {
  edges <- t$edges
  if (nrow(edges) == 0) {
    return(list())
  }
  if (!".side" %in% names(edges)) {
    edges$.side <- seq_len(nrow(edges))
  }
  edges <- edges[order(edges$.side), , drop = FALSE]
  out <- split(edges$target, edges$source)
  out
}

._hierarchy_roots <- function(t) {
  setdiff(t$nodes$id, t$edges$target)
}

# Shared post-order walk for hierarchy engines: leaves are numbered
# strictly left-to-right across the whole forest (merge-side .side ordering
# decides which child is "left"), and every internal node sits at the mean
# leaf position of its children.  Used by layout_tree and
# layout_dendrogram so both share one ordering convention.
._hierarchy_leaf_x <- function(kids, roots, ids) {
  x_of <- stats::setNames(numeric(length(ids)), ids)
  counter <- 0
  for (rt in roots) {
    stack <- list(list(id = rt, phase = 0L))
    while (length(stack) > 0) {
      cur <- stack[[length(stack)]]
      stack[length(stack)] <- NULL
      if (cur$phase == 0L) {
        stack[[length(stack) + 1L]] <- list(id = cur$id, phase = 1L)
        kid_ids <- rev(kids[[cur$id]] %||% character(0))
        for (k in kid_ids) stack[[length(stack) + 1L]] <- list(id = k, phase = 0L)
      } else if (is.null(kids[[cur$id]])) {
        counter <- counter + 1L
        x_of[[cur$id]] <- as.numeric(counter)
      } else {
        x_of[[cur$id]] <- mean(x_of[kids[[cur$id]]])
      }
    }
  }
  x_of
}

# Depth of every node below its forest root.  Guards against cycles: a
# visited node reached again means parent/child edges do not form a tree.
._hierarchy_depths <- function(kids, roots, ids) {
  depth <- stats::setNames(numeric(length(ids)), ids)
  visited <- stats::setNames(logical(length(ids)), ids)
  for (rt in roots) {
    stack <- list(list(id = rt, d = 0))
    while (length(stack) > 0) {
      cur <- stack[[length(stack)]]
      stack[length(stack)] <- NULL
      if (visited[[cur$id]]) next
      visited[[cur$id]] <- TRUE
      depth[[cur$id]] <- cur$d
      for (k in kids[[cur$id]] %||% character(0)) {
        stack[[length(stack) + 1L]] <- list(id = k, d = cur$d + 1)
      }
    }
  }
  if (!all(visited[ids])) {
    ._abort_hint(
      "Tree layout found unreachable nodes.",
      "Edges must point parent -> child and must not contain cycles."
    )
  }
  depth
}

# ---- Fruchterman-Reingold force layout (self-contained) --------------------
#
# Classic FR (1991) relaxation on a unit canvas with linear cooling:
#   repulsion  : k^2 / d between every node pair
#   attraction : d^2 / k along every edge, optionally scaled by `weights`
#   movement   : per-iteration displacement capped by the temperature
# Nodes start on a circle with a tiny jitter so symmetric graphs still
# relax; runs sharing a seed are identical.

# Accumulate per-node force contributions by integer key (base R only;
# rowsum() sums duplicate group entries without Matrix dependencies).
._fr_accum <- function(values, idx, n) {
  agg <- rowsum(matrix(values, ncol = 1), group = idx, reorder = FALSE)
  out <- numeric(n)
  out[as.integer(rownames(agg))] <- agg[, 1]
  out
}

._fr_coords <- function(n, from, to, weights, iterations) {
  k <- 1 / sqrt(max(n, 1)) # ideal edge length on the unit canvas
  ang <- seq(0, 2 * pi, length.out = n + 1)[seq_len(n)]
  x <- cos(ang) * 0.4 + stats::runif(n, -0.01, 0.01)
  y <- sin(ang) * 0.4 + stats::runif(n, -0.01, 0.01)
  temp0 <- 0.1

  for (iter in seq_len(iterations)) {
    temp <- temp0 * (1 - iter / (iterations + 1))

    # Pairwise repulsion (vectorized n x n; no self-force via Inf diag).
    dx <- matrix(x, n, n) - matrix(x, n, n, byrow = TRUE)
    dy <- matrix(y, n, n) - matrix(y, n, n, byrow = TRUE)
    d <- sqrt(dx^2 + dy^2)
    diag(d) <- Inf
    f_rep <- ifelse(d > 0, (k * k) / d, 0)
    fx <- rowSums(dx / d * f_rep, na.rm = TRUE)
    fy <- rowSums(dy / d * f_rep, na.rm = TRUE)

    # Edge attraction in both directions.
    if (length(from) > 0) {
      de <- sqrt((x[from] - x[to])^2 + (y[from] - y[to])^2)
      de <- pmax(de, 1e-9)
      fa <- de^2 / k * weights
      ex <- (x[from] - x[to]) / de
      ey <- (y[from] - y[to]) / de
      both <- c(from, to)
      fx <- fx + ._fr_accum(c(ex * fa, -ex * fa), both, n)
      fy <- fy + ._fr_accum(c(ey * fa, -ey * fa), both, n)
    }

    # Cap displacement by the cooling temperature.
    disp <- sqrt(fx^2 + fy^2)
    scale <- pmin(disp, temp) / pmax(disp, 1e-12)
    x <- x + fx * scale
    y <- y + fy * scale
  }
  list(x = x, y = y)
}

#' @noRd
#' @keywords internal
._layout_engine_force <- function(g, iterations = 500, seed = NULL, ...) {
  t <- ._graph_topology(g)
  directed <- isTRUE(attr(g, "directed"))
  n <- nrow(t$nodes)
  if (n == 0) {
    ._abort_hint(
      "Force layout requires at least one node.",
      "Start from an edge table with at least one row."
    )
  }
  iterations <- floor(iterations)
  if (iterations < 1) {
    ._abort_arg_range("iterations", ">= 1", got = iterations)
  }

  dots <- rlang::list2(...)
  unknown <- setdiff(names(dots), "weights")
  if (length(unknown) > 0) {
    cli::cli_warn(c(
      "{.fn layout_force} ignores unknown arguments: {.val {unknown}}.",
      "i" = "The self-contained Fruchterman-Reingold engine accepts \\
             {.arg weights} only."
    ))
  }
  weights <- suppressWarnings(as.numeric(dots$weights %||% rep(1, nrow(t$edges))))
  if (length(weights) != nrow(t$edges) || anyNA(weights) || any(weights < 0)) {
    ._abort_arg_range(
      "weights", "finite non-negative values, one per edge",
      got = weights
    )
  }

  # Self-loops carry no attraction in an undirected relaxation.
  keep <- t$edges$source != t$edges$target
  from <- match(t$edges$source[keep], t$nodes$id)
  to <- match(t$edges$target[keep], t$nodes$id)

  # Seed locally: save and restore the global RNG state so a reproducible
  # layout does not perturb the caller's random stream.
  if (!is.null(seed)) {
    if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
      old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
      on.exit(assign(".Random.seed", old_seed, envir = .GlobalEnv), add = TRUE)
    } else {
      on.exit(rm(".Random.seed", envir = .GlobalEnv), add = TRUE)
    }
    set.seed(seed)
  }

  coords <- ._fr_coords(n, from, to, weights[keep], iterations)
  # Rescale into [0.05, 0.95]^2, aspect preserved: the layout owns a 10%
  # canvas margin so node radii and labels stay inside the panel
  # (B5, design/03 <U+00A7>5.4).
  xr <- range(coords$x)
  yr <- range(coords$y)
  span <- max(diff(xr), diff(yr), 1e-9)
  t$nodes$x <- 0.5 + 0.9 * (coords$x - mean(xr)) / span
  t$nodes$y <- 0.5 + 0.9 * (coords$y - mean(yr)) / span
  t$edges <- ._map_edge_coords(t$nodes, t$edges)
  ._new_graph_from_parts(t, directed)
}

#' @noRd
#' @keywords internal
._layout_engine_circle <- function(g, order_by = c("id", "degree")) {
  t <- ._graph_topology(g)
  directed <- isTRUE(attr(g, "directed"))
  order_by <- match.arg(order_by)
  n <- nrow(t$nodes)
  if (n == 0) {
    ._abort_hint(
      "Circle layout requires at least one node.",
      "Start from an edge table with at least one row."
    )
  }
  if (order_by == "degree") {
    deg <- table(c(t$edges$source, t$edges$target))
    d <- as.numeric(deg[t$nodes$id])
    d[is.na(d)] <- 0
    t$nodes <- t$nodes[order(-d), , drop = FALSE]
  }
  angle <- (seq_len(n) - 1) / n * 2 * pi # start at top, clockwise
  t$nodes$x <- sin(angle)
  t$nodes$y <- cos(angle)
  t$edges <- ._map_edge_coords(t$nodes, t$edges)
  ._new_graph_from_parts(t, directed)
}

#' @noRd
#' @keywords internal
._layout_engine_tree <- function(g, direction = c("down", "up", "left", "right"),
                                 leaf_spacing = c("count", "equal"),
                                 edge = c("straight", "elbow")) {
  direction <- match.arg(direction)
  leaf_spacing <- match.arg(leaf_spacing)
  edge <- match.arg(edge)
  t <- ._graph_topology(g)
  if (nrow(t$edges) == 0) {
    ._abort_hint(
      "Tree layout requires at least one edge.",
      "Start from an edge table with at least one row."
    )
  }
  roots <- ._hierarchy_roots(t)
  if (length(roots) == 0) {
    cli::cli_abort(
      c("Tree layout found no root: the graph contains a cycle.",
        "i" = "Edges must point from parent to child."
      )
    )
  }
  kids <- ._hierarchy_children(t)
  # Raw layout: x spreads leaves left-to-right, y is depth from the root
  # (root at 0).  Direction names describe where the tree grows; the root
  # sits opposite.  leaf_spacing = "count" packs leaves one unit apart in
  # traversal order (d3 tidy-tree); "equal" normalises them onto [0, 1]
  # so leaf slots align with split-facet panels.
  xx <- unname(._hierarchy_leaf_x(kids, roots, t$nodes$id)[t$nodes$id])
  hh <- unname(._hierarchy_depths(kids, roots, t$nodes$id)[t$nodes$id])
  if (leaf_spacing == "equal") {
    n_leaves <- sum(!(t$nodes$id %in% names(kids)))
    if (n_leaves > 1) {
      xx <- (xx - 1) / (n_leaves - 1)
    } else {
      xx <- xx * 0
    }
  }
  if (direction == "down") {
    t$nodes$x <- xx
    t$nodes$y <- -hh
  } else if (direction == "up") {
    t$nodes$x <- xx
    t$nodes$y <- hh
  } else if (direction == "right") {
    t$nodes$x <- hh
    t$nodes$y <- xx
  } else {
    t$nodes$x <- -hh
    t$nodes$y <- xx
  }
  if (edge == "elbow") {
    # Right-angle connection: one bend per edge.  For vertically growing
    # trees the elbow sits at (child x, parent y); for horizontal growth at
    # (parent x, child y).  Two rows per edge render with mark_rule.
    px <- t$nodes$x[match(t$edges$source, t$nodes$id)]
    py <- t$nodes$y[match(t$edges$source, t$nodes$id)]
    cx <- t$nodes$x[match(t$edges$target, t$nodes$id)]
    cy <- t$nodes$y[match(t$edges$target, t$nodes$id)]
    ex <- if (direction %in% c("down", "up")) cx else px
    ey <- if (direction %in% c("down", "up")) py else cy
    legs <- rbind(
      data.frame(
        source = t$edges$source, target = paste0(t$edges$target, "*"),
        x = px, y = py, xend = ex, yend = ey
      ),
      data.frame(
        source = paste0(t$edges$source, "*"), target = t$edges$target,
        x = ex, y = ey, xend = cx, yend = cy
      )
    )
    rownames(legs) <- NULL
    t$edges <- legs
  } else {
    t$edges <- ._map_edge_coords(t$nodes, t$edges)
  }
  ._new_graph_from_parts(t, directed = TRUE)
}

#' @noRd
#' @keywords internal
._layout_engine_dendrogram <- function(g, direction = c("down", "up", "left", "right")) {
  direction <- match.arg(direction)
  t <- ._graph_topology(g)
  nodes <- t$nodes
  edges <- t$edges
  needed <- c("id", "leaf", "height")
  if (!all(needed %in% names(nodes))) {
    cli::cli_abort(c(
      "{.fn layout_dendrogram} requires a merge tree with {.col leaf}/{.col height} columns.",
      "i" = "Create one via {.code as_graph(hclust_obj)}."
    ))
  }
  kids <- ._hierarchy_children(t)
  roots <- ._hierarchy_roots(t)
  if (length(roots) == 0) {
    ._abort_hint(
      "{.fn layout_dendrogram} found no root: edges must point parent -> child.",
      "The graph contains a cycle; remove it before laying out."
    )
  }

  # Leaf ordering comes from the shared post-order walk (leaves numbered
  # left-to-right by merge side; internal nodes at mean child position).
  x_of <- ._hierarchy_leaf_x(kids, roots, nodes$id)

  xx <- unname(x_of[nodes$id])
  hh <- unname(as.numeric(nodes$height))
  # Raw heights are root-maximal, so the sign mapping differs from
  # layout_tree (whose raw depth axis is root-minimal).
  if (direction == "down") {
    t$nodes$x <- xx
    t$nodes$y <- hh
  } else if (direction == "up") {
    t$nodes$x <- xx
    t$nodes$y <- -hh
  } else if (direction == "right") {
    t$nodes$x <- -hh
    t$nodes$y <- xx
  } else {
    t$nodes$x <- hh
    t$nodes$y <- xx
  }
  t$edges <- ._map_edge_coords(t$nodes, t$edges)
  ._new_graph_from_parts(t, directed = TRUE)
}

#' @noRd
#' @keywords internal
._layout_engine_sankey <- function(g, node_width = 0.04, padding = 0.02,
                                   curvature = 0.5, n_points = 50,
                                   max_sweeps = 4L) {
  if (node_width <= 0 || node_width >= 0.5) {
    ._abort_arg_range("node_width", "in (0, 0.5)", got = node_width)
  }
  if (padding < 0 || padding >= 1) {
    ._abort_arg_range("padding", "in [0, 1)", got = padding)
  }
  n_points <- floor(n_points)
  if (n_points < 2) {
    ._abort_arg_range("n_points", ">= 2", got = n_points)
  }

  t <- ._graph_topology(g)
  nodes <- t$nodes
  edges <- t$edges
  if (nrow(edges) == 0) {
    ._abort_hint(
      "{.fn layout_sankey} requires at least one edge.",
      "Start from an edge table with at least one row."
    )
  }
  if (any(edges$source == edges$target)) {
    ._abort_hint(
      "{.fn layout_sankey} does not support self-loops.",
      "Remove self-loop rows (source equal to target) or use {.fn mark_network}."
    )
  }

  ids <- nodes$id

  # -- layering: longest-path relaxation; non-convergence means a cycle --
  depth <- stats::setNames(rep(NA_real_, length(ids)), ids)
  depth[stats::setNames(!(ids %in% unique(edges$target)), ids)] <- 0
  converged <- FALSE
  for (pass in seq_len(length(ids) + 1L)) {
    changed <- FALSE
    for (i in seq_len(nrow(edges))) {
      s <- edges$source[[i]]
      tt <- edges$target[[i]]
      cand <- depth[[s]] + 1
      if (!is.na(depth[[s]]) && (is.na(depth[[tt]]) || cand > depth[[tt]])) {
        depth[[tt]] <- cand
        changed <- TRUE
      }
    }
    if (!changed) {
      converged <- TRUE
      break
    }
  }
  if (!converged || anyNA(depth)) {
    # Non-convergence = depths kept climbing; residual NA = no seedable
    # source exists (every node is a target) -- both indicate a cycle.
    ._abort_hint(
      "{.fn layout_sankey} requires an acyclic graph (DAG); a cycle was detected.",
      "Remove the cycle from the edge table, or use {.fn layout_force} for cyclic graphs."
    )
  }

  # -- within-layer ordering: deterministic barycenter sweeps --
  depths <- sort(unique(depth))
  layer_nodes <- lapply(depths, function(d) ids[depth == d])
  names(layer_nodes) <- as.character(depths)
  flat <- unlist(layer_nodes)
  pos <- stats::setNames(unlist(lapply(layer_nodes, seq_along)), flat)

  in_by <- split(edges$source, edges$target)
  out_by <- split(edges$target, edges$source)
  for (sweep in seq_len(max_sweeps)) {
    going_up <- sweep %% 2 == 1L
    seq_d <- if (going_up) depths else rev(depths)
    for (d in seq_d) {
      key <- as.character(d)
      memb <- layer_nodes[[key]]
      keys <- vapply(memb, function(v) {
        nb <- if (going_up) in_by[[v]] else out_by[[v]]
        if (is.null(nb) || length(nb) == 0) pos[[v]] else mean(pos[nb])
      }, numeric(1))
      layer_nodes[[key]] <- memb[order(keys)]
      pos[layer_nodes[[key]]] <- seq_along(memb)
    }
  }

  # -- magnitudes and global vertical scale --
  val <- as.numeric(edges$value)
  if (any(!is.finite(val)) || any(val < 0)) {
    ._abort_hint(
      "{.fn layout_sankey} requires finite non-negative edge {.col value}.",
      "Drop or repair {.val NA}/{.val NaN}/{.val Inf} and negative values."
    )
  }
  # Positional alignment: tapply() only reports observed levels, so match()
  # (never name-based indexing on pmax results) fills absent endpoints.
  out_v <- as.numeric(tapply(val, edges$source, sum))[match(ids, unique(edges$source))]
  in_v <- as.numeric(tapply(val, edges$target, sum))[match(ids, unique(edges$target))]
  out_v[is.na(out_v)] <- 0
  in_v[is.na(in_v)] <- 0
  nv <- stats::setNames(pmax(out_v, in_v), ids)

  k_candidates <- vapply(layer_nodes, function(memb) {
    tot <- sum(nv[memb])
    if (tot <= 0) Inf else (1 - padding * (length(memb) - 1)) / tot
  }, numeric(1))
  k <- min(c(k_candidates[is.finite(k_candidates)], 1))

  # -- node rectangles --
  D <- max(depths)
  span <- 1 - node_width
  xmin_v <- xmax_v <- ymin_v <- ymax_v <- stats::setNames(numeric(length(ids)), ids)
  for (d in depths) {
    memb <- layer_nodes[[as.character(d)]]
    x0 <- if (D == 0) (1 - node_width) / 2 else d * span / D
    used <- sum(nv[memb]) * k + padding * (length(memb) - 1)
    cursor <- (1 - used) / 2
    for (v in memb) {
      hgt <- nv[[v]] * k
      ymin_v[[v]] <- cursor
      ymax_v[[v]] <- cursor + hgt
      cursor <- ymax_v[[v]] + padding
    }
    xmin_v[memb] <- x0
    xmax_v[memb] <- x0 + node_width
  }

  # -- ribbon offsets: two passes keep source/target stacks consistent --
  sy_top <- sy_bot <- ty_top <- ty_bot <- numeric(nrow(edges))
  ord_out <- order(depth[edges$source], pos[edges$source], pos[edges$target])
  off <- stats::setNames(numeric(length(ids)), ids)
  for (r in ord_out) {
    th <- val[r] * k
    top <- ymax_v[[edges$source[r]]] - off[[edges$source[r]]]
    sy_top[r] <- top
    sy_bot[r] <- top - th
    off[[edges$source[r]]] <- off[[edges$source[r]]] + th
  }
  off[] <- 0
  ord_in <- order(depth[edges$target], pos[edges$target], pos[edges$source])
  for (r in ord_in) {
    th <- val[r] * k
    top <- ymax_v[[edges$target[r]]] - off[[edges$target[r]]]
    ty_top[r] <- top
    ty_bot[r] <- top - th
    off[[edges$target[r]]] <- off[[edges$target[r]]] + th
  }

  # -- ribbon polygons (long form): cubic bezier with horizontal tangents --
  sx <- xmax_v[edges$source]
  tx <- xmin_v[edges$target]
  cxm <- sx + curvature * (tx - sx)
  u <- seq(0, 1, length.out = n_points)
  wa <- (1 - u)^3 # start-anchor weight
  wm1 <- 3 * (1 - u)^2 * u # first control point weight
  wm2 <- 3 * (1 - u) * u^2 # second control point weight
  wb <- u^3 # end-anchor weight
  parts <- vector("list", nrow(edges))
  for (r in seq_len(nrow(edges))) {
    # x: anchors at sx/tx, both controls at cxm
    bxr <- wa * sx[r] + (wm1 + wm2) * cxm[r] + wb * tx[r]
    # y: anchors a,a,b,b with horizontal tangents
    y_top <- (wa + wm1) * sy_top[r] + (wm2 + wb) * ty_top[r]
    y_bot <- (wa + wm1) * sy_bot[r] + (wm2 + wb) * ty_bot[r]
    df <- data.frame(
      .ribbon_id = r,
      x = c(bxr, rev(bxr)),
      y = c(y_top, rev(y_bot)),
      stringsAsFactors = FALSE
    )
    for (cl in names(edges)) df[[cl]] <- edges[[cl]][r]
    parts[[r]] <- df
  }
  ribbons <- do.call(rbind, parts)

  t$nodes$xmin <- unname(xmin_v[ids])
  t$nodes$xmax <- unname(xmax_v[ids])
  t$nodes$ymin <- unname(ymin_v[ids])
  t$nodes$ymax <- unname(ymax_v[ids])
  t$nodes$xc <- (t$nodes$xmin + t$nodes$xmax) / 2
  t$nodes$yc <- (t$nodes$ymin + t$nodes$ymax) / 2
  ._new_graph(
    list(nodes = t$nodes, edges = t$edges, ribbons = ribbons),
    directed = TRUE
  )
}
# ---- squarify treemap ------------------------------------------------------

# Bruls et al. squarify: pack positive `values` (arbitrary order; sorted
# internally) into rect [x0,x1]x[y0,y1].  Returns an n x 4 matrix
# (xmin, xmax, ymin, ymax) aligned to the input order.
._squarify_pack <- function(values, x0, y0, x1, y1) {
  n <- length(values)
  ord <- order(-values, seq_along(values)) # stable descending
  areas <- values[ord] / sum(values) * (x1 - x0) * (y1 - y0)
  rects <- matrix(NA_real_, n, 4)

  ratio_row <- function(idxs, thickness) {
    dims <- cbind(areas[idxs] / thickness, thickness)
    max(apply(dims, 1, function(z) max(z) / min(z)))
  }

  i <- 1L
  ox <- x0
  oy <- y0
  w <- x1 - x0
  h <- y1 - y0
  while (i <= n) {
    short_side <- min(w, h)
    j <- i
    while (j < n) {
      cur <- ratio_row(i:j, sum(areas[i:j]) / short_side)
      nxt <- ratio_row(i:(j + 1), sum(areas[i:(j + 1)]) / short_side)
      if (nxt <= cur) j <- j + 1L else break
    }
    idxs <- i:j
    thickness <- sum(areas[idxs]) / short_side
    if (w >= h) {
      # strip against the left edge: full height, thickness along x
      cum <- oy
      for (k in idxs) {
        hh <- areas[k] / thickness
        rects[k, ] <- c(ox, ox + thickness, cum, cum + hh)
        cum <- cum + hh
      }
      ox <- ox + thickness
      w <- w - thickness
    } else {
      cum <- ox
      for (k in idxs) {
        ww <- areas[k] / thickness
        rects[k, ] <- c(cum, cum + ww, oy, oy + thickness)
        cum <- cum + ww
      }
      oy <- oy + thickness
      h <- h - thickness
    }
    i <- j + 1L
  }
  rects[order(ord), , drop = FALSE] # restore input order
}

#' @noRd
#' @keywords internal
._layout_engine_treemap <- function(g) {
  t <- ._graph_topology(g)
  nodes <- t$nodes
  edges <- t$edges
  if (!"value" %in% names(nodes)) {
    cli::cli_abort(c(
      "{.fn layout_treemap} requires leaf sizes in a {.col value} column.",
      "i" = "Build the graph from a hierarchy table carrying \\
             {.code id}/{.code parent}/{.code value}."
    ))
  }
  kids <- ._hierarchy_children(t)
  roots <- ._hierarchy_roots(t)
  if (length(roots) == 0) {
    ._abort_hint(
      "{.fn layout_treemap} found no root: edges must point parent -> child.",
      "Ensure exactly one node has {.val NA} as its {.col parent}."
    )
  }
  has_children <- names(kids)
  leaf_mask <- !(nodes$id %in% has_children)
  leaf_vals <- suppressWarnings(as.numeric(nodes$value))
  bad <- leaf_mask & (!is.finite(leaf_vals) | leaf_vals <= 0)
  if (any(bad)) {
    ._abort_hint(
      sprintf("Leaves need positive finite {.col value}: {.val %s}.", paste0("c(", deparse(nodes$id[bad]), ")")),
      "Assign each leaf a positive numeric {.col value}."
    )
  }

  # Aggregate values bottom-up (deepest first).
  depth <- stats::setNames(rep(0L, nrow(nodes)), nodes$id)
  edges$.depth <- 0
  changed <- TRUE
  while (changed) {
    changed <- FALSE
    for (i in seq_len(nrow(edges))) {
      nd <- edges$.depth[i] + 1L
      tgt <- edges$target[i]
      if (depth[[tgt]] < nd) {
        depth[[tgt]] <- nd
        changed <- TRUE
      }
    }
  }
  agg <- stats::setNames(ifelse(leaf_mask, leaf_vals, NA_real_), nodes$id)
  for (nd in rev(sort(unique(depth)))) {
    internal <- nodes$id[depth == nd & !leaf_mask]
    for (v in internal) agg[[v]] <- sum(agg[kids[[v]]])
  }
  # Roots may also be leaves (single-node tree).
  for (rt in roots) {
    if (is.na(agg[[rt]])) agg[[rt]] <- leaf_vals[[rt]]
  }

  rects <- matrix(NA_real_, nrow(nodes), 4,
    dimnames = list(nodes$id, c("xmin", "xmax", "ymin", "ymax"))
  )
  place <- function(v, rect) {
    rects[v, ] <<- rect
    kid_ids <- kids[[v]]
    if (is.null(kid_ids)) {
      return(invisible())
    }
    vals <- agg[kid_ids]
    sub <- ._squarify_pack(as.numeric(vals), rect[1], rect[3], rect[2], rect[4])
    for (kk in seq_along(kid_ids)) {
      place(kid_ids[kk], sub[kk, ])
    }
  }
  root_vals <- agg[roots]
  root_sub <- ._squarify_pack(as.numeric(root_vals), 0, 0, 1, 1)
  for (rr in seq_along(roots)) {
    place(roots[rr], root_sub[rr, ])
  }

  t$nodes$xmin <- rects[nodes$id, "xmin"]
  t$nodes$xmax <- rects[nodes$id, "xmax"]
  t$nodes$ymin <- rects[nodes$id, "ymin"]
  t$nodes$ymax <- rects[nodes$id, "ymax"]
  t$nodes$xc <- (t$nodes$xmin + t$nodes$xmax) / 2
  t$nodes$yc <- (t$nodes$ymin + t$nodes$ymax) / 2
  t$edges$.depth <- NULL
  t$nodes$leaf <- leaf_mask
  tables <- list(nodes = t$nodes, edges = t$edges)
  if (any(leaf_mask)) {
    # Convenience view for mark_rect(data = ~leaves, ...) rendering.
    tables$leaves <- t$nodes[leaf_mask, , drop = FALSE]
  }
  ._new_graph(tables, directed = TRUE)
}

# ---- chord -----------------------------------------------------------------

# Circular chord layout: nodes become annular sectors sized by total flow
# (out + in; self-loops counted once), edges become closed bezier bands.
#
# Output tables:
#   nodes   : original attributes + flow_total / arc_lo / arc_hi angles +
#             xc/yc label anchors placed just outside the ring
#   edges   : untouched topology rows
#   arcs    : long-form sector polygons (.arc_id, x, y + node attributes)
#   ribbons : long-form band polygons (.ribbon_id, x, y + edge attributes);
#             duplicate (source,target) pairs are summed into one band
#
#' @noRd
#' @keywords internal
._layout_engine_chord <- function(g, inner_radius = 0.65,
                                  pad_angle = 0.03, n_points = 60,
                                  curvature = 0.35,
                                  order_by = c("total", "appearance")) {
  if (inner_radius <= 0 || inner_radius >= 1) {
    ._abort_arg_range("inner_radius", "in (0, 1)", got = inner_radius)
  }
  if (pad_angle < 0 || pad_angle > pi / 4) {
    ._abort_arg_range(
      "pad_angle", "a small non-negative angle in radians [0, pi/4]",
      got = pad_angle
    )
  }
  curvature <- min(max(curvature, 0), 0.95)
  n_points <- floor(n_points)
  if (n_points < 2) {
    ._abort_arg_range("n_points", ">= 2", got = n_points)
  }

  t <- ._graph_topology(g)
  nodes <- t$nodes
  edges <- t$edges
  if (nrow(edges) == 0) {
    ._abort_hint(
      "{.fn layout_chord} requires at least one edge.",
      "Start from an edge table with at least one row."
    )
  }
  val_raw <- suppressWarnings(as.numeric(edges$value))
  if (any(!is.finite(val_raw)) || any(val_raw < 0)) {
    ._abort_hint(
      "{.fn layout_chord} requires finite non-negative edge {.col value}.",
      "Drop or repair {.val NA}/{.val NaN}/{.val Inf} and negative values."
    )
  }

  ids <- nodes$id

  # Aggregate duplicate (source,target) pairs: one ribbon per ordered pair;
  # the representative row keeps its extra attribute columns.  tapply()
  # sorts by key levels, so realign the sums back to appearance order.
  key <- paste(edges$source, "\u0001", edges$target, sep = "")
  rep_row <- which(!duplicated(key))
  agg <- edges[rep_row, , drop = FALSE]
  summed <- as.numeric(tapply(
    edges$value, factor(key, levels = unique(key)),
    sum
  ))
  agg$value <- summed
  m_pairs <- nrow(agg)

  # Node magnitudes: every aggregated pair contributes its value to BOTH
  # endpoints (a self-loop therefore occupies two sub-spans on its own arc,
  # matching the two ribbon ends drawn for it).
  total_v <- stats::setNames(numeric(length(ids)), ids)
  for (r in seq_len(m_pairs)) {
    total_v[[agg$source[r]]] <- total_v[[agg$source[r]]] + agg$value[r]
    total_v[[agg$target[r]]] <- total_v[[agg$target[r]]] + agg$value[r]
  }
  if (sum(total_v) <= 0) {
    ._abort_hint(
      "{.fn layout_chord} requires positive edge {.col value}.",
      "All-zero weights leave no sector to draw; drop empty edges."
    )
  }

  # Sector ordering: descending total (d3-chord style) or input appearance.
  order_by <- match.arg(order_by)
  rank_vec <- if (order_by == "total") {
    order(-total_v[ids], seq_along(ids))
  } else {
    seq_along(ids)
  }
  ids_seq <- ids[rank_vec]

  # Angular budget: clockwise from 12 o'clock, fixed gap between sectors.
  usable <- 2 * pi - pad_angle * length(ids)
  if (usable <= 0) {
    ._abort_hint(
      sprintf("{.arg pad_angle} is too large for {.val %s} sectors.", length(ids)),
      "Reduce {.arg pad_angle} so sectors keep positive angular width."
    )
  }
  k_ang <- usable / sum(total_v)

  a_lo <- stats::setNames(numeric(length(ids)), ids)
  a_hi <- stats::setNames(numeric(length(ids)), ids)
  cursor <- pi / 2
  for (vid in ids_seq) {
    sp <- total_v[[vid]] * k_ang
    a_hi[[vid]] <- cursor
    a_lo[[vid]] <- cursor - sp
    cursor <- a_lo[[vid]] - pad_angle
  }

  # Sub-span allocation: outgoing ends first pass (sorted by ribbon order),
  # incoming second pass; diagonal consumes two consecutive widths.
  agg$.sp <- ._pos_in_circ(agg$source, ids, rank_vec)
  agg$.tp <- ._pos_in_circ(agg$target, ids, rank_vec)
  agg <- agg[order(agg$.sp, agg$.tp), , drop = FALSE]
  is_diag <- agg$source == agg$target

  cur <- a_hi
  s_span <- matrix(NA_real_, m_pairs, 2) # source-side [lo, hi]
  t_span <- matrix(NA_real_, m_pairs, 2) # target-side [lo, hi]
  for (r in seq_len(m_pairs)) {
    vid <- agg$source[r]
    w <- agg$value[r] * k_ang
    hi1 <- cur[[vid]]
    if (is_diag[r]) {
      # self-loop: split the double width into source (upper) / target (lower)
      mid <- hi1 - w
      s_span[r, ] <- c(mid - w, hi1)
      t_span[r, ] <- c(mid - w, mid)
      cur[[vid]] <- mid - w
    } else {
      s_span[r, ] <- c(hi1 - w, hi1)
      cur[[vid]] <- hi1 - w
    }
  }
  cur[] <- a_hi
  for (r in which(!is_diag)) {
    vid <- agg$target[r]
    w <- agg$value[r] * k_ang
    hi <- cur[[vid]]
    t_span[r, ] <- c(hi - w, hi)
    cur[[vid]] <- hi - w
  }

  r_in <- inner_radius
  pt <- function(rr, th) c(rr * cos(th), rr * sin(th))
  arc_chain <- function(rr, from, to, np) {
    th <- seq(from, to, length.out = np)
    matrix(c(rr * cos(th), rr * sin(th)), ncol = 2)
  }
  bez <- function(p0, p3, np) {
    p1 <- p0 * (1 - curvature)
    p2 <- p3 * (1 - curvature)
    u_ <- seq(0, 1, length.out = np)
    b0 <- (1 - u_)^3
    b1 <- 3 * (1 - u_)^2 * u_
    b2 <- 3 * (1 - u_) * u_^2
    b3 <- u_^3
    cbind(
      b0 * p0[1] + b1 * p1[1] + b2 * p2[1] + b3 * p3[1],
      b0 * p0[2] + b1 * p1[2] + b2 * p2[2] + b3 * p3[2]
    )
  }

  parts <- vector("list", m_pairs)
  for (r in seq_len(m_pairs)) {
    ss <- s_span[r, ]
    ts <- t_span[r, ]
    chain_a <- arc_chain(r_in, ss[2], ss[1], n_points)
    chain_b <- arc_chain(r_in, ts[2], ts[1], n_points)
    curve_a <- bez(pt(r_in, ss[1]), pt(r_in, ts[2]), n_points)
    curve_b <- bez(pt(r_in, ts[1]), pt(r_in, ss[2]), n_points)
    poly <- rbind(
      chain_a, curve_a[-1, , drop = FALSE],
      chain_b, curve_b[-1, , drop = FALSE]
    )
    df <- data.frame(
      .ribbon_id = r, x = poly[, 1], y = poly[, 2],
      stringsAsFactors = FALSE
    )
    for (cl in names(agg)) {
      if (!grepl("^\\.", cl)) df[[cl]] <- agg[[cl]][r]
    }
    parts[[r]] <- df
  }
  ribbons <- do.call(rbind, parts)

  # Annular sector polygons for the node ring.
  apart <- vector("list", length(ids))
  for (p in seq_along(ids)) {
    vid <- ids[p]
    outer <- arc_chain(1, a_hi[[vid]], a_lo[[vid]], n_points)
    inner_r <- arc_chain(r_in, a_lo[[vid]], a_hi[[vid]], n_points)
    poly <- rbind(outer, inner_r)
    df <- data.frame(
      .arc_id = p, x = poly[, 1], y = poly[, 2],
      stringsAsFactors = FALSE
    )
    for (cl in names(nodes)) df[[cl]] <- nodes[[cl]][p]
    apart[[p]] <- df
  }
  arcs <- do.call(rbind, apart)

  mid_ang <- (a_hi + a_lo) / 2
  t$nodes$flow_total <- unname(total_v[ids])
  t$nodes$arc_lo <- unname(a_lo[ids])
  t$nodes$arc_hi <- unname(a_hi[ids])
  t$nodes$xc <- cos(unname(mid_ang[ids])) * 1.08
  t$nodes$yc <- sin(unname(mid_ang[ids])) * 1.08

  ._new_graph(
    list(nodes = t$nodes, edges = t$edges, arcs = arcs, ribbons = ribbons),
    directed = TRUE
  )
}

# Position of each id within the circular sequence defined by rank_vec.
._pos_in_circ <- function(id_vec, ids, rank_vec) {
  pos <- integer(length(ids))
  pos[rank_vec] <- seq_along(ids)
  stats::setNames(pos[id_vec], id_vec)
}

# ---- pipeline plumbing -----------------------------------------------------

._apply_layout <- function(fn, plot, engine, ...) {
  if (is.null(plot@graph)) {
    cli::cli_abort(c(
      "{.fn {fn}} requires graph data.",
      "i" = "Create it with {.fn as_graph} and pass to {.fn plotit}."
    ))
  }
  plot@graph <- engine(plot@graph, ...)
  plot
}

# Register both dispatch targets for a layout generic:
#   plotit_class     -> pipeline form (requires @graph, returns modified plot)
#   plotit_graph_cls -> bare-graph form (returns a new graph)
# Mirrors the mark factory in R/mark.R: only the exported generic stays
# hand-written.  Forwarding bodies name every declared argument explicitly
# (no `...`) so the method formals stay exactly identical to the generic's.
#' Register pipeline and bare-graph methods for a layout generic.
#' @noRd
#' @keywords internal
._register_layout_methods <- function(generic, engine) {
  force(generic)
  force(engine)
  fn_name <- deparse(substitute(generic))
  # Forward every declared argument except `plot`, which both wrappers
  # consume themselves.  Symbols keep their formal names so the generated
  # calls pass arguments by name.
  fwd_args <- setdiff(names(formals(generic)), "plot")
  arg_syms <- lapply(fwd_args, as.symbol)
  names(arg_syms) <- fwd_args

  # engine(<all generic args>) -- bare graph passthrough.
  graph_body <- as.call(c(list(engine), quote(plot), arg_syms))
  graph_fun <- as.function(
    c(formals(generic), list(as.call(list(quote(`{`), graph_body)))),
    envir = parent.frame()
  )

  # ._apply_layout("<generic>", plot, engine, <all generic args>)
  pipeline_body <- as.call(c(
    list(as.name("._apply_layout")),
    list(fn_name), quote(plot), list(engine), arg_syms
  ))
  pipeline_fun <- as.function(
    c(formals(generic), list(as.call(list(quote(`{`), pipeline_body)))),
    envir = parent.frame()
  )

  S7::method(generic, plotit_class) <- pipeline_fun
  S7::method(generic, plotit_graph_cls) <- graph_fun
  invisible()
}

# ---- public API ------------------------------------------------------------

#' Force-directed layout
#'
#' Positions nodes with a self-contained Fruchterman-Reingold force
#' simulation (attractive edge forces, pairwise repulsion, linear cooling).
#' No external dependency; runs are deterministic when `seed` is given.
#' Node table gains `x`/`y`; edge table gains `x`, `y`, `xend`, `yend`.
#'
#' @param plot A `plotit` object holding graph data (created via
#'   [as_graph()] + [plotit()]), or a bare `plotit_graph`.
#' @param iterations Number of simulation steps.
#' @param seed Random seed; pass one for reproducible output.
#' @param ... Optional named argument `weights`: non-negative numeric
#'   vector, one per edge -- higher weights pull endpoints closer together.
#'   Any other name is ignored with a warning.
#' @return A modified `plotit` object (pipeline form), or a new
#'   `plotit_graph` when called on raw graph data.
#' @examples
#' e <- data.frame(source = c("a", "a", "b"), target = c("b", "c", "c"))
#' g <- as_graph(e) |> layout_force(seed = 1)
#' g$nodes
#'
#' as_graph(e) |>
#'   plotit() |>
#'   layout_force(seed = 1) |>
#'   mark_point(data = ~nodes) |>
#'   mark_rule(data = ~edges, colour = "grey70")
#' @export
layout_force <- S7::new_generic(
  "layout_force", "plot",
  function(plot, iterations = 500, seed = NULL, ...) {
    S7::S7_dispatch()
  }
)
._register_layout_methods(layout_force, ._layout_engine_force)

#' Circular layout
#'
#' Places all nodes on a unit circle, optionally sorted by connectivity.
#'
#' @param plot A `plotit` object holding graph data, or a bare
#'   `plotit_graph`.
#' @param order_by `"id"` keeps node-table order; `"degree"` sorts nodes by
#'   descending degree before placement.
#' @return A modified `plotit` object (pipeline form), or a new
#'   `plotit_graph` when called on raw graph data.
#' @examples
#' e <- data.frame(source = c("a", "a", "b"), target = c("b", "c", "c"))
#' g <- as_graph(e) |> layout_circle()
#' g$nodes
#' @export
layout_circle <- S7::new_generic(
  "layout_circle", "plot",
  function(plot, order_by = c("id", "degree")) {
    S7::S7_dispatch()
  }
)
._register_layout_methods(layout_circle, ._layout_engine_circle)

#' Tree layout
#'
#' Arranges a rooted hierarchy: leaves spread left-to-right in merge-side
#' order and internal nodes sit at the mean leaf position of their
#' children.  Self-contained (no external dependency).  Edges must point
#' from parent to child; multiple roots (forests) are supported.
#'
#' @param plot A `plotit` object holding graph data (created via
#'   [as_graph()] + [plotit()]), or a bare `plotit_graph`.
#' @param direction Direction the tree grows: `"down"` (root on top),
#'   `"up"`, `"right"`, or `"left"`.
#' @param leaf_spacing Leaf placement: `"count"` packs leaves one unit
#'   apart in merge-side order (d3 tidy-tree); `"equal"` normalises leaves
#'   onto `[0, 1]` so leaf slots align with split-facet panels.
#' @param edge Edge shape: `"straight"` (direct parent-child segments) or
#'   `"elbow"` (right-angle bend via a midpoint row pair; each edge becomes
#'   two rows in the edges table so [mark_rule()] renders the polyline).
#' @return A modified `plotit` object (pipeline form), or a new
#'   `plotit_graph` when called on raw graph data.
#' @examples
#' h <- data.frame(
#'   id     = c("root", "A", "B", "a1", "a2"),
#'   parent = c(NA, "root", "root", "A", "A")
#' )
#' as_graph(h) |>
#'   plotit() |>
#'   layout_tree(direction = "down") |>
#'   mark_rule(data = ~edges) |>
#'   mark_point(data = ~nodes)
#'
#' as_graph(h) |>
#'   plotit() |>
#'   layout_tree(direction = "right", edge = "elbow") |>
#'   mark_rule(data = ~edges) |>
#'   mark_point(data = ~nodes)
#' @export
layout_tree <- S7::new_generic(
  "layout_tree", "plot",
  function(plot, direction = c("down", "up", "left", "right"),
           leaf_spacing = c("count", "equal"),
           edge = c("straight", "elbow")) {
    S7::S7_dispatch()
  }
)
._register_layout_methods(layout_tree, ._layout_engine_tree)

# ---- dendrogram ------------------------------------------------------------

#' Dendrogram layout
#'
#' Positions a merge tree (from [as_graph()] applied to an `hclust` or
#' `dendrogram` object) using node heights as the depth axis.  Leaf order
#' follows the original merge sides, so label ordering matches the cluster
#' analysis output.
#'
#' @param plot A `plotit` object holding graph data, or a bare
#'   `plotit_graph`.
#' @param direction Direction the tree grows: `"down"` (root on top),
#'   `"up"`, `"right"`, or `"left"`.
#' @return A modified `plotit` object (pipeline form), or a new
#'   `plotit_graph` when called on raw graph data.
#' @examples
#' hc <- hclust(dist(USArrests[1:6, ]))
#' g <- as_graph(hc) |> layout_dendrogram()
#' head(g$nodes)
#'
#' as_graph(hc) |>
#'   plotit() |>
#'   layout_dendrogram(direction = "down") |>
#'   mark_rule(data = ~edges) |>
#'   mark_point(data = ~nodes)
#' @export
layout_dendrogram <- S7::new_generic(
  "layout_dendrogram", "plot",
  function(plot, direction = c("down", "up", "left", "right")) {
    S7::S7_dispatch()
  }
)
._register_layout_methods(layout_dendrogram, ._layout_engine_dendrogram)

# ---- sankey ----------------------------------------------------------------

#' Sankey layout
#'
#' Layered flow layout for DAG edge tables: nodes become rectangles
#' (`xmin`/`xmax`/`ymin`/`ymax`, plus `xc`/`yc` centers), and each edge
#' becomes a closed bezier ribbon emitted to a third table named
#' `ribbons` in long-form polygon coordinates (`x`, `y`, `.ribbon_id`
#' plus all original edge attribute columns for fill mapping).
#'
#' The layout is fully deterministic: layers follow longest-path depths,
#' refined by barycenter sweeps; no seed is required.
#'
#' @param plot A `plotit` object holding graph data, or a bare
#'   `plotit_graph`.  The graph must be acyclic.
#' @param node_width Horizontal width of node rectangles (unit-square
#'   fraction).
#' @param padding Vertical gap between nodes in the same layer.
#' @param curvature Ribbon curvature in `[0, 1]`; `0.5` gives symmetric
#'   horizontal-tangent beziers.
#' @param n_points Samples per ribbon boundary curve.
#' @param max_sweeps Barycenter refinement sweeps (deterministic).
#' @return A modified `plotit` object (pipeline form), or a new
#'   `plotit_graph` with a `ribbons` table when called on raw graph data.
#' @examples
#' e <- data.frame(
#'   source = c("A", "A", "B", "B", "C"),
#'   target = c("B", "C", "C", "D", "D"),
#'   value  = c(10, 5, 8, 3, 6)
#' )
#' g <- as_graph(e) |> layout_sankey()
#' names(g)
#' head(g$nodes[, c("id", "xmin", "ymin")])
#'
#' as_graph(e) |>
#'   plotit() |>
#'   layout_sankey() |>
#'   mark_polygon(
#'     data = ~ribbons,
#'     encode(fill = source, group = .ribbon_id),
#'     alpha = 0.5
#'   ) |>
#'   mark_rect(data = ~nodes, encode(fill = id))
#' @export
layout_sankey <- S7::new_generic(
  "layout_sankey", "plot",
  function(plot, node_width = 0.04, padding = 0.02, curvature = 0.5,
           n_points = 50, max_sweeps = 4L) {
    S7::S7_dispatch()
  }
)
._register_layout_methods(layout_sankey, ._layout_engine_sankey)

# ---- treemap ---------------------------------------------------------------

#' Treemap layout
#'
#' Recursive squarified tiling (Bruls et al.) of a value hierarchy.  Leaves
#' carry sizes in the node table's `value` column (build via
#' `as_graph()` on an `id`/`parent`/`value` hierarchy table); parent values
#' are aggregated from their descendants.  Every node gains
#' `xmin`/`xmax`/`ymin`/`ymax` within the unit square plus a `leaf` flag.
#' A derived `leaves` table is emitted for direct rendering with
#' `mark_rect(data = ~leaves)`.
#'
#' @param plot A `plotit` object holding graph data, or a bare
#'   `plotit_graph`.
#' @return A modified `plotit` object (pipeline form), or a new
#'   `plotit_graph` when called on raw graph data.
#' @examples
#' h <- data.frame(
#'   id     = c("root", "A", "B", "a1", "a2"),
#'   parent = c(NA, "root", "root", "A", "A"),
#'   value  = c(NA, NA, 50, 30, 20)
#' )
#' g <- as_graph(h) |> layout_treemap()
#' subset(g$nodes, leaf)[, c("id", "xmin", "xmax")]
#'
#' as_graph(h) |>
#'   plotit() |>
#'   layout_treemap() |>
#'   mark_rect(data = ~leaves, encode(fill = id))
#' @export
layout_treemap <- S7::new_generic(
  "layout_treemap", "plot",
  function(plot) {
    S7::S7_dispatch()
  }
)
._register_layout_methods(layout_treemap, ._layout_engine_treemap)

# ---- chord -----------------------------------------------------------------

#' Chord layout
#'
#' Circular chord layout: nodes become annular sectors on a ring whose
#' angular spans are proportional to total incident flow; edges become
#' closed bezier bands crossing the interior.  Emits four tables:
#'
#' * `nodes` -- original attributes plus `flow_total`, arc angles
#'   (`arc_lo`/`arc_hi`) and `xc`/`yc` label anchors outside the ring;
#' * `edges` -- untouched topology rows;
#' * `arcs` -- long-form sector polygons (`.arc_id`, `x`, `y`, node attrs)
#'   rendered with `mark_polygon(data = ~arcs, group = .arc_id)`;
#' * `ribbons` -- long-form band polygons (`.ribbon_id`, `x`, `y`, edge
#'   attrs) rendered with `mark_polygon(data = ~ribbons,
#'   group = .ribbon_id)`.
#'
#' Duplicate `(source, target)` pairs are summed into a single band.
#' Sectors are ordered by descending total flow by default; use
#' `order_by = "appearance"` to keep input order.  Fully deterministic.
#'
#' @param plot A `plotit` object holding graph data, or a bare
#'   `plotit_graph`.
#' @param inner_radius Inner radius of the ring, `(0, 1)`.
#' @param pad_angle Gap between sectors in radians.
#' @param n_points Samples per boundary chain of each polygon.
#' @param curvature Inward bowing of bands, `[0, 0.95]`.
#' @param order_by `"total"` sorts sectors by descending flow;
#'   `"appearance"` keeps first-appearance order.
#' @return A modified `plotit` object (pipeline form), or a new
#'   `plotit_graph` with `arcs`/`ribbons` tables when called on raw graph
#'   data.
#' @examples
#' e <- data.frame(
#'   source = c("A", "A", "B", "B", "C"),
#'   target = c("B", "C", "C", "D", "D"),
#'   value  = c(10, 5, 8, 3, 6)
#' )
#' g <- as_graph(e) |> layout_chord()
#' g$nodes[, c("id", "flow_total")]
#'
#' as_graph(e) |>
#'   plotit() |>
#'   layout_chord() |>
#'   mark_polygon(
#'     data = ~ribbons,
#'     encode(fill = source, group = .ribbon_id),
#'     alpha = 0.4
#'   ) |>
#'   mark_polygon(
#'     data = ~arcs,
#'     encode(fill = id, group = .arc_id)
#'   )
#' @export
layout_chord <- S7::new_generic(
  "layout_chord", "plot",
  function(plot, inner_radius = 0.65, pad_angle = 0.03, n_points = 60,
           curvature = 0.35, order_by = c("total", "appearance")) {
    S7::S7_dispatch()
  }
)
._register_layout_methods(layout_chord, ._layout_engine_chord)

# ---- layout catalog ---------------------------------------------------------
# Consumed by zzz.R to register plotit_composite rejection stubs.
._CATALOG_LAYOUTS <- c(
  "layout_force", "layout_circle", "layout_tree",
  "layout_dendrogram", "layout_sankey", "layout_treemap", "layout_chord"
)
