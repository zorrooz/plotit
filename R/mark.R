#' @include class.R
NULL

# ---- Internal helpers ----

# Shared mark logic: resolve position (auto-dodge or explicit), build geom,
# clear default_color if the layer provides colour/fill, rasterize.
#' Shared mark implementation: resolve position, clear default_color, rasterise.
#' @noRd
#' @keywords internal
._mark_impl <- function(plot, mapping, data, position, geom_fun,
                        rasterize, rasterize_dpi, rasterize_dev,
                        auto_dodge = TRUE, ...) {
  # Only clear default_color when the layer actually provides colour/fill
  if (!is.null(mapping) && (!is.null(mapping$colour) || !is.null(mapping$fill))) {
    plot <- ._clear_default_color(plot, mapping)
  }
  pos <- position
  if (is.null(pos) && auto_dodge && !is.null(plot@meta@dodge) && plot@meta@dodge > 0) {
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
  if (!is.null(mapping) && (!is.null(mapping$colour) || !is.null(mapping$fill))) {
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
    # annotate() avoids the "All aesthetics have length 1" warning that
    # constant aes() mappings trigger on multi-row data (R6).  NULL
    # parameters are omitted -- annotate() requires equal-length params.
    ann_args <- list(x = x, xend = xend, y = y, yend = yend)
    if (!is.null(colour))    ann_args$colour <- colour
    if (!is.null(linetype))  ann_args$linetype <- linetype
    if (!is.null(linewidth)) ann_args$linewidth <- linewidth
    geom_call <- do.call(
      ggplot2::annotate, c(list("segment"), ann_args, rlang::list2(...))
    )
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
  if (!requireNamespace("hexbin", quietly = TRUE)) {
    cli::cli_abort("{.fn mark_hex} requires the {.pkg hexbin} package.")
  }
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
  do.call(function(...) {
    ._mark_impl(plot, mapping, data, position, geom_fun,
                rasterize, rasterize_dpi, rasterize_dev, ...)
  }, dots)
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
  # Clear the default_color injected by plotit() so the fill legend appears
  plot <- ._clear_default_color(plot)
  # Extract numeric columns from plot data
  raw_data <- plot@gg$data
  num_cols <- vapply(raw_data, is.numeric, logical(1))
  if (sum(num_cols) < 2) {
    cli::cli_abort("{.fn mark_corr} requires at least 2 numeric columns.")
  }
  # Pairwise complete observations so a single NA column does not
  # invalidate the whole correlation matrix.
  mat <- stats::cor(raw_data[, num_cols, drop = FALSE], method = method,
                    use = "pairwise.complete.obs")
  # Hierarchical clustering reorder
  if (reorder) {
    if (anyNA(mat)) {
      # e.g. a zero-variance column yields NA correlations; clustering
      # would crash, so fall back to the original order with a warning.
      cli::cli_warn(
        "Correlation matrix contains NA (zero-variance column?); skipping reorder."
      )
    } else {
      ord <- stats::hclust(stats::as.dist(1 - abs(mat)))$order
      mat <- mat[ord, ord]
    }
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

# ---- mark_errorbar ----
#' Error bar layer
#'
#' Adds error bars showing confidence intervals, standard errors,
#' or other variability measures. Data should include columns for
#' `ymin`/`ymax` (vertical) or `xmin`/`xmax` (horizontal).
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics (must include `ymin`/`ymax`
#'   or `xmin`/`xmax`)
#' @param data Optional data for this layer
#' @param position Position adjustment.
#' @param width Width of the error bar caps (default 0.5).
#' @param orientation `"vertical"` (default) or `"horizontal"`.
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to the underlying geom
#' @return Modified plotit object
#' @references
#' Vega-Lite: \href{https://vega.github.io/vega-lite/docs/errorbar.html}{Errorbar} (composite mark)
#' @examples
#' df <- data.frame(
#'   x = c("A", "B"), y = c(10, 20), ymin = c(8, 18), ymax = c(12, 22))
#' plotit(df, encode(x = x, y = y, ymin = ymin, ymax = ymax)) |>
#'   mark_errorbar(width = 0.3)
#' @export
mark_errorbar <- S7::new_generic(
  "mark_errorbar", "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           width = 0.5, orientation = c("vertical", "horizontal"),
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_errorbar, plotit_class) <- function(
    plot, mapping = NULL, data = NULL, position = NULL, ...,
    width = 0.5, orientation = c("vertical", "horizontal"),
    rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
  orientation <- match.arg(orientation)
  geom_fun <- if (orientation == "horizontal") {
    ggplot2::geom_errorbarh
  } else {
    ggplot2::geom_errorbar
  }
  params <- rlang::list2(...)
  params$width <- width
  do.call(function(...) {
    ._mark_impl(plot, mapping, data, position, geom_fun,
                rasterize, rasterize_dpi, rasterize_dev, ...)
  }, params)
}

# ---- mark_significance ----
#' Significance annotation layer
#'
#' Adds statistical significance brackets and labels between groups.
#' This is a **syntax-sugar composite mark** that combines
#' `mark_rule` and `mark_text` internally.
#'
#' Equivalent expansion:
#' \preformatted{
#'   p |> mark_rule(x = comp$group1, xend = comp$group2,
#'                  y = comp$y_position, yend = comp$y_position) |>
#'        mark_text(x = midpoint, y = comp$y_position + y_offset,
#'                  label = comp$label)
#' }
#'
#' @param plot A plotit object
#' @param comparisons A data frame with columns: `group1`, `group2`,
#'   `label`, and optionally `y_position`. Character columns are
#'   matched against the x-axis variable.
#' @param y_position Numeric vector of y-positions for the brackets.
#'   If omitted, auto-computed from data range.
#' @param y_offset Text offset above the bracket line (default 0.5).
#'   In data units.
#' @param line_colour Colour for the bracket lines (default `"grey30"`).
#' @param line_width Width of bracket lines (default 0.3).
#' @param text_size Size of significance label text (default 3.5).
#' @param tip_length Length of bracket end-tick lines (default 0.02
#'   as fraction of x-axis range).
#' @param ... Additional arguments passed to `mark_text()`
#' @return Modified plotit object
#' @examples
#' df <- data.frame(group = c("A", "B", "C"), value = c(5, 8, 4))
#' comp <- data.frame(
#'   group1 = c("A", "A"), group2 = c("B", "C"),
#'   label = c("**", "ns"))
#' plotit(df, encode(x = group, y = value)) |>
#'   mark_bar() |>
#'   mark_significance(comp, y_position = c(9, 6))
#' @export
mark_significance <- S7::new_generic(
  "mark_significance", "plot",
  function(plot, comparisons, y_position = NULL, y_offset = NULL,
           line_colour = "grey30", line_width = 0.3,
           text_size = 3.5, tip_length = 0.02, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_significance, plotit_class) <- function(
    plot, comparisons, y_position = NULL, y_offset = NULL,
    line_colour = "grey30", line_width = 0.3,
    text_size = 3.5, tip_length = 0.02, ...) {
  if (!is.data.frame(comparisons)) {
    cli::cli_abort("{.arg comparisons} must be a data frame.")
  }
  required <- c("group1", "group2", "label")
  missing_cols <- setdiff(required, names(comparisons))
  if (length(missing_cols) > 0) {
    cli::cli_abort(
      "{.arg comparisons} must have columns: {.val {required}}."
    )
  }
  # Extract data range only when needed for auto-computation (C3)
  d <- plot@gg$data
  y_var <- if (!is.null(plot@gg$mapping$y)) rlang::eval_tidy(plot@gg$mapping$y, d) else NULL
  y_range <- if (!is.null(y_var)) range(y_var, na.rm = TRUE) else c(0, 1)
  y_span <- diff(y_range)
  if (is.null(y_offset)) y_offset <- y_span * 0.02
  # Auto-compute y_position if not provided
  if (is.null(y_position)) {
    if (is.null(y_var)) {
      cli::cli_abort(c(
        "{.fn mark_significance} cannot auto-compute {.arg y_position} without a y mapping.",
        "i" = "Provide {.arg y_position} explicitly."
      ))
    }
    y_position <- y_range[2] + y_span * 0.1 + seq_len(nrow(comparisons)) * y_span * 0.08
  }
  # Get x positions (handle factor/character group1/group2)
  x_var <- rlang::eval_tidy(plot@gg$mapping$x, d)
  x_levels <- if (is.factor(x_var)) levels(x_var) else sort(unique(as.character(x_var)))
  x_positions <- seq_along(x_levels)
  names(x_positions) <- x_levels
  # Draw brackets
  for (i in seq_len(nrow(comparisons))) {
    g1 <- as.character(comparisons$group1[i])
    g2 <- as.character(comparisons$group2[i])
    x1 <- if (g1 %in% names(x_positions)) x_positions[[g1]] else as.numeric(g1)
    x2 <- if (g2 %in% names(x_positions)) x_positions[[g2]] else as.numeric(g2)
    if (is.na(x1) || is.na(x2)) next
    y_pos <- if (i <= length(y_position)) y_position[i] else y_position[1] + (i - 1) * y_span * 0.08
    # Bracket line
    plot@gg <- plot@gg + ggplot2::annotate(
      "segment", x = x1, xend = x2, y = y_pos, yend = y_pos,
      colour = line_colour, linewidth = line_width
    )
    # Left tick
    tick_len <- if (is.factor(x_var)) tip_length * length(x_levels) else tip_length * diff(range(x_positions))
    plot@gg <- plot@gg + ggplot2::annotate(
      "segment", x = x1, xend = x1, y = y_pos - tick_len, yend = y_pos,
      colour = line_colour, linewidth = line_width
    )
    # Right tick
    plot@gg <- plot@gg + ggplot2::annotate(
      "segment", x = x2, xend = x2, y = y_pos - tick_len, yend = y_pos,
      colour = line_colour, linewidth = line_width
    )
    # Label
    plot@gg <- plot@gg + ggplot2::annotate(
      "text", x = (x1 + x2) / 2, y = y_pos + y_offset,
      label = comparisons$label[i], size = text_size, ...
    )
  }
  plot
}

# ---- mark_lollipop ----
#' Lollipop chart layer
#'
#' Creates a lollipop chart: a point anchored by a stem to a reference
#' line. This is a **syntax-sugar composite mark** combining
#' `geom_segment` and `geom_point`.
#'
#' Equivalent expansion:
#' \preformatted{
#'   p |> mark_rule(x = x, xend = x, y = ref, yend = y) |>
#'        mark_point(x = x, y = y)
#' }
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param stem_colour Colour for the stem lines (default `"grey50"`).
#' @param stem_width Line width for stems (default 0.5).
#' @param point_size Point size for the lollipop head (default 3).
#' @param ref Baseline value for the stems (default 0).
#' @param ... Other arguments passed to `mark_point()`
#' @return Modified plotit object
#' @examples
#' df <- data.frame(cat = LETTERS[1:5], val = c(3, 7, 2, 9, 5))
#' plotit(df, encode(x = cat, y = val)) |>
#'   mark_lollipop(point_size = 4, stem_colour = "grey70")
#' @export
mark_lollipop <- S7::new_generic(
  "mark_lollipop", "plot",
  function(plot, mapping = NULL, data = NULL,
           stem_colour = "grey50", stem_width = 0.5,
           point_size = 3, ref = 0, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_lollipop, plotit_class) <- function(
    plot, mapping = NULL, data = NULL,
    stem_colour = "grey50", stem_width = 0.5,
    point_size = 3, ref = 0, ...) {
  d <- data %||% plot@gg$data
  m <- mapping %||% plot@gg$mapping
  # Extract x and y from mapping
  x_col <- rlang::eval_tidy(m$x, d)
  y_col <- rlang::eval_tidy(m$y, d)
  # Stem: segment from `ref` to y.  Values are injected with !! so the
  # aes do not depend on data column names (D4).
  stem_mapping <- encode(x = !!x_col, xend = !!x_col, y = !!ref, yend = !!y_col)
  geome <- ggplot2::geom_segment(
    mapping = stem_mapping,
    colour = stem_colour, linewidth = stem_width
  )
  plot <- .add_geom(plot, geome)
  # Point at the top (inherits the full mapping: x/y/colour/fill)
  plot <- plot |> mark_point(
    mapping = m, data = d, size = point_size, ...
  )
  plot
}

# ---- mark_dumbbell ----
#' Dumbbell comparison chart layer
#'
#' Creates a dumbbell chart with two connected points showing before/after
#' or paired comparisons. This is a **syntax-sugar composite mark**
#' combining two `mark_point` calls and a `geom_segment`.
#'
#' Equivalent expansion:
#' \preformatted{
#'   p |> mark_rule(x = x, xend = x, y = y_start, yend = y_end) |>
#'        mark_point(x = x, y = y_start, colour = colour_start) |>
#'        mark_point(x = x, y = y_end, colour = colour_end)
#' }
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param colour_start Colour for the start point (default `"#4E79A7"`).
#' @param colour_end Colour for the end point (default `"#E15759"`).
#' @param line_colour Colour for the connecting line (default `"grey50"`).
#' @param point_size Size for both dumbbell points (default 3).
#' @param line_width Width for the connecting line (default 1).
#' @param ... Other arguments passed to `mark_point()` calls
#' @return Modified plotit object
#' @examples
#' df <- data.frame(cat = LETTERS[1:5], before = c(3, 5, 2, 8, 4),
#'                  after = c(7, 6, 5, 10, 6))
#' plotit(df, encode(x = cat, y = before, yend = after)) |>
#'   mark_dumbbell()
#' @export
mark_dumbbell <- S7::new_generic(
  "mark_dumbbell", "plot",
  function(plot, mapping = NULL, data = NULL,
           colour_start = "#4E79A7", colour_end = "#E15759",
           line_colour = "grey50", point_size = 3,
           line_width = 1, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_dumbbell, plotit_class) <- function(
    plot, mapping = NULL, data = NULL,
    colour_start = "#4E79A7", colour_end = "#E15759",
    line_colour = "grey50", point_size = 3,
    line_width = 1, ...) {
  d <- data %||% plot@gg$data
  m <- mapping %||% plot@gg$mapping
  x_col <- rlang::eval_tidy(m$x, d)
  y_col <- rlang::eval_tidy(m$y, d)
  if (is.null(m$yend)) {
    cli::cli_abort(c(
      "{.fn mark_dumbbell} requires a {.arg yend} mapping for the second point.",
      "i" = "Use {.code encode(x = ..., y = ..., yend = ...)}."
    ))
  }
  yend_col <- rlang::eval_tidy(m$yend, d)
  # Connecting line (values injected with !! so the aes do not depend on
  # data column names, D4)
  segment_mapping <- encode(
    x = !!x_col, xend = !!x_col,
    y = !!y_col, yend = !!yend_col
  )
  geome <- ggplot2::geom_segment(
    mapping = segment_mapping,
    colour = line_colour, linewidth = line_width
  )
  plot <- .add_geom(plot, geome)
  # Start point
  start_mapping <- encode(x = !!x_col, y = !!y_col)
  plot <- plot |>
    mark_point(mapping = start_mapping, data = d,
               colour = colour_start, size = point_size, ...)
  # End point
  end_mapping <- encode(x = !!x_col, y = !!yend_col)
  plot <- plot |>
    mark_point(mapping = end_mapping, data = d,
               colour = colour_end, size = point_size, ...)
  plot
}

# ---- mark_beeswarm ----
#' Beeswarm plot layer
#'
#' Adds a beeswarm (quasirandom scatter) layer to avoid overplotting
#' for one-dimensional distributions. Requires the
#' \pkg{ggbeeswarm} package.
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param position Position adjustment.
#' @param method Method for point placement:
#'   `"swarm"`, `"compactswarm"`, `"hex"`, `"square"`,
#'   `"center"`, or `"centre"`.
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to `geom_beeswarm`
#' @return Modified plotit object
#' @references
#' AntV G2: \href{https://g2.antv.antgroup.com/en/api/mark/beeswarm}{Beeswarm} (corelib)
#' @examples
#' \dontrun{
#' if (requireNamespace("ggbeeswarm", quietly = TRUE)) {
#'   plotit(iris, encode(x = Species, y = Sepal.Length)) |>
#'     mark_beeswarm()
#' }
#' }
#' @export
mark_beeswarm <- S7::new_generic(
  "mark_beeswarm", "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           method = c("swarm", "compactswarm", "hex", "square", "center", "centre"),
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_beeswarm, plotit_class) <- function(
    plot, mapping = NULL, data = NULL, position = NULL, ...,
    method = c("swarm", "compactswarm", "hex", "square", "center", "centre"),
    rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
  if (!requireNamespace("ggbeeswarm", quietly = TRUE)) {
    cli::cli_abort("{.fn mark_beeswarm} requires the {.pkg ggbeeswarm} package.")
  }
  method <- match.arg(method)
  params <- rlang::list2(...)
  params$method <- method[1]
  # geom_beeswarm implements its own collision placement; the global
  # auto-dodge position is not supported (B3).
  do.call(function(...) {
    ._mark_impl(plot, mapping, data, position, ggbeeswarm::geom_beeswarm,
                rasterize, rasterize_dpi, rasterize_dev,
                auto_dodge = FALSE, ...)
  }, params)
}

# ---- mark_sankey ----
#' Sankey flow diagram layer
#'
#' Creates a Sankey diagram showing directed flows between nodes.
#' Requires the \pkg{ggsankey} package.
#'
#' Accepts an **edges table** (data.frame) with `source`, `target`, and
#' optionally `value` columns. The mark internally builds the node-link
#' structure — no need for `ggsankey::make_long()` preprocessing.
#'
#' @param plot A plotit object
#' @param mapping Aesthetics. Structural aesthetics:
#'   \code{source} (required), \code{target} (required), \code{value} (optional).
#'   Visual aesthetics: \code{fill} (node colour, default maps to node
#'   identity, compatible with \code{scale_fill_*}).
#' @param data Optional data for this layer
#' @param position Position adjustment.
#' @param node_colour Default colour for node rectangles (used when no
#'   \code{fill} mapping is present, default \code{"grey30"}).
#' @param flow_alpha Alpha transparency for flow ribbons (default 0.5).
#' @param rasterize If \code{TRUE}, rasterize via \code{ggrastr::rasterise()}.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default \code{"cairo"}).
#' @param ... Other arguments passed to \code{geom_sankey}
#' @return Modified plotit object
#' @references
#' AntV G2: \href{https://g2.antv.antgroup.com/en/api/mark/sankey}{Sankey} (graphlib)
#' @examples
#' \dontrun{
#' if (requireNamespace("ggsankey", quietly = TRUE)) {
#'   df <- data.frame(
#'     source = c("A", "A", "B", "B", "C"),
#'     target = c("B", "C", "C", "D", "D"),
#'     value  = c(10, 5, 8, 3, 6)
#'   )
#'   df |> plotit(encode(source = source, target = target,
#'                       value = value, fill = source)) |>
#'     mark_sankey() |>
#'     scale_fill(range = "viridis")
#' }
#' }
#' @export
mark_sankey <- S7::new_generic(
  "mark_sankey", "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           node_colour = "grey30", flow_alpha = 0.5,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_sankey, plotit_class) <- function(
    plot, mapping = NULL, data = NULL, position = NULL, ...,
    node_colour = "grey30", flow_alpha = 0.5,
    rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
  if (!requireNamespace("ggsankey", quietly = TRUE)) {
    cli::cli_abort("{.fn mark_sankey} requires the {.pkg ggsankey} package.")
  }

  edges <- data %||% plot@gg$data
  mapping <- mapping %||% plot@gg$mapping

  # --- Extract structural aesthetics: source, target, value ---
  if (is.null(mapping$source) || is.null(mapping$target)) {
    cli::cli_abort(c(
      "{.fn mark_sankey} requires {.arg source} and {.arg target} aesthetics.",
      "i" = "Map them in {.fn plotit}: {.code encode(source = ..., target = ..., value = ...)}.",
      "i" = "Or pass {.arg mapping} to {.fn mark_sankey} directly."
    ))
  }
  src <- as.character(rlang::eval_tidy(mapping$source, edges))
  tgt <- as.character(rlang::eval_tidy(mapping$target, edges))
  val <- rlang::eval_tidy(mapping$value, edges)
  if (is.null(val)) val <- rep(1, length(src))

  # --- Convert edges table to ggsankey long format ---
  n <- length(src)
  sankey_data <- data.frame(
    x         = rep("source", 2 * n),
    node      = c(src, tgt),
    next_x    = c(rep("target", n), rep(NA, n)),
    next_node = c(tgt, rep(NA, n)),
    value     = c(val, rep(NA, n)),
    stringsAsFactors = FALSE
  )

  # --- Build fill aesthetic ---
  # plotit() injects fill = I(default_color) as a constant; it is not a
  # real data mapping and must not drive the node palette.
  has_fill <- !is.null(mapping$fill) && !inherits(mapping$fill, "AsIs")
  if (has_fill) {
    fill_vals <- as.character(rlang::eval_tidy(mapping$fill, edges))
    sankey_data$fill_grp <- c(fill_vals, fill_vals)
  } else {
    sankey_data$fill_grp <- sankey_data$node
  }

  # The flow fill mapping needs a legend; drop the default_color guides
  # suppression injected by plotit().
  plot <- ._clear_default_color(plot)

  # Add layers incrementally on top of the existing plot so the theme,
  # scales and previously added layers are preserved (A4).
  flow_mapping <- ggplot2::aes(
    x = x, next_x = next_x, node = node, next_node = next_node,
    fill = fill_grp, value = value
  )
  if (!has_fill) {
    plot@gg <- plot@gg + ggsankey::geom_sankey(
      data = sankey_data, mapping = flow_mapping, inherit.aes = FALSE,
      node.fill = node_colour, flow.alpha = flow_alpha, ...)
  } else {
    plot@gg <- plot@gg + ggsankey::geom_sankey(
      data = sankey_data, mapping = flow_mapping, inherit.aes = FALSE,
      flow.alpha = flow_alpha, ...)
  }

  # Node labels
  text_mapping <- ggplot2::aes(
    x = x, next_x = next_x, node = node, next_node = next_node,
    label = node
  )
  plot@gg <- plot@gg + ggsankey::geom_sankey_text(
    data = sankey_data, mapping = text_mapping, inherit.aes = FALSE,
    size = 3, check_overlap = FALSE)
  plot
}

# ---- mark_treemap ----
#' Treemap layer
#'
#' Creates a treemap showing hierarchical data as nested rectangles.
#' Requires the \pkg{treemapify} package. Data should contain
#' `area`, `subgroup`, and optionally `subgroup2` columns.
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics. Must include `area` for
#'   rectangle sizing.
#' @param data Optional data for this layer
#' @param position Position adjustment.
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to `geom_treemap`
#' @return Modified plotit object
#' @references
#' AntV G2: \href{https://g2.antv.antgroup.com/en/api/mark/treemap}{Treemap} (graphlib)
#' @examples
#' \dontrun{
#' if (requireNamespace("treemapify", quietly = TRUE)) {
#'   df <- data.frame(
#'     group = c("A", "B", "C"),
#'     subgroup = c("a1", "a2", "b1"),
#'     size = c(30, 20, 50))
#'   plotit(df, encode(area = size, fill = group,
#'                     subgroup = subgroup)) |>
#'     mark_treemap()
#' }
#' }
#' @export
mark_treemap <- S7::new_generic(
  "mark_treemap", "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_treemap, plotit_class) <- function(
    plot, mapping = NULL, data = NULL, position = NULL, ...,
    rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
  if (!requireNamespace("treemapify", quietly = TRUE)) {
    cli::cli_abort("{.fn mark_treemap} requires the {.pkg treemapify} package.")
  }
  if (!is.null(mapping) && !is.null(mapping$fill)) {
    plot <- ._clear_default_color(plot, mapping)
  }
  # geom_treemap lays out rectangles itself; the global auto-dodge
  # position is ignored by treemapify (D6).
  geom <- treemapify::geom_treemap(mapping = mapping, data = data, ...)
  plot <- .add_geom(plot, geom,
    rasterize = rasterize, rasterize_dpi = rasterize_dpi,
    rasterize_dev = rasterize_dev
  )
  plot
}

# ---- mark_network ----
#' Network / force-directed graph layer
#'
#' Creates a network visualization with nodes and edges.
#' Requires the \pkg{ggraph} and \pkg{igraph} packages.
#'
#' **Dual data source design**: The main data (passed to \code{plotit()}) is a
#' **nodes** data.frame.  Edges are passed via the \code{edges} parameter with
#' their own \code{encode_edges}.  Node aesthetics (\code{color}, \code{size},
#' \code{label}) work with standard \code{scale_*} functions.
#'
#' @param plot A plotit object. The data should be a data.frame of **nodes**.
#' @param edges A data.frame of **edges**.
#' @param encode_edges An \code{encode()} object with \code{source} (required),
#'   \code{target} (required), \code{weight} (optional).
#' @param layout Layout algorithm: \code{"auto"}, \code{"circle"},
#'   \code{"linear"}, \code{"bipartite"}, or \code{"manual"}.
#' @param edge_colour Default colour for edges (default \code{"grey70"}).
#' @param node_colour Default fill colour for nodes (default \code{"#4E79A7"}).
#' @param node_size Default size for nodes (default 5).
#' @param ... Other arguments passed to \code{ggraph::geom_edge_link}
#' @return Modified plotit object
#' @references
#' AntV G2: \href{https://g2.antv.antgroup.com/en/api/mark/force-graph}{ForceGraph}
#' @examples
#' \dontrun{
#' if (requireNamespace("ggraph", quietly = TRUE) &&
#'     requireNamespace("igraph", quietly = TRUE)) {
#'   nodes <- data.frame(
#'     name  = c("A", "B", "C", "D"),
#'     group = c("X", "Y", "X", "Y"),
#'     value = c(10, 20, 15, 25)
#'   )
#'   edges <- data.frame(
#'     from   = c("A", "A", "B", "C"),
#'     to     = c("B", "C", "C", "D"),
#'     weight = c(1, 2, 3, 4)
#'   )
#'   nodes |> plotit(encode(color = group, size = value, label = name)) |>
#'     mark_network(
#'       edges = edges,
#'       encode_edges = encode(source = from, target = to, weight = weight)
#'     ) |>
#'     scale_color(range = "viridis") |>
#'     scale_size(range = c(5, 20))
#' }
#' }
#' @export
mark_network <- S7::new_generic(
  "mark_network", "plot",
  function(plot,
           edges = NULL,
           encode_edges = NULL,
           layout = c("auto", "circle", "linear", "bipartite", "manual"),
           edge_colour = "grey70", edge_width = 0.5,
           node_colour = "#4E79A7", node_size = 5, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_network, plotit_class) <- function(
    plot,
    edges = NULL,
    encode_edges = NULL,
    layout = c("auto", "circle", "linear", "bipartite", "manual"),
    edge_colour = "grey70", edge_width = 0.5,
    node_colour = "#4E79A7", node_size = 5, ...) {
  if (!requireNamespace("ggraph", quietly = TRUE)) {
    cli::cli_abort("{.fn mark_network} requires the {.pkg ggraph} package.")
  }
  if (!requireNamespace("igraph", quietly = TRUE)) {
    cli::cli_abort("{.fn mark_network} requires the {.pkg igraph} package.")
  }
  layout <- match.arg(layout)

  nodes <- plot@gg$data
  if (is.null(nodes) || !is.data.frame(nodes)) {
    cli::cli_abort(
      "{.fn mark_network} expects a data.frame of nodes as plot data."
    )
  }

  node_id_col <- names(nodes)[1]
  node_ids <- as.character(nodes[[node_id_col]])
  bad_ids <- duplicated(node_ids) | is.na(node_ids) | !nzchar(node_ids)
  if (any(bad_ids)) {
    cli::cli_abort(c(
      "{.fn mark_network} requires a unique, non-NA node id.",
      "x" = "The first column {.val {node_id_col}} contains {sum(bad_ids)} duplicate/empty/NA value(s).",
      "i" = "Ensure the first column of the nodes data frame is a unique id (e.g. name)."
    ))
  }

  if (!is.null(edges) && !is.null(encode_edges)) {
    edge_src <- as.character(rlang::eval_tidy(encode_edges$source, edges))
    edge_tgt <- as.character(rlang::eval_tidy(encode_edges$target, edges))
    edge_wt  <- rlang::eval_tidy(encode_edges$weight, edges)
    edges_df <- data.frame(from = edge_src, to = edge_tgt,
                           weight = edge_wt %||% rep(1, length(edge_src)),
                           stringsAsFactors = FALSE)
  } else {
    edges_df <- data.frame(from = character(0), to = character(0))
  }

  graph_obj <- tryCatch(
    igraph::graph_from_data_frame(
      d = edges_df,
      vertices = nodes,
      directed = FALSE
    ),
    error = function(e) cli::cli_abort(c(
      "Failed to build the network graph from nodes and edges.",
      "x" = conditionMessage(e),
      "i" = "Ensure {.arg edges} reference node ids from the first column of the nodes data."
    ))
  )

  layout_name <- switch(layout,
    auto="fr", circle="circle",
    linear="linear", bipartite="bipartite",
    manual="nicely")

  gg <- ggraph::ggraph(graph_obj, layout = layout_name) +
    ggraph::geom_edge_link(edge_colour = edge_colour,
                           edge_width = edge_width, ...)

  node_aes <- plot@gg$mapping
  node_mapping <- ggplot2::aes()
  if (!is.null(node_aes)) {
    # Skip I() constants injected by plotit() (D5): copying them into the
    # layer would make later scale_color()/scale_fill() calls ineffective.
    if (!is.null(node_aes$colour) && !inherits(node_aes$colour, "AsIs")) {
      node_mapping$colour <- node_aes$colour
    }
    if (!is.null(node_aes$fill) && !inherits(node_aes$fill, "AsIs")) {
      node_mapping$fill   <- node_aes$fill
    }
    if (!is.null(node_aes$size)) node_mapping$size <- node_aes$size
  }

  gg <- gg + ggraph::geom_node_point(
    mapping = node_mapping, fill = node_colour, size = node_size)

  if (!is.null(node_aes$label)) {
    gg <- gg + ggraph::geom_node_text(
      mapping = ggplot2::aes(label = !!node_aes$label),
      repel = FALSE, size = 3)
  }

  # Inherit the plotit theme so the default look is preserved (A4).
  # ggraph builds its own plot object, so previously added layers and
  # scales cannot be carried over -- documented limitation of the
  # network renderer.
  gg <- gg + plot@gg$theme +
    ggplot2::theme(
      axis.line = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),
      axis.text = ggplot2::element_blank(),
      axis.title = ggplot2::element_blank()
    )
  plot@gg <- gg
  plot
}
# ---- mark_chord ----
#' Chord diagram layer
#'
#' Creates a chord diagram showing pairwise relationships between groups.
#' Requires the \pkg{circlize} package.
#'
#' Accepts an **edges table** (data.frame) with \code{source}, \code{target},
#' and optionally \code{value} columns. The mark internally builds the
#' adjacency matrix.
#'
#' @param plot A plotit object
#' @param mapping Aesthetics. Structural aesthetics:
#'   \code{source} (required), \code{target} (required), \code{value} (optional).
#'   Visual aesthetics: \code{fill} (sector colour, default maps to source
#'   identity, compatible with \code{scale_fill_*}).
#' @param data Optional data for this layer
#' @param gap_width Gap between sectors in degrees (default 4).
#' @param link_alpha Alpha transparency for links (default 0.5).
#' @param rasterize If \code{TRUE}, rasterize via \code{ggrastr::rasterise()}.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default \code{"cairo"}).
#' @param ... Other arguments passed to \code{circlize::chordDiagram}
#' @return Modified plotit object
#'
#' **Renderer note**: `mark_chord` renders natively with `circlize` on the
#' current graphics device (not through the ggplot2 build system) and
#' replaces the plot's `gg` with an empty ggplot.  Layers added before or
#' after it therefore do not share a coordinate system -- treat it as a
#' standalone renderer.
#' @references
#' AntV G2: \href{https://g2.antv.antgroup.com/en/api/mark/chord}{Chord} (graphlib)
#' @examples
#' \dontrun{
#' if (requireNamespace("circlize", quietly = TRUE)) {
#'   df <- data.frame(
#'     source = c("A", "A", "B", "B", "C"),
#'     target = c("B", "C", "C", "D", "D"),
#'     value  = c(5, 3, 4, 2, 6)
#'   )
#'   df |> plotit(encode(source = source, target = target,
#'                       value = value, fill = source)) |>
#'     mark_chord() |>
#'     scale_fill(range = "viridis")
#' }
#' }
#' @export
mark_chord <- S7::new_generic(
  "mark_chord", "plot",
  function(plot, mapping = NULL, data = NULL,
           gap_width = 4, link_alpha = 0.5,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo",
           ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_chord, plotit_class) <- function(
    plot, mapping = NULL, data = NULL,
    gap_width = 4, link_alpha = 0.5,
    rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo",
    ...) {
  if (!requireNamespace("circlize", quietly = TRUE)) {
    cli::cli_abort("{.fn mark_chord} requires the {.pkg circlize} package.")
  }

  edges <- data %||% plot@gg$data
  mapping <- mapping %||% plot@gg$mapping

  # Auto-detect data format:
  #   If mapping has source/target -> new API (edges table)
  #   Otherwise -> fallback (from/to legacy, Var1/Var2/Freq, or matrix)
  if (!is.null(mapping$source) && !is.null(mapping$target)) {
    src <- as.character(rlang::eval_tidy(mapping$source, edges))
    tgt <- as.character(rlang::eval_tidy(mapping$target, edges))
    val <- rlang::eval_tidy(mapping$value, edges) %||% rep(1, length(src))
  } else if (is.data.frame(edges)) {
    if (all(c("from", "to") %in% names(edges))) {
      # Legacy API compatibility: from/to/value columns map to source/target/value
      src <- as.character(edges[["from"]])
      tgt <- as.character(edges[["to"]])
      val <- edges[["value"]] %||% rep(1, length(src))
    } else if (all(c("Var1", "Var2", "Freq") %in% names(edges))) {
      mat <- xtabs(Freq ~ Var1 + Var2, data = edges)
      circlize::chordDiagram(mat, transparency = 1 - link_alpha,
        annotationTrack = "grid", preAllocateTracks = list(track.height = 0.1), ...)
      gg <- ggplot2::ggplot() + ggplot2::theme_void()
      plot@gg <- gg
      return(plot)
    } else {
      cli::cli_abort(c(
        "{.fn mark_chord} needs {.code encode(source =, target =, value =)}.",
        "i" = "Or provide {.val from}/{.val to} (legacy) or {.val Var1}/{.val Var2}/{.val Freq} columns."
      ))
    }
  } else {
    mat <- as.matrix(edges)
    circlize::chordDiagram(mat, transparency = 1 - link_alpha,
      annotationTrack = "grid", preAllocateTracks = list(track.height = 0.1), ...)
    gg <- ggplot2::ggplot() + ggplot2::theme_void()
    plot@gg <- gg
    return(plot)
  }

  # --- Build adjacency matrix ---
  all_nodes <- unique(c(src, tgt))
  mat <- matrix(0, nrow = length(all_nodes), ncol = length(all_nodes),
                dimnames = list(all_nodes, all_nodes))
  for (i in seq_along(src)) {
    mat[src[i], tgt[i]] <- mat[src[i], tgt[i]] + val[i]
  }

  # --- Build sector colours from fill mapping ---
  # plotit() injects fill = I(default_color) as a constant; it is not a
  # real data mapping and must not drive the sector palette.
  has_fill <- !is.null(mapping$fill) && !inherits(mapping$fill, "AsIs")
  if (has_fill) {
    fill_vals <- as.character(rlang::eval_tidy(mapping$fill, edges))
    node_fill <- stats::setNames(rep("grey60", length(all_nodes)), all_nodes)
    for (i in seq_along(src)) {
      node_fill[src[i]] <- fill_vals[i]
    }
    grid_col <- node_fill[all_nodes]
  } else {
    grid_col <- "grey80"
  }

  gg <- ggplot2::ggplot() + ggplot2::theme_void()
  plot@gg <- gg

  circlize::chordDiagram(mat,
    transparency = 1 - link_alpha,
    grid.col = grid_col,
    annotationTrack = "grid",
    preAllocateTracks = list(track.height = 0.1),
    ...
  )
  plot
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
