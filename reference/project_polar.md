# Polar / radial coordinate system

Maps one axis to angle and the other to radius. Default (full circle,
zero inner radius) uses `coord_polar()`. Set `inner_radius > 0` or
`r_axis_inside = TRUE` to switch to the radial variant.

## Usage

``` r
project_polar(
  plot,
  theta = "x",
  start = 0,
  end = NULL,
  direction = 1,
  inner_radius = 0,
  r_axis_inside = FALSE,
  clip = "on",
  reverse = "none",
  rotate_angle = FALSE,
  ...
)
```

## Arguments

- plot:

  A plotit object.

- theta:

  Variable mapped to angle: `"x"` or `"y"`.

- start:

  Starting angle in radians (0 = 12 o'clock).

- end:

  Ending angle in radians (radial mode only). `NULL` (default) = full
  circle; a finite value renders a partial arc (e.g. semicircle gauges
  via `start = -pi / 2, end = pi / 2`). Ignored with a warning in plain
  polar mode.

- direction:

  `1` = clockwise, `-1` = anti-clockwise. **Deprecated**: use
  `reverse = "theta"`. `-1` still works but warns once per call
  (deprecation cycle, AGENTS.md 1.4).

- inner_radius:

  Inner radius as a fraction of the panel (0-1). `0` = polar (full
  circle). `>0` = radial (hollow centre).

- r_axis_inside:

  If `TRUE`, place the radial axis inside the panel (radial mode only).

- clip:

  Should drawing be clipped? `"on"` or `"off"`.

- reverse:

  Reverse direction: `"none"` (default), `"theta"` (anti-clockwise,
  replaces `direction = -1`), `"r"` (radial axis) or `"thetar"` (both).
  `"r"`/`"thetar"` are radial-mode only.

- rotate_angle:

  Rotate angle aesthetics with the theta axis (radial mode only, ggplot2
  `coord_radial(rotate.angle)`).

- ...:

  Passed to the underlying `coord_polar()` or `coord_radial()`.

## Value

Modified plotit object.

## Examples

``` r
plotit(mtcars, encode(x = factor(cyl))) |>
  mark_bar() |>
  project_polar()
```
