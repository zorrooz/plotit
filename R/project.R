#' @include class.R
NULL

#' Generic for polar coordinate projection
#'
#' @param plot A plotit object
#' @param theta Variable to map to angle ("x" or "y")
#' @param start Starting angle in radians
#' @param direction 1 for clockwise, -1 for anti-clockwise
#' @param clip Should drawing be clipped to the panel? ("on" or "off")
#' @param ... Other arguments passed to `coord_polar`
#' @return Modified plotit object
#' @export
project_polar <- S7::new_generic(
  "project_polar",
  "plot",
  function(plot, theta = "x", start = 0, direction = 1, clip = "on", ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(project_polar, plotit_class) <- function(
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
      clip = clip,
      ...
    )
  plot
}

#' Generic for Cartesian coordinate projection
#'
#' @param plot A plotit object
#' @param xlim,ylim Axis limits for the Cartesian coordinate system
#' @param expand If `TRUE`, add expansion; if `FALSE`, no expansion
#' @param clip Should drawing be clipped to the panel? ("on" or "off")
#' @param ... Other arguments passed to `coord_cartesian`
#' @return Modified plotit object
#' @export
project_cartesian <- S7::new_generic(
  "project_cartesian",
  "plot",
  function(plot, xlim = NULL, ylim = NULL, expand = TRUE, clip = "on", ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(project_cartesian, plotit_class) <- function(
  plot,
  xlim = NULL,
  ylim = NULL,
  expand = TRUE,
  clip = "on",
  ...
) {
  plot@gg <- plot@gg +
    ggplot2::coord_cartesian(
      xlim = xlim,
      ylim = ylim,
      expand = expand,
      clip = clip,
      ...
    )
  plot
}

#' Generic for flipped Cartesian coordinates
#'
#' @param plot A plotit object
#' @param xlim,ylim Axis limits
#' @param expand If `TRUE`, add expansion; if `FALSE`, no expansion
#' @param clip Should drawing be clipped to the panel? ("on" or "off")
#' @param ... Other arguments passed to `coord_flip`
#' @return Modified plotit object
#' @export
project_flip <- S7::new_generic(
  "project_flip",
  "plot",
  function(plot, xlim = NULL, ylim = NULL, expand = TRUE, clip = "on", ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(project_flip, plotit_class) <- function(
  plot,
  xlim = NULL,
  ylim = NULL,
  expand = TRUE,
  clip = "on",
  ...
) {
  plot@gg <- plot@gg +
    ggplot2::coord_flip(
      xlim = xlim,
      ylim = ylim,
      expand = expand,
      clip = clip,
      ...
    )
  plot
}
