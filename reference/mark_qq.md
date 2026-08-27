# Quantile-quantile points layer

Adds sample quantiles against theoretical (or another sample's)
quantiles – the classic normality check. Map `x` to the sample; `y` is
optional (another sample for two-sample QQ). Add a reference line with
[`mark_qq_line()`](https://zorrooz.github.io/plotit/reference/mark_qq_line.md).

## Usage

``` r
mark_qq(
  plot,
  mapping = NULL,
  data = NULL,
  position = NULL,
  ...,
  distribution = "norm",
  rasterize = FALSE,
  rasterize_dpi = 300,
  rasterize_dev = "cairo"
)
```

## Arguments

- plot:

  A plotit object

- mapping:

  Optional new aesthetics (`x` required, `y` optional)

- data:

  Optional data for this layer

- position:

  Position adjustment.

- ...:

  Other arguments passed to `geom_qq` (e.g. `dparams`)

- distribution:

  Theoretical distribution function without the `q` prefix (`"norm"`
  default); any `q*` function works: `"norm"`, `"unif"`, `"exp"`,
  `"lnorm"`, ...

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

Observable Plot: [Plot.qq](https://observablehq.com/plot/plots/qq)

## Examples

``` r
ecdf_data <- data.frame(eruptions = faithful$eruptions)
plotit(ecdf_data, encode(x = eruptions)) |>
  mark_qq() |>
  mark_qq_line()


# two-sample QQ against an exponential reference
set.seed(42)
df <- data.frame(value = rexp(200))
plotit(df, encode(x = value)) |>
  mark_qq(distribution = "exp") |>
  mark_qq_line(distribution = "exp")
```
