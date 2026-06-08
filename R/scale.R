#' @include class.R utils.R
NULL

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
  function(plot, name = ggplot2::waiver(), ...) {
    S7::S7_dispatch()
  }
)

# 撤销 plot() 中因 default_color 注入的 I(color) 和 guides(colour = "none")
# plot@gg$mapping 是 ?ggplot 文档中公开的可访问字段
.reset_default_color <- function(plot) {
  if (is.null(plot@meta@default_color)) return(plot)
  plot@gg$mapping$colour <- NULL
  plot@gg <- plot@gg + ggplot2::guides(colour = ggplot2::waiver())
  plot@meta@default_color <- NULL
  plot
}

#' @export
S7::method(scale_color, plotit_class) <- function(plot, name = ggplot2::waiver(), ...) {
  plot <- .reset_default_color(plot)
  plot@gg <- plot@gg + ggplot2::scale_color_discrete(name = name, ...)
  plot
}

#' Generic for adding a fill scale
#'
#' @param plot A plotit object
#' @param name Legend title for fill aesthetic
#' @param ... Other arguments passed to the appropriate fill scale
#' @return Modified plotit object
#' @export
scale_fill <- S7::new_generic(
  "scale_fill",
  "plot",
  function(plot, name = ggplot2::waiver(), ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(scale_fill, plotit_class) <- function(plot, name = ggplot2::waiver(), ...) {
  plot <- .reset_default_color(plot)
  plot@gg <- plot@gg + ggplot2::scale_fill_discrete(name = name, ...)
  plot
}

#' Generic for setting x-axis scale
#'
#' @param plot A plotit object
#' @param name Axis title (use [label_axis()] for more control)
#' @param discrete If `TRUE`, use discrete scale; if `FALSE`, use continuous.
#'   If `NULL`, auto-detected from data type.
#' @param trans Transformation to apply (e.g. "log10", "sqrt", "reverse").
#'   Only used when `discrete = FALSE`.
#' @param limits Axis limits
#' @param breaks Axis break positions
#' @param ... Other arguments passed to `scale_x_continuous` or `scale_x_discrete`
#' @return Modified plotit object
#' @export
scale_x <- S7::new_generic(
  "scale_x",
  "plot",
  function(plot, name = NULL, discrete = NULL, trans = NULL,
           limits = NULL, breaks = NULL, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(scale_x, plotit_class) <- function(plot, name = NULL, discrete = NULL,
                                              trans = NULL, limits = NULL,
                                              breaks = NULL, ...) {
  if (is.null(discrete)) {
    discrete <- is_discrete(plot@gg$data, plot@gg$mapping$x)
  }
  if (discrete) {
    plot@gg <- plot@gg + ggplot2::scale_x_discrete(name = name, limits = limits, ...)
  } else {
    args <- list(name = name, limits = limits, breaks = breaks, ...)
    if (!is.null(trans)) args$trans <- trans
    plot@gg <- plot@gg + do.call(ggplot2::scale_x_continuous, args)
  }
  plot
}

#' Generic for setting y-axis scale
#'
#' @param plot A plotit object
#' @param name Axis title (use [label_axis()] for more control)
#' @param discrete If `TRUE`, use discrete scale; if `FALSE`, use continuous.
#'   If `NULL`, auto-detected from data type.
#' @param trans Transformation to apply (e.g. "log10", "sqrt", "reverse").
#'   Only used when `discrete = FALSE`.
#' @param limits Axis limits
#' @param breaks Axis break positions
#' @param ... Other arguments passed to `scale_y_continuous` or `scale_y_discrete`
#' @return Modified plotit object
#' @export
scale_y <- S7::new_generic(
  "scale_y",
  "plot",
  function(plot, name = NULL, discrete = NULL, trans = NULL,
           limits = NULL, breaks = NULL, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(scale_y, plotit_class) <- function(plot, name = NULL, discrete = NULL,
                                              trans = NULL, limits = NULL,
                                              breaks = NULL, ...) {
  if (is.null(discrete)) {
    discrete <- is_discrete(plot@gg$data, plot@gg$mapping$y)
  }
  if (discrete) {
    plot@gg <- plot@gg + ggplot2::scale_y_discrete(name = name, limits = limits, ...)
  } else {
    args <- list(name = name, limits = limits, breaks = breaks, ...)
    if (!is.null(trans)) args$trans <- trans
    plot@gg <- plot@gg + do.call(ggplot2::scale_y_continuous, args)
  }
  plot
}
