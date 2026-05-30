# 在 R/split.R 中

#' Generic for wrapping facets
#'
#' @param plot A plotit object.
#' @param ... Variables to facet by, wrapped in `ggplot2::vars()`.
#' @param nrow Number of rows in the facet grid (optional).
#' @param ncol Number of columns in the facet grid (optional).
#' @param scales Should scales be fixed ("fixed"), free ("free"), or free in
#'   one dimension ("free_x", "free_y")?
#' @param ... Additional arguments passed to `ggplot2::facet_wrap()`.
#' @return A modified `plotit` object.
#' @export
split_wrap <- S7::new_generic(
  "split_wrap",
  "plot",
  function(plot, ..., nrow = NULL, ncol = NULL, scales = "fixed") {
    S7_dispatch()
  }
)

#' @export
S7::method(split_wrap, plotit) <- function(
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
