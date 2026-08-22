#' @include class.R utils.R style.R
NULL

# Convert user-specified size unit to inches
#' Convert user-specified size unit to inches.
#' @noRd
#' @keywords internal
.unit_to_inches <- function(x, unit) {
  x / switch(unit,
    "in" = 1,
    "cm" = 2.54,
    "mm" = 25.4
  )
}

# ---- format ----
# Suppress S7 text output so pkgdown reference examples capture rendered plots.
#' @noRd
S7::method(format, plotit_class) <- function(x, ...) ""
S7::method(format, plotit_composite) <- function(x, ...) ""

# ---- internal render routing ----
# Route plot rendering based on context.
# Always renders to the device so evaluate/pkgdown/R CMD check
# can capture the plot output.  Both branches are identical;
# kept separate in case one needs context-specific logic later.
#' @noRd
#' @keywords internal
._render_plotit <- function(x) {
  print(x@gg)
  invisible(x)
}

# ---- pkgdown_print ----
# pkgdown evaluates @examples via evaluate::evaluate(), which calls
# pkgdown_print(value) as the output_handler `value` callback.  S7 objects
# hit pkgdown_print.default() → print.S7_object() → str.S7_object(), which
# dumps the full ggproto tree.  Intercept with S3 methods that render the
# plot to the device so evaluate records it, then return invisible to
# suppress the text dump.
#' @exportS3Method pkgdown::pkgdown_print
pkgdown_print.plotit <- function(x, visible = TRUE) {
  if (!visible) {
    return(invisible())
  }
  ._print_render(x)
}

#' @exportS3Method pkgdown::pkgdown_print
pkgdown_print.plotit_composite <- function(x, visible = TRUE) {
  if (!visible) {
    return(invisible())
  }
  ._apply_annotations(x) |> print()
  invisible()
}

# ---- print ----
#' Print a plotit object (automatically render the plot)
#'
#' @param x A plotit object
#' @param ... Additional arguments (not used)
#' @return The plotit object (invisibly)
#' @noRd
S7::method(print, plotit_class) <- function(x, ...) {
  # Fall back to the default theme when the plot was built without one.
  needs_theme <- is.null(attr(x@meta, "plotit_theme_managed", exact = TRUE)) ||
    length(x@gg$theme) == 0
  if (needs_theme) {
    x@gg <- x@gg + .theme_default()
    attr(x@meta, "plotit_theme_managed") <- TRUE
  }

  # Apply lazy labels on every print (not just the first)
  x <- ._sync_labels(x)

  dev_opt <- getOption("plotit.device", "default")
  if (interactive() && !is.null(x@meta@width) && !is.null(x@meta@height) && !is.null(dev_opt)) {
    if (inherits(x@gg, "patchwork")) {
      gt <- patchwork::patchworkGrob(x@gg)
    } else {
      gt <- ._build_fixed_gtable(x@gg, x@meta@width, x@meta@height, x@meta@unit)
    }
    pw <- grid::convertWidth(
      sum(gt$widths) + ggplot2::unit(1, "mm"), "inches",
      valueOnly = TRUE
    )
    ph <- grid::convertHeight(
      sum(gt$heights) + ggplot2::unit(1, "mm"), "inches",
      valueOnly = TRUE
    )
    use_rstudio <- isTRUE(dev_opt == "rstudio")
    grDevices::dev.new(width = pw, height = ph, noRStudioGD = !use_rstudio)
    grid::grid.draw(gt)
    invisible(x)
  } else {
    ._render_plotit(x)
  }
}

# S3 print method — reaches knitr/vignette contexts where S7 dispatch doesn't fire
#' @export
print.plotit <- function(x, ...) {
  needs_theme <- is.null(attr(x@meta, "plotit_theme_managed", exact = TRUE)) ||
    length(x@gg$theme) == 0
  if (needs_theme) {
    x@gg <- x@gg + .theme_default()
    attr(x@meta, "plotit_theme_managed") <- TRUE
  }
  x <- ._sync_labels(x)
  ._render_plotit(x)
}

# ---- knit_print ----
# S3 methods for knitr to capture plotit plots in vignettes / R Markdown.
# Renders the underlying ggplot to knitr's active device.

# Shared knit_print / pkgdown_print path: sync labels, render, suppress text.
#' @noRd
#' @keywords internal
._print_render <- function(x) {
  x <- ._sync_labels(x)
  ._render_plotit(x)
}

#' @exportS3Method knitr::knit_print
knit_print.plotit <- function(x, ...) {
  ._print_render(x)
}

#' @exportS3Method knitr::knit_print
knit_print.plotit_composite <- function(x, ...) {
  x@gg <- ._apply_annotations(x)
  print(x@gg)
  invisible(x)
}

# ---- export ----
#' Export a plotit object to a file
#'
#' @param plot A plotit object.
#' @param filename Output filename (extension determines device, e.g., ".pdf").
#' @param width Output width (if NULL, uses meta then package default).
#' @param height Output height (if NULL, uses meta then package default).
#' @param dpi Resolution for raster formats (default 300).
#' @param device Graphics device to use (if NULL, auto-detected from filename).
#' @param ... Additional arguments passed to `ggplot2::ggsave()`.
#' @return Invisibly, the original `plotit` object.
#' @examples
#' p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
#' export(p, tempfile(fileext = ".png"), dpi = 72)
#' @export
export <- S7::new_generic(
  "export",
  "plot",
  function(
    plot,
    filename,
    width = NULL,
    height = NULL,
    dpi = 300,
    device = NULL,
    ...
  ) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(export, plotit_class) <- function(
  plot,
  filename,
  width = NULL,
  height = NULL,
  dpi = 300,
  device = NULL,
  ...
) {
  if (is.null(filename) || identical(filename, "")) {
    cli::cli_abort("{.arg filename} must be a non-empty file path.")
  }

  meta_unit <- plot@meta@unit %||% getOption("plotit.default_unit", "in")

  # Apply lazy labels before measuring / exporting
  plot <- ._sync_labels(plot)

  if (isTRUE(plot@meta@autofit)) {
    final_plot <- plot@gg
    final_width <- if (is.null(width)) {
      getOption("plotit.default_width", 7)
    } else {
      .unit_to_inches(width, meta_unit)
    }
    final_height <- if (is.null(height)) {
      getOption("plotit.default_height", 5)
    } else {
      .unit_to_inches(height, meta_unit)
    }
  } else {
    if (inherits(plot@gg, "patchwork")) {
      gt <- patchwork::patchworkGrob(plot@gg)
    } else {
      gt <- ._build_fixed_gtable(plot@gg, plot@meta@width, plot@meta@height, plot@meta@unit)
    }
    final_plot <- if (inherits(plot@gg, "patchwork")) plot@gg else gt
    final_width <- if (is.null(width)) {
      grid::convertWidth(sum(gt$widths) + ggplot2::unit(1, "mm"), "in", valueOnly = TRUE)
    } else {
      .unit_to_inches(width, meta_unit)
    }
    final_height <- if (is.null(height)) {
      grid::convertHeight(sum(gt$heights) + ggplot2::unit(1, "mm"), "in", valueOnly = TRUE)
    } else {
      .unit_to_inches(height, meta_unit)
    }
  }

  ggplot2::ggsave(
    filename = filename,
    plot = final_plot,
    width = final_width,
    height = final_height,
    dpi = dpi,
    device = device,
    units = "in",
    bg = "white",
    ...
  )

  invisible(plot)
}
