#' @include class.R
NULL

# ---- Internal helpers for label family ----
# Three-parameter protocol (AGENTS.md §3.3.7):
#   text  = NULL     → no-op (don't change current label)
#   text  = "str"    → set custom text
#   hide  = TRUE     → remove element from layout (element_blank())
#   reset = TRUE     → restore variable name (axis/legend) or remove (title/subtitle/caption)
#   text + reset     → mutually exclusive; error if both are set

# Check text/reset mutual exclusion
._check_text_reset <- function(text, reset, fun_name) {
  if (!is.null(text) && isTRUE(reset)) {
    cli::cli_abort(c(
      "{.arg text} and {.arg reset} are mutually exclusive in {.fn {fun_name}}.",
      "i" = "Use {.arg text} to set a custom label, or {.arg reset = TRUE} to restore the default."
    ))
  }
}

# Shared implementation for label_title / label_subtitle / label_caption.
# These three differ only in the meta slot name, theme element, and labs key.
._set_text_label <- function(plot, slot_name, theme_el_name,
                             text, hide, reset, fun_name) {
  ._check_text_reset(text, reset, fun_name)
  if (hide) {
    S7::prop(plot@meta@labels, slot_name) <- NULL
    plot@gg <- plot@gg + .theme_el(theme_el_name, ggplot2::element_blank())
  } else if (isTRUE(reset)) {
    S7::prop(plot@meta@labels, slot_name) <- NULL
    plot@gg <- plot@gg + .labs_el(slot_name, NULL)
  } else if (!is.null(text)) {
    S7::prop(plot@meta@labels, slot_name) <- text
    plot@gg <- plot@gg + .labs_el(slot_name, text)
  }
  plot
}

# Helper: construct a single-element theme() call with dynamic name
.theme_el <- function(el, val) {
  args <- list(val)
  names(args) <- el
  do.call(ggplot2::theme, args)
}
# Helper: construct a single-element labs() call with dynamic name
.labs_el <- function(a, val) {
  args <- list(val)
  names(args) <- a
  do.call(ggplot2::labs, args)
}

# Collect all aesthetic names from global + layer-level mappings
.collect_aes_names <- function(gg, candidates) {
  unique(c(
    intersect(names(gg$mapping), candidates),
    unlist(lapply(gg$layers, function(l) {
      if (is.null(l$mapping)) {
        character(0)
      } else {
        intersect(names(l$mapping), candidates)
      }
    }))
  ))
}

# Set legend scale name + labels for a single aesthetic.
.label_set_aes <- function(gg, a, text, hide) {
  if (hide) {
    labs <- gg$labels
    labs[a] <- NULL
    gg$labels <- labs
    final_name <- NULL
  } else if (is.null(text)) {
    labs <- gg$labels
    labs[a] <- NULL
    gg$labels <- labs
    final_name <- ggplot2::waiver()
  } else {
    gg <- gg + .labs_el(a, text)
    final_name <- text
  }
  for (s in gg$scales$scales) {
    if (any(s$aesthetics == a)) {
      s$name <- final_name
      break
    }
  }
  gg
}

# ---- label_title ----
#' Generic for setting plot title
#' @param plot A plotit object
#' @param text Title text. `NULL` = don't modify. `"str"` = custom title.
#' @param hide If `TRUE`, remove title element from layout entirely.
#' @param reset If `TRUE`, remove the title text (restore to no title).
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
#' @param text Subtitle text. `NULL` = don't modify. `"str"` = custom subtitle.
#' @param hide If `TRUE`, remove subtitle element from layout entirely.
#' @param reset If `TRUE`, remove the subtitle text (restore to no subtitle).
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
#' @param text Caption text. `NULL` = don't modify. `"str"` = custom caption.
#' @param hide If `TRUE`, remove caption element from layout entirely.
#' @param reset If `TRUE`, remove the caption text (restore to no caption).
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
#' @param text Axis title text. `NULL` = don't modify. `"str"` = custom title.
#' @param aes Which axis to apply to: `"x"` or `"y"` (required).
#' @param hide If `TRUE`, hide the axis title entirely (`element_blank()`).
#' @param reset If `TRUE`, restore the axis title to the variable name.
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
    plot@gg <- plot@gg + .theme_el(paste0("axis.title.", aes), ggplot2::element_blank())
  } else if (isTRUE(reset)) {
    S7::prop(plot@meta@labels, aes) <- NULL
    plot@gg <- plot@gg + .theme_el(paste0("axis.title.", aes), NULL)
    labs <- plot@gg$labels
    labs[aes] <- NULL
    plot@gg$labels <- labs
  } else if (!is.null(text)) {
    S7::prop(plot@meta@labels, aes) <- text
    plot@gg <- plot@gg + .theme_el(paste0("axis.title.", aes), NULL)
    plot@gg <- plot@gg + .labs_el(aes, text)
  }
  plot
}

# ---- label_legend ----
#' Generic for setting legend title(s)
#' @param plot A plotit object
#' @param text Legend title text. `NULL` = don't modify. `"str"` = custom title.
#' @param aes Aesthetic to apply to (e.g. `"colour"`, `"fill"`). `NULL` = all mapped aesthetics.
#' @param hide If `TRUE`, hide the legend title.
#' @param reset If `TRUE`, restore the legend title to the variable name.
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
  # Determine the effective text: NULL=skip, reset=waiver, otherwise custom
  eff_text <- if (isTRUE(reset)) ggplot2::waiver() else text
  # Skip if nothing to do (all defaults)
  if (is.null(eff_text) && !isTRUE(hide)) return(plot)
  if (is.null(aes)) {
    plot@meta@labels@legend[["default"]] <- if (hide) NULL else eff_text
    aes_names <- .collect_aes_names(
      plot@gg,
      c("colour", "fill", "shape", "linetype", "size", "alpha")
    )
    for (a in aes_names) {
      plot@gg <- .label_set_aes(plot@gg, a, eff_text, hide)
    }
  } else {
    plot@meta@labels@legend[[aes]] <- if (hide) NULL else eff_text
    aes_all <- .collect_aes_names(
      plot@gg,
      c("colour", "fill", "shape", "linetype", "size", "alpha")
    )
    if (!(aes %in% aes_all)) {
      cli::cli_warn("Aesthetic {.val {aes}} is not present in the plot mapping.")
    } else {
      plot@gg <- .label_set_aes(plot@gg, aes, eff_text, hide)
    }
  }
  plot
}
