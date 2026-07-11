# Polygon layer

Adds a filled polygon layer. Each group forms one polygon; subgroups are
separated by `NA` rows or the `group` aesthetic.

## Usage

``` r
mark_polygon(
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

  Other arguments passed to `geom_polygon`

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

AntV G2: [Polygon](https://g2.antv.antgroup.com/en/api/mark/polygon)

## Examples

``` r
tri <- data.frame(x = c(0, 1, 0.5), y = c(0, 0, 1))
plotit(tri, encode(x = x, y = y)) |> mark_polygon(fill = "skyblue")
```
