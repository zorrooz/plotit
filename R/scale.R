#' @include class.R utils.R theme.R
NULL

# ---- Internal helpers ----

._detect_discrete_aes <- function(plot, aes_name) {
  var <- plot@gg$mapping[[aes_name]]
  if (!is.null(var)) {
    return(is_discrete(plot@gg$data, var))
  }
  # Layer-resolved channels (graph pipelines declare aesthetics on marks
  # only): the mark path records each channel's evaluated kind.
  kinds <- ._aes_kinds_get(plot)
  if (!is.null(kinds[[aes_name]])) {
    return(kinds[[aes_name]])
  }
  # Unknown channel with no trace anywhere: assume discrete (AGENTS.md
  # 4.6: gg$layers is internal, so we cannot re-scan layer mappings).
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

# ---- scheme catalog (design 04 ss3.1: 20 whitelisted names, additive) ----
# Diverging anchors (low, neutral, high) from ColorBrewer / tidyplots
# (research/05 ss5.3); needed by both the `mid=` routing and the diverging
# `range=` whitelist below.
#' Diverging colour anchors: c(low, neutral, high) per scheme name.
#' @noRd
#' @keywords internal
._DIVERGING_ANCHORS <- list(
  rdbu       = c("#67001F", "#F7F7F7", "#053061"),
  rdylbu     = c("#A50026", "#F7F7F7", "#313695"),
  spectral   = c("#D53E4F", "#F7F7F7", "#3288BD"),
  brbg       = c("#A6611A", "#F7F7F7", "#018571"),
  puor       = c("#7F3B08", "#F7F7F7", "#2D004B"),
  blue2brown = c("#1961A5", "#F7F7F7", "#B3322E")
)

#' Return diverging anchors c(low, neutral, high) for a scheme name.
#' @noRd
#' @keywords internal
._diverging_ramp <- function(scheme) {
  anchors <- ._DIVERGING_ANCHORS[[scheme]]
  if (is.null(anchors)) {
    ._abort_arg_enum("range", names(._DIVERGING_ANCHORS), got = scheme)
  }
  anchors
}

# Sequential (8): viridis (default), magma, inferno, plasma, cividis, mako,
#   rocket, turbo -- all ride ggplot2's viridis option= machinery.
# Qualitative (7): friendly (default), friendly_long, tableau10, okabeito,
#   brewer, hue, grey.
# Diverging (6): rdbu (default), rdylbu, spectral, brbg, puor, blue2brown.
#' Sequential colour scheme names.
#' @noRd
#' @keywords internal
._SEQUENTIAL_SCHEMES <- c("viridis", "magma", "inferno", "plasma", "cividis", "mako", "rocket", "turbo")
#' Qualitative colour scheme names.
#' @noRd
#' @keywords internal
._QUALITATIVE_SCHEMES <- c("friendly", "friendly_long", "tableau10", "okabeito", "brewer", "hue", "grey")
#' Diverging colour scheme names.
#' @noRd
#' @keywords internal
._DIVERGING_SCHEMES <- names(._DIVERGING_ANCHORS)
#' All whitelisted colour scheme names.
#' @noRd
#' @keywords internal
._ALL_SCHEMES <- c(._SEQUENTIAL_SCHEMES, ._QUALITATIVE_SCHEMES, ._DIVERGING_SCHEMES)

# Qualitative ramp builders (anchors from tidyplots / G2 academy,
# research/05 ss5.3 and 03 ss5.3).
#' friendly_long ramp (7 anchors, tidyplots).
#' @noRd
#' @keywords internal
._palette_friendly_long <- function(n) {
  grDevices::colorRampPalette(c(
    "#CC79A7", "#0072B2", "#56B4E9", "#009E73", "#F5C710", "#E69F00", "#D55E00"
  ))(n)
}
#' tableau10 ramp (10 anchors, G2 academy = Tableau 10).
#' @noRd
#' @keywords internal
._palette_tableau10 <- function(n) {
  grDevices::colorRampPalette(c(
    "#4E79A7", "#F28E2C", "#E15759", "#76B7B2", "#59A14F",
    "#EDC949", "#AF7AA1", "#FF9DA7", "#9C755F", "#BAB0AB"
  ))(n)
}
#' Okabe-Ito ramp (grDevices built-in).
#' @noRd
#' @keywords internal
._palette_okabeito <- function(n) {
  grDevices::colorRampPalette(grDevices::palette.colors(palette = "Okabe-Ito"))(n)
}

# Scheme-based dispatch over the 20-name catalog.
#' Dispatch to colour/fill scale by scheme name.
#' @noRd
#' @keywords internal
._scale_scheme <- function(aes, scheme, discrete, binned, reverse, ...) {
  dir <- if (reverse) -1 else 1
  if (discrete) {
    if (scheme %in% ._SEQUENTIAL_SCHEMES) {
      ._cf(aes, ggplot2::scale_colour_viridis_d, ggplot2::scale_fill_viridis_d)(
        option = scheme, direction = dir, ...
      )
    } else if (scheme == "friendly") {
      ggplot2::discrete_scale(
        aesthetics = aes,
        palette = if (reverse) {
          function(n) rev(._palette_discrete(n))
        } else {
          function(n) ._palette_discrete(n)
        },
        ...
      )
    } else if (scheme == "friendly_long") {
      ggplot2::discrete_scale(
        aesthetics = aes,
        palette = if (reverse) {
          function(n) rev(._palette_friendly_long(n))
        } else {
          function(n) ._palette_friendly_long(n)
        },
        ...
      )
    } else if (scheme == "tableau10") {
      ggplot2::discrete_scale(
        aesthetics = aes,
        palette = if (reverse) {
          function(n) rev(._palette_tableau10(n))
        } else {
          function(n) ._palette_tableau10(n)
        },
        ...
      )
    } else if (scheme == "okabeito") {
      ggplot2::discrete_scale(
        aesthetics = aes,
        palette = if (reverse) {
          function(n) rev(._palette_okabeito(n))
        } else {
          function(n) ._palette_okabeito(n)
        },
        ...
      )
    } else if (scheme == "brewer") {
      ._cf(aes, ggplot2::scale_colour_brewer, ggplot2::scale_fill_brewer)(direction = dir, ...)
    } else if (scheme == "grey") {
      ._cf(aes, ggplot2::scale_colour_grey, ggplot2::scale_fill_grey)(
        start = if (reverse) 0.8 else 0.2,
        end = if (reverse) 0.2 else 0.8,
        ...
      )
    } else if (scheme == "hue") {
      ._cf(aes, ggplot2::scale_colour_discrete, ggplot2::scale_fill_discrete)(direction = dir, ...)
    } else if (scheme %in% ._DIVERGING_SCHEMES) {
      ramp <- ._diverging_ramp(scheme)
      ggplot2::discrete_scale(
        aesthetics = aes,
        palette = function(n) grDevices::colorRampPalette(if (reverse) rev(ramp) else ramp)(n),
        ...
      )
    } else {
      ._abort_arg_enum("scheme", ._ALL_SCHEMES, got = scheme)
    }
  } else if (binned) {
    if (scheme %in% ._SEQUENTIAL_SCHEMES) {
      ._cf(aes, ggplot2::scale_colour_viridis_b, ggplot2::scale_fill_viridis_b)(
        option = scheme, direction = dir, ...
      )
    } else if (scheme == "brewer") {
      ._cf(aes, ggplot2::scale_colour_fermenter, ggplot2::scale_fill_fermenter)(direction = dir, ...)
    } else if (scheme %in% ._DIVERGING_SCHEMES) {
      ramp <- ._diverging_ramp(scheme)
      if (reverse) ramp <- rev(ramp)
      ._cf(aes, ggplot2::scale_colour_steps2, ggplot2::scale_fill_steps2)(
        low = ramp[1], mid = ramp[2], high = ramp[3], midpoint = 0, ...
      )
    } else {
      ._abort_arg_enum(
        "scheme", c(._SEQUENTIAL_SCHEMES, "brewer", ._DIVERGING_SCHEMES),
        got = scheme,
        hint = "Binned scales support sequential, diverging and {.val brewer} schemes only."
      )
    }
  } else {
    if (scheme %in% ._SEQUENTIAL_SCHEMES) {
      ._cf(aes, ggplot2::scale_colour_viridis_c, ggplot2::scale_fill_viridis_c)(
        option = scheme, direction = dir, ...
      )
    } else if (scheme == "brewer") {
      ._cf(aes, ggplot2::scale_colour_distiller, ggplot2::scale_fill_distiller)(direction = dir, ...)
    } else if (scheme %in% ._DIVERGING_SCHEMES) {
      ramp <- ._diverging_ramp(scheme)
      if (reverse) ramp <- rev(ramp)
      ._cf(aes, ggplot2::scale_colour_gradient2, ggplot2::scale_fill_gradient2)(
        low = ramp[1], mid = ramp[2], high = ramp[3], midpoint = 0, ...
      )
    } else {
      ._abort_arg_enum(
        "scheme", c(._SEQUENTIAL_SCHEMES, "brewer", ._DIVERGING_SCHEMES),
        got = scheme,
        hint = "Continuous scales support sequential, diverging and {.val brewer} schemes only."
      )
    }
  }
}

# Custom colour vector dispatch: manual, gradient, steps
#' Dispatch to colour/fill scale with custom colour vector.
#' @noRd
#' @keywords internal
._scale_custom <- function(aes, range, discrete, binned, reverse, midpoint = NULL, ...) {
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
        ._cf(aes, ggplot2::scale_colour_steps2, ggplot2::scale_fill_steps2)(
          low = lo, mid = range[2], high = hi, midpoint = midpoint %||% 0, ...
        )
      }
    } else {
      if (length(range) == 2) {
        ._cf(aes, ggplot2::scale_colour_gradient, ggplot2::scale_fill_gradient)(low = lo, high = hi, ...)
      } else {
        ._cf(aes, ggplot2::scale_colour_gradient2, ggplot2::scale_fill_gradient2)(
          low = lo, mid = range[2], high = hi, midpoint = midpoint %||% 0, ...
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
    # Single colour name -> helpful error instead of "unknown scheme"
    single_unknown_scheme <- is.character(range) &&
      length(range) == 1 && !(scheme %in% ._ALL_SCHEMES)
    if (single_unknown_scheme) {
      cli::cli_abort(c(
        "{.val {range}} is not a known colour scheme name.",
        "i" = paste0(
          "Use {.code range = c({range})} for a single custom colour, ",
          "or one of: ", paste(._ALL_SCHEMES, collapse = ", "), "."
        )
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
  if (!is.null(range)) {
    if (!discrete) {
      # Continuous and binned scales both accept an output range.
      args$range <- range
    } else {
      cli::cli_warn(c(
        "{.arg range} is ignored for a discrete {.val {aes}} scale.",
        "i" = "Output ranges apply to continuous or binned scales only."
      ))
    }
  }
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
  trans <- ._resolve_trans(plot, aes, trans, ._TRANS_XY)
  discrete <- trans == "discrete"
  reverse <- trans == "reverse"
  binned <- trans == "binned"

  # When trans="reverse" and the mapped variable is discrete, route to
  # the discrete scale with reversed level order instead of attempting
  # scale_x_continuous(trans="reverse") which breaks on factors.  Uses the
  # same shared routing helper as the colour/fill and size/alpha pairs.
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
    cli::cli_warn(c(
      "{.arg range} for discrete or binned x/y axes is not supported.",
      "i" = "The x/y {.arg range} (visual proportion) applies to continuous scales only."
    ))
  }

  # Date/POSIXct columns must use the date scale; trans="identity" would
  # turn dates into raw day numbers (T9.1).  Warn on the misconfiguration
  # and route automatically.
  date_axis <- FALSE
  if (!discrete && !binned) {
    data <- plot@gg$data
    var <- plot@gg$mapping[[aes]]
    if (!is.null(data) && !is.null(var)) {
      vals <- tryCatch(rlang::eval_tidy(var, data), error = function(e) NULL)
      date_axis <- !is.null(vals) &&
        (inherits(vals, "Date") || inherits(vals, "POSIXct") || inherits(vals, "POSIXt"))
    }
  }
  if (date_axis) {
    if (!is.null(trans) && identical(trans, "identity")) {
      cli::cli_warn(c(
        sprintf(
          "{.fn scale_%s}: {.arg trans} = {.val identity} on a DATE/POSIXct column shows raw day numbers.",
          aes
        ),
        "i" = "Date axes use the date scale automatically; drop {.arg trans}."
      ))
    }
    trans <- "date"
  }

  scale_fun <- if (aes == "x") {
    if (date_axis) {
      ggplot2::scale_x_date
    } else if (binned) {
      ggplot2::scale_x_binned
    } else if (discrete) {
      ggplot2::scale_x_discrete
    } else {
      ggplot2::scale_x_continuous
    }
  } else {
    if (date_axis) {
      ggplot2::scale_y_date
    } else if (binned) {
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
  # Date scales have no trans parameter (T9.1).
  if (!discrete && !binned && !date_axis) args$trans <- trans
  if (date_axis && identical(trans, "date")) args$trans <- NULL
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
                            labels, na_color = NULL, n_bins = NULL, mid = NULL, ...) {
  plot <- ._clear_default_color(plot)
  user_trans <- trans
  trans <- ._resolve_trans(plot, aes, trans, ._TRANS_CONT)

  # T5.3: a sequential/diverging scheme name with a discrete variable is
  # almost always a misconfiguration (the variable should be numeric for a
  # continuous gradient).  Warn with the actual routing instead of silently
  # switching to the discrete variant.
  if (is.character(range) && length(range) == 1 &&
    range %in% c(._SEQUENTIAL_SCHEMES, ._DIVERGING_SCHEMES) &&
    (is.null(user_trans) || identical(user_trans, "identity")) &&
    isTRUE(._detect_discrete_aes(plot, aes))) {
    variant <- if (identical(trans, "discrete") || identical(trans, "binned")) {
      sprintf("%s", trans)
    } else {
      "discrete"
    }
    cli::cli_warn(c(
      sprintf(
        "{.arg range} = {.val %s} with a discrete {.val %s} variable uses the %s {.val %s} variant.",
        range, aes, variant, range
      ),
      "i" = "For a continuous gradient, map a numeric column instead."
    ))
  }

  extra <- list()
  if (!is.null(na_color)) {
    if (!is.character(na_color) || length(na_color) != 1 || is.na(na_color)) {
      ._abort_arg_range("na_color", "a single colour", got = na_color)
    }
    extra$na.value <- na_color
  }
  if (!is.null(n_bins)) {
    if (!is.numeric(n_bins) || length(n_bins) != 1 || is.na(n_bins) || n_bins < 2 ||
      n_bins != as.integer(n_bins)) {
      ._abort_arg_range("n_bins", "a single integer >= 2", got = n_bins)
    }
    if (trans == "discrete") {
      ._abort_hint(
        "{.arg n_bins} needs a continuous scale; {.arg trans} is {.val discrete}.",
        "Drop {.arg n_bins} or use a continuous {.arg trans}."
      )
    }
    trans <- "binned"
    extra$n.breaks <- n_bins
  }
  if (!is.null(mid)) {
    if (!is.numeric(mid) || length(mid) != 1 || is.na(mid)) {
      ._abort_arg_range("mid", "a single number", got = mid)
    }
    if (trans %in% c("discrete", "binned")) {
      ._abort_hint(
        sprintf(
          "{.arg mid} needs an untransformed continuous scale; got {.val %s}.",
          trans
        ),
        "Use a continuous {.arg trans} (e.g. {.val identity}) with {.arg mid}."
      )
    }
    # Diverging route: a diverging scheme in `range` (default rdbu) centred
    # at the user's mid; any other range is a conflict (design 04 ss3.2).
    if (!is.null(range)) {
      if (!(is.character(range) && length(range) == 1 &&
        range %in% names(._DIVERGING_ANCHORS))) {
        ._abort_hint(
          "{.arg mid} requires a diverging scheme in {.arg range} (e.g. {.val rdbu}); got a non-diverging range.",
          "Use {.code range = \"rdbu\", mid = 0} or drop {.arg mid}."
        )
      }
      scheme <- range
    } else {
      scheme <- "rdbu"
    }
    range <- ._diverging_ramp(scheme)
    extra$midpoint <- mid
  }
  rd <- ._resolve_reverse_discrete(plot, aes, trans)
  args <- c(
    list(...),
    list(
      aes = aes, trans = rd$trans, range = range,
      name = name, limits = limits, breaks = breaks, labels = labels,
      force_reverse = rd$force_reverse
    ),
    extra
  )
  plot@gg <- plot@gg + do.call(._scale_colour_fun, args)
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
#' @param na_color Colour used for `NA` values (passed to `na.value`).
#'   `NULL` = ggplot2 default.
#' @param n_bins Bin a continuous scale into this many legend steps
#'   (`guide_coloursteps`; shorthand for `trans = "binned"`).  `NULL` =
#'   continuous.
#' @param mid Centre of a diverging colour scale (e.g. `0` for correlation
#'   matrices).  Requires a continuous scale and a diverging scheme in
#'   `range` (`"rdbu"` default); mutually exclusive with `n_bins`.
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
           limits = NULL, range = NULL, breaks = NULL, labels = NULL,
           na_color = NULL, n_bins = NULL, mid = NULL, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(scale_color, plotit_class) <- function(plot, name = ggplot2::waiver(),
                                                  trans = NULL, limits = NULL,
                                                  range = NULL, breaks = NULL,
                                                  labels = NULL, na_color = NULL,
                                                  n_bins = NULL, mid = NULL, ...) {
  ._scale_cf_impl(plot, "colour", name, trans, limits, range, breaks, labels,
    na_color = na_color, n_bins = n_bins, mid = mid, ...
  )
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
#' @param na_color,n_bins,mid Same as [scale_color()].
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
           limits = NULL, range = NULL, breaks = NULL, labels = NULL,
           na_color = NULL, n_bins = NULL, mid = NULL, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(scale_fill, plotit_class) <- function(plot, name = ggplot2::waiver(),
                                                 trans = NULL, limits = NULL,
                                                 range = NULL, breaks = NULL,
                                                 labels = NULL, na_color = NULL,
                                                 n_bins = NULL, mid = NULL, ...) {
  ._scale_cf_impl(plot, "fill", name, trans, limits, range, breaks, labels,
    na_color = na_color, n_bins = n_bins, mid = mid, ...
  )
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
  ._scale_xy_impl(plot, "y", name, trans, limits, range, breaks, labels, ...)
}

# ---- scale_radius (defunct) ----
# Radius encoding belongs to the scale/size domain.  plotit's dedicated
# scale_radius() duplicated scale_size() (two verbs, one semantic) and was
# removed at 1.0.  The stub below is kept exported so legacy code fails
# with a directed migration error instead of "object not found".
#' Radius scale (defunct)
#'
#' `scale_radius()` is **defunct** as of plotit 1.0. Radius/size encoding is
#' the [scale_size()] domain.
#'
#' For bubble charts whose area should encode magnitude:
#' - `scale_size(range = c(1, 6))` maps linearly to ggplot2's area-like
#'   size unit (the size domain default), or
#' - `ggplot2::scale_radius(...)` maps to the circle radius directly
#'   (area-proportional emphasis, Vega-Lite's `scaleRadius` semantics).
#'
#' @param ... Ignored. Present only for drop-in detection.
#' @return Never returns; aborts with migration guidance.
#' @references
#' Vega-Lite: \href{https://vega.github.io/vega-lite/docs/radius.html}{Radius}
#' @export
scale_radius <- function(...) {
  cli::cli_abort(c(
    "{.fn scale_radius} is defunct as of plotit 1.0.0.",
    "x" = "Radius encoding is the {.fn scale_size} domain; the two verbs had one semantic.",
    "i" = "Use {.fn scale_size} (e.g. {.code scale_size(range = c(1, 6))}) for size/radius channels.",
    "i" = "For area-proportional radius mapping call {.fn ggplot2::scale_radius} directly."
  ))
}

# ---- scale catalog ----------------------------------------------------------
# Consumed by zzz.R to register plotit_composite rejection stubs.
._CATALOG_SCALES <- c(
  "scale_color", "scale_fill", "scale_size", "scale_alpha",
  "scale_shape", "scale_linetype", "scale_x", "scale_y"
)
