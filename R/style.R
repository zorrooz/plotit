#' @include class.R utils.R theme.R
NULL

# The default theme builder (._theme_default) and every global visual token
# live in theme.R -- the single style source of truth (AGENTS.md 3.3.11).
# This file only exposes the user-facing style() / style_default() generics.

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
#' @param base_size Base font size in pts (default 10).
#' @param base_family Base font family (default `""` = system sans-serif).
#' @param base_theme A complete ggplot2 theme object to use instead of the
#'   default (e.g., `ggplot2::theme_bw()`). `NULL` = use plotit default.
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
  thm <- base_theme %||% ._theme_default(base_size, base_family)
  plot@gg <- plot@gg + thm + ggplot2::theme(...)
  attr(plot@meta, "plotit_theme_managed") <- TRUE
  plot
}

# ---- style_default ----
#' Apply the default plotit theme (convenience wrapper for style())
#'
#' @param plot A plotit object.
#' @param ... Ignored.
#' @param base_size Base font size in pts (default 10).
#' @param base_family Base font family (default `""` = system sans-serif).
#' @return Modified plotit object.
#' @examples
#' plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
#'   mark_point() |>
#'   style_default()
#' @export
style_default <- S7::new_generic(
  "style_default",
  "plot",
  function(plot, ..., base_size = NULL, base_family = NULL) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(style_default, plotit_class) <- function(
  plot,
  base_size = NULL,
  base_family = NULL,
  ...
) {
  style(plot, ..., base_size = base_size, base_family = base_family)
}
