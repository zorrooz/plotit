#' @include class.R utils.R
NULL

# ---- Internal theme builder ----
# Constructs the default plotit theme object (not exported — use style_default())
.theme_default <- function(base_size = NULL, base_family = NULL) {
  ggplot2::theme_minimal(
    base_size = base_size %||% 11,
    base_family = base_family %||% ""
  ) + ggplot2::theme(
    plot.background = ggplot2::element_rect(fill = NA, colour = NA),
    panel.background = ggplot2::element_rect(fill = NA, colour = NA),
    legend.background = ggplot2::element_rect(fill = NA, colour = NA),
    legend.key = ggplot2::element_rect(fill = NA, colour = NA),
    legend.box.background = ggplot2::element_rect(fill = NA, colour = NA),
    legend.box.spacing = ggplot2::unit(0, "cm"),
    strip.background = ggplot2::element_rect(fill = NA, colour = NA),
    panel.grid.minor = ggplot2::element_blank(),
    panel.grid.major = ggplot2::element_line(
      colour = "grey92", linewidth = 0.3
    ),
    axis.line = ggplot2::element_line(colour = "grey50", linewidth = 0.3),
    axis.ticks = ggplot2::element_line(colour = "grey50", linewidth = 0.3),
    legend.position = "right",
    plot.title = ggplot2::element_text(face = "bold", hjust = 0),
    plot.subtitle = ggplot2::element_text(hjust = 0),
    axis.title = ggplot2::element_text(size = ggplot2::rel(0.9)),
    axis.text = ggplot2::element_text(size = ggplot2::rel(0.8))
  )
}

# ---- style_default ----
#' Apply the default plotit theme
#'
#' @param plot A plotit object.
#' @param base_size Base font size in pts (default 11).
#' @param base_family Base font family (default `""` = system sans-serif).
#' @return Modified plotit object.
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
  plot@gg <- plot@gg + .theme_default(base_size, base_family)
  attr(plot@meta, "plotit_theme_managed") <- TRUE
  plot
}

# ---- style ----
#' Apply an arbitrary ggplot2 theme
#'
#' @param plot A plotit object.
#' @param theme A ggplot2 theme object (e.g., `theme_minimal()`).
#' @param ... Additional arguments passed to `ggplot2::theme()`.
#' @return Modified plotit object.
#' @export
style <- S7::new_generic(
  "style",
  "plot",
  function(plot, theme, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(style, plotit_class) <- function(
  plot,
  theme,
  ...
) {
  plot@gg <- plot@gg + theme + ggplot2::theme(...)
  attr(plot@meta, "plotit_theme_managed") <- TRUE
  plot
}
