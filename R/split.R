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


# T2.4: when a facet variable is also the colour/fill grouping variable, the
# legend is redundant (every level is already visible in its own panel --
# Vega-Lite/G2 drop the legend in this case).  Auto-hide that channel.
#' Suppress redundant legends when the facet variable == colour/fill variable.
#' @noRd
#' @keywords internal
._facet_suppress_legend <- function(plot, facet_quos) {
  if (length(facet_quos) == 0) {
    return(plot)
  }
  mapping <- plot@gg$mapping
  hide <- c()
  for (aes_name in c("colour", "fill")) {
    mv <- mapping[[aes_name]]
    if (is.null(mv) || inherits(mv, "AsIs")) {
      next
    }
    mv_expr <- deparse(rlang::quo_get_expr(mv))
    for (fq in facet_quos) {
      fv_expr <- deparse(rlang::quo_get_expr(fq))
      if (identical(mv_expr, fv_expr)) {
        hide <- c(hide, aes_name)
        break
      }
    }
  }
  if (length(hide) > 0) {
    # do.call with the plain aesthetic name works; the trailing-= form is
    # not recognised on all ggplot2 versions.
    args <- stats::setNames(
      rep(list("none"), length(hide)),
      hide
    )
    plot@gg <- plot@gg + do.call(ggplot2::guides, args)
  }
  plot
}

#' Generic for wrapping facets
#'
#' @param plot A plotit object.
#' @param ... Unnamed arguments are faceting variables (e.g. `Species`);
#'   named arguments (`labeller`, `strip.position`, `drop`, ...)
#'   are passed through to [ggplot2::facet_wrap()].
#' @param nrow Number of rows in the facet grid (optional).
#' @param ncol Number of columns in the facet grid (optional).
#' @param scales Should scales be fixed ("fixed"), free ("free"), or free in
#'   one dimension ("free_x", "free_y")?
#' @param dir Facet fill direction code passed to [ggplot2::facet_wrap()]:
#'   ggplot2 4.0 supports the eight-direction codes `"lt"`, `"tl"`, `"lb"`,
#'   `"bl"`, `"rt"`, `"tr"`, `"rb"`, `"br"` (first letter = first-panel
#'   corner, second letter = fill direction). `NULL` = ggplot2 default.
#' @return A modified `plotit` object.
#' @examples
#' plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
#'   mark_point() |>
#'   split_wrap(Species, ncol = 3)
#' @export
split_wrap <- S7::new_generic(
  "split_wrap",
  "plot",
  function(plot, ..., nrow = NULL, ncol = NULL, scales = "fixed",
           dir = NULL) {
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
  scales = "fixed",
  dir = NULL
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
  # facet_wrap() rejects dir = NULL (its own default is "h"), so only
  # forward the argument when the user actually set it.
  if (!is.null(dir)) {
    args$dir <- dir
  }
  plot@gg <- plot@gg + do.call(ggplot2::facet_wrap, args)
  plot <- ._facet_suppress_legend(plot, split$facets)
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
#' @param axes Axis repetition passed to [ggplot2::facet_grid()]:
#'   `"all"`/`"all_x"`/`"all_y"` repeat axes on every panel (ggplot2 >= 3.5).
#'   `NULL` = axes on the outer edges only.
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
           scales = "fixed", space = "fixed", axes = NULL) {
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
  space = "fixed",
  axes = NULL
) {
  split <- ._split_facet_dots(...)

  if (length(split$facets) > 0) {
    if (!is.null(rows)) {
      ._warn_precedence("...", "rows")
    }
    # The ggplot2-idiomatic `rows ~ cols` formula is accepted directly
    # (T11.1); any other unnamed facets become the rows shorthand.
    formulas <- vapply(split$facets, function(fq) {
      rlang::is_formula(rlang::quo_get_expr(fq))
    }, logical(1))
    if (any(formulas)) {
      if (sum(formulas) > 1 || length(split$facets) > 1) {
        ._abort_hint(
          "A {.code rows ~ cols} formula must be the only unnamed facet argument.",
          "Pass the formula alone ({.code split_grid(Species ~ year)}) or use the vars() form."
        )
      }
      fml <- split$facets[[1]]
      if (!is.null(cols)) {
        ._warn_precedence("formula", "cols")
        cols <- NULL
      }
      rows <- rlang::quo_get_expr(fml)
    } else {
      rows <- ggplot2::vars(!!!split$facets)
    }
  }

  args <- c(
    list(rows = rows, cols = cols, scales = scales, space = space),
    split$passthrough
  )
  # facet_grid() rejects axes = NULL (its own default is "margins"), so only
  # forward the argument when the user actually set it.
  if (!is.null(axes)) {
    args$axes <- axes
  }
  plot@gg <- plot@gg + do.call(ggplot2::facet_grid, args)
  plot <- ._facet_suppress_legend(plot, split$facets)
  ._split_rebake_size(plot)
}

# ---- split catalog ----------------------------------------------------------
# Consumed by zzz.R to register plotit_composite rejection stubs.
._CATALOG_SPLITS <- c("split_wrap", "split_grid")
