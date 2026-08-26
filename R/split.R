#' @include class.R
NULL

# Shared dots protocol for the facet family: unnamed quosures are facet
# variables, named arguments are evaluated and passed through to the
# underlying ggplot2 facet constructor.
#' Split facet `...` into facet quosures and passthrough args.
#' @noRd
#' @keywords internal
._split_facet_dots <- function(...) {
  dots <- rlang::enquos(...)
  dot_names <- names(dots) %||% character(length(dots))
  is_named <- nzchar(dot_names)
  list(
    facets = dots[!is_named],
    passthrough = lapply(dots[is_named], rlang::eval_tidy),
    named = dot_names[is_named]
  )
}

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

# Re-bake WYSIWYG panel sizing after the facet grid changes the panel
# layout: meta sizes describe the whole panel area, so the baked
# panel.widths/heights must be re-spread across the new grid dimensions.
#' Re-bake panel sizing for the current facet grid.
#' @noRd
#' @keywords internal
._split_rebake_size <- function(plot) {
  meta <- plot@meta
  if (isTRUE(meta@autofit) || is.null(meta@width) || is.null(meta@height)) {
    return(plot)
  }
  plot@gg <- ._strip_panel_size(plot@gg)
  plot@gg <- ._apply_panel_size(
    plot@gg, meta@width, meta@height, meta@unit,
    grid = ._panel_grid_dims(plot@gg)
  )
  plot
}

#' @export
S7::method(split_wrap, plotit_class) <- function(
  plot,
  ...,
  nrow = NULL,
  ncol = NULL,
  scales = "fixed"
) {
  split <- ._split_facet_dots(...)
  # A named `facets=` in `...` would collide with the constructed formal at
  # do.call time and fail with an opaque match error -- catch it here.
  if ("facets" %in% split$named) {
    cli::cli_abort(c(
      "{.code facets =} cannot be passed via {.arg ...} in {.fn split_wrap}.",
      "i" = "Pass facet variables as unnamed arguments: \\
             {.code split_wrap(Species, ncol = 3)}."
    ))
  }

  args <- c(
    list(facets = ggplot2::vars(!!!split$facets)),
    list(nrow = nrow, ncol = ncol, scales = scales),
    split$passthrough
  )
  plot@gg <- plot@gg + do.call(ggplot2::facet_wrap, args)
  ._split_rebake_size(plot)
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
  split <- ._split_facet_dots(...)

  if (length(split$facets) > 0) {
    if (!is.null(rows)) {
      cli::cli_warn("Both {.code ...} and {.code rows} provided; {.code ...} will be used.")
    }
    rows <- ggplot2::vars(!!!split$facets)
  }

  args <- c(
    list(rows = rows, cols = cols, scales = scales, space = space),
    split$passthrough
  )
  plot@gg <- plot@gg + do.call(ggplot2::facet_grid, args)
  ._split_rebake_size(plot)
}

# ---- split catalog ----------------------------------------------------------
# Consumed by zzz.R to register plotit_composite rejection stubs.
._CATALOG_SPLITS <- c("split_wrap", "split_grid")
