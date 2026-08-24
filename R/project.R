#' @include class.R
#' @include utils.R
NULL

# ---- project_cartesian ----

#' Cartesian coordinate system
#'
#' The primary coordinate function. Supports zooming, flipping, fixed aspect
#' ratio, and coordinate transformations -- all through parameters.
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
#' @examples
#' plotit(iris, encode(x = Species, y = Sepal.Length)) |>
#'   mark_boxplot() |>
#'   project_cartesian(flip = TRUE)
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
      ggplot2::coord_fixed(
        ratio = fixed, xlim = xlim, ylim = ylim,
        expand = expand, clip = clip, ...
      )
  } else if (!is.null(coord_trans)) {
    trans_fun <- if (utils::packageVersion("ggplot2") >= "3.5.0") {
      ggplot2::coord_transform
    } else {
      ggplot2::coord_trans
    }
    plot@gg <- plot@gg +
      trans_fun(
        x = coord_trans, xlim = xlim, ylim = ylim,
        expand = expand, clip = clip, ...
      )
  } else {
    plot@gg <- plot@gg +
      ggplot2::coord_cartesian(
        xlim = xlim, ylim = ylim,
        expand = expand, clip = clip, ...
      )
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
#' @param inner_radius Inner radius as a fraction of the panel (0-1).
#'   `0` = polar (full circle). `>0` = radial (hollow centre, needs
#'   ggplot2 >= 3.5.0).
#' @param r_axis_inside If `TRUE`, place the radial axis inside the panel
#'   (radial mode only).
#' @param clip Should drawing be clipped? `"on"` or `"off"`.
#' @param ... Passed to the underlying `coord_polar()` or `coord_radial()`.
#' @return Modified plotit object.
#' @examples
#' plotit(mtcars, encode(x = factor(cyl))) |>
#'   mark_bar() |>
#'   project_polar()
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
    # coord_radial supports direction parameter since ggplot2 3.5.0
    if (direction != 1) args$direction <- direction
    plot@gg <- plot@gg + do.call(ggplot2::coord_radial, c(args, list(...)))
  } else {
    plot@gg <- plot@gg +
      ggplot2::coord_polar(
        theta = theta, start = start,
        direction = direction, clip = clip, ...
      )
  }
  # Blank axes only in polar mode.  Radial mode (inner_radius > 0 or
  # r_axis_inside = TRUE) needs its radial axis visible.
  if (!(inner_radius > 0 || isTRUE(r_axis_inside))) {
    plot@gg <- plot@gg +
      ggplot2::theme(
        axis.line = ggplot2::element_blank(),
        axis.ticks = ggplot2::element_blank(),
        axis.ticks.length = ggplot2::unit(0, "pt"),
        axis.text = ggplot2::element_blank(),
        axis.title = ggplot2::element_blank()
      )
  }
  plot
}

# ---- project_parallel ----

#' Parallel coordinates
#'
#' Reshapes the plot data so that the selected columns become parallel
#' vertical axes. Each observation is drawn as a polyline connecting its
#' values across all axes. Values are optionally normalised per column
#' to share a common 0-1 scale.
#'
#' Adds `geom_line()` and `geom_point()` layers. Call *after* any
#' `mark_*` layers that should sit beneath the parallel-coordinate lines.
#'
#' @param plot A plotit object.
#' @param columns Character vector of column names to use as parallel axes.
#'   Order matters: the first column is the leftmost axis.
#' @param group Column name for colouring lines. `NULL` = no grouping.
#' @param scale `"std"` (default): min-max normalise each column to 0-1.
#'   `"global"`: min-max normalise across all columns to 0-1.
#'   `"none"`: no normalisation, each column keeps its own range.
#' @param alpha,size Passed to `geom_line()` / `geom_point()`.
#' @param ... Passed to `geom_line()`.
#' @return Modified plotit object.
#' @examples
#' plotit(iris, encode()) |>
#'   project_parallel(columns = c("Sepal.Width", "Sepal.Length", "Petal.Width", "Petal.Length"))
#' @export
project_parallel <- S7::new_generic(
  "project_parallel",
  "plot",
  function(plot, columns, group = NULL, scale = c("std", "global", "none"),
           alpha = 0.5, size = 1, ...) {
    S7::S7_dispatch()
  }
)

# Resolve axis theme properties + tick length for per-column axis rendering.
# Returns a list of visual properties matching the plot's current theme.
#' Extract axis theme properties for per-column axis rendering.
#' @noRd
#' @keywords internal
._parallel_theme_props <- function(theme) {
  base_pt <- (ggplot2::calc_element("text", theme)$size) %||% 11

  g_lc <- function(name, default) {
    el <- ggplot2::calc_element(name, theme)
    if (inherits(el, "element_blank")) default else el$colour %||% default
  }
  g_ll <- function(name, default) {
    el <- ggplot2::calc_element(name, theme)
    if (inherits(el, "element_blank")) default else el$linewidth %||% default
  }
  g_tc <- function(name, default) {
    el <- ggplot2::calc_element(name, theme)
    if (inherits(el, "element_blank")) default else el$colour %||% el$color %||% default
  }
  g_ts <- function(name, default_pt) {
    el <- ggplot2::calc_element(name, theme)
    if (inherits(el, "element_blank")) {
      return(default_pt * 0.3528)
    }
    sz <- el$size %||% default_pt
    if (inherits(sz, "rel")) sz <- as.numeric(sz) * base_pt
    sz * 0.3528
  }
  g_tf <- function(name, default) {
    el <- ggplot2::calc_element(name, theme)
    if (inherits(el, "element_blank")) default else el$face %||% default
  }
  g_tfm <- function(name, default) {
    el <- ggplot2::calc_element(name, theme)
    if (inherits(el, "element_blank")) default else el$family %||% default
  }

  # Tick length: 2% of inter-column spacing in data coordinates.
  # The theme's axis.ticks.length is in absolute units (pt) and cannot
  # be used directly in data coordinates without knowing the plot size.
  tick_len <- 0.02
  label_gap <- tick_len * 0.4

  list(
    axis_line_col = g_lc("axis.line.y", g_lc("axis.line", "grey50")),
    axis_line_lwd = g_ll("axis.line.y", g_ll("axis.line", 0.3)),
    tick_col      = g_lc("axis.ticks.y", g_lc("axis.ticks", "grey50")),
    tick_lwd      = g_ll("axis.ticks.y", g_ll("axis.ticks", 0.3)),
    tick_len      = tick_len,
    label_gap     = label_gap,
    text_col      = g_tc("axis.text.y", g_tc("axis.text", "grey30")),
    text_sz_mm    = g_ts("axis.text.y", 9),
    text_face     = g_tf("axis.text.y", g_tf("axis.text", "plain")),
    text_family   = g_tfm("axis.text.y", g_tfm("axis.text", ""))
  )
}

# Build a format string for axis tick labels based on the step size between
# breaks.  Uses 0, 1, or 2 decimal places depending on the break granularity.
#' Build a format string for axis tick labels based on break step size.
#' @noRd
#' @keywords internal
._pp_label_fmt <- function(breaks) {
  if (length(breaks) < 2) {
    return("%.2f")
  }
  step <- diff(range(breaks, na.rm = TRUE)) / (length(breaks) - 1)
  if (step >= 1) "%.0f" else if (step >= 0.1) "%.1f" else "%.2f"
}

# Draw per-column axes for scale="none" mode.
# Uses geom_segment for axis lines + ticks, geom_text for labels.
# All colours, sizes, and fonts are drawn from `tp` (theme properties).
#' Draw per-column axes for scale="none" parallel coordinates mode.
#' Uses geom_segment and geom_text with theme-matched styling.
#' @noRd
#' @keywords internal
._pp_draw_axes <- function(plot, col_info, tp) {
  # Suppress native y-axis
  plot@gg <- plot@gg +
    ggplot2::theme(
      axis.line.y  = ggplot2::element_blank(),
      axis.ticks.y = ggplot2::element_blank(),
      axis.text.y  = ggplot2::element_blank(),
      axis.title.y = ggplot2::element_blank()
    )

  # Axis lines
  df_axis <- do.call(rbind, lapply(col_info, function(ci) {
    data.frame(x = ci$pos, xend = ci$pos, y = ci$ymin, yend = ci$ymax)
  }))
  plot@gg <- plot@gg +
    ggplot2::geom_segment(
      data = df_axis,
      mapping = ggplot2::aes(
        x = .data$x, y = .data$y,
        xend = .data$xend, yend = .data$yend
      ),
      colour = tp$axis_line_col,
      linewidth = tp$axis_line_lwd,
      inherit.aes = FALSE
    )

  # Ticks
  tlen <- tp$tick_len
  df_ticks <- do.call(rbind, lapply(col_info, function(ci) {
    n <- length(ci$breaks)
    if (n == 0) {
      return(NULL)
    }
    data.frame(
      x = rep(ci$pos, n), xend = rep(ci$pos - tlen, n),
      y = ci$breaks, yend = ci$breaks
    )
  }))
  if (!is.null(df_ticks) && nrow(df_ticks) > 0) {
    plot@gg <- plot@gg +
      ggplot2::geom_segment(
        data = df_ticks,
        mapping = ggplot2::aes(
          x = .data$x, y = .data$y,
          xend = .data$xend, yend = .data$yend
        ),
        colour = tp$tick_col,
        linewidth = tp$tick_lwd,
        inherit.aes = FALSE
      )
  }

  # Labels (positioned with extra gap beyond tick end)
  df_lab <- do.call(rbind, lapply(col_info, function(ci) {
    n <- length(ci$breaks)
    if (n == 0) {
      return(NULL)
    }
    data.frame(
      x = rep(ci$pos - tlen - tp$label_gap, n), y = ci$breaks,
      label = sprintf(ci$fmt, ci$breaks), hjust = rep(1, n),
      stringsAsFactors = FALSE
    )
  }))
  if (!is.null(df_lab) && nrow(df_lab) > 0) {
    plot@gg <- plot@gg +
      ggplot2::geom_text(
        data = df_lab,
        mapping = ggplot2::aes(
          x = .data$x, y = .data$y,
          label = .data$label, hjust = .data$hjust
        ),
        colour = tp$text_col,
        size = tp$text_sz_mm,
        family = tp$text_family,
        fontface = tp$text_face,
        inherit.aes = FALSE
      )
  }

  plot
}

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
  reserved <- c(id_col, val_col, var_col)
  conflict <- intersect(reserved, names(data))
  if (length(conflict) > 0) {
    cli::cli_abort(c(
      "Data contains reserved column names.",
      "x" = "Found: {.val {conflict}}.",
      "i" = "These names are used internally by {.fn project_parallel}."
    ))
  }
  data[[id_col]] <- seq_len(nrow(data))
  keep_cols <- c(id_col, columns)
  if (!is.null(group)) {
    keep_cols <- c(keep_cols, group)
  }

  long <- stats::reshape(
    data[, keep_cols, drop = FALSE],
    varying = list(columns),
    v.names = val_col,
    times = columns,
    timevar = var_col,
    idvar = id_col,
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

  # Clear default_color if group introduces a colour mapping
  if (!is.null(group)) {
    plot <- ._clear_default_color(plot)
  }

  # ---- Axis rendering: three mutually exclusive modes ----
  #
  #   std    -- per-column normalised to 0-1  ->  shared native y-axis
  #   global -- globally normalised to 0-1     ->  shared native y-axis
  #   none   -- no normalisation                ->  per-column axes
  #
  #  Shared-scale modes delegate tick & label rendering to the native
  #  scale_y_continuous() guide -- this guarantees visual consistency with
  #  the rest of the plot.  "none" mode must draw per-column ticks, axis
  #  lines and labels manually, using the current theme's axis.* elements
  #  so the look stays as close to native as possible.
  n_cols <- length(columns)
  shared_scale <- scale %in% c("std", "global")

  # ---- Global normalisation (scale = "global") ----
  if (scale == "global") {
    all_vals <- long[[val_col]]
    grng <- range(all_vals, na.rm = TRUE)
    if (grng[2] > grng[1]) {
      long[[val_col]] <- (all_vals - grng[1]) / (grng[2] - grng[1])
    } else {
      long[[val_col]] <- 0.5
    }
  }

  # ---- Resolve theme properties once (extracted helper) ----
  tp <- ._parallel_theme_props(plot@gg$theme)


  # ---- Build per-column info (incl. raw values for break computation) ----
  col_info <- lapply(seq_along(columns), function(i) {
    cn <- columns[i]
    cv <- long[[val_col]][long[[var_col]] == cn]
    rng <- range(cv, na.rm = TRUE)
    # nice break points (target ~5, cap at 6 to avoid overcrowding)
    brk <- pretty(rng, n = 5)
    brk <- brk[brk >= rng[1] & brk <= rng[2]]
    if (length(brk) > 6) brk <- brk[seq(1, length(brk), length.out = 6)]
    # label format based on break step size (not data range)
    fmt <- ._pp_label_fmt(brk)
    list(
      pos = i, name = cn, ymin = rng[1], ymax = rng[2],
      values = cv, breaks = brk, fmt = fmt
    )
  })

  # ---- Data layers ----
  plot@gg <- plot@gg +
    ggplot2::geom_line(data = long, mapping = pc_mapping, alpha = alpha, ...) +
    ggplot2::geom_point(data = long, mapping = pc_mapping, size = size)

  # ---- Common scales (both modes) ----
  y_limits <- range(
    vapply(col_info, `[[`, numeric(1), "ymax"),
    vapply(col_info, `[[`, numeric(1), "ymin")
  )
  pad <- 0.04 * diff(y_limits)
  plot@gg <- plot@gg +
    ggplot2::scale_y_continuous(
      limits = y_limits + c(-pad, pad),
      expand = c(0, 0)
    ) +
    ggplot2::scale_x_discrete(
      labels = stats::setNames(columns, columns),
      expand = ggplot2::expansion(add = 0.3)
    ) +
    ggplot2::theme(
      axis.line.x  = ggplot2::element_blank(),
      axis.ticks.x = ggplot2::element_blank(),
      axis.title   = ggplot2::element_blank()
    )

  # ---- Shared-scale mode (std / global) -- native y-axis provides ticks ----
  if (shared_scale) {
    # no additional per-column elements needed
  } else {
    # ---- Per-column mode (none) -- manual per-column axes ----
    plot <- ._pp_draw_axes(plot, col_info, tp)
  }

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
#' @examplesIf(requireNamespace("sf", quietly = TRUE))
#' # requires the sf package
#' nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
#' plotit(nc, encode()) |> project_map()
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
      ggplot2::coord_map(
        projection = projection, xlim = xlim, ylim = ylim,
        clip = clip, ...
      )
  } else {
    plot@gg <- plot@gg +
      ggplot2::coord_sf(xlim = xlim, ylim = ylim, clip = clip, ...)
  }
  plot@gg <- plot@gg +
    ggplot2::theme(axis.title = ggplot2::element_blank())
  plot
}
