# Bar layer

Adds a bar layer. Automatically uses `geom_col()` when a y aesthetic is
mapped, or `geom_bar()` for count-based bars.

## Usage

``` r
mark_bar(
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

  Position adjustment; overrides `geom_bar`/`geom_col` default.

- ...:

  Other arguments passed to `geom_bar` or `geom_col`

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

Vega-Lite: [Bar](https://vega.github.io/vega-lite/docs/bar.html)

AntV G2: [Interval](https://g2.antv.antgroup.com/en/api/mark/interval)
(corelib)

## Examples

``` r
plotit(mtcars, encode(x = factor(cyl))) |> mark_bar()
```
