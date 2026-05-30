#' Internal utility functions for plotit
#'
#' @noRd
#' @keywords internal
NULL

# Null coalescing operator
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

# Check if a variable (from data) is discrete (factor, character, or logical)
is_discrete <- function(data, var) {
  if (is.null(data) || is.null(var)) {
    return(FALSE)
  }
  tryCatch(
    {
      col <- eval(ggplot2::quo_get_expr(var), data, parent.frame())
      is.factor(col) || is.character(col) || is.logical(col)
    },
    error = function(e) FALSE
  )
}
