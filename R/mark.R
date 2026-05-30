#' Generic for adding a point layer
#'
#' @include class.R
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param ... Other arguments passed to `geom_point`
#' @return Modified plotit object
#' @export
mark_point <- S7::new_generic(
  "mark_point",
  "plot",
  function(plot, mapping = NULL, data = NULL, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_point, plotit_class) <- function(plot, mapping = NULL, data = NULL, ...) {
  plot@gg <- plot@gg + ggplot2::geom_point(mapping = mapping, data = data, ...)
  plot
}

#' Generic for adding a line layer
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param ... Other arguments passed to `geom_line`
#' @return Modified plotit object
#' @export
mark_line <- S7::new_generic(
  "mark_line",
  "plot",
  function(plot, mapping = NULL, data = NULL, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_line, plotit_class) <- function(plot, mapping = NULL, data = NULL, ...) {
  plot@gg <- plot@gg + ggplot2::geom_line(mapping = mapping, data = data, ...)
  plot
}

#' Generic for adding a bar layer
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param ... Other arguments passed to `geom_bar`
#' @return Modified plotit object
#' @export
mark_bar <- S7::new_generic(
  "mark_bar",
  "plot",
  function(plot, mapping = NULL, data = NULL, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_bar, plotit_class) <- function(plot, mapping = NULL, data = NULL, ...) {
  plot@gg <- plot@gg + ggplot2::geom_bar(mapping = mapping, data = data, ...)
  plot
}

#' Generic for adding a boxplot layer
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param ... Other arguments passed to `geom_boxplot`
#' @return Modified plotit object
#' @export
mark_boxplot <- S7::new_generic(
  "mark_boxplot",
  "plot",
  function(plot, mapping = NULL, data = NULL, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_boxplot, plotit_class) <- function(plot, mapping = NULL, data = NULL, ...) {
  plot@gg <- plot@gg + ggplot2::geom_boxplot(mapping = mapping, data = data, ...)
  plot
}
