#' @include class.R graph.R mark_style.R mark.R
NULL

# ---- Relational sugar marks (sankey / treemap / network / chord) -----------
#
# One file keeps the whole relational family cohesive: every mark here is a
# syntax-sugar composite over a self-contained layout engine (R/layout.R)
# plus plain ggplot2 layers (AGENTS.md 3.3.4a).  Shared machinery lives at
# the top so the four sugars stay thin and mutually consistent:
#
# * ._rel_canon_edges()      : one canonicalization rule for edges tables
# * ._rel_label_aes()        : xc/yc/id label aes for layout anchors
# * ._first_occurrence_fill(): node identity derived from edge groups
# * ._rel_reject_dots()      : uniform "..." rejection pointing at layout_*
# * ._rel_ribbon_layer()     : shared flow-band polygon layer
# * ._rel_label_layer()      : shared conditional-colour label layer
# * ._rel_legend_title()     : semantic legend title for derived fills
# * ._rel_canvas()           : shared coordinate-free canvas chrome

#' Warn and drop any arguments passed via `...` to a sugar mark.
#' @noRd
#' @keywords internal
._rel_reject_dots <- function(dots, fn, hint) {
  if (length(dots) > 0) {
    cli::cli_warn(c(
      "Arguments passed to {.fn {fn}} via {.arg ...} are ignored.",
      "i" = "Use {hint} in the explicit pipeline form."
    ))
  }
}

#' Add the shared ribbon/band polygon layer (fill_grp x .ribbon_id).
#' @noRd
#' @keywords internal
._rel_ribbon_layer <- function(plot, edge_alpha) {
  band_mapping <- ggplot2::aes()
  band_mapping$group <- rlang::sym(".ribbon_id")
  band_mapping$fill <- rlang::sym("fill_grp")
  mark_polygon(plot,
    mapping = band_mapping, data = ~ribbons,
    alpha = edge_alpha
  )
}

#' Add the conditional-contrast label layer over `table` (~nodes/~leaves).
#' White labels over an unmapped static fill, near-black over user-mapped
#' channel colours.
#' @noRd
#' @keywords internal
._rel_label_layer <- function(plot, table, has_fill, show_labels = TRUE) {
  if (!isTRUE(show_labels)) {
    return(plot)
  }
  lbl_args <- list(
    plot = plot, mapping = ._rel_label_aes(), data = table,
    size = ._MARK_STYLE$txt_note
  )
  lbl_args$colour <- if (!has_fill) "white" else "grey20"
  do.call(mark_text, lbl_args)
}

#' Semantic legend title for the derived fill channel: "source" when the
#' source-identity default is live, otherwise the user's own column name.
#' @noRd
#' @keywords internal
._rel_legend_title <- function(has_fill, fill_name) {
  if (!has_fill) "source" else (fill_name %||% "fill")
}

#' Apply the coordinate-free relational canvas: blank every axis element,
#' optionally pinning a fixed aspect ratio (`clip = "off"` keeps outside-
#' ring labels visible on chord diagrams).
#' @noRd
#' @keywords internal
._rel_canvas <- function(plot, fixed = FALSE, clip = "on") {
  if (fixed) {
    plot@gg <- plot@gg + ggplot2::coord_fixed(clip = clip)
  }
  ._theme_blank_axes(plot)
}

# Canonicalize an edges table for the flow sugars (mark_sankey /
# mark_chord):
#
# * structural aesthetics (`encode(source =, target =[, value =])`) win
#   over literal columns;
# * without a mapping, the table must carry literal `source`/`target`
#   (optional `value`) columns -- any other format (from/to pairs,
#   contingency long form, adjacency matrix) goes through as_graph()
#   first; its `edges` table plugs straight back in;
# * the fill vector defaults to source identity when no fill is mapped.
#
# Returns list(canon, src, tgt, fill_vals, fill_name, has_fill); `canon`
# carries the renamed structural columns plus every untouched extra column.
#' Canonicalize an edges table for the relational flow sugars.
#' @noRd
#' @keywords internal
._rel_canon_edges <- function(edges_df, mapping) {
  if (!is.data.frame(edges_df)) {
    cli::cli_abort("{.arg data} must be an edges data frame.")
  }
  has_struct <- !is.null(mapping$source) && !is.null(mapping$target)
  has_lit <- all(c("source", "target") %in% names(edges_df))
  src_nm <- tgt_nm <- val_nm <- NULL
  if (has_struct) {
    src_nm <- ._quo_name_arg(mapping$source)
    tgt_nm <- ._quo_name_arg(mapping$target)
    if (!is.null(mapping$value)) val_nm <- ._quo_name_arg(mapping$value)
    src <- as.character(rlang::eval_tidy(mapping$source, edges_df))
    tgt <- as.character(rlang::eval_tidy(mapping$target, edges_df))
  } else if (has_lit) {
    src <- as.character(edges_df$source)
    tgt <- as.character(edges_df$target)
  } else {
    cli::cli_abort(c(
      "Relational marks require structural aesthetics or literal \\
       {.col source}/{.col target} columns.",
      "i" = "Map other column names: {.code encode(source = ..., \\
              target = ..., value = ...)}.",
      "i" = "For matrices / tables: convert first with {.fn as_graph}, \\
             then feed its {.field edges} table to the mark."
    ))
  }
  if (anyNA(src) || anyNA(tgt)) {
    cli::cli_abort("Edge endpoints must not contain {.val NA}.")
  }
  val <- NULL
  if (has_struct) {
    if (!is.null(mapping$value)) {
      val <- suppressWarnings(as.numeric(
        rlang::eval_tidy(mapping$value, edges_df)
      ))
      if (anyNA(val)) {
        cli::cli_abort(
          "Column {.val {val_nm}} used as {.arg value} must be numeric."
        )
      }
    }
  } else if ("value" %in% names(edges_df)) {
    val_nm <- "value"
    val <- suppressWarnings(as.numeric(edges_df$value))
  }

  # Fill: mapped aesthetic wins; numeric values stay numeric so continuous
  # scales keep their semantics; categorical values coerce to character.
  has_fill <- !is.null(mapping$fill) && !inherits(mapping$fill, "AsIs")
  fill_name <- NULL
  if (has_fill) {
    fill_vals <- rlang::eval_tidy(mapping$fill, edges_df)
    fill_name <- tryCatch(._quo_name_arg(mapping$fill), error = function(e) NULL)
    if (!is.numeric(fill_vals)) fill_vals <- as.character(fill_vals)
  } else {
    fill_vals <- src # source identity default for ribbons/bands
  }

  canon <- data.frame(source = src, target = tgt)
  if (!is.null(val)) canon$value <- val
  canon$fill_grp <- fill_vals
  skip_cols <- unique(c(
    src_nm, tgt_nm, val_nm,
    "source", "target", "value", "fill_grp"
  ))
  for (cl in setdiff(names(edges_df), skip_cols)) canon[[cl]] <- edges_df[[cl]]

  list(
    canon = canon, src = src, tgt = tgt,
    fill_vals = fill_vals, fill_name = fill_name, has_fill = has_fill
  )
}

# Label aes for layout anchors: xc/yc position + id text.
#' Label aes for relational layout anchor columns.
#' @noRd
#' @keywords internal
._rel_label_aes <- function() {
  m <- ggplot2::aes()
  m$x <- rlang::sym("xc")
  m$y <- rlang::sym("yc")
  m$label <- rlang::sym("id")
  m
}

# Node-level fill derived from edge-level groups: each node inherits the
# group of the edge on which it first appears.  Endpoint positions live in
# the concatenated (source, target) vector; the second half folds back to
# the owning edge row.  Shared by the sankey and chord sugars.
#' First-occurrence node fill from edge groups.
#' @noRd
#' @keywords internal
._first_occurrence_fill <- function(src, tgt, fill_vals, ids) {
  endpoints <- c(src, tgt)
  pos <- vapply(ids, function(z) which(endpoints == z)[1], integer(1))
  first_edge <- ifelse(pos > length(src), pos - length(src), pos)
  stats::setNames(unname(fill_vals[first_edge]), ids)
}

# ---- mark_sankey ----
#' Sankey flow diagram layer (sugar)
#'
#' Creates a Sankey diagram showing directed flows between nodes.
#' Equivalent to the pipeline
#' `as_graph() |> layout_sankey() |> mark_polygon(data = ~ribbons) |>
#' mark_rect(data = ~nodes)` -- see §3.3.4a.  Accepts an **edges table**
#' with `source`, `target`, and optionally `value` columns (either mapped
#' via structural aesthetics or present as literal columns); node and
#' ribbon geometry come from the built-in layered layout (deterministic,
#' dependency-free).  The derived flow/node fill channel defaults to source
#' identity and ships with the curated token palette -- friendly qualitative
#' for categories, viridis sequential for continuous values; chain
#' `scale_fill()` to replace it (last call wins).
#'
#' The laid-out graph (`nodes` / `edges` / `ribbons` tables) is stored on
#' `@graph`, so subsequent marks can reference any table directly for
#' tuning beyond this sugar's two parameters.
#'
#' @param plot A plotit object
#' @param mapping Structural aesthetics: \code{source} (required),
#'   \code{target} (required), \code{value} (optional).  Visual: \code{fill}
#'   colours ribbons and nodes alike; ribbons default to source identity.
#' @param data Optional edges data.frame for this layer
#' @param node_color Default colour for node rectangles (used when no
#'   \code{fill} mapping is present, default `._MARK_STYLE$ink` =
#'   \code{"grey30"}).
#' @param edge_alpha Alpha transparency for flow ribbons
#'   (default `._MARK_STYLE$alpha_link` = 0.5).
#' @param show_labels If `TRUE` (default), draw node ids inside the strips.
#' @param ... Unused; fine-tuning (padding, curvature, node width) lives on
#'   [layout_sankey()] in the explicit pipeline form.
#' @return Modified plotit object; `@graph` holds the laid-out tables.
#' @references
#' AntV G2: \href{https://g2.antv.antgroup.com/en/api/mark/sankey}{Sankey} (graphlib)
#' @examples
#' df <- data.frame(
#'   source = c("A", "A", "B", "B", "C"),
#'   target = c("B", "C", "C", "D", "D"),
#'   value  = c(10, 5, 8, 3, 6)
#' )
#' df |>
#'   plotit(encode(
#'     source = source, target = target,
#'     value = value, fill = source
#'   )) |>
#'   mark_sankey() |>
#'   scale_fill(range = "viridis")
#' @export
mark_sankey <- S7::new_generic(
  "mark_sankey", "plot",
  function(plot, mapping = NULL, data = NULL, ...,
           node_color = ._MARK_STYLE$ink,
           edge_alpha = ._MARK_STYLE$alpha_link,
           show_labels = TRUE) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_sankey, plotit_class) <- function(
  plot, mapping = NULL, data = NULL, ...,
  node_color = ._MARK_STYLE$ink,
  edge_alpha = ._MARK_STYLE$alpha_link,
  show_labels = TRUE
) {
  ._rel_reject_dots(
    rlang::list2(...), "mark_sankey",
    "{.fn layout_sankey} to control padding, curvature and node width"
  )

  rel <- ._rel_canon_edges(
    data %||% plot@gg$data,
    mapping %||% plot@gg$mapping
  )

  g <- ._graph_from_edgelist(rel$canon, NULL, "source", "target", "value",
    directed = TRUE
  )
  g <- ._layout_engine_sankey(g)

  # Node fill: first-occurrence identity (see ._first_occurrence_fill).
  g$nodes$fill_grp <- ._first_occurrence_fill(
    rel$src, rel$tgt, rel$fill_vals, g$nodes$id
  )
  plot@graph <- g

  # The flow/node fills need a legend; drop the default_color guides
  # suppression injected by plotit().
  plot <- ._clear_default_color(plot)

  plot <- ._rel_ribbon_layer(plot, edge_alpha)

  if (rel$has_fill) {
    node_mapping <- ggplot2::aes()
    node_mapping$fill <- rlang::sym("fill_grp")
    plot <- mark_rect(plot, mapping = node_mapping, data = ~nodes)
  } else {
    plot <- mark_rect(plot, data = ~nodes, fill = node_color)
  }

  # Labels sit inside the node strips (conditional contrast).
  plot <- ._rel_label_layer(plot, ~nodes, rel$has_fill, show_labels)

  # Semantic legend title: the derived channel renders through the
  # fill_grp column, which would otherwise leak into the legend.  A user
  # mapping restores its own column name; label_legend() can override.
  plot@gg <- plot@gg +
    ggplot2::labs(fill = ._rel_legend_title(rel$has_fill, rel$fill_name))

  # Coordinate-free diagram: no axes around the layout canvas.
  ._rel_canvas(plot)
}

# ---- mark_treemap ----
#' Treemap layer (sugar)
#'
#' Creates a treemap from a **hierarchy table** (`id`/`parent` columns, leaf
#' sizes in a `value` column) using plotit's self-contained squarified
#' tiling.  Equivalent to the pipeline `as_graph(hierarchy) |>
#' layout_treemap() |> mark_rect(data = ~leaves)`; the laid-out tables
#' (`nodes`/`edges`/`leaves`) are stored on `@graph` for further tuning.
#'
#' Fully self-contained: no \pkg{treemapify} dependency, deterministic
#' Bruls squarify layout.  Tiles receive the unified white hairline
#' separators and coordinate axes are blanked (the diagram is
#' coordinate-free).  A mapped `fill` column ships with the curated token
#' palette -- friendly qualitative for categories, viridis sequential for
#' continuous values (chain `scale_fill()` to replace it).
#'
#' @param plot A plotit object whose data is a hierarchy table with `id`,
#'   `parent`, and leaf-level `value` columns (build via
#'   `as_graph()` on the same shape).  A global `encode(fill = ...)`
#'   maps tile fill against any hierarchy column.
#' @param data Optional hierarchy table for this layer.
#' @param node_color Default tile fill when no fill aesthetic is mapped
#'   (default `._MARK_STYLE$primary` = `"#4E79A7"`).
#' @param show_labels If `TRUE` (default), draw leaf ids at tile centres.
#'   Labels render white over the unmapped brand-blue fill; when a fill is
#'   mapped they fall back to near-black -- chain
#'   `mark_text(data = ~leaves, colour = ...)` for full control.
#' @param ... Unused; tiling fine-tuning lives on [layout_treemap()] in the
#'   explicit pipeline form.
#' @return Modified plotit object; `@graph` holds nodes/edges/leaves.
#' @references
#' AntV G2: \href{https://g2.antv.antgroup.com/en/api/mark/treemap}{Treemap} (graphlib)
#' @examples
#' h <- data.frame(
#'   id     = c("root", "A", "B", "a1", "a2", "b1"),
#'   parent = c(NA, "root", "root", "A", "A", "B"),
#'   value  = c(NA, NA, NA, 30, 20, 50)
#' )
#' h |>
#'   plotit(encode(fill = id)) |>
#'   mark_treemap()
#' @export
mark_treemap <- S7::new_generic(
  "mark_treemap", "plot",
  function(plot, data = NULL,
           node_color = ._MARK_STYLE$primary,
           show_labels = TRUE, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_treemap, plotit_class) <- function(
  plot, data = NULL,
  node_color = ._MARK_STYLE$primary,
  show_labels = TRUE, ...
) {
  ._rel_reject_dots(
    rlang::list2(...), "mark_treemap",
    "{.fn layout_treemap} to control the squarified tiling"
  )

  hier <- data %||% plot@gg$data
  if (!is.data.frame(hier) || !all(c("id", "parent") %in% names(hier))) {
    cli::cli_abort(c(
      "{.fn mark_treemap} requires a hierarchy table with {.col id}, \\
       {.col parent} and leaf {.col value} columns.",
      "i" = "Or run {.code as_graph() |> layout_treemap()} yourself and \\
              render {.code mark_rect(data = ~leaves)}."
    ))
  }

  g <- ._graph_from_hierarchy(hier, directed = TRUE)
  g <- ._layout_engine_treemap(g)
  plot@graph <- g

  # Tile fills need a legend; drop the default_color guides suppression.
  plot <- ._clear_default_color(plot)

  # Fill channel: mapped aesthetic wins over the static default (gated per
  # channel, mirroring mark_network's node statics).
  global_fill <- plot@gg$mapping$fill
  has_fill <- !is.null(global_fill) && !inherits(global_fill, "AsIs")
  rect_mapping <- ggplot2::aes()
  if (has_fill) {
    rect_mapping$fill <- global_fill
    # Mapped tile fill is curated by the layer-level auto-attach (identity
    # channels -> friendly, continuous values -> viridis); a later
    # scale_fill() replaces it (last call wins).
  }
  rect_args <- list(plot = plot, data = ~leaves, mapping = rect_mapping)
  if (!has_fill) rect_args$fill <- node_color
  plot <- do.call(mark_rect, rect_args)

  # Leaf labels centred on each tile (conditional contrast).
  plot <- ._rel_label_layer(plot, ~leaves, has_fill, show_labels)

  # Coordinate-free diagram: no axes around the canvas.
  ._rel_canvas(plot)
}

# ---- mark_network ----
#' Network / force-directed graph layer (sugar)
#'
#' Creates a network visualization from a **nodes** table (main data) plus an
#' **edges** table.  Equivalent to the pipeline
#' `as_graph() |> layout_force()/layout_circle() |>
#' mark_point(data = ~nodes) |> mark_rule(data = ~edges)` -- the composite
#' form exists so common network plots stay one-call simple.  The laid-out
#' graph is stored on `@graph`, so subsequent marks can reference
#' `~nodes` / `~edges` directly, and layers/scales/theme added *before* this
#' call are preserved (additive composition).
#'
#' Fully self-contained: the force/circle layouts run on plotit's own
#' deterministic engines and rendering is plain ggplot2 layers.  Edges
#' render as straight segments; curved edges are a known limitation of the
#' sugar form.  Mapped node colour/fill channels ship with the curated
#' token palette (friendly qualitative / viridis sequential, chain
#' [scale_color()] to replace).
#'
#' @param plot A plotit object. The data should be a data.frame of **nodes**
#'   whose first column is a unique id.
#' @param edges A data.frame of **edges** with literal `source`/`target`
#'   columns, or mapped through `encode_edges`.
#' @param encode_edges An \code{encode()} object with \code{source}
#'   (required), \code{target} (required), \code{value} (optional magnitude).
#'   Visual channels supported on edges:
#'   \code{colour}/\code{linewidth}/\code{linetype}/\code{alpha},
#'   referenced against original edge columns.
#' @param layout Layout algorithm: \code{"auto"} (force-directed),
#'   \code{"circle"}, or \code{"manual"} (numeric \code{x}/\code{y}
#'   columns on the nodes table).
#' @param seed Random seed for the force layout (reproducibility).
#' @param edge_color Default edge colour when no edge colour channel is
#'   mapped (default `._MARK_STYLE$faint` = \code{"grey70"}).
#' @param edge_width Default edge width when no edge linewidth channel is
#'   mapped (default `._MARK_STYLE$lw_thin` = 0.5).
#' @param edge_alpha Optional alpha transparency for edge segments.
#'   `NULL` (default) leaves the edges fully opaque -- unlike the area
#'   bands of sankey/chord, thin strokes do not need translucency; the
#'   parameter exists so the unified edge vocabulary
#'   (`edge_color`/`edge_width`/`edge_alpha`) is available on every
#'   relational sugar.
#' @param edge_shape `"straight"` (default) renders each edge as a rule;
#'   `"curved"` renders quadratic-bezier links through [mark_curve()],
#'   reducing visual overlap in dense networks.  Curve tension is tunable
#'   via `curvature` in `...`.
#' @param node_color Default node colour, applied to the `colour` and
#'   `fill` channels only where they are not mapped
#'   (default `._MARK_STYLE$primary` = \code{"#4E79A7"}).
#' @param node_size Default node size when `size` is not mapped (default 5).
#' @param show_labels If `TRUE` (default), draw node labels when a global
#'   `label` aesthetic is mapped.
#' @param ... Other arguments passed to the edge segment layer (e.g.
#'   \code{arrow}).
#' @return Modified plotit object; `@graph` holds the laid-out tables.
#' @references
#' AntV G2: \href{https://g2.antv.antgroup.com/en/api/mark/force-graph}{ForceGraph}
#' @examples
#' nodes <- data.frame(
#'   name  = c("A", "B", "C", "D"),
#'   group = c("X", "Y", "X", "Y"),
#'   value = c(10, 20, 15, 25)
#' )
#' edges <- data.frame(
#'   source = c("A", "A", "B", "C"),
#'   target = c("B", "C", "C", "D"),
#'   value  = c(1, 2, 3, 4)
#' )
#' nodes |>
#'   plotit(encode(color = group, size = value, label = name)) |>
#'   mark_network(edges = edges, seed = 1) |>
#'   scale_color(range = "viridis") |>
#'   scale_size(range = c(5, 20))
#' @export
mark_network <- S7::new_generic(
  "mark_network", "plot",
  function(plot,
           edges = NULL,
           encode_edges = NULL,
           layout = c("auto", "circle", "manual"),
           seed = NULL,
           edge_color = ._MARK_STYLE$faint, edge_width = ._MARK_STYLE$lw_thin,
           edge_alpha = NULL, edge_shape = c("straight", "curved"),
           node_color = ._MARK_STYLE$primary, node_size = 5,
           show_labels = TRUE, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_network, plotit_class) <- function(
  plot,
  edges = NULL,
  encode_edges = NULL,
  layout = c("auto", "circle", "manual"),
  seed = NULL,
  edge_color = ._MARK_STYLE$faint, edge_width = ._MARK_STYLE$lw_thin,
  edge_alpha = NULL, edge_shape = c("straight", "curved"),
  node_color = ._MARK_STYLE$primary, node_size = 5,
  show_labels = TRUE, ...
) {
  layout <- match.arg(layout)
  edge_shape <- match.arg(edge_shape)

  nodes <- plot@gg$data
  if (is.null(nodes) || !is.data.frame(nodes)) {
    cli::cli_abort(
      "{.fn mark_network} expects a data.frame of nodes as plot data."
    )
  }
  node_id_col <- names(nodes)[1]
  node_ids <- as.character(nodes[[node_id_col]])
  bad_ids <- duplicated(node_ids) | is.na(node_ids) | !nzchar(node_ids)
  if (any(bad_ids)) {
    cli::cli_abort(c(
      "{.fn mark_network} requires a unique, non-NA node id.",
      "x" = "The first column {.val {node_id_col}} contains {sum(bad_ids)} duplicate/empty/NA value(s).",
      "i" = "Ensure the first column of the nodes data frame is a unique id (e.g. name)."
    ))
  }

  # ---- canonicalize edges through the shared relational contract ----
  if (is.null(edges)) {
    canon <- data.frame(
      source = character(0), target = character(0),
      value = numeric(0)
    )
    g <- ._graph_from_edgelist(canon, NULL, "source", "target", "value",
      directed = FALSE
    )
    # nodes-only graph: keep user's table, add id column
    nodes_g <- nodes
    nodes_g$id <- node_ids
    g$nodes <- nodes_g[, c("id", setdiff(names(nodes_g), "id")), drop = FALSE]
    plot@graph <- g
  } else {
    # Structural aesthetics come from encode_edges; everything else follows
    # the single canonicalization rule shared with sankey/chord.
    struct <- NULL
    if (!is.null(encode_edges)) {
      if (is.null(encode_edges$source) || is.null(encode_edges$target)) {
        cli::cli_abort(c(
          "{.arg encode_edges} must map {.val source} and {.val target}.",
          "i" = "Use {.code encode(source = ..., target = ..., value = ...)}."
        ))
      }
      struct <- ggplot2::aes()
      struct$source <- encode_edges$source
      struct$target <- encode_edges$target
      if (!is.null(encode_edges$value)) struct$value <- encode_edges$value
      class(struct) <- c("plotit_encode", oldClass(struct))
    }
    # NOTE: never fall back to the global (nodes) mapping here -- its
    # aesthetics reference node columns that do not exist on the edges
    # table.
    rel <- ._rel_canon_edges(edges, struct)

    nodes_g <- nodes
    nodes_g$id <- node_ids
    nodes_g <- nodes_g[, c("id", setdiff(names(nodes_g), "id")), drop = FALSE]

    g <- ._graph_from_edgelist(rel$canon, nodes_g, "source", "target",
      if ("value" %in% names(rel$canon)) "value" else NULL,
      directed = FALSE
    )

    # ---- layout via shared engines ----
    if (!is.null(seed) && layout != "auto") {
      cli::cli_warn(c(
        "{.arg seed} is ignored for {.code layout = {layout}}.",
        "i" = "Only the force layout is stochastic; circle and manual layouts are deterministic."
      ))
    }
    if (layout == "manual") {
      has_xy <- all(c("x", "y") %in% names(nodes)) &&
        is.numeric(nodes$x) && is.numeric(nodes$y)
      if (!has_xy) {
        cli::cli_abort(
          'layout = "manual" requires numeric {.col x}/{.col y} columns \\
           on the nodes table.'
        )
      }
      # Keep the user's coordinates verbatim -- no topology stripping here.
      g$edges <- ._map_edge_coords(g$nodes, g$edges)
    } else if (layout == "circle") {
      g <- ._layout_engine_circle(g)
    } else {
      g <- ._layout_engine_force(g, seed = seed)
    }
    plot@graph <- g
  }

  # ---- edge layer first (beneath nodes): mapped channels win over statics
  edge_mapping <- ggplot2::aes()
  if (!is.null(encode_edges)) {
    allowed <- c("colour", "linetype", "linewidth", "alpha")
    for (nm in intersect(names(encode_edges), allowed)) {
      edge_mapping[[nm]] <- encode_edges[[nm]]
    }
    unsupported <- setdiff(
      names(encode_edges),
      c("source", "target", "value", allowed)
    )
    if (length(unsupported) > 0) {
      cli::cli_warn(
        "Unsupported edge channels ignored: {.val {unsupported}}."
      )
    }
  }
  dots <- rlang::list2(...)
  if (!is.null(edge_alpha)) dots$alpha <- edge_alpha
  # Straight rules vs curved links -- same data/mapping contract, the
  # graph-edge geometry binds on both mark families.
  edge_marker <- if (identical(edge_shape, "curved")) mark_curve else mark_rule
  if (length(edge_mapping) > 0) {
    args <- c(list(plot = plot, mapping = edge_mapping, data = ~edges), dots)
  } else {
    args <- c(list(
      plot = plot, data = ~edges,
      color = edge_color, linewidth = edge_width
    ), dots)
  }
  plot <- do.call(edge_marker, args)

  # ---- node layer on top of edges: statics gated per channel ----
  # A ggplot2 layer parameter would silently override an aesthetic mapping
  # of the same name, so each static is only injected when the user did not
  # map that channel.
  node_aes <- plot@gg$mapping
  node_mapping <- ggplot2::aes()
  if (!is.null(node_aes)) {
    # Skip I() constants injected by plotit() (D5): copying them into the
    # layer would make later scale_color()/scale_fill() calls ineffective.
    if (!is.null(node_aes$colour) && !inherits(node_aes$colour, "AsIs")) {
      node_mapping$colour <- node_aes$colour
    }
    if (!is.null(node_aes$fill) && !inherits(node_aes$fill, "AsIs")) {
      node_mapping$fill <- node_aes$fill
    }
    if (!is.null(node_aes$size)) node_mapping$size <- node_aes$size
  }
  node_statics <- list()
  # node_color applies to both channels: default shape 19 renders through
  # `colour`, filled shapes (21+) through `fill`.
  if (is.null(node_mapping$colour)) node_statics$colour <- node_color
  if (is.null(node_mapping$fill)) node_statics$fill <- node_color
  if (is.null(node_mapping$size)) node_statics$size <- node_size
  plot <- do.call(._mark_impl, c(list(
    plot, node_mapping, ~nodes,
    position = NULL,
    ggplot2::geom_point,
    rasterize = FALSE, rasterize_dpi = 300,
    rasterize_dev = "cairo",
    auto_dodge = FALSE,
    bind_aes = ._MARK_BIND_AES$mark_point
  ), node_statics))

  # Node labels float just above their points instead of overlapping them.
  if (isTRUE(show_labels) && !is.null(node_aes$label)) {
    label_mapping <- ggplot2::aes()
    label_mapping$label <- node_aes$label
    plot <- mark_text(plot,
      mapping = label_mapping, data = ~nodes,
      position = ggplot2::position_identity(),
      size = ._MARK_STYLE$txt_note,
      vjust = -0.9
    )
  }

  # Mapped node colour/fill channels are curated by the layer-level
  # auto-attach in ._mark_impl() (identity -> friendly, continuous ->
  # viridis); a later scale_color() replaces them (last call wins).

  # Coordinate-free canvas with a true aspect ratio so the layout geometry
  # is not stretched by the panel shape.
  ._rel_canvas(plot, fixed = TRUE)
}

# ---- mark_chord ----
#' Chord diagram layer (sugar)
#'
#' Creates a chord diagram showing pairwise relationships between groups.
#' Equivalent to the pipeline `as_graph() |> layout_chord() |>
#' mark_polygon(data = ~ribbons) |> mark_polygon(data = ~arcs)` -- see
#' §3.3.4a.  Accepts an **edges table** with `source`, `target`, and
#' optionally `value` columns (either mapped via structural aesthetics or
#' present as literal columns); sector arcs and bezier bands come from the
#' built-in circular layout (deterministic, dependency-free).  The fill
#' channel defaults to source identity (the same derived-channel rule as
#' [mark_sankey()]) and ships with the curated token palette -- friendly
#' qualitative for categories, viridis sequential for continuous values
#' (chain [scale_fill()] to replace it).
#'
#' The laid-out graph (`nodes` / `edges` / `arcs` / `ribbons` tables) is
#' stored on `@graph`, so subsequent marks can reference any table directly
#' for tuning beyond this sugar's parameters.  Sector ids are labelled just
#' outside the ring and the panel keeps a fixed aspect ratio so sectors
#' stay circular.
#'
#' @param plot A plotit object
#' @param mapping Structural aesthetics: \code{source} (required),
#'   \code{target} (required), \code{value} (optional).  Visual:
#'   \code{fill} colours sectors and bands alike; bands default to source
#'   identity, compatible with \code{scale_fill_*}.
#' @param data Optional edges data.frame for this layer.  Other formats
#'   (adjacency matrices, contingency tables) convert via [as_graph()]
#'   first -- its `edges` table plugs straight into this mark.
#' @param gap_width Gap between sectors in degrees (default 4); translated
#'   to the layout's angular padding.
#' @param edge_alpha Alpha transparency for link bands
#'   (default `._MARK_STYLE$alpha_link` = 0.5).
#' @param show_labels If `TRUE` (default), draw sector ids outside the ring.
#' @param ... Unused; fine-tuning (inner radius, curvature, sector order)
#'   lives on [layout_chord()] in the explicit pipeline form.
#' @return Modified plotit object; `@graph` holds the laid-out tables.
#' @references
#' AntV G2: \href{https://g2.antv.antgroup.com/en/api/mark/chord}{Chord} (graphlib)
#' @examples
#' df <- data.frame(
#'   source = c("A", "A", "B", "B", "C"),
#'   target = c("B", "C", "C", "D", "D"),
#'   value  = c(5, 3, 4, 2, 6)
#' )
#' df |>
#'   plotit(encode(
#'     source = source, target = target,
#'     value = value, fill = source
#'   )) |>
#'   mark_chord()
#' @export
mark_chord <- S7::new_generic(
  "mark_chord", "plot",
  function(plot, mapping = NULL, data = NULL,
           gap_width = 4, edge_alpha = ._MARK_STYLE$alpha_link,
           show_labels = TRUE, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_chord, plotit_class) <- function(
  plot, mapping = NULL, data = NULL,
  gap_width = 4, edge_alpha = ._MARK_STYLE$alpha_link,
  show_labels = TRUE, ...
) {
  ._rel_reject_dots(
    rlang::list2(...), "mark_chord",
    "{.fn layout_chord} to control inner radius, curvature and sector order"
  )

  rel <- ._rel_canon_edges(
    data %||% plot@gg$data,
    mapping %||% plot@gg$mapping
  )

  g <- ._graph_from_edgelist(rel$canon, NULL, "source", "target", "value",
    directed = TRUE
  )
  g <- ._layout_engine_chord(g, pad_angle = gap_width * pi / 180)

  # Node-level first-occurrence fill, attached to the arc polygons, keeps
  # pair aggregation consistent (#11).
  g$arcs$fill_grp <- ._first_occurrence_fill(
    rel$src, rel$tgt, rel$fill_vals, g$arcs$id
  )
  plot@graph <- g

  # Fills need legends; drop the default_color guides suppression.
  plot <- ._clear_default_color(plot)

  plot <- ._rel_ribbon_layer(plot, edge_alpha)

  arc_mapping <- ggplot2::aes()
  arc_mapping$group <- rlang::sym(".arc_id")
  arc_mapping$fill <- rlang::sym("fill_grp")
  plot <- mark_polygon(plot, mapping = arc_mapping, data = ~arcs)

  # Sector labels float outside the ring on the layout's xc/yc anchors.
  if (isTRUE(show_labels)) {
    plot <- mark_text(plot,
      mapping = ._rel_label_aes(), data = ~nodes,
      size = ._MARK_STYLE$txt_note, colour = ._MARK_STYLE$ink
    )
  }

  # Semantic legend title (same rule as mark_sankey): derived channel gets
  # "source", a user mapping keeps its own column name.
  plot@gg <- plot@gg +
    ggplot2::labs(fill = ._rel_legend_title(rel$has_fill, rel$fill_name))

  # True circles need a fixed aspect ratio; clip off so the outer labels
  # at radius > 1 are not cropped.  No axes around the canvas.
  ._rel_canvas(plot, fixed = TRUE, clip = "off")
}
