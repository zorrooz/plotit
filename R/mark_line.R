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
    S7_dispatch()
  }
)

#' @export
S7::method(mark_line, plotit) <- function(
  plot,
  mapping = NULL,
  data = NULL,
  ...
) {
  plot@gg <- plot@gg + ggplot2::geom_line(mapping = mapping, data = data, ...)
  plot
}
