# Count layer (overlap-aware points)

Draws each unique point once, sized by the number of observations at
that location (`stat_sum`). The standard answer to overplotting in
scatter plots of discrete or binned data; pair with
[`scale_radius()`](https://zorrooz.github.io/plotit/reference/scale_radius.md)
for an area-proportional legend.

## Usage

``` r
mark_count(
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

  Optional new aesthetics

- data:

  Optional data for this layer

- position:

  Position adjustment.

- ...:

  Other arguments passed to `geom_count`

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

Vega-Lite: [Point](https://vega.github.io/vega-lite/docs/point.html)
with `aggregate: count`

tidyplots: `add_count_dot()` equivalent

## Examples

``` r
plotit(ggplot2::diamonds, encode(x = cut, y = carat)) |> mark_count()


plotit(ggplot2::diamonds, encode(x = carat, y = price)) |> mark_count()
```
