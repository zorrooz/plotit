#' Graphics composition -- multi-panel layout assembly
#'
#' @include class.R label.R style.R output.R
#' @name compose
#' @keywords internal
#' @examples NULL
NULL

# ---- Internal helpers -----------------------------------------------------

# Pull the raw ggplot out of any plotit-family object.  plotit_composite
# inherits from plotit, so one S7 check covers both.
#' Extract the raw ggplot from a plotit or plotit_composite object.
#' @noRd
#' @keywords internal
._extract_gg <- function(x) {
  if (S7::S7_inherits(x, plotit_class)) {
    return(x@gg)
  }
  ._abort_hint(
    "Every element must be a {.cls plotit} or {.cls plotit_composite} object.",
    "Build each panel through the {.code plotit() |> mark_*()} pipeline before composing."
  )
}

# plotit() bakes absolute panel dimensions into each sub-plot's ggplot theme
# (panel.widths / panel.heights, WYSIWYG sizing).  Inside a composite these
# would force fixed physical sizes that overflow patchwork cells.  Strip them
# here so the composite controls layout.
#' Strip baked panel sizing from a plot before composite assembly.
#' Called to prevent cropping inside patchwork layouts.
#' @noRd
#' @keywords internal
._reset_sizing <- function(gg) {
  gg <- ._strip_panel_size(gg)
  if (!inherits(gg, "patchwork")) {
    return(gg)
  }
  gg + patchwork::plot_layout(widths = NULL, heights = NULL)
}

# Sync lazy labels on a sub-plot before extraction so label_* settings
# survive composition (AGENTS.md <U+00A7>1.2).  Composites are skipped: their
# labels live in annotations, not meta@labels.
#' Sync lazy labels on a sub-plot before composition.
#' @noRd
#' @keywords internal
._sync_subplot <- function(p) {
  if (S7::S7_inherits(p, plotit_class) && !S7::S7_inherits(p, plotit_composite)) {
    ._sync_labels(p)
  } else {
    p
  }
}

# Full subplot preparation: sync lazy labels, extract the raw ggplot, and
# strip baked panel sizing.  One choke point for every compose_* entry.
#' Prepare a sub-plot's raw ggplot for composite assembly.
#' @noRd
#' @keywords internal
._prep_subplot_gg <- function(p) {
  ._reset_sizing(._extract_gg(._sync_subplot(p)))
}

# Fresh annotation skeleton shared by all compose_* constructors.
#' Create an empty composite annotation list.
#' @noRd
#' @keywords internal
._new_annotations <- function(tag_levels = NULL) {
  list(
    title      = NULL,
    subtitle   = NULL,
    caption    = NULL,
    tag_levels = tag_levels
  )
}

# Shared export plumbing: one filename validation + one ggsave invocation
# with the locked-argument policy (inches, white background) in a single
# place.  `...` forwards to ggsave after the locked arguments, so users can
# still pass device-specific options -- but `bg`/`units` are plotit policy.
#' Validate an export filename and save via ggsave with package policy.
#' @noRd
#' @keywords internal
._ggsave_inches <- function(filename, plot, width, height, dpi, device, ...) {
  if (is.null(filename) || identical(filename, "")) {
    ._abort_hint(
      "{.arg filename} must be a non-empty file path.",
      "Pass an output path such as {.code 'figure.png'}."
    )
  }
  ggplot2::ggsave(
    filename = filename,
    plot = plot,
    width = width,
    height = height,
    dpi = dpi,
    device = device,
    units = "in",
    bg = "white",
    ...
  )
}

# Default composite canvas size.
#
# patchworkGrob() contains `1null` panel units that only resolve inside a
# device viewport, so measuring it standalone yields garbage (a 2-plot grid
# measures ~0.7 x 1.2 in).  Instead, compute the canvas from the sub-plot
# panel sizes (meta) plus a fixed chrome allowance -- the same numbers the
# single-plot WYSIWYG path uses.
# Declared panel size (inches) of one sub-plot, falling back to the default
# canvas when the plot carries no explicit width/height.
#' @noRd
#' @keywords internal
._subplot_panel_size <- function(p) {
  def_size <- ._default_panel_size()
  sized <- S7::S7_inherits(p, plotit_class) &&
    !S7::S7_inherits(p, plotit_composite) &&
    !is.null(p@meta@width) && !is.null(p@meta@height)
  if (sized) {
    list(
      w = ._unit_to_inches(p@meta@width, p@meta@unit),
      h = ._unit_to_inches(p@meta@height, p@meta@unit)
    )
  } else {
    list(w = def_size$width, h = def_size$height)
  }
}

# Resolve the effective (ncol, nrow) of a grid layout for n plots, honouring
# whichever of ncol/nrow the caller fixed.
#' @noRd
#' @keywords internal
._grid_dims <- function(layout, n) {
  ncol <- layout$ncol %||% if (!is.null(layout$nrow)) ceiling(n / layout$nrow) else 1L
  nrow <- layout$nrow %||% ceiling(n / ncol)
  list(ncol = ncol, nrow = nrow)
}

# Relative column widths / row heights that preserve each sub-plot's own
# aspect ratio as far as a shared grid allows: a column is as wide as its
# widest cell, a row as tall as its tallest cell.  For the common single
# column (ncol = 1) or single row (nrow = 1) stacks this keeps every panel
# at its declared size; for a mixed grid it is the best a shared-gridline
# layout can do.  Returns inch vectors ready for patchwork.
#' @noRd
#' @keywords internal
._grid_units <- function(sizes, ncol, nrow, byrow = TRUE) {
  n <- length(sizes)
  w <- vapply(sizes, function(s) s$w, numeric(1))
  h <- vapply(sizes, function(s) s$h, numeric(1))
  col_of <- if (byrow) ((seq_len(n) - 1) %% ncol) + 1 else (((seq_len(n) - 1) %/% max(nrow, 1)) + 1)
  row_of <- if (byrow) ((seq_len(n) - 1) %/% ncol) + 1 else ((seq_len(n) - 1) %% nrow) + 1
  widths <- vapply(seq_len(ncol), function(j) max(w[col_of == j & seq_len(n) <= n], 0), numeric(1))
  heights <- vapply(seq_len(nrow), function(i) max(h[row_of == i & seq_len(n) <= n], 0), numeric(1))
  list(widths = widths, heights = heights)
}

#' Default width/height (inches) for a composite without explicit size.
#' @noRd
#' @keywords internal
._composite_default_size <- function(cmp) {
  sizes <- lapply(cmp@plots, ._subplot_panel_size)
  # Chrome allowance: axes / labels / legend / annotation around one panel
  # (mirrors the single-plot 5 x 3.5 panel -> ~6.6 in footprint budget).
  allowance_w <- 1.6
  allowance_h <- 1.6
  n <- length(sizes)
  lt <- cmp@layout$type %||% "grid"
  if (lt == "marginal") {
    widths <- cmp@layout$widths %||% c(4, 1)
    heights <- cmp@layout$heights %||% c(1, 4)
    main <- sizes[[1]]
    list(
      width  = main$w * sum(widths) / widths[1] + allowance_w,
      height = main$h * sum(heights) / heights[2] + allowance_h
    )
  } else if (lt == "inset") {
    base <- sizes[[1]]
    list(width = base$w + allowance_w, height = base$h + allowance_h)
  } else {
    grid <- ._grid_dims(cmp@layout, n)
    units <- ._grid_units(sizes, grid$ncol, grid$nrow, cmp@layout$byrow %||% TRUE)
    list(
      width  = sum(units$widths) + allowance_w,
      height = sum(units$heights) + allowance_h
    )
  }
}

# Assemble a list of plots into a patchwork via wrap_plots()
#' Assemble a list of plots into a patchwork via wrap_plots().
#' @noRd
#' @keywords internal
# Parse a compose_grid `design` into a patchwork design specification:
# a text layout string passes through; a list of numeric vectors
# c(top, left, bottom, right) becomes a combination of area() objects.
#' Parse compose_grid design into a patchwork design spec.
#' @noRd
#' @keywords internal
._parse_design <- function(design) {
  if (is.character(design)) {
    return(design)
  }
  if (!is.list(design)) {
    ._abort_hint(
      "{.arg design} must be a layout string or a list of area vectors.",
      "Strings use one row per line, e.g. {.code \"122\\n133\"}; lists use c(top, left, bottom, right) vectors."
    )
  }
  for (a in design) {
    if (!is.numeric(a) || length(a) != 4) {
      ._abort_hint(
        "Each {.arg design} entry must be a numeric vector c(top, left, bottom, right).",
        "Example: {.code design = list(c(1, 1, 2, 2), c(1, 3, 2, 3))}."
      )
    }
  }
  # patchwork accepts design as a combination of area() objects (a plain
  # numeric matrix is not a valid design spec).
  do.call(c, lapply(design, function(a) {
    patchwork::area(a[1], a[2], a[3], a[4])
  }))
}

._assemble_plots <- function(plots, layout) {
  plots <- lapply(plots, ._sync_subplot)
  ggs <- lapply(plots, ._extract_gg)
  ggs <- lapply(ggs, ._reset_sizing)

  # When the caller did not pin column/row proportions, derive them from each
  # sub-plot's own declared panel size so the composite keeps original
  # ratios instead of forcing every cell to one aspect.
  widths <- layout$widths
  heights <- layout$heights
  if (is.null(widths) || is.null(heights)) {
    lt <- layout$type %||% "grid"
    if (lt == "grid" || is.null(layout$type)) {
      sizes <- lapply(plots, ._subplot_panel_size)
      grid <- ._grid_dims(layout, length(sizes))
      units <- ._grid_units(sizes, grid$ncol, grid$nrow, layout$byrow %||% TRUE)
      if (is.null(widths)) widths <- grid::unit(units$widths, "in")
      if (is.null(heights)) heights <- grid::unit(units$heights, "in")
    }
  }

  design <- layout$design
  if (is.null(design)) {
    args <- c(ggs, list(
      ncol    = layout$ncol,
      nrow    = layout$nrow,
      byrow   = layout$byrow %||% TRUE,
      widths  = widths,
      heights = heights,
      guides  = layout$guides
    ))
    gg <- do.call(patchwork::wrap_plots, args)
  } else {
    # Design-driven layout (D-03): the area spec replaces ncol/nrow/byrow.
    args <- c(ggs, list(
      design  = ._parse_design(design),
      widths  = widths,
      heights = heights,
      guides  = layout$guides
    ))
    gg <- do.call(patchwork::wrap_plots, args)
  }

  # Composite-level plot_layout: axes / axis-title sharing live here
  layout_args <- list()
  if (!is.null(layout$axes) && layout$axes != "keep") {
    layout_args$axes <- layout$axes
  }
  if (!is.null(layout$axis_titles) && layout$axis_titles != "keep") {
    layout_args$axis_titles <- layout$axis_titles
  }
  if (length(layout_args) > 0) {
    gg <- gg + do.call(patchwork::plot_layout, layout_args)
  }

  gg
}

# Lazily apply stored annotations to the raw assembled gg.
# Called at print() / export() time so that label_* methods can be
# called in any order without worrying about plot_annotation overwrites.
# The annotation theme comes from the shared style tokens so composite
# titles/subtitles/captions match the single-plot type hierarchy.
#' Lazily apply stored annotations (title, subtitle, caption, tags) to composite gg.
#' @noRd
#' @keywords internal
._apply_annotations <- function(cmp) {
  gg <- cmp@gg
  ann <- cmp@annotations
  has <- !is.null(ann$title) || !is.null(ann$subtitle) ||
    !is.null(ann$caption) || !is.null(ann$tag_levels)
  if (!has) {
    return(gg)
  }
  gg + patchwork::plot_annotation(
    title      = ann$title,
    subtitle   = ann$subtitle,
    caption    = ann$caption,
    tag_levels = ann$tag_levels,
    theme      = ._theme_default()
  )
}

# ---- compose_grid ---------------------------------------------------------

#' Assemble multiple plots into a grid layout
#'
#' `compose_grid()` arranges `plotit` or `plotit_composite` objects into a
#' grid via `patchwork::wrap_plots()`.  The default vertical stack (`ncol =
#' 1` when neither `ncol` nor `nrow` is given) is the most common layout for
#' report figures.  Pipe the result to `label_title()` / `style()` /
#' `export()` just as with a single `plotit`.
#'
#' @param ... `plotit` or `plotit_composite` objects to arrange.
#' @param ncol Number of columns. `NULL` (default) = auto; if both `ncol`
#'   and `nrow` are `NULL` defaults to 1 (vertical stack).
#' @param nrow Number of rows. `NULL` (default) = inferred from `ncol` and
#'   the number of plots.
#' @param byrow Fill direction: `TRUE` (default) = row-major.
#' @param widths Relative column widths, e.g. `c(1, 2)`.
#' @param heights Relative row heights.
#' @param guides `"collect"` (default) to merge identical legends into one,
#'   `"keep"` to keep per-panel legends, `NULL` for patchwork auto-detect.
#' @param axes `"collect"` to share all axes, `"collect_x"` or `"collect_y"`
#'   for a single direction, `"keep"` (default) to keep axes independent.
#' @param axis_titles Axis-title sharing: defaults to the `axes` value;
#'   `"collect"` merges repeated axis titles onto one panel,
#'   `"collect_x"`/`"collect_y"` per direction, `"keep"` independent.
#' @param design Layout specification replacing `ncol`/`nrow`/`byrow`:
#'   either a text layout (one row per line, digits = plot order,
#'   `#` = empty cell, e.g. the two-row layout "122" / "133") or a
#'   list of numeric area
#'   vectors `c(top, left, bottom, right)`.  When given, it wins over
#'   `ncol`/`nrow`/`byrow` (a warning flags the overlap).
#' @param tag_levels Sub-figure tag scheme: `"A"` for uppercase letters,
#'   `"a"` for lowercase, `"1"` for numbers, `"i"` for roman numerals, or a
#'   custom character vector (e.g. `c("(a)", "(b)")`).  `NULL` = no tags.
#'
#' @return A `plotit_composite` object.  Pipe it to `label_title()`,
#'   `style()`, or `export()`.
#' @examples
#' p1 <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
#' p2 <- plotit(iris, encode(x = Species, y = Sepal.Length)) |> mark_boxplot()
#' compose_grid(p1, p2)
#' @export
compose_grid <- function(
  ...,
  ncol = NULL,
  nrow = NULL,
  byrow = TRUE,
  widths = NULL,
  heights = NULL,
  guides = "collect",
  axes = "keep",
  axis_titles = axes,
  design = NULL,
  tag_levels = NULL
) {
  plots <- list(...)
  if (length(plots) == 0) {
    ._abort_hint(
      "At least one {.cls plotit} or {.cls plotit_composite} object is required.",
      "Compose individual plots first, e.g. {.code compose_grid(p1, p2)}."
    )
  }

  if (!is.null(design)) {
    if (!is.null(ncol) || !is.null(nrow) || !byrow) {
      cli::cli_warn(c(
        "{.arg design} takes precedence; {.arg ncol}/{.arg nrow}/{.arg byrow} are ignored.",
        "i" = "Drop the grid arguments or drop {.arg design} to restore them."
      ))
    }
    # The area spec fully replaces the grid: keep ncol/nrow NULL so the
    # stored layout reflects the design-driven assembly.
    ncol <- NULL
    nrow <- NULL
    byrow <- TRUE
  } else if (is.null(ncol) && is.null(nrow)) {
    ncol <- 1
  }

  layout <- list(
    type        = "grid",
    ncol        = ncol,
    nrow        = nrow,
    byrow       = byrow,
    widths      = widths,
    heights     = heights,
    guides      = guides,
    axes        = axes,
    axis_titles = axis_titles,
    design      = design
  )

  annotations <- ._new_annotations(tag_levels)

  gg <- ._assemble_plots(plots, layout)

  plotit_composite(
    gg          = gg,
    plots       = plots,
    layout      = layout,
    annotations = annotations
  )
}

# ---- compose_inset --------------------------------------------------------

#' Overlay an inset plot on a base plot
#'
#' Places a smaller plot (`inset`) as a floating panel on top of a base
#' `plotit` via `patchwork::inset_element()`.  Position is specified in
#' normalised parent coordinates (0-1 relative to the panel or plot area).
#' The returned composite accepts `label_title()` / `style()` / `export()`
#' in the usual way.
#'
#' @param base A `plotit` object serving as the background.
#' @param inset A `plotit` or `plotit_composite` object to overlay.
#' @param left,right,bottom,top Inset edges in npc (0-1).
#' @param align_to Coordinate reference: `"panel"` (default) or `"plot"`.
#' @param on_top Logical; `TRUE` (default) = inset rendered above base.
#' @param ... Passed through to `patchwork::inset_element()`.
#'
#' @return A `plotit_composite` object.
#' @examples
#' p1 <- plotit(mtcars, encode(x = wt, y = mpg)) |> mark_point()
#' p2 <- plotit(mtcars, encode(x = factor(cyl))) |> mark_bar()
#' compose_inset(p1, p2, left = 0.6, bottom = 0.6, right = 0.95, top = 0.95)
#' @export
compose_inset <- function(
  base,
  inset,
  left = 0,
  bottom = 0,
  right = 1,
  top = 1,
  align_to = "panel",
  on_top = TRUE,
  ...
) {
  if (!S7::S7_inherits(base, plotit_class)) {
    ._abort_hint(
      "{.arg base} must be a {.cls plotit} object.",
      "Build it through the {.code plotit() |> mark_*()} pipeline first."
    )
  }

  base_gg <- ._prep_subplot_gg(base)
  inset_gg <- ._prep_subplot_gg(inset)
  # The inset is self-contained: its legend must not float outside the inset
  # box onto the base canvas (T2.3).  Park it inside the inset panel; a user
  # style() on the inset plot overrides this in the usual way.
  inset_gg <- inset_gg + ggplot2::theme(
    legend.position = "inside",
    legend.position.inside = c(0.98, 0.98),
    legend.justification = c(1, 1),
    legend.background = ggplot2::element_rect(fill = "white", colour = NA)
  )
  gg <- base_gg + patchwork::inset_element(
    inset_gg,
    left     = left,
    bottom   = bottom,
    right    = right,
    top      = top,
    align_to = align_to,
    on_top   = on_top,
    ...
  )

  layout <- list(
    type     = "inset",
    left     = left,
    bottom   = bottom,
    right    = right,
    top      = top,
    align_to = align_to,
    on_top   = on_top
  )

  plotit_composite(
    gg = gg,
    plots = list(base, inset),
    layout = layout,
    annotations = ._new_annotations()
  )
}

# ---- compose_marginal -----------------------------------------------------

#' Scatter plot with marginal distributions
#'
#' Arranges a main scatter plot with marginal histogram or density plots on
#' the top (x-axis distribution) and right (y-axis distribution).  The axes
#' are shared so that the marginal bins align exactly with the scatter axes.
#'
#' @param main A `plotit` scatter plot (must have both x and y mapped).
#' @param top A `plotit` histogram or density plot for the x variable.
#'   Typically built from the same data and x mapping as `main`, with the
#'   same `fill`/`colour` aesthetic to match.
#' @param right A `plotit` histogram or density plot for the y variable.
#'   Same conventions as `top`.  Call `project_cartesian(flip = TRUE)` on
#'   this plot before passing it so the y-axis aligns with the scatter.
#' @param widths Relative column widths for the main and right-marginal
#'   panels (applies when `right` is supplied).
#'   Default `c(4, 1)` = right marginal is 1/5 of total width.
#' @param heights Relative row heights for the top-marginal and main
#'   panels (applies when `top` is supplied).
#'   Default `c(1, 4)` = top marginal is 1/5 of total height.
#' @param guides `"collect"` (default) to merge legends across all panels,
#'   `"keep"` to keep them separate, `NULL` for patchwork auto-detect.
#' @param align Alignment reference: `"panel"` (default, strips align to
#'   the base panel area).  `"plot"` requests full-area alignment; grid
#'   members always align on panel areas, so it currently falls back to
#'   `"panel"` (documented approximation).
#'
#' @return A `plotit_composite` object.  Pipe to `label_title()`,
#'   `style()`, `export()` as usual.
#' @examples
#' main <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |> mark_point()
#' top <- plotit(iris, encode(x = Sepal.Width, fill = Species)) |> mark_histogram(bins = 15, alpha = 0.5)
#' right <- plotit(iris, encode(x = Sepal.Length, fill = Species)) |>
#'   mark_histogram(bins = 15, alpha = 0.5) |>
#'   project_cartesian(flip = TRUE)
#' compose_marginal(main, top, right)
#' @export

compose_marginal <- function(
  main,
  top = NULL,
  right = NULL,
  widths = c(4, 1),
  heights = c(1, 4),
  guides = "collect",
  align = "panel"
) {
  if (!S7::S7_inherits(main, plotit_class)) {
    ._abort_hint(
      "{.arg main} must be a {.cls plotit} object.",
      "Build it through the {.code plotit() |> mark_*()} pipeline first."
    )
  }
  main_gg <- ._prep_subplot_gg(main)
  if (!align %in% c("panel", "plot")) {
    ._abort_arg_enum("align", c("panel", "plot"), got = align)
  }

  strips <- list(top = top, right = right)
  strips <- strips[!vapply(strips, is.null, logical(1))]
  if (length(strips) == 0) {
    ._abort_hint(
      "Attach at least one marginal via {.arg top}/{.arg right}.",
      "Every marginal must be a {.cls plotit} or {.cls plotit_composite} object."
    )
  }
  for (s in names(strips)) {
    if (!S7::S7_inherits(strips[[s]], plotit_class)) {
      ._abort_hint(
        sprintf(
          "The {.arg %s} marginal must be a {.cls plotit} or {.cls plotit_composite} object.",
          s
        ),
        "Build it through the {.code plotit() |> mark_*()} pipeline first."
      )
    }
  }
  strip_ggs <- lapply(strips, ._prep_subplot_gg)

  # Shared axes: hide redundant labels / ticks on marginal panels
  # BEFORE assembly (robust -- no patchwork-internals dependency)
  if (!is.null(strip_ggs$top)) {
    strip_ggs$top <- strip_ggs$top + ggplot2::theme(
      axis.text.x  = ggplot2::element_blank(),
      axis.title.x = ggplot2::element_blank(),
      axis.ticks.x = ggplot2::element_blank()
    )
  }
  if (!is.null(strip_ggs$right)) {
    strip_ggs$right <- strip_ggs$right + ggplot2::theme(
      axis.text.y  = ggplot2::element_blank(),
      axis.title.y = ggplot2::element_blank(),
      axis.ticks.y = ggplot2::element_blank()
    )
  }

  # Flat 2x2 layout via the shared annotation-strip engine (D-04).
  # Defaults are side-relative: heights = c(top, main) applies when `top`
  # is present; widths = c(main, right) applies when `right` is present.
  gg <- ._assemble_annot(main_gg, strip_ggs,
    widths  = if (!is.null(strip_ggs$right)) widths else NULL,
    heights = if (!is.null(strip_ggs$top)) heights else NULL,
    guides  = guides
  )

  plotit_composite(
    gg = gg,
    plots = c(list(main), strips),
    layout = list(
      type    = "marginal",
      widths  = widths,
      heights = heights,
      align   = align
    ),
    annotations = ._new_annotations()
  )
}

# ---- shared annotation-strip assembly engine (D-04) -----------------------
# One engine behind compose_annot and compose_marginal (AGENTS.md
# 3.3.4a dual-track rule): builds a patchwork whose design places the
# base plot plus up to four annotation strips (top/bottom/left/right).
# `widths`/`heights` are FULL-GRID vectors over (strips + base) columns/
# rows in relative units; `gap` inserts empty spacer rows/cols of
# unit(gap, "in") between the strips and the base.
#' Assemble a base plot with annotation strips (shared engine).
#' @noRd
#' @keywords internal
._assemble_annot <- function(base_gg, strips, widths = NULL, heights = NULL,
                             gap = 0, guides = "collect") {
  has <- function(x) !is.null(strips[[x]])
  sides <- intersect(c("top", "bottom", "left", "right"), names(strips))
  nrow_m <- 1L + has("top") + has("bottom")
  ncol_m <- 1L + has("left") + has("right")
  base_row <- 1L + has("top")
  base_col <- 1L + has("left")

  # Design matrix with optional gap spacer rows/cols.  Numbering: base = 1,
  # strips follow the fixed top/bottom/left/right order.
  row_slots <- character()
  if (has("top")) row_slots <- c(row_slots, "top")
  if (has("top") && gap > 0) row_slots <- c(row_slots, "gapv")
  row_slots <- c(row_slots, "base")
  if (has("bottom") && gap > 0) row_slots <- c(row_slots, "gapv")
  if (has("bottom")) row_slots <- c(row_slots, "bottom")
  col_slots <- character()
  if (has("left")) col_slots <- c(col_slots, "left")
  if (has("left") && gap > 0) col_slots <- c(col_slots, "gaph")
  col_slots <- c(col_slots, "base")
  if (has("right") && gap > 0) col_slots <- c(col_slots, "gaph")
  if (has("right")) col_slots <- c(col_slots, "right")

  # Design as patchwork area() objects.  The base spans its whole grid
  # row AND column so strips align to the base panel by construction;
  # each strip occupies its single slot cell.
  base_area <- patchwork::area(
    base_row, base_col,
    match("base", row_slots), match("base", col_slots)
  )
  areas <- list(base_area)
  for (s in sides) {
    ri <- match(if (s == "top" || s == "bottom") s else "base", row_slots)
    ci <- match(if (s == "left" || s == "right") s else "base", col_slots)
    areas <- c(areas, list(patchwork::area(ri, ci, ri, ci)))
  }

  # Full-grid size vectors for the default layout.  The base row/column is
  # 1 relative unit; strip rows/cols default to 0.9 in; spacer rows/cols use
  # absolute gap units.  Explicit user sizes bypass this helper entirely.
  gap_u <- if (gap > 0) grid::unit(gap, "in") else NULL
  mk_sizes <- function(slots) {
    out <- vector("list", length(slots))
    for (i in seq_along(slots)) {
      sl <- slots[i]
      out[[i]] <- if (sl == "base") {
        1
      } else if (sl == "gapv" || sl == "gaph") {
        gap_u
      } else {
        grid::unit(0.9, "in")
      }
    }
    out
  }
  if (is.null(heights)) {
    heights <- mk_sizes(row_slots)
  }
  if (is.null(widths)) {
    widths <- mk_sizes(col_slots)
  }
  # patchwork accepts numeric vectors or grid::unit objects -- normalize the
  # mixed relative/absolute lists into a single unit vector (numerics become
  # "null" relative units, unit elements pass through).
  as_unit_vec <- function(xs) {
    if (inherits(xs, "unit") || !is.list(xs)) {
      return(xs)
    }
    do.call(grid::unit.c, lapply(xs, function(x) {
      if (inherits(x, "unit")) x else grid::unit(as.numeric(x), "null")
    }))
  }
  widths <- as_unit_vec(widths)
  heights <- as_unit_vec(heights)
  # Explicit sizes are FULL-GRID vectors (strips + spacers + base): length
  # must match the assembled grid (or recycle from 1) -- fail loudly otherwise.
  # Messages are sprintf-preformatted: ._abort_hint's .envir carries no locals.
  if (!is.null(heights) && length(heights) > 1 && length(heights) != length(row_slots)) {
    ._abort_hint(
      sprintf(
        "{.arg heights} has length %d but the assembled grid has %d rows.",
        length(heights), length(row_slots)
      ),
      "Explicit heights are full-grid vectors over the strip rows, spacer rows and the base row."
    )
  }
  if (!is.null(widths) && length(widths) > 1 && length(widths) != length(col_slots)) {
    ._abort_hint(
      sprintf(
        "{.arg widths} has length %d but the assembled grid has %d columns.",
        length(widths), length(col_slots)
      ),
      "Explicit widths are full-grid vectors over the strip columns, spacer columns and the base column."
    )
  }

  order <- c("base", sides)
  ggs <- c(list(base_gg), strips[sides])
  gg <- do.call(patchwork::wrap_plots, c(ggs, list(design = do.call(c, areas))))
  gg + patchwork::plot_layout(
    widths  = widths,
    heights = heights,
    guides  = guides
  )
}

# ---- compose_annot --------------------------------------------------------

#' Attach annotation strips to a base plot
#'
#' `compose_annot()` glues one to four `plotit` strips (dendrograms,
#' annotation bars, marginal densities) onto the matching sides of a base
#' plot.  Strips share the base panel span: patchwork aligns the panel
#' areas of plots stacked in the same design row/column, so tree tips and
#' annotation cells line up with the base heatmap rows/columns by
#' construction.
#'
#' This is the same assembly engine behind [compose_marginal()]
#' (`marginal` = a `top` + `right` special case with axis-hiding
#' conventions).  The result can be nested into [compose_grid()].
#'
#' @param base A `plotit` or `plotit_composite` object.
#' @param top,bottom,left,right Optional `plotit`/`plotit_composite`
#'   strips attached to the matching side.
#' @param heights,widths Strip sizes for the vertical (top/bottom) and
#'   horizontal (left/right) sides: `NULL` (default) = 0.9 inch per strip;
#'   `grid::unit()` = absolute size; numeric = ratio relative to the base
#'   row/column (same three-state contract as [compose_grid()]).
#' @param gap Space between the strips and the base plot in inches
#'   (default 0; realised as empty spacer rows/columns).
#' @param guides `"collect"` (default) to merge legends, `"keep"` to keep
#'   per-panel legends.
#' @param align Alignment reference. `"panel"` (default) = strips align to
#'   the base panel area.  `"plot"` requests full-area alignment; grid
#'   members always align on panel areas, so it currently falls back to
#'   `"panel"` (documented approximation).
#' @param on_top Reserved for overlap semantics (use [compose_inset()]);
#'   `TRUE` warns and renders the strips beside the base.
#'
#' @return A `plotit_composite` object.
#' @examples
#' mat <- matrix(c(9, 1, 8, 2, 1, 9, 2, 8, 5, 3, 7, 4),
#'   nrow = 4,
#'   dimnames = list(paste0("g", 1:4), paste0("s", 1:3))
#' )
#' h <- stats::hclust(stats::dist(mat))
#' hm <- plotit(mat, encode()) |> mark_heatmap(cluster = h)
#' tree <- as_graph(h) |>
#'   plotit() |>
#'   layout_dendrogram(direction = "up") |>
#'   mark_rule(data = ~edges)
#' hm |> compose_annot(top = tree)
#' @export
compose_annot <- function(
  base,
  top = NULL,
  bottom = NULL,
  left = NULL,
  right = NULL,
  heights = NULL,
  widths = NULL,
  gap = 0,
  guides = "collect",
  align = "panel",
  on_top = FALSE
) {
  if (!S7::S7_inherits(base, plotit_class)) {
    ._abort_hint(
      "{.arg base} must be a {.cls plotit} object.",
      "Build it through the {.code plotit() |> mark_*()} pipeline first."
    )
  }
  if (isTRUE(on_top)) {
    cli::cli_warn(c(
      "{.arg on_top} is reserved; strips render beside the base.",
      "i" = "Use {.fn compose_inset} for overlapping annotation."
    ))
  }
  if (!align %in% c("panel", "plot")) {
    ._abort_arg_enum("align", c("panel", "plot"), got = align)
  }
  strips <- list(top = top, bottom = bottom, left = left, right = right)
  strips <- strips[!vapply(strips, is.null, logical(1))]
  if (length(strips) == 0) {
    ._abort_hint(
      "Attach at least one strip via {.arg top}/{.arg bottom}/{.arg left}/{.arg right}.",
      "Every strip must be a {.cls plotit} or {.cls plotit_composite} object."
    )
  }
  for (s in names(strips)) {
    if (!S7::S7_inherits(strips[[s]], plotit_class)) {
      ._abort_hint(
        sprintf(
          "The {.arg %s} strip must be a {.cls plotit} or {.cls plotit_composite} object.",
          s
        ),
        "Build it through the {.code plotit() |> mark_*()} pipeline first."
      )
    }
  }

  base_gg <- ._prep_subplot_gg(base)
  strip_ggs <- lapply(strips, ._prep_subplot_gg)
  gg <- ._assemble_annot(base_gg, strip_ggs,
    widths = widths, heights = heights, gap = gap, guides = guides
  )

  plotit_composite(
    gg = gg,
    plots = c(list(base), strips),
    layout = list(
      type   = "annot",
      sides  = names(strips),
      gap    = gap,
      align  = align
    ),
    annotations = ._new_annotations()
  )
}

# ---- print method ---------------------------------------------------------

#' @export
S7::method(print, plotit_composite) <- function(x, ...) {
  gg <- ._apply_annotations(x)

  # Device management (consistent with plotit_class print).  Default size
  # comes from the sub-plot panel metas -- patchworkGrob measurement is
  # unreliable outside a viewport (null units do not resolve).
  dev_opt <- getOption("plotit.device", "default")
  if (interactive() && !is.null(dev_opt)) {
    size_in <- ._composite_default_size(x)
    ._open_sized_device(size_in, dev_opt)
  }
  print(gg)
  invisible(x)
}

# ---- export method --------------------------------------------------------

#' @export
S7::method(export, plotit_composite) <- function(
  plot,
  filename,
  width = NULL,
  height = NULL,
  dpi = 300,
  device = NULL,
  ...
) {
  gg <- ._apply_annotations(plot)

  # Resolve size_unit from first sub-plot's meta, or global option.
  # Only plain sub-plots carry a meaningful meta; nested composites hold a
  # synthetic one and are skipped.
  meta_unit <- NULL
  for (p in plot@plots) {
    is_plain <- S7::S7_inherits(p, plotit_class) && !S7::S7_inherits(p, plotit_composite)
    if (is_plain) {
      meta_unit <- p@meta@unit
      break
    }
  }
  meta_unit <- meta_unit %||% getOption("plotit.default_unit", "in")

  if (!is.null(width)) width <- ._unit_to_inches(width, meta_unit)
  if (!is.null(height)) height <- ._unit_to_inches(height, meta_unit)

  if (is.null(width) || is.null(height)) {
    # Default canvas from sub-plot panel metas; patchworkGrob measurement
    # is unreliable outside a viewport (null units do not resolve).
    size_in <- ._composite_default_size(plot)
    if (is.null(width)) width <- size_in$width
    if (is.null(height)) height <- size_in$height
  }

  ._ggsave_inches(filename, gg, width, height, dpi, device, ...)
  invisible(plot)
}

# ---- composite label_* methods ---------------------------------------------
# Shared three-parameter protocol setter for composite-level annotations
# (same text/hide/reset contract as single plots).  Composites store text in
# @annotations and render lazily via plot_annotation(), so hide/reset just
# drop the stored entry.
#' Set or clear a composite-level annotation field.
#' @noRd
#' @keywords internal
._set_composite_annotation <- function(plot, field, text, hide, reset, fun_name) {
  ._check_text_reset(text, reset, fun_name)
  if (hide || isTRUE(reset)) {
    plot@annotations[[field]] <- NULL
  } else if (!is.null(text)) {
    plot@annotations[[field]] <- text
  }
  plot
}

# Three explicit thin methods (shared protocol lives in the setter above).
# A registration loop was tried here and reverted: under package load the
# S7 method closures did not capture their per-iteration bindings reliably,
# silently routing every annotation into the last field.
#
#' @export
S7::method(label_title, plotit_composite) <- function(
  plot,
  text = NULL,
  hide = FALSE,
  reset = FALSE,
  ...
) {
  ._set_composite_annotation(plot, "title", text, hide, reset, "label_title")
}

#' @export
S7::method(label_subtitle, plotit_composite) <- function(
  plot,
  text = NULL,
  hide = FALSE,
  reset = FALSE,
  ...
) {
  ._set_composite_annotation(plot, "subtitle", text, hide, reset, "label_subtitle")
}

#' @export
S7::method(label_caption, plotit_composite) <- function(
  plot,
  text = NULL,
  hide = FALSE,
  reset = FALSE,
  ...
) {
  ._set_composite_annotation(plot, "caption", text, hide, reset, "label_caption")
}

# ---- style method (composite) ---------------------------------------------

#' @export
S7::method(style, plotit_composite) <- function(
  plot,
  ...,
  base_size = NULL,
  base_family = NULL,
  base_theme = NULL
) {
  thm <- base_theme %||% ._theme_default(base_size, base_family)
  # patchwork: `+` adds to the last sub-plot only; `&` applies to every
  # panel, matching the single-plot style() semantics.
  if (inherits(plot@gg, "patchwork")) {
    plot@gg <- plot@gg & thm & ggplot2::theme(...)
  } else {
    plot@gg <- plot@gg + thm + ggplot2::theme(...)
  }
  plot
}
