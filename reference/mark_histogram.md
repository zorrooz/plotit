# Histogram layer

Adds a histogram layer with automatic binning.

## Usage

``` r
mark_histogram(
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

  Other arguments passed to `geom_histogram`

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

R: [`graphics::hist()`](https://rdrr.io/r/graphics/hist.html) (binning
semantics; realised by ggplot2's stat_bin) Vega-Lite:
[Bar](https://vega.github.io/vega-lite/docs/bar.html) with `bin`
transform

## Examples

``` r
plotit(iris, encode(x = Sepal.Width)) |> mark_histogram()
#> `stat_bin()` using `bins = 30`. Pick better value `binwidth`.
```
