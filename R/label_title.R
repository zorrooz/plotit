#' Generic for setting plot title
#'
#' @param plot A plotit object
#' @param text Title text
#' @param ... Currently unused
#' @return Modified plotit object
#' @export
label_title <- S7::new_generic(
  "label_title",
  "plot",
  function(plot, text = NULL, ...) {
    S7_dispatch()
  }
)

#' @export
S7::method(label_title, plotit) <- function(plot, text = NULL, ...) {
  plot@meta@labels@title <- text
  plot@gg <- plot@gg + ggplot2::labs(title = plot@meta@labels@title)
  plot
}
