# Hexagonal heatmap layer

Divides the x-y plane into hexagonal bins and fills each by the count
(or other aggregation) of observations in that bin. Ideal for
visualizing overplotting in large datasets.

## Usage

``` r
mark_hex(
  plot,
  mapping = NULL,
  data = NULL,
  position = NULL,
  ...,
  bins = NULL,
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

  Other arguments passed to `geom_hex`

- bins:

  Number of bins along both axes (default 30).

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

AntV G2: [Heatmap](https://g2.antv.antgroup.com/en/api/mark/heatmap)
(corelib)

## Examples

``` r
plotit(
  ggplot2::diamonds[sample(nrow(ggplot2::diamonds), 1000), ],
  encode(x = carat, y = price)
) |> mark_hex(bins = 20)
```
