#' Generic for setting axis titles
#'
#' @param plot A plotit object
#' @param x X-axis title (character)
#' @param y Y-axis title (character)
#' @param ... Currently unused
#' @return Modified plotit object
#' @export
label_axis <- S7::new_generic(
  "label_axis",
  "plot",
  function(plot, x = NULL, y = NULL, ...) {
    S7_dispatch()
  }
)

#' @export
S7::method(label_axis, plotit) <- function(plot, x = NULL, y = NULL, ...) {
  if (!is.null(x)) {
    plot@meta@labels@x <- x
    plot@gg <- plot@gg + ggplot2::labs(x = plot@meta@labels@x)
  }
  if (!is.null(y)) {
    plot@meta@labels@y <- y
    plot@gg <- plot@gg + ggplot2::labs(y = plot@meta@labels@y)
  }
  plot
}
