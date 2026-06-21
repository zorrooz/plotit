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
    mapping$colour <- I(default_color)
    mapping$fill <- I(default_color)
    p <- ggplot2::ggplot(data, mapping) +
      ggplot2::guides(colour = "none", fill = "none")
  } else {
    p <- ggplot2::ggplot(data, mapping)
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

  p <- p + .theme_default()

  # Stored on meta, not gg$theme -- patchwork wrapping would shadow $theme
  attr(meta, "plotit_theme_managed") <- TRUE

  if (!autofit) {
    p <- p + patchwork::plot_layout(
      widths  = ggplot2::unit(width, size_unit),
      heights = ggplot2::unit(height, size_unit)
    )
  }

  plotit_class(gg = p, meta = meta)
}
