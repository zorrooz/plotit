# 2D density contour layer

Adds 2D kernel density estimate contours. Use `filled = TRUE` for filled
density bands via
[ggplot2::geom_density_2d_filled](https://ggplot2.tidyverse.org/reference/geom_density_2d.html).

## Usage

``` r
mark_density_2d(
  plot,
  mapping = NULL,
  data = NULL,
  position = NULL,
  ...,
  filled = FALSE,
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

  Other arguments passed to the underlying geom

- filled:

  If `TRUE`, use filled density contours.

- bins:

  Number of contour bins (for filled mode).

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

AntV G2: [Density](https://g2.antv.antgroup.com/en/api/mark/density)
(corelib, contour mode)

## Examples

``` r
plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
  mark_density_2d()
```
