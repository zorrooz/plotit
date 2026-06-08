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
    unit = if (autofit) NULL else size_unit,
    dodge = dodge,
    default_color = if (use_default) default_color else NULL,
    labels = meta_labels
  )

  # 应用包级默认主题并标记，供 print() 判断是否重复叠加
  p <- p + plotit_theme_default()
  attr(p$theme, "plotit_applied") <- TRUE

  plotit_class(gg = p, meta = meta)
}

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
  if (
    isTRUE(getOption("plotit.preview_lock", FALSE)) &&
      !is.null(x@meta@width) &&
      !is.null(x@meta@height)
  ) {
    grDevices::dev.new(
      width = x@meta@width,
      height = x@meta@height,
      noRStudioGD = TRUE
    )
    print(x@gg)
  } else {
    print(x@gg)
  }
  invisible(x)
}

#' Modify output dimensions
#'
#' @param plot A plotit object.
#' @param width,height Numeric; new dimensions.
#' @param unit Character; new unit ("in", "cm", "mm").
#' @return Modified plotit object.
#' @export
set_size <- S7::new_generic("set_size", "plot")
S7::method(set_size, plotit_class) <- function(
  plot,
  width = NULL,
  height = NULL,
  unit = NULL
) {
  if (!is.null(width)) {
    plot@meta@width <- width
  }
  if (!is.null(height)) {
    plot@meta@height <- height
  }
  if (!is.null(unit)) {
    valid_units <- c("in", "cm", "mm")
    if (!(unit %in% valid_units)) {
      cli::cli_abort("{.arg unit} must be one of {.val {valid_units}}.")
    }
    plot@meta@unit <- unit
  }
  plot
}
