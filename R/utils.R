#' Internal utility functions for plotit
#'
#' @include class.R
#' @noRd
#' @keywords internal
NULL

# ---- default_color management ----

# Colour-scale management registry.
#
# Tracks which aesthetics already carry a managed colour scale (the
# construction-time default, an injected default_color, or a user scale_*()).
# `._mark_impl()` consults the registry so a layer-level colour/fill mapping
# only gets the token default palette when no managed scale exists yet -- this
# keeps explicit-pipeline relational charts (as_graph() |> plotit() |> ...)
# on the same curated palettes as the sugar marks without ever clobbering a
# user scale.  Stored as an attribute on meta, mirroring the
# `plotit_theme_managed` pattern.
#' Get the aesthetics with a managed colour scale.
#' @noRd
#' @keywords internal
._colour_managed_get <- function(plot) {
  attr(plot@meta, "plotit_colour_managed", exact = TRUE) %||% character(0)
}

#' Register aesthetics as colour-managed.
#' @noRd
#' @keywords internal
._colour_managed_add <- function(plot, aes_names) {
  attr(plot@meta, "plotit_colour_managed") <-
    union(._colour_managed_get(plot), aes_names)
  plot
}

#' Un-register aesthetics (their scale was removed or handed to the user).
#' @noRd
#' @keywords internal
._colour_managed_remove <- function(plot, aes_names) {
  attr(plot@meta, "plotit_colour_managed") <-
    setdiff(._colour_managed_get(plot), aes_names)
  plot
}

# Clear the global default_color injected by plotit() so that legends
# appear when a layer or scale introduces its own colour/fill mapping.
# Called from the unified mark path (._mark_impl with layer mapping),
# hand-written marks (map/corr/treemap/sankey), scale_color/fill
# (unconditional), and project_parallel (when group introduces colour).
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
      # `guides(colour = NULL)` removes the injected "none" entry (public
      # API).  `waiver()` does NOT reset a stored guide under ggplot2 >= 3.5
      # S7 guides -- legends would stay suppressed.
      plot@gg <- plot@gg + ggplot2::guides(colour = NULL)
      plot <- ._colour_managed_remove(plot, "colour")
    }
    if (!is.null(mapping$fill)) {
      plot@gg$mapping$fill <- NULL
      plot@gg <- plot@gg + ggplot2::guides(fill = NULL)
      plot <- ._colour_managed_remove(plot, "fill")
    }
    # Only clear the meta marker when *both* colour and fill defaults
    # have been individually removed by layer mappings.  Prematurely
    # setting it to NULL would cause the next mark_* call that provides
    # the OTHER aesthetic to return early, leaving a residual default in
    # the global mapping that suppresses that legend.
    if (is.null(plot@gg$mapping$colour) && is.null(plot@gg$mapping$fill)) {
      S7::prop(plot@meta, "default_color") <- NULL
    }
    return(plot)
  }
  # Called from scale_*: unconditional clear (user explicitly manages colour/fill)
  plot@gg$mapping$colour <- NULL
  plot@gg$mapping$fill <- NULL
  plot@gg <- plot@gg +
    ggplot2::guides(colour = NULL, fill = NULL)
  S7::prop(plot@meta, "default_color") <- NULL
  # The injected constants owned both channels; they are gone now, so both
  # channels are free again (scale_*() re-registers its own aes right after;
  # mark-owned derived channels re-attach via the layer-level auto-attach).
  ._colour_managed_remove(plot, c("colour", "fill"))
}

# ---- aesthetic-kind registry ----
# scale_* auto-detection (trans = NULL) can only see the *global* mapping.
# Graph plots declare aesthetics exclusively at the layer level, so the
# mark pipeline records the evaluated kind (continuous/discrete) of every
# channel it resolves, and ._detect_discrete_aes consults this registry as
# a fallback.  Stored as an attribute on meta, like the colour-managed
# registry above; last write wins.
#' Record the discrete/continuous kind of layer-resolved channels.
#' @noRd
#' @keywords internal
._aes_kinds_add <- function(plot, kinds) {
  if (length(kinds) == 0) {
    return(plot)
  }
  attr(plot@meta, "plotit_aes_kinds") <-
    utils::modifyList(._aes_kinds_get(plot), kinds)
  plot
}

#' Read the recorded channel kinds.
#' @noRd
#' @keywords internal
._aes_kinds_get <- function(plot) {
  attr(plot@meta, "plotit_aes_kinds", exact = TRUE) %||% list()
}

# ---- optional-dependency guards ----

# Single choke point for the "requires package X" abort used by every
# optional-enhancement code path (ggrastr, ggrepel, sf, hexbin, ggbeeswarm,
# mapproj, tidygraph).  Keeps error wording identical across the package.
#' Abort when an optional dependency is missing.
#' @noRd
#' @keywords internal
._require_pkg <- function(pkg, reason) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    return(invisible())
  }
  cli::cli_abort(c(
    sprintf("%s requires the {.pkg %s} package.", reason, pkg),
    "i" = sprintf("Install it with {.code install.packages(%s)}.", deparse(pkg))
  ))
}

# ---- error / warning message constructors (SM7, design/08 §6) ----
#
# Three-part contract (AGENTS 4.5): problem -> got/cause -> remedy with the
# legal values.  These constructors keep the recurring validation shapes
# uniform so wording cannot drift apart between call sites.  `requirement`
# and `hint` strings may carry cli markup; value bullets interpolate via
# .envir so {.val {got}} renders exactly what the user passed.

# Parameter violates a range / shape constraint:
# ._abort_arg_range("inner_radius", "in (0, 1)", got = 1.5)
#' Abort: parameter outside its required range or shape.
#' @noRd
#' @keywords internal
._abort_arg_range <- function(name, requirement, got = NULL, hint = NULL) {
  segs <- c(sprintf("{.arg %s} must be %s.", name, requirement))
  if (!is.null(got)) {
    segs <- c(segs, "x" = "Got {.val {got}}.")
  }
  if (!is.null(hint)) {
    segs <- c(segs, "i" = hint)
  }
  cli::cli_abort(segs, .envir = list2env(
    list(got = got),
    parent = parent.frame()
  ))
}

# Parameter is outside a closed enumeration; ALL legal values are listed:
# ._abort_arg_enum("size_unit", c("in", "cm", "mm"), got = "pt")
#' Abort: parameter outside a closed set of legal values.
#' @noRd
#' @keywords internal
._abort_arg_enum <- function(name, allowed, got = NULL, hint = NULL) {
  msg <- sprintf("{.arg %s} must be one of {.or {.val {allowed}}}.", name)
  segs <- c(msg)
  if (!is.null(got)) {
    segs <- c(segs, "x" = "Got {.val {got}}.")
  }
  if (!is.null(hint)) {
    segs <- c(segs, "i" = hint)
  }
  cli::cli_abort(segs, .envir = list2env(
    list(allowed = allowed, got = got),
    parent = parent.frame()
  ))
}

# Validation failure with a single remedy bullet:
# ._abort_hint("{.fn mark_corr} requires tabular plot data.", "i" = "...")
#' Abort: problem statement plus one remedy bullet.
#' @noRd
#' @keywords internal
._abort_hint <- function(problem, hint) {
  cli::cli_abort(c(problem, "i" = hint))
}

# An argument has no effect in the current context:
# ._warn_ignored("seed", "the {layout} layout is deterministic")
#' Warn: argument is silently not applicable.
#' @noRd
#' @keywords internal
._warn_ignored <- function(name, reason, hint = NULL) {
  segs <- sprintf("{.arg %s} is ignored: %s.", name, reason)
  if (!is.null(hint)) {
    segs <- c(segs, "i" = hint)
  }
  cli::cli_warn(segs)
}

# Two inputs conflict; the first wins:
# ._warn_precedence("...", "rows")
#' Warn: two conflicting inputs, first takes precedence.
#' @noRd
#' @keywords internal
._warn_precedence <- function(winner, loser) {
  cli::cli_warn(c(
    sprintf("Both `%s` and `%s` provided.", winner, loser),
    "i" = sprintf("`%s` takes precedence; `%s` is ignored.", winner, loser)
  ))
}

# ---- size units & default canvas ----

# Convert user-specified size unit to inches.
#' Convert a measurement to inches.
#' @noRd
#' @keywords internal
._unit_to_inches <- function(x, unit) {
  x / switch(unit,
    "in" = 1,
    "cm" = 2.54,
    "mm" = 25.4
  )
}

# Package-default panel size in inches (registered by zzz.R, overridable
# via options()).  Single source for the autofit fallback in export() and
# the composite chrome budget in compose.R -- both must agree with the
# plotit() canvas defaults (5 x 3.5 in panel).
#' Package-default panel size in inches.
#' @noRd
#' @keywords internal
._default_panel_size <- function() {
  list(
    width = getOption("plotit.default_width", 5),
    height = getOption("plotit.default_height", 3.5)
  )
}

# ---- axis label cleanup ----

# Deparse a mapping quosure into a readable default axis label, stripping
# discrete-cast wrappers (factor/as.factor/ordered/as.ordered/as.character)
# so `encode(x = factor(cyl))` labels the axis "cyl" instead of the raw
# expression.  Non-wrapped expressions keep ggplot2's deparse behaviour.
# Constant mappings (e.g. the G2-style pie trick `encode(x = 1, ...)`)
# arrive as bare values rather than quosures and get no custom label --
# ggplot2's own default applies.
#' Clean a mapping expression into a default axis label.
#' @noRd
#' @keywords internal
._clean_axis_label <- function(var) {
  if (is.null(var) || !rlang::is_quosure(var)) {
    return(NULL)
  }
  expr <- rlang::quo_get_expr(var)
  wrappers <- c("factor", "as.factor", "ordered", "as.ordered", "as.character")
  is_wrapper <- rlang::is_call(expr) &&
    deparse(expr[[1]]) %in% wrappers &&
    length(expr) == 2
  if (is_wrapper) {
    expr <- expr[[2]]
  }
  paste(rlang::expr_deparse(expr), collapse = " ")
}

# Build a gtable with fixed panel dimensions (used at print/export time).
# When the plot uses a fixed-aspect coordinate system, the panel is shrunk
# to the largest aspect-true rectangle inside the declared box (letterbox)
# instead of being stretched.
#' Build a gtable with fixed panel dimensions.
#'
#' The declared panel size describes the whole panel *area*: across an
#' n-column x m-row facet grid each cell receives width / n and
#' height / m.  When the plot uses a fixed-aspect coordinate system, the
#' panel is shrunk to the largest aspect-true rectangle inside the
#' declared box (letterbox) instead of being stretched.
#' @noRd
#' @keywords internal
._build_fixed_gtable <- function(gg, width, height, unit = "in") {
  build <- ggplot2::ggplot_build(gg)
  gt <- ggplot2::ggplot_gtable(build)
  panel_cols <- unique(gt$layout$l[gt$layout$name == "panel"])
  panel_rows <- unique(gt$layout$t[gt$layout$name == "panel"])
  # Spread the declared panel area across the facet grid (1x1 for single
  # plots), so multi-panel exports keep the meta-declared total footprint.
  lay <- build$layout$layout
  n_col <- if (!is.null(lay)) max(1, max(lay$COL)) else 1
  n_row <- if (!is.null(lay)) max(1, max(lay$ROW)) else 1
  w_in <- ._unit_to_inches(width, unit) / n_col
  h_in <- ._unit_to_inches(height, unit) / n_row
  # Honour coordinate aspect ratios (e.g. coord_fixed): aspect is the
  # required physical height/width ratio per panel.  Multi-panel layouts
  # use the first panel's ranges (documented approximation for free scales).
  aspect <- tryCatch(
    {
      a <- gg$coordinates$aspect(build$layout$panel_params[[1]])
      if (is.numeric(a) && length(a) == 1 && is.finite(a) && a > 0) a else NULL
    },
    error = function(e) NULL
  )
  if (!is.null(aspect)) {
    if (h_in / w_in > aspect) {
      h_in <- w_in * aspect
    } else {
      w_in <- h_in / aspect
    }
  }
  for (col in panel_cols) gt$widths[[col]] <- grid::unit(w_in, "in")
  for (row in panel_rows) gt$heights[[row]] <- grid::unit(h_in, "in")
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
      cli::cli_warn(c(
        sprintf("Cannot determine variable type: %s", e$message),
        "i" = "Falling back to the continuous colour route."
      ))
      FALSE
    }
  )
}
