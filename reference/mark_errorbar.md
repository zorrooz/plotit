# Error bar / interval layer

Adds interval bars showing pre-computed intervals (`stat = "identity"`,
the default: `ymin`/`ymax` come straight from the data) or statistical
entities computed per group (`stat = "mean_sem"`, `"mean_sd"`,
`"mean_range"`, `"mean_ci95"`): the interval is aggregated from the raw
`y` values of each x group with no manual pre-computation.

## Usage

``` r
mark_errorbar(
  plot,
  mapping = NULL,
  data = NULL,
  position = NULL,
  ...,
  stat = "identity",
  level = 0.95,
  ci_method = c("normal", "boot"),
  seed = NULL,
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

  Optional new aesthetics. With `stat = "identity"` it must include the
  interval columns for the chosen orientation (`ymin`/`ymax` vertical,
  `xmin`/`xmax` horizontal); with a statistical entity it only needs `x`
  (group) and `y` (value).

- data:

  Optional data for this layer

- position:

  Position adjustment.

- ...:

  Other arguments passed to the underlying geom

- stat:

  Statistical entity: `"identity"` (pre-computed intervals, no implicit
  aggregation) or one of `"mean_sem"`, `"mean_sd"`, `"mean_range"`,
  `"mean_ci95"` (per-group aggregation of `y`).

- level:

  Confidence level for `stat = "mean_ci95"`, in `(0, 1)` (default 0.95).

- ci_method:

  `"normal"` (default, t-based normal approximation) or `"boot"`
  (percentile bootstrap of the mean; requires `seed`).

- seed:

  RNG seed for `ci_method = "boot"`; required for reproducibility of the
  bootstrap.

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

## Details

Vertical bars (default) map the position on `x` and the interval on
`ymin`/`ymax`; horizontal bars map the position on `y` and the interval
on `xmin`/`xmax` (G2's `rangeX`/`rangeY` semantics). Set `caps = FALSE`
for plain interval lines without end caps (Vega-Lite's `errorband`).

## References

Vega-Lite:
[Errorbar](https://vega.github.io/vega-lite/docs/errorbar.html) /
[Errorband](https://vega.github.io/vega-lite/docs/errorband.html)
(`extent`: stderr \<-\> sem, stdev \<-\> sd, ci \<-\> ci95)

AntV G2: [Range](https://g2.antv.antgroup.com/en/api/mark/range)

## Examples

``` r
df <- data.frame(
  x = c("A", "B"), y = c(10, 20), ymin = c(8, 18), ymax = c(12, 22)
)
plotit(df, encode(x = x, y = y, ymin = ymin, ymax = ymax)) |>
  mark_errorbar(width = 0.3)


# statistical entity: mean +- sem aggregated per group from raw y
plotit(iris, encode(x = Species, y = Sepal.Length)) |>
  mark_errorbar(stat = "mean_sem")


# horizontal interval (position on y, range on x)
dfh <- data.frame(
  y = c("A", "B"), x = c(10, 20), xmin = c(8, 18), xmax = c(12, 22)
)
plotit(dfh, encode(x = x, y = y, xmin = xmin, xmax = xmax)) |>
  mark_point() |>
  mark_errorbar(orientation = "horizontal", caps = FALSE)
```
