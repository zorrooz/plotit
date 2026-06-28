#' @include class.R
NULL

#' Create aesthetic mapping
#'
#' @param ... List of aesthetic mappings (e.g., x = wt, y = mpg, color = cyl).
#' @return An object of class "plotit_encode" (a list).
#' @examples
#' encode(x = mpg, y = wt)
#' encode(x = Sepal.Width, y = Sepal.Length, colour = Species)
#' encode() # empty mapping
#' @export
encode <- function(...) {
  mapping <- ggplot2::aes(...)
  class(mapping) <- c("plotit_encode", class(mapping))
  mapping
}
