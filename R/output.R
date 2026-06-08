#' @include class.R utils.R style.R
NULL

# ---- print ----
#' Print a plotit object (automatically render the plot)
#'
#' @param x A plotit object
#' @param ... Additional arguments (not used)
#' @return The plotit object (invisibly)
#' @noRd
S7::method(print, plotit_class) <- function(x, ...) {
  # 兜底：若 plotit_applied 标记不存在（如绕过 plotit() 直接构造 S7 对象），补注默认主题
  if (is.null(attr(x@gg$theme, "plotit_applied", exact = TRUE))) {
    x@gg <- x@gg + plotit_theme_default()
    attr(x@gg$theme, "plotit_applied") <- TRUE
  }
  # 若有指定尺寸，以指定尺寸打开设备（dev.new 始终使用英寸）
  if (!is.null(x@meta@width) && !is.null(x@meta@height)) {
    unit_factor <- switch(x@meta@unit %||% "in",
      "in" = 1,
      "cm" = 2.54,
      "mm" = 25.4
    )
    grDevices::dev.new(
      width = x@meta@width / unit_factor,
      height = x@meta@height / unit_factor,
      noRStudioGD = TRUE
    )
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
  final_width <- width %||%
    plot@meta@width %||%
    getOption("plotit.default_width", 7)
  final_height <- height %||%
    plot@meta@height %||%
    getOption("plotit.default_height", 5)

  if (isTRUE(plot@meta@autofit)) {
    final_width <- NULL
    final_height <- NULL
  }

  unit <- plot@meta@unit %||% getOption("plotit.default_unit", "in")

  ggplot2::ggsave(
    filename = filename,
    plot = plot@gg,
    width = final_width,
    height = final_height,
    dpi = dpi,
    device = device,
    units = unit,
    ...
  )

  invisible(plot)
}
