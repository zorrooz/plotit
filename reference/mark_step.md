# Step layer

Adds a stair-step line layer: observations are connected with
axis-parallel segments, so every change renders as an explicit jump. Use
for discrete state changes over time, reference thresholds, or
cumulative (ECDF-style) views.

## Usage

``` r
mark_step(
  plot,
  mapping = NULL,
  data = NULL,
  position = NULL,
  ...,
  direction = c("vh", "hv", "mid"),
  rasterize = FALSE,
  rasterize_dpi = 300,
  rasterize_dev = "cairo"
)
```

## Arguments

- plot:

  A plotit object

- mapping:

  Optional new aesthetics

- data:

  Optional data for this layer

- position:

  Position adjustment.

- ...:

  Other arguments passed to `geom_step`

- direction:

  `"vh"` (default) draws vertical-then-horizontal steps; `"hv"` the
  reverse; `"mid"` steps at the midpoint.

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

Vega-Lite: [Line](https://vega.github.io/vega-lite/docs/line.html) with
`interpolate: "step"`

AntV G2: [Line](https://g2.antv.antgroup.com/en/api/mark/line) with
`shape: "hv"`

## Examples

``` r
plotit(ggplot2::economics, encode(x = date, y = unemploy)) |>
  mark_step()


# horizontal-then-vertical steps
plotit(ggplot2::economics, encode(x = date, y = unemploy)) |>
  mark_step(direction = "hv")


# grouped steps
plotit(
  subset(ggplot2::economics, date > "1990-01-01"),
  encode(x = date, y = psavert, colour = "savings")
) |>
  mark_step() |>
  mark_line(colour = "#E15759", alpha = 0.3)
```
