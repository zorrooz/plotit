#' @include class.R graph.R mark_style.R
NULL

# ---- Internal helpers ----

# Shared mark logic: resolve position (auto-dodge or explicit), build geom,
# clear default_color if the layer provides colour/fill, apply unified style
# defaults, rasterize.
#' Shared mark implementation: resolve position, clear default_color,
#' apply style defaults, rasterise.
#' @noRd
#' @keywords internal
._mark_impl <- function(plot, mapping, data, position, geom_fun,
                        rasterize, rasterize_dpi, rasterize_dev,
                        auto_dodge = TRUE, bind_aes = NULL, mark_name = NULL,
                        ...) {
  # Graph plots: resolve ~table references and auto-bind layout geometry.
  resolved <- ._resolve_layer_data(data, plot)
  data <- resolved$data
  dots <- rlang::list2(...)
  if (resolved$from_graph) {
    mapping <- ._auto_bind_geometry(mapping, data, scope = bind_aes)
    # Layers referencing graph tables carry complete mappings of their own;
    # never merge the (empty) global mapping on top of them.
    dots$inherit.aes <- FALSE
  }
  # Only clear default_color when the layer actually provides colour/fill
  if (!is.null(mapping) && (!is.null(mapping$colour) || !is.null(mapping$fill))) {
    plot <- ._clear_default_color(plot, mapping)
  }
  # Token default palette for layer-level channels that no managed scale
  # covers yet (construction attached globals; explicit relational pipelines
  # start unmanaged).  Keeps every path on the same curated palettes without
  # ever clobbering a user scale_*().
  if (!is.null(mapping)) {
    unmanaged <- setdiff(
      intersect(c("colour", "fill"), names(mapping)),
      ._colour_managed_get(plot)
    )
    for (aes_name in unmanaged) {
      sc <- ._default_colour_scale(aes_name, data %||% plot@gg$data, mapping[[aes_name]])
      if (!is.null(sc)) {
        plot@gg <- plot@gg + sc
        plot <- ._colour_managed_add(plot, aes_name)
      }
    }
  }
  # Unified mark style defaults (see R/mark_style.R).  Runs after the
  # default_color clear so gating sees the final mapping state.
  dots <- ._apply_mark_defaults(plot, mapping, dots, mark_name)
  pos <- position
  if (is.null(pos) && auto_dodge && !is.null(plot@meta@dodge) && plot@meta@dodge > 0) {
    pos <- ggplot2::position_dodge(plot@meta@dodge)
  }
  geom <- if (is.null(pos)) {
    do.call(geom_fun, c(list(mapping = mapping, data = data), dots))
  } else {
    do.call(geom_fun, c(list(mapping = mapping, data = data, position = pos), dots))
  }
  plot <- .add_geom(plot, geom,
    rasterize = rasterize, rasterize_dpi = rasterize_dpi,
    rasterize_dev = rasterize_dev
  )
  # Closed-cell heatmap chrome: tiles span the full data range, so axis
  # lines/ticks double the grid the cells already draw and expansion padding
  # would detach cells from the panel edge (AGENTS.md 6, cell-chrome rule).
  if (!is.null(mark_name) && mark_name %in% c("mark_rect", "mark_corr")) {
    plot@gg <- ._gg_tile_chrome(plot@gg)
  }
  plot
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
  mark_name <- deparse(substitute(generic))
  # Restrict graph auto-binding to what this mark family understands.
  bind_aes <- ._MARK_BIND_AES[[mark_name]]

  S7::method(generic, plotit_class) <- function(
    plot, mapping = NULL, data = NULL, position = NULL, ...,
    rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo"
  ) {
    ._mark_impl(plot, mapping, data, position, geom_fun,
      rasterize, rasterize_dpi, rasterize_dev,
      bind_aes = bind_aes, mark_name = mark_name, ...
    )
  }
  invisible()
}

# Standard mark generic: every basic mark shares one signature, so the
# declaration collapses to `mark_x <- ._make_mark_generic("mark_x")`.
# Marks with extra parameters (e.g. mark_text) keep their own generic.
._make_mark_generic <- function(name) {
  S7::new_generic(
    name, "plot",
    function(plot, mapping = NULL, data = NULL, position = NULL, ...,
             rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
      S7::S7_dispatch()
    }
  )
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
mark_point <- ._make_mark_generic("mark_point")
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
mark_line <- ._make_mark_generic("mark_line")
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
mark_boxplot <- ._make_mark_generic("mark_boxplot")
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
mark_histogram <- ._make_mark_generic("mark_histogram")
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
mark_density <- ._make_mark_generic("mark_density")
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
mark_area <- ._make_mark_generic("mark_area")
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
  rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo"
) {
  if (repel) {
    if (!requireNamespace("ggrepel", quietly = TRUE)) {
      cli::cli_abort("{.arg repel = TRUE} requires the {.pkg ggrepel} package.")
    }
    geom_fun <- ggrepel::geom_text_repel
  } else {
    geom_fun <- ggplot2::geom_text
  }
  ._mark_impl(
    plot, mapping, data, position, geom_fun,
    rasterize, rasterize_dpi, rasterize_dev,
    bind_aes = ._MARK_BIND_AES$mark_text, mark_name = "mark_text", ...
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
mark_violin <- ._make_mark_generic("mark_violin")
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
#' @examplesIf(requireNamespace("sf", quietly = TRUE))
#' nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
#' plotit(nc, encode(geometry = geometry)) |> mark_map()
#' @export
mark_map <- ._make_mark_generic("mark_map")

#' @export
S7::method(mark_map, plotit_class) <- function(
  plot, mapping = NULL, data = NULL, position = NULL, ...,
  rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo"
) {
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
mark_rect <- ._make_mark_generic("mark_rect")
#' @export
S7::method(mark_rect, plotit_class) <- function(
  plot, mapping = NULL, data = NULL, position = NULL, ...,
  rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo"
) {
  # Corner aesthetics (e.g. auto-bound treemap/sankey geometry) route to
  # geom_rect; centered aesthetics keep the classic geom_tile behaviour.
  peeked <- ._resolve_layer_data(data, plot)
  if (peeked$from_graph) {
    mapping <- ._auto_bind_geometry(mapping, peeked$data,
      scope = ._MARK_BIND_AES$mark_rect
    )
  }
  corners <- !is.null(mapping) &&
    all(c("xmin", "xmax", "ymin", "ymax") %in% names(mapping))
  geom_fun <- if (corners) ggplot2::geom_rect else ggplot2::geom_tile
  ._mark_impl(plot, mapping, data, position, geom_fun,
    rasterize, rasterize_dpi, rasterize_dev,
    bind_aes = ._MARK_BIND_AES$mark_rect, mark_name = "mark_rect", ...
  )
}

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
#' @param colour Line colour (default `"grey50"`, the unified soft neutral;
#'   ggplot2's black is restored by passing `colour = "black"`).
#' @param linetype Line type
#' @param linewidth Line width in mm (default 0.5).
#' @param mapping Optional aesthetics for data-driven segments
#'   (`x`/`xend`/`y`/`yend`); layout tables bind them automatically.
#' @param data Optional data for segment mode: one segment per row.
#'   Accepts a data.frame or a `~table` reference into graph data.
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
#'
#' # Data-driven segments: network edges from a layout_* transform
#' e <- data.frame(source = c("a", "a", "b"), target = c("b", "c", "c"))
#' as_graph(e) |>
#'   plotit() |>
#'   layout_force(seed = 1) |>
#'   mark_point(data = ~nodes) |>
#'   mark_rule(data = ~edges, colour = "grey70")
#' @export
mark_rule <- S7::new_generic(
  "mark_rule", "plot",
  function(plot, mapping = NULL, data = NULL,
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
  plot, mapping = NULL, data = NULL,
  xintercept = NULL, yintercept = NULL,
  slope = NULL, intercept = NULL,
  x = NULL, xend = NULL, y = NULL, yend = NULL,
  colour = NULL, linetype = NULL, linewidth = NULL,
  ...,
  rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo"
) {
  # Data-driven segment mode: render one segment per row (e.g. network
  # edges from a layout_* transform).  Endpoints come from the mapping
  # (auto-bound from layout geometry when data is a ~table reference).
  if (!is.null(data)) {
    scalar_endpoints <- any(
      !is.null(x), !is.null(xend),
      !is.null(y), !is.null(yend)
    )
    if (scalar_endpoints) {
      cli::cli_abort(c(
        "Scalar endpoints conflict with {.arg data} in {.fn mark_rule}.",
        "i" = "Map columns via {.code encode(x = ..., xend = ...)} instead."
      ))
    }
    resolved <- ._resolve_layer_data(data, plot)
    seg_data <- resolved$data
    if (resolved$from_graph) {
      mapping <- ._auto_bind_geometry(mapping, seg_data,
        scope = ._MARK_BIND_AES$mark_rule
      )
    }
    need <- c("x", "xend", "y", "yend")
    if (!all(need %in% names(mapping))) {
      cli::cli_abort(c(
        "{.fn mark_rule} with {.arg data} requires aesthetics \\
         {.val {need}} on the layer.",
        "i" = "Provide them via {.code encode(...)}; layout tables bind \\
               them automatically."
      ))
    }
    static <- rlang::list2(...)
    if (!is.null(colour)) static$colour <- colour
    if (!is.null(linetype)) static$linetype <- linetype
    if (!is.null(linewidth)) static$linewidth <- linewidth
    # Explicit segment mapping: never merge the global aes over it.
    static$inherit.aes <- FALSE
    # do.call splice (not !!!): dynamic dots are unreliable inside
    # byte-compiled package methods.
    return(do.call(
      ._mark_impl,
      c(
        list(plot, mapping, seg_data,
          position = NULL, ggplot2::geom_segment,
          rasterize, rasterize_dpi, rasterize_dev,
          auto_dodge = FALSE,
          mark_name = "mark_rule"
        ),
        static
      )
    ))
  }

  # Build named list of non-NULL params for the geom call
  params <- rlang::list2(...)
  if (!is.null(colour)) params$colour <- colour
  if (!is.null(linetype)) params$linetype <- linetype
  if (!is.null(linewidth)) params$linewidth <- linewidth
  # Unified reference-line default (R/mark_style.R): soft neutral stroke
  # unless the user supplies a colour or maps one themselves.  The AsIs
  # constants injected by plotit() do not render on param geoms, so they
  # must not block the default either (._user_owned_aes).
  if (is.null(params$colour) && !"colour" %in% ._user_owned_aes(plot, mapping)) {
    params$colour <- ._MARK_STYLE$soft
  }
  if (is.null(params$linewidth) && !"linewidth" %in% ._user_owned_aes(plot, mapping)) {
    params$linewidth <- ._MARK_STYLE$lw_thin
  }

  # Dispatch by param combination
  if (!is.null(xintercept)) {
    params$xintercept <- xintercept
    geom_call <- do.call(ggplot2::geom_vline, params)
  } else if (!is.null(yintercept)) {
    params$yintercept <- yintercept
    geom_call <- do.call(ggplot2::geom_hline, params)
  } else if (!is.null(slope) || !is.null(intercept)) {
    if (!is.null(slope)) params$slope <- slope
    if (!is.null(intercept)) params$intercept <- intercept
    geom_call <- do.call(ggplot2::geom_abline, params)
  } else if (!is.null(x) && !is.null(xend) && !is.null(y) && !is.null(yend)) {
    # annotate() avoids the "All aesthetics have length 1" warning that
    # constant aes() mappings trigger on multi-row data (R6).  NULL
    # parameters are omitted -- annotate() requires equal-length params.
    ann_args <- list(x = x, xend = xend, y = y, yend = yend)
    if (!is.null(colour)) ann_args$colour <- colour
    if (!is.null(linetype)) ann_args$linetype <- linetype
    if (!is.null(linewidth)) ann_args$linewidth <- linewidth
    if (is.null(ann_args$colour) && !"colour" %in% ._user_owned_aes(plot, mapping)) {
      ann_args$colour <- ._MARK_STYLE$soft
    }
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
mark_path <- ._make_mark_generic("mark_path")
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
mark_polygon <- ._make_mark_generic("mark_polygon")
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
  rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo"
) {
  params <- rlang::list2(...)
  params$method <- method
  params$formula <- formula
  params$se <- se
  do.call(function(...) {
    ._mark_impl(
      plot, mapping, data, position, ggplot2::geom_smooth,
      rasterize, rasterize_dpi, rasterize_dev,
      bind_aes = ._MARK_BIND_AES$mark_smooth, mark_name = "mark_smooth", ...
    )
  }, params)
}

# ---- mark_hex ----
#' Hexagonal heatmap layer
#'
#' Divides the x-y plane into hexagonal bins and fills each by the
#' count (or other aggregation) of observations in that bin.
#' Ideal for visualizing overplotting in large datasets.
#' The count fill scale defaults to viridis; chain [scale_fill()]
#' afterwards to replace it (last call wins).
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
#' plotit(
#'   ggplot2::diamonds[sample(nrow(ggplot2::diamonds), 1000), ],
#'   encode(x = carat, y = price)
#' ) |> mark_hex(bins = 20)
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
  rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo"
) {
  if (!requireNamespace("hexbin", quietly = TRUE)) {
    cli::cli_abort("{.fn mark_hex} requires the {.pkg hexbin} package.")
  }
  # Track whether the user owns the fill channel before the injected
  # default_color constants are cleared below.
  user_fill <- !is.null(mapping$fill) ||
    (!is.null(plot@gg$mapping$fill) && !inherits(plot@gg$mapping$fill, "AsIs"))
  # The bin-count fill is owned by this closed statistical mark: drop the
  # injected single-colour constants so the count scale can render.
  plot <- ._clear_default_color(plot)
  params <- rlang::list2(...)
  params$bins <- bins
  plot <- do.call(function(...) {
    ._mark_impl(
      plot, mapping, data, position, ggplot2::geom_hex,
      rasterize, rasterize_dpi, rasterize_dev,
      bind_aes = ._MARK_BIND_AES$mark_hex, mark_name = "mark_hex", ...
    )
  }, params)
  # Default continuous fill (AGENTS.md §6): viridis unless the user mapped
  # their own fill.  A later scale_fill() call replaces it (last wins);
  # replacement of a construction-attached scale is intended -> suppressed.
  if (!user_fill) {
    plot <- suppressMessages(scale_fill(plot, trans = "identity", range = "viridis"))
  }
  plot
}

# ---- mark_density_2d ----
#' 2D density contour layer
#'
#' Adds 2D kernel density estimate contours. Use `filled = TRUE`
#' for filled density bands via [ggplot2::geom_density_2d_filled];
#' filled bands default to a discrete viridis fill scale, replaceable
#' by chaining [scale_fill()] afterwards.
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
  rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo"
) {
  geom_fun <- if (filled) ggplot2::geom_density_2d_filled else ggplot2::geom_density_2d
  dots <- rlang::list2(...)
  if (!is.null(bins)) dots$bins <- bins
  # Filled bands map fill to a computed `level` factor owned by this closed
  # statistical mark: clear injected colour constants and default the band
  # scale to viridis (AGENTS.md §6).
  if (filled) {
    plot <- ._clear_default_color(plot)
  }
  plot <- do.call(function(...) {
    ._mark_impl(
      plot, mapping, data, position, geom_fun,
      rasterize, rasterize_dpi, rasterize_dev,
      bind_aes = ._MARK_BIND_AES$mark_density, mark_name = "mark_density_2d", ...
    )
  }, dots)
  if (filled) {
    plot <- suppressMessages(scale_fill(plot, trans = "discrete", range = "viridis"))
  }
  plot
}

# ---- transform_corr ----
#' Correlation preprocessing transform
#'
#' Computes pairwise correlations over the numeric columns of `data` and
#' melts the matrix into a long-form table (`Var1`, `Var2`, `value`),
#' optionally reordering rows/columns by hierarchical clustering.
#' [mark_corr()] is sugar over this transform plus a tile layer; call it
#' directly when you need the table for custom rendering or inspection.
#'
#' @param data A data.frame with at least two numeric columns.
#' @param method Correlation method: `"pearson"` (default), `"spearman"`,
#'   or `"kendall"`.
#' @param reorder If `TRUE` (default), reorder rows and columns by
#'   hierarchical clustering.  Skipped with a warning when the matrix
#'   contains NA (e.g. zero-variance columns).
#' @return A data.frame with columns `Var1`, `Var2` (factors) and
#'   `value` (numeric correlation).
#' @examples
#' head(transform_corr(mtcars[, c("mpg", "disp", "hp")]))
#' @export
transform_corr <- function(data,
                           method = c("pearson", "spearman", "kendall"),
                           reorder = TRUE) {
  method <- match.arg(method)
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data.frame.")
  }
  num_cols <- vapply(data, is.numeric, logical(1))
  if (sum(num_cols) < 2) {
    cli::cli_abort(
      "{.fn transform_corr} requires at least 2 numeric columns."
    )
  }
  # Pairwise complete observations so a single NA column does not
  # invalidate the whole correlation matrix.  cor() additionally warns on
  # zero-variance columns; our own NA/skip-reorder warning covers it.
  mat <- suppressWarnings(stats::cor(data[, num_cols, drop = FALSE],
    method = method,
    use = "pairwise.complete.obs"
  ))
  if (reorder) {
    if (anyNA(mat)) {
      cli::cli_warn(
        "Correlation matrix contains NA (zero-variance column?); skipping reorder."
      )
    } else {
      ord <- stats::hclust(stats::as.dist(1 - abs(mat)))$order
      mat <- mat[ord, ord]
    }
  }
  df <- expand.grid(
    Var1 = factor(rownames(mat), levels = rownames(mat)),
    Var2 = factor(colnames(mat), levels = colnames(mat))
  )
  df$value <- as.vector(mat)
  df
}

# ---- mark_corr ----
#' Correlation matrix heatmap (sugar)
#'
#' Computes a correlation matrix from numeric data columns, optionally
#' reorders by hierarchical clustering, and renders it as a tile heatmap.
#' Sugar over [transform_corr()] plus a tile layer.  The value fill scale
#' defaults to viridis (colour-blind safe); chain [scale_fill()] afterwards
#' to replace it (last call wins).
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
  rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo"
) {
  # Clear the default_color injected by plotit() so the fill legend appears
  plot <- ._clear_default_color(plot)
  raw_data <- plot@gg$data
  if (!is.data.frame(raw_data)) {
    cli::cli_abort("{.fn mark_corr} requires tabular plot data.")
  }
  # Sugar over transform_corr() + tile layer (see §3.3.4a discipline).
  # Routed through the shared mark path so the unified style defaults apply
  # (white hairline separators between tiles, matching mark_rect).
  df <- transform_corr(raw_data, method = method, reorder = reorder)
  mapping <- encode(x = Var1, y = Var2, fill = value)
  # The correlation value channel is mark-owned (magnitude -> sequential
  # viridis, AGENTS.md §6); pre-register it as managed so the layer-level
  # auto-attach does not double-fire.
  plot <- ._colour_managed_add(plot, "fill")
  plot <- do.call(function(...) {
    ._mark_impl(
      plot, mapping, df,
      position = NULL, ggplot2::geom_tile,
      rasterize, rasterize_dpi, rasterize_dev,
      auto_dodge = FALSE, bind_aes = NULL, mark_name = "mark_corr", ...
    )
  }, rlang::list2(...))
  # Default the value fill to the colour-blind-safe continuous scheme; a
  # later scale_fill() call replaces it (last wins).  Suppressed: replacing
  # a construction-attached scale is the documented intent here.
  plot <- suppressMessages(scale_fill(plot, trans = "identity", range = "viridis"))
  # Synthetic Var1/Var2 titles carry no meaning; the variable names on the
  # axes do.  (Axis lines/ticks and expansion are handled by the shared
  # closed-cell chrome inside ._mark_impl.)
  plot@gg <- plot@gg + ggplot2::theme(axis.title = ggplot2::element_blank())
  plot
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
#'   x = c("A", "B"), y = c(10, 20), ymin = c(8, 18), ymax = c(12, 22)
#' )
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
  rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo"
) {
  orientation <- match.arg(orientation)
  geom_fun <- if (orientation == "horizontal") {
    ggplot2::geom_errorbarh
  } else {
    ggplot2::geom_errorbar
  }
  params <- rlang::list2(...)
  params$width <- width
  do.call(function(...) {
    ._mark_impl(
      plot, mapping, data, position, geom_fun,
      rasterize, rasterize_dpi, rasterize_dev,
      bind_aes = ._MARK_BIND_AES$mark_errorbar, mark_name = "mark_errorbar", ...
    )
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
#' @param line_color Colour for the bracket lines
#'   (default `._MARK_STYLE$ink` = `"grey30"`).
#' @param line_width Width of bracket lines (default 0.5).
#' @param text_size Size of significance label text (default 3.2).
#' @param tip_length Length of bracket end-tick lines (default 0.02
#'   as fraction of x-axis range).
#' @param ... Additional arguments passed to `mark_text()`
#' @return Modified plotit object
#' @examples
#' df <- data.frame(group = c("A", "B", "C"), value = c(5, 8, 4))
#' comp <- data.frame(
#'   group1 = c("A", "A"), group2 = c("B", "C"),
#'   label = c("**", "ns")
#' )
#' plotit(df, encode(x = group, y = value)) |>
#'   mark_bar() |>
#'   mark_significance(comp, y_position = c(9, 6))
#' @export
mark_significance <- S7::new_generic(
  "mark_significance", "plot",
  function(plot, comparisons, y_position = NULL, y_offset = NULL,
           line_color = ._MARK_STYLE$ink, line_width = ._MARK_STYLE$lw_thin,
           text_size = ._MARK_STYLE$txt_note, tip_length = 0.02, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_significance, plotit_class) <- function(
  plot, comparisons, y_position = NULL, y_offset = NULL,
  line_color = ._MARK_STYLE$ink, line_width = ._MARK_STYLE$lw_thin,
  text_size = ._MARK_STYLE$txt_note, tip_length = 0.02, ...
) {
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
  # Determine whether the x axis is discrete.  Brackets are then placed
  # by level label and the scale maps them to positions, which stays
  # correct even when scale limits reorder or drop levels -- regardless
  # of whether scale_x() runs before or after this mark (#10).
  x_var <- rlang::eval_tidy(plot@gg$mapping$x, d)
  # NOTE: reads the ggplot scales slot -- an undocumented structure per
  # AGENTS.md 4.6; known exception tracked alongside AD-2 (there is no
  # public API to query an installed scale's class/limits).
  x_scale <- plot@gg$scales$get_scales("x")
  is_discrete_x <- inherits(x_scale, "ScaleDiscretePosition") ||
    (is.null(x_scale) && (is.factor(x_var) || is.character(x_var)))
  x_levels <- if (is.factor(x_var)) levels(x_var) else sort(unique(as.character(x_var)))
  if (is.character(x_scale$limits)) x_levels <- as.character(x_scale$limits)
  # Draw brackets
  for (i in seq_len(nrow(comparisons))) {
    g1 <- as.character(comparisons$group1[i])
    g2 <- as.character(comparisons$group2[i])
    if (is_discrete_x) {
      # Skip comparisons involving levels outside the visible axis
      if (!(g1 %in% x_levels) || !(g2 %in% x_levels)) next
      x1 <- g1
      x2 <- g2
    } else {
      x1 <- as.numeric(g1)
      x2 <- as.numeric(g2)
      if (is.na(x1) || is.na(x2)) next
    }
    y_pos <- if (i <= length(y_position)) y_position[i] else y_position[1] + (i - 1) * y_span * 0.08
    # Bracket line
    plot@gg <- plot@gg + ggplot2::annotate(
      "segment",
      x = x1, xend = x2, y = y_pos, yend = y_pos,
      colour = line_color, linewidth = line_width
    )
    # Left tick
    tick_len <- if (is_discrete_x) tip_length * length(x_levels) else tip_length * diff(range(c(x1, x2)))
    plot@gg <- plot@gg + ggplot2::annotate(
      "segment",
      x = x1, xend = x1, y = y_pos - tick_len, yend = y_pos,
      colour = line_color, linewidth = line_width
    )
    # Right tick
    plot@gg <- plot@gg + ggplot2::annotate(
      "segment",
      x = x2, xend = x2, y = y_pos - tick_len, yend = y_pos,
      colour = line_color, linewidth = line_width
    )
    # Label (midpoint in numeric position space for discrete axes)
    mid_x <- if (is_discrete_x) {
      (match(g1, x_levels) + match(g2, x_levels)) / 2
    } else {
      (x1 + x2) / 2
    }
    plot@gg <- plot@gg + ggplot2::annotate(
      "text",
      x = mid_x, y = y_pos + y_offset,
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
#' @param stem_color Colour for the stem lines
#'   (default `._MARK_STYLE$soft` = `"grey50"`).
#' @param stem_width Line width for stems (default 0.5).
#' @param point_size Point size for the lollipop head (default 3).
#' @param ref Baseline value for the stems (default 0).
#' @param ... Other arguments passed to `mark_point()`
#' @return Modified plotit object
#' @examples
#' df <- data.frame(cat = LETTERS[1:5], val = c(3, 7, 2, 9, 5))
#' plotit(df, encode(x = cat, y = val)) |>
#'   mark_lollipop(point_size = 4, stem_color = "grey70")
#' @export
mark_lollipop <- S7::new_generic(
  "mark_lollipop", "plot",
  function(plot, mapping = NULL, data = NULL,
           stem_color = ._MARK_STYLE$soft, stem_width = ._MARK_STYLE$lw_thin,
           point_size = ._MARK_STYLE$point_head, ref = 0, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_lollipop, plotit_class) <- function(
  plot, mapping = NULL, data = NULL,
  stem_color = ._MARK_STYLE$soft, stem_width = ._MARK_STYLE$lw_thin,
  point_size = ._MARK_STYLE$point_head, ref = 0, ...
) {
  d <- data %||% plot@gg$data
  m <- mapping %||% plot@gg$mapping
  if (is.null(m$x) || is.null(m$y)) {
    cli::cli_abort(c(
      "{.fn mark_lollipop} requires {.arg x} and {.arg y} aesthetics.",
      "i" = "Use {.code encode(x = ..., y = ...)} in {.fn plotit} or \\
             pass a layer {.arg mapping}."
    ))
  }
  # Extract x and y from mapping
  x_col <- rlang::eval_tidy(m$x, d)
  y_col <- rlang::eval_tidy(m$y, d)
  # Stem: segment from `ref` to y.  Values are injected with !! so the
  # aes do not depend on data column names (D4).
  stem_mapping <- encode(x = !!x_col, xend = !!x_col, y = !!ref, yend = !!y_col)
  geome <- ggplot2::geom_segment(
    mapping = stem_mapping,
    colour = stem_color, linewidth = stem_width
  )
  plot <- .add_geom(plot, geome)
  # Point at the top: keep the visual channels (colour/fill/...) but drop
  # positional extras such as `yend`, which geom_point does not understand.
  keep <- setdiff(names(m), c("xend", "yend"))
  point_mapping <- structure(m[keep], class = oldClass(m))
  plot <- plot |> mark_point(
    mapping = point_mapping, data = d, size = point_size, ...
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
#'        mark_point(x = x, y = y_start, colour = color_start) |>
#'        mark_point(x = x, y = y_end, colour = color_end)
#' }
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param color_start Colour for the start point
#'   (default `._MARK_STYLE$primary` = `"#4E79A7"`).
#' @param color_end Colour for the end point
#'   (default `._MARK_STYLE$secondary` = `"#E15759"`).
#' @param line_color Colour for the connecting line
#'   (default `._MARK_STYLE$soft` = `"grey50"`).
#' @param point_size Size for both dumbbell points (default 3).
#' @param line_width Width for the connecting line (default 0.9).
#' @param ... Other arguments passed to `mark_point()` calls
#' @return Modified plotit object
#' @examples
#' df <- data.frame(
#'   cat = LETTERS[1:5], before = c(3, 5, 2, 8, 4),
#'   after = c(7, 6, 5, 10, 6)
#' )
#' plotit(df, encode(x = cat, y = before, yend = after)) |>
#'   mark_dumbbell()
#' @export
mark_dumbbell <- S7::new_generic(
  "mark_dumbbell", "plot",
  function(plot, mapping = NULL, data = NULL,
           color_start = ._MARK_STYLE$primary,
           color_end = ._MARK_STYLE$secondary,
           line_color = ._MARK_STYLE$soft,
           point_size = ._MARK_STYLE$point_head,
           line_width = ._MARK_STYLE$lw_data, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_dumbbell, plotit_class) <- function(
  plot, mapping = NULL, data = NULL,
  color_start = ._MARK_STYLE$primary,
  color_end = ._MARK_STYLE$secondary,
  line_color = ._MARK_STYLE$soft,
  point_size = ._MARK_STYLE$point_head,
  line_width = ._MARK_STYLE$lw_data, ...
) {
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
    colour = line_color, linewidth = line_width
  )
  plot <- .add_geom(plot, geome)
  # Start point
  start_mapping <- encode(x = !!x_col, y = !!y_col)
  plot <- plot |>
    mark_point(
      mapping = start_mapping, data = d,
      colour = color_start, size = point_size, ...
    )
  # End point
  end_mapping <- encode(x = !!x_col, y = !!yend_col)
  plot <- plot |>
    mark_point(
      mapping = end_mapping, data = d,
      colour = color_end, size = point_size, ...
    )
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
#' @examplesIf(requireNamespace("ggbeeswarm", quietly = TRUE))
#' plotit(iris, encode(x = Species, y = Sepal.Length)) |>
#'   mark_beeswarm()
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
  rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo"
) {
  if (!requireNamespace("ggbeeswarm", quietly = TRUE)) {
    cli::cli_abort("{.fn mark_beeswarm} requires the {.pkg ggbeeswarm} package.")
  }
  method <- match.arg(method)
  params <- rlang::list2(...)
  params$method <- method
  # geom_beeswarm implements its own collision placement; the global
  # auto-dodge position is not supported (B3).
  do.call(function(...) {
    ._mark_impl(plot, mapping, data, position, ggbeeswarm::geom_beeswarm,
      rasterize, rasterize_dpi, rasterize_dev,
      auto_dodge = FALSE, bind_aes = ._MARK_BIND_AES$mark_point,
      mark_name = "mark_beeswarm", ...
    )
  }, params)
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
    rasterize, rasterize_dpi, rasterize_dev,
    bind_aes = ._MARK_BIND_AES$mark_bar, mark_name = "mark_bar", ...
  )
}
