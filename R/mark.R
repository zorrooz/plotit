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
#' Adds a scatter plot layer.
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param position Position adjustment; if `NULL` and global dodge is set,
#'   auto-applies `position_dodge()`.
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
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
#' Adds a connected line or trend layer.
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param position Position adjustment.
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
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
#' Adds a box-and-whisker distribution layer.
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param position Position adjustment; overrides `geom_boxplot` default.
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
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
#' Adds a histogram layer with automatic binning.
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param position Position adjustment.
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
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
#' Adds a kernel density estimate layer.
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param position Position adjustment.
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
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

# ---- mark_area ----
#' Area layer
#'
#' Adds a filled area layer. Use for stacked area charts, stream graphs,
#' or error bands.
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param position Position adjustment.
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to `geom_area`
#' @return Modified plotit object
#' @examples
#' plotit(ggplot2::economics, encode(x = date, y = unemploy)) |>
#'   mark_area(alpha = 0.5)
#' @export
mark_area <- S7::new_generic(
  "mark_area", "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)
._register_mark_method(mark_area, ggplot2::geom_area)

# ---- mark_text ----
#' Text layer
#'
#' Adds a text label layer. For automatic label placement with collision
#' avoidance, install the optional \pkg{ggrepel} package and set
#' `repel = TRUE`.
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics (e.g. `encode(label = ...)`)
#' @param data Optional data for this layer
#' @param position Position adjustment.
#' @param repel If `TRUE`, use `ggrepel::geom_text_repel` instead of
#'   `geom_text`. Requires the \pkg{ggrepel} package.
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to `geom_text` or `geom_text_repel`
#' @return Modified plotit object
#' @examples
#' plotit(mtcars, encode(x = wt, y = mpg, label = rownames(mtcars))) |>
#'   mark_text(size = 3)
#' @export
mark_text <- S7::new_generic(
  "mark_text", "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           repel = FALSE,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_text, plotit_class) <- function(
    plot, mapping = NULL, data = NULL, position = NULL, ...,
    repel = FALSE,
    rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
  if (repel) {
    if (!requireNamespace("ggrepel", quietly = TRUE)) {
      cli::cli_abort("{.arg repel = TRUE} requires the {.pkg ggrepel} package.")
    }
    geom_fun <- ggrepel::geom_text_repel
  } else {
    geom_fun <- ggplot2::geom_text
  }
  if (!is.null(mapping) && !is.null(mapping$colour)) {
    plot <- ._clear_default_color(plot, mapping)
  }
  ._mark_impl(
    plot, mapping, data, position, geom_fun,
    rasterize, rasterize_dpi, rasterize_dev, ...
  )
}

# ---- mark_violin ----
#' Violin layer
#'
#' Adds a violin plot layer showing the kernel density estimate of the data
#' at each position.
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param position Position adjustment.
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to `geom_violin`
#' @return Modified plotit object
#' @examples
#' plotit(iris, encode(x = Species, y = Sepal.Length)) |>
#'   mark_violin(draw_quantiles = 0.5)
#' @export
mark_violin <- S7::new_generic(
  "mark_violin", "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)
._register_mark_method(mark_violin, ggplot2::geom_violin)

# ---- mark_map ----
#' Map layer
#'
#' Adds a geographic map layer for \pkg{sf} spatial data frames.
#' Requires the \pkg{sf} package.
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional sf data frame for this layer
#' @param position Position adjustment (ignored for sf layers).
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to `geom_sf`
#' @return Modified plotit object
#' @references
#' Vega-Lite: \href{https://vega.github.io/vega-lite/docs/geoshape.html}{Geoshape}
#'
#' AntV G2: \href{https://g2.antv.antgroup.com/en/api/mark/geo-path}{GeoPath}
#' @examples
#' if (requireNamespace("sf", quietly = TRUE)) {
#'   nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
#'   plotit(nc, encode(geometry = geometry)) |> mark_map()
#' }
#' @export
mark_map <- S7::new_generic(
  "mark_map", "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_map, plotit_class) <- function(
    plot, mapping = NULL, data = NULL, position = NULL, ...,
    rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
  if (!requireNamespace("sf", quietly = TRUE)) {
    cli::cli_abort("{.fn mark_map} requires the {.pkg sf} package.")
  }
  layer_data <- data %||% plot@gg$data
  if (!inherits(layer_data, "sf")) {
    cli::cli_abort(c(
      "{.fn mark_map} requires {.pkg sf} spatial data.",
      "i" = "Use {.fn plotit} with an {.cls sf} data frame."
    ))
  }
  # geom_sf does not support position adjustment; ignore dodge
  if (!is.null(mapping) && !is.null(mapping$colour)) {
    plot <- ._clear_default_color(plot, mapping)
  }
  geom <- ggplot2::geom_sf(mapping = mapping, data = data, ...)
  .add_geom(plot, geom,
    rasterize = rasterize, rasterize_dpi = rasterize_dpi,
    rasterize_dev = rasterize_dev
  )
}

# ---- mark_rect ----
#' Rectangle layer
#'
#' Adds a rectangle or tile layer. Use for heatmaps, grid cells,
#' Gantt charts, or any plot where both x and y span a range.
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param position Position adjustment.
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to `geom_tile`
#' @return Modified plotit object
#' @references
#' Vega-Lite: \href{https://vega.github.io/vega-lite/docs/rect.html}{Rect}
#'
#' AntV G2: \href{https://g2.antv.antgroup.com/en/api/mark/cell}{Cell} /
#' \href{https://g2.antv.antgroup.com/en/api/mark/rect}{Rect}
#' @examples
#' df <- expand.grid(x = 1:5, y = 1:5)
#' df$z <- df$x * df$y
#' plotit(df, encode(x = x, y = y, fill = z)) |> mark_rect()
#' @export
mark_rect <- S7::new_generic(
  "mark_rect", "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)
._register_mark_method(mark_rect, ggplot2::geom_tile)

# ---- mark_rule ----
#' Reference line / segment layer
#'
#' Adds one or more reference lines or segments to a plot. Dispatches
#' to the appropriate ggplot2 geom based on the parameters supplied:
#'
#' - `xintercept` → [ggplot2::geom_vline]
#' - `yintercept` → [ggplot2::geom_hline]
#' - `slope` + `intercept` → [ggplot2::geom_abline]
#' - `x`/`xend`/`y`/`yend` → [ggplot2::geom_segment]
#'
#' Dispatch priority: vline/hline > abline > segment.
#'
#' @param plot A plotit object
#' @param xintercept x-intercept for vertical line(s)
#' @param yintercept y-intercept for horizontal line(s)
#' @param slope Line slope for abline
#' @param intercept Line intercept for abline
#' @param x Start x coordinate(s) for segment
#' @param xend End x coordinate(s) for segment
#' @param y Start y coordinate(s) for segment
#' @param yend End y coordinate(s) for segment
#' @param colour Line colour
#' @param linetype Line type
#' @param linewidth Line width in mm
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to the underlying geom
#' @return Modified plotit object
#' @references
#' Vega-Lite: \href{https://vega.github.io/vega-lite/docs/rule.html}{Rule}
#'
#' AntV G2: \href{https://g2.antv.antgroup.com/en/api/mark/line-x}{LineX} /
#' \href{https://g2.antv.antgroup.com/en/api/mark/line-y}{LineY} /
#' \href{https://g2.antv.antgroup.com/en/api/mark/range}{Range}
#' @examples
#' plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
#'   mark_rule(xintercept = 3, colour = "red", linetype = "dashed")
#' @export
mark_rule <- S7::new_generic(
  "mark_rule", "plot",
  function(plot,
           xintercept = NULL, yintercept = NULL,
           slope = NULL, intercept = NULL,
           x = NULL, xend = NULL, y = NULL, yend = NULL,
           colour = NULL, linetype = NULL, linewidth = NULL,
           ...,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_rule, plotit_class) <- function(
    plot,
    xintercept = NULL, yintercept = NULL,
    slope = NULL, intercept = NULL,
    x = NULL, xend = NULL, y = NULL, yend = NULL,
    colour = NULL, linetype = NULL, linewidth = NULL,
    ...,
    rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
  # Build named list of non-NULL params for the geom call
  params <- rlang::list2(...)
  if (!is.null(colour))    params$colour    <- colour
  if (!is.null(linetype))  params$linetype  <- linetype
  if (!is.null(linewidth)) params$linewidth <- linewidth

  # Dispatch by param combination
  if (!is.null(xintercept)) {
    params$xintercept <- xintercept
    geom_call <- do.call(ggplot2::geom_vline, params)
  } else if (!is.null(yintercept)) {
    params$yintercept <- yintercept
    geom_call <- do.call(ggplot2::geom_hline, params)
  } else if (!is.null(slope) || !is.null(intercept)) {
    if (!is.null(slope))     params$slope     <- slope
    if (!is.null(intercept)) params$intercept <- intercept
    geom_call <- do.call(ggplot2::geom_abline, params)
  } else if (!is.null(x) && !is.null(xend) && !is.null(y) && !is.null(yend)) {
    params$x    <- x
    params$xend <- xend
    params$y    <- y
    params$yend <- yend
    geom_call <- do.call(ggplot2::geom_segment, params)
  } else {
    cli::cli_abort(c(
      "{.fn mark_rule} requires one of:",
      "*" = "{.arg xintercept} or {.arg yintercept}",
      "*" = "{.arg slope} + {.arg intercept}",
      "*" = "{.arg x} + {.arg xend} + {.arg y} + {.arg yend}"
    ))
  }

  .add_geom(plot, geom_call,
    rasterize = rasterize, rasterize_dpi = rasterize_dpi,
    rasterize_dev = rasterize_dev
  )
}

# ---- mark_path ----
#' Path layer
#'
#' Adds a path layer connecting observations in their original order.
#' Use for trajectories, time-ordered connected points, or custom
#' drawing orders.
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param position Position adjustment.
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to `geom_path`
#' @return Modified plotit object
#' @references
#' AntV G2: \href{https://g2.antv.antgroup.com/en/api/mark/path}{Path}
#' @examples
#' df <- data.frame(x = 1:10, y = cumsum(runif(10, -1, 1)))
#' plotit(df, encode(x = x, y = y)) |> mark_path()
#' @export
mark_path <- S7::new_generic(
  "mark_path", "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)
._register_mark_method(mark_path, ggplot2::geom_path)

# ---- mark_polygon ----
#' Polygon layer
#'
#' Adds a filled polygon layer. Each group forms one polygon;
#' subgroups are separated by `NA` rows or the `group` aesthetic.
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param position Position adjustment.
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to `geom_polygon`
#' @return Modified plotit object
#' @references
#' AntV G2: \href{https://g2.antv.antgroup.com/en/api/mark/polygon}{Polygon}
#' @examples
#' tri <- data.frame(x = c(0, 1, 0.5), y = c(0, 0, 1))
#' plotit(tri, encode(x = x, y = y)) |> mark_polygon(fill = "skyblue")
#' @export
mark_polygon <- S7::new_generic(
  "mark_polygon", "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)
._register_mark_method(mark_polygon, ggplot2::geom_polygon)

# ---- mark_smooth ----
#' Smoothed conditional mean layer
#'
#' Adds a smoothed conditional mean line with a confidence band.
#' Aids the eye in seeing patterns in the presence of overplotting.
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param position Position adjustment.
#' @param method Smoothing method: `"auto"` (loess for n<1000, gam otherwise),
#'   `"lm"`, `"glm"`, `"gam"`, or `"loess"`.
#' @param formula Formula to use in the smoothing function.
#' @param se If `TRUE` (default), display confidence interval around smooth.
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to `geom_smooth`
#' @return Modified plotit object
#' @references
#' Vega-Lite: achieved via \code{layer(point) + layer(line) + transform(regression)}
#'
#' AntV G2: achieved via transform pipeline
#' @examples
#' plotit(mtcars, encode(x = wt, y = mpg)) |> mark_smooth()
#' @export
mark_smooth <- S7::new_generic(
  "mark_smooth", "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           method = NULL, formula = NULL, se = NULL,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_smooth, plotit_class) <- function(
    plot, mapping = NULL, data = NULL, position = NULL, ...,
    method = NULL, formula = NULL, se = NULL,
    rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
  params <- rlang::list2(...)
  params$method <- method
  params$formula <- formula
  params$se <- se
  do.call(function(...) {
    ._mark_impl(plot, mapping, data, position, ggplot2::geom_smooth,
                rasterize, rasterize_dpi, rasterize_dev, ...)
  }, params)
}

# ---- mark_hex ----
#' Hexagonal heatmap layer
#'
#' Divides the x-y plane into hexagonal bins and fills each by the
#' count (or other aggregation) of observations in that bin.
#' Ideal for visualizing overplotting in large datasets.
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param position Position adjustment.
#' @param bins Number of bins along both axes (default 30).
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to `geom_hex`
#' @return Modified plotit object
#' @references
#' AntV G2: \href{https://g2.antv.antgroup.com/en/api/mark/heatmap}{Heatmap} (corelib)
#' @examples
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   plotit(ggplot2::diamonds[sample(nrow(ggplot2::diamonds), 1000), ],
#'          encode(x = carat, y = price)) |> mark_hex(bins = 20)
#' }
#' @export
mark_hex <- S7::new_generic(
  "mark_hex", "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           bins = NULL,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_hex, plotit_class) <- function(
    plot, mapping = NULL, data = NULL, position = NULL, ...,
    bins = NULL,
    rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
  params <- rlang::list2(...)
  params$bins <- bins
  do.call(function(...) {
    ._mark_impl(plot, mapping, data, position, ggplot2::geom_hex,
                rasterize, rasterize_dpi, rasterize_dev, ...)
  }, params)
}

# ---- mark_density_2d ----
#' 2D density contour layer
#'
#' Adds 2D kernel density estimate contours. Use `filled = TRUE`
#' for filled density bands via [ggplot2::geom_density_2d_filled].
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param position Position adjustment.
#' @param filled If `TRUE`, use filled density contours.
#' @param bins Number of contour bins (for filled mode).
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to the underlying geom
#' @return Modified plotit object
#' @references
#' AntV G2: \href{https://g2.antv.antgroup.com/en/api/mark/density}{Density} (corelib, contour mode)
#' @examples
#' plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
#'   mark_density_2d()
#' @export
mark_density_2d <- S7::new_generic(
  "mark_density_2d", "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           filled = FALSE, bins = NULL,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_density_2d, plotit_class) <- function(
    plot, mapping = NULL, data = NULL, position = NULL, ...,
    filled = FALSE, bins = NULL,
    rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
  geom_fun <- if (filled) ggplot2::geom_density_2d_filled else ggplot2::geom_density_2d
  dots <- rlang::list2(...)
  if (!is.null(bins)) dots$bins <- bins
  # Only clear default_color when the layer provides colour/fill
  if (!is.null(mapping) && (!is.null(mapping$colour) || !is.null(mapping$fill))) {
    plot <- ._clear_default_color(plot, mapping)
  }
  pos <- position
  if (is.null(pos) && !is.null(plot@meta@dodge) && plot@meta@dodge > 0) {
    pos <- ggplot2::position_dodge(plot@meta@dodge)
  }
  geom <- if (is.null(pos)) {
    do.call(geom_fun, c(list(mapping = mapping, data = data), dots))
  } else {
    do.call(geom_fun, c(list(mapping = mapping, data = data, position = pos), dots))
  }
  .add_geom(plot, geom,
    rasterize = rasterize, rasterize_dpi = rasterize_dpi,
    rasterize_dev = rasterize_dev
  )
}

# ---- mark_corr ----
#' Correlation matrix heatmap
#'
#' Computes a correlation matrix from numeric data columns, optionally
#' reorders by hierarchical clustering, and renders it as a tile heatmap.
#'
#' @param plot A plotit object. Numeric columns are extracted from the
#'   plot data for correlation computation.
#' @param method Correlation method: `"pearson"` (default), `"spearman"`,
#'   or `"kendall"`.
#' @param reorder If `TRUE` (default), reorder rows and columns by
#'   hierarchical clustering.
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to `geom_tile`
#' @return Modified plotit object
#' @references
#' AntV G2: \href{https://g2.antv.antgroup.com/en/api/mark/cell}{Cell} (correlation matrix expression)
#' @examples
#' plotit(mtcars, encode()) |> mark_corr()
#' @export
mark_corr <- S7::new_generic(
  "mark_corr", "plot",
  function(plot, method = c("pearson", "spearman", "kendall"),
           reorder = TRUE, ...,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_corr, plotit_class) <- function(
    plot, method = c("pearson", "spearman", "kendall"),
    reorder = TRUE, ...,
    rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
  method <- match.arg(method)
  # Extract numeric columns from plot data
  raw_data <- plot@gg$data
  num_cols <- vapply(raw_data, is.numeric, logical(1))
  if (sum(num_cols) < 2) {
    cli::cli_abort("{.fn mark_corr} requires at least 2 numeric columns.")
  }
  mat <- stats::cor(raw_data[, num_cols, drop = FALSE], method = method)
  # Hierarchical clustering reorder
  if (reorder) {
    ord <- stats::hclust(stats::as.dist(1 - abs(mat)))$order
    mat <- mat[ord, ord]
  }
  # Melt to long form
  df <- expand.grid(
    Var1 = factor(rownames(mat), levels = rownames(mat)),
    Var2 = factor(colnames(mat), levels = colnames(mat))
  )
  df$value <- as.vector(mat)
  # Build tile
  mapping <- encode(x = Var1, y = Var2, fill = value)
  geom <- ggplot2::geom_tile(mapping = mapping, data = df, ...)
  .add_geom(plot, geom,
    rasterize = rasterize, rasterize_dpi = rasterize_dpi,
    rasterize_dev = rasterize_dev
  )
}

# ---- mark_bar (hand-written: geom_col vs geom_bar dispatch) ----
#' Bar layer
#'
#' Adds a bar layer. Automatically uses `geom_col()` when a y aesthetic is
#' mapped, or `geom_bar()` for count-based bars.
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param position Position adjustment; overrides `geom_bar`/`geom_col` default.
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
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
