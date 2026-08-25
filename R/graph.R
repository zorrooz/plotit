#' Relational graph data
#'
#' Converts common relational data formats into a `plotit_graph` object: a
#' named collection of data.frames (canonical tables `nodes` / `edges`)
#' consumable by [plotit()] and transformed by `layout_*()` functions.
#'
#' @include class.R utils.R encode.R
#' @name graph-internal
#' @noRd
#' @keywords internal
NULL

# Aesthetics eligible for automatic binding on formula-resolved layers.
# Only columns actually present in the resolved table are bound, and only
# when the user has not mapped that aesthetic explicitly.
._GRAPH_GEOM_AES <- c(
  "x", "y", "xend", "yend",
  "xmin", "xmax", "ymin", "ymax"
)

# Per-mark binding scopes: geometry columns each mark family understands.
# Restricting the scope prevents e.g. rect corners leaking onto text layers
# (which would trigger ggplot2 "unknown aesthetics" warnings).  Marks not
# listed fall back to the full whitelist.
._MARK_BIND_AES <- list(
  mark_point     = c("x", "y"),
  mark_line      = c("x", "y"),
  mark_path      = c("x", "y"),
  mark_polygon   = c("x", "y"),
  mark_text      = c("x", "y"),
  mark_area      = c("x", "y"),
  mark_density   = c("x", "y"),
  mark_histogram = c("x", "y"),
  mark_boxplot   = c("x", "y"),
  mark_violin    = c("x", "y"),
  mark_smooth    = c("x", "y"),
  mark_hex       = c("x", "y"),
  mark_bar       = c("x", "y"),
  mark_rule      = c("x", "y", "xend", "yend"),
  mark_rect      = c("xmin", "xmax", "ymin", "ymax", "x", "y"),
  mark_errorbar  = c("x", "y", "xmin", "xmax", "ymin", "ymax")
)

# Resolve an argument that may be a bare symbol or a single string into a
# column name.  NULL passes through (optional arguments).
._arg_name <- function(q, arg) {
  if (rlang::quo_is_null(q)) {
    return(NULL)
  }
  e <- rlang::quo_get_expr(q)
  if (rlang::is_symbol(e)) {
    return(as.character(e))
  }
  if (is.character(e) && length(e) == 1 && !is.na(e)) {
    return(e)
  }
  cli::cli_abort("{.arg {arg}} must be a single column name.")
}

# ---- coercions -------------------------------------------------------------

._graph_from_edgelist <- function(edges, nodes, source_col, target_col, value_col,
                                  directed) {
  if (!source_col %in% names(edges)) {
    cli::cli_abort("Edge table has no column {.val {source_col}}; pass {.arg source}.")
  }
  if (!target_col %in% names(edges)) {
    cli::cli_abort("Edge table has no column {.val {target_col}}; pass {.arg target}.")
  }
  src <- edges[[source_col]]
  tgt <- edges[[target_col]]
  if (anyNA(src) || anyNA(tgt)) {
    cli::cli_abort("Edge endpoints must not contain {.val NA}.")
  }
  src <- as.character(src)
  tgt <- as.character(tgt)

  # Magnitude: explicit column > existing "value" column > unit weights.
  # A named column absent from the table falls back to unit weights instead
  # of crashing (e.g. mark_chord/mark_sankey on pure source/target tables).
  val_col <- value_col %||% if ("value" %in% names(edges)) "value" else NULL
  if (!is.null(val_col) && !val_col %in% names(edges)) {
    val_col <- NULL
  }
  val <- if (is.null(val_col)) {
    rep(1, nrow(edges))
  } else {
    raw <- edges[[val_col]]
    num <- suppressWarnings(as.numeric(raw))
    if (anyNA(num) || length(num) != nrow(edges)) {
      cli::cli_abort("Column {.val {val_col}} used as {.arg value} must be numeric.")
    }
    num
  }

  out_edges <- data.frame(source = src, target = tgt, value = val)
  extra <- setdiff(names(edges), c(source_col, target_col, val_col))
  for (col in extra) out_edges[[col]] <- edges[[col]]

  if (is.null(nodes)) {
    node_ids <- unique(c(src, tgt)) # first-appearance order (Vega convention)
    out_nodes <- data.frame(id = node_ids, stringsAsFactors = FALSE)
  } else {
    if (!"id" %in% names(nodes)) {
      cli::cli_abort(
        c("Node table must have an {.col id} column.",
          "i" = "Rename the key column to {.col id}, or omit {.arg nodes} to generate it."
        )
      )
    }
    if (anyNA(nodes$id) || anyDuplicated(nodes$id) > 0) {
      cli::cli_abort("Node {.col id} values must be non-missing and unique.")
    }
    node_ids <- as.character(nodes$id)
    missing_ids <- setdiff(unique(c(src, tgt)), node_ids)
    if (length(missing_ids) > 0) {
      cli::cli_abort(
        c("Edge endpoints missing from {.arg nodes}: {.val {missing_ids}}.",
          "i" = "Add them, or omit {.arg nodes} to generate nodes implicitly."
        )
      )
    }
    out_nodes <- data.frame(id = node_ids, stringsAsFactors = FALSE)
    for (col in setdiff(names(nodes), "id")) out_nodes[[col]] <- nodes[[col]]
  }

  ._new_graph(list(nodes = out_nodes, edges = out_edges), directed = directed)
}

._graph_from_matrix <- function(mat, directed) {
  if (is.null(dimnames(mat)) || is.null(rownames(mat))) {
    dimnames(mat) <- list(
      paste0("n", seq_len(nrow(mat))),
      paste0("n", seq_len(ncol(mat)))
    )
  }
  # Column-major expansion: M[i, j] is the flow source = rownames[i],
  # target = colnames[j].  Zero cells carry no relation and are dropped.
  df <- data.frame(
    source = rep.int(rownames(mat), times = ncol(mat)),
    target = rep(colnames(mat), each = nrow(mat)),
    value = as.vector(mat),
    stringsAsFactors = FALSE
  )
  df <- df[df$value != 0, , drop = FALSE]
  ._graph_from_edgelist(df, NULL, "source", "target", "value", directed)
}

._graph_from_table <- function(tab, directed) {
  df <- as.data.frame(tab)
  if (length(dim(tab)) != 2 || ncol(df) != 3) {
    cli::cli_abort("Contingency tables must have exactly two classifying dimensions.")
  }
  out <- data.frame(
    source = as.character(df[[1]]),
    target = as.character(df[[2]]),
    value = as.numeric(df[[3]])
  )
  ._graph_from_edgelist(out, NULL, "source", "target", "value", directed)
}

# hclust / dendrogram -> binary merge tree.  Node heights are stored on the
# node table so a dendrogram layout engine can consume them later.  The
# merge side (1 = left, 2 = right) is kept on the edge table (.side) so
# leaf order -- and thus label ordering -- survives the round trip.
._graph_from_hclust <- function(hc, directed = TRUE) {
  n_leaves <- length(hc$labels)
  n_nodes <- 2 * n_leaves - 1
  internal_ids <- paste0("hclust_", seq_len(n_leaves - 1))
  ids <- c(as.character(hc$labels), internal_ids)

  nodes <- data.frame(
    id = ids,
    leaf = c(rep(TRUE, n_leaves), rep(FALSE, n_leaves - 1)),
    height = c(rep(0, n_leaves), hc$height),
    stringsAsFactors = FALSE
  )

  src <- character(0)
  tgt <- character(0)
  side <- integer(0)
  for (s in seq_len(n_leaves - 1)) {
    for (j in seq_along(hc$merge[s, ])) {
      child <- hc$merge[s, j]
      src <- c(src, internal_ids[s])
      tgt <- c(tgt, if (child < 0) as.character(hc$labels[-child]) else ids[n_leaves + child])
      side <- c(side, j)
    }
  }
  edges <- data.frame(
    source = src,
    target = tgt,
    value = rep(1, length(src)),
    .side = side,
    stringsAsFactors = FALSE
  )
  ._new_graph(list(nodes = nodes, edges = edges), directed = TRUE)
}

# Flat hierarchy table (id + parent columns, optional value on leaves).
# Edges are synthesized child <- parent; all node attributes survive.
._graph_from_hierarchy <- function(h, directed = TRUE) {
  ids <- as.character(h$id)
  if (anyNA(ids) || anyDuplicated(ids) > 0) {
    cli::cli_abort("Hierarchy {.col id} values must be non-missing and unique.")
  }
  root_mask <- is.na(h$parent)
  par <- as.character(h$parent)
  unknown <- setdiff(unique(par[!root_mask]), ids)
  if (length(unknown) > 0) {
    cli::cli_abort(
      "Hierarchy {.col parent} references unknown ids: {.val {unknown}}."
    )
  }
  if (any(ids == par, na.rm = TRUE)) {
    cli::cli_abort("Nodes cannot be their own {.col parent}.")
  }
  edges <- data.frame(
    source = par[!root_mask],
    target = ids[!root_mask],
    value = rep(1, sum(!root_mask)),
    stringsAsFactors = FALSE
  )
  nodes <- h[, c("id", setdiff(names(h), "id")), drop = FALSE]
  ._new_graph(list(nodes = nodes, edges = edges), directed = TRUE)
}

._graph_from_tbl_graph <- function(g) {
  if (!requireNamespace("tidygraph", quietly = TRUE)) {
    cli::cli_abort("Converting {.cls tbl_graph} requires the {.pkg tidygraph} package.")
  }
  nd <- as.data.frame(tidygraph::activate(g, nodes))
  ed <- as.data.frame(tidygraph::activate(g, edges))
  # Directedness: read via igraph when available (tidygraph itself imports
  # igraph, so this fallback branch is theoretical).
  directed <- FALSE
  if (requireNamespace("igraph", quietly = TRUE)) {
    directed <- tryCatch(
      igraph::is_directed(tidygraph::as.igraph(g)),
      error = function(e) FALSE
    )
  }
  key <- nd[[1]]
  ed$source <- key[ed$from]
  ed$target <- key[ed$to]
  ed$from <- NULL
  ed$to <- NULL
  names(nd)[1] <- "id"
  weight_col <- intersect(c("weight", "value"), names(ed))[1]
  if (is.na(weight_col)) {
    ed$value <- rep(1, nrow(ed))
  } else {
    names(ed)[names(ed) == weight_col] <- "value"
  }
  ._graph_from_edgelist(ed, nd, "source", "target", "value", directed)
}

# ---- public API ------------------------------------------------------------

#' Convert relational data to a plotit graph
#'
#' Coerces edge lists, adjacency matrices, contingency tables, cluster trees,
#' or `tbl_graph` objects into a `plotit_graph`: a named list of data frames
#' (`nodes`, `edges`) that can initialize [plotit()] and be positioned by
#' `layout_*()` transforms.  Layout coordinates are never mapped by hand --
#' they are produced by layouts and bound automatically at mark time.
#'
#' @param edges Primary relational input.  One of:
#'   * a data.frame edge list (columns selected by `source`/`target`/`value`);
#'   * a matrix or `xtabs`/table of flows (melted automatically);
#'   * an `hclust` or `dendrogram` object;
#'   * a `tbl_graph`.
#' @param nodes Optional node attribute table.  Must contain a column named
#'   `id`.  When omitted, nodes are generated implicitly from the edge
#'   endpoints in first-appearance order.
#' @param source,target Column names (bare or quoted) locating the edge
#'   endpoints in `edges`.  Defaults `"source"` / `"target"`.
#' @param value Column name (bare or quoted) holding flow magnitudes.
#'   Defaults to a column named `"value"` when present, otherwise unit
#'   weights are used.  The output column is always named `value`.
#' @param directed Logical; whether the relation is directed.
#' @return An S3 `plotit_graph` object: a named list with at least `nodes`
#'   (`id` column first) and `edges` (`source`, `target`, `value`).
#' @examples
#' e <- data.frame(source = c("a", "b"), target = c("b", "c"))
#' g <- as_graph(e)
#' names(g)
#' g$edges
#' @export
as_graph <- function(edges, nodes = NULL,
                     source = "source", target = "target",
                     value = NULL, directed = FALSE) {
  source_col <- ._arg_name(rlang::enquo(source), "source")
  target_col <- ._arg_name(rlang::enquo(target), "target")
  value_col <- ._arg_name(rlang::enquo(value), "value")

  if (inherits(edges, "hclust")) {
    return(._graph_from_hclust(edges))
  }
  if (inherits(edges, "dendrogram")) {
    return(._graph_from_hclust(stats::as.hclust(edges)))
  }
  if (inherits(edges, "tbl_graph")) {
    return(._graph_from_tbl_graph(edges))
  }
  if (inherits(edges, "table")) {
    return(._graph_from_table(edges, directed))
  }
  if (is.matrix(edges)) {
    return(._graph_from_matrix(edges, directed))
  }
  if (is.data.frame(edges)) {
    # Flat hierarchy table (id + parent) wins over the edgelist reading;
    # documented precedence for tables that carry both conventions.
    if (all(c("id", "parent") %in% names(edges))) {
      return(._graph_from_hierarchy(edges, directed = TRUE))
    }
    return(._graph_from_edgelist(
      edges, nodes,
      source_col %||% "source",
      target_col %||% "target",
      value_col, directed
    ))
  }
  cli::cli_abort(c(
    "{.arg edges} must be an edge data.frame, matrix, table, hclust, \\
     dendrogram, or tbl_graph.",
    "x" = "Received {.cls {class(edges)[1]}}."
  ))
}

# ---- mark-time helpers -----------------------------------------------------

# Resolve the `data` argument of a mark against the plot.
#
# Returns list(data, from_graph):
#   formula (~nodes)  -> look up the named table in plot@graph
#   NULL              -> global-data inheritance (forbidden on graph plots)
#   anything else     -> passthrough (existing behaviour)
#
#' Resolve a layer data argument against the plot's graph slot.
#' @noRd
#' @keywords internal
._resolve_layer_data <- function(data, plot) {
  if (inherits(data, "formula")) {
    g <- plot@graph
    if (is.null(g)) {
      cli::cli_abort(c(
        "{.code data = ~table} requires graph data.",
        "i" = "Create it with {.fn as_graph} and pass to {.fn plotit}."
      ))
    }
    rhs <- rlang::f_rhs(data)
    if (!rlang::is_symbol(rhs)) {
      cli::cli_abort(
        "{.code data = ~name}: right-hand side must be a bare table name."
      )
    }
    if (!is.null(rlang::f_lhs(data))) {
      cli::cli_abort(
        "{.arg data} must be a one-sided formula, e.g. {.code data = ~nodes}."
      )
    }
    nm <- as.character(rhs)
    if (!(nm %in% names(g))) {
      cli::cli_abort(c(
        "Table {.val {nm}} not found in graph data.",
        "i" = "Available tables: {.val {names(g)}}."
      ))
    }
    return(list(data = g[[nm]], from_graph = TRUE))
  }
  if (is.null(data)) {
    if (!is.null(plot@graph)) {
      cli::cli_abort(c(
        "Plot data is a graph: marks must reference a table explicitly.",
        "i" = "Use {.code data = ~nodes} or {.code data = ~edges}."
      ))
    }
    return(list(data = NULL, from_graph = FALSE))
  }
  list(data = data, from_graph = FALSE)
}

# Bind layout-produced geometry columns (x/y/xend/yend/xmin...) onto the
# layer mapping when the user did not map them.  Explicit mappings always
# win.  Only called for formula-resolved layers; `scope` restricts the
# candidate aesthetics to what the target mark understands.
#
#' Auto-bind geometry columns for formula-resolved layers.
#' @noRd
#' @keywords internal
._auto_bind_geometry <- function(mapping, data, scope = NULL) {
  if (is.null(mapping)) {
    mapping <- ggplot2::aes()
  }
  cols <- intersect(scope %||% ._GRAPH_GEOM_AES, names(data))
  todo <- setdiff(cols, names(mapping))
  for (col in todo) {
    mapping[[col]] <- rlang::sym(col)
  }
  if (!inherits(mapping, "plotit_encode")) {
    class(mapping) <- c("plotit_encode", class(mapping))
  }
  mapping
}
