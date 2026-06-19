#' @include class.R
NULL

# ---- project_cartesian ----

#' Cartesian coordinate system
#'
#' The primary coordinate function. Supports zooming, flipping, fixed aspect
#' ratio, and coordinate transformations — all through parameters rather than
#' separate functions.
#'
#' @param plot A plotit object.
#' @param xlim,ylim Axis limits (zoom). `NULL` = auto.
#' @param expand If `TRUE`, add default expansion padding; `FALSE` or
#'   `c(0, 0)` to remove.
#' @param clip Should drawing be clipped to the panel? `"on"` or `"off"`.
#' @param flip If `TRUE`, swap the x and y axes (replaces `project_flip()`).
#' @param fixed Aspect ratio (`y / x`). `NULL` = free; `1` = square.
#' @param trans Transformer for coordinate system (e.g. `"log10"`, `"sqrt"`,
#'   `scales::exp_trans()`). `NULL` = identity.
#' @param ... Passed to the underlying `coord_*` function.
#' @return Modified plotit object.
#' @export
project_cartesian <- S7::new_generic(
  "project_cartesian",
  "plot",
  function(plot, xlim = NULL, ylim = NULL, expand = TRUE, clip = "on",
           flip = FALSE, fixed = NULL, trans = NULL, ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(project_cartesian, plotit_class) <- function(
  plot,
  xlim = NULL,
  ylim = NULL,
  expand = TRUE,
  clip = "on",
  flip = FALSE,
  fixed = NULL,
  trans = NULL,
  ...
) {
  if (flip) {
    plot@gg <- plot@gg +
      ggplot2::coord_flip(xlim = xlim, ylim = ylim, expand = expand, clip = clip, ...)
  } else if (!is.null(fixed)) {
    plot@gg <- plot@gg +
      ggplot2::coord_fixed(ratio = fixed, xlim = xlim, ylim = ylim,
                           expand = expand, clip = clip, ...)
  } else if (!is.null(trans)) {
    trans_fun <- if (utils::packageVersion("ggplot2") >= "4.0") {
      ggplot2::coord_transform
    } else {
      ggplot2::coord_trans
    }
    plot@gg <- plot@gg +
      trans_fun(x = trans, xlim = xlim, ylim = ylim,
                expand = expand, clip = clip, ...)
  } else {
    plot@gg <- plot@gg +
      ggplot2::coord_cartesian(xlim = xlim, ylim = ylim,
                               expand = expand, clip = clip, ...)
  }
  plot
}

# ---- project_flip ----

#' Flipped Cartesian coordinates (convenience)
#'
#' Convenience wrapper for `project_cartesian(flip = TRUE)`.
#'
#' @param plot A plotit object.
#' @param xlim,ylim Axis limits.
#' @param expand Expansion padding.
#' @param clip Clipping mode.
#' @param ... Passed to `coord_flip`.
#' @return Modified plotit object.
#' @export
project_flip <- S7::new_generic(
  "project_flip",
  "plot",
  function(plot, xlim = NULL, ylim = NULL, expand = TRUE, clip = "on", ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(project_flip, plotit_class) <- function(
  plot,
  xlim = NULL,
  ylim = NULL,
  expand = TRUE,
  clip = "on",
  ...
) {
  project_cartesian(plot, xlim = xlim, ylim = ylim, expand = expand,
                    clip = clip, flip = TRUE, ...)
}

# ---- project_polar ----

#' Polar coordinate system
#'
#' @param plot A plotit object.
#' @param theta Variable to map to angle (`"x"` or `"y"`).
#' @param start Starting angle in radians (default 0 = 12 o'clock).
#' @param direction `1` = clockwise, `-1` = anti-clockwise.
#' @param clip Should drawing be clipped? `"on"` or `"off"`.
#' @param ... Passed to `ggplot2::coord_polar`.
#' @return Modified plotit object.
#' @export
project_polar <- S7::new_generic(
  "project_polar",
  "plot",
  function(plot, theta = "x", start = 0, direction = 1, clip = "on", ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(project_polar, plotit_class) <- function(
  plot,
  theta = "x",
  start = 0,
  direction = 1,
  clip = "on",
  ...
) {
  plot@gg <- plot@gg +
    ggplot2::coord_polar(theta = theta, start = start,
                         direction = direction, clip = clip, ...)
  plot
}

# ---- project_parallel ----

#' Parallel coordinates
#'
#' Reshapes the plot data so that the selected columns become parallel
#' vertical axes. Each observation is drawn as a polyline connecting its
#' values across all axes. Values are optionally min-max normalised per
#' column so that axes share a common 0–1 scale.
#'
#' Adds `geom_line()` and `geom_point()` layers to the plot.  Call
#' `project_parallel()` *after* `mark_*` layers that should sit beneath
#' the parallel-coordinate lines.
#'
#' @param plot A plotit object.
#' @param columns Character vector of column names to use as parallel axes.
#'   Order matters: the first column is the leftmost axis.
#' @param group Optional grouping variable for colouring lines
#'   (character, column name).
#' @param scale If `"std"` (default), each column is min-max normalised to
#'   [0, 1] so axes share a common scale.  If `"global"`, raw values are
#'   used (useful when columns already share the same unit).  If `"none"`,
#'   no scaling is applied.
#' @param alpha Line transparency passed to `geom_line()`.
#' @param size Point size passed to `geom_point()`.
#' @param ... Passed to `geom_line()`.
#' @return Modified plotit object.
#' @export
project_parallel <- S7::new_generic(
  "project_parallel",
  "plot",
  function(plot, columns, group = NULL, scale = c("std", "global", "none"),
           alpha = 0.5, size = 1, ...) {
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
  ...
) {
  scale <- match.arg(scale)
  data <- plot@gg$data

  if (is.null(data)) {
    cli::cli_abort("No data found in plot. Call plotit() with a data frame first.")
  }

  missing_cols <- setdiff(columns, names(data))
  if (length(missing_cols) > 0) {
    cli::cli_abort("Column(s) not found in data: {.val {missing_cols}}.")
  }

  # Reshape selected columns to long format via base R reshape()
  id_col <- ".plotit_id"
  data[[id_col]] <- seq_len(nrow(data))
  keep_cols <- c(id_col, columns)
  if (!is.null(group)) {
    keep_cols <- c(keep_cols, group)
  }

  long <- stats::reshape(
    data[, keep_cols, drop = FALSE],
    varying   = list(columns),
    v.names   = ".plotit_val",
    times     = columns,
    timevar   = ".plotit_var",
    direction = "long"
  )
  long[[".plotit_var"]] <- factor(long[[".plotit_var"]], levels = columns)

  # Scale values per variable
  if (scale == "std") {
    for (v in columns) {
      rows <- long[[".plotit_var"]] == v
      vals <- long[[".plotit_val"]][rows]
      rng <- range(vals, na.rm = TRUE)
      if (rng[2] > rng[1]) {
        long[[".plotit_val"]][rows] <- (vals - rng[1]) / (rng[2] - rng[1])
      } else {
        long[[".plotit_val"]][rows] <- 0.5
      }
    }
  }

  # Build mapping for the parallel-coordinate layers
  aes_args <- list(
    x     = as.name(".plotit_var"),
    y     = as.name(".plotit_val"),
    group = as.name(id_col)
  )
  if (!is.null(group)) {
    aes_args$colour <- as.name(group)
  }
  pc_mapping <- do.call(ggplot2::aes, aes_args)

  plot@gg <- plot@gg +
    ggplot2::geom_line(data = long, mapping = pc_mapping, alpha = alpha, ...) +
    ggplot2::geom_point(data = long, mapping = pc_mapping, size = size)

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
#'   `NULL` uses the default `coord_sf()` projection.
#' @param xlim,ylim Longitude/latitude limits.
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

# ---- project_radial ----

#' Radial coordinate system
#'
#' A radial coordinate system where one axis is mapped to angle and
#' another to radius. Available in ggplot2 >= 3.5.0. Useful for
#' Coxcomb plots, radial bar charts, and spiral visualisations.
#'
#' @param plot A plotit object.
#' @param theta Variable mapped to angle (`"x"` or `"y"`, default `"x"`).
#' @param start Starting angle in radians (default 0 = 12 o'clock).
#' @param direction `1` = clockwise, `-1` = anti-clockwise.
#' @param r.axis.inside If `TRUE`, place the radial axis inside the plot.
#' @param inner.radius Inner radius as a fraction of the panel (0–1).
#' @param clip Should drawing be clipped? `"on"` or `"off"`.
#' @param ... Passed to `coord_radial()`.
#' @return Modified plotit object.
#' @export
project_radial <- S7::new_generic(
  "project_radial",
  "plot",
  function(plot, theta = "x", start = 0, direction = 1,
           r.axis.inside = FALSE, inner.radius = 0, clip = "on", ...) {
    S7::S7_dispatch()
  }
)

#' @export
S7::method(project_radial, plotit_class) <- function(
  plot,
  theta = "x",
  start = 0,
  direction = 1,
  r.axis.inside = FALSE,
  inner.radius = 0,
  clip = "on",
  ...
) {
  if (utils::packageVersion("ggplot2") < "3.5.0") {
    cli::cli_abort(c(
      "Radial coordinates require ggplot2 >= 3.5.0.",
      "i" = "You have ggplot2 {utils::packageVersion('ggplot2')}."
    ))
  }
  plot@gg <- plot@gg +
    suppressWarnings(ggplot2::coord_radial(
      theta = theta, start = start, direction = direction,
      r.axis.inside = r.axis.inside, inner.radius = inner.radius,
      clip = clip, ...
    ))
  plot
}
