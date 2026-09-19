#' @include class.R utils.R theme.R
NULL

# The default theme builder (._theme_default) and every global visual token
# live in theme.R -- the single style source of truth (AGENTS.md 3.3.11).
# This file only exposes the user-facing style() generic.

# ---- style ----
#' Modify plot theme (aligns with ggplot2::theme)
#'
#' Applies plotit's default theme and overrides individual elements via `...`.
#' Call `style(p)` without arguments to apply the default theme, or pass
#' theme-element overrides like `style(p, plot.title = element_text(face="bold"))`.
#' Use `base_theme` to switch to an entirely different base theme (e.g.,
#' `style(p, base_theme = ggplot2::theme_bw())`).
#'
#' @param plot A plotit object.
#' @param ... Theme element overrides, passed to `ggplot2::theme()`.
#' @param base_size Base font size in pts (default 7, tidyplots-calibrated).
#' @param base_family Base font family (default `""` = system sans-serif).
#' @param base_theme A complete ggplot2 theme *object* (e.g.
#'   `ggplot2::theme_bw()`) or a theme *function* (e.g.
#'   `ggplot2::theme_minimal`). `NULL` = use plotit default. When a
#'   theme function is supplied, `base_size`/`base_family` are forwarded
#'   to it; when a theme object is supplied together with font args, the
#'   font args are ignored with a warning.
#' @return Modified plotit object.
#' @examples
#' plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
#'   mark_point() |>
#'   style()
#' @export
style <- S7::new_generic(
  "style",
  "plot",
  function(plot, ..., base_size = NULL, base_family = NULL,
           base_theme = NULL) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(style, plotit_class) <- function(
  plot,
  ...,
  base_size = NULL,
  base_family = NULL,
  base_theme = NULL
) {
  thm <- ._resolve_style_theme(base_size, base_family, base_theme)
  plot@gg <- plot@gg + thm + ggplot2::theme(...)
  attr(plot@meta, "plotit_theme_managed") <- TRUE
  plot
}

# Shared by style() single-plot and composite methods.
# base_theme may be a theme object or a theme *function* (e.g.
# ggplot2::theme_minimal).  Font args only apply when no complete
# base_theme object was supplied; otherwise they are warned and dropped.
#' Resolve the effective theme for style().
#' @noRd
#' @keywords internal
._resolve_style_theme <- function(base_size, base_family, base_theme) {
  if (!is.null(base_theme) && is.function(base_theme)) {
    args <- list()
    if (!is.null(base_size)) args$base_size <- base_size
    if (!is.null(base_family)) args$base_family <- base_family
    base_theme <- tryCatch(
      do.call(base_theme, args),
      error = function(e) base_theme()
    )
    # Font args were consumed by the function call -- no warning.
    return(base_theme)
  }
  if (!is.null(base_theme) && (!is.null(base_size) || !is.null(base_family))) {
    ._warn_ignored(
      "base_size/base_family",
      "a complete base_theme was supplied; bake font size into base_theme or drop it."
    )
  }
  base_theme %||% ._theme_default(base_size, base_family)
}
