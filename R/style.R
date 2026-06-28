#' @include class.R utils.R
NULL

# ---- Internal theme builder ----
# Constructs the default plotit theme object (not exported -- use style_default())
.theme_default <- function(base_size = NULL, base_family = NULL) {
  ggplot2::theme_minimal(
    base_size = base_size %||% 11,
    base_family = base_family %||% ""
  ) + ggplot2::theme(
    # Clean white panel, no grid
    panel.background = ggplot2::element_rect(fill = "white", colour = NA),
    panel.grid = ggplot2::element_blank(),
    panel.grid.major = ggplot2::element_blank(),
    panel.grid.minor = ggplot2::element_blank(),
    # Transparent outer elements
    plot.background = ggplot2::element_rect(fill = NA, colour = NA),
    legend.background = ggplot2::element_rect(fill = NA, colour = NA),
    legend.key = ggplot2::element_rect(fill = NA, colour = NA),
    legend.box.background = ggplot2::element_rect(fill = NA, colour = NA),
    legend.box.spacing = ggplot2::unit(0, "cm"),
    strip.background = ggplot2::element_rect(fill = NA, colour = NA),
    # Axis lines and ticks (Cartesian)
    axis.line = ggplot2::element_line(colour = "grey50", linewidth = 0.3),
    axis.ticks = ggplot2::element_line(colour = "grey50", linewidth = 0.3),
    legend.position = "right",
    plot.title = ggplot2::element_text(face = "bold", hjust = 0),
    plot.subtitle = ggplot2::element_text(hjust = 0),
    axis.title = ggplot2::element_text(size = ggplot2::rel(0.9)),
    axis.text = ggplot2::element_text(size = ggplot2::rel(0.8))
  )
}

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
#' @param base_size Base font size in pts (default 11).
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
  thm <- base_theme %||% .theme_default(base_size, base_family)
  plot@gg <- plot@gg + thm + ggplot2::theme(...)
  attr(plot@meta, "plotit_theme_managed") <- TRUE
  plot
}

# ---- style_default ----
#' Apply the default plotit theme (convenience wrapper for style())
#'
#' @param plot A plotit object.
#' @param base_size Base font size in pts (default 11).
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
  function(plot, base_size = NULL, base_family = NULL) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(style_default, plotit_class) <- function(
  plot,
  base_size = NULL,
  base_family = NULL
) {
  style(plot, base_size = base_size, base_family = base_family)
}
