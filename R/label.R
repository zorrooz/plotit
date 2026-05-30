#' Generic for setting plot title
#'
#' @include class.R
#' @param plot A plotit object
#' @param text Title text
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
  plot@meta@labels@title <- text
  plot@gg <- plot@gg + ggplot2::labs(title = plot@meta@labels@title)
  plot
}

#' Generic for setting axis titles
#'
#' @include class.R
#' @param plot A plotit object
#' @param x X-axis title (character)
#' @param y Y-axis title (character)
#' @param ... Currently unused
#' @return Modified plotit object
#' @export
label_axis <- S7::new_generic(
  "label_axis",
  "plot",
  function(plot, x = NULL, y = NULL, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(label_axis, plotit_class) <- function(plot, x = NULL, y = NULL, ...) {
  args <- list()
  if (!is.null(x)) {
    plot@meta@labels@x <- x
    args$x <- x
  }
  if (!is.null(y)) {
    plot@meta@labels@y <- y
    args$y <- y
  }
  if (length(args) > 0) {
    plot@gg <- plot@gg + do.call(ggplot2::labs, args)
  }
  plot
}

#' Generic for setting plot subtitle
#'
#' @include class.R
#' @param plot A plotit object
#' @param text Subtitle text
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
  plot@meta@labels@subtitle <- text
  plot@gg <- plot@gg + ggplot2::labs(subtitle = plot@meta@labels@subtitle)
  plot
}

#' Generic for setting plot caption
#'
#' @include class.R
#' @param plot A plotit object
#' @param text Caption text
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
  plot@meta@labels@caption <- text
  plot@gg <- plot@gg + ggplot2::labs(caption = plot@meta@labels@caption)
  plot
}

#' Generic for setting legend title(s)
#'
#' @include class.R
#' @param plot A plotit object
#' @param title Legend title text
#' @param aesthetic Aesthetic to apply the title to (e.g. "colour", "fill").
#'   If `NULL`, applies to all currently mapped aesthetics.
#' @param ... Currently unused
#' @return Modified plotit object
#' @export
label_legend <- S7::new_generic(
  "label_legend",
  "plot",
  function(plot, title = NULL, aesthetic = NULL, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(label_legend, plotit_class) <- function(plot, title = NULL, aesthetic = NULL, ...) {
  if (is.null(aesthetic)) {
    plot@meta@labels@legend[["default"]] <- title
    # 遍历 gg 中所有已映射的离散美学，统一设置标题
    aesthetic_names <- intersect(
      names(plot@gg$mapping),
      c("colour", "color", "fill", "shape", "linetype", "size", "alpha")
    )
    if (length(aesthetic_names) > 0) {
      all_args <- stats::setNames(rep(list(title), length(aesthetic_names)), aesthetic_names)
      plot@gg <- plot@gg + do.call(ggplot2::labs, all_args)
    }
  } else {
    plot@meta@labels@legend[[aesthetic]] <- title
    labs_args <- stats::setNames(list(title), aesthetic)
    plot@gg <- plot@gg + do.call(ggplot2::labs, labs_args)
  }
  plot
}
