#' @include class.R utils.R
NULL

# ---- Internal helpers ----

# 撤销 plot() 中因 default_color 注入的 I(color) 和 guides(colour = "none")
# plot@gg$mapping 是 ?ggplot 文档中公开的可访问字段
.reset_default_color <- function(plot) {
  if (is.null(plot@meta@default_color)) return(plot)
  plot@gg$mapping$colour <- NULL
  plot@gg <- plot@gg + ggplot2::guides(colour = ggplot2::waiver())
  plot@meta@default_color <- NULL
  plot
}

# Auto-detect whether an aesthetic (e.g. "colour", "fill") is discrete.
# Searches global mapping first, then layer-level mappings.
.detect_discrete_aes <- function(plot, aes_name) {
  # 1) global mapping
  var <- plot@gg$mapping[[aes_name]]
  if (!is.null(var)) {
    return(is_discrete(plot@gg$data, var))
  }
  # 2) layer-level mappings
  for (layer in plot@gg$layers) {
    lmap <- layer$mapping
    if (is.null(lmap)) next
    var <- lmap[[aes_name]]
    if (!is.null(var)) {
      data <- layer$data
      if (is.null(data)) data <- plot@gg$data
      return(is_discrete(data, var))
    }
  }
  # 3) not found anywhere — assume discrete (safe fallback for most uses)
  TRUE
}

# Shared implementation for scale_x / scale_y
.scale_axis_impl <- function(plot, aes, name, discrete, trans, limits, breaks, ...) {
  if (is.null(discrete)) {
    discrete <- is_discrete(plot@gg$data, plot@gg$mapping[[aes]])
  }
  scale_fun <- if (aes == "x") {
    if (discrete) ggplot2::scale_x_discrete else ggplot2::scale_x_continuous
  } else {
    if (discrete) ggplot2::scale_y_discrete else ggplot2::scale_y_continuous
  }
  args <- list(name = name, limits = limits, breaks = breaks)
  if (!discrete) {
    args$trans <- trans
  }
  args <- args[!vapply(args, is.null, logical(1))]
  plot@gg <- plot@gg + do.call(scale_fun, c(args, list(...)))
  plot
}

# ---- scale_color ----
#' Generic for adding a color scale
#'
#' Auto-detects whether the mapped variable is discrete or continuous and
#' dispatches to the appropriate ggplot2 scale (discrete → default hue palette;
#' continuous → viridis).
#'
#' @param plot A plotit object
#' @param name Legend title for color aesthetic
#' @param ... Other arguments passed to the appropriate color scale
#' @return Modified plotit object
#' @export
scale_color <- S7::new_generic(
  "scale_color",
  "plot",
  function(plot, name = ggplot2::waiver(), ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(scale_color, plotit_class) <- function(plot, name = ggplot2::waiver(), ...) {
  plot <- .reset_default_color(plot)
  if (.detect_discrete_aes(plot, "colour")) {
    plot@gg <- plot@gg +
      ggplot2::scale_color_discrete(name = name, ...)
  } else {
    plot@gg <- plot@gg +
      ggplot2::scale_color_viridis_c(name = name, ...)
  }
  plot
}

# ---- scale_fill ----
#' Generic for adding a fill scale
#'
#' Auto-detects whether the mapped variable is discrete or continuous and
#' dispatches to the appropriate ggplot2 scale (discrete → default hue palette;
#' continuous → viridis).
#'
#' @param plot A plotit object
#' @param name Legend title for fill aesthetic
#' @param ... Other arguments passed to the appropriate fill scale
#' @return Modified plotit object
#' @export
scale_fill <- S7::new_generic(
  "scale_fill",
  "plot",
  function(plot, name = ggplot2::waiver(), ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(scale_fill, plotit_class) <- function(plot, name = ggplot2::waiver(), ...) {
  plot <- .reset_default_color(plot)
  if (.detect_discrete_aes(plot, "fill")) {
    plot@gg <- plot@gg +
      ggplot2::scale_fill_discrete(name = name, ...)
  } else {
    plot@gg <- plot@gg +
      ggplot2::scale_fill_viridis_c(name = name, ...)
  }
  plot
}

# ---- scale_x ----
#' Generic for setting x-axis scale
#'
#' @param plot A plotit object
#' @param name Axis title (use [label_axis()] for more control)
#' @param discrete If `TRUE`, use discrete scale; if `FALSE`, use continuous.
#'   If `NULL`, auto-detected from data type.
#' @param trans Transformation to apply (e.g. "log10", "sqrt", "reverse").
#'   Only used when `discrete = FALSE`.
#' @param limits Axis limits
#' @param breaks Axis break positions
#' @param ... Other arguments passed to `scale_x_continuous` or `scale_x_discrete`
#' @return Modified plotit object
#' @export
scale_x <- S7::new_generic(
  "scale_x",
  "plot",
  function(plot, name = ggplot2::waiver(), discrete = NULL, trans = NULL,
           limits = NULL, breaks = NULL, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(scale_x, plotit_class) <- function(plot, name = ggplot2::waiver(),
                                              discrete = NULL, trans = NULL,
                                              limits = NULL, breaks = NULL, ...) {
  .scale_axis_impl(plot, "x", name, discrete, trans, limits, breaks, ...)
}

# ---- scale_y ----
#' Generic for setting y-axis scale
#'
#' @param plot A plotit object
#' @param name Axis title (use [label_axis()] for more control)
#' @param discrete If `TRUE`, use discrete scale; if `FALSE`, use continuous.
#'   If `NULL`, auto-detected from data type.
#' @param trans Transformation to apply (e.g. "log10", "sqrt", "reverse").
#'   Only used when `discrete = FALSE`.
#' @param limits Axis limits
#' @param breaks Axis break positions
#' @param ... Other arguments passed to `scale_y_continuous` or `scale_y_discrete`
#' @return Modified plotit object
#' @export
scale_y <- S7::new_generic(
  "scale_y",
  "plot",
  function(plot, name = ggplot2::waiver(), discrete = NULL, trans = NULL,
           limits = NULL, breaks = NULL, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(scale_y, plotit_class) <- function(plot, name = ggplot2::waiver(),
                                              discrete = NULL, trans = NULL,
                                              limits = NULL, breaks = NULL, ...) {
  .scale_axis_impl(plot, "y", name, discrete, trans, limits, breaks, ...)
}