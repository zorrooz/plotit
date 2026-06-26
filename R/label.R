#' @include class.R
NULL

# ---- Internal helpers for label family ----
# Three-parameter protocol (AGENTS.md §3.3.7):
#   text  = NULL     -> no-op (don't change current label)
#   text  = "str"    -> set custom text
#   hide  = TRUE     -> remove element from layout (element_blank())
#   reset = TRUE     -> restore variable name (axis/legend) or remove (title/subtitle/caption)
#   text + reset     -> mutually exclusive; error if both are set

# Check text/reset mutual exclusion
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

._set_text_label <- function(plot, slot_name, theme_el_name,
                             text, hide, reset, fun_name) {
  ._check_text_reset(text, reset, fun_name)
  if (hide) {
    S7::prop(plot@meta@labels, slot_name) <- FALSE
    plot@meta@labels@dirty[[slot_name]] <- TRUE
  } else if (isTRUE(reset)) {
    S7::prop(plot@meta@labels, slot_name) <- NULL
    plot@meta@labels@dirty[[slot_name]] <- TRUE
  } else if (!is.null(text)) {
    S7::prop(plot@meta@labels, slot_name) <- text
    plot@meta@labels@dirty[[slot_name]] <- TRUE
  }
  plot
}

# Helper: construct a single-element theme() call with dynamic name
._theme_el <- function(el, val) {
  args <- list(val)
  names(args) <- el
  do.call(ggplot2::theme, args)
}
# Helper: construct a single-element labs() call with dynamic name
._labs_el <- function(a, val) {
  args <- list(val)
  names(args) <- a
  do.call(ggplot2::labs, args)
}

# Collect all aesthetic names from global + layer-level mappings
._collect_aes_names <- function(gg, candidates) {
  unique(c(
    intersect(names(gg), candidates),
    unlist(lapply(gg, function(l) {
      if (is.null(l)) {
        character(0)
      } else {
        intersect(names(l), candidates)
      }
    }))
  ))
}

# Set legend title for a single aesthetic (public ggplot2 API only).
._label_set_aes <- function(gg, a, text, hide) {
  if (hide) {
    args <- list(ggplot2::guide_legend(title = NULL))
    names(args) <- a
    gg <- gg + do.call(ggplot2::guides, args)
  } else if (is.null(text)) {
    gg[[a]] <- NULL
  } else {
    gg <- gg + ._labs_el(a, text)
  }
  gg
}

# ---- Synchronise meta@labels to gg (called at print/export time) ----
# Applies the complete label state from meta to gg, overwriting any
# previous gg modifications.  Only touches slots listed in dirty.
._sync_labels <- function(plot) {
  labels <- plot@meta@labels
  dirty <- names(labels@dirty)
  if (length(dirty) == 0) return(plot)

  # Title
  if ("title" %in% dirty) {
    val <- labels@title
    if (isTRUE(val == FALSE)) {
      plot@gg <- plot@gg + ._theme_el("plot.title", ggplot2::element_blank())
    } else if (is.null(val)) {
      plot@gg <- plot@gg + ._theme_el("plot.title", NULL)
      plot@gg <- NULL
    } else if (is.character(val)) {
      plot@gg <- plot@gg + ._labs_el("title", val)
      plot@gg <- plot@gg + ._theme_el("plot.title", NULL)
    }
  }

  # Subtitle
  if ("subtitle" %in% dirty) {
    val <- labels@subtitle
    if (isTRUE(val == FALSE)) {
      plot@gg <- plot@gg + ._theme_el("plot.subtitle", ggplot2::element_blank())
    } else if (is.null(val)) {
      plot@gg <- plot@gg + ._theme_el("plot.subtitle", NULL)
      plot@gg <- NULL
    } else if (is.character(val)) {
      plot@gg <- plot@gg + ._labs_el("subtitle", val)
      plot@gg <- plot@gg + ._theme_el("plot.subtitle", NULL)
    }
  }

  # Caption
  if ("caption" %in% dirty) {
    val <- labels@caption
    if (isTRUE(val == FALSE)) {
      plot@gg <- plot@gg + ._theme_el("plot.caption", ggplot2::element_blank())
    } else if (is.null(val)) {
      plot@gg <- plot@gg + ._theme_el("plot.caption", NULL)
      plot@gg <- NULL
    } else if (is.character(val)) {
      plot@gg <- plot@gg + ._labs_el("caption", val)
      plot@gg <- plot@gg + ._theme_el("plot.caption", NULL)
    }
  }

  # X axis
  if ("x" %in% dirty) {
    val <- labels@x
    if (isTRUE(val == FALSE)) {
      plot@gg <- plot@gg + ._theme_el("axis.title.x", ggplot2::element_blank())
    } else if (is.null(val)) {
      plot@gg <- plot@gg + ._theme_el("axis.title.x", NULL)
      plot@gg <- NULL
    } else if (is.character(val)) {
      plot@gg <- plot@gg + ._labs_el("x", val)
      plot@gg <- plot@gg + ._theme_el("axis.title.x", NULL)
    }
  }

  # Y axis
  if ("y" %in% dirty) {
    val <- labels@y
    if (isTRUE(val == FALSE)) {
      plot@gg <- plot@gg + ._theme_el("axis.title.y", ggplot2::element_blank())
    } else if (is.null(val)) {
      plot@gg <- plot@gg + ._theme_el("axis.title.y", NULL)
      plot@gg <- NULL
    } else if (is.character(val)) {
      plot@gg <- plot@gg + ._labs_el("y", val)
      plot@gg <- plot@gg + ._theme_el("axis.title.y", NULL)
    }
  }

  # Legend entries
  if ("legend" %in% dirty && length(labels@legend) > 0) {
    aes_names <- ._collect_aes_names(plot@gg,
      c("colour", "fill", "shape", "linetype", "size", "alpha"))
    for (a in aes_names) {
      val <- labels@legend[[a]] %||% labels@legend[["default"]]
      if (isTRUE(val == FALSE)) {
        plot@gg <- ._label_set_aes(plot@gg, a, NULL, hide = TRUE)
      } else if (is.null(val)) {
        plot@gg <- ._label_set_aes(plot@gg, a, NULL, hide = FALSE)
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
  ._set_text_label(plot, "title", "plot.title", text, hide, reset, "label_title")
}

# ---- label_subtitle ----
#' Generic for setting plot subtitle
#' @param plot A plotit object
#' @param text Subtitle text. NULL = don't modify. "str" = custom subtitle.
#' @param hide If TRUE, remove subtitle element from layout entirely.
#' @param reset If TRUE, remove the subtitle text (restore to no subtitle).
#' @param ... Currently unused
#' @return Modified plotit object
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
  ._set_text_label(plot, "subtitle", "plot.subtitle", text, hide, reset, "label_subtitle")
}

# ---- label_caption ----
#' Generic for setting plot caption
#' @param plot A plotit object
#' @param text Caption text. NULL = don't modify. "str" = custom caption.
#' @param hide If TRUE, remove caption element from layout entirely.
#' @param reset If TRUE, remove the caption text (restore to no caption).
#' @param ... Currently unused
#' @return Modified plotit object
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
  ._set_text_label(plot, "caption", "plot.caption", text, hide, reset, "label_caption")
}

# ---- label_axis ----
#' Generic for setting axis titles
#' @param plot A plotit object
#' @param text Axis title text. NULL = don't modify. "str" = custom title.
#' @param aes Which axis to apply to: "x" or "y" (required).
#' @param hide If TRUE, hide the axis title entirely (lement_blank()).
#' @param reset If TRUE, restore the axis title to the variable name.
#' @param ... Currently unused
#' @return Modified plotit object
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
  ._check_text_reset(text, reset, "label_axis")

  if (hide) {
    S7::prop(plot@meta@labels, aes) <- FALSE
    plot@meta@labels@dirty[[aes]] <- TRUE
  } else if (isTRUE(reset)) {
    S7::prop(plot@meta@labels, aes) <- NULL
    plot@meta@labels@dirty[[aes]] <- TRUE
  } else if (!is.null(text)) {
    S7::prop(plot@meta@labels, aes) <- text
    plot@meta@labels@dirty[[aes]] <- TRUE
  }
  plot
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
  eff_text <- if (isTRUE(reset)) NULL else text
  if (is.null(eff_text) && !isTRUE(hide) && !isTRUE(reset)) {
    return(plot)
  }
  if (is.null(aes)) {
    plot@meta@labels@legend[["default"]] <- if (hide) FALSE else eff_text
    plot@meta@labels@dirty[["legend"]] <- TRUE
  } else {
    aes_all <- ._collect_aes_names(
      plot@gg,
      c("colour", "fill", "shape", "linetype", "size", "alpha"))
    if (!(aes %in% aes_all)) {
      cli::cli_warn("Aesthetic {.val {aes}} is not present in the plot mapping.")
    } else {
      plot@meta@labels@legend[[aes]] <- if (hide) FALSE else eff_text
      plot@meta@labels@dirty[["legend"]] <- TRUE
    }
  }
  plot
}
