#' Graphics composition -- multi-panel layout assembly
#'
#' @include class.R label.R style.R output.R
#' @name compose
#' @keywords internal
NULL

# ---- Internal helpers -----------------------------------------------------

# Pull the raw ggplot out of any plotit-family object
#' Extract the raw ggplot from a plotit or plotit_composite object.
#' @noRd
#' @keywords internal
._extract_gg <- function(x) {
  if (S7::S7_inherits(x, plotit_composite)) {
    return(x@gg)
  }
  if (S7::S7_inherits(x, plotit_class)) {
    return(x@gg)
  }
  cli::cli_abort(
    "Each element must be a {.cls plotit} or {.cls plotit_composite} object."
  )
}

# plotit() applies plot_layout(widths = unit(7, "in"), ...) for single-plot
# panel sizing.  This would force every sub-plot to a fixed physical size
# when assembled by wrap_plots(), causing overflow and cropping.  Strip it
# here so the composite controls layout.
#' Strip fixed panel sizing from a patchwork object.
#' Called before composite assembly to prevent cropping.
#' @noRd
#' @keywords internal
._reset_sizing <- function(gg) {
  if (!inherits(gg, "patchwork")) {
    return(gg)
  }
  gg + patchwork::plot_layout(widths = NULL, heights = NULL)
}

# Assemble a list of plots into a patchwork via wrap_plots()
#' Assemble a list of plots into a patchwork via wrap_plots().
#' @noRd
#' @keywords internal
._assemble_plots <- function(plots, layout) {
  ggs <- lapply(plots, ._extract_gg)
  ggs <- lapply(ggs, ._reset_sizing)

  args <- c(ggs, list(
    ncol    = layout$ncol,
    nrow    = layout$nrow,
    byrow   = layout$byrow %||% TRUE,
    widths  = layout$widths,
    heights = layout$heights,
    guides  = layout$guides
  ))
  gg <- do.call(patchwork::wrap_plots, args)

  # Composite-level plot_layout: axes sharing lives here
  if (!is.null(layout$axes) && layout$axes != "keep") {
    gg <- gg + patchwork::plot_layout(axes = layout$axes)
  }

  gg
}

# Lazily apply stored annotations to the raw assembled gg.
# Called at print() / export() time so that label_* methods can be
# called in any order without worrying about plot_annotation overwrites.
#' Lazily apply stored annotations (title, subtitle, caption, tags) to composite gg.
#' @noRd
#' @keywords internal
._apply_annotations <- function(c) {
  gg <- c@gg
  ann <- c@annotations
  has <- !is.null(ann$title) || !is.null(ann$subtitle) ||
    !is.null(ann$caption) || !is.null(ann$tag_levels)
  if (!has) {
    return(gg)
  }
  gg + patchwork::plot_annotation(
    title      = ann$title,
    subtitle   = ann$subtitle,
    caption    = ann$caption,
    tag_levels = ann$tag_levels
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
#' @param guides `"collect"` to merge legends, `"keep"` to separate,
#'   `NULL` (default) for patchwork auto-detect.
#' @param axes `"collect"` to share all axes, `"collect_x"` or `"collect_y"`
#'   for a single direction, `"keep"` (default) to keep axes independent.
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
  guides = NULL,
  axes = "keep",
  tag_levels = NULL
) {
  plots <- list(...)
  if (length(plots) == 0) {
    cli::cli_abort(
      "At least one {.cls plotit} or {.cls plotit_composite} object is required."
    )
  }

  if (is.null(ncol) && is.null(nrow)) {
    ncol <- 1
  }

  layout <- list(
    type    = "grid",
    ncol    = ncol,
    nrow    = nrow,
    byrow   = byrow,
    widths  = widths,
    heights = heights,
    guides  = guides,
    axes    = axes
  )

  annotations <- list(
    title      = NULL,
    subtitle   = NULL,
    caption    = NULL,
    tag_levels = tag_levels
  )

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
    cli::cli_abort("{.arg base} must be a {.cls plotit} object.")
  }

  base_gg <- ._reset_sizing(._extract_gg(base))
  inset_gg <- ._reset_sizing(._extract_gg(inset))
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
    annotations = list(
      title      = NULL,
      subtitle   = NULL,
      caption    = NULL,
      tag_levels = NULL
    )
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
#'   panels.  Default `c(4, 1)` = right marginal is 1/5 of total width.
#' @param heights Relative row heights for the top-marginal and main
#'   panels.  Default `c(1, 4)` = top marginal is 1/5 of total height.
#' @param guides `"collect"` (default) to merge legends across all panels,
#'   `"keep"` to keep them separate, `NULL` for patchwork auto-detect.
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
  top,
  right,
  widths = c(4, 1),
  heights = c(1, 4),
  guides = "collect"
) {
  if (!S7::S7_inherits(main, plotit_class)) {
    cli::cli_abort("{.arg main} must be a {.cls plotit} object.")
  }

  main_gg <- ._reset_sizing(._extract_gg(main))
  top_gg <- ._reset_sizing(._extract_gg(top))
  right_gg <- ._reset_sizing(._extract_gg(right))

  # Shared axes: hide redundant labels / ticks on marginal panels
  # BEFORE assembly (robust -- no patchwork-internals dependency)
  top_gg <- top_gg + ggplot2::theme(
    axis.text.x  = ggplot2::element_blank(),
    axis.title.x = ggplot2::element_blank(),
    axis.ticks.x = ggplot2::element_blank()
  )
  right_gg <- right_gg + ggplot2::theme(
    axis.text.y  = ggplot2::element_blank(),
    axis.title.y = ggplot2::element_blank(),
    axis.ticks.y = ggplot2::element_blank()
  )

  # Flat 2<U+00D7>2 design
  gg <- patchwork::wrap_plots(
    A = top_gg, B = patchwork::plot_spacer(),
    C = main_gg, D = right_gg,
    design = "AB\nCD"
  ) + patchwork::plot_layout(
    widths  = widths,
    heights = heights,
    guides  = guides
  )

  plotit_composite(
    gg = gg,
    plots = list(main, top, right),
    layout = list(
      type    = "marginal",
      widths  = widths,
      heights = heights
    ),
    annotations = list(
      title      = NULL,
      subtitle   = NULL,
      caption    = NULL,
      tag_levels = NULL
    )
  )
}

# ---- print method ---------------------------------------------------------

#' @export
S7::method(print, plotit_composite) <- function(x, ...) {
  gg <- ._apply_annotations(x)

  # Device management (consistent with plotit_class print)
  dev_opt <- getOption("plotit.device", "default")
  if (interactive() && !is.null(dev_opt)) {
    gt <- patchwork::patchworkGrob(gg)
    pw <- grid::convertWidth(
      sum(gt$widths) + ggplot2::unit(1, "mm"), "inches",
      valueOnly = TRUE
    )
    ph <- grid::convertHeight(
      sum(gt$heights) + ggplot2::unit(1, "mm"), "inches",
      valueOnly = TRUE
    )
    use_rstudio <- isTRUE(dev_opt == "rstudio")
    grDevices::dev.new(width = pw, height = ph, noRStudioGD = !use_rstudio)
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
  if (is.null(filename) || identical(filename, "")) {
    cli::cli_abort("{.arg filename} must be a non-empty file path.")
  }

  gg <- ._apply_annotations(plot)

  # Resolve size_unit from first sub-plot's meta, or global option
  meta_unit <- NULL
  for (p in plot@plots) {
    if (S7::S7_inherits(p, plotit_class)) {
      meta_unit <- p@meta@unit
      break
    }
  }
  meta_unit <- meta_unit %||% getOption("plotit.default_unit", "in")

  if (!is.null(width)) width <- .unit_to_inches(width, meta_unit)
  if (!is.null(height)) height <- .unit_to_inches(height, meta_unit)

  if (is.null(width) || is.null(height)) {
    gt <- patchwork::patchworkGrob(gg)
    if (is.null(width)) {
      width <- grid::convertWidth(
        sum(gt$widths) + ggplot2::unit(1, "mm"), "in",
        valueOnly = TRUE
      )
    }
    if (is.null(height)) {
      height <- grid::convertHeight(
        sum(gt$heights) + ggplot2::unit(1, "mm"), "in",
        valueOnly = TRUE
      )
    }
  }

  ggplot2::ggsave(
    filename = filename,
    plot     = gg,
    width    = width,
    height   = height,
    dpi      = dpi,
    device   = device,
    units    = "in",
    bg       = "white",
    ...
  )

  invisible(plot)
}

# ---- label_title method (composite) ---------------------------------------

#' @export
S7::method(label_title, plotit_composite) <- function(
  plot,
  text = NULL,
  hide = FALSE,
  reset = FALSE,
  ...
) {
  ._check_text_reset(text, reset, "label_title")
  if (hide || isTRUE(reset)) {
    plot@annotations$title <- NULL
  } else if (!is.null(text)) {
    plot@annotations$title <- text
  }
  plot
}

# ---- label_subtitle method (composite) ------------------------------------

#' @export
S7::method(label_subtitle, plotit_composite) <- function(
  plot,
  text = NULL,
  hide = FALSE,
  reset = FALSE,
  ...
) {
  ._check_text_reset(text, reset, "label_subtitle")
  if (hide || isTRUE(reset)) {
    plot@annotations$subtitle <- NULL
  } else if (!is.null(text)) {
    plot@annotations$subtitle <- text
  }
  plot
}

# ---- label_caption method (composite) -------------------------------------

#' @export
S7::method(label_caption, plotit_composite) <- function(
  plot,
  text = NULL,
  hide = FALSE,
  reset = FALSE,
  ...
) {
  ._check_text_reset(text, reset, "label_caption")
  if (hide || isTRUE(reset)) {
    plot@annotations$caption <- NULL
  } else if (!is.null(text)) {
    plot@annotations$caption <- text
  }
  plot
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
  thm <- base_theme %||% .theme_default(base_size, base_family)
  plot@gg <- plot@gg + thm + ggplot2::theme(...)
  plot
}

# ---- style_default method (composite) -------------------------------------

#' @export
S7::method(style_default, plotit_composite) <- function(
  plot,
  base_size = NULL,
  base_family = NULL
) {
  style(plot, base_size = base_size, base_family = base_family)
}
