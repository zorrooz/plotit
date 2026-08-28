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
  # Record the evaluated kind of every layer-resolved visual channel so a
  # later scale_*() auto-detection can see it (graph plots have no global
  # mapping at all, and the scale layer is otherwise blind).
  if (!is.null(mapping)) {
    channels <- intersect(
      names(mapping),
      c("colour", "fill", "size", "alpha", "shape", "linetype")
    )
    kinds <- list()
    for (ch in channels) {
      col <- tryCatch(
        rlang::eval_tidy(mapping[[ch]], data %||% plot@gg$data),
        error = function(e) NULL
      )
      if (!is.null(col) && !inherits(col, "AsIs")) {
        kinds[[ch]] <- is.factor(col) || is.character(col) || is.logical(col)
      }
    }
    plot <- ._aes_kinds_add(plot, kinds)
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
  plot <- ._add_geom(plot, geom,
    rasterize = rasterize, rasterize_dpi = rasterize_dpi,
    rasterize_dev = rasterize_dev
  )
  # Closed-cell heatmap chrome (AGENTS.md 6, cell-chrome rule): corr /
  # heatmap / rect tiles span the full data range, so axis lines/ticks
  # double the grid the cells already draw and expansion padding would
  # detach cells from the panel edge.  bin2d/hex binnings blank all axis
  # furniture (the count field carries the meaning) while keeping the
  # default padding so edge bins stay whole (see ._gg_cell_chrome).
  cell_chrome <- if (length(mark_name) == 1L) {
    switch(mark_name,
      mark_rect = list(keep_text = TRUE, zero_expand = TRUE),
      mark_corr = list(keep_text = TRUE, zero_expand = TRUE),
      mark_heatmap = list(keep_text = TRUE, zero_expand = TRUE),
      mark_bin2d = list(keep_text = FALSE, zero_expand = FALSE),
      mark_hex = list(keep_text = FALSE, zero_expand = FALSE),
      NULL
    )
  } else {
    NULL
  }
  if (!is.null(cell_chrome)) {
    plot@gg <- do.call(._gg_cell_chrome, c(list(plot@gg), cell_chrome))
  }
  plot
}

# ---- Rasterization helper ----
# Wraps a geom call with ggrastr::rasterise() when rasterize = TRUE
._add_geom <- function(plot, geom_call, rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
  if (rasterize) {
    ._require_pkg("ggrastr", "Rasterization")
    plot@gg <- plot@gg + ggrastr::rasterise(geom_call, dpi = rasterize_dpi, dev = rasterize_dev)
  } else {
    plot@gg <- plot@gg + geom_call
  }
  plot
}

# Unified entry point for marks that must merge named extras (method-level
# formals such as `bins`, `method`, `width`) into the dots before dispatching
# through the shared mark path.  Uses do.call splicing rather than `!!!`:
# dynamic dots are unreliable inside byte-compiled package methods.
#' Dispatch to ._mark_impl with pre-merged extra arguments.
#' @noRd
#' @keywords internal
._impl_with <- function(plot, mapping, data, position, geom_fun,
                        rasterize, rasterize_dpi, rasterize_dev,
                        bind_aes = NULL, mark_name = NULL,
                        extra = list(), auto_dodge = TRUE) {
  do.call(
    function(...) {
      ._mark_impl(
        plot, mapping, data, position, geom_fun,
        rasterize, rasterize_dpi, rasterize_dev,
        auto_dodge = auto_dodge, bind_aes = bind_aes, mark_name = mark_name, ...
      )
    },
    extra
  )
}

# Attach the default fill scale for a mark-owned derived channel (corr
# value / hex count / density level).  Internal installs replace the
# construction-time scale by design, so ggplot2's replacement message is
# suppressed here once instead of at every call site.
#' Attach a managed default fill scale for a derived channel.
#' @noRd
#' @keywords internal
._derived_fill <- function(plot, trans, range = "viridis") {
  suppressMessages(scale_fill(plot, trans = trans, range = range))
}

# ---- closed statistical-mark fill ownership ----
# mark_hex / mark_bin2d / filled density_2d / filled contour own their fill
# channel: the computed count/level drives the colouring, so the
# plotit()-injected single-colour constants must go first, and a curated
# viridis scale is attached afterwards (a later user scale_*() replaces it,
# last-wins).  One pre/post pair keeps the five call sites identical.
#' Pre-step: capture user fill ownership, then clear the injection.
#' @noRd
#' @keywords internal
._closed_fill_pre <- function(plot, mapping) {
  user_fill <- !is.null(mapping$fill) ||
    "fill" %in% ._user_owned_aes(plot, mapping)
  list(plot = ._clear_default_color(plot), user_fill = user_fill)
}

#' Post-step: attach the default viridis scale unless the user owns fill.
#' @noRd
#' @keywords internal
._closed_fill_post <- function(plot, user_fill, trans) {
  if (!user_fill) {
    plot <- ._derived_fill(plot, trans = trans)
  }
  plot
}

# Resolve a distribution name ("norm") to its quantile function ("qnorm").
# Shared by mark_qq / mark_qq_line (AGENTS.md 4.3 error-wording parity).
#' Resolve a q*-function from a distribution short name.
#' @noRd
#' @keywords internal
._resolve_qfun <- function(distribution) {
  qfun <- paste0("q", distribution)
  if (!exists(qfun, mode = "function")) {
    cli::cli_abort(c(
      "{.arg distribution} must name a `q*` function (e.g. {.val norm} for {.fn qnorm}).",
      "x" = "{.fn {qfun}} was not found."
    ))
  }
  get(qfun, mode = "function")
}

# ---- composite-mark shared helper ----
# The composite sugars (lollipop / dumbbell / forest) share one contract:
# resolve the effective layer data/mapping, require a fixed set of
# aesthetics, and evaluate them to plain vectors for `!!`-injection.
# Centralising it keeps every sugar's validation and error wording
# identical (AGENTS.md 4.3).
#' Resolve layer data/mapping, require aesthetics, evaluate to vectors.
#' @noRd
#' @keywords internal
._eval_layer_aes <- function(plot, mapping, data, required, mark_name) {
  d <- data %||% plot@gg$data
  m <- mapping %||% plot@gg$mapping
  missing_aes <- setdiff(required, names(m))
  if (length(missing_aes) > 0) {
    cli::cli_abort(c(
      "{.fn {mark_name}} requires the {.val {missing_aes}} aesthetic{?s}.",
      "i" = "Use {.code encode(...)} in {.fn plotit} or pass a layer {.arg mapping}."
    ))
  }
  cols <- lapply(required, function(a) rlang::eval_tidy(m[[a]], d))
  names(cols) <- required
  list(data = d, mapping = m, cols = cols)
}

# ---- mark method factory ----
# Generates only the S7 method for a standard mark.  The S7 generic
# (`new_generic`) stays hand-written with @export so roxygen2 can see it.
#
# generic  : the S7 generic object (e.g. mark_point)
# geom_fun : the ggplot2 geom function (e.g. ggplot2::geom_point)
#
# NOTE on stat_* wrappers: ggplot2's `stat_ecdf(geom = "step")` etc.
# resolve their counterpart layer through substitute() side effects that
# misfire under this package's do.call argument splicing (the "step"
# string escapes into stats::step).  Marks pairing a geom with a
# different stat therefore wrap the GEOM constructor and hand it the stat
# as a ggproto object -- the same object the wrapper resolves to.
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
#' @references
#' Vega-Lite: \href{https://vega.github.io/vega-lite/docs/point.html}{Point}
#'
#' AntV G2: \href{https://g2.antv.antgroup.com/en/api/mark/point}{Point} (corelib)
#' @examples
#' plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
#' @export
mark_point <- ._make_mark_generic("mark_point")
._register_mark_method(mark_point, ggplot2::geom_point)

# ---- shared aesthetic-name filter ----
# Keep only the channels a point-like sugar layer understands.
# geom_point does not know xend/yend (or any other foreign column), so
# generic "drop the end channels" filtering used to leak new geometry
# columns into composite sugars.  A whitelist makes the filter stable as
# the geometry vocabulary grows.
._POINT_BIND_AES <- c(
  "x", "y", "colour", "fill", "size", "shape",
  "alpha", "linetype", "stroke", "group"
)

# Channels a segment/interval layer understands (geom_errorbar/linerange).
# Used by mark_forest to strip fill from a global mapping the bar geom has
# no use for (which would otherwise warn "Ignoring unknown aesthetics").
._INTERVAL_BIND_AES <- c(
  "x", "y", "ymin", "ymax", "xmin", "xmax",
  "colour", "alpha", "linetype", "linewidth", "group"
)

# Channels geom_segment understands. mark_rule's data-driven segment mode
# adopts the global mapping, which carries the default_color-injected
# `fill` that geom_segment rejects with an "Ignoring unknown aesthetics"
# warning; filtering to this whitelist keeps colour and drops fill.
._SEGMENT_BIND_AES <- c(
  "x", "y", "xend", "yend",
  "colour", "alpha", "linetype", "linewidth", "group"
)

#' Keep a mapping down to the channels a given geom family accepts.
#' @noRd
#' @keywords internal
._filter_aes <- function(m, allowed) {
  structure(m[intersect(names(m), allowed)], class = oldClass(m))
}

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
#' @references
#' Vega-Lite: \href{https://vega.github.io/vega-lite/docs/line.html}{Line}
#'
#' AntV G2: \href{https://g2.antv.antgroup.com/en/api/mark/line}{Line} (corelib)
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
#' @references
#' R: \code{stats::quantile()} (five-number summary behind the boxplot stat)
#' Vega-Lite: \href{https://vega.github.io/vega-lite/docs/boxplot.html}{Boxplot} (composite mark)
#'
#' AntV G2: boxplot (corelib)
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
#' @references
#' R: \code{graphics::hist()} (binning semantics; realised by ggplot2's stat_bin)
#' Vega-Lite: \href{https://vega.github.io/vega-lite/docs/bar.html}{Bar} with `bin` transform
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
#' @references
#' R: \code{stats::density()} (kernel density estimate)
#' AntV G2: \href{https://g2.antv.antgroup.com/en/api/mark/density}{Density} (corelib)
#' @examples
#' plotit(iris, encode(x = Sepal.Width)) |> mark_density()
#' @export
mark_density <- ._make_mark_generic("mark_density")
._register_mark_method(mark_density, ggplot2::geom_density)

# ---- mark_area ----
#' Area layer
#'
#' Adds a filled area layer.  With `y` mapped this is a classic
#' (optionally stacked) area chart via `geom_area`; with `ymin`/`ymax`
#' mapped instead it becomes an interval band via `geom_ribbon` <U+2014>
#' confidence bands, min/max envelopes, or any "area between two
#' curves" view (Vega-Lite's `area` covers both, as does G2).
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param position Position adjustment.
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to `geom_area` (or `geom_ribbon`
#'   when `ymin`/`ymax` drive the layer)
#' @return Modified plotit object
#' @references
#' Vega-Lite: \href{https://vega.github.io/vega-lite/docs/area.html}{Area} /
#' \href{https://vega.github.io/vega-lite/docs/band.html}{Band}
#'
#' AntV G2: \href{https://g2.antv.antgroup.com/en/api/mark/area}{Area}
#' @examples
#' plotit(ggplot2::economics, encode(x = date, y = unemploy)) |>
#'   mark_area(alpha = 0.5)
#'
#' # interval band: smooth fit with 95% confidence envelope
#' fit <- stats::loess(mpg ~ wt, data = mtcars)
#' band <- data.frame(
#'   wt = mtcars$wt,
#'   fit = stats::predict(fit),
#'   se = stats::predict(fit, se = TRUE)$se.fit
#' )
#' band$lo <- band$fit - 1.96 * band$se
#' band$hi <- band$fit + 1.96 * band$se
#' plotit(band, encode(x = wt, ymin = lo, ymax = hi)) |>
#'   mark_area(alpha = 0.2, fill = "#4E79A7") |>
#'   mark_line(mapping = encode(x = wt, y = fit))
#' @export
mark_area <- ._make_mark_generic("mark_area")
# Registered by hand (not via ._register_mark_method): the geom choice
# depends on whether the layer is driven by `y` (area) or `ymin`/`ymax`
# (band), mirroring the geom_col/geom_bar dispatch in mark_bar.
#' @export
S7::method(mark_area, plotit_class) <- function(
  plot, mapping = NULL, data = NULL, position = NULL, ...,
  rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo"
) {
  eff <- if (is.null(mapping)) plot@gg$mapping else mapping
  band <- !is.null(eff$ymin) && !is.null(eff$ymax)
  geom_fun <- if (band) ggplot2::geom_ribbon else ggplot2::geom_area
  ._mark_impl(plot, mapping, data, position, geom_fun,
    rasterize, rasterize_dpi, rasterize_dev,
    # A single band must not dodge against sibling layers.
    auto_dodge = !band,
    bind_aes = ._MARK_BIND_AES$mark_area, mark_name = "mark_area", ...
  )
}

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
#' @param ... Other arguments passed to `geom_text` or `geom_text_repel`.
#'   With `repel = TRUE` the frequently used \pkg{ggrepel} passthrough
#'   parameters are (defaults from the ggrepel docs):
#'   `max.overlaps` (plural! labels overlapping more than this many others
#'   are dropped; default `getOption("ggrepel.max.overlaps", 10)`;
#'   `Inf` keeps every label), `min.segment.length = 0.5` (leader-line
#'   threshold, `0` draws all), `force = 1`, `force_pull = 1`,
#'   `direction = "both"`, `seed = NA` (set a number for reproducible
#'   placement), `nudge_x = 0`, `nudge_y = 0`, `point.padding = 1e-6`,
#'   `box.padding = 0.25`, `max.time = 0.5`, `max.iter = 10000`,
#'   `xlim = c(NA, NA)`, `ylim = c(NA, NA)`.
#' @return Modified plotit object
#' @references
#' Observable Plot: `Plot.text`
#'
#' ggrepel: \href{https://ggrepel.slowkow.com/reference/geom_text_repel.html}{geom_text_repel}
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
    ._require_pkg("ggrepel", "{.arg repel = TRUE}")
    geom_fun <- ggrepel::geom_text_repel
  } else {
    geom_fun <- ggplot2::geom_text
  }
  ._impl_with(
    plot, mapping, data, position, geom_fun,
    rasterize, rasterize_dpi, rasterize_dev,
    bind_aes = ._MARK_BIND_AES$mark_text, mark_name = "mark_text",
    extra = rlang::list2(...)
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
#' @param ... Other arguments passed to `geom_violin`. Since ggplot2 4.0 the
#'   quantile lines live on the stat: `quantiles =` selects the quantiles
#'   drawn and `quantile.colour`/`quantile.linetype`/`quantile.linewidth`
#'   style them (`quantile.linetype = 0` hides them by default).
#' @return Modified plotit object
#' @references
#' AntV G2: \href{https://g2.antv.antgroup.com/en/api/general/shape}{density (violin)}
#' @examples
#' plotit(iris, encode(x = Species, y = Sepal.Length)) |>
#'   mark_violin(quantiles = 0.5, quantile.linetype = "dashed")
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
  ._require_pkg("sf", "{.fn mark_map}")
  if (!is.null(position)) {
    ._warn_ignored(
      "position", "{.fn geom_sf} implements no position adjustments."
    )
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
  ._add_geom(plot, geom,
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
  dots <- rlang::list2(...)
  if (peeked$from_graph) {
    mapping <- ._auto_bind_geometry(mapping, peeked$data,
      scope = ._MARK_BIND_AES$mark_rect
    )
    # Hand the resolved table down so the unified path does not resolve
    # the ~table reference a second time, and mirror its graph-layer
    # contract (never merge the global mapping over a resolved table).
    data <- peeked$data
    dots$inherit.aes <- FALSE
  }
  corners <- !is.null(mapping) &&
    all(c("xmin", "xmax", "ymin", "ymax") %in% names(mapping))
  geom_fun <- if (corners) ggplot2::geom_rect else ggplot2::geom_tile
  ._impl_with(plot, mapping, data, position, geom_fun,
    rasterize, rasterize_dpi, rasterize_dev,
    bind_aes = ._MARK_BIND_AES$mark_rect, mark_name = "mark_rect",
    extra = dots
  )
}

# ---- mark_rule ----
#' Reference line / segment layer
#'
#' Adds one or more reference lines or segments to a plot. Dispatches
#' to the appropriate ggplot2 geom based on the parameters supplied:
#'
#' - `xintercept` <U+2192> [ggplot2::geom_vline]
#' - `yintercept` <U+2192> [ggplot2::geom_hline]
#' - `slope` + `intercept` <U+2192> [ggplot2::geom_abline]
#' - `x`/`xend`/`y`/`yend` <U+2192> [ggplot2::geom_segment]
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
#' @param color Line colour (default `"grey50"`, the unified soft neutral;
#'   ggplot2's black is restored by passing `color = "black"`).  The British
#'   spelling `colour` is still accepted through `...`.
#' @param linetype Line type
#' @param linewidth Line width in mm (default 0.5).
#' @param mapping Optional aesthetics for data-driven segments
#'   (`x`/`xend`/`y`/`yend`); layout tables bind them automatically.
#' @param data Optional data for segment mode: one segment per row.
#'   Accepts a data.frame or a `~table` reference into graph data.
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to the underlying geom. ggplot2 4.0
#'   also accepts `layout=` on any layer, which controls how the layer is
#'   placed across `split_*` facet panels: `NULL` (default) matches layer
#'   rows to panels by the facet variable, `"fixed"` repeats the layer on
#'   every panel (a unified reference line), and an integer pins it to a
#'   single panel, e.g. `mark_rule(yintercept = 0, layout = "fixed")`.
#' @return Modified plotit object
#' @references
#' Vega-Lite: \href{https://vega.github.io/vega-lite/docs/rule.html}{Rule}
#'
#' AntV G2: \href{https://g2.antv.antgroup.com/en/api/mark/line-x}{LineX} /
#' \href{https://g2.antv.antgroup.com/en/api/mark/line-y}{LineY} /
#' \href{https://g2.antv.antgroup.com/en/api/mark/range}{Range}
#' @examples
#' plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
#'   mark_rule(xintercept = 3, color = "red", linetype = "dashed")
#'
#' # Data-driven segments: network edges from a layout_* transform
#' e <- data.frame(source = c("a", "a", "b"), target = c("b", "c", "c"))
#' as_graph(e) |>
#'   plotit() |>
#'   layout_force(seed = 1) |>
#'   mark_point(data = ~nodes) |>
#'   mark_rule(data = ~edges, color = "grey70")
#' @export
mark_rule <- S7::new_generic(
  "mark_rule", "plot",
  function(plot, mapping = NULL, data = NULL,
           xintercept = NULL, yintercept = NULL,
           slope = NULL, intercept = NULL,
           x = NULL, xend = NULL, y = NULL, yend = NULL,
           color = NULL, linetype = NULL, linewidth = NULL,
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
  color = NULL, linetype = NULL, linewidth = NULL,
  ...,
  rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo"
) {
  # Data-driven segment mode: render one segment per row (e.g. network
  # edges from a layout_* transform, or a global x/xend/y/yend mapping).
  # Endpoints come from the mapping (auto-bound from layout geometry when
  # data is a ~table reference; global mapping when data is omitted).
  eff_mapping <- if (is.null(mapping)) plot@gg$mapping else mapping
  seg_aes <- all(c("x", "xend", "y", "yend") %in% names(eff_mapping))
  if (is.null(data) && !is.null(eff_mapping) && seg_aes) {
    data <- plot@gg$data
  }
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
    # Graph layers bind geometry from their own table and must never fall
    # back to the global mapping (a graph's global aes would reference
    # node-table columns the edges table lacks).
    if (is.null(mapping) && !resolved$from_graph) {
      mapping <- eff_mapping
    }
    if (resolved$from_graph) {
      mapping <- ._auto_bind_geometry(mapping, seg_data,
        scope = ._MARK_BIND_AES$mark_rule
      )
    }
    # geom_segment rejects `fill` (and any foreign channel the global
    # mapping may carry, e.g. the default_color-injected fill) with an
    # "Ignoring unknown aesthetics" warning; keep only segment channels.
    mapping <- ._filter_aes(mapping, ._SEGMENT_BIND_AES)
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
    if (!is.null(color)) static$colour <- color
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
  if (!is.null(color)) params$colour <- color
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
    if (!is.null(color)) ann_args$colour <- color
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

  ._add_geom(plot, geom_call,
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
#' R: \code{stats::loess()} / \code{stats::lm()} (default smoothing methods)
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
  ._impl_with(plot, mapping, data, position, ggplot2::geom_smooth,
    rasterize, rasterize_dpi, rasterize_dev,
    bind_aes = ._MARK_BIND_AES$mark_smooth, mark_name = "mark_smooth",
    extra = params
  )
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
  ._require_pkg("hexbin", "{.fn mark_hex}")
  # The bin-count fill is owned by this closed statistical mark (shared
  # pre/post: clear injection, then attach the curated viridis default).
  pre <- ._closed_fill_pre(plot, mapping)
  plot <- pre$plot
  params <- rlang::list2(...)
  params$bins <- bins
  plot <- ._impl_with(plot, mapping, data, position, ggplot2::geom_hex,
    rasterize, rasterize_dpi, rasterize_dev,
    bind_aes = ._MARK_BIND_AES$mark_hex, mark_name = "mark_hex",
    extra = params
  )
  ._closed_fill_post(plot, pre$user_fill, trans = "identity")
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
#' R: \code{MASS::kde2d()} (2D kernel density estimate)
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
    pre <- ._closed_fill_pre(plot, mapping)
    plot <- pre$plot
  }
  plot <- ._impl_with(plot, mapping, data, position, geom_fun,
    rasterize, rasterize_dpi, rasterize_dev,
    bind_aes = ._MARK_BIND_AES$mark_density_2d, mark_name = "mark_density_2d",
    extra = dots
  )
  if (filled) {
    plot <- ._closed_fill_post(plot, pre$user_fill, trans = "discrete")
  }
  plot
}

# ---- correlation preprocessing (internal) ----
# Vega-style discipline: data transforms live inside the spec, not on the
# public surface.  [mark_corr()] is the public entry point; this helper
# builds its long-form table (the formerly exported transform_corr() was an
# orphan single-verb family and was folded back into the package interior).
#' Compute a reordered, melted correlation table.
#' @noRd
#' @keywords internal
._transform_corr <- function(data,
                             method = c("pearson", "spearman", "kendall"),
                             reorder = TRUE) {
  method <- match.arg(method)
  if (!is.data.frame(data)) {
    ._abort_hint(
      "{.arg data} must be a data.frame.",
      "Correlation preprocessing works on tabular data with numeric columns."
    )
  }
  num_cols <- vapply(data, is.numeric, logical(1))
  if (sum(num_cols) < 2) {
    ._abort_hint(
      "Correlation preprocessing requires at least 2 numeric columns.",
      "Select a wider numeric frame or convert columns before plotting."
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
      cli::cli_warn(c(
        "Correlation matrix contains {.val NA}; skipping reorder.",
        "i" = "A zero-variance column produces undefined correlations."
      ))
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
#' The value fill scale defaults to viridis (colour-blind safe); chain
#' [scale_fill()] afterwards to replace it (last call wins).
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
#' R: \code{stats::cor()} (pairwise correlation matrix)
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
    ._abort_hint(
      "{.fn mark_corr} requires tabular plot data.",
      "Call {.fn plotit} with a data.frame of numeric columns first."
    )
  }
  # Sugar over the internal corr transform + tile layer.  Routed through
  # the shared mark path so the unified style defaults apply (white hairline
  # separators between tiles, matching mark_rect).
  df <- ._transform_corr(raw_data, method = method, reorder = reorder)
  mapping <- encode(x = Var1, y = Var2, fill = value)
  # The correlation value channel is mark-owned (magnitude -> sequential
  # viridis, AGENTS.md <U+00A7>6); pre-register it as managed so the layer-level
  # auto-attach does not double-fire.
  plot <- ._colour_managed_add(plot, "fill")
  plot <- ._impl_with(plot, mapping, df,
    position = NULL, ggplot2::geom_tile,
    rasterize, rasterize_dpi, rasterize_dev,
    auto_dodge = FALSE, bind_aes = NULL, mark_name = "mark_corr",
    extra = rlang::list2(...)
  )
  # Default the value fill to the colour-blind-safe continuous scheme; a
  # later scale_fill() call replaces it (last wins).
  plot <- ._derived_fill(plot, trans = "identity")
  # Synthetic Var1/Var2 titles carry no meaning; the variable names on the
  # axes do.  (Axis lines/ticks and expansion are handled by the shared
  # closed-cell chrome inside ._mark_impl.)
  plot@gg <- plot@gg + ggplot2::theme(axis.title = ggplot2::element_blank())
  plot
}

# ---- mark_heatmap ----
# Tidyheatmaps-style matrix heatmap expressed as a plotit MARK, not a
# standalone system: it reads a matrix / wide data.frame / tidy long mapping
# from the pipeline, optionally z-scores and hclust-reorders it, and renders
# the tile grid through the shared mark path (so it inherits the unified
# white-hairline cell chrome, the managed viridis fill default, and stays
# chainable with scale_fill()/label_*/compose_*).

# Coerce the pipeline input to a numeric matrix with named rows/cols.
#' @noRd
#' @keywords internal
._heatmap_to_matrix <- function(data, mapping) {
  mnames <- names(mapping)
  if (is.matrix(data)) {
    mat <- data
    if (is.null(rownames(mat))) rownames(mat) <- as.character(seq_len(nrow(mat)))
    if (is.null(colnames(mat))) colnames(mat) <- as.character(seq_len(ncol(mat)))
    return(mat)
  }
  if (!is.data.frame(data)) {
    cli::cli_abort(c(
      "{.fn mark_heatmap} needs a matrix, a wide numeric data.frame,",
      "i" = "or a tidy {.code encode(x =, y =, fill =)} mapping."
    ))
  }
  # Tidy long form: explicit x / y / fill(value) aesthetics define the grid.
  if (all(c("x", "y", "fill") %in% mnames)) {
    long <- data.frame(
      .x = rlang::eval_tidy(mapping$x, data),
      .y = rlang::eval_tidy(mapping$y, data),
      .v = as.numeric(rlang::eval_tidy(mapping$fill, data))
    )
    long$.x <- as.character(long$.x)
    long$.y <- as.character(long$.y)
    return(
      stats::xtabs(.v ~ .y + .x, data = long, drop.unused.levels = TRUE)
    )
  }
  # Wide numeric data.frame: columns -> heatmap columns, rows -> observations.
  num <- vapply(data, is.numeric, logical(1))
  if (sum(num) < 1) {
    ._abort_hint(
      "{.fn mark_heatmap} found no numeric columns and no {.code x/y/fill} mapping.",
      "Pass a wide numeric frame or map {.code encode(x =, y =, fill =)}."
    )
  }
  mat <- as.matrix(data[, num, drop = FALSE])
  if (is.null(rownames(mat))) rownames(mat) <- as.character(seq_len(nrow(mat)))
  mat
}

# Row/column z-score normalisation (pheatmap `scale` semantics).
#' @noRd
#' @keywords internal
._heatmap_scale <- function(mat, scale) {
  if (identical(scale, "none")) {
    return(mat)
  }
  z <- function(r) {
    s <- stats::sd(r, na.rm = TRUE)
    if (!is.finite(s) || s == 0) s <- 1
    (r - mean(r, na.rm = TRUE)) / s
  }
  if (identical(scale, "row")) {
    # apply(MARGIN = 1) stacks row results as COLUMNS; transpose back.
    return(t(apply(mat, 1L, z)))
  }
  # apply(MARGIN = 2) already keeps the original orientation.
  apply(mat, 2L, z)
}

# Hierarchical clustering reorder of rows and/or columns.
#' @noRd
#' @keywords internal
._heatmap_cluster <- function(mat, cluster) {
  row_ord <- rownames(mat)
  col_ord <- colnames(mat)
  if (cluster %in% c("row", "both") && nrow(mat) > 2) {
    row_ord <- rownames(mat)[stats::hclust(stats::dist(mat))$order]
  }
  if (cluster %in% c("column", "both") && ncol(mat) > 2) {
    col_ord <- colnames(mat)[stats::hclust(stats::dist(t(mat)))$order]
  }
  list(row = row_ord, col = col_ord)
}

#' Matrix heatmap layer (sugar)
#'
#' Renders a tidyheatmaps-style matrix heatmap as a plotit mark. Accepts a
#' numeric matrix, a wide numeric data.frame (columns become heatmap
#' columns), or a tidy long mapping (`encode(x =, y =, fill =)`). Optionally
#' z-score normalises rows/columns ([base::scale()]) and reorders them by
#' hierarchical clustering ([stats::hclust()]). The tile grid reuses the
#' shared mark path, so it inherits the white-hairline cell chrome (tiles
#' hug the panel, no 0-origin whitespace) and the colour-blind-safe viridis
#' fill default; chain [scale_fill()] to replace it (last call wins). This is
#' a mark, not a separate system: combine it with [layout_dendrogram()] and
#' [compose_marginal()] for a full annotated heatmap.
#'
#' @param plot A plotit object carrying the matrix / data.frame / tidy mapping.
#' @param cluster Reorder axes by hierarchical clustering: `"both"` (default),
#'   `"row"`, `"column"`, or `"none"`.
#' @param scale z-score normalisation: `"none"` (default), `"row"`, or
#'   `"column"`.
#' @param ... Other arguments passed to [ggplot2::geom_tile()].
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @return Modified plotit object.
#' @references
#' R: \code{stats::hclust()} / \code{stats::dist()} (row/column clustering)
#' tidyheatmaps: \href{https://jbengler.github.io/tidyheatmaps/}{Heatmaps from Tidy Data}
#' @examples
#' mat <- matrix(rnorm(30),
#'   nrow = 6,
#'   dimnames = list(paste0("g", 1:6), paste0("s", 1:5))
#' )
#' plotit(mat, encode()) |> mark_heatmap()
#' plotit(mat, encode()) |> mark_heatmap(cluster = "both", scale = "row")
#' @export
mark_heatmap <- S7::new_generic(
  "mark_heatmap", "plot",
  function(plot, cluster = c("both", "row", "column", "none"),
           scale = c("none", "row", "column"), ...,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_heatmap, plotit_class) <- function(
  plot, cluster = c("both", "row", "column", "none"),
  scale = c("none", "row", "column"), ...,
  rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo"
) {
  cluster <- match.arg(cluster)
  scale <- match.arg(scale)
  plot <- ._clear_default_color(plot)
  mat <- ._heatmap_to_matrix(plot@gg$data, plot@gg$mapping)
  mat <- ._heatmap_scale(mat, scale)
  ord <- ._heatmap_cluster(mat, cluster)
  mat <- mat[ord$row, ord$col, drop = FALSE]
  df <- expand.grid(
    Var2 = factor(ord$col, levels = ord$col),
    Var1 = factor(ord$row, levels = ord$row)
  )
  # expand.grid varies Var2 (the matrix column) fastest, which walks `mat`
  # in row-major order; as.vector() is column-major, so transpose first to
  # keep tile <-> value pairing correct.
  df$value <- as.vector(t(mat))
  mapping <- encode(x = Var2, y = Var1, fill = value)
  plot <- ._colour_managed_add(plot, "fill")
  plot <- ._impl_with(plot, mapping, df,
    position = NULL, ggplot2::geom_tile,
    rasterize, rasterize_dpi, rasterize_dev,
    auto_dodge = FALSE, bind_aes = NULL, mark_name = "mark_heatmap",
    extra = rlang::list2(...)
  )
  plot <- ._derived_fill(plot, trans = "identity")
  # Synthetic Var1/Var2 titles carry no meaning; the axis labels do.
  plot@gg <- plot@gg + ggplot2::theme(axis.title = ggplot2::element_blank())
  plot
}

# ---- statistical entity fun-data (D-01, design/03 §2) ----
# fun.data contracts for ggplot2::stat_summary: input is the value vector of
# the central aesthetic, output is a data.frame with `y`, `ymin`, `ymax`
# (ggplot2's orientation machinery maps these to xmin/xmax for horizontal
# orientation).  Pure R, zero new dependencies.  `mean_` names the CENTER;
# the interval semantics follow Vega-Lite's `extent` enumeration
# (sem <-> stderr, sd <-> stdev, ci95 <-> ci; range is tidyplots semantics).

._fun_data_mean_sem <- function(x, ...) {
  x <- x[!is.na(x)]
  n <- length(x)
  m <- mean(x)
  se <- if (n > 1) stats::sd(x) / sqrt(n) else NA_real_
  data.frame(y = m, ymin = m - se, ymax = m + se)
}

._fun_data_mean_sd <- function(x, ...) {
  x <- x[!is.na(x)]
  n <- length(x)
  m <- mean(x)
  s <- if (n > 1) stats::sd(x) else NA_real_
  data.frame(y = m, ymin = m - s, ymax = m + s)
}

._fun_data_mean_range <- function(x, ...) {
  x <- x[!is.na(x)]
  data.frame(y = mean(x), ymin = min(x), ymax = max(x))
}

# Two-sided t interval at confidence `level`: mean +- qt((1+level)/2, n-1)*se.
._fun_data_mean_ci <- function(x, level = 0.95, ci_method = "normal",
                               seed = NULL, ...) {
  x <- x[!is.na(x)]
  n <- length(x)
  m <- mean(x)
  if (identical(ci_method, "boot")) {
    if (!is.null(seed)) {
      set.seed(seed)
    }
    boot_means <- replicate(1000, mean(sample(x, n, replace = TRUE)))
    qs <- stats::quantile(
      boot_means, c((1 - level) / 2, 1 - (1 - level) / 2)
    )
    return(data.frame(y = m, ymin = unname(qs[1]), ymax = unname(qs[2])))
  }
  se <- if (n > 1) stats::sd(x) / sqrt(n) else NA_real_
  tcrit <- stats::qt((1 + level) / 2, df = n - 1)
  data.frame(y = m, ymin = m - tcrit * se, ymax = m + tcrit * se)
}

# Shared validation for the statistical-entity parameters.  Returns the
# cleaned stat string; aborts with targeted three-part messages otherwise.
#' Validate statistical-entity parameters shared by errorbar and ribbon.
#' @noRd
#' @keywords internal
._validate_stat_entity <- function(stat, level, ci_method, seed) {
  stat <- match.arg(stat, c(
    "identity", "mean_sem", "mean_sd", "mean_range", "mean_ci95"
  ))
  if (length(level) != 1 || is.na(level) || level <= 0 || level >= 1) {
    ._abort_arg_range("level", "in (0, 1)", got = level)
  }
  if (identical(ci_method, "boot") && is.null(seed)) {
    ._abort_hint(
      "{.code ci_method = \"boot\"} requires a {.arg seed} for reproducible resampling.",
      "Pass a fixed integer, e.g. {.code seed = 1}."
    )
  }
  if (!identical(stat, "identity") && !identical(stat, "mean_ci95") &&
      !is.null(seed)) {
    ._warn_ignored("seed", "only {.code ci_method = \"boot\"} resamples")
  }
  stat
}

# ---- mark_errorbar ----
#' Error bar / interval layer
#'
#' Adds interval bars showing pre-computed intervals (`stat = "identity"`,
#' the default: `ymin`/`ymax` come straight from the data) or statistical
#' entities computed per group (`stat = "mean_sem"`, `"mean_sd"`,
#' `"mean_range"`, `"mean_ci95"`): the interval is aggregated from the raw
#' `y` values of each x group with no manual pre-computation.
#'
#' Vertical bars (default) map the position on `x` and the interval on
#' `ymin`/`ymax`; horizontal bars map the position on `y` and the interval
#' on `xmin`/`xmax` (G2's `rangeX`/`rangeY` semantics).  Set `caps = FALSE`
#' for plain interval lines without end caps (Vega-Lite's `errorband`).
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics.  With `stat = "identity"` it must
#'   include the interval columns for the chosen orientation (`ymin`/`ymax`
#'   vertical, `xmin`/`xmax` horizontal); with a statistical entity it only
#'   needs `x` (group) and `y` (value).
#' @param data Optional data for this layer
#' @param position Position adjustment.
#' @param stat Statistical entity: `"identity"` (pre-computed intervals,
#'   no implicit aggregation) or one of `"mean_sem"`, `"mean_sd"`,
#'   `"mean_range"`, `"mean_ci95"` (per-group aggregation of `y`).
#' @param level Confidence level for `stat = "mean_ci95"`, in `(0, 1)`
#'   (default 0.95).
#' @param ci_method `"normal"` (default, t-based normal approximation) or
#'   `"boot"` (percentile bootstrap of the mean; requires `seed`).
#' @param seed RNG seed for `ci_method = "boot"`; required for
#'   reproducibility of the bootstrap.
#' @param width Size of the error bar caps as a fraction of the resolution
#'   of the data (default 0.5).  Ignored when `caps = FALSE`.
#' @param orientation `"vertical"` (default) or `"horizontal"`.
#' @param caps If `TRUE` (default), draw end caps; `FALSE` renders bare
#'   interval lines (`geom_linerange`).
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to the underlying geom
#' @return Modified plotit object
#' @references
#' Vega-Lite: \href{https://vega.github.io/vega-lite/docs/errorbar.html}{Errorbar} /
#' \href{https://vega.github.io/vega-lite/docs/errorband.html}{Errorband}
#' (`extent`: stderr <-> sem, stdev <-> sd, ci <-> ci95)
#'
#' AntV G2: \href{https://g2.antv.antgroup.com/en/api/mark/range}{Range}
#' @examples
#' df <- data.frame(
#'   x = c("A", "B"), y = c(10, 20), ymin = c(8, 18), ymax = c(12, 22)
#' )
#' plotit(df, encode(x = x, y = y, ymin = ymin, ymax = ymax)) |>
#'   mark_errorbar(width = 0.3)
#'
#' # statistical entity: mean +- sem aggregated per group from raw y
#' plotit(iris, encode(x = Species, y = Sepal.Length)) |>
#'   mark_errorbar(stat = "mean_sem")
#'
#' # horizontal interval (position on y, range on x)
#' dfh <- data.frame(
#'   y = c("A", "B"), x = c(10, 20), xmin = c(8, 18), xmax = c(12, 22)
#' )
#' plotit(dfh, encode(x = x, y = y, xmin = xmin, xmax = xmax)) |>
#'   mark_point() |>
#'   mark_errorbar(orientation = "horizontal", caps = FALSE)
#' @export
mark_errorbar <- S7::new_generic(
  "mark_errorbar", "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           stat = "identity", level = 0.95,
           ci_method = c("normal", "boot"), seed = NULL,
           width = 0.5, orientation = c("vertical", "horizontal"),
           caps = TRUE,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_errorbar, plotit_class) <- function(
  plot, mapping = NULL, data = NULL, position = NULL, ...,
  stat = "identity", level = 0.95,
  ci_method = c("normal", "boot"), seed = NULL,
  width = 0.5, orientation = c("vertical", "horizontal"),
  caps = TRUE,
  rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo"
) {
  orientation <- match.arg(orientation)
  ci_method <- match.arg(ci_method)
  stat <- ._validate_stat_entity(stat, level, ci_method, seed)
  gg_orient <- if (orientation == "horizontal") "y" else "x"
  geom_fun <- if (isTRUE(caps)) ggplot2::geom_errorbar else ggplot2::geom_linerange
  params <- rlang::list2(...)
  params$orientation <- gg_orient
  # Cap width is an errorbar-only parameter; linerange has no caps.
  if (isTRUE(caps)) params$width <- width
  if (!identical(stat, "identity")) {
    params$stat <- "summary"
    params$fun.data <- switch(stat,
      mean_sem = ._fun_data_mean_sem,
      mean_sd = ._fun_data_mean_sd,
      mean_range = ._fun_data_mean_range,
      mean_ci95 = function(x, ...) {
        ._fun_data_mean_ci(
          x, level = level, ci_method = ci_method, seed = seed
        )
      }
    )
  }
  ._impl_with(plot, mapping, data, position, geom_fun,
    rasterize, rasterize_dpi, rasterize_dev,
    bind_aes = ._MARK_BIND_AES$mark_errorbar, mark_name = "mark_errorbar",
    extra = params
  )
}

# ---- mark_ribbon ----
#' Statistical ribbon layer
#'
#' Draws an interval band.  This is a **syntax-sugar composite mark** over
#' `geom_ribbon`:
#'
#' Equivalent expansion:
#' \preformatted{
#'   stat = "identity"  is  mark_area()'s interval routing (ymin/ymax from
#'                      the data, no aggregation)
#'   stat = "mean_sem"  is  stat_summary(fun.data = mean_sem, geom = "ribbon")
#'                      (tidyplots add_sem_ribbon is the same shape)
#' }
#'
#' @param plot A plotit object
#' @param mapping Optional aesthetics: `x` plus `ymin`/`ymax` for
#'   `stat = "identity"`, or `x` (group) + `y` (value) for a statistical
#'   entity.
#' @param data Optional data for this layer
#' @param position Position adjustment.
#' @param stat Statistical entity: `"identity"` (pre-computed band) or
#'   `"mean_sem"` / `"mean_sd"` / `"mean_range"` / `"mean_ci95"`
#'   (per-group aggregation of `y`; shares the engine with
#'   [mark_errorbar()]).
#' @param level Confidence level for `stat = "mean_ci95"`, in `(0, 1)`.
#' @param ci_method `"normal"` (t-based approximation) or `"boot"`
#'   (percentile bootstrap; requires `seed`).
#' @param seed RNG seed for `ci_method = "boot"`.
#' @param alpha Band fill opacity; `NULL` (default) uses the statistical
#'   token `alpha_ci` (0.25), tuned so stacked evidence stays readable
#'   behind points and lines.
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to `geom_ribbon`
#' @return Modified plotit object
#' @references
#' Vega-Lite: \href{https://vega.github.io/vega-lite/docs/errorband.html}{Errorband}
#' (`extent`: stderr <-> sem, stdev <-> sd, ci <-> ci95)
#'
#' tidyplots: `add_sem_ribbon()` / `add_ci95()` (same aggregation shapes)
#' @examples
#' fit <- stats::loess(mpg ~ wt, data = mtcars)
#' band <- data.frame(
#'   wt = mtcars$wt,
#'   fit = stats::predict(fit),
#'   se = stats::predict(fit, se = TRUE)$se.fit
#' )
#' band$lo <- band$fit - 1.96 * band$se
#' band$hi <- band$fit + 1.96 * band$se
#' plotit(band, encode(x = wt, ymin = lo, ymax = hi)) |>
#'   mark_ribbon() |>
#'   mark_line(mapping = encode(x = wt, y = fit))
#'
#' # statistical entity: mean +- sem per group from raw y
#' plotit(iris, encode(x = Species, y = Sepal.Length)) |>
#'   mark_ribbon(stat = "mean_sem") |>
#'   mark_point(stat = "summary", fun = "mean")
#' @export
mark_ribbon <- S7::new_generic(
  "mark_ribbon", "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           stat = "identity", level = 0.95,
           ci_method = c("normal", "boot"), seed = NULL, alpha = NULL,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_ribbon, plotit_class) <- function(
  plot, mapping = NULL, data = NULL, position = NULL, ...,
  stat = "identity", level = 0.95,
  ci_method = c("normal", "boot"), seed = NULL, alpha = NULL,
  rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo"
) {
  ci_method <- match.arg(ci_method)
  stat <- ._validate_stat_entity(stat, level, ci_method, seed)
  params <- rlang::list2(...)
  if (is.null(alpha)) {
    alpha <- ._MARK_STYLE$alpha_ci
  }
  params$alpha <- alpha
  if (!identical(stat, "identity")) {
    params$stat <- "summary"
    params$fun.data <- switch(stat,
      mean_sem = ._fun_data_mean_sem,
      mean_sd = ._fun_data_mean_sd,
      mean_range = ._fun_data_mean_range,
      mean_ci95 = function(x, ...) {
        ._fun_data_mean_ci(
          x, level = level, ci_method = ci_method, seed = seed
        )
      }
    )
  }
  ._impl_with(plot, mapping, data, position, ggplot2::geom_ribbon,
    rasterize, rasterize_dpi, rasterize_dev,
    auto_dodge = FALSE,
    bind_aes = ._MARK_BIND_AES$mark_ribbon, mark_name = "mark_ribbon",
    extra = params
  )
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
#' @param tip_length Length of bracket end-tick lines (default 0.02).  Units
#'   follow the axis type: a fraction of the level count on discrete x axes,
#'   a fraction of the bracket's numeric span on continuous axes.
#' @param ... Additional arguments passed to the label annotation
#'   (`ggplot2::annotate("text", ...)`).
#' @return Modified plotit object
#' @references
#' Vega-Lite: `layer` composition of rule + text annotation layers; no native
#' significance mark
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
    ._abort_arg_range("comparisons", "a data.frame", got = deparse(substitute(comparisons)))
  }
  required <- c("group1", "group2", "label")
  missing_cols <- setdiff(required, names(comparisons))
  if (length(missing_cols) > 0) {
    cli::cli_abort(c(
      "{.arg comparisons} must have the columns {.val group1}, {.val group2}, {.val label}.",
      "x" = sprintf("Missing: {.val %s}.", paste0("c(", deparse(missing_cols), ")")),
      "i" = "One row per comparison; {.val label} carries the annotation text."
    ))
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
  # Draw every bracket in one vectorized pass (annotate() is vectorized, so
  # a single segment + tick-pair + text layer replaces 3 annotate layers
  # *per comparison*; order-invariant since brackets never overlap).
  g1 <- as.character(comparisons$group1)
  g2 <- as.character(comparisons$group2)
  if (is_discrete_x) {
    keep <- g1 %in% x_levels & g2 %in% x_levels
    x1 <- g1[keep]
    x2 <- g2[keep]
    tick_len <- rep(tip_length * length(x_levels), sum(keep))
    mid_x <- (match(g1[keep], x_levels) + match(g2[keep], x_levels)) / 2
  } else {
    n1 <- suppressWarnings(as.numeric(g1))
    n2 <- suppressWarnings(as.numeric(g2))
    keep <- !is.na(n1) & !is.na(n2)
    x1 <- n1[keep]
    x2 <- n2[keep]
    tick_len <- tip_length * abs(x2 - x1)
    mid_x <- (x1 + x2) / 2
  }
  if (!any(keep)) {
    return(plot)
  }
  if (length(y_position) >= nrow(comparisons)) {
    y_pos <- y_position[keep]
  } else {
    y_all <- y_position[1] + (seq_len(nrow(comparisons)) - 1) * y_span * 0.08
    y_pos <- y_all[keep]
  }
  plot@gg <- plot@gg +
    # Bracket lines
    ggplot2::annotate(
      "segment",
      x = x1, xend = x2, y = y_pos, yend = y_pos,
      colour = line_color, linewidth = line_width
    ) +
    # End ticks (left and right ends share one segment layer)
    ggplot2::annotate(
      "segment",
      x = c(x1, x2), xend = c(x1, x2),
      y = c(y_pos - tick_len, y_pos - tick_len), yend = c(y_pos, y_pos),
      colour = line_color, linewidth = line_width
    ) +
    # Labels (midpoint in numeric position space for discrete axes)
    ggplot2::annotate(
      "text",
      x = mid_x, y = y_pos + y_offset,
      label = comparisons$label[keep], size = text_size, ...
    )
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
#' @references
#' AntV G2: `interval` + `point` layer composition (corelib); no native
#' lollipop mark
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
  resolved <- ._eval_layer_aes(
    plot, mapping, data, c("x", "y"), "mark_lollipop"
  )
  x_col <- resolved$cols$x
  y_col <- resolved$cols$y
  # Stem: segment from `ref` to y.  Values are injected with !! so the
  # aes do not depend on data column names (D4).
  stem_mapping <- encode(x = !!x_col, xend = !!x_col, y = !!ref, yend = !!y_col)
  geome <- ggplot2::geom_segment(
    mapping = stem_mapping,
    colour = stem_color, linewidth = stem_width
  )
  plot <- ._add_geom(plot, geome)
  # Point at the top: keep the visual channels (colour/fill/...) but drop
  # positional extras the point geom does not understand.
  plot <- plot |> mark_point(
    mapping = ._filter_aes(resolved$mapping, ._POINT_BIND_AES),
    data = resolved$data, size = point_size, ...
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
#' @references
#' AntV G2: \href{https://g2.antv.antgroup.com/en/api/mark/link}{Link} (corelib)
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
  plot <- ._add_geom(plot, geome)
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
#' R: \code{ggbeeswarm::geom_beeswarm()} (collision-avoidance rendering)
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
  ._require_pkg("ggbeeswarm", "{.fn mark_beeswarm}")
  method <- match.arg(method)
  params <- rlang::list2(...)
  params$method <- method
  # geom_beeswarm implements its own collision placement; the global
  # auto-dodge position is not supported (B3).
  ._impl_with(plot, mapping, data, position, ggbeeswarm::geom_beeswarm,
    rasterize, rasterize_dpi, rasterize_dev,
    auto_dodge = FALSE, bind_aes = ._MARK_BIND_AES$mark_beeswarm,
    mark_name = "mark_beeswarm", extra = params
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
#' @references
#' Vega-Lite: \href{https://vega.github.io/vega-lite/docs/bar.html}{Bar}
#'
#' AntV G2: \href{https://g2.antv.antgroup.com/en/api/mark/interval}{Interval} (corelib)
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

# ---- mark_step ----
#' Step layer
#'
#' Adds a stair-step line layer: observations are connected with
#' axis-parallel segments, so every change renders as an explicit jump.
#' Use for discrete state changes over time, reference thresholds, or
#' cumulative (ECDF-style) views.
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param position Position adjustment.
#' @param direction `"vh"` (default) draws vertical-then-horizontal steps;
#'   `"hv"` the reverse; `"mid"` steps at the midpoint.
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to `geom_step`
#' @return Modified plotit object
#' @references
#' Vega-Lite: \href{https://vega.github.io/vega-lite/docs/line.html}{Line} with `interpolate: "step"`
#'
#' AntV G2: \href{https://g2.antv.antgroup.com/en/api/mark/line}{Line} with `shape: "hv"`
#' @examples
#' plotit(ggplot2::economics, encode(x = date, y = unemploy)) |>
#'   mark_step()
#'
#' # horizontal-then-vertical steps
#' plotit(ggplot2::economics, encode(x = date, y = unemploy)) |>
#'   mark_step(direction = "hv")
#'
#' # grouped steps
#' plotit(
#'   subset(ggplot2::economics, date > "1990-01-01"),
#'   encode(x = date, y = psavert, colour = "savings")
#' ) |>
#'   mark_step() |>
#'   mark_line(colour = "#E15759", alpha = 0.3)
#' @export
mark_step <- S7::new_generic(
  "mark_step", "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           direction = c("vh", "hv", "mid"),
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_step, plotit_class) <- function(
  plot, mapping = NULL, data = NULL, position = NULL, ...,
  direction = c("vh", "hv", "mid"),
  rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo"
) {
  direction <- match.arg(direction)
  params <- rlang::list2(...)
  params$direction <- direction
  ._impl_with(plot, mapping, data, position, ggplot2::geom_step,
    rasterize, rasterize_dpi, rasterize_dev,
    bind_aes = ._MARK_BIND_AES$mark_step, mark_name = "mark_step",
    extra = params
  )
}

# ---- mark_rug ----
#' Rug / tick layer
#'
#' Adds marginal tick marks along the axes: one short segment per
#' observation.  Use for 1D marginals under a histogram or density,
#' censoring ticks in survival timelines, or exact data positions
#' behind a smoothed curve.
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param position Position adjustment.
#' @param sides Which sides to draw on: any combination of `"b"` (bottom),
#'   `"l"` (left), `"t"` (top), `"r"` (right).  Default `"bl"`.
#' @param length Tick length as a fraction of the panel (default 0.03).
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to `geom_rug`
#' @return Modified plotit object
#' @references
#' Vega-Lite: \href{https://vega.github.io/vega-lite/docs/rule.html}{Rule} (marginal tick pattern)
#'
#' AntV G2: \href{https://g2.antv.antgroup.com/en/api/mark/range}{Range} (brush ticks)
#' @examples
#' plotit(faithful, encode(x = eruptions)) |>
#'   mark_histogram(bins = 20) |>
#'   mark_rug()
#'
#' # top rug to frame a density
#' plotit(faithful, encode(x = eruptions)) |>
#'   mark_density() |>
#'   mark_rug(sides = "t", color = "#E15759")
#'
#' # two 1D marginals beside a scatter
#' plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
#'   mark_point(alpha = 0.5) |>
#'   mark_rug(sides = "bl")
#' @export
mark_rug <- S7::new_generic(
  "mark_rug", "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           sides = "bl", length = NULL,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_rug, plotit_class) <- function(
  plot, mapping = NULL, data = NULL, position = NULL, ...,
  sides = "bl", length = NULL,
  rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo"
) {
  # rug is a marginal annotation layer: collision with dodge placement is
  # not meaningful, so never auto-dodge here.
  params <- rlang::list2(...)
  params$sides <- sides
  if (!is.null(length)) params$length <- grid::unit(length, "npc")
  ._impl_with(plot, mapping, data, position, ggplot2::geom_rug,
    rasterize, rasterize_dpi, rasterize_dev,
    auto_dodge = FALSE, bind_aes = ._MARK_BIND_AES$mark_rug,
    mark_name = "mark_rug", extra = params
  )
}

# ---- mark_spoke ----
#' Spoke layer
#'
#' Draws a radial segment ("spoke") from each point `(x, y)` at `angle`
#' (radians) for `radius` length.  A first-class primitive for
#' direction/velocity fields and for radial network edges whose endpoints
#' are naturally expressed in polar terms.
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics (must include `x`, `y`,
#'   `angle` in radians, and `radius`)
#' @param data Optional data for this layer
#' @param position Position adjustment.
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to `geom_spoke`
#' @return Modified plotit object
#' @references
#' Vega-Lite: \href{https://vega.github.io/vega-lite/docs/spoke.html}{Spoke}
#' @examples
#' df <- data.frame(
#'   x = c(0, 1, 2), y = c(0, 1, 0),
#'   angle = c(0, pi / 2, pi), radius = c(0.5, 0.8, 0.3)
#' )
#' plotit(df, encode(x = x, y = y, angle = angle, radius = radius)) |>
#'   mark_spoke()
#' @export
mark_spoke <- ._make_mark_generic("mark_spoke")
._register_mark_method(mark_spoke, ggplot2::geom_spoke)

# ---- mark_curve ----
#' Curved link layer
#'
#' Draws curved segments between `(x, y)` and `(xend, yend)` endpoints --
#' the link/diagram edge for arc diagrams, bipartite layouts and network
#' charts, where straight rules overlap node labels.  Arrows are available
#' through `arrow = grid::arrow()` via `...`.
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics (must include `x`, `y`,
#'   `xend`, `yend`; layout tables bind them automatically)
#' @param data Optional data for this layer; accepts a `~table` graph
#'   reference
#' @param position Position adjustment.
#' @param curvature Amount of curvature: `1` is a semicircle, smaller
#'   values are flatter, negative values bend the other way (default 0.5).
#' @param angle Angle at which the curve approaches the endpoint, in
#'   degrees (default 90).
#' @param arrow Optional `grid::arrow()` object to draw arrow heads.
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to `geom_curve`
#' @return Modified plotit object
#' @references
#' AntV G2: \href{https://g2.antv.antgroup.com/en/api/mark/link}{Link}
#'
#' D3: `d3.linkHorizontal` / arc-diagram link generator
#' @examples
#' edges <- data.frame(
#'   x = c(1, 2, 3), y = c(0, 0, 0),
#'   xend = c(2, 3, 4), yend = c(1, 1, 1)
#' )
#' plotit(edges, encode(x = x, y = y, xend = xend, yend = yend)) |>
#'   mark_point(colour = "#4E79A7", size = 3) |>
#'   mark_point(
#'     mapping = encode(x = xend, y = yend),
#'     colour = "#E15759", size = 3
#'   ) |>
#'   mark_curve(curvature = 0.3)
#'
#' # curved flow with arrows
#' plotit(edges, encode(x = x, y = y, xend = xend, yend = yend)) |>
#'   mark_curve(arrow = grid::arrow(length = grid::unit(0.1, "cm")))
#' @export
mark_curve <- S7::new_generic(
  "mark_curve", "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           curvature = 0.5, angle = 90, arrow = NULL,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_curve, plotit_class) <- function(
  plot, mapping = NULL, data = NULL, position = NULL, ...,
  curvature = 0.5, angle = 90, arrow = NULL,
  rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo"
) {
  # Curves are graph-edge connectors: dodge placement is meaningless here.
  params <- rlang::list2(...)
  params$curvature <- curvature
  params$angle <- angle
  if (!is.null(arrow)) params$arrow <- arrow
  ._impl_with(plot, mapping, data, position, ggplot2::geom_curve,
    rasterize, rasterize_dpi, rasterize_dev,
    auto_dodge = FALSE, bind_aes = ._MARK_BIND_AES$mark_curve,
    mark_name = "mark_curve", extra = params
  )
}

# ---- mark_count ----
#' Count layer (overlap-aware points)
#'
#' Draws each unique point once, sized by the number of observations at
#' that location (`stat_sum`).  The standard answer to overplotting in
#' scatter plots of discrete or binned data; pair with [scale_size()]
#' for an area-proportional legend.
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param position Position adjustment.
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to `geom_count`
#' @return Modified plotit object
#' @references
#' Vega-Lite: \href{https://vega.github.io/vega-lite/docs/point.html}{Point} with `aggregate: count`
#'
#' tidyplots: `add_count_dot()` equivalent
#' @examples
#' plotit(ggplot2::diamonds, encode(x = cut, y = carat)) |> mark_count()
#'
#' plotit(ggplot2::diamonds, encode(x = carat, y = price)) |> mark_count()
#' @export
mark_count <- ._make_mark_generic("mark_count")
._register_mark_method(mark_count, ggplot2::geom_count)

# ---- mark_bin2d ----
#' 2D binned heatmap layer
#'
#' Divides the x-y plane into rectangular bins and fills each by the count
#' (or another aggregation) of observations it holds.  The rectangular
#' sibling of [mark_hex()]: exact bin boundaries make counts easier to read
#' against the axes, hex bins pack denser.
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics
#' @param data Optional data for this layer
#' @param position Position adjustment.
#' @param bins Number of bins along each axis (default 30).
#' @param binwidth Bin width along each axis; overrides `bins` when given.
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to `geom_bin_2d`
#' @return Modified plotit object
#' @details
#' The bin-count fill is owned by this closed statistical mark: it defaults
#' to the sequential viridis scale (colour-blind safe).  Chain
#' [scale_fill()] afterwards to replace it (last call wins).
#' @references
#' Vega-Lite: \href{https://vega.github.io/vega-lite/docs/rect.html}{Rect} with `bin` transform
#'
#' AntV G2: \href{https://g2.antv.antgroup.com/en/api/mark/heatmap}{Heatmap} (corelib)
#' @examples
#' plotit(ggplot2::diamonds, encode(x = carat, y = price)) |>
#'   mark_bin2d(bins = 20)
#'
#' plotit(faithful, encode(x = eruptions, y = waiting)) |>
#'   mark_bin2d(bins = 15) |>
#'   scale_fill(trans = "binned")
#' @export
mark_bin2d <- S7::new_generic(
  "mark_bin2d", "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           bins = NULL, binwidth = NULL,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_bin2d, plotit_class) <- function(
  plot, mapping = NULL, data = NULL, position = NULL, ...,
  bins = NULL, binwidth = NULL,
  rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo"
) {
  # The bin-count fill is owned by this closed statistical mark (shared
  # pre/post, same contract as mark_hex).
  pre <- ._closed_fill_pre(plot, mapping)
  plot <- pre$plot
  params <- rlang::list2(...)
  params$bins <- bins
  params$binwidth <- binwidth
  plot <- ._impl_with(plot, mapping, data, position, ggplot2::geom_bin_2d,
    rasterize, rasterize_dpi, rasterize_dev,
    bind_aes = ._MARK_BIND_AES$mark_bin2d, mark_name = "mark_bin2d",
    extra = params
  )
  ._closed_fill_post(plot, pre$user_fill, trans = "identity")
}

# ---- mark_contour ----
#' Contour layer for 2D scalar fields
#'
#' Draws contour lines of a 2D scalar field: the data must carry a `z`
#' aesthetic (value at each `x`/`y` grid point).  Use `filled = TRUE` for
#' banded fills.  Where [mark_density_2d()] estimates density from points,
#' `mark_contour()` renders an *observed* field (elevation, temperature,
#' a fitted surface).
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics (must include `x`, `y`, `z`)
#' @param data Optional data for this layer
#' @param position Position adjustment.
#' @param filled If `TRUE`, draw filled contour bands via
#'   `geom_contour_filled`; otherwise contour lines via `geom_contour`.
#' @param bins Number of contour bins.
#' @param breaks Numeric vector of exact contour levels; overrides `bins`.
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to the underlying geom
#' @return Modified plotit object
#' @details
#' Filled bands map `fill` to a computed level factor owned by this closed
#' statistical mark; the band scale defaults to discrete viridis and can be
#' replaced by chaining [scale_fill()] afterwards.
#' @references
#' R: \code{grDevices::contourLines()} (contour extraction)
#' AntV G2: \href{https://g2.antv.antgroup.com/en/api/mark/contour}{Contour}
#'
#' Observable Plot: `Plot.contour`
#' @examples
#' df <- expand.grid(x = seq(0, 10, length.out = 30), y = seq(0, 10, length.out = 30))
#' df$z <- with(df, sin(x / 2) * cos(y / 2))
#' plotit(df, encode(x = x, y = y, z = z)) |>
#'   mark_contour(breaks = seq(-1, 1, by = 0.25))
#'
#' plotit(df, encode(x = x, y = y, z = z)) |>
#'   mark_contour(filled = TRUE, bins = 10)
#' @export
mark_contour <- S7::new_generic(
  "mark_contour", "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           filled = FALSE, bins = NULL, breaks = NULL,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_contour, plotit_class) <- function(
  plot, mapping = NULL, data = NULL, position = NULL, ...,
  filled = FALSE, bins = NULL, breaks = NULL,
  rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo"
) {
  geom_fun <- if (filled) ggplot2::geom_contour_filled else ggplot2::geom_contour
  dots <- rlang::list2(...)
  if (!is.null(bins)) dots$bins <- bins
  if (!is.null(breaks)) dots$breaks <- breaks
  # Filled bands map fill to a computed level factor owned by this closed
  # statistical mark: shared pre/post, same contract as mark_density_2d.
  if (filled) {
    pre <- ._closed_fill_pre(plot, mapping)
    plot <- pre$plot
  }
  plot <- ._impl_with(plot, mapping, data, position, geom_fun,
    rasterize, rasterize_dpi, rasterize_dev,
    bind_aes = ._MARK_BIND_AES$mark_contour, mark_name = "mark_contour",
    extra = dots
  )
  if (filled) {
    plot <- ._closed_fill_post(plot, pre$user_fill, trans = "discrete")
  }
  plot
}

# ---- mark_qq / mark_qq_line ----
#' Quantile-quantile points layer
#'
#' Adds sample quantiles against theoretical (or another sample's)
#' quantiles -- the classic normality check.  Map `x` to the sample; `y`
#' is optional (another sample for two-sample QQ).  Add a reference line
#' with [mark_qq_line()].
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics (`x` required, `y` optional)
#' @param data Optional data for this layer
#' @param position Position adjustment.
#' @param distribution Theoretical distribution function without the
#'   `q` prefix (`"norm"` default); any `q*` function works: `"norm"`,
#'   `"unif"`, `"exp"`, `"lnorm"`, ...
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to `geom_qq` (e.g. `dparams`)
#' @return Modified plotit object
#' @references
#' R: \code{stats::qqnorm()} / \code{stats::qqplot()}
#' @examples
#' ecdf_data <- data.frame(eruptions = faithful$eruptions)
#' plotit(ecdf_data, encode(x = eruptions)) |>
#'   mark_qq() |>
#'   mark_qq_line()
#'
#' # two-sample QQ against an exponential reference
#' set.seed(42)
#' df <- data.frame(value = rexp(200))
#' plotit(df, encode(x = value)) |>
#'   mark_qq(distribution = "exp") |>
#'   mark_qq_line(distribution = "exp")
#' @export
mark_qq <- S7::new_generic(
  "mark_qq", "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           distribution = "norm",
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)

# ggplot2 >= 4.0 renamed the quantile-stat input aesthetic from `x` to
# `sample` (StatQq$required_aes == "sample").  A coexisting `x` -- even one
# overridden with NULL -- makes the stat drop `x` during transformation and
# the point/line geoms then report it missing; only a layer whose effective
# mapping has no `x` at all works.  The plotit contract keeps `x` as the
# user-facing sample channel (positional thinking, consistent with every
# other mark) and translates it here: the layer mapping is rebuilt from the
# global visuals plus the sample (user mapping wins over global), and the
# layer runs with inherit.aes = FALSE so the global `x` cannot leak in.
# Shared by mark_qq and mark_qq_line.
#' Build the sample-only effective mapping for the QQ marks.
#' Returns list(mapping, statics): AsIs constants from plotit()'s
#' default-color injection are lifted out of the aes and handed back as
#' static parameters, so the explicit layer mapping neither re-triggers the
#' default_color clear nor surfaces a spurious single-key legend.
#' @noRd
#' @keywords internal
._qq_sample_mapping <- function(plot, mapping, mark_name, keep_fill = TRUE) {
  layer <- if (is.null(mapping)) ggplot2::aes() else mapping
  global <- plot@gg$mapping %||% ggplot2::aes()
  src <- layer$sample %||% layer$x %||% global$sample %||% global$x
  if (is.null(src)) {
    cli::cli_abort(c(
      "{.fn {mark_name}} requires the {.val x} aesthetic (the sample).",
      "i" = "Use {.code encode(x = ...)} in {.fn plotit} or a layer {.arg mapping}."
    ))
  }
  m <- utils::modifyList(global[names(global) != "x"], layer[names(layer) != "x"])
  m$sample <- src
  m$x <- NULL
  statics <- list()
  for (ch in intersect(c("colour", "fill"), names(m))) {
    e <- m[[ch]]
    # Injected defaults are plain AsIs constants; user mappings are
    # quosures.  Only the plain constants are lifted to statics:
    # mark_qq_line's abline geom has no `fill` parameter and would warn.
    if (inherits(e, "AsIs")) {
      if (ch == "fill" && !keep_fill) {
        m[[ch]] <- NULL
      } else {
        statics[[ch]] <- as.vector(e)
        m[[ch]] <- NULL
      }
    }
  }
  list(mapping = m, statics = statics)
}

#' @export
S7::method(mark_qq, plotit_class) <- function(
  plot, mapping = NULL, data = NULL, position = NULL, ...,
  distribution = "norm",
  rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo"
) {
  params <- rlang::list2(...)
  params$distribution <- ._resolve_qfun(distribution)
  qq <- ._qq_sample_mapping(plot, mapping, "mark_qq")
  params <- utils::modifyList(qq$statics, params)
  params$inherit.aes <- FALSE
  ._impl_with(plot, qq$mapping, data,
    position, ggplot2::geom_qq,
    rasterize, rasterize_dpi, rasterize_dev,
    bind_aes = ._MARK_BIND_AES$mark_qq, mark_name = "mark_qq",
    extra = params
  )
}

#' Quantile-quantile reference line layer
#'
#' Adds a fitted reference line to a [mark_qq()] layer: quantiles of the
#' data projected onto the theoretical distribution.  A two-parameter fit
#' passes through the first and third quartile pairs.
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics (inherit from the QQ layer's
#'   data: `x` required)
#' @param data Optional data for this layer
#' @param position Position adjustment.
#' @param distribution Theoretical quantile function name without `q`
#'   (default `"norm"`).
#' @param line.p Quantile pair used for the fit (default `c(0.25, 0.75)`).
#' @param fullrange If `TRUE`, extend the line across the panel range.
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to `geom_qq_line`
#' @return Modified plotit object
#' @references
#' R: \code{stats::qqline()} (quartile-pair reference line)
#' @examples
#' ecdf_data <- data.frame(eruptions = faithful$eruptions)
#' plotit(ecdf_data, encode(x = eruptions)) |>
#'   mark_qq() |>
#'   mark_qq_line()
#' @export
mark_qq_line <- S7::new_generic(
  "mark_qq_line", "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           distribution = "norm", line.p = c(0.25, 0.75), fullrange = FALSE,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_qq_line, plotit_class) <- function(
  plot, mapping = NULL, data = NULL, position = NULL, ...,
  distribution = "norm", line.p = c(0.25, 0.75), fullrange = FALSE,
  rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo"
) {
  # Build the sample-only mapping first; the qq-line geom (abline) does not
  # take an `x` at all and does not accept a `fill` parameter.
  qq <- ._qq_sample_mapping(plot, mapping, "mark_qq_line")
  params <- rlang::list2(...)
  params$distribution <- ._resolve_qfun(distribution)
  params$line.p <- line.p
  params$fullrange <- fullrange
  params$inherit.aes <- FALSE
  ._impl_with(plot, qq$mapping, data,
    position, ggplot2::geom_qq_line,
    rasterize, rasterize_dpi, rasterize_dev,
    bind_aes = ._MARK_BIND_AES$mark_qq_line, mark_name = "mark_qq_line",
    extra = params
  )
}

# ---- mark_ecdf ----
#' Empirical CDF layer
#'
#' Plots the empirical cumulative distribution function as a stair step.
#' A distribution view with no binning parameter to choose: every point is
#' exactly represented, and group comparisons (quantiles, shifts, tails)
#' are easy to read.
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics (`x` is the sample)
#' @param data Optional data for this layer
#' @param position Position adjustment.
#' @param n Oversampling factor for the step function (default 1000;
#'   use `Inf` for the exact step function).
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to the underlying step layer
#' @return Modified plotit object
#' @references
#' R: \code{stats::ecdf()} (empirical cumulative distribution)
#' Observable Plot: `Plot.ecdf`
#'
#' Vega-Lite: `line`/`step` with cumulative `window` transform
#' @examples
#' plotit(faithful, encode(x = eruptions)) |> mark_ecdf()
#'
#' # ECDF comparison
#' df <- data.frame(
#'   value = c(iris$Sepal.Length, iris$Petal.Length),
#'   part = rep(c("Sepal", "Petal"), each = 150)
#' )
#' plotit(df, encode(x = value, colour = part)) |>
#'   mark_ecdf()
#' @export
mark_ecdf <- S7::new_generic(
  "mark_ecdf", "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           n = 1000,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_ecdf, plotit_class) <- function(
  plot, mapping = NULL, data = NULL, position = NULL, ...,
  n = 1000,
  rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo"
) {
  # geom_step + the StatEcdf ggproto object.  (`ggplot2::stat_ecdf()`
  # resolves its geom through substitute() side effects that misfire under
  # this package's do.call argument splicing -- see the factory note.)
  step_ecdf <- function(...) ggplot2::geom_step(stat = ggplot2::StatEcdf, ...)
  params <- rlang::list2(...)
  params$n <- n
  ._impl_with(plot, mapping, data, position, step_ecdf,
    rasterize, rasterize_dpi, rasterize_dev,
    auto_dodge = FALSE, bind_aes = ._MARK_BIND_AES$mark_ecdf,
    mark_name = "mark_ecdf", extra = params
  )
}

# ---- mark_label ----
#' Label layer
#'
#' Adds a text layer where every label sits inside a rounded box -- the
#' readable-over-data sibling of [mark_text()].  For collision-avoiding
#' placement, install the optional \pkg{ggrepel} package and set
#' `repel = TRUE`.
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics (e.g. `encode(label = ...)`)
#' @param data Optional data for this layer
#' @param position Position adjustment.
#' @param repel If `TRUE`, use `ggrepel::geom_label_repel` instead of
#'   `geom_label`. Requires the \pkg{ggrepel} package.
#' @param rasterize If `TRUE`, rasterize via `ggrastr::rasterise()`.
#' @param rasterize_dpi DPI for rasterization (default 300).
#' @param rasterize_dev Graphics device for rasterization (default `"cairo"`).
#' @param ... Other arguments passed to `geom_label` or `geom_label_repel`.
#'   With `repel = TRUE` the \pkg{ggrepel} passthrough parameters are the
#'   same as [mark_text()] (see its `@param ...` for the full list with
#'   defaults); `geom_label_repel` additionally styles the box with
#'   `label.padding = 0.25`, `label.r = 0.15`, `label.size = 0.25`.
#'   Without repel, ggplot2 4.0 styles the box with the `linewidth`
#'   aesthetic (the old `label.size` argument is deprecated): use
#'   `mark_label(linewidth = 0.4)`; `border.colour`/`text.colour` style the
#'   box and text independently.
#' @return Modified plotit object
#' @references
#' AntV G2: \href{https://g2.antv.antgroup.com/en/api/mark/text}{Text} (`badge` state)
#' @examples
#' agg <- aggregate(mpg ~ cyl, data = mtcars, FUN = mean)
#' plotit(agg, encode(x = cyl, y = mpg, label = round(mpg, 1))) |>
#'   mark_point() |>
#'   mark_label(nudge_y = 1.5, size = 3)
#' @export
mark_label <- S7::new_generic(
  "mark_label", "plot",
  function(plot, mapping = NULL, data = NULL, position = NULL, ...,
           repel = FALSE,
           rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo") {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_label, plotit_class) <- function(
  plot, mapping = NULL, data = NULL, position = NULL, ...,
  repel = FALSE,
  rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo"
) {
  if (repel) {
    ._require_pkg("ggrepel", "{.arg repel = TRUE}")
    geom_fun <- ggrepel::geom_label_repel
  } else {
    geom_fun <- ggplot2::geom_label
  }
  ._impl_with(
    plot, mapping, data, position, geom_fun,
    rasterize, rasterize_dpi, rasterize_dev,
    bind_aes = ._MARK_BIND_AES$mark_text, mark_name = "mark_label",
    extra = rlang::list2(...)
  )
}

# ---- mark_forest ----
#' Forest plot layer (estimate + interval)
#'
#' Draws an estimate point with its confidence interval per row -- the
#' standard meta-analysis / effect-size panel.  This is a **syntax-sugar
#' composite mark** combining [mark_errorbar()] and [mark_point()], plus a
#' vertical reference rule when `ref` is supplied.
#'
#' Equivalent expansion:
#' \preformatted{
#'   p |> mark_errorbar(width = 0.3) |>
#'        mark_point(size = 2) |>
#'        mark_rule(xintercept = ref, linetype = "dashed")
#' }
#'
#' Each row needs `y` (the study/category label position), `x` (the
#' estimate) and `xmin`/`xmax` (the interval); map them through
#' `encode()`.  This is the standard horizontal forest; for a vertical
#' forest, flip the whole plot afterwards with
#' `project_cartesian(flip = TRUE)`.
#'
#' @param plot A plotit object
#' @param mapping Optional new aesthetics (must include `x`, `y`, `xmin`,
#'   `xmax`)
#' @param data Optional data for this layer
#' @param ref Reference value for the null-effect rule (e.g. `0` for
#'   differences, `1` for ratios).  `NULL` (default) draws no rule.
#' @param point_size Size of the estimate points (default 2).
#' @param bar_width Width of the interval bars as a fraction of the
#'   categorical slot (default 0.4).
#' @param line_color Colour for the interval bars and reference rule
#'   (default `._MARK_STYLE$soft` = `"grey50"`).
#' @param line_width Stroke width for interval bars (default 0.5).
#' @param ... Other arguments passed to the estimate point layer
#' @return Modified plotit object
#' @references
#' tidyplots: `add_ci95_errorbar()` + `add_mean_dot()` + `add_reference_lines()`
#'
#' Vega-Lite: `point` + `errorbar` layer composition
#' @examples
#' studies <- data.frame(
#'   trial = paste0("Trial ", 1:5),
#'   es    = c(0.42, 0.31, 0.55, 0.20, 0.48),
#'   lo    = c(0.10, -0.05, 0.30, -0.10, 0.22),
#'   hi    = c(0.74, 0.67, 0.80, 0.50, 0.74)
#' )
#' studies |>
#'   plotit(encode(x = es, y = trial, xmin = lo, xmax = hi)) |>
#'   mark_forest(ref = 0) |>
#'   project_cartesian(flip = TRUE)
#' @export
mark_forest <- S7::new_generic(
  "mark_forest", "plot",
  function(plot, mapping = NULL, data = NULL,
           ref = NULL, point_size = 2, bar_width = 0.4,
           line_color = ._MARK_STYLE$soft, line_width = ._MARK_STYLE$lw_thin,
           ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(mark_forest, plotit_class) <- function(
  plot, mapping = NULL, data = NULL,
  ref = NULL, point_size = 2, bar_width = 0.4,
  line_color = ._MARK_STYLE$soft, line_width = ._MARK_STYLE$lw_thin,
  ...
) {
  resolved <- ._eval_layer_aes(
    plot, mapping, data, c("y", "x", "xmin", "xmax"), "mark_forest"
  )
  d <- resolved$data
  # Interval bar (horizontal: position on y, range on x) behind the
  # estimate point.  The mapping is filtered to interval-channel aesthetics
  # so an injected `fill` from plotit()'s default does not leak to the bar
  # geom ("Ignoring unknown aesthetics: fill").
  bar_aes <- ._filter_aes(resolved$mapping, ._INTERVAL_BIND_AES)
  plot <- plot |>
    mark_errorbar(
      mapping = bar_aes, data = d, orientation = "horizontal",
      width = bar_width, color = line_color, linewidth = line_width
    )
  point_aes <- ._filter_aes(resolved$mapping, ._POINT_BIND_AES)
  plot <- plot |>
    mark_point(
      mapping = point_aes, data = d, size = point_size, ...
    )
  if (!is.null(ref)) {
    plot <- plot |>
      mark_rule(xintercept = ref, color = line_color, linetype = "dashed")
  }
  plot
}

# ---- mark catalog -----------------------------------------------------------
# Single source of truth for every built-in mark generic.  zzz.R consumes
# this to register the plotit_composite rejection stubs, so a newly added
# mark only needs its name here (plus the generic/method above) to be fully
# pipeline-integrated.  Existence is verified at load time in zzz.R.
._CATALOG_MARKS <- c(
  # Basic geometry
  "mark_point", "mark_line", "mark_area", "mark_bar", "mark_rect",
  "mark_polygon", "mark_text", "mark_rule", "mark_path",
  "mark_step", "mark_rug", "mark_spoke", "mark_curve",
  "mark_image",
  # Distributions
  "mark_histogram", "mark_density", "mark_boxplot", "mark_violin",
  "mark_ecdf",
  # Geographic
  "mark_map",
  # Statistical
  "mark_smooth", "mark_hex", "mark_density_2d", "mark_corr", "mark_heatmap",
  "mark_count", "mark_bin2d", "mark_contour", "mark_qq", "mark_qq_line",
  "mark_ribbon",
  # Composite / annotation
  "mark_errorbar", "mark_significance", "mark_lollipop", "mark_dumbbell",
  "mark_beeswarm", "mark_forest", "mark_label",
  # Relational sugars
  "mark_sankey", "mark_treemap", "mark_network", "mark_chord"
)
