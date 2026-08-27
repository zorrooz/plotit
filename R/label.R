#' @include class.R
NULL

# ---- Internal helpers for label family ----
# Three-parameter protocol (AGENTS.md 3.3.7):
#   text  = NULL     -> no-op (don't change current label)
#   text  = "str"    -> set custom text
#   hide  = TRUE     -> remove element from layout (element_blank())
#   reset = TRUE     -> restore variable name (axis/legend) or remove (title/subtitle/caption)
#   text + reset     -> mutually exclusive; error if both are set
# Priority: reset > hide > text — checked in exactly that order so a
# reset+hide call restores rather than blanks (matching the documented
# contract; an explicit reset always wins over an older intent).

# Check text/reset mutual exclusion
#' Check mutual exclusion of text and reset parameters.
#' @noRd
#' @keywords internal
._check_text_reset <- function(text, reset, fun_name) {
  if (!is.null(text) && isTRUE(reset)) {
    cli::cli_abort(c(
      "{.arg text} and {.arg reset} are mutually exclusive in {.fn {fun_name}}.",
      "i" = "Use {.arg text} to set a custom label, or {.arg reset = TRUE} to restore the default."
    ))
  }
}

# ---- Lazy label storage (Problem 3) ----
# Labels are stored in meta@labels and only applied to gg at print/export
# time via ._sync_labels().  The dirty list tracks which slots have been
# touched by label_* functions.

#' Store a text/hide/reset intent for title/subtitle/caption in meta@labels.
#' @noRd
#' @keywords internal
._set_text_label <- function(plot, slot_name, text, hide, reset, fun_name) {
  ._check_text_reset(text, reset, fun_name)
  if (isTRUE(reset)) {
    S7::prop(plot@meta@labels, slot_name) <- NULL
    plot@meta@labels@dirty[[slot_name]] <- TRUE
  } else if (hide) {
    S7::prop(plot@meta@labels, slot_name) <- FALSE
    plot@meta@labels@dirty[[slot_name]] <- TRUE
  } else if (!is.null(text)) {
    S7::prop(plot@meta@labels, slot_name) <- text
    plot@meta@labels@dirty[[slot_name]] <- TRUE
  }
  plot
}

# Helper: construct a single-element theme() call with dynamic name
#' Construct a single-element theme() call.
#' @noRd
#' @keywords internal
._theme_el <- function(el, val) {
  args <- list(val)
  names(args) <- el
  do.call(ggplot2::theme, args)
}
# Helper: construct a single-element labs() call with dynamic name
#' Construct a single-element labs() call.
#' @noRd
#' @keywords internal
._labs_el <- function(a, val) {
  args <- list(val)
  names(args) <- a
  do.call(ggplot2::labs, args)
}

# Aesthetic families that can carry a legend title, used by both the sync
# pass and the validation in label_legend().
._LEGEND_AES <- c("colour", "fill", "shape", "linetype", "size", "alpha")

# Collect all aesthetic names from global + layer-level mappings
#' Collect aesthetic names from global mapping.
#' @noRd
#' @keywords internal
._collect_aes_names <- function(gg, candidates = ._LEGEND_AES) {
  if (inherits(gg, "patchwork")) {
    return(unique(unlist(lapply(gg$plots, function(p) {
      ._collect_aes_names(p, candidates)
    }))))
  }
  # Global mapping
  global_aes <- intersect(names(gg$mapping), candidates)
  # Layer-level mappings
  layer_aes <- unlist(lapply(gg$layers, function(layer) {
    intersect(names(layer$mapping), candidates)
  }))
  # Labels
  label_aes <- intersect(names(gg$labels), candidates)
  unique(c(global_aes, layer_aes, label_aes))
}

# Set legend title for a single aesthetic (public ggplot2 API only).
#' Set legend title for a single aesthetic via guides/labs.
#' @noRd
#' @keywords internal
._label_set_aes <- function(gg, a, text, hide) {
  if (hide) {
    args <- list(ggplot2::guide_legend(title = NULL))
    names(args) <- a
    gg <- gg + do.call(ggplot2::guides, args)
  } else if (is.null(text)) {
    gg$labels[[a]] <- NULL
  } else {
    gg$labels[[a]] <- text
    gg <- gg + ._labs_el(a, text)
  }
  gg
}

# ---- Synchronise meta@labels to gg (called at print/export time) ----
# Applies the complete label state from meta to gg, overwriting any
# previous gg modifications.  Only touches slots listed in dirty.

# Internal: sync one text label slot.
# slot_name: property name in plotit_labels (e.g. "title")
# theme_el_name: gg theme element (e.g. "plot.title")
# labs_name: gg labels name (e.g. "title")
#' Sync one text label slot: hide / reset / set.
#' @noRd
#' @keywords internal
._sync_one_label <- function(plot, slot_name, theme_el_name, labs_name) {
  val <- S7::prop(plot@meta@labels, slot_name)
  if (isTRUE(val == FALSE)) {
    plot@gg <- plot@gg + ._theme_el(theme_el_name, ggplot2::element_blank())
  } else if (is.null(val)) {
    plot@gg <- plot@gg + ._theme_el(theme_el_name, NULL)
    plot@gg$labels[[labs_name]] <- NULL
  } else if (is.character(val)) {
    plot@gg <- plot@gg + ._labs_el(labs_name, val)
    # Undo a previous hide without deleting the styled default element:
    # `theme(el = NULL)` removes the key entirely (modifyList semantics),
    # which would wipe the shared theme's typography (alignment, size
    # hierarchy) for that element.
    cur <- plot@gg$theme[[theme_el_name]]
    if (inherits(cur, "element_blank")) {
      plot@gg <- plot@gg + ._theme_el(
        theme_el_name, ggplot2::calc_element(theme_el_name, ._theme_default())
      )
    }
  }
  plot
}

# Table mapping dirty slot → (theme element, labs name).
._LABEL_SYNC_MAP <- list(
  title    = list(theme = "plot.title", labs = "title"),
  subtitle = list(theme = "plot.subtitle", labs = "subtitle"),
  caption  = list(theme = "plot.caption", labs = "caption"),
  x        = list(theme = "axis.title.x", labs = "x"),
  y        = list(theme = "axis.title.y", labs = "y")
)

#' Sync meta@labels to gg at print/export time.
#' Applies the complete label state (text, hide, reset) to gg.
#' @noRd
#' @keywords internal
._sync_labels <- function(plot) {
  labels <- plot@meta@labels
  dirty <- names(labels@dirty)
  if (length(dirty) == 0) {
    return(plot)
  }

  for (slot in intersect(dirty, names(._LABEL_SYNC_MAP))) {
    m <- ._LABEL_SYNC_MAP[[slot]]
    plot <- ._sync_one_label(plot, slot, m$theme, m$labs)
  }

  # Legend entries (non-uniform: state machine with default fallback).
  # Stored intent encodings: character = set text, FALSE = hide,
  # TRUE = reset (drop the synced custom title, restore the scale-derived
  # one), NULL/absent = no intent for that aesthetic.
  if ("legend" %in% dirty && length(labels@legend) > 0) {
    aes_names <- ._collect_aes_names(plot@gg, ._LEGEND_AES)
    for (a in aes_names) {
      val <- labels@legend[[a]] %||% labels@legend[["default"]]
      # No stored intent for this aesthetic -> leave its title untouched.
      # (Deleting gg$labels[[a]] here would silently wipe titles that came
      # from scale names or earlier labs() calls on sibling legends.)
      if (is.null(val)) {
        next
      }
      if (isTRUE(val)) {
        plot@gg <- ._label_set_aes(plot@gg, a, NULL, hide = FALSE)
      } else if (isFALSE(val)) {
        plot@gg <- ._label_set_aes(plot@gg, a, NULL, hide = TRUE)
      } else {
        plot@gg <- ._label_set_aes(plot@gg, a, val, hide = FALSE)
      }
    }
  }

  plot
}

# ---- label_title ----
#' Generic for setting plot title
#' @param plot A plotit object
#' @param text Title text. NULL = don't modify. "str" = custom title.
#' @param hide If TRUE, remove title element from layout entirely.
#' @param reset If TRUE, remove the title text (restore to no title).
#' @param ... Currently unused
#' @return Modified plotit object
#' @examples
#' plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> label_title("My Title")
#' @export
label_title <- S7::new_generic(
  "label_title",
  "plot",
  function(plot, text = NULL, hide = FALSE, reset = FALSE, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(label_title, plotit_class) <- function(plot, text = NULL, hide = FALSE,
                                                  reset = FALSE, ...) {
  ._set_text_label(plot, "title", text, hide, reset, "label_title")
}

# ---- label_subtitle ----
#' Generic for setting plot subtitle
#' @param plot A plotit object
#' @param text Subtitle text. NULL = don't modify. "str" = custom subtitle.
#' @param hide If TRUE, remove subtitle element from layout entirely.
#' @param reset If TRUE, remove the subtitle text (restore to no subtitle).
#' @param ... Currently unused
#' @return Modified plotit object
#' @examples
#' plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> label_subtitle("Subtitle")
#' @export
label_subtitle <- S7::new_generic(
  "label_subtitle",
  "plot",
  function(plot, text = NULL, hide = FALSE, reset = FALSE, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(label_subtitle, plotit_class) <- function(plot, text = NULL, hide = FALSE,
                                                     reset = FALSE, ...) {
  ._set_text_label(plot, "subtitle", text, hide, reset, "label_subtitle")
}

# ---- label_caption ----
#' Generic for setting plot caption
#' @param plot A plotit object
#' @param text Caption text. NULL = don't modify. "str" = custom caption.
#' @param hide If TRUE, remove caption element from layout entirely.
#' @param reset If TRUE, remove the caption text (restore to no caption).
#' @param ... Currently unused
#' @return Modified plotit object
#' @examples
#' plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> label_caption("Caption")
#' @export
label_caption <- S7::new_generic(
  "label_caption",
  "plot",
  function(plot, text = NULL, hide = FALSE, reset = FALSE, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(label_caption, plotit_class) <- function(plot, text = NULL, hide = FALSE,
                                                    reset = FALSE, ...) {
  ._set_text_label(plot, "caption", text, hide, reset, "label_caption")
}

# ---- label_axis ----
#' Generic for setting axis titles
#' @param plot A plotit object
#' @param text Axis title text. NULL = don't modify. "str" = custom title.
#' @param aes Which axis to apply to: "x" or "y" (required).
#' @param hide If TRUE, hide the axis title entirely (`element_blank()`).
#' @param reset If TRUE, restore the axis title to the variable name.
#' @param ... Currently unused
#' @return Modified plotit object
#' @examples
#' plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
#'   label_axis(text = "Width", aes = "x") |>
#'   label_axis(text = "Length", aes = "y")
#' @export
label_axis <- S7::new_generic(
  "label_axis",
  "plot",
  function(plot, text = NULL, aes = NULL, hide = FALSE, reset = FALSE, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(label_axis, plotit_class) <- function(plot, text = NULL, aes = NULL,
                                                 hide = FALSE, reset = FALSE, ...) {
  if (is.null(aes)) {
    cli::cli_abort("{.arg aes} must be specified: {.code aes = \"x\"} or {.code aes = \"y\"}.")
  }
  if (!(aes %in% c("x", "y"))) {
    cli::cli_abort("{.arg aes} must be one of {.val c('x', 'y')}, not {.val {aes}}.")
  }
  # Same three-parameter protocol as title/subtitle/caption; the axis slot
  # names in meta@labels match the aes argument.
  ._set_text_label(plot, aes, text, hide, reset, "label_axis")
}

# ---- label_legend ----
#' Generic for setting legend title(s)
#' @param plot A plotit object
#' @param text Legend title text. NULL = don't modify. "str" = custom title.
#' @param aes Aesthetic to apply to (e.g. "colour", "fill"). NULL = all mapped aesthetics.
#' @param hide If TRUE, hide the legend title.
#' @param reset If TRUE, restore the legend title to the variable name.
#' @param ... Currently unused
#' @return Modified plotit object
#' @examples
#' plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
#'   mark_point() |>
#'   scale_color() |>
#'   label_legend(text = "Species", aes = "colour")
#' @export
label_legend <- S7::new_generic(
  "label_legend",
  "plot",
  function(plot, text = NULL, aes = NULL, hide = FALSE, reset = FALSE, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(label_legend, plotit_class) <- function(plot, text = NULL, aes = NULL,
                                                   hide = FALSE, reset = FALSE, ...) {
  ._check_text_reset(text, reset, "label_legend")
  # Priority reset > hide > text (mirrors ._set_text_label and the
  # documented protocol).  TRUE is the reset sentinel consumed by
  # ._sync_labels; it must survive a later sync (NULL would read as
  # "no intent" and leave a previously applied custom title in place).
  intent <- if (isTRUE(reset)) TRUE else if (isTRUE(hide)) FALSE else text
  if (is.null(intent)) {
    return(plot)
  }
  if (is.null(aes)) {
    # Global mode: drop per-aes entries on reset so the restore intent
    # reaches every mapped aesthetic (per-aes entries shadow the default).
    if (isTRUE(reset)) {
      plot@meta@labels@legend <- list()
    }
    plot@meta@labels@legend[["default"]] <- intent
    plot@meta@labels@dirty[["legend"]] <- TRUE
  } else {
    aes_all <- ._collect_aes_names(plot@gg, ._LEGEND_AES)
    if (!(aes %in% aes_all)) {
      cli::cli_warn("Aesthetic {.val {aes}} is not present in the plot mapping.")
    } else {
      plot@meta@labels@legend[[aes]] <- intent
      plot@meta@labels@dirty[["legend"]] <- TRUE
    }
  }
  plot
}
