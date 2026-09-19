#' Initialize a plotit object
#'
#' @include class.R encode.R utils.R style.R
#' @param data A data frame, a matrix (coerced with `as.data.frame()`),
#'   or a `plotit_graph` (relational pipeline; see [as_graph()]).
#' @param mapping An object created by [encode()].
#' @param autofit Logical; if `TRUE`, panel size is not baked (follows the
#'   device). If `FALSE` (default) the panel is baked WYSIWYG at
#'   `width`/`height`.
#' @param width,height Numeric; panel size in `size_unit`. Default is a
#'   Nature single-column canvas (89 x 56 mm). Ignored when `autofit = TRUE`.
#' @param size_unit Unit for width/height: `"in"`, `"cm"`, `"mm"`.
#' @param dodge Numeric; global default dodge width. If `NULL`, heuristically set
#'   to `0.8` when a discrete axis is present, else `0`.
#' @param default_color Single color string. Applied as default color mapping if no
#'   color/fill aesthetic is present in `mapping`. Adding any `scale_color()` or
#'   `scale_fill()` later will automatically disable this single-color mapping.
#'   Default is the first friendly palette anchor (`#0072B2`).
#' @return A `plotit` object.
#' @examples
#' plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
#' plotit(mtcars, encode(x = wt, y = mpg, colour = cyl))
#' @export
plotit <- function(
  data,
  mapping = encode(),
  autofit = FALSE,
  width = 89,
  height = 56,
  size_unit = "mm",
  dodge = NULL,
  default_color = "#0072B2"  # = ._MARK_STYLE$primary (friendly anchor)
) {
  if (!inherits(mapping, "plotit_encode")) {
    cli::cli_abort(c(
      "Invalid {.arg mapping} argument",
      "x" = "{.arg mapping} must be created with {.fn encode}",
      "i" = "Did you forget to use {.code encode(x = ..., y = ...)}?"
    ))
  }

  # Graph input: mappings are declared at mark level (~nodes / ~edges),
  # so a non-empty global mapping has no well-defined target table.
  graph_input <- inherits(data, "plotit_graph")
  if (graph_input && length(mapping) > 0) {
    cli::cli_abort(c(
      "Graph plots declare aesthetics at the mark level.",
      "x" = "{.arg mapping} must be empty for {.cls plotit_graph} data.",
      "i" = "Use {.code mark_point(data = ~nodes, encode(...))} instead."
    ))
  }
  if (graph_input && !missing(default_color) && !is.null(default_color)) {
    cli::cli_warn(c(
      "{.arg default_color} is ignored for {.cls plotit_graph} data.",
      "i" = "Graph marks take their colour from the mapped aesthetic or scale_*()."
    ))
  }

  if (!autofit && (is.null(width) || is.null(height))) {
    ._abort_hint(
      "When {.code autofit = FALSE}, both {.arg width} and {.arg height} must be provided.",
      "Pass both dimensions or set {.code autofit = TRUE}."
    )
  }

  valid_units <- c("in", "cm", "mm")
  if (!(size_unit %in% valid_units)) {
    ._abort_arg_enum("size_unit", valid_units, got = size_unit)
  }

  if (autofit && (!missing(width) || !missing(height))) {
    cli::cli_warn(c(
      "{.arg autofit} is {.val TRUE}; {.arg width} and {.arg height} have no effect.",
      "i" = "They are ignored; remove them or set {.code autofit = FALSE} for explicit sizing."
    ))
  }

  # Matrix input: ggplot2 4.0's data validation requires uniquely named
  # columns (`check_data_frame_like`), so plain matrices (with or without
  # dimnames) error before any layer is built.  Coerce early on the plotit
  # boundary so `plotit(matrix, encode(...))` just works; `as.data.frame()`
  # keeps dimnames (column names, row names) when present and invents
  # V1..Vk otherwise.
  if (!graph_input && is.matrix(data)) {
    data <- as.data.frame(data, stringsAsFactors = FALSE)
  }

  if (graph_input) {
    # No global mapping: no discrete heuristic, no default color injection.
    dodge <- dodge %||% 0
    use_default <- FALSE
    p <- ggplot2::ggplot()
  } else {
    if (is.null(dodge)) {
      disc_x <- !is.null(mapping$x) && is_discrete(data, mapping$x)
      disc_y <- !is.null(mapping$y) && is_discrete(data, mapping$y)
      dodge <- if (disc_x || disc_y) 0.8 else 0
    }

    has_color <- "colour" %in% names(mapping)
    has_fill <- "fill" %in% names(mapping)

    # tidyplots-style colour/fill mirroring -- DISCRETE channels only.
    # A categorical group drives both outline and fill (boxplot strokes,
    # bar edges, point borders).  Continuous fill (heatmap / corr magnitude)
    # is left alone: mirroring it would inject a colour quosure that layer
    # reshapes (Var1/Var2/value) cannot resolve.
    # The mirrored twin is visual-only: its default scale is attached with
    # guide="none" so one group variable never renders two legends.
    .is_disc_quo <- function(q, data) {
      col <- tryCatch(rlang::eval_tidy(q, data), error = function(e) NULL)
      !is.null(col) && (is.factor(col) || is.character(col) || is.logical(col))
    }
    mirrored_aes <- NULL
    if (has_color && !has_fill && .is_disc_quo(mapping$colour, data)) {
      mapping <- structure(
        utils::modifyList(mapping, list(fill = mapping$colour)),
        class = c("plotit_encode", "uneval")
      )
      has_fill <- TRUE
      mirrored_aes <- "fill"
    } else if (has_fill && !has_color && .is_disc_quo(mapping$fill, data)) {
      mapping <- structure(
        utils::modifyList(mapping, list(colour = mapping$fill)),
        class = c("plotit_encode", "uneval")
      )
      has_color <- TRUE
      mirrored_aes <- "colour"
    }

    # Inject I(default_color) to both colour and fill so that all geoms
    # (points, bars, tiles, ...) pick up the same single-color appearance.
    use_default <- !is.null(default_color) && !has_color && !has_fill
    if (use_default) {
      # Clone mapping to avoid mutating the caller's encode() object
      mapping <- structure(
        utils::modifyList(mapping, list(colour = I(default_color), fill = I(default_color))),
        class = c("plotit_encode", "uneval")
      )
      p <- ggplot2::ggplot(data, mapping) +
        ggplot2::guides(colour = "none", fill = "none")
    } else {
      p <- ggplot2::ggplot(data, mapping)
    }
  }

  meta_labels <- plotit_labels()
  meta <- plotit_metadata(
    autofit = autofit,
    width = if (autofit) NULL else width,
    height = if (autofit) NULL else height,
    unit = size_unit,
    dodge = dodge,
    default_color = if (use_default) default_color else NULL,
    labels = meta_labels
  )

  p <- p + ._theme_default()

  # Coordinate-free canvas for graph data (domain-level rule, AGENTS.md
  # 3.3.4a): relational layouts carry their own geometry, so axis lines,
  # ticks, text and titles are blanked at construction.  This makes the
  # explicit pipeline form (as_graph() |> plotit() |> layout_*() |> mark_*)
  # render identically to the sugar marks, which blank idempotently.
  if (graph_input) {
    p <- ._gg_blank_axes(p)
  }

  # Clean default axis titles: strip discrete-cast wrappers so
  # encode(x = factor(cyl)) labels the axis "cyl", not "factor(cyl)".
  clean_labels <- list(
    x = ._clean_axis_label(mapping$x),
    y = ._clean_axis_label(mapping$y)
  )
  clean_labels <- Filter(Negate(is.null), clean_labels)
  if (length(clean_labels) > 0) {
    p <- p + do.call(ggplot2::labs, clean_labels)
  }

  # Curated default colour scales for mapped colour/fill aesthetics
  # (friendly discrete / viridis continuous).  Skipped for the injected
  # single-colour path, which owns its static brand blue.
  managed <- character(0)
  if (!graph_input && !use_default) {
    silent <- if (!is.null(mirrored_aes)) mirrored_aes else character(0)
    p <- ._attach_default_colour_scale(p, data, mapping, silent_aes = silent)
    managed <- intersect(c("colour", "fill"), names(mapping))
  }
  if (use_default) {
    # The injected constants own both channels until cleared.
    managed <- c("colour", "fill")
  }
  attr(meta, "plotit_colour_managed") <- managed

  # Bake absolute panel dimensions into the ggplot object so every render
  # context (IDE, knitr, pkgdown, export) shares identical content
  # proportions (WYSIWYG; AGENTS.md 3.3.11).
  p <- ._apply_panel_size(p, meta@width, meta@height, meta@unit)

  # Stored on meta, not gg$theme -- patchwork wrapping would shadow $theme
  attr(meta, "plotit_theme_managed") <- TRUE

  out <- plotit_class(gg = p, meta = meta, graph = if (graph_input) data else NULL)
  # Prepend unqualified class so S3 dispatch (e.g. print.plotit) fires
  # before the S7-default print.S7_object.  The namespaced class remains
  # in the vector for S7 method dispatch.
  class(out) <- c("plotit", class(out))
  out
}

# ---- ggplot2 escape hatch ----
# `add_ggplot(plot, component)` forwards a ggplot2 component (annotate,
# guides, labs, theme elements, custom layers, facets) to the underlying
# ggplot, giving advanced users the full ggplot2 vocabulary without
# dropping the plotit wrapper.  The verb API stays the recommended path:
# direct `+ scale_*()` usage bypasses the package's managed colour registry.
# Replaces the former S3 `+.plotit` / `+.plotit_composite` overloads so the
# escape hatch has one explicit, discoverable entry point (tidyplots'
# `add()` plays the same role in that package).
#' Add a ggplot2 component to a plot
#'
#' Escape hatch for advanced ggplot2 usage: `add_ggplot(p,
#' ggplot2::annotate(...))`, `add_ggplot(p, ggplot2::guides(...))`,
#' `add_ggplot(p, ggplot2::labs(...))` etc. modify the underlying ggplot
#' and return the `plotit` object so the pipeline continues.  Prefer the
#' verb API (`mark_*`, `scale_*`, `label_*`, `style`) for reproducible,
#' well-validated plots.
#'
#' @section Stability:
#' Extension surface (contract tier: extensible). The signature is stable as
#' documented; it is the supported replacement for the former S3 `+` operator
#' on `plotit` objects, which is intentionally not defined so that ggplot2
#' components are only added through this single explicit entry point.
#'
#' ggplot2 4.0's [ggplot2::stat_manual()] slots in here as a custom
#' data-transformation layer without a dedicated plotit verb:
#' `add_ggplot(p, ggplot2::stat_manual(fun = function(d) ...))`.
#'
#' @param plot A `plotit` object (or a `plotit_composite`).
#' @param component Any object ggplot2's `+` accepts (layer, scale, coord,
#'   facet, theme, labs, or a ggplot2 object).
#' @return A modified `plotit` (or `plotit_composite`) object.
#' @examples
#' p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
#'   mark_point() |>
#'   add_ggplot(ggplot2::annotate("text", x = 2.5, y = 7.9, label = "high", size = 3))
#' @export
add_ggplot <- S7::new_generic(
  "add_ggplot", "plot",
  function(plot, component) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(add_ggplot, plotit_class) <- function(plot, component) {
  plot@gg <- plot@gg + component
  plot
}

#' @export
S7::method(add_ggplot, plotit_composite) <- function(plot, component) {
  # patchwork owns `+` for composite gg objects (applies to the last
  # sub-panel; use style() to reach every panel).
  plot@gg <- plot@gg + component
  plot
}
