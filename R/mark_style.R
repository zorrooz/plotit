#' @include class.R
NULL

# ---- Unified mark style system (AGENTS.md §6) ----
#
# Single source of truth for every style literal used by mark_* so that all
# marks share one visual language out of the box.
#
# - `._MARK_STYLE`    : named style tokens (colours, stroke widths, sizes).
# - `._MARK_DEFAULTS` : per-mark static defaults injected by `._mark_impl()`.
# - `._apply_mark_defaults()` : merge rules (see below).
#
# Precedence: explicit user parameter > mapped aesthetic (layer or global,
# including the AsIs constants injected by plotit()) > mark default.
# Tokens are iterables per AGENTS.md §1.4 (default-aesthetics tier).

._MARK_STYLE <- list(
  # Brand palette (Tableau 10 subset)
  primary = "#4E79A7", # data marks without a colour/fill mapping
  secondary = "#E15759", # comparison accent (e.g. mark_dumbbell end point)
  # Neutral greys, strong -> light
  ink = "grey30", # strong annotation strokes (significance brackets, sankey nodes)
  soft = "grey50", # mid connectors (lollipop stems, dumbbell links, reference rules)
  faint = "grey70", # background structure (network edges)
  # Stroke ladder (mm): data lines > thin strokes > hairline borders
  lw_data = 0.9, # lines / paths / smooth trends
  lw_thin = 0.5, # stems, edges, connectors, brackets, error bars
  lw_border = 0.25, # white hairline borders on bars / tiles
  # Annotation text size
  txt_note = 3.2, # significance labels, network / sankey node labels
  # Translucency for overlapping filled forms
  alpha_fill = 0.6, # density curves, violins
  alpha_link = 0.5, # sankey flows, chord bands
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
  # Step families use miter joins so corners stay crisp; round joins smear
  # the step geometry at steep slopes.
  mark_step = list(
    linewidth = ._MARK_STYLE$lw_data,
    linejoin = "miter"
  ),
  mark_ecdf = list(
    linewidth = ._MARK_STYLE$lw_data,
    linejoin = "miter"
  ),
  # Link/connector marks share the thin stroke rung of the width ladder.
  mark_curve = list(linewidth = ._MARK_STYLE$lw_thin),
  mark_spoke = list(linewidth = ._MARK_STYLE$lw_thin),
  mark_smooth = list(linewidth = ._MARK_STYLE$lw_data),
  # Bars: 0.7 of the slot (slot = global dodge 0.8) -- slimmer than ggplot2's
  # 0.9 so single-series bars get air and grouped slots keep clear gaps.
  mark_bar = list(colour = "white", linewidth = ._MARK_STYLE$lw_border, width = 0.7),
  mark_histogram = list(colour = "white", linewidth = ._MARK_STYLE$lw_border),
  mark_rect = list(colour = "white", linewidth = ._MARK_STYLE$lw_border),
  mark_bin2d = list(colour = "white", linewidth = ._MARK_STYLE$lw_border),
  mark_area = list(linewidth = 0),
  mark_polygon = list(linewidth = 0),
  mark_density = list(alpha = ._MARK_STYLE$alpha_fill),
  mark_violin = list(alpha = ._MARK_STYLE$alpha_fill),
  mark_rule = list(colour = ._MARK_STYLE$soft, linewidth = ._MARK_STYLE$lw_thin),
  mark_errorbar = list(linewidth = ._MARK_STYLE$lw_thin),
  mark_qq_line = list(
    linewidth = ._MARK_STYLE$lw_thin,
    linetype = "dashed",
    colour = ._MARK_STYLE$soft
  ),
  # Boxplots: slim boxes with generous slot spacing and hairline strokes,
  # calibrated against tidyplots' add_boxplot (box_width 0.6 / lw 0.25 /
  # tiny outliers).  Slot width is the global dodge (0.8), so a 0.5-wide
  # box leaves ~0.3 slot of air between neighbouring groups.
  mark_boxplot = list(
    width = 0.5,
    linewidth = ._MARK_STYLE$lw_border,
    staplewidth = 0.4,
    outlier.size = 0.6
  ),
  # Closed statistical / relational marks rendered through tile-like geoms:
  # white hairline separators keep adjacent cells readable (same token as
  # bar/histogram/rect).  (The treemap sugar renders through mark_rect and
  # inherits its hairline entry above; it needs no entry of its own.)
  mark_corr = list(colour = "white", linewidth = ._MARK_STYLE$lw_border)
)

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

# Closed-cell marks (tile heatmaps: mark_rect / mark_corr) span the full
# data range with no meaningful axis furniture: cells should touch the panel
# edges (zero expansion) and axis lines/ticks would double the grid the tiles
# already draw.  Category text stays visible.  Only applies when the plot
# still uses the default cartesian coordinate system -- an explicit
# project_*() call by the user always wins.
#' Apply closed-cell heatmap chrome to a ggplot object.
#' @noRd
#' @keywords internal
._gg_tile_chrome <- function(gg) {
  gg <- gg + ggplot2::theme(
    axis.line = ggplot2::element_blank(),
    axis.ticks = ggplot2::element_blank()
  )
  coords <- gg$coordinates
  if (is.null(coords) || identical(class(coords)[1], "CoordCartesian")) {
    gg <- gg + ggplot2::coord_cartesian(expand = FALSE)
  }
  gg
}
