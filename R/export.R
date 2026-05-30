#' Export a plotit object to a file
#'
#' @include class.R utils.R
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
  # 确定最终尺寸
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

  # 确定单位
  unit <- plot@meta@unit %||% getOption("plotit.default_unit", "in")

  # 确定设备（如果未给出，则由 ggsave 根据扩展名自动判断）
  # 直接调用 ggsave
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
