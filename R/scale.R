#' @include class.R utils.R
NULL

# ---- Internal helpers ----

._detect_discrete_aes <- function(plot, aes_name) {
  var <- plot@gg$mapping[[aes_name]]
  if (!is.null(var)) {
    return(is_discrete(plot@gg$data, var))
  }
  # Only check global mapping (AGENTS.md 4.6: gg$layers is internal).
  TRUE
}

# When trans="reverse" and the mapped variable is discrete, route to
# the discrete scale instead of attempting a continuous reverse scale
# which breaks on factors.  Returns a list(trans, force_reverse).
#' Route trans="reverse" to discrete scale when variable is discrete.
#' @noRd
#' @keywords internal
._resolve_reverse_discrete <- function(plot, aes_name, trans) {
  if (identical(trans, "reverse") && ._detect_discrete_aes(plot, aes_name)) {
    list(trans = "discrete", force_reverse = TRUE)
  } else {
    list(trans = trans, force_reverse = FALSE)
  }
}

# Per-aesthetic trans validation sets
._TRANS_CONT <- c("identity", "discrete", "reverse", "binned") # colour/fill/size/alpha (visual_cont)
._TRANS_SL <- c("discrete", "reverse") # shape/linetype (visual_disc)
._TRANS_XY <- c("identity", "discrete", "log", "log10", "log2", "sqrt", "reverse", "binned") # positional

# Friendly error messages for known-bad trans x aesthetic combinations.
# Called before the generic allowed-set check so the user gets a targeted
# explanation instead of a generic "must be one of ..." message.
#' Validate trans parameter for a given aesthetic.
#' @noRd
#' @keywords internal
._validate_trans <- function(aes_name, trans, allowed) {
  visual_aes <- c("colour", "fill", "size", "alpha", "shape", "linetype")
  # log / sqrt on visual aesthetics
  if (aes_name %in% visual_aes && trans %in% c("log", "log10", "log2", "sqrt")) {
    cli::cli_abort(c(
      "{.val {aes_name}} is a visual aesthetic; log/sqrt transformations are not applicable.",
      "i" = "Use {.fn scale_x} / {.fn scale_y} for positional log transforms.",
      "i" = "{.arg trans} for visual scales supports: {.val {allowed}}."
    ))
  }
  # identity on shape/linetype
  if (aes_name %in% c("shape", "linetype") && trans == "identity") {
    cli::cli_abort(c(
      "{.val {aes_name}} is a discrete visual aesthetic;
       continuous mapping ({.code trans = \"identity\"}) is not supported.",
      "i" = "Use {.val 'discrete'} or {.val 'reverse'}."
    ))
  }
  # binned on shape/linetype
  if (aes_name %in% c("shape", "linetype") && trans == "binned") {
    cli::cli_abort(c(
      "{.val {aes_name}} is a discrete visual aesthetic; binned mapping ({.code trans = \"binned\"}) is not supported.",
      "i" = "{.arg trans} for shape/linetype supports: {.val {allowed}}."
    ))
  }
}

# Resolve trans=NULL: auto-detect; otherwise validate and return
._resolve_trans <- function(plot, aes_name, trans, allowed) {
  if (is.null(trans)) {
    return(if (._detect_discrete_aes(plot, aes_name)) "discrete" else "identity")
  }
  # Friendly error for known-bad combos (before generic allowed-set check)
  ._validate_trans(aes_name, trans, allowed)
  if (!(trans %in% allowed)) {
    cli::cli_abort(c(
      "{.arg trans} must be one of {.val {allowed}} for this scale.",
      "x" = "Got {.val {trans}}."
    ))
  }
  trans
}

# Pick colour or fill variant of a scale function (eliminates aes branching)
#' Pick colour or fill variant of a scale function.
#' @noRd
#' @keywords internal
._cf <- function(aes, fun_c, fun_f) {
  if (aes == "colour") fun_c else fun_f
}

# Scheme-based dispatch: viridis, brewer, grey, friendly, hue
#' Dispatch to colour/fill scale by scheme name.
#' @noRd
#' @keywords internal
._scale_scheme <- function(aes, scheme, discrete, binned, reverse, ...) {
  dir <- if (reverse) -1 else 1
  if (discrete) {
    switch(scheme,
      viridis = ._cf(aes, ggplot2::scale_colour_viridis_d, ggplot2::scale_fill_viridis_d)(direction = dir, ...),
      brewer = ._cf(aes, ggplot2::scale_colour_brewer, ggplot2::scale_fill_brewer)(direction = dir, ...),
      grey = ._cf(aes, ggplot2::scale_colour_grey, ggplot2::scale_fill_grey)(
        start = if (reverse) 0.8 else 0.2,
        end = if (reverse) 0.2 else 0.8,
        ...
      ),
      friendly = ggplot2::discrete_scale(
        aesthetics = aes,
        palette = if (reverse) {
          function(n) rev(._palette_discrete(n))
        } else {
          function(n) ._palette_discrete(n)
        },
        ...
      ),
      hue = ._cf(aes, ggplot2::scale_colour_discrete, ggplot2::scale_fill_discrete)(direction = dir, ...),
      cli::cli_abort("Unknown colour scheme: {.val {scheme}}.")
    )
  } else if (binned) {
    switch(scheme,
      viridis = ._cf(aes, ggplot2::scale_colour_viridis_b, ggplot2::scale_fill_viridis_b)(direction = dir, ...),
      brewer  = ._cf(aes, ggplot2::scale_colour_fermenter, ggplot2::scale_fill_fermenter)(direction = dir, ...),
      cli::cli_abort("Unknown colour scheme for binned: {.val {scheme}}.")
    )
  } else {
    switch(scheme,
      viridis = ._cf(aes, ggplot2::scale_colour_viridis_c, ggplot2::scale_fill_viridis_c)(direction = dir, ...),
      brewer  = ._cf(aes, ggplot2::scale_colour_distiller, ggplot2::scale_fill_distiller)(direction = dir, ...),
      cli::cli_abort("Unknown colour scheme for continuous: {.val {scheme}}.")
    )
  }
}

# Custom colour vector dispatch: manual, gradient, steps
#' Dispatch to colour/fill scale with custom colour vector.
#' @noRd
#' @keywords internal
._scale_custom <- function(aes, range, discrete, binned, reverse, ...) {
  if (discrete) {
    if (reverse) range <- rev(range)
    ._cf(aes, ggplot2::scale_colour_manual, ggplot2::scale_fill_manual)(values = range, ...)
  } else {
    lo <- if (reverse) range[length(range)] else range[1]
    hi <- if (reverse) range[1] else range[length(range)]
    if (binned) {
      if (length(range) == 2) {
        ._cf(aes, ggplot2::scale_colour_steps, ggplot2::scale_fill_steps)(low = lo, high = hi, ...)
      } else {
        ._cf(aes, ggplot2::scale_colour_steps2, ggplot2::scale_fill_steps2)(low = lo, mid = range[2], high = hi, ...)
      }
    } else {
      if (length(range) == 2) {
        ._cf(aes, ggplot2::scale_colour_gradient, ggplot2::scale_fill_gradient)(low = lo, high = hi, ...)
      } else {
        ._cf(aes, ggplot2::scale_colour_gradient2, ggplot2::scale_fill_gradient2)(
          low = lo, mid = range[2], high = hi, ...
        )
      }
    }
  }
}

# Internal helper: strip NULL entries from a list so that `breaks = NULL`
# and friends do not coerce downstream ggplot2 scales into guide = "none".
#' Strip NULL entries from a list.
#' @noRd
#' @keywords internal
._strip_nulls <- function(args) {
  args[!vapply(args, is.null, logical(1L))]
}

# Pick the right scale function for colour/fill given trans + range
._scale_colour_fun <- function(aes, trans, range, ..., force_reverse = FALSE) {
  discrete <- trans == "discrete"
  binned <- trans == "binned"
  reverse <- trans == "reverse" || force_reverse

  extra_args <- ._strip_nulls(list(...))

  if (is.character(range) && length(range) >= 2) {
    do.call(._scale_custom, c(list(aes, range, discrete, binned, reverse), extra_args))
  } else {
    scheme <- range %||% if (binned) "viridis" else if (discrete) "friendly" else "viridis"
    # Single color name -> helpful error instead of "unknown scheme"
    known_schemes <- c("viridis", "brewer", "grey", "friendly", "hue")
    single_unknown_scheme <- is.character(range) &&
      length(range) == 1 && !(scheme %in% known_schemes)
    if (single_unknown_scheme) {
      cli::cli_abort(c(
        "{.val {range}} is not a known colour scheme name.",
        "i" = "Use {.code range = c({range})} for a single custom colour,
        or one of: viridis, brewer, grey, friendly, hue."
      ))
    }
    do.call(._scale_scheme, c(list(aes, scheme, discrete, binned, reverse), extra_args))
  }
}

# Pick size/alpha scale function
._scale_numeric_fun <- function(aes, trans, range, ..., force_reverse = FALSE) {
  discrete <- trans == "discrete"
  binned <- trans == "binned"
  reverse <- trans == "reverse" || force_reverse

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
  args <- ._strip_nulls(list(...))
  # Explicit defaults per AGENTS.md 3.3.4
  if (is.null(range) && !binned && !discrete) {
    range <- switch(aes,
      size = c(1, 6),
      alpha = c(0.1, 1)
    )
  }
  if (!is.null(range) && !binned && !discrete) args$range <- range
  if (reverse && !discrete) args$trans <- "reverse"
  # Discrete + reverse: reverse the guide order (symmetry with ._scale_discrete_fun)
  if (reverse && discrete) args$guide <- ggplot2::guide_legend(reverse = TRUE)
  do.call(fun, args)
}

# Pick shape/linetype scale function
._scale_discrete_fun <- function(aes, trans, range, ...) {
  reverse <- trans == "reverse"
  args <- ._strip_nulls(list(...))
  if (reverse && !is.null(range)) range <- rev(range)
  if (!is.null(range)) {
    args$values <- range
    fun <- if (aes == "shape") ggplot2::scale_shape_manual else ggplot2::scale_linetype_manual
  } else {
    fun <- if (aes == "shape") ggplot2::scale_shape_discrete else ggplot2::scale_linetype_discrete
  }
  if (reverse) args$guide <- ggplot2::guide_legend(reverse = TRUE)
  do.call(fun, args)
}

# Build args list for scale_x/y
._scale_xy_impl <- function(plot, aes, name, trans, limits, range, breaks, labels, ...) {
  discrete <- trans == "discrete"
  reverse <- trans == "reverse"
  binned <- trans == "binned"

  # When trans="reverse" and the mapped variable is discrete, route to
  # the discrete scale with reversed level order instead of attempting
  # scale_x_continuous(trans="reverse") which breaks on factors.
  if (reverse && ._detect_discrete_aes(plot, aes)) {
    discrete <- TRUE
  }

  # range = normalized panel proportion (Vega-aligned, AGENTS.md 3.3.4)
  if (!is.null(range) && !discrete && !binned) {
    if (!is.null(limits)) {
      cli::cli_warn(c(
        "Both {.arg range} and {.arg limits} are set for the {.val {aes}} axis.",
        "i" = "{.arg range} takes precedence; {.arg limits} is ignored."
      ))
    }
    # Compute expanded limits so the data occupies the specified panel proportion
    data <- plot@gg$data
    var <- plot@gg$mapping[[aes]]
    if (!is.null(data) && !is.null(var)) {
      vals <- rlang::eval_tidy(var, data)
      rng <- range(vals, na.rm = TRUE, finite = TRUE)
      dr <- rng[2] - rng[1]
      d <- range[2] - range[1]
      if (dr > 0 && d > 0) {
        p_left <- range[1]
        p_right <- range[2]
        limits <- c(rng[1] - (p_left / d) * dr, rng[2] + ((1 - p_right) / d) * dr)
      }
    }
  } else if (!is.null(range) && (discrete || binned)) {
    cli::cli_warn("{.arg range} for discrete or binned x/y axes is not supported.")
  }

  scale_fun <- if (aes == "x") {
    if (binned) {
      ggplot2::scale_x_binned
    } else if (discrete) {
      ggplot2::scale_x_discrete
    } else {
      ggplot2::scale_x_continuous
    }
  } else {
    if (binned) {
      ggplot2::scale_y_binned
    } else if (discrete) {
      ggplot2::scale_y_discrete
    } else {
      ggplot2::scale_y_continuous
    }
  }
  args <- list(name = name, limits = limits, breaks = breaks, labels = labels)
  # When range is provided for continuous axes, tighten expand so the data
  # range maps directly to the panel edges (no padding).
  if (!is.null(range) && !discrete && !binned) {
    args$expand <- c(0, 0)
  }
  if (!discrete && !binned) args$trans <- trans
  # For discrete + reverse, reverse the level order in limits
  if (discrete && reverse && is.null(limits)) {
    args$limits <- rev
  }
  args <- ._strip_nulls(args)
  extra_args <- ._strip_nulls(list(...))
  plot@gg <- plot@gg + do.call(scale_fun, c(args, extra_args))
  plot
}

# ---- shared scale implementations -------------------------------------------
# The eight scale_* functions come in four symmetric pairs (colour/fill,
# size/alpha, shape/linetype, x/y).  Each pair shares one implementation
# parameterised by the aesthetic name, so per-aesthetic behaviour lives in
# exactly one place.

# colour/fill pair: clears the injected default_color (these are the two
# channels it owns), resolves trans, installs the scale, and hands the
# channel to the user in the managed registry.
#' Shared implementation for the colour/fill scale pair.
#' @noRd
#' @keywords internal
._scale_cf_impl <- function(plot, aes, name, trans, limits, range, breaks,
                            labels, ...) {
  plot <- ._clear_default_color(plot)
  trans <- ._resolve_trans(plot, aes, trans, ._TRANS_CONT)
  rd <- ._resolve_reverse_discrete(plot, aes, trans)
  plot@gg <- plot@gg +
    ._scale_colour_fun(aes, rd$trans, range,
      name = name, limits = limits, breaks = breaks, labels = labels,
      force_reverse = rd$force_reverse, ...
    )
  # The user now owns the channel: later layer-level mappings must not
  # attach the token default on top of it.
  ._colour_managed_add(plot, aes)
}

# size/alpha pair: same resolution pipeline without default_color handling.
#' Shared implementation for the size/alpha scale pair.
#' @noRd
#' @keywords internal
._scale_visual_impl <- function(plot, aes, name, trans, limits, range, breaks,
                                labels, ...) {
  trans <- ._resolve_trans(plot, aes, trans, ._TRANS_CONT)
  rd <- ._resolve_reverse_discrete(plot, aes, trans)
  plot@gg <- plot@gg +
    ._scale_numeric_fun(aes, rd$trans, range,
      name = name, limits = limits, breaks = breaks, labels = labels,
      force_reverse = rd$force_reverse, ...
    )
  plot
}

# shape/linetype pair: discrete-only channels.
#' Shared implementation for the shape/linetype scale pair.
#' @noRd
#' @keywords internal
._scale_disc_visual_impl <- function(plot, aes, name, trans, limits, range,
                                     breaks, labels, ...) {
  trans <- ._resolve_trans(plot, aes, trans, ._TRANS_SL)
  plot@gg <- plot@gg +
    ._scale_discrete_fun(aes, trans, range,
      name = name, limits = limits, breaks = breaks, labels = labels, ...
    )
  plot
}

# ---- scale_color ----
#' Color scale
#'
#' Maps data values to colours. Auto-detects discrete vs continuous variables;
#' supports manual colour vectors and named colour schemes.
#'
#' @param plot A plotit object.
#' @param name Scale title (legend name). `ggplot2::waiver()` = use variable name.
#' @param trans Scale transformation. `NULL` auto-detects, otherwise one of:
#'   `"identity"`, `"discrete"`, `"reverse"`, `"binned"`.
#'   Unsupported values (e.g. `"log"`) produce a targeted error message.
#' @param limits Data domain. `c(min, max)` for continuous; character vector for discrete limits.
#' @param range Output range. `NULL` = auto (discrete->friendly, continuous->viridis).
#'   A colour vector (`c("blue","red")`) for manual colours, or a scheme name:
#'   `"viridis"`, `"brewer"`, `"grey"`, `"friendly"`, `"hue"`.
#'   For binned: only `"viridis"`, `"brewer"`.
#'   For continuous: only `"viridis"`, `"brewer"`.
#' @param breaks Legend key positions.
#' @param labels Legend key labels.
#' @param ... Passed to the underlying ggplot2 scale function.
#' @return A modified plotit object.
#' @examples
#' plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
#'   mark_point() |>
#'   scale_color(range = "viridis")
#' @export
scale_color <- S7::new_generic(
  "scale_color", "plot",
  function(plot, name = ggplot2::waiver(), trans = NULL,
           limits = NULL, range = NULL, breaks = NULL, labels = NULL, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(scale_color, plotit_class) <- function(plot, name = ggplot2::waiver(),
                                                  trans = NULL, limits = NULL,
                                                  range = NULL, breaks = NULL,
                                                  labels = NULL, ...) {
  ._scale_cf_impl(plot, "colour", name, trans, limits, range, breaks, labels, ...)
}

# ---- scale_fill ----
#' Fill scale
#'
#' Maps data values to fill colours. Same semantics as [scale_color()] but for
#' the `fill` aesthetic (bars, boxes, polygons, etc.).
#'
#' @param plot A plotit object.
#' @param name Scale title (legend name). `ggplot2::waiver()` = use variable name.
#' @param trans Scale transformation. `NULL` auto-detects, otherwise one of:
#'   `"identity"`, `"discrete"`, `"reverse"`, `"binned"`.
#'   Unsupported values (e.g. `"log"`) produce a targeted error message.
#' @param limits Data domain.
#' @param range Output range. Same as [scale_color()]: colour vector, or `"viridis"`,
#'   `"brewer"`, `"grey"`, `"friendly"`, `"hue"`.
#' @param breaks Legend key positions.
#' @param labels Legend key labels.
#' @param ... Passed to the underlying ggplot2 scale function.
#' @return A modified plotit object.
#' @examples
#' plotit(iris, encode(x = Species, fill = Species)) |>
#'   mark_bar() |>
#'   scale_fill(range = "viridis")
#' @export
scale_fill <- S7::new_generic(
  "scale_fill", "plot",
  function(plot, name = ggplot2::waiver(), trans = NULL,
           limits = NULL, range = NULL, breaks = NULL, labels = NULL, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(scale_fill, plotit_class) <- function(plot, name = ggplot2::waiver(),
                                                 trans = NULL, limits = NULL,
                                                 range = NULL, breaks = NULL,
                                                 labels = NULL, ...) {
  ._scale_cf_impl(plot, "fill", name, trans, limits, range, breaks, labels, ...)
}

# ---- scale_size ----
#' Size scale
#'
#' Maps data values to point/line sizes.
#'
#' @param plot A plotit object.
#' @param name Scale title (legend name).
#' @param trans Scale transformation. `NULL` auto-detects, otherwise one of:
#'   `"identity"`, `"discrete"`, `"reverse"`, `"binned"`.
#'   Unsupported values (e.g. `"log"`) produce a targeted error message.
#' @param limits Data domain.
#' @param range Output size range as `c(min, max)`. `NULL` = default `c(1, 6)`.
#'   Only meaningful for continuous scales (ignored for discrete/binned).
#' @param breaks Legend key positions.
#' @param labels Legend key labels.
#' @param ... Passed to the underlying ggplot2 scale function.
#' @return A modified plotit object.
#' @examples
#' plotit(mtcars, encode(x = wt, y = mpg, size = hp)) |>
#'   mark_point() |>
#'   scale_size(range = c(1, 6))
#' @export
scale_size <- S7::new_generic(
  "scale_size", "plot",
  function(plot, name = ggplot2::waiver(), trans = NULL,
           limits = NULL, range = NULL, breaks = NULL, labels = NULL, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(scale_size, plotit_class) <- function(plot, name = ggplot2::waiver(),
                                                 trans = NULL, limits = NULL,
                                                 range = NULL, breaks = NULL,
                                                 labels = NULL, ...) {
  ._scale_visual_impl(plot, "size", name, trans, limits, range, breaks, labels, ...)
}

# ---- scale_alpha ----
#' Alpha (transparency) scale
#'
#' Maps data values to alpha transparency.
#'
#' @param plot A plotit object.
#' @param name Scale title (legend name).
#' @param trans Scale transformation. `NULL` auto-detects, otherwise one of:
#'   `"identity"`, `"discrete"`, `"reverse"`, `"binned"`.
#'   Unsupported values (e.g. `"log"`) produce a targeted error message.
#' @param limits Data domain.
#' @param range Output alpha range as `c(min, max)`. `NULL` = default `c(0.1, 1)`.
#'   Only meaningful for continuous scales.
#' @param breaks Legend key positions.
#' @param labels Legend key labels.
#' @param ... Passed to the underlying ggplot2 scale function.
#' @return A modified plotit object.
#' @examples
#' plotit(mtcars, encode(x = wt, y = mpg, alpha = hp)) |>
#'   mark_point() |>
#'   scale_alpha()
#' @export
scale_alpha <- S7::new_generic(
  "scale_alpha", "plot",
  function(plot, name = ggplot2::waiver(), trans = NULL,
           limits = NULL, range = NULL, breaks = NULL, labels = NULL, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(scale_alpha, plotit_class) <- function(plot, name = ggplot2::waiver(),
                                                  trans = NULL, limits = NULL,
                                                  range = NULL, breaks = NULL,
                                                  labels = NULL, ...) {
  ._scale_visual_impl(plot, "alpha", name, trans, limits, range, breaks, labels, ...)
}

# ---- scale_shape ----
#' Shape scale
#'
#' Maps data values to point shapes. Supports discrete and reverse scales;
#' continuous variables are not supported (use binned via scale_colour instead).
#'
#' @param plot A plotit object.
#' @param name Scale title (legend name).
#' @param trans Scale transformation. Default `"discrete"`. Allowed:
#'   `"discrete"`, `"reverse"`. `"identity"` and `"binned"` are rejected
#'   with targeted error messages.
#' @param limits Data domain.
#' @param range Shape numbers as `c(from, to)`. `NULL` = ggplot2 default shapes.
#' @param breaks Legend key positions.
#' @param labels Legend key labels.
#' @param ... Passed to the underlying ggplot2 scale function.
#' @return A modified plotit object.
#' @examples
#' plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, shape = Species)) |>
#'   mark_point() |>
#'   scale_shape()
#' @export
scale_shape <- S7::new_generic(
  "scale_shape", "plot",
  function(plot, name = ggplot2::waiver(), trans = "discrete",
           limits = NULL, range = NULL, breaks = NULL, labels = NULL, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(scale_shape, plotit_class) <- function(plot, name = ggplot2::waiver(),
                                                  trans = "discrete", limits = NULL,
                                                  range = NULL, breaks = NULL,
                                                  labels = NULL, ...) {
  ._scale_disc_visual_impl(plot, "shape", name, trans, limits, range, breaks, labels, ...)
}

# ---- scale_linetype ----
#' Linetype scale
#'
#' Maps data values to line types. Supports discrete and reverse scales;
#' continuous variables are not supported.
#'
#' @param plot A plotit object.
#' @param name Scale title (legend name).
#' @param trans Scale transformation. Default `"discrete"`. Allowed:
#'   `"discrete"`, `"reverse"`. `"identity"` and `"binned"` are rejected
#'   with targeted error messages.
#' @param limits Data domain.
#' @param range Linetype names or codes (`c("solid","dashed")`). `NULL` = ggplot2 defaults.
#' @param breaks Legend key positions.
#' @param labels Legend key labels.
#' @param ... Passed to the underlying ggplot2 scale function.
#' @return A modified plotit object.
#' @examples
#' plotit(ggplot2::economics, encode(x = date, y = unemploy)) |>
#'   mark_line() |>
#'   scale_linetype()
#' @export
scale_linetype <- S7::new_generic(
  "scale_linetype", "plot",
  function(plot, name = ggplot2::waiver(), trans = "discrete",
           limits = NULL, range = NULL, breaks = NULL, labels = NULL, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(scale_linetype, plotit_class) <- function(plot, name = ggplot2::waiver(),
                                                     trans = "discrete", limits = NULL,
                                                     range = NULL, breaks = NULL,
                                                     labels = NULL, ...) {
  ._scale_disc_visual_impl(plot, "linetype", name, trans, limits, range, breaks, labels, ...)
}

# ---- scale_x ----
#' X-axis position scale
#'
#' Controls the x-axis scale: transformation, limits, breaks, and labels.
#'
#' @param plot A plotit object.
#' @param name Axis title. `ggplot2::waiver()` = use variable name.
#' @param trans Scale transformation. Default `"identity"`. Allowed:
#'   `"identity"`, `"discrete"`, `"log"`, `"log10"`, `"log2"`,
#'   `"sqrt"`, `"reverse"`, `"binned"`.
#' @param limits Axis limits as `c(min, max)`.
#' @param range Normalized panel proportion as `c(min, max)` in \code{[0,1]}.
#'   E.g. `c(0.1, 0.9)` maps data to the middle 80% of the panel.
#' @param breaks Axis tick positions.
#' @param labels Axis tick labels.
#' @param ... Passed to the underlying ggplot2 scale function.
#' @return A modified plotit object.
#' @examples
#' plotit(mtcars, encode(x = wt, y = mpg)) |>
#'   mark_point() |>
#'   scale_x(trans = "log10")
#' @export
scale_x <- S7::new_generic(
  "scale_x", "plot",
  function(plot, name = ggplot2::waiver(), trans = "identity",
           limits = NULL, range = NULL, breaks = NULL, labels = NULL, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(scale_x, plotit_class) <- function(plot, name = ggplot2::waiver(),
                                              trans = "identity", limits = NULL,
                                              range = NULL, breaks = NULL,
                                              labels = NULL, ...) {
  trans <- ._resolve_trans(plot, "x", trans, ._TRANS_XY)
  ._scale_xy_impl(plot, "x", name, trans, limits, range, breaks, labels, ...)
}

# ---- scale_y ----
#' Y-axis position scale
#'
#' Controls the y-axis scale: transformation, limits, breaks, and labels.
#'
#' @param plot A plotit object.
#' @param name Axis title. `ggplot2::waiver()` = use variable name.
#' @param trans Scale transformation. Default `"identity"`. Allowed:
#'   `"identity"`, `"discrete"`, `"log"`, `"log10"`, `"log2"`,
#'   `"sqrt"`, `"reverse"`, `"binned"`.
#' @param limits Axis limits as `c(min, max)`.
#' @param range Normalized panel proportion as `c(min, max)` in \code{[0,1]}.
#'   E.g. `c(0.1, 0.9)` maps data to the middle 80% of the panel.
#' @param breaks Axis tick positions.
#' @param labels Axis tick labels.
#' @param ... Passed to the underlying ggplot2 scale function.
#' @return A modified plotit object.
#' @examples
#' plotit(mtcars, encode(x = wt, y = mpg)) |>
#'   mark_point() |>
#'   scale_y(limits = c(0, 40))
#' @export
scale_y <- S7::new_generic(
  "scale_y", "plot",
  function(plot, name = ggplot2::waiver(), trans = "identity",
           limits = NULL, range = NULL, breaks = NULL, labels = NULL, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(scale_y, plotit_class) <- function(plot, name = ggplot2::waiver(),
                                              trans = "identity", limits = NULL,
                                              range = NULL, breaks = NULL,
                                              labels = NULL, ...) {
  trans <- ._resolve_trans(plot, "y", trans, ._TRANS_XY)
  ._scale_xy_impl(plot, "y", name, trans, limits, range, breaks, labels, ...)
}
