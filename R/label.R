#' @include class.R
NULL

# ---- Internal helpers for label family ----
# Four-state protocol for all text parameters:
#   NULL  = skip (no change)
#   FALSE = hide
#   TRUE  = show default
#   "str" = show custom text

#' @noRd
.label_skip <- function(x) is.null(x)
#' @noRd
.label_hide <- function(x) identical(x, FALSE)
#' @noRd
.label_default <- function(x) isTRUE(x)

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

# ---- label_title ----
#' Generic for setting plot title
#' @param plot A plotit object
#' @param text Title text. `NULL` = skip, `FALSE` = hide, `TRUE` = default, `"str"` = custom
#' @param ... Currently unused
#' @return Modified plotit object
#' @export
label_title <- S7::new_generic(
  "label_title",
  "plot",
  function(plot, text = NULL, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(label_title, plotit_class) <- function(plot, text = NULL, ...) {
  if (.label_skip(text)) return(plot)
  final <- if (.label_hide(text) || .label_default(text)) NULL else text
  plot@meta@labels@title <- final
  plot@gg <- plot@gg + ggplot2::labs(title = final)
  plot
}

# ---- label_subtitle ----
#' Generic for setting plot subtitle
#' @param plot A plotit object
#' @param text Subtitle text. `NULL` = skip, `FALSE` = hide, `TRUE` = default, `"str"` = custom
#' @param ... Currently unused
#' @return Modified plotit object
#' @export
label_subtitle <- S7::new_generic(
  "label_subtitle",
  "plot",
  function(plot, text = NULL, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(label_subtitle, plotit_class) <- function(plot, text = NULL, ...) {
  if (.label_skip(text)) return(plot)
  final <- if (.label_hide(text) || .label_default(text)) NULL else text
  plot@meta@labels@subtitle <- final
  plot@gg <- plot@gg + ggplot2::labs(subtitle = final)
  plot
}

# ---- label_caption ----
#' Generic for setting plot caption
#' @param plot A plotit object
#' @param text Caption text. `NULL` = skip, `FALSE` = hide, `TRUE` = default, `"str"` = custom
#' @param ... Currently unused
#' @return Modified plotit object
#' @export
label_caption <- S7::new_generic(
  "label_caption",
  "plot",
  function(plot, text = NULL, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(label_caption, plotit_class) <- function(plot, text = NULL, ...) {
  if (.label_skip(text)) return(plot)
  final <- if (.label_hide(text) || .label_default(text)) NULL else text
  plot@meta@labels@caption <- final
  plot@gg <- plot@gg + ggplot2::labs(caption = final)
  plot
}

# ---- label_axis ----
#' Generic for setting axis titles
#' @param plot A plotit object
#' @param text Axis title text. `NULL` = skip, `FALSE` = hide, `TRUE` = variable name, `"str"` = custom
#' @param aes Which axis to apply to: `"x"` or `"y"` (required).
#' @param ... Currently unused
#' @return Modified plotit object
#' @export
label_axis <- S7::new_generic(
  "label_axis",
  "plot",
  function(plot, text = NULL, aes = NULL, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(label_axis, plotit_class) <- function(plot, text = NULL, aes = NULL, ...) {
  if (.label_skip(text)) return(plot)
  if (is.null(aes)) {
    cli::cli_abort("{.arg aes} must be specified: {.code aes = \"x\"} or {.code aes = \"y\"}.")
  }

  if (.label_hide(text)) {
    S7::prop(plot@meta@labels, aes) <- NULL
    plot@gg <- plot@gg + .theme_el(paste0("axis.title.", aes), ggplot2::element_blank())
  } else if (.label_default(text)) {
    S7::prop(plot@meta@labels, aes) <- NULL
    plot@gg <- plot@gg + .theme_el(paste0("axis.title.", aes), NULL)
    # Rebuild labels without this aesthetic key so setup_plot_labels()
    # falls back to the mapping variable name
    labs <- plot@gg$labels
    labs[aes] <- NULL
    plot@gg$labels <- labs
  } else {
    S7::prop(plot@meta@labels, aes) <- text
    plot@gg <- plot@gg + .theme_el(paste0("axis.title.", aes), NULL)
    plot@gg <- plot@gg + .labs_el(aes, text)
  }
  plot
}

# ---- label_legend ----
#' Generic for setting legend title(s)
#' @param plot A plotit object
#' @param text Legend title text. `NULL` = skip, `FALSE` = hide, `TRUE` = variable name, `"str"` = custom
#' @param aes Aesthetic to apply to (e.g. `"colour"`, `"fill"`). `NULL` = all mapped aesthetics.
#' @param ... Currently unused
#' @return Modified plotit object
#' @export
label_legend <- S7::new_generic(
  "label_legend",
  "plot",
  function(plot, text = NULL, aes = NULL, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(label_legend, plotit_class) <- function(plot, text = NULL, aes = NULL, ...) {
  if (.label_skip(text)) return(plot)

  .set_aes <- function(plot, a, val) {
    if (.label_default(val)) {
      # Rebuild labels without this aesthetic key so setup_plot_labels()
      # falls back to the mapping variable name
      labs <- plot@gg$labels
      labs[a] <- NULL
      plot@gg$labels <- labs
      final_name <- ggplot2::waiver()
    } else {
      labs_val <- if (.label_hide(val)) NULL else val
      labs_args <- list(labs_val)
      names(labs_args) <- a
      plot@gg <- plot@gg + do.call(ggplot2::labs, labs_args)
      final_name <- labs_val
    }
    for (s in plot@gg$scales$scales) {
      if (any(s$aesthetics == a)) {
        s$name <- final_name
        break
      }
    }
    plot
  }

  if (is.null(aes)) {
    plot@meta@labels@legend[["default"]] <- if (.label_hide(text) || .label_default(text)) NULL else text
    aes_names <- intersect(
      names(plot@gg$mapping),
      c("colour", "color", "fill", "shape", "linetype", "size", "alpha")
    )
    for (a in aes_names) {
      plot <- .set_aes(plot, a, text)
    }
  } else {
    plot@meta@labels@legend[[aes]] <- if (.label_hide(text) || .label_default(text)) NULL else text
    plot <- .set_aes(plot, aes, text)
  }
  plot
}
