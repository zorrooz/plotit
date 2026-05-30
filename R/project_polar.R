#' Generic for polar coordinate projection
#'
#' @param plot A plotit object
#' @param theta Variable to map to angle ("x" or "y")
#' @param start Starting angle in radians
#' @param direction 1 for clockwise, -1 for anti-clockwise
#' @param clip Should drawing be clipped to the panel? ("on" or "off")
#' @param ... Other arguments (currently unused)
#' @return Modified plotit object
#' @export
project_polar <- S7::new_generic(
  "project_polar",
  "plot",
  function(plot, theta = "x", start = 0, direction = 1, clip = "on", ...) {
    S7_dispatch()
  }
)

#' @export
S7::method(project_polar, plotit) <- function(
  plot,
  theta = "x",
  start = 0,
  direction = 1,
  clip = "on",
  ...
) {
  plot@gg <- plot@gg +
    ggplot2::coord_polar(
      theta = theta,
      start = start,
      direction = direction,
      clip = clip
    )
  plot
}
