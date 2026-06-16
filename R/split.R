#' @include class.R
NULL

#' Generic for wrapping facets
#'
#' @param plot A plotit object.
#' @param ... Variables to facet by (passed directly, e.g., `Species`).
#' @param nrow Number of rows in the facet grid (optional).
#' @param ncol Number of columns in the facet grid (optional).
#' @param scales Should scales be fixed ("fixed"), free ("free"), or free in
#'   one dimension ("free_x", "free_y")?
#' @return A modified `plotit` object.
#' @export
split_wrap <- S7::new_generic(
  "split_wrap",
  "plot",
  function(plot, ..., nrow = NULL, ncol = NULL, scales = "fixed") {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(split_wrap, plotit_class) <- function(
  plot,
  ...,
  nrow = NULL,
  ncol = NULL,
  scales = "fixed"
) {
  plot@gg <- plot@gg +
    ggplot2::facet_wrap(
      ggplot2::vars(...),
      nrow = nrow,
      ncol = ncol,
      scales = scales
    )
  plot
}

#' Generic for grid facets
#'
#' @param plot A plotit object.
#' @param ... Variables passed to `ggplot2::vars()` for the rows.
#'   Use `rows` and `cols` for explicit control.
#' @param rows,cols Variables to facet by, wrapped in `ggplot2::vars()`.
#' @param scales Should scales be fixed ("fixed"), free ("free"), or free in
#'   one dimension ("free_x", "free_y")?
#' @param space Should the space be fixed ("fixed"), free ("free"), or free in
#'   one dimension ("free_x", "free_y")?
#' @return A modified `plotit` object.
#' @export
split_grid <- S7::new_generic(
  "split_grid",
  "plot",
  function(plot, ..., rows = NULL, cols = NULL,
           scales = "fixed", space = "fixed") {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(split_grid, plotit_class) <- function(
  plot,
  ...,
  rows = NULL,
  cols = NULL,
  scales = "fixed",
  space = "fixed"
) {
  if (...length() > 0) {
    if (!is.null(rows)) {
      cli::cli_warn("Both {.code ...} and {.code rows} provided; {.code ...} will be used.")
    }
    rows <- ggplot2::vars(...)
  }
  plot@gg <- plot@gg +
    ggplot2::facet_grid(
      rows = rows,
      cols = cols,
      scales = scales,
      space = space
    )
  plot
}
