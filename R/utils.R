`%>%` <- dplyr::`%>%`

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
      col <- rlang::eval_tidy(var, data = data)
      is.factor(col) || is.character(col) || is.logical(col)
    },
    error = function(e) FALSE
  )
}
