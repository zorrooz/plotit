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
# Uses rlang::eval_tidy for proper data-masking (avoids clashes when column
# names shadow base R functions like 'mean' or 'list').
is_discrete <- function(data, var) {
  if (is.null(data) || is.null(var)) {
    return(FALSE)
  }
  tryCatch(
    {
      col <- rlang::eval_tidy(var, data)
      is.factor(col) || is.character(col) || is.logical(col)
    },
    error = function(e) {
      cli::cli_warn("Cannot determine variable type: {e$message}")
      FALSE
    }
  )
}
