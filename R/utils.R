#' Internal utility functions for plotit
#'
#' @include class.R
#' @noRd
#' @keywords internal
NULL

# Null coalescing operator
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

# Check if a variable (from data) is discrete (factor, character, or logical).
# `var` is expected to be a quosure (as produced by aes()/encode()).
is_discrete <- function(data, var) {
  if (is.null(data) || is.null(var)) {
    return(FALSE)
  }
  tryCatch(
    {
      col <- eval(rlang::quo_get_expr(var), data, baseenv())
      is.factor(col) || is.character(col) || is.logical(col)
    },
    error = function(e) {
      cli::cli_warn("Cannot determine variable type: {e$message}")
      FALSE
    }
  )
}
