#' Initialize a plotit object
#'
#' @include class.R encode.R utils.R style.R
#' @param data A data frame.
#' @param mapping An object created by [encode()].
#' @param autofit Logical; if `TRUE`, plot dimensions are determined automatically.
#' @param width,height Numeric; default width and height (ignored if `autofit = TRUE`).
#' @param size_unit Unit for width/height: `"in"`, `"cm"`, `"mm"`.
#' @param dodge Numeric; global default dodge width. If `NULL`, heuristically set.
#' @param default_color Single color string. Applied as default color mapping if no
#'   color/fill aesthetic is present in `mapping`. Adding any `scale_color()` or
#'   `scale_fill()` later will automatically disable this single-color mapping.
#' @return A `plotit` object.
#' @examples
#' plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
#' plotit(mtcars, encode(x = wt, y = mpg, colour = cyl))
#' @export
plotit <- function(
  data,
  mapping = encode(),
  autofit = FALSE,
  width = 7,
  height = 5,
  size_unit = "in",
  dodge = NULL,
  default_color = "#4E79A7"
) {
  if (!inherits(mapping, "plotit_encode")) {
    cli::cli_abort(c(
      "Invalid {.arg mapping} argument",
      "x" = "{.arg mapping} must be created with {.fn encode}",
      "i" = "Did you forget to use {.code encode(x = ..., y = ...)}?"
    ))
  }

  # Graph input: mappings are declared at mark level (~nodes / ~edges),
  # so a non-empty global mapping has no well-defined target table.
  graph_input <- inherits(data, "plotit_graph")
  if (graph_input && length(mapping) > 0) {
    cli::cli_abort(c(
      "Graph plots declare aesthetics at the mark level.",
      "x" = "{.arg mapping} must be empty for {.cls plotit_graph} data.",
      "i" = "Use {.code mark_point(data = ~nodes, encode(...))} instead."
    ))
  }
  if (graph_input && !missing(default_color) && !is.null(default_color)) {
    cli::cli_warn(
      "{.arg default_color} is ignored for {.cls plotit_graph} data."
    )
  }

  if (!autofit && (is.null(width) || is.null(height))) {
    cli::cli_abort(
      "When {.code autofit = FALSE}, both {.arg width} and {.arg height} must be provided."
    )
  }

  valid_units <- c("in", "cm", "mm")
  if (!(size_unit %in% valid_units)) {
    cli::cli_abort("{.arg size_unit} must be one of {.val {valid_units}}.")
  }

  if (autofit && (!missing(width) || !missing(height))) {
    cli::cli_warn(
      "{.arg autofit} is {.val TRUE}; {.arg width} and {.arg height} will be ignored."
    )
  }

  if (graph_input) {
    # No global mapping: no discrete heuristic, no default color injection.
    dodge <- dodge %||% 0
    use_default <- FALSE
    p <- ggplot2::ggplot()
  } else {
    if (is.null(dodge)) {
      disc_x <- !is.null(mapping$x) && is_discrete(data, mapping$x)
      disc_y <- !is.null(mapping$y) && is_discrete(data, mapping$y)
      dodge <- if (disc_x || disc_y) 0.8 else 0
    }

    has_color <- "colour" %in% names(mapping)
    has_fill <- "fill" %in% names(mapping)

    # Inject I(default_color) to both colour and fill so that all geoms
    # (points, bars, tiles, ...) pick up the same single-color appearance.
    use_default <- !is.null(default_color) && !has_color && !has_fill
    if (use_default) {
      # Clone mapping to avoid mutating the caller's encode() object
      mapping <- structure(
        utils::modifyList(mapping, list(colour = I(default_color), fill = I(default_color))),
        class = c("plotit_encode", "uneval")
      )
      p <- ggplot2::ggplot(data, mapping) +
        ggplot2::guides(colour = "none", fill = "none")
    } else {
      p <- ggplot2::ggplot(data, mapping)
    }
  }

  meta_labels <- plotit_labels()
  meta <- plotit_metadata(
    autofit = autofit,
    width = if (autofit) NULL else width,
    height = if (autofit) NULL else height,
    unit = size_unit,
    dodge = dodge,
    default_color = if (use_default) default_color else NULL,
    labels = meta_labels
  )

  p <- p + ._theme_default()

  # Curated default colour scales for mapped colour/fill aesthetics
  # (friendly discrete / viridis continuous).  Skipped for the injected
  # single-colour path, which owns its static brand blue.
  if (!graph_input && !use_default) {
    p <- ._attach_default_colour_scale(p, data, mapping)
  }

  # Bake absolute panel dimensions into the ggplot object so every render
  # context (IDE, knitr, pkgdown, export) shares identical content
  # proportions (WYSIWYG; AGENTS.md 3.3.11).
  p <- ._apply_panel_size(p, meta@width, meta@height, meta@unit)

  # Stored on meta, not gg$theme -- patchwork wrapping would shadow $theme
  attr(meta, "plotit_theme_managed") <- TRUE

  out <- plotit_class(gg = p, meta = meta, graph = if (graph_input) data else NULL)
  # Prepend unqualified class so S3 dispatch (e.g. print.plotit) fires
  # before the S7-default print.S7_object.  The namespaced class remains
  # in the vector for S7 method dispatch.
  class(out) <- c("plotit", class(out))
  out
}
