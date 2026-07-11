# Error bar layer

Adds error bars showing confidence intervals, standard errors, or other
variability measures. Data should include columns for `ymin`/`ymax`
(vertical) or `xmin`/`xmax` (horizontal).

## Usage

``` r
mark_errorbar(
  plot,
  mapping = NULL,
  data = NULL,
  position = NULL,
  ...,
  width = 0.5,
  orientation = c("vertical", "horizontal"),
  rasterize = FALSE,
  rasterize_dpi = 300,
  rasterize_dev = "cairo"
)
```

## Arguments

- plot:

  A plotit object

- mapping:

  Optional new aesthetics (must include `ymin`/`ymax` or `xmin`/`xmax`)

- data:

  Optional data for this layer

- position:

  Position adjustment.

- ...:

  Other arguments passed to the underlying geom

- width:

  Width of the error bar caps (default 0.5).

- orientation:

  `"vertical"` (default) or `"horizontal"`.

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

Vega-Lite:
[Errorbar](https://vega.github.io/vega-lite/docs/errorbar.html)
(composite mark)

## Examples

``` r
df <- data.frame(
  x = c("A", "B"), y = c(10, 20), ymin = c(8, 18), ymax = c(12, 22))
plotit(df, encode(x = x, y = y, ymin = ymin, ymax = ymax)) |>
  mark_errorbar(width = 0.3)
```
