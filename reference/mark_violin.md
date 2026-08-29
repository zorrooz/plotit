# Violin layer

Adds a violin plot layer showing the kernel density estimate of the data
at each position.

## Usage

``` r
mark_violin(
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

  Other arguments passed to `geom_violin`. Since ggplot2 4.0 the
  quantile lines live on the stat: `quantiles =` selects the quantiles
  drawn and `quantile.colour`/`quantile.linetype`/`quantile.linewidth`
  style them (`quantile.linetype = 0` hides them by default).

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

AntV G2: [density
(violin)](https://g2.antv.antgroup.com/en/api/general/shape)

## Examples

``` r
plotit(iris, encode(x = Species, y = Sepal.Length)) |>
  mark_violin(quantiles = 0.5, quantile.linetype = "dashed")
```
