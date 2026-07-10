# Boxplot layer

Adds a box-and-whisker distribution layer.

## Usage

``` r
mark_boxplot(
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

  Position adjustment; overrides `geom_boxplot` default.

- ...:

  Other arguments passed to `geom_boxplot`

- rasterize:

  If `TRUE`, rasterize via
  [`ggrastr::rasterise()`](https://rdrr.io/pkg/ggrastr/man/rasterise.html).

- rasterize_dpi:

  DPI for rasterization (default 300).

- rasterize_dev:

  Graphics device for rasterization (default `"cairo"`).

## Value

Modified plotit object

## Examples

``` r
plotit(iris, encode(x = Species, y = Sepal.Length)) |> mark_boxplot()
```
