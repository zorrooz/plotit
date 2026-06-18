#' @include class.R
NULL

# ---- Rasterization helper ----
# Wraps a geom call with ggrastr::rasterise() when rasterize = TRUE
.add_geom <- function(plot, geom_call, rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
  if (rasterize) {
    if (!requireNamespace("ggrastr", quietly = TRUE)) {
      cli::cli_abort("Rasterization requires the {.pkg ggrastr} package.")
    }
    plot@gg <- plot@gg + ggrastr::rasterise(geom_call, dpi = rasterize_dpi, dev = rasterize_dev)
  } else {
    plot@gg <- plot@gg + geom_call
  }
  plot
}

#' Generic for adding a point layer
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param position Position adjustment; if `NULL` and global dodge is set, auto-applies `position_dodge()`.
#' @param rasterize If `TRUE`, rasterize the layer via `ggrastr::rasterise()` (requires \pkg{ggrastr}).
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to `geom_point`
#' @return Modified plotit object
#' @export
mark_point <- S7::new_generic(
  "mark_point",
  "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_point, plotit_class) <- function(plot, mapping = NULL, data = NULL,
                                                 position = NULL, ...,
                                                 rasterize = FALSE, rasterize_dpi = 300,
                                                 rasterize_dev = "cairo") {
  pos <- position
  if (is.null(pos) && !is.null(plot@meta@dodge) && plot@meta@dodge > 0) {
    pos <- ggplot2::position_dodge(plot@meta@dodge)
  }
  if (is.null(pos)) {
    geom <- ggplot2::geom_point(mapping = mapping, data = data, ...)
  } else {
    geom <- ggplot2::geom_point(mapping = mapping, data = data, position = pos, ...)
  }
  .add_geom(plot, geom,
    rasterize = rasterize, rasterize_dpi = rasterize_dpi,
    rasterize_dev = rasterize_dev
  )
}

#' Generic for adding a line layer
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param position Position adjustment; if `NULL` and global dodge is set, auto-applies `position_dodge()`.
#' @param rasterize If `TRUE`, rasterize the layer via `ggrastr::rasterise()` (requires \pkg{ggrastr}).
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to `geom_line`
#' @return Modified plotit object
#' @export
mark_line <- S7::new_generic(
  "mark_line",
  "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_line, plotit_class) <- function(plot, mapping = NULL, data = NULL,
                                                position = NULL, ...,
                                                rasterize = FALSE, rasterize_dpi = 300,
                                                rasterize_dev = "cairo") {
  pos <- position
  if (is.null(pos) && !is.null(plot@meta@dodge) && plot@meta@dodge > 0) {
    pos <- ggplot2::position_dodge(plot@meta@dodge)
  }
  if (is.null(pos)) {
    geom <- ggplot2::geom_line(mapping = mapping, data = data, ...)
  } else {
    geom <- ggplot2::geom_line(mapping = mapping, data = data, position = pos, ...)
  }
  .add_geom(plot, geom,
    rasterize = rasterize, rasterize_dpi = rasterize_dpi,
    rasterize_dev = rasterize_dev
  )
}

#' Generic for adding a bar layer
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param position Position adjustment; if `NULL` and global dodge is set, auto-applies `position_dodge()`. Overrides `geom_bar`/`geom_col` default.
#' @param rasterize If `TRUE`, rasterize the layer via `ggrastr::rasterise()` (requires \pkg{ggrastr}).
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to `geom_bar` or `geom_col`
#' @return Modified plotit object
#' @export
mark_bar <- S7::new_generic(
  "mark_bar",
  "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_bar, plotit_class) <- function(plot, mapping = NULL, data = NULL,
                                               position = NULL, ...,
                                               rasterize = FALSE, rasterize_dpi = 300,
                                               rasterize_dev = "cairo") {
  pos <- position
  if (is.null(pos) && !is.null(plot@meta@dodge) && plot@meta@dodge > 0) {
    pos <- ggplot2::position_dodge(plot@meta@dodge)
  }
  has_y <- (!is.null(mapping) && !is.null(mapping$y)) ||
    (!is.null(plot@gg$mapping$y))
  geom_fun <- if (has_y) ggplot2::geom_col else ggplot2::geom_bar
  if (is.null(pos)) {
    geom <- geom_fun(mapping = mapping, data = data, ...)
  } else {
    geom <- geom_fun(mapping = mapping, data = data, position = pos, ...)
  }
  .add_geom(plot, geom,
    rasterize = rasterize, rasterize_dpi = rasterize_dpi,
    rasterize_dev = rasterize_dev
  )
}

#' Generic for adding a boxplot layer
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param position Position adjustment; if `NULL` and global dodge is set, auto-applies `position_dodge()`. Overrides `geom_boxplot` default (`"dodge2"`).
#' @param rasterize If `TRUE`, rasterize the layer via `ggrastr::rasterise()` (requires \pkg{ggrastr}).
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to `geom_boxplot`
#' @return Modified plotit object
#' @export
mark_boxplot <- S7::new_generic(
  "mark_boxplot",
  "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_boxplot, plotit_class) <- function(plot, mapping = NULL, data = NULL,
                                                   position = NULL, ...,
                                                   rasterize = FALSE, rasterize_dpi = 300,
                                                   rasterize_dev = "cairo") {
  pos <- position
  if (is.null(pos) && !is.null(plot@meta@dodge) && plot@meta@dodge > 0) {
    pos <- ggplot2::position_dodge(plot@meta@dodge)
  }
  if (is.null(pos)) {
    geom <- ggplot2::geom_boxplot(mapping = mapping, data = data, ...)
  } else {
    geom <- ggplot2::geom_boxplot(mapping = mapping, data = data, position = pos, ...)
  }
  .add_geom(plot, geom,
    rasterize = rasterize, rasterize_dpi = rasterize_dpi,
    rasterize_dev = rasterize_dev
  )
}
