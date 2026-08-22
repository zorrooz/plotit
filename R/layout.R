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

._require_igraph <- function() {
  if (!requireNamespace("igraph", quietly = TRUE)) {
    cli::cli_abort("This layout requires the {.pkg igraph} package.")
  }
}

# Strip computed geometry so every engine recomputes purely from topology.
._graph_topology <- function(g) {
  drop <- function(df, cols) df[, setdiff(names(df), intersect(cols, names(df))), drop = FALSE]
  list(
    nodes = drop(g$nodes, c("x", "y", "r")),
    edges = drop(g$edges, c("x", "y", "xend", "yend"))
  )
}

._check_nodes_table <- function(nodes, fn) {
  if (!"id" %in% names(nodes)) {
    cli::cli_abort("{.fn {fn}} requires an {.col id} column on the node table.")
  }
  # igraph treats the first vertices column as node names.
  nodes[, c("id", setdiff(names(nodes), "id")), drop = FALSE]
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

#' @noRd
#' @keywords internal
._layout_engine_force <- function(g, iterations = 500, seed = NULL, ...) {
  ._require_igraph()
  t <- ._graph_topology(g)
  directed <- isTRUE(attr(g, "directed"))
  if (nrow(t$nodes) == 0) {
    cli::cli_abort("Force layout requires at least one node.")
  }
  if (!is.null(seed)) set.seed(seed)
  gr <- igraph::graph_from_data_frame(
    t$edges[, c("source", "target"), drop = FALSE],
    directed = directed,
    vertices = ._check_nodes_table(t$nodes, "layout_force")
  )
  coords <- igraph::layout_with_fr(gr, niter = iterations, ...)
  t$nodes$x <- coords[, 1]
  t$nodes$y <- coords[, 2]
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
    cli::cli_abort("Circle layout requires at least one node.")
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
._layout_engine_tree <- function(g, direction = c("down", "up", "left", "right")) {
  ._require_igraph()
  direction <- match.arg(direction)
  t <- ._graph_topology(g)
  if (nrow(t$edges) == 0) {
    cli::cli_abort("Tree layout requires at least one edge.")
  }
  gr <- igraph::graph_from_data_frame(
    t$edges[, c("source", "target"), drop = FALSE],
    directed = TRUE,
    vertices = ._check_nodes_table(t$nodes, "layout_tree")
  )
  roots <- which(igraph::degree(gr, mode = "in") == 0)
  if (length(roots) == 0) {
    cli::cli_abort(
      c("Tree layout found no root: the graph contains a cycle.",
        "i" = "Edges must point from parent to child."
      )
    )
  }
  coords <- igraph::layout_as_tree(gr, root = roots, mode = "out")
  x <- coords[, 1]
  y <- coords[, 2]
  # Raw layout: x spreads leaves, y is depth from the root (root at 0).
  # Direction names describe where the tree grows; the root sits opposite.
  if (direction == "down") {
    t$nodes$x <- x
    t$nodes$y <- -y
  } else if (direction == "up") {
    t$nodes$x <- x
    t$nodes$y <- y
  } else if (direction == "right") {
    t$nodes$x <- y
    t$nodes$y <- x
  } else {
    t$nodes$x <- -y
    t$nodes$y <- x
  }
  t$edges <- ._map_edge_coords(t$nodes, t$edges)
  ._new_graph(list(nodes = t$nodes, edges = t$edges), directed = TRUE)
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

# ---- public API ------------------------------------------------------------

#' Force-directed layout
#'
#' Positions nodes with a Fruchterman-Reingold force simulation
#' ([igraph::layout_with_fr]).  Node table gains `x`/`y`; edge table gains
#' `x`, `y`, `xend`, `yend`.
#'
#' @param plot A `plotit` object holding graph data (created via
#'   [as_graph()] + [plotit()]), or a bare `plotit_graph`.
#' @param iterations Number of simulation steps.
#' @param seed Random seed; pass one for reproducible output.
#' @param ... Passed to [igraph::layout_with_fr] (e.g. `weights`, `area`).
#' @return A modified `plotit` object (pipeline form), or a new
#'   `plotit_graph` when called on raw graph data.
#' @examplesIf requireNamespace("igraph", quietly = TRUE)
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

#' @export
S7::method(layout_force, plotit_class) <- function(plot, iterations = 500,
                                                   seed = NULL, ...) {
  ._apply_layout("layout_force", plot, ._layout_engine_force,
    iterations = iterations, seed = seed, ...
  )
}

S7::method(layout_force, plotit_graph_cls) <- function(plot, iterations = 500,
                                                       seed = NULL, ...) {
  ._layout_engine_force(plot, iterations = iterations, seed = seed, ...)
}

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

#' @export
S7::method(layout_circle, plotit_class) <- function(plot,
                                                    order_by = c("id", "degree")) {
  order_by <- match.arg(order_by)
  ._apply_layout("layout_circle", plot, ._layout_engine_circle,
    order_by = order_by
  )
}

S7::method(layout_circle, plotit_graph_cls) <- function(
  plot, order_by = c("id", "degree")
) {
  order_by <- match.arg(order_by)
  ._layout_engine_circle(plot, order_by = order_by)
}

#' Tree layout
#'
#' Arranges a rooted hierarchy with [igraph::layout_as_tree].  Edges must
#' point from parent to child; multiple roots (forests) are supported.
#'
#' @param plot A `plotit` object holding graph data (created via
#'   [as_graph()] + [plotit()]), or a bare `plotit_graph`.
#' @param direction Direction the tree grows: `"down"` (root on top),
#'   `"up"`, `"right"`, or `"left"`.
#' @return A modified `plotit` object (pipeline form), or a new
#'   `plotit_graph` when called on raw graph data.
#' @examplesIf requireNamespace("igraph", quietly = TRUE)
#' hc <- hclust(dist(USArrests[, 1:3]))
#' as_graph(hc) |>
#'   plotit() |>
#'   layout_tree(direction = "down") |>
#'   mark_rule(data = ~edges) |>
#'   mark_point(data = ~nodes)
#' @export
layout_tree <- S7::new_generic(
  "layout_tree", "plot",
  function(plot, direction = c("down", "up", "left", "right")) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(layout_tree, plotit_class) <- function(
  plot, direction = c("down", "up", "left", "right")
) {
  direction <- match.arg(direction)
  ._apply_layout("layout_tree", plot, ._layout_engine_tree,
    direction = direction
  )
}

S7::method(layout_tree, plotit_graph_cls) <- function(
  plot, direction = c("down", "up", "left", "right")
) {
  direction <- match.arg(direction)
  ._layout_engine_tree(plot, direction = direction)
}
