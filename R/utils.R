#' Internal utility functions for plotit
#'
#' @include class.R
#' @noRd
#' @keywords internal
NULL

# ---- default_color management ----

# Clear the global default_color injected by plotit() so that legends
# appear when a layer or scale introduces its own colour/fill mapping.
# Called from mark_* (with mapping), scale_color/fill (unconditional),
# and project_parallel (when group introduces colour).
#
# @param plot A plotit object.
# @param mapping Optional layer mapping.  If provided, the function only
#   clears when the mapping actually contains `colour` or `fill`.
# @return The modified plotit object.
#' Clear the global default_color injected by plotit().
#' Called from mark_* / scale_* / project_parallel when colour/fill is provided.
#' @noRd
#' @keywords internal
._clear_default_color <- function(plot, mapping = NULL) {
  if (is.null(plot@meta@default_color)) {
    return(plot)
  }
  if (!is.null(mapping)) {
    # Called from mark_*: only clear the aesthetics the layer actually provides
    if (is.null(mapping$colour) && is.null(mapping$fill)) {
      return(plot)
    }
    if (!is.null(mapping$colour)) {
      plot@gg$mapping$colour <- NULL
      plot@gg <- plot@gg + ggplot2::guides(colour = ggplot2::waiver())
    }
    if (!is.null(mapping$fill)) {
      plot@gg$mapping$fill <- NULL
      plot@gg <- plot@gg + ggplot2::guides(fill = ggplot2::waiver())
    }
    S7::prop(plot@meta, "default_color") <- NULL
    return(plot)
  }
  # Called from scale_*: unconditional clear (user explicitly manages colour/fill)
  plot@gg$mapping$colour <- NULL
  plot@gg$mapping$fill <- NULL
  plot@gg <- plot@gg +
    ggplot2::guides(colour = ggplot2::waiver(), fill = ggplot2::waiver())
  S7::prop(plot@meta, "default_color") <- NULL
 plot
}

# Build a gtable with fixed panel dimensions (used at print/export time).
#' Build a gtable with fixed panel dimensions.
#' @noRd
#' @keywords internal
._build_fixed_gtable <- function(gg, width, height, unit = "in") {
  gt <- ggplot2::ggplot_gtable(ggplot2::ggplot_build(gg))
  panel_cols <- unique(gt$layout$l[gt$layout$name == "panel"])
  panel_rows <- unique(gt$layout$t[gt$layout$name == "panel"])
  for (col in panel_cols) gt$widths[[col]] <- grid::unit(width, unit)
  for (row in panel_rows) gt$heights[[row]] <- grid::unit(height, unit)
  gt
}

# Null coalescing operator
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

# Check if a variable (from data) is discrete (factor, character, or logical).
# `var` is expected to be a quosure (as produced by aes()/encode()).
# Uses rlang::eval_tidy for proper data-masking (avoids clashes when column
# names shadow base R functions like 'mean' or 'list').
#' Check if a variable (from data) is discrete.
#' Uses rlang::eval_tidy for proper data-masking.
#' @noRd
#' @keywords internal
is_discrete <- function(data, var) {
  if (is.null(data) || is.null(var)) {
    return(FALSE)
  }
  tryCatch(
    {
      col <- rlang::eval_tidy(var, data)
      is.factor(col) || is.character(col) || is.logical(col)
    },
    error = function(e) {
      cli::cli_warn("Cannot determine variable type: {e$message}")
      FALSE
    }
  )
}
