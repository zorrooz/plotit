# Spoke layer

Draws a radial segment ("spoke") from each point `(x, y)` at `angle`
(radians) for `radius` length. A first-class primitive for
direction/velocity fields and for radial network edges whose endpoints
are naturally expressed in polar terms.

## Usage

``` r
mark_spoke(
  plot,
  mapping = NULL,
  data = NULL,
  position = NULL,
  ...,
  rasterize = FALSE,
  rasterize_dpi = 300,
  rasterize_dev = "cairo"
)
```

## Arguments

- plot:

  A plotit object

- mapping:

  Optional new aesthetics (must include `x`, `y`, `angle` in radians,
  and `radius`)

- data:

  Optional data for this layer

- position:

  Position adjustment.

- ...:

  Other arguments passed to `geom_spoke`

- rasterize:

  If `TRUE`, rasterize via
  [`ggrastr::rasterise()`](https://rdrr.io/pkg/ggrastr/man/rasterise.html).

- rasterize_dpi:

  DPI for rasterization (default 300).

- rasterize_dev:

  Graphics device for rasterization (default `"cairo"`).

## Value

Modified plotit object

## References

Vega-Lite: [Spoke](https://vega.github.io/vega-lite/docs/spoke.html)

## Examples

``` r
df <- data.frame(
  x = c(0, 1, 2), y = c(0, 1, 0),
  angle = c(0, pi / 2, pi), radius = c(0.5, 0.8, 0.3)
)
plotit(df, encode(x = x, y = y, angle = angle, radius = radius)) |>
  mark_spoke()
```
