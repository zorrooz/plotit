#' @include class.R
NULL

# ---- Internal helpers for label family ----
# text + hide protocol: NULL=reset, "str"=custom, hide=TRUE=element_blank

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
#' @param text Title text. `NULL` = remove title, `"str"` = custom title.
#' @param hide If `TRUE`, remove title element from layout entirely.
#' @param ... Currently unused
#' @return Modified plotit object
#' @export
label_title <- S7::new_generic(
  "label_title",
  "plot",
  function(plot, text = NULL, hide = FALSE, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(label_title, plotit_class) <- function(plot, text = NULL, hide = FALSE, ...) {
  if (hide) {
    plot@meta@labels@title <- NULL
    plot@gg <- plot@gg + ggplot2::theme(plot.title = ggplot2::element_blank())
  } else if (is.null(text)) {
    plot@meta@labels@title <- NULL
    plot@gg <- plot@gg + ggplot2::labs(title = NULL)
  } else {
    plot@meta@labels@title <- text
    plot@gg <- plot@gg + ggplot2::labs(title = text)
  }
  plot
}

# ---- label_subtitle ----
#' Generic for setting plot subtitle
#' @param plot A plotit object
#' @param text Subtitle text. `NULL` = remove subtitle, `"str"` = custom subtitle.
#' @param hide If `TRUE`, remove subtitle element from layout entirely.
#' @param ... Currently unused
#' @return Modified plotit object
#' @export
label_subtitle <- S7::new_generic(
  "label_subtitle",
  "plot",
  function(plot, text = NULL, hide = FALSE, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(label_subtitle, plotit_class) <- function(plot, text = NULL, hide = FALSE, ...) {
  if (hide) {
    plot@meta@labels@subtitle <- NULL
    plot@gg <- plot@gg + ggplot2::theme(plot.subtitle = ggplot2::element_blank())
  } else if (is.null(text)) {
    plot@meta@labels@subtitle <- NULL
    plot@gg <- plot@gg + ggplot2::labs(subtitle = NULL)
  } else {
    plot@meta@labels@subtitle <- text
    plot@gg <- plot@gg + ggplot2::labs(subtitle = text)
  }
  plot
}

# ---- label_caption ----
#' Generic for setting plot caption
#' @param plot A plotit object
#' @param text Caption text. `NULL` = remove caption, `"str"` = custom caption.
#' @param hide If `TRUE`, remove caption element from layout entirely.
#' @param ... Currently unused
#' @return Modified plotit object
#' @export
label_caption <- S7::new_generic(
  "label_caption",
  "plot",
  function(plot, text = NULL, hide = FALSE, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(label_caption, plotit_class) <- function(plot, text = NULL, hide = FALSE, ...) {
  if (hide) {
    plot@meta@labels@caption <- NULL
    plot@gg <- plot@gg + ggplot2::theme(plot.caption = ggplot2::element_blank())
  } else if (is.null(text)) {
    plot@meta@labels@caption <- NULL
    plot@gg <- plot@gg + ggplot2::labs(caption = NULL)
  } else {
    plot@meta@labels@caption <- text
    plot@gg <- plot@gg + ggplot2::labs(caption = text)
  }
  plot
}

# ---- label_axis ----
#' Generic for setting axis titles
#' @param plot A plotit object
#' @param text Axis title text. `NULL` = restore variable name, `"str"` = custom title.
#' @param aes Which axis to apply to: `"x"` or `"y"` (required).
#' @param hide If `TRUE`, hide the axis title entirely (`element_blank()`).
#' @param ... Currently unused
#' @return Modified plotit object
#' @export
label_axis <- S7::new_generic(
  "label_axis",
  "plot",
  function(plot, text = NULL, aes = NULL, hide = FALSE, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(label_axis, plotit_class) <- function(plot, text = NULL, aes = NULL,
                                                 hide = FALSE, ...) {
  if (is.null(aes)) {
    cli::cli_abort("{.arg aes} must be specified: {.code aes = \"x\"} or {.code aes = \"y\"}.")
  }
  if (!(aes %in% c("x", "y"))) {
    cli::cli_abort("{.arg aes} must be one of {.val c('x', 'y')}, not {.val {aes}}.")
  }

  if (hide) {
    S7::prop(plot@meta@labels, aes) <- FALSE
    plot@gg <- plot@gg + .theme_el(paste0("axis.title.", aes), ggplot2::element_blank())
  } else if (is.null(text)) {
    S7::prop(plot@meta@labels, aes) <- NULL
    plot@gg <- plot@gg + .theme_el(paste0("axis.title.", aes), NULL)
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
#' @param text Legend title text. `NULL` = restore variable name, `"str"` = custom title.
#' @param aes Aesthetic to apply to (e.g. `"colour"`, `"fill"`). `NULL` = all mapped aesthetics.
#' @param hide If `TRUE`, hide the legend title.
#' @param ... Currently unused
#' @return Modified plotit object
#' @export
label_legend <- S7::new_generic(
  "label_legend",
  "plot",
  function(plot, text = NULL, aes = NULL, hide = FALSE, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(label_legend, plotit_class) <- function(plot, text = NULL, aes = NULL,
                                                   hide = FALSE, ...) {
  if (is.null(aes)) {
    plot@meta@labels@legend[["default"]] <- if (hide) NULL else text
    aes_names <- .collect_aes_names(
      plot@gg,
      c("colour", "fill", "shape", "linetype", "size", "alpha")
    )
    for (a in aes_names) {
      plot@gg <- .label_set_aes(plot@gg, a, text, hide)
    }
  } else {
    plot@meta@labels@legend[[aes]] <- if (hide) NULL else text
    aes_all <- .collect_aes_names(
      plot@gg,
      c("colour", "fill", "shape", "linetype", "size", "alpha")
    )
    if (!(aes %in% aes_all)) {
      cli::cli_warn("Aesthetic {.val {aes}} is not present in the plot mapping.")
    } else {
      plot@gg <- .label_set_aes(plot@gg, aes, text, hide)
    }
  }
  plot
}
