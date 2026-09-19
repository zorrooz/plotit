#' @include class.R
NULL

# ---- Unified mark style system (visual contract) ----
#
# SINGLE SOURCE OF TRUTH for every mark-level visual literal.
# Theme/canvas/palette tokens live in R/theme.R (._STYLE_TOKENS).
# Do not duplicate these numbers in AGENTS.md -- point here instead.
# Behavioural pins: tests/testthat/test-style-contract.R
#
# - `._MARK_STYLE`    : named tokens (colours, stroke widths, alphas).
# - `._MARK_DEFAULTS` : per-mark static defaults injected by `._mark_impl()`.
# - `._apply_mark_defaults()` : merge rules (see below).
# - `._MARK_CHROME`   : per-mark canvas axis/legend/expand conventions.
#
# Calibrated to tidyplots source (add-general.R, add-misc.R, add-points.R).
# Precedence: explicit user parameter > mapped aesthetic (layer or global,
# including the AsIs constants injected by plotit()) > mark default.
# Tokens are iterables per AGENTS.md §1.4 (default-aesthetics tier).

._MARK_STYLE <- list(
  # Brand palette: first friendly anchor (tidyplots single-colour default)
  primary = "#0072B2", # data marks without a colour/fill mapping
  secondary = "#E15759", # comparison accent (e.g. mark_dumbbell end point)
  # Neutral greys, strong -> light
  ink = "grey30", # strong annotation strokes (significance brackets, sankey nodes)
  soft = "grey50", # mid connectors (lollipop stems, dumbbell links, reference rules)
  faint = "grey70", # background structure (network edges)
  # Stroke ladder calibrated to tidyplots source (add-general.R / add-misc.R):
  # almost every geometric stroke is 0.25pt hairline; connectors stay at 0.5.
  lw_data = 0.25, # lines / paths / smooth / step / boxplot outlines
  lw_thin = 0.5, # stems, edges, connectors, brackets
  lw_border = 0.25, # hairline rung (alias of tidyplots' default linewidth)
  # Annotation text size
  txt_note = 3.2, # significance labels, network / sankey node labels
  # Translucency (tidyplots: violin/box 0.3, ribbon/area/smooth 0.4)
  alpha_fill = 0.3, # density curves, violins, boxplot fills
  alpha_link = 0.5, # sankey flows, chord bands
  alpha_ci = 0.4, # statistical ribbons / smooth confidence bands
  alpha_annot = 0.18, # encircle annotation envelopes
  alpha_path = 0.2, # project_parallel polyline translucency
  annot_step = 0.06, # significance bracket stacking step (y-span share)
  # Geometry slots (tidyplots)
  width_bar = 0.6,
  width_bar_stack = 0.8,
  width_box = 0.6,
  width_errorbar = 0.4,
  width_ribbon = 0.9,
  width_staple = 0.8,
  size_outlier = 0.5,
  size_node = 5, # network / sankey node dot
  size_path = 1, # project_parallel points
  tip_annot = 0.02, # significance bracket tip length
  lw_path = 1.6, # project_parallel polyline
  # NA cell fill for matrix marks
  na_colour = "grey85",
  # Label contrast on filled tiles (auto contrast)
  on_fill_dark = "grey20",
  on_fill_light = "white",
  # Composite point heads
  point_head = 3 # lollipop heads, dumbbell endpoints
)

._MARK_DEFAULTS <- list(
  mark_line = list(
    linewidth = ._MARK_STYLE$lw_data,
    lineend = "round",
    linejoin = "round"
  ),
  mark_path = list(
    linewidth = ._MARK_STYLE$lw_data,
    lineend = "round",
    linejoin = "round"
  ),
  # Step families use mitre joins so corners stay crisp; round joins smear
  # the step geometry at steep slopes.  (grid spells it "mitre".)
  mark_step = list(
    linewidth = ._MARK_STYLE$lw_data,
    linejoin = "mitre"
  ),
  mark_ecdf = list(
    linewidth = ._MARK_STYLE$lw_data,
    linejoin = "mitre"
  ),
  # Link/connector marks share the mid stroke rung of the width ladder.
  mark_curve = list(linewidth = ._MARK_STYLE$lw_thin),
  mark_spoke = list(linewidth = ._MARK_STYLE$lw_thin),
  # tidyplots add_curve_fit: linewidth 0.25, alpha 0.4
  mark_smooth = list(
    linewidth = ._MARK_STYLE$lw_data,
    alpha = ._MARK_STYLE$alpha_ci
  ),
  # tidyplots ff_bar: width 0.6, color = NA (flush, no stroke).
  # Stacked bars often want width 0.8 -- pass width= explicitly.
  mark_bar = list(linewidth = 0, width = 0.6),
  # tidyplots add_data_points: size 1 (ggplot2 default is 1.5)
  mark_point = list(size = 1),
  # tidyplots add_data_points_beeswarm: size 1 + collision cex 3
  mark_beeswarm = list(size = 1, cex = 3),
  # QQ points follow the same point scale
  mark_qq = list(size = 1),
  mark_count = list(),
  # Annotation text: publication-sized note font
  mark_text = list(size = ._MARK_STYLE$txt_note),
  mark_label = list(size = ._MARK_STYLE$txt_note),
  # Rug ticks: hairline ink
  mark_rug = list(linewidth = ._MARK_STYLE$lw_data),
  # Contour / 2D density strokes: hairline
  mark_contour = list(linewidth = ._MARK_STYLE$lw_data),
  mark_density_2d = list(linewidth = ._MARK_STYLE$lw_data),
  # Hex / heatmap cells flush like rect/tile family
  mark_hex = list(linewidth = 0),
  mark_heatmap = list(linewidth = 0),
  mark_histogram = list(linewidth = 0),
  mark_rect = list(linewidth = 0),
  mark_bin2d = list(linewidth = 0),
  # tidyplots add_area: linewidth 0, alpha 0.4
  mark_area = list(linewidth = 0, alpha = ._MARK_STYLE$alpha_ci),
  mark_polygon = list(
    linewidth = 0,
    fill = ._MARK_STYLE$primary
  ),
  # tidyplots add_violin / density family: alpha 0.3
  mark_density = list(alpha = ._MARK_STYLE$alpha_fill),
  mark_violin = list(
    alpha = ._MARK_STYLE$alpha_fill,
    linewidth = ._MARK_STYLE$lw_data
  ),
  mark_rule = list(colour = ._MARK_STYLE$soft, linewidth = ._MARK_STYLE$lw_thin),
  # tidyplots ff_errorbar: linewidth 0.25, width 0.4
  mark_errorbar = list(
    linewidth = ._MARK_STYLE$lw_data,
    width = 0.4
  ),
  # tidyplots ff_ribbon: alpha 0.4, color = NA
  mark_ribbon = list(alpha = ._MARK_STYLE$alpha_ci, colour = NA),
  mark_qq_line = list(
    linewidth = ._MARK_STYLE$lw_data,
    linetype = "dashed",
    colour = ._MARK_STYLE$soft
  ),
  # tidyplots add_boxplot: width 0.6, alpha 0.3, linewidth 0.25,
  # staplewidth 0.8, outlier.size 0.5.  Stroke follows the mapped colour
  # (do NOT force ink -- that overrode group outlines).
  mark_boxplot = list(
    width = 0.6,
    alpha = ._MARK_STYLE$alpha_fill,
    linewidth = ._MARK_STYLE$lw_data,
    staplewidth = 0.8,
    outlier.size = 0.5
  ),
  # Closed statistical / relational marks: flush cells (tidyplots heatmap).
  mark_corr = list(linewidth = 0)
)

# tidyplots ff_bar / ff_barstack zero the lower padding so bars sit flush
# on the value axis instead of floating above a 5% expansion gap.
# Continuous value axis only; discrete axes keep ggplot2 expansion.
#' Zero the lower expansion on the continuous value axis (tidyplots bars).
#' @noRd
#' @keywords internal
._flush_value_axis <- function(plot, axis = "y") {
  gg <- plot@gg
  sc <- gg$scales$get_scales(axis)
  has_sc <- !is.null(sc)
  discrete <- has_sc && inherits(sc, c("ScaleDiscretePosition", "ScaleDiscrete"))
  if (discrete) {
    return(plot)
  }
  # Default continuous expansion is mult = c(0.05, 0.05); keep the upper
  # headroom for value labels (tidyplots padding = c(0, NA) -> upper 0.05).
  plot@gg <- gg + ggplot2::scale_y_continuous(
    name = if (has_sc && !inherits(sc$name, "waiver")) sc$name else ggplot2::waiver(),
    expand = ggplot2::expansion(mult = c(0, 0.05))
  )
  plot
}

# Collect aesthetics mapped on the layer or globally.  Used to gate static
# defaults: a default never overrides an aesthetic the pipeline already maps.
#' Collect aesthetics mapped on the layer or in the global mapping.
#' @noRd
#' @keywords internal
._mapped_aes <- function(plot, mapping) {
  gm <- plot@gg$mapping
  union(names(mapping), names(gm))
}

# Aesthetics the *user* owns: like ._mapped_aes(), but ignores the AsIs
# constants injected by plotit()'s default_color mechanism.  Used where a
# style default must coexist with the injected single-colour look.
#' Collect user-owned (non-injected) mapped aesthetics.
#' @noRd
#' @keywords internal
._user_owned_aes <- function(plot, mapping) {
  keep_user <- function(x) {
    nms <- names(x)
    nms[!vapply(x[nms], inherits, logical(1), "AsIs")]
  }
  union(names(mapping), keep_user(plot@gg$mapping %||% list()))
}

# Merge per-mark static defaults into the geom-call dots.
# - Skips any parameter the user supplied via ... .
# - Skips any parameter whose name is mapped as an aesthetic (so e.g. the
#   white bar border never clobbers a mapped `colour` grouping).
# - Special case mark_boxplot: while the plotit()-injected single default
#   colour is live, the box stroke/median/outliers would render in the same
#   blue as the fill; a dark neutral stroke restores contrast.  The override
#   only fires when the user has not chosen their own colour.
#' Apply unified mark style defaults to geom-call dots.
#' @noRd
#' @keywords internal
._apply_mark_defaults <- function(plot, mapping, dots, mark_name) {
  if (is.null(mark_name)) {
    return(dots)
  }
  defaults <- ._MARK_DEFAULTS[[mark_name]]
  if (!is.null(defaults)) {
    mapped <- ._mapped_aes(plot, mapping)
    for (nm in names(defaults)) {
      if (nm %in% names(dots) || nm %in% mapped) {
        next
      }
      dots[[nm]] <- defaults[[nm]]
    }
  }
  # Special case mark_boxplot: while the plotit()-injected single default
  # colour is live, the box stroke/median/outliers would render in the same
  # blue as the fill; a dark neutral stroke restores contrast.  The override
  # only fires when the user has not chosen their own colour (the AsIs
  # injected constants do not count as user ownership).
  if (identical(mark_name, "mark_boxplot") && !"colour" %in% names(dots)) {
    injection_live <- !is.null(plot@meta@default_color)
    if (!"colour" %in% ._user_owned_aes(plot, mapping) && injection_live) {
      dots$colour <- ._MARK_STYLE$ink
    }
  }
  dots
}

# Relational diagrams (network / sankey / chord / treemap) are coordinate-
# free canvases: blank every axis element so the shared theme's axis lines,
# ticks and titles do not frame an unframed layout.  One helper keeps the
# whole family visually uniform.  The gg-level variant is also applied at
# construction for graph data, so the explicit pipeline form renders
# identically to the sugar marks.  `ticks_length = TRUE` additionally
# zeroes axis.ticks.length (used by project_polar, where residual tick
# space would offset the polar panel even with ticks blanked).
#' Blank all axis elements on a ggplot object.
#' @noRd
#' @keywords internal
._gg_blank_axes <- function(gg, ticks_length = FALSE) {
  args <- list(
    axis.line = ggplot2::element_blank(),
    axis.ticks = ggplot2::element_blank(),
    axis.text = ggplot2::element_blank(),
    axis.title = ggplot2::element_blank()
  )
  if (ticks_length) {
    args$axis.ticks.length <- ggplot2::unit(0, "pt")
  }
  gg + do.call(ggplot2::theme, args)
}

#' Blank all axis elements for coordinate-free relational diagrams.
#' @noRd
#' @keywords internal
._theme_blank_axes <- function(plot) {
  plot@gg <- ._gg_blank_axes(plot@gg)
  plot
}

# Closed-cell / heatmap marks (corr, heatmap, rect tiles, bin2d, hex) span
# their own canvas: the cells or bins draw the structure, so axis furniture
# is redundant and gets blanked per the AGENTS.md <U+00A7>6 convention table.  Two
# knobs: keep_text (category labels of corr/rect/heatmap rows and columns
# carry meaning; bin2d/hex count fields blank everything) and zero_expand
# (cells flush to the panel edge for tile marks; bin2d/hex keep the default
# padding so edge bins stay whole).  Only applies while the plot still uses
# the default cartesian coordinate system -- an explicit project_*() call
# by the user always wins.
#' Apply cell-mark axis chrome (B2 convention table).
#' @noRd
#' @keywords internal
._gg_cell_chrome <- function(gg, keep_text = TRUE, zero_expand = TRUE) {
  args <- list(
    axis.line = ggplot2::element_blank(),
    axis.ticks = ggplot2::element_blank()
  )
  if (!keep_text) {
    args$axis.text <- ggplot2::element_blank()
    args$axis.title <- ggplot2::element_blank()
  }
  gg <- gg + do.call(ggplot2::theme, args)
  if (!is.null(zero_expand) && zero_expand) {
    coords <- gg$coordinates
    if (is.null(coords) || identical(class(coords)[1], "CoordCartesian")) {
      gg <- gg + ggplot2::coord_cartesian(expand = FALSE)
    }
  }
  gg
}

# ---- chrome convention registry (D-06, design/03 <U+00A7>6) ----
# One decision point for per-mark canvas conventions, consulted by the
# shared mark path (_mark_impl) and the relational sugars (_rel_canvas):
#
#   axis   "keep"  native axes (geometry / distribution / trend marks)
#          "blank" coordinate-free canvas (no axis furniture at all)
#          "cell"  closed-cell chrome: no axis line/ticks, category text
#                  kept, panel flush (expand = 0)
#   legend "auto"  follow the mapping (default); "none" force-hidden
#   expand "default" ggplot2 expansion; "zero" tiles flush to the panel
#
# Marks absent from the table default to keep/auto/default, so make_mark()
# customs keep zero behavior difference (AGENTS.md 3.3.3c).
._MARK_CHROME <- list(
  # Geometry / distribution / trend: native axes
  mark_point = list(axis = "keep"),
  mark_line = list(axis = "keep"),
  mark_step = list(axis = "keep"),
  mark_path = list(axis = "keep"),
  mark_area = list(axis = "keep"),
  mark_bar = list(axis = "keep"),
  mark_histogram = list(axis = "keep"),
  mark_density = list(axis = "keep"),
  mark_boxplot = list(axis = "keep"),
  mark_violin = list(axis = "keep"),
  mark_beeswarm = list(axis = "keep"),
  mark_count = list(axis = "keep"),
  mark_rug = list(axis = "keep"),
  mark_spoke = list(axis = "keep"),
  mark_curve = list(axis = "keep"),
  mark_label = list(axis = "keep"),
  mark_text = list(axis = "keep"),
  mark_smooth = list(axis = "keep"),
  mark_ecdf = list(axis = "keep"),
  mark_qq = list(axis = "keep"),
  mark_qq_line = list(axis = "keep"),
  mark_errorbar = list(axis = "keep"),
  mark_ribbon = list(axis = "keep"),
  mark_lollipop = list(axis = "keep"),
  mark_dumbbell = list(axis = "keep"),
  mark_forest = list(axis = "keep"),
  mark_significance = list(axis = "keep"),
  mark_encircle = list(axis = "keep"),
  mark_image = list(axis = "keep"),
  # Long-table tile marks keep light axes (G2 Cell / OP calendar); tiles
  # themselves span the full data range so rect stays panel-flush.
  mark_rect = list(axis = "keep", expand = "zero"),
  mark_bin2d = list(axis = "keep"),
  mark_hex = list(axis = "keep"),
  # Matrix-input marks: closed-cell chrome, category labels carry the story
  mark_heatmap = list(axis = "cell"),
  mark_corr = list(axis = "cell"),
  # Geographic: the projection draws its own graticule
  mark_map = list(axis = "blank"),
  # Relational sugars own their canvas
  mark_sankey = list(axis = "blank"),
  mark_treemap = list(axis = "blank"),
  mark_network = list(axis = "blank"),
  mark_chord = list(axis = "blank")
)

#' Apply a mark's registered canvas chrome.
#' @noRd
#' @keywords internal
._apply_chrome <- function(plot, mark_name) {
  chrome <- ._MARK_CHROME[[mark_name]] %||% list(axis = "keep")
  axis <- chrome$axis %||% "keep"
  if (identical(axis, "blank")) {
    plot <- ._theme_blank_axes(plot)
  } else if (identical(axis, "cell")) {
    plot@gg <- ._gg_cell_chrome(plot@gg, keep_text = TRUE, zero_expand = TRUE)
  }
  if (identical(chrome$expand, "zero") && !identical(axis, "cell")) {
    coords <- plot@gg$coordinates
    if (is.null(coords) || identical(class(coords)[1], "CoordCartesian")) {
      plot@gg <- plot@gg + ggplot2::coord_cartesian(expand = FALSE)
    }
  }
  if (identical(chrome$legend, "none")) {
    plot@gg <- plot@gg + ggplot2::guides(colour = "none", fill = "none")
  }
  plot
}

#' Closed-cell heatmap chrome (tiles flush to the panel, fonts kept).
#' @noRd
#' @keywords internal
._gg_tile_chrome <- function(gg) {
  ._gg_cell_chrome(gg, keep_text = TRUE, zero_expand = TRUE)
}
