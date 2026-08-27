#' @include class.R utils.R style.R
NULL

# Measure a grob (fixed gtable or patchwork) in inches; the 1 mm slack
# mirrors the device sizing used by print() so both paths agree.
#' Measure a grob's width/height in inches.
#' @noRd
#' @keywords internal
._measure_inches <- function(gt) {
  list(
    width = grid::convertWidth(
      sum(gt$widths) + ggplot2::unit(1, "mm"), "in",
      valueOnly = TRUE
    ),
    height = grid::convertHeight(
      sum(gt$heights) + ggplot2::unit(1, "mm"), "in",
      valueOnly = TRUE
    )
  )
}

# Open an interactively sized device window (plotit.device option).
#' Open a device window at the given physical size.
#' @noRd
#' @keywords internal
._open_sized_device <- function(size_in, dev_opt) {
  use_rstudio <- isTRUE(dev_opt == "rstudio")
  grDevices::dev.new(
    width = size_in$width,
    height = size_in$height,
    noRStudioGD = !use_rstudio
  )
}

# ---- format ----
# Suppress S7 text output so pkgdown reference examples capture rendered plots.
#' @noRd
S7::method(format, plotit_class) <- function(x, ...) ""
S7::method(format, plotit_composite) <- function(x, ...) ""

# ---- internal render routing ----
# Render to the active device so evaluate/pkgdown/R CMD check capture output.
#' @noRd
#' @keywords internal
._render_plotit <- function(x) {
  print(x@gg)
  invisible(x)
}

# ---- pkgdown_print ----
# pkgdown evaluates @examples via evaluate::evaluate(), which calls
# pkgdown_print(value) as the output_handler `value` callback.  S7 objects
# hit pkgdown_print.default() → print.S7_object() → str.S7_object(), which
# dumps the full ggproto tree.  Intercept with S3 methods that render the
# plot to the device so evaluate records it, then return invisible to
# suppress the text dump.
#' @exportS3Method pkgdown::pkgdown_print
pkgdown_print.plotit <- function(x, visible = TRUE) {
  if (!visible) {
    return(invisible())
  }
  ._print_render(x)
}

#' @exportS3Method pkgdown::pkgdown_print
pkgdown_print.plotit_composite <- function(x, visible = TRUE) {
  if (!visible) {
    return(invisible())
  }
  ._apply_annotations(x) |> print()
  invisible()
}

# ---- print ----
# Shared render preparation: default-theme fallback + lazy label sync.
# Used by every print/export/knit entry point (AGENTS.md 1.2).
#' Apply the managed-theme fallback to a plot built without one.
#'
#' Export() shares this step so a plot that is exported before it is ever
#' printed carries the same academic theme as the on-screen render.
#' @noRd
#' @keywords internal
._ensure_theme <- function(x) {
  needs_theme <- is.null(attr(x@meta, "plotit_theme_managed", exact = TRUE)) ||
    length(x@gg$theme) == 0
  if (needs_theme) {
    x@gg <- x@gg + ._theme_default()
    attr(x@meta, "plotit_theme_managed") <- TRUE
  }
  x
}

#' Apply theme fallback and sync lazy labels before rendering.
#' @noRd
#' @keywords internal
._prepare_render <- function(x) {
  x <- ._ensure_theme(x)
  # Aspect-true rendering outranks fixed panel sizing: baked absolute panel
  # dimensions would stretch fixed-aspect coordinates (chord / network /
  # project_cartesian(fixed = ...)).
  if (._gg_aspect_conflict(x@gg)) {
    x@gg <- ._strip_panel_size(x@gg)
  }
  # Apply lazy labels on every print (not just the first)
  ._sync_labels(x)
}

#' Print a plotit object (automatically render the plot)
#'
#' @param x A plotit object
#' @param ... Additional arguments (not used)
#' @return The plotit object (invisibly)
#' Shared print body for the S3 and S7 print paths.
#'
#' plotit() prepends the unqualified class "plotit", so ordinary print()
#' dispatch lands on the S3 print.plotit below; the S7 method only fires
#' for explicit S7 dispatch (e.g. S7 objects held under the namespaced
#' class alone).  Both route through here so interactive device sizing —
#' the documented WYSIWYG behavior (AGENTS.md 7) — is never silently lost
#' on whichever path dispatch takes.
#' @noRd
#' @keywords internal
._print_plotit_impl <- function(x) {
  x <- ._prepare_render(x)
  dev_opt <- getOption("plotit.device", "default")
  if (interactive() && !is.null(x@meta@width) && !is.null(x@meta@height) && !is.null(dev_opt)) {
    gt <- ._build_fixed_gtable(x@gg, x@meta@width, x@meta@height, x@meta@unit)
    ._open_sized_device(._measure_inches(gt), dev_opt)
    grid::grid.draw(gt)
    invisible(x)
  } else {
    ._render_plotit(x)
  }
}

#' @noRd
S7::method(print, plotit_class) <- function(x, ...) {
  ._print_plotit_impl(x)
}

# S3 print method — the live dispatch path for plotit objects (class is
# prepended unqualified in plotit()); also what knitr/vignettes reach.
#' @export
print.plotit <- function(x, ...) {
  ._print_plotit_impl(x)
}

# ---- knit_print ----
# S3 methods for knitr to capture plotit plots in vignettes / R Markdown.
# Renders the underlying ggplot to knitr's active device.

# Shared knit_print / pkgdown_print path.  Routes through the same render
# preparation as print() (theme fallback + aspect-conflict panel strip +
# lazy label sync) so knitr/pkgdown output is pixel-identical to the
# interactive device.
#' @noRd
#' @keywords internal
._print_render <- function(x) {
  x <- ._prepare_render(x)
  ._render_plotit(x)
}

#' @exportS3Method knitr::knit_print
knit_print.plotit <- function(x, ...) {
  ._print_render(x)
}

#' @exportS3Method knitr::knit_print
knit_print.plotit_composite <- function(x, ...) {
  x@gg <- ._apply_annotations(x)
  print(x@gg)
  invisible(x)
}

# ---- export ----
#' Export a plotit object to a file
#'
#' @param plot A plotit object.
#' @param filename Output filename (extension determines device, e.g., ".pdf").
#' @param width Output width (if NULL, uses meta then package default).
#' @param height Output height (if NULL, uses meta then package default).
#' @param dpi Resolution for raster formats (default 300).
#' @param device Graphics device to use (if NULL, auto-detected from filename).
#' @param ... Additional arguments passed to `ggplot2::ggsave()`.
#' @return Invisibly, the original `plotit` object.
#' @examples
#' p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
#' export(p, tempfile(fileext = ".png"), dpi = 72)
#' @export
export <- S7::new_generic(
  "export",
  "plot",
  function(
    plot,
    filename,
    width = NULL,
    height = NULL,
    dpi = 300,
    device = NULL,
    ...
  ) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(export, plotit_class) <- function(
  plot,
  filename,
  width = NULL,
  height = NULL,
  dpi = 300,
  device = NULL,
  ...
) {
  meta_unit <- plot@meta@unit %||% getOption("plotit.default_unit", "in")

  # Theme fallback + lazy labels before measuring / exporting (same
  # preparation as print, minus the aspect strip -- the fixed gtable
  # letterboxes CoordFixed panels on its own).
  plot <- ._ensure_theme(plot)
  plot <- ._sync_labels(plot)

  if (isTRUE(plot@meta@autofit)) {
    final_plot <- plot@gg
    def_size <- ._default_panel_size()
    final_width <- if (is.null(width)) {
      def_size$width
    } else {
      ._unit_to_inches(width, meta_unit)
    }
    final_height <- if (is.null(height)) {
      def_size$height
    } else {
      ._unit_to_inches(height, meta_unit)
    }
  } else {
    gt <- ._build_fixed_gtable(plot@gg, plot@meta@width, plot@meta@height, plot@meta@unit)
    measured <- ._measure_inches(gt)
    final_plot <- gt
    final_width <- if (is.null(width)) measured$width else ._unit_to_inches(width, meta_unit)
    final_height <- if (is.null(height)) measured$height else ._unit_to_inches(height, meta_unit)
  }

  ._ggsave_inches(filename, final_plot, final_width, final_height, dpi, device, ...)

  invisible(plot)
}
