#' @include class.R utils.R
NULL

# ---- Internal helpers ----

# 撤销 plot() 中因 default_color 注入的 I(color) 和 guides(colour = "none")
.reset_default_color <- function(plot) {
  if (is.null(plot@meta@default_color)) return(plot)
  plot@gg$mapping$colour <- NULL
  plot@gg <- plot@gg + ggplot2::guides(colour = ggplot2::waiver())
  plot@meta@default_color <- NULL
  plot
}

# Auto-detect whether an aesthetic is discrete.
.detect_discrete_aes <- function(plot, aes_name) {
  var <- plot@gg$mapping[[aes_name]]
  if (!is.null(var)) return(is_discrete(plot@gg$data, var))
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
  TRUE
}

# Per-aesthetic trans validation sets
.trans_cf <- c("identity", "discrete", "reverse", "binned")  # colour/fill
.trans_n  <- c("identity", "discrete", "reverse", "binned")  # size/alpha (numeric)
.trans_sl <- c("discrete", "binned")                          # shape/linetype
.trans_xy <- c("identity", "discrete", "log", "log10", "log2", "sqrt", "reverse", "binned")

# Resolve trans=NULL: auto-detect; otherwise validate and return
.resolve_trans <- function(plot, aes_name, trans, allowed) {
  if (is.null(trans))
    return(if (.detect_discrete_aes(plot, aes_name)) "discrete" else "identity")
  if (!(trans %in% allowed)) {
    cli::cli_abort(c(
      "{.arg trans} must be one of {.val {allowed}} for this scale.",
      "x" = "Got {.val {trans}}."
    ))
  }
  trans
}

# Pick the right scale function for colour/fill given trans + range
.scale_colour_fun <- function(aes, trans, range, ...) {
  discrete <- trans == "discrete"
  binned   <- trans == "binned"
  reverse  <- trans == "reverse"

  if (is.character(range) && length(range) >= 2) {
    # 离散 + 颜色值 → 手动映射；连续/分箱 + 颜色值 → 渐变
    if (discrete) {
      if (aes == "colour") ggplot2::scale_colour_manual(values = range, ...)
      else                 ggplot2::scale_fill_manual(values = range, ...)
    } else {
      lo <- if (reverse) range[length(range)] else range[1]
      hi <- if (reverse) range[1] else range[length(range)]
      if (binned) {
        if (length(range) == 2) {
          if (aes == "colour") ggplot2::scale_colour_steps(low = lo, high = hi, ...)
          else                 ggplot2::scale_fill_steps(low = lo, high = hi, ...)
        } else {
          if (aes == "colour") ggplot2::scale_colour_steps2(low = lo, mid = range[2], high = hi, ...)
          else                 ggplot2::scale_fill_steps2(low = lo, mid = range[2], high = hi, ...)
        }
      } else {
        if (length(range) == 2) {
          if (aes == "colour") ggplot2::scale_colour_gradient(low = lo, high = hi, ...)
          else                 ggplot2::scale_fill_gradient(low = lo, high = hi, ...)
        } else {
          if (aes == "colour") ggplot2::scale_colour_gradient2(low = lo, mid = range[2], high = hi, ...)
          else                 ggplot2::scale_fill_gradient2(low = lo, mid = range[2], high = hi, ...)
        }
      }
    }
  } else {
    # scheme name or NULL default
    scheme <- range %||% if (binned) "viridis" else if (discrete) "hue" else "viridis"
    dir <- if (reverse) -1 else 1
    if (discrete) {
      switch(scheme,
        viridis = if (aes == "colour") ggplot2::scale_colour_viridis_d(direction = dir, ...)
                  else                 ggplot2::scale_fill_viridis_d(direction = dir, ...),
        brewer  = if (aes == "colour") ggplot2::scale_colour_brewer(direction = dir, ...)
                  else                 ggplot2::scale_fill_brewer(direction = dir, ...),
        grey    = if (aes == "colour") ggplot2::scale_colour_grey(...)
                  else                 ggplot2::scale_fill_grey(...),
        hue     = if (aes == "colour") ggplot2::scale_colour_discrete(direction = dir, ...)
                  else                 ggplot2::scale_fill_discrete(direction = dir, ...),
        cli::cli_abort("Unknown colour scheme: {.val {scheme}}.")
      )
    } else if (binned) {
      switch(scheme,
        viridis = if (aes == "colour") ggplot2::scale_colour_viridis_b(direction = dir, ...)
                  else                 ggplot2::scale_fill_viridis_b(direction = dir, ...),
        brewer  = if (aes == "colour") ggplot2::scale_colour_fermenter(direction = dir, ...)
                  else                 ggplot2::scale_fill_fermenter(direction = dir, ...),
        cli::cli_abort("Unknown colour scheme for binned: {.val {scheme}}.")
      )
    } else {
      switch(scheme,
        viridis = if (aes == "colour") ggplot2::scale_colour_viridis_c(direction = dir, ...)
                  else                 ggplot2::scale_fill_viridis_c(direction = dir, ...),
        brewer  = if (aes == "colour") ggplot2::scale_colour_distiller(direction = dir, ...)
                  else                 ggplot2::scale_fill_distiller(direction = dir, ...),
        cli::cli_abort("Unknown colour scheme for continuous: {.val {scheme}}.")
      )
    }
  }
}

# Pick size/alpha scale function
.scale_numeric_fun <- function(aes, trans, range, ...) {
  discrete <- trans == "discrete"
  binned   <- trans == "binned"
  reverse  <- trans == "reverse"

  if (binned) {
    fun <- switch(aes,
      size  = ggplot2::scale_size_binned,
      alpha = ggplot2::scale_alpha_binned
    )
  } else if (discrete) {
    fun <- switch(aes,
      size  = ggplot2::scale_size_discrete,
      alpha = ggplot2::scale_alpha_discrete
    )
  } else {
    fun <- switch(aes,
      size  = ggplot2::scale_size_continuous,
      alpha = ggplot2::scale_alpha_continuous
    )
  }
  args <- list(...)
  if (!is.null(range) && !binned && !discrete) args$range <- range
  if (reverse && !discrete) args$trans <- "reverse"
  do.call(fun, args)
}

# Pick shape/linetype scale function
.scale_discrete_fun <- function(aes, trans, range, ...) {
  binned <- trans == "binned"
  if (binned) {
    fun <- switch(aes,
      shape    = ggplot2::scale_shape_binned,
      linetype = ggplot2::scale_linetype_binned
    )
  } else {
    fun <- switch(aes,
      shape    = ggplot2::scale_shape_discrete,
      linetype = ggplot2::scale_linetype_discrete
    )
  }
  args <- list(...)
  if (!is.null(range) && !binned) {
    if (aes == "shape") {
      # shape range → scale_shape_manual(values = range); 仅非 binned 时生效
      args$values <- range
      fun <- ggplot2::scale_shape_manual
    } else {
      args$values <- range
      fun <- ggplot2::scale_linetype_manual
    }
  }
  do.call(fun, args)
}

# Build args list for scale_x/y
.scale_xy_impl <- function(plot, aes, name, trans, limits, range, breaks, labels, ...) {
  discrete <- trans == "discrete"
  binned   <- trans == "binned"
  scale_fun <- if (aes == "x") {
    if (binned)  ggplot2::scale_x_binned
    else if (discrete) ggplot2::scale_x_discrete
    else         ggplot2::scale_x_continuous
  } else {
    if (binned)  ggplot2::scale_y_binned
    else if (discrete) ggplot2::scale_y_discrete
    else         ggplot2::scale_y_continuous
  }
  args <- list(name = name, limits = limits, breaks = breaks, labels = labels)
  # range 对 x/y 无意义（ggplot2 无 pixel range 概念），忽略
  if (!discrete && !binned) args$trans <- trans
  args <- args[!vapply(args, is.null, logical(1))]
  plot@gg <- plot@gg + do.call(scale_fun, c(args, list(...)))
  plot
}

# ---- scale_color ----
#' @export
scale_color <- S7::new_generic(
  "scale_color", "plot",
  function(plot, name = ggplot2::waiver(), trans = NULL,
           limits = NULL, range = NULL, breaks = NULL, labels = NULL, ...) S7::S7_dispatch()
)

#' @export
S7::method(scale_color, plotit_class) <- function(plot, name = ggplot2::waiver(),
                                                   trans = NULL, limits = NULL,
                                                   range = NULL, breaks = NULL,
                                                   labels = NULL, ...) {
  plot <- .reset_default_color(plot)
  trans <- .resolve_trans(plot, "colour", trans, .trans_cf)
  plot@gg <- plot@gg +
    .scale_colour_fun("colour", trans, range,
                       name = name, limits = limits, breaks = breaks, labels = labels, ...)
  plot
}

# ---- scale_fill ----
#' @export
scale_fill <- S7::new_generic(
  "scale_fill", "plot",
  function(plot, name = ggplot2::waiver(), trans = NULL,
           limits = NULL, range = NULL, breaks = NULL, labels = NULL, ...) S7::S7_dispatch()
)

#' @export
S7::method(scale_fill, plotit_class) <- function(plot, name = ggplot2::waiver(),
                                                  trans = NULL, limits = NULL,
                                                  range = NULL, breaks = NULL,
                                                  labels = NULL, ...) {
  plot <- .reset_default_color(plot)
  trans <- .resolve_trans(plot, "fill", trans, .trans_cf)
  plot@gg <- plot@gg +
    .scale_colour_fun("fill", trans, range,
                       name = name, limits = limits, breaks = breaks, labels = labels, ...)
  plot
}

# ---- scale_size ----
#' @export
scale_size <- S7::new_generic(
  "scale_size", "plot",
  function(plot, name = ggplot2::waiver(), trans = NULL,
           limits = NULL, range = NULL, breaks = NULL, labels = NULL, ...) S7::S7_dispatch()
)

#' @export
S7::method(scale_size, plotit_class) <- function(plot, name = ggplot2::waiver(),
                                                  trans = NULL, limits = NULL,
                                                  range = NULL, breaks = NULL,
                                                  labels = NULL, ...) {
  trans <- .resolve_trans(plot, "size", trans, .trans_n)
  plot@gg <- plot@gg +
    .scale_numeric_fun("size", trans, range,
                        name = name, limits = limits, breaks = breaks, labels = labels, ...)
  plot
}

# ---- scale_alpha ----
#' @export
scale_alpha <- S7::new_generic(
  "scale_alpha", "plot",
  function(plot, name = ggplot2::waiver(), trans = NULL,
           limits = NULL, range = NULL, breaks = NULL, labels = NULL, ...) S7::S7_dispatch()
)

#' @export
S7::method(scale_alpha, plotit_class) <- function(plot, name = ggplot2::waiver(),
                                                   trans = NULL, limits = NULL,
                                                   range = NULL, breaks = NULL,
                                                   labels = NULL, ...) {
  trans <- .resolve_trans(plot, "alpha", trans, .trans_n)
  plot@gg <- plot@gg +
    .scale_numeric_fun("alpha", trans, range,
                        name = name, limits = limits, breaks = breaks, labels = labels, ...)
  plot
}

# ---- scale_shape ----
#' @export
scale_shape <- S7::new_generic(
  "scale_shape", "plot",
  function(plot, name = ggplot2::waiver(), trans = "discrete",
           limits = NULL, range = NULL, breaks = NULL, labels = NULL, ...) S7::S7_dispatch()
)

#' @export
S7::method(scale_shape, plotit_class) <- function(plot, name = ggplot2::waiver(),
                                                   trans = "discrete", limits = NULL,
                                                   range = NULL, breaks = NULL,
                                                   labels = NULL, ...) {
  trans <- .resolve_trans(plot, "shape", trans, .trans_sl)
  if (trans == "identity") cli::cli_abort(c(
    "A continuous variable cannot be mapped to shape.",
    "i" = "Use {.code trans = \"binned\"} to discretize a continuous variable."
  ))
  plot@gg <- plot@gg +
    .scale_discrete_fun("shape", trans, range,
                         name = name, limits = limits, breaks = breaks, labels = labels, ...)
  plot
}

# ---- scale_linetype ----
#' @export
scale_linetype <- S7::new_generic(
  "scale_linetype", "plot",
  function(plot, name = ggplot2::waiver(), trans = "discrete",
           limits = NULL, range = NULL, breaks = NULL, labels = NULL, ...) S7::S7_dispatch()
)

#' @export
S7::method(scale_linetype, plotit_class) <- function(plot, name = ggplot2::waiver(),
                                                      trans = "discrete", limits = NULL,
                                                      range = NULL, breaks = NULL,
                                                      labels = NULL, ...) {
  trans <- .resolve_trans(plot, "linetype", trans, .trans_sl)
  if (trans == "identity") cli::cli_abort(c(
    "A continuous variable cannot be mapped to linetype.",
    "i" = "Use {.code trans = \"binned\"} to discretize a continuous variable."
  ))
  plot@gg <- plot@gg +
    .scale_discrete_fun("linetype", trans, range,
                         name = name, limits = limits, breaks = breaks, labels = labels, ...)
  plot
}

# ---- scale_x ----
#' @export
scale_x <- S7::new_generic(
  "scale_x", "plot",
  function(plot, name = ggplot2::waiver(), trans = "identity",
           limits = NULL, range = NULL, breaks = NULL, labels = NULL, ...) S7::S7_dispatch()
)

#' @export
S7::method(scale_x, plotit_class) <- function(plot, name = ggplot2::waiver(),
                                              trans = "identity", limits = NULL,
                                              range = NULL, breaks = NULL,
                                              labels = NULL, ...) {
  trans <- .resolve_trans(plot, "x", trans, .trans_xy)
  .scale_xy_impl(plot, "x", name, trans, limits, range, breaks, labels, ...)
}

# ---- scale_y ----
#' @export
scale_y <- S7::new_generic(
  "scale_y", "plot",
  function(plot, name = ggplot2::waiver(), trans = "identity",
           limits = NULL, range = NULL, breaks = NULL, labels = NULL, ...) S7::S7_dispatch()
)

#' @export
S7::method(scale_y, plotit_class) <- function(plot, name = ggplot2::waiver(),
                                              trans = "identity", limits = NULL,
                                              range = NULL, breaks = NULL,
                                              labels = NULL, ...) {
  trans <- .resolve_trans(plot, "y", trans, .trans_xy)
  .scale_xy_impl(plot, "y", name, trans, limits, range, breaks, labels, ...)
}
