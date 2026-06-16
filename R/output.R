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
  # 兜底：若 plotit_theme_managed 标记不存在（如绕过 plotit() 直接构造 S7 对象），补注默认主题
  if (is.null(attr(x@meta, "plotit_theme_managed", exact = TRUE))) {
    x@gg <- x@gg + .theme_default()
    attr(x@meta, "plotit_theme_managed") <- TRUE
  }

  has_patchwork <- inherits(x@gg, "patchwork")

  if (interactive() && !is.null(x@meta@width) && !is.null(x@meta@height)) {
    if (has_patchwork) {
      # 通过 patchworkGrob 构建完整 gtable，测量精确总尺寸（参考 tidyplots）
      gt <- patchwork::patchworkGrob(x@gg)
      pw <- grid::convertWidth(
        sum(gt$widths) + ggplot2::unit(1, "mm"), "inches", valueOnly = TRUE)
      ph <- grid::convertHeight(
        sum(gt$heights) + ggplot2::unit(1, "mm"), "inches", valueOnly = TRUE)
      grDevices::dev.new(width = pw, height = ph, noRStudioGD = TRUE)
    } else {
      # 无 patchwork：按 meta 尺寸换算后打开设备
      units_per_inch <- switch(x@meta@unit %||% "in",
        "in" = 1,
        "cm" = 2.54,
        "mm" = 25.4
      )
      grDevices::dev.new(
        width  = x@meta@width  / units_per_inch,
        height = x@meta@height / units_per_inch,
        noRStudioGD = TRUE
      )
    }
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

  # 若 patchwork 可用，从 gtable 测量总尺寸（面板+装饰+1mm）
  # 这比 meta 面板尺寸更精确——避免裁切；用户显式参数可覆盖
  has_patchwork <- requireNamespace("patchwork", quietly = TRUE) &&
    inherits(plot@gg, "patchwork")
  if (has_patchwork) {
    gt <- patchwork::patchworkGrob(plot@gg)
    # 用户显式参数优先，未传则用 gtable 测量值（已是英寸）
    final_width <- if (is.null(width))
      grid::convertWidth(
        sum(gt$widths) + ggplot2::unit(1, "mm"), "in", valueOnly = TRUE)
    else
      width / switch(meta_unit, "in" = 1, "cm" = 2.54, "mm" = 25.4)
    final_height <- if (is.null(height))
      grid::convertHeight(
        sum(gt$heights) + ggplot2::unit(1, "mm"), "in", valueOnly = TRUE)
    else
      height / switch(meta_unit, "in" = 1, "cm" = 2.54, "mm" = 25.4)
  } else {
    # 无 patchwork：按 meta 面板尺寸 + 用户回退
    final_width <- width %||%
      plot@meta@width %||%
      getOption("plotit.default_width", 7)
    final_height <- height %||%
      plot@meta@height %||%
      getOption("plotit.default_height", 5)

    if (isTRUE(plot@meta@autofit)) {
      if (is.null(width))  final_width  <- NA
      if (is.null(height)) final_height <- NA
    }
    if (!is.na(final_width) && !is.na(final_height)) {
      units_per_inch <- switch(meta_unit, "in" = 1, "cm" = 2.54, "mm" = 25.4)
      final_width  <- final_width  / units_per_inch
      final_height <- final_height / units_per_inch
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
