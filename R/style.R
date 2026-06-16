#' Build default plotit theme
#'
#' @include class.R utils.R
#' @return A ggplot2 theme object.
#' @keywords internal
plotit_theme_default <- function(base_size = NULL, base_family = NULL) {
  ggplot2::theme_minimal(
    base_size = base_size %||% 11,
    base_family = base_family %||% ""
  ) + ggplot2::theme(
      # 透明背景（固定面板尺寸时多余区域透明）
      plot.background = ggplot2::element_rect(fill = NA, colour = NA),
      panel.background = ggplot2::element_rect(fill = NA, colour = NA),
      legend.background = ggplot2::element_rect(fill = NA, colour = NA),
      legend.key = ggplot2::element_rect(fill = NA, colour = NA),
      legend.box.background = ggplot2::element_rect(fill = NA, colour = NA),
      legend.box.spacing = ggplot2::unit(0, "cm"),
      strip.background = ggplot2::element_rect(fill = NA, colour = NA),
      # 仅保留主要网格线
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(
        colour = "grey92", linewidth = 0.3
      ),
      # 轴线可见
      axis.line = ggplot2::element_line(colour = "grey50", linewidth = 0.3),
      axis.ticks = ggplot2::element_line(colour = "grey50", linewidth = 0.3),
      # 图例右侧
      legend.position = "right",
      # 标题加粗
      plot.title = ggplot2::element_text(face = "bold", hjust = 0),
      plot.subtitle = ggplot2::element_text(hjust = 0),
      # 坐标轴标题略大
      axis.title = ggplot2::element_text(size = ggplot2::rel(0.9)),
      axis.text = ggplot2::element_text(size = ggplot2::rel(0.8))
    )
}

#' Apply a theme to a plotit object
#'
#' @param plot A plotit object.
#' @param theme A ggplot2 theme object (e.g., `theme_minimal()`).
#'   If `NULL`, the default plotit theme is applied.
#' @param ... Additional arguments passed to `ggplot2::theme()`.
#' @param base_size Base font size for the theme.
#' @param base_family Base font family for the theme.
#' @return Modified plotit object.
#' @export
style <- S7::new_generic(
  "style",
  "plot",
  function(plot, theme = NULL, ..., base_size = NULL, base_family = NULL) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(style, plotit_class) <- function(
  plot,
  theme = NULL,
  ...,
  base_size = NULL,
  base_family = NULL
) {
  # 若默认主题已应用且未传入新 theme/base 参数，跳过以避免重复叠加
  has_applied <- !is.null(attr(plot@meta, "plotit_applied", exact = TRUE))
  no_new_theme <- is.null(theme) && is.null(base_size) &&
    is.null(base_family) && ...length() == 0L
  if (has_applied && no_new_theme) return(plot)

  if (is.null(theme)) {
    theme <- plotit_theme_default()
  }
  if (!is.null(base_size) || !is.null(base_family)) {
    theme <- theme + ggplot2::theme(
      text = ggplot2::element_text(
        size = base_size %||% ggplot2::rel(1),
        family = base_family %||% ""
      )
    )
  }
  plot@gg <- plot@gg + theme + ggplot2::theme(...)
  attr(plot@meta, "plotit_applied") <- TRUE
  plot
}
