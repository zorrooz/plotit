# Error bar / interval layer

Adds interval bars showing confidence intervals, standard errors, or
other variability measures. Vertical bars (default) map the position on
`x` and the interval on `ymin`/`ymax`; horizontal bars map the position
on `y` and the interval on `xmin`/`xmax` (G2's `rangeX`/`rangeY`
semantics). Set `caps = FALSE` for plain interval lines without end caps
(Vega-Lite's `errorband`).

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
  caps = TRUE,
  rasterize = FALSE,
  rasterize_dpi = 300,
  rasterize_dev = "cairo"
)
```

## Arguments

- plot:

  A plotit object

- mapping:

  Optional new aesthetics (must include the interval columns for the
  chosen orientation: `ymin`/`ymax` vertical, `xmin`/`xmax` horizontal)

- data:

  Optional data for this layer

- position:

  Position adjustment.

- ...:

  Other arguments passed to the underlying geom

- width:

  Size of the error bar caps as a fraction of the resolution of the data
  (default 0.5). Ignored when `caps = FALSE`.

- orientation:

  `"vertical"` (default) or `"horizontal"`.

- caps:

  If `TRUE` (default), draw end caps; `FALSE` renders bare interval
  lines (`geom_linerange`).

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
[Errorbar](https://vega.github.io/vega-lite/docs/errorbar.html) /
[Errorband](https://vega.github.io/vega-lite/docs/errorband.html)
(composite marks)

AntV G2: [Range](https://g2.antv.antgroup.com/en/api/mark/range)

## Examples

``` r
df <- data.frame(
  x = c("A", "B"), y = c(10, 20), ymin = c(8, 18), ymax = c(12, 22)
)
plotit(df, encode(x = x, y = y, ymin = ymin, ymax = ymax)) |>
  mark_errorbar(width = 0.3)


# horizontal interval (position on y, range on x)
dfh <- data.frame(
  y = c("A", "B"), x = c(10, 20), xmin = c(8, 18), xmax = c(12, 22)
)
plotit(dfh, encode(x = x, y = y, xmin = xmin, xmax = xmax)) |>
  mark_point() |>
  mark_errorbar(orientation = "horizontal", caps = FALSE)
```
