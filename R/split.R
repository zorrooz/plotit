#' @include class.R
NULL

#' Generic for wrapping facets
#'
#' @param plot A plotit object.
#' @param ... Unnamed arguments are faceting variables (e.g. `Species`);
#'   named arguments (`labeller`, `strip.position`, `dir`, `drop`, ...)
#'   are passed through to [ggplot2::facet_wrap()].
#' @param nrow Number of rows in the facet grid (optional).
#' @param ncol Number of columns in the facet grid (optional).
#' @param scales Should scales be fixed ("fixed"), free ("free"), or free in
#'   one dimension ("free_x", "free_y")?
#' @return A modified `plotit` object.
#' @examples
#' plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
#'   mark_point() |>
#'   split_wrap(Species, ncol = 3)
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
  dots <- rlang::enquos(...)
  dot_names <- names(dots) %||% character(length(dots))
  is_named <- nzchar(dot_names)
  # Unnamed args -> facet variables (quosures, passed to vars())
  facet_quos <- dots[!is_named]
  # Named args -> evaluated and passed through to facet_wrap()
  passthrough <- lapply(dots[is_named], rlang::eval_tidy)

  args <- c(
    list(facets = ggplot2::vars(!!!facet_quos)),
    list(nrow = nrow, ncol = ncol, scales = scales),
    passthrough
  )
  plot@gg <- plot@gg + do.call(ggplot2::facet_wrap, args)
  plot
}

#' Generic for grid facets
#'
#' @param plot A plotit object.
#' @param ... Unnamed arguments are shorthand for `rows` (e.g. `Species`
#'   becomes `rows = vars(Species)`). Named arguments (`labeller`,
#'   `switch`, ...) are passed through to [ggplot2::facet_grid()].
#' @param rows,cols Variables to facet by, wrapped in `ggplot2::vars()`.
#' @param scales Should scales be fixed ("fixed"), free ("free"), or free in
#'   one dimension ("free_x", "free_y")?
#' @param space Should the space be fixed ("fixed"), free ("free"), or free in
#'   one dimension ("free_x", "free_y")?
#' @return A modified `plotit` object.
#' @examples
#' plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
#'   mark_point() |>
#'   split_grid(rows = ggplot2::vars(Species))
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
  dots <- rlang::enquos(...)
  dot_names <- names(dots) %||% character(length(dots))
  is_named <- nzchar(dot_names)
  facet_quos <- dots[!is_named]
  passthrough <- lapply(dots[is_named], rlang::eval_tidy)

  if (length(facet_quos) > 0) {
    if (!is.null(rows)) {
      cli::cli_warn("Both {.code ...} and {.code rows} provided; {.code ...} will be used.")
    }
    rows <- ggplot2::vars(!!!facet_quos)
  }

  args <- c(
    list(rows = rows, cols = cols, scales = scales, space = space),
    passthrough
  )
  plot@gg <- plot@gg + do.call(ggplot2::facet_grid, args)
  plot
}
