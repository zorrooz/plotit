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
#'   color/fill aesthetic is present in `mapping`.
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
  default_color = "black"
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

  # 始终验证 size_unit（不受 autofit 影响，属于包层自约束）
  valid_units <- c("in", "cm", "mm")
  if (!(size_unit %in% valid_units)) {
    cli::cli_abort("{.arg size_unit} must be one of {.val {valid_units}}.")
  }

  # 启发式 dodge
  if (is.null(dodge)) {
    disc_x <- !is.null(mapping$x) && is_discrete(data, mapping$x)
    disc_y <- !is.null(mapping$y) && is_discrete(data, mapping$y)
    dodge <- if (disc_x || disc_y) 0.8 else 0
  }

  has_color <- "colour" %in% names(mapping)
  has_fill <- "fill" %in% names(mapping)

  # 单色映射：如果没有颜色/填充映射，使用 default_color 并隐藏图例
  use_default <- !is.null(default_color) && !has_color && !has_fill
  if (use_default) {
    mapping$colour <- I(default_color)
    p <- ggplot2::ggplot(data, mapping) + ggplot2::guides(colour = "none")
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

  # 应用包级默认主题
  p <- p + .theme_default()

  # 标记已应用默认主题（存于 meta 而非 gg$theme，因后续 patchwork 包装会遮蔽 $theme）
  attr(meta, "plotit_theme_managed") <- TRUE

  # 若 patchwork 可用且非 autofit 模式，固定面板尺寸（参考 tidyplots 方案）
  if (!autofit && requireNamespace("patchwork", quietly = TRUE)) {
    p <- p + patchwork::plot_layout(
      widths  = ggplot2::unit(width,  size_unit),
      heights = ggplot2::unit(height, size_unit)
    )
  }

  plotit_class(gg = p, meta = meta)
}


