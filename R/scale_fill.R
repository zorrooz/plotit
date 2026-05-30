#' Generic for adding a fill scale
#'
#' @param plot A plotit object
#' @param name Legend title for fill aesthetic
#' @param ... Other arguments passed to `ggplot2::scale_fill_discrete` or similar
#' @return Modified plotit object
#' @export
scale_fill <- S7::new_generic(
  "scale_fill",
  "plot",
  function(plot, name = NULL, ...) {
    S7_dispatch()
  }
)

#' @export
S7::method(scale_fill, plotit) <- function(plot, name = NULL, ...) {
  # 取消 default_color 单色映射
  if (!is.null(plot@meta@default_color)) {
    plot@meta@default_color <- NULL
    # 也可以选择移除已有的单色 scale，但此处仅使标记失效
  }

  # 构建 scale_fill_*，默认使用离散色标
  # 若用户指定了 palette 参数，应选用 scale_fill_brewer 等，但最小化这里用 scale_fill_discrete
  args <- list(...)
  if (!is.null(name)) {
    plot@gg <- plot@gg + ggplot2::scale_fill_discrete(name = name)
  } else {
    plot@gg <- plot@gg + ggplot2::scale_fill_discrete(...)
  }
  plot
}
