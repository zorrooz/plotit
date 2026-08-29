# Smoothed conditional mean layer

Adds a smoothed conditional mean line with a confidence band. Aids the
eye in seeing patterns in the presence of overplotting.

## Usage

``` r
mark_smooth(
  plot,
  mapping = NULL,
  data = NULL,
  position = NULL,
  ...,
  method = NULL,
  formula = NULL,
  se = NULL,
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

  Other arguments passed to `geom_smooth`

- method:

  Smoothing method: `"auto"` (loess for n\<1000, gam otherwise), `"lm"`,
  `"glm"`, `"gam"`, or `"loess"`.

- formula:

  Formula to use in the smoothing function.

- se:

  If `TRUE` (default), display confidence interval around smooth.

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

R: [`stats::loess()`](https://rdrr.io/r/stats/loess.html) /
[`stats::lm()`](https://rdrr.io/r/stats/lm.html) (default smoothing
methods) Vega-Lite: achieved via
`layer(point) + layer(line) + transform(regression)`

AntV G2: achieved via transform pipeline

## Examples

``` r
plotit(mtcars, encode(x = wt, y = mpg)) |> mark_smooth()
#> `geom_smooth()` using method = 'loess' and formula = 'y ~ x'
```
