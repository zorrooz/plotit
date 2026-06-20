#' @include class.R
NULL

# ---- project_cartesian ----

#' Cartesian coordinate system
#'
#' The primary coordinate function. Supports zooming, flipping, fixed aspect
#' ratio, and coordinate transformations — all through parameters.
#'
#' @param plot A plotit object.
#' @param xlim,ylim Axis limits (zoom). `NULL` = auto.
#' @param expand If `TRUE`, add default expansion padding; `FALSE` or
#'   `c(0, 0)` to remove.
#' @param flip If `TRUE`, swap the x and y axes.
#' @param fixed Aspect ratio (`y / x`). `NULL` = free; `1` = square.
#' @param coord_trans Transformer for coordinate system (e.g. `"log10"`,
#'   `"sqrt"`, `scales::exp_trans()`). `NULL` = identity.
#' @param clip Should drawing be clipped to the panel? `"on"` or `"off"`.
#' @param ... Passed to the underlying `coord_*` function.
#' @return Modified plotit object.
#' @export
project_cartesian <- S7::new_generic(
  "project_cartesian",
  "plot",
  function(plot, xlim = NULL, ylim = NULL, expand = TRUE,
           flip = FALSE, fixed = NULL, coord_trans = NULL,
           clip = "on", ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(project_cartesian, plotit_class) <- function(
  plot,
  xlim = NULL,
  ylim = NULL,
  expand = TRUE,
  flip = FALSE,
  fixed = NULL,
  coord_trans = NULL,
  clip = "on",
  ...
) {
  modes <- sum(flip, !is.null(fixed), !is.null(coord_trans))
  if (modes > 1) {
    active <- if (flip) "flip" else if (!is.null(fixed)) "fixed" else "coord_trans"
    cli::cli_warn(c(
      "Multiple coordinate modes set: {.arg flip}={flip}, {.arg fixed}={fixed}, {.arg coord_trans}={coord_trans}.",
      "i" = "Only {.arg {active}} will be used."
    ))
  }
  if (flip) {
    plot@gg <- plot@gg +
      ggplot2::coord_flip(xlim = xlim, ylim = ylim, expand = expand, clip = clip, ...)
  } else if (!is.null(fixed)) {
    plot@gg <- plot@gg +
      ggplot2::coord_fixed(ratio = fixed, xlim = xlim, ylim = ylim,
                           expand = expand, clip = clip, ...)
  } else if (!is.null(coord_trans)) {
    trans_fun <- if (utils::packageVersion("ggplot2") >= "3.5.0") {
      ggplot2::coord_transform
    } else {
      ggplot2::coord_trans
    }
    plot@gg <- plot@gg +
      trans_fun(x = coord_trans, xlim = xlim, ylim = ylim,
                expand = expand, clip = clip, ...)
  } else {
    plot@gg <- plot@gg +
      ggplot2::coord_cartesian(xlim = xlim, ylim = ylim,
                               expand = expand, clip = clip, ...)
  }
  plot
}

# ---- project_polar ----

#' Polar / radial coordinate system
#'
#' Maps one axis to angle and the other to radius.  Default (full circle,
#' zero inner radius) uses `coord_polar()`.  Set `inner_radius > 0` or
#' `r_axis_inside = TRUE` to switch to the radial variant (requires
#' ggplot2 >= 3.5.0).
#'
#' @param plot A plotit object.
#' @param theta Variable mapped to angle: `"x"` or `"y"`.
#' @param start Starting angle in radians (0 = 12 o'clock).
#' @param direction `1` = clockwise, `-1` = anti-clockwise.
#' @param inner_radius Inner radius as a fraction of the panel (0–1).
#'   `0` = polar (full circle). `>0` = radial (hollow centre, needs
#'   ggplot2 >= 3.5.0).
#' @param r_axis_inside If `TRUE`, place the radial axis inside the panel
#'   (radial mode only).
#' @param clip Should drawing be clipped? `"on"` or `"off"`.
#' @param ... Passed to the underlying `coord_polar()` or `coord_radial()`.
#' @return Modified plotit object.
#' @export
project_polar <- S7::new_generic(
  "project_polar",
  "plot",
  function(plot, theta = "x", start = 0, direction = 1,
           inner_radius = 0, r_axis_inside = FALSE, clip = "on", ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(project_polar, plotit_class) <- function(
  plot,
  theta = "x",
  start = 0,
  direction = 1,
  inner_radius = 0,
  r_axis_inside = FALSE,
  clip = "on",
  ...
) {
  use_radial <- inner_radius > 0 || isTRUE(r_axis_inside)
  if (use_radial && utils::packageVersion("ggplot2") < "3.5.0") {
    cli::cli_abort(c(
      "Radial coordinates (inner_radius > 0 or r_axis_inside = TRUE) require ggplot2 >= 3.5.0.",
      "i" = "You have ggplot2 {utils::packageVersion('ggplot2')}."
    ))
  }
  if (use_radial) {
    args <- list(
      theta = theta, start = start,
      r.axis.inside = r_axis_inside, inner.radius = inner_radius, clip = clip
    )
    if (utils::packageVersion("ggplot2") >= "4.0") {
      if (direction == -1) args$reverse <- "theta"
    } else {
      args$direction <- direction
    }
    plot@gg <- plot@gg + do.call(ggplot2::coord_radial, c(args, list(...)))
  } else {
    plot@gg <- plot@gg +
      ggplot2::coord_polar(theta = theta, start = start,
                           direction = direction, clip = clip, ...)
  }
  plot@gg <- plot@gg +
    ggplot2::theme(axis.line = ggplot2::element_blank(),
                   axis.ticks = ggplot2::element_blank(),
                   axis.ticks.length = ggplot2::unit(0, "pt"),
                   axis.text = ggplot2::element_blank())
  plot
}

# ---- project_parallel ----

#' Parallel coordinates
#'
#' Reshapes the plot data so that the selected columns become parallel
#' vertical axes. Each observation is drawn as a polyline connecting its
#' values across all axes. Values are optionally normalised per column
#' to share a common 0–1 scale.
#'
#' Adds `geom_line()` and `geom_point()` layers. Call *after* any
#' `mark_*` layers that should sit beneath the parallel-coordinate lines.
#'
#' @param plot A plotit object.
#' @param columns Character vector of column names to use as parallel axes.
#'   Order matters: the first column is the leftmost axis.
#' @param group Column name for colouring lines. `NULL` = no grouping.
#' @param scale `"std"` (default): min-max normalise each column to 0–1.
#'   `"global"`: use raw values. `"none"`: no scaling.
#' @param alpha,size Passed to `geom_line()` / `geom_point()`.
#' @param clip Currently unused (parallel coordinates do not apply a
#'   coordinate system). Accepted for signature consistency.
#' @param ... Passed to `geom_line()`.
#' @return Modified plotit object.
#' @export
project_parallel <- S7::new_generic(
  "project_parallel",
  "plot",
  function(plot, columns, group = NULL, scale = c("std", "global", "none"),
           alpha = 0.5, size = 1, clip = "on", ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(project_parallel, plotit_class) <- function(
  plot,
  columns,
  group = NULL,
  scale = c("std", "global", "none"),
  alpha = 0.5,
  size = 1,
  clip = "on",
  ...
) {
  scale <- match.arg(scale)
  data <- plot@gg$data

  if (is.null(data) || nrow(data) == 0) {
    cli::cli_abort("No data found in plot. Call plotit() with a non-empty data frame.")
  }

  if (length(columns) == 0) {
    cli::cli_abort("{.arg columns} must contain at least one column name.")
  }

  missing_cols <- setdiff(columns, names(data))
  if (length(missing_cols) > 0) {
    cli::cli_abort("Column(s) not found in data: {.val {missing_cols}}.")
  }

  if (!is.null(group)) {
    if (!(group %in% names(data))) {
      cli::cli_abort("{.arg group} column {.val {group}} not found in data.")
    }
    if (group %in% columns) {
      cli::cli_abort("{.arg group} column {.val {group}} is also in {.arg columns}. Use a different grouping variable.")
    }
  }

  id_col <- ".plotit_id"
  val_col <- ".plotit_val"
  var_col <- ".plotit_var"
  if (any(c(id_col, val_col, var_col) %in% names(data))) {
    cli::cli_abort(c(
      "Data contains reserved column names.",
      "i" = "Columns {.val {c(id_col, val_col, var_col)}} are used internally."
    ))
  }
  data[[id_col]] <- seq_len(nrow(data))
  keep_cols <- c(id_col, columns)
  if (!is.null(group)) {
    keep_cols <- c(keep_cols, group)
  }

  long <- stats::reshape(
    data[, keep_cols, drop = FALSE],
    varying   = list(columns),
    v.names   = val_col,
    times     = columns,
    timevar   = var_col,
    idvar     = id_col,
    direction = "long"
  )
  long[[var_col]] <- factor(long[[var_col]], levels = columns)

  if (scale == "std") {
    for (v in columns) {
      rows <- long[[var_col]] == v
      vals <- long[[val_col]][rows]
      rng <- range(vals, na.rm = TRUE)
      if (rng[2] > rng[1]) {
        long[[val_col]][rows] <- (vals - rng[1]) / (rng[2] - rng[1])
      } else {
        long[[val_col]][rows] <- 0.5
      }
    }
  }

  aes_args <- list(
    x     = as.name(var_col),
    y     = as.name(val_col),
    group = as.name(id_col)
  )
  if (!is.null(group)) {
    aes_args$colour <- as.name(group)
  }
  pc_mapping <- do.call(ggplot2::aes, aes_args)

  # Clear default_color if group introduces a colour mapping (§7 principle 7)
  if (!is.null(group) && !is.null(plot@meta@default_color)) {
    plot@gg$mapping$colour <- NULL
    plot@gg <- plot@gg + ggplot2::guides(colour = ggplot2::waiver())
    S7::prop(plot@meta, "default_color") <- NULL
  }

  # Parallel-coordinate-specific theme: show column names and ticks
  # (each factor level is a visible axis), suppress the rectangular frame.
  plot@gg <- plot@gg +
    ggplot2::geom_line(data = long, mapping = pc_mapping, alpha = alpha, ...) +
    ggplot2::geom_point(data = long, mapping = pc_mapping, size = size) +
    ggplot2::theme(axis.line = ggplot2::element_blank())

  plot
}

# ---- project_map ----

#' Map coordinate system
#'
#' Applies a geographic projection. Uses `ggplot2::coord_sf()` by default
#' (for simple features), or `ggplot2::coord_map()` when a `projection`
#' string is provided (requires \pkg{mapproj}).
#'
#' @param plot A plotit object.
#' @param projection Map projection name (e.g. `"mercator"`, `"orthographic"`).
#'   `NULL` uses `coord_sf()` default.
#' @param xlim,ylim Longitude/latitude limits. `NULL` = auto.
#' @param clip Should drawing be clipped? `"on"` or `"off"`.
#' @param ... Passed to `coord_sf()` or `coord_map()`.
#' @return Modified plotit object.
#' @export
project_map <- S7::new_generic(
  "project_map",
  "plot",
  function(plot, projection = NULL, xlim = NULL, ylim = NULL,
           clip = "on", ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(project_map, plotit_class) <- function(
  plot,
  projection = NULL,
  xlim = NULL,
  ylim = NULL,
  clip = "on",
  ...
) {
  if (!is.null(projection)) {
    if (!requireNamespace("mapproj", quietly = TRUE)) {
      cli::cli_abort("Map projections require the {.pkg mapproj} package.")
    }
    plot@gg <- plot@gg +
      ggplot2::coord_map(projection = projection, xlim = xlim, ylim = ylim,
                         clip = clip, ...)
  } else {
    plot@gg <- plot@gg +
      ggplot2::coord_sf(xlim = xlim, ylim = ylim, clip = clip, ...)
  }
  plot
}


