# Point layer

Adds a scatter plot layer.

## Usage

``` r
mark_point(
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

  Position adjustment; if `NULL` and global dodge is set, auto-applies
  `position_dodge()`.

- ...:

  Other arguments passed to `geom_point`

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

AntV G2: [Point](https://g2.antv.antgroup.com/en/api/mark/point)
(corelib)

## Examples

``` r
plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
```
