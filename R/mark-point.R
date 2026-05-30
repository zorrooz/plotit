#' Generic for adding a point layer
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param ... Other arguments passed to `geom_point`
#' @return Modified plotit object
#' @export
mark_point <- new_generic(
  "mark_point",
  "plot",
  function(plot, mapping = NULL, data = NULL, ...) {
    S7_dispatch()
  }
)

#' @export
method(mark_point, plotit) <- function(plot, mapping = NULL, data = NULL, ...) {
  plot@gg <- plot@gg + ggplot2::geom_point(mapping = mapping, data = data, ...)
  plot
}
