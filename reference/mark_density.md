# Density layer

Adds a kernel density estimate layer.

## Usage

``` r
mark_density(
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

  Other arguments passed to `geom_density`

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

R: [`stats::density()`](https://rdrr.io/r/stats/density.html) (kernel
density estimate) AntV G2:
[Density](https://g2.antv.antgroup.com/en/api/mark/density) (corelib)

## Examples

``` r
plotit(iris, encode(x = Sepal.Width)) |> mark_density()
```
