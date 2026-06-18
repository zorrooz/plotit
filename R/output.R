#' @include class.R utils.R style.R
NULL

# Convert user-specified size unit to inches
.unit_to_inches <- function(x, unit) {
  x / switch(unit,
    "in" = 1,
    "cm" = 2.54,
    "mm" = 25.4
  )
}

# ---- print ----
#' Print a plotit object (automatically render the plot)
#'
#' @param x A plotit object
#' @param ... Additional arguments (not used)
#' @return The plotit object (invisibly)
#' @noRd
S7::method(print, plotit_class) <- function(x, ...) {
  if (is.null(attr(x@meta, "plotit_theme_managed", exact = TRUE))) {
    x@gg <- x@gg + .theme_default()
    attr(x@meta, "plotit_theme_managed") <- TRUE
  }

  if (interactive() && !is.null(x@meta@width) && !is.null(x@meta@height)) {
    gt <- patchwork::patchworkGrob(x@gg)
    pw <- grid::convertWidth(
      sum(gt$widths) + ggplot2::unit(1, "mm"), "inches",
      valueOnly = TRUE
    )
    ph <- grid::convertHeight(
      sum(gt$heights) + ggplot2::unit(1, "mm"), "inches",
      valueOnly = TRUE
    )
    grDevices::dev.new(width = pw, height = ph, noRStudioGD = TRUE)
  }
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

  if (isTRUE(plot@meta@autofit)) {
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
    gt <- patchwork::patchworkGrob(plot@gg)
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

  gg <- plot@gg

  ggplot2::ggsave(
    filename = filename,
    plot = gg,
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
