#' @include class.R
NULL

# ---- Internal helpers ----

# Shared mark logic: resolve position (auto-dodge or explicit), build geom,
# clear default_color if the layer provides colour/fill, rasterize.
#' Shared mark implementation: resolve position, clear default_color, rasterise.
#' @noRd
#' @keywords internal
._mark_impl <- function(plot, mapping, data, position, geom_fun,
                        rasterize, rasterize_dpi, rasterize_dev, ...) {
  # Only clear default_color when the layer actually provides colour/fill
  if (!is.null(mapping) && (!is.null(mapping$colour) || !is.null(mapping$fill))) {
    plot <- ._clear_default_color(plot, mapping)
  }
  pos <- position
  if (is.null(pos) && !is.null(plot@meta@dodge) && plot@meta@dodge > 0) {
    pos <- ggplot2::position_dodge(plot@meta@dodge)
  }
  geom <- if (is.null(pos)) {
    geom_fun(mapping = mapping, data = data, ...)
  } else {
    geom_fun(mapping = mapping, data = data, position = pos, ...)
  }
  .add_geom(plot, geom,
    rasterize = rasterize, rasterize_dpi = rasterize_dpi,
    rasterize_dev = rasterize_dev
  )
}

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

# ---- mark method factory ----
# Generates only the S7 method for a standard mark.  The S7 generic
# (`new_generic`) stays hand-written with @export so roxygen2 can see it.
#
# generic  : the S7 generic object (e.g. mark_point)
# geom_fun : the ggplot2 geom function (e.g. ggplot2::geom_point)
#' Register an S7 method for a standard mark.
#' @noRd
#' @keywords internal
._register_mark_method <- function(generic, geom_fun) {
  force(generic)
  force(geom_fun)

  S7::method(generic, plotit_class) <- function(
    plot, mapping = NULL, data = NULL, position = NULL, ...,
    rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo"
  ) {
    ._mark_impl(plot, mapping, data, position, geom_fun,
                rasterize, rasterize_dpi, rasterize_dev, ...)
  }
  invisible()
}

# ---- mark_point ----
#' Point layer
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
#' @examples
#' plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
#' @export
mark_point <- S7::new_generic(
  "mark_point", "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)
._register_mark_method(mark_point, ggplot2::geom_point)

# ---- mark_line ----
#' Line layer
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
#' @examples
#' plotit(ggplot2::economics, encode(x = date, y = unemploy)) |> mark_line()
#' @export
mark_line <- S7::new_generic(
  "mark_line", "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)
._register_mark_method(mark_line, ggplot2::geom_line)

# ---- mark_boxplot ----
#' Boxplot layer
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
#' @examples
#' plotit(iris, encode(x = Species, y = Sepal.Length)) |> mark_boxplot()
#' @export
mark_boxplot <- S7::new_generic(
  "mark_boxplot", "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)
._register_mark_method(mark_boxplot, ggplot2::geom_boxplot)

# ---- mark_histogram ----
#' Histogram layer
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param position Position adjustment; if `NULL` and global dodge is set, auto-applies `position_dodge()`.
#' @param rasterize If `TRUE`, rasterize the layer via `ggrastr::rasterise()` (requires \pkg{ggrastr}).
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to `geom_histogram`
#' @return Modified plotit object
#' @examples
#' plotit(iris, encode(x = Sepal.Width)) |> mark_histogram()
#' @export
mark_histogram <- S7::new_generic(
  "mark_histogram", "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)
._register_mark_method(mark_histogram, ggplot2::geom_histogram)

# ---- mark_density ----
#' Density layer
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param position Position adjustment; if `NULL` and global dodge is set, auto-applies `position_dodge()`.
#' @param rasterize If `TRUE`, rasterize the layer via `ggrastr::rasterise()` (requires \pkg{ggrastr}).
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to `geom_density`
#' @return Modified plotit object
#' @examples
#' plotit(iris, encode(x = Sepal.Width)) |> mark_density()
#' @export
mark_density <- S7::new_generic(
  "mark_density", "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)
._register_mark_method(mark_density, ggplot2::geom_density)

# ---- mark_bar (hand-written: geom_col vs geom_bar dispatch) ----
#' Bar layer
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
#' @examples
#' plotit(mtcars, encode(x = factor(cyl))) |> mark_bar()
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
  # If layer mapping is provided, trust it (even if y = NULL).
  # Only fall back to global mapping when no layer mapping is given.
  has_y <- if (!is.null(mapping)) {
    !is.null(mapping$y)
  } else {
    !is.null(plot@gg$mapping$y)
  }
  geom_fun <- if (has_y) ggplot2::geom_col else ggplot2::geom_bar
  ._mark_impl(
    plot, mapping, data, position, geom_fun,
    rasterize, rasterize_dpi, rasterize_dev, ...
  )
}
