#' Generic for adding a color scale
#'
#' @param plot A plotit object
#' @param name Legend title for color aesthetic
#' @param ... Other arguments passed to the appropriate color scale
#' @return Modified plotit object
#' @export
scale_color <- S7::new_generic(
  "scale_color",
  "plot",
  function(plot, name = NULL, ...) {
    S7_dispatch()
  }
)

#' @export
S7::method(scale_color, plotit) <- function(plot, name = NULL, ...) {
  # 取消 default_color 单色映射
  if (!is.null(plot@meta@default_color)) {
    plot@meta@default_color <- NULL
  }

  # 最小实现：默认离散色标（可根据数据类型扩展）
  plot@gg <- plot@gg + ggplot2::scale_color_discrete(name = name, ...)
  plot
}
