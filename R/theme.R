#' @include class.R utils.R
NULL

# ---- Global visual style tokens (single source of truth) ----
#
# SINGLE SOURCE OF TRUTH for theme, canvas, and default palettes.
# Mark-level literals live in mark_style.R (._MARK_STYLE / ._MARK_DEFAULTS).
# The two tables never cross-reference. Behavioural pins:
# tests/testthat/test-style-contract.R
#
# Calibrated to the Nature/publication figure contract (theme_classic,
# 6.5 pt type ladder, 0.35 axis strokes, fixed 89 x 56 mm single-column
# canvas, 600 dpi export). Mark-level literals live in mark_style.R.
# Changing a value here restyles every plotit output.

# Mix ink toward paper: 0 = pure ink, 1 = pure paper.
#' Mix the ink token toward paper by a proportion.
#' @noRd
#' @keywords internal
._ink_mix <- function(proportion) {
  ink <- grDevices::col2rgb(._PLOTIT_INK)
  paper <- grDevices::col2rgb(._PLOTIT_PAPER)
  mixed <- paper * proportion + ink * (1 - proportion)
  grDevices::rgb(
    red = mixed[1], green = mixed[2], blue = mixed[3],
    maxColorValue = 255
  )
}

._PLOTIT_INK <- "#000000"
._PLOTIT_PAPER <- "#FFFFFF"

._STYLE_TOKENS <- list(
  # Paper / ink anchors
  paper = ._PLOTIT_PAPER,
  ink = ._PLOTIT_INK,
  # Derived greys (ink mixed toward paper) -- still used by chrome helpers
  grey_title_sub = ._ink_mix(0.35),
  grey_caption = ._ink_mix(0.50),
  grey_text_axis = ._ink_mix(0.30),
  grey_legend_title = ._ink_mix(0.20),
  grey_legend_text = ._ink_mix(0.30),
  # Axis stroke (Nature contract: 0.35 pt)
  lw_axis = 0.35,
  # Type ladder in absolute pt (Nature / journal-final dense figures)
  base_size = 6.5,
  size_title = 7,
  size_subtitle = 6.5,
  size_caption = 6,
  size_axis_title = 6.5,
  size_axis_text = 6,
  size_strip = 6.2,
  size_legend_title = 6.2,
  size_legend_text = 5.8,
  legend_key_mm = 3.5,
  # Default palettes (friendly qualitative / viridis sequential)
  palette_discrete = c(
    "#0072B2", "#56B4E9", "#009E73", "#F5C710", "#E69F00", "#D55E00"
  ),
  palette_continuous = "viridis"
)

# Sample n colours from the discrete token palette.  Up to the anchor count an
# evenly spaced subset is returned (preserving contrast); beyond it the anchors
# are interpolated, mirroring tidyplots' make_palette behaviour.
#' Sample n colours from the default discrete palette.
#' @noRd
#' @keywords internal
._palette_discrete <- function(n) {
  anchors <- ._STYLE_TOKENS$palette_discrete
  n_l <- length(anchors)
  if (n <= n_l) {
    idx <- unique(round(seq(1, n_l, length.out = n)))
    return(anchors[idx])
  }
  grDevices::colorRampPalette(anchors)(n)
}

# ---- Default theme builder ----
# Nature/journal contract: classic base, white paper, L-spines only,
# 0.35 pt axes, 6.5 pt type ladder, bold title, frameless legend.
._theme_default <- function(base_size = NULL, base_family = NULL) {
  tok <- ._STYLE_TOKENS
  size <- base_size %||% tok$base_size
  family <- base_family %||% ""
  # Scale the absolute type ladder when the caller overrides base_size
  k <- size / tok$base_size
  ggplot2::theme_classic(
    base_size = size,
    base_family = family,
    base_line_size = tok$lw_axis,
    base_rect_size = tok$lw_axis
  ) + ggplot2::theme(
    panel.background = ggplot2::element_rect(fill = tok$paper, colour = NA),
    panel.border = ggplot2::element_blank(),
    panel.grid = ggplot2::element_blank(),
    plot.background = ggplot2::element_rect(fill = tok$paper, colour = NA),
    legend.background = ggplot2::element_rect(fill = NA, colour = NA),
    legend.key = ggplot2::element_rect(fill = NA, colour = NA),
    legend.box.background = ggplot2::element_rect(fill = NA, colour = NA),
    legend.box.spacing = ggplot2::unit(0, "cm"),
    strip.background = ggplot2::element_rect(fill = NA, colour = NA),
    axis.line = ggplot2::element_line(colour = tok$ink, linewidth = tok$lw_axis),
    axis.ticks = ggplot2::element_line(colour = tok$ink, linewidth = tok$lw_axis),
    plot.title = ggplot2::element_text(
      size = tok$size_title * k,
      face = "bold",
      hjust = 0,
      colour = tok$ink
    ),
    plot.subtitle = ggplot2::element_text(
      size = tok$size_subtitle * k,
      hjust = 0,
      colour = tok$ink
    ),
    plot.caption = ggplot2::element_text(
      size = tok$size_caption * k,
      colour = tok$ink
    ),
    axis.title = ggplot2::element_text(
      size = tok$size_axis_title * k,
      colour = tok$ink
    ),
    axis.text = ggplot2::element_text(
      size = tok$size_axis_text * k,
      colour = tok$ink
    ),
    strip.text = ggplot2::element_text(
      size = tok$size_strip * k,
      face = "bold",
      colour = tok$ink
    ),
    legend.position = "right",
    legend.title = ggplot2::element_text(
      size = tok$size_legend_title * k,
      colour = tok$ink
    ),
    legend.text = ggplot2::element_text(
      size = tok$size_legend_text * k,
      colour = tok$ink
    ),
    legend.key.size = ggplot2::unit(tok$legend_key_mm, "mm")
  )
}

# Pick the colour or fill variant of a scale function (eliminates aes
# branching).  Lives beside the palette decision point because both encode
# "which channel of the colour pair am I serving".
#' Pick colour or fill variant of a scale function.
#' @noRd
#' @keywords internal
._cf <- function(aes, fun_c, fun_f) {
  if (aes == "colour") fun_c else fun_f
}

# ---- Default colour scale attachment ----
# Attach the token palettes as soon as a colour/fill mapping exists, so every
# reference example looks curated without any scale_*() call.  A later user
# scale_*() replaces these (last-wins), preserving full override semantics.
# AsIs constants (encode(colour = I("red"))) resolve through ggplot2's
# identity scaling and are left untouched.
#
# ._default_colour_scale() is the SINGLE decision point for every default
# colour scale in the package: construction-time global mappings, layer-level
# mappings (via ._mark_impl) and mark-owned derived channels all route through
# it, so a categorical column always renders in the friendly token palette and
# a continuous column always in the token sequential scheme -- no matter which
# mark family produced it.
#' Resolve the default colour scale for one aesthetic/column pair.
#'
#' Returns `NULL` when the column cannot be resolved or is an AsIs constant
#' (identity scaling owns those).
#' @noRd
#' @keywords internal
._default_colour_scale <- function(aes_name, data_tbl, var, guide = "legend") {
  col <- tryCatch(rlang::eval_tidy(var, data_tbl), error = function(e) NULL)
  if (is.null(col) || inherits(col, "AsIs")) {
    return(NULL)
  }
  if (is.factor(col) || is.character(col) || is.logical(col)) {
    # discrete_scale(palette=) instead of scale_*_discrete(type=): the
    # latter is re-executed by ggplot2 >= 4.0's backward-compatibility
    # layer, which misinterprets plain palette functions.
    ggplot2::discrete_scale(
      aesthetics = aes_name,
      palette = function(n) ._palette_discrete(n),
      guide = guide
    )
  } else {
    sc <- ._cf(
      aes_name,
      ggplot2::scale_colour_viridis_c,
      ggplot2::scale_fill_viridis_c
    )(option = ._STYLE_TOKENS$palette_continuous)
    if (!identical(guide, "legend")) {
      guides <- list(guide)
      names(guides) <- aes_name
      sc <- sc + do.call(ggplot2::guides, guides)
    }
    sc
  }
}

#' Attach default colour scales for mapped colour/fill aesthetics.
#' `silent_aes` get `guide = "none"` (mirrored colour/fill twins).
#' @noRd
#' @keywords internal
._attach_default_colour_scale <- function(p, data, mapping,
                                          silent_aes = character(0)) {
  for (aes_name in intersect(c("colour", "fill"), names(mapping))) {
    guide <- if (aes_name %in% silent_aes) "none" else "legend"
    sc <- ._default_colour_scale(aes_name, data, mapping[[aes_name]],
      guide = guide
    )
    if (!is.null(sc)) {
      p <- p + sc
    }
  }
  p
}

# ---- WYSIWYG absolute panel sizing ----
# Bake the meta panel dimensions into the ggplot object itself via the
# ggplot2 >= 4.0 theme elements panel.widths / panel.heights (#5338).  Every
# render path (IDE device, knitr, pkgdown examples, ggsave) then draws the
# panel at exactly the declared physical size, so on-screen previews and
# exports share identical content proportions.
#' Bake fixed panel dimensions into a ggplot object.
#'
#' `grid` gives the panel-grid dimensions (cols, rows) the declared size is
#' spread across: meta sizes describe the whole panel *area*, so each cell
#' in an n-column facet layout receives width / ncol (height / nrow).
#' @noRd
#' @keywords internal
._apply_panel_size <- function(gg, width, height, unit = "in",
                               grid = c(1, 1)) {
  if (is.null(width) || is.null(height)) {
    return(gg)
  }
  ncol <- max(1, grid[1])
  nrow <- max(1, grid[2])
  gg + ggplot2::theme(
    panel.widths = grid::unit(rep(width / ncol, ncol), unit),
    panel.heights = grid::unit(rep(height / nrow, nrow), unit)
  )
}

#' Panel-grid dimensions (cols, rows) of a built ggplot.
#'
#' Reads the panel layout from a ggplot_build result so facet layouts
#' spread the declared panel area across their cells.
#' @noRd
#' @keywords internal
._panel_grid_dims <- function(gg) {
  built <- tryCatch(ggplot2::ggplot_build(gg), error = function(e) NULL)
  if (is.null(built)) {
    return(c(1, 1))
  }
  lay <- built$layout$layout
  if (is.null(lay) || nrow(lay) == 0) {
    return(c(1, 1))
  }
  c(max(lay$COL), max(lay$ROW))
}

#' Strip baked panel dimensions from a ggplot object.
#'
#' Uses the public `+ theme(panel.widths = NULL)` reset rather than mutating
#' `gg$theme` directly -- under ggplot2 >= 4.0 themes are S7 objects whose
#' list-subset assignment fails validation.
#' @noRd
#' @keywords internal
._strip_panel_size <- function(gg) {
  baked_keys <- c("panel.widths", "panel.heights")
  has_baked <- vapply(baked_keys, function(k) !is.null(gg$theme[[k]]), logical(1))
  if (!any(has_baked)) {
    return(gg)
  }
  gg + ggplot2::theme(panel.widths = NULL, panel.heights = NULL)
}

# Aspect-true rendering outranks fixed panel sizing: absolute baked panel
# dimensions would override a fixed-aspect coordinate system (coord_fixed)
# and stretch circles into ellipses.  Circular diagrams (chord / network)
# and user project_cartesian(fixed = ...) hit this.
#' Whether baked panel sizing would conflict with a fixed-aspect coord.
#' @noRd
#' @keywords internal
._gg_aspect_conflict <- function(gg) {
  if (is.null(gg$coordinates)) {
    return(FALSE)
  }
  inherits(gg$coordinates, "CoordFixed") ||
    inherits(gg$coordinates, "CoordPolar") ||
    inherits(gg$coordinates, "CoordRadial")
}

# ---- polar coordinate chrome (single decision point) ----
#
# Polar panels never carry Cartesian furniture.  The budget:
#   theta = "y"  (pie / donut)              -> no axes at all
#   theta = "x", plain coord_polar (rose)   -> no axes at all
#   theta = "x", coord_radial              -> angular (theta) axis blanked,
#                                             radius axis kept (radial ticks
#                                             carry the value story per
#                                             AGENTS.md 3.2b)
# Applied inside project_polar() AND defensively at every render entry
# (._prepare_render / ._export_prepare_page) so a later style() cannot
# resurrect Cartesian axes around a polar panel.
#' Apply the polar-coordinate axis budget to a ggplot.
#' @noRd
#' @keywords internal
._polar_axes_budget <- function(gg) {
  coord <- gg$coordinates
  if (is.null(coord) || !(inherits(coord, "CoordPolar") || inherits(coord, "CoordRadial"))) {
    return(gg)
  }
  # ggplot2's polar background render takes a collapsed, small-panel layout
  # branch when the panel background rect has an NA/white border (and can be
  # skipped entirely when the resolved element is blank, as some platforms
  # resolve).  Override the panel background unconditionally with a white
  # fill and an invisible (linewidth 0) black border so the polar panel
  # always keeps the full-extent layout.
  bg <- tryCatch(ggplot2::calc_element("panel.background", gg$theme), error = function(e) NULL)
  bg_fill <- if (inherits(bg, "element_rect") && !is.null(bg$fill)) bg$fill else "white"
  gg <- gg + ggplot2::theme(
    panel.background = ggplot2::element_rect(
      fill = bg_fill,
      colour = "black",
      linewidth = 0
    )
  )
  # All polar modes blank every axis element: reference galleries
  # (r-graph-gallery / G2 / Vega-Lite) draw pies, donuts, roses and
  # circular histograms without Cartesian furniture, and the default
  # target of project_polar() is exactly those forms.  Radial bar charts
  # that want the radius ticks back can re-enable them with style().
  ._gg_blank_axes(gg, ticks_length = TRUE)
}

# Polar unframing: bar-family layers get a white hairline border by default
# (mark_bar / mark_histogram).  Around a circle this draws the "dashed white
# ring" at the pie rim (segment borders meeting the rim).  Polar layouts drop
# the stroke so sector separation comes from the palette, matching
# r-graph-gallery / G2 / Vega-Lite pies.
#' Remove white hairline borders from bar-family layers in polar coords.
#' @noRd
#' @keywords internal
._polar_unframe <- function(gg) {
  coord <- gg$coordinates
  if (is.null(coord) || !(inherits(coord, "CoordPolar") || inherits(coord, "CoordRadial"))) {
    return(gg)
  }
  for (i in seq_along(gg$layers)) {
    lay <- gg$layers[[i]]
    bc <- lay$aes_params$colour %||% lay$geom$default_aes$colour %||% NA
    if (is.character(bc) && length(bc) == 1 && identical(unname(bc), "white") &&
          !is.null(lay$aes_params$linewidth)) {
      lay$aes_params$linewidth <- 0
    }
  }
  gg
}
