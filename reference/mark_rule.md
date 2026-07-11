# Reference line / segment layer

Adds one or more reference lines or segments to a plot. Dispatches to
the appropriate ggplot2 geom based on the parameters supplied:

## Usage

``` r
mark_rule(
  plot,
  xintercept = NULL,
  yintercept = NULL,
  slope = NULL,
  intercept = NULL,
  x = NULL,
  xend = NULL,
  y = NULL,
  yend = NULL,
  colour = NULL,
  linetype = NULL,
  linewidth = NULL,
  ...,
  rasterize = FALSE,
  rasterize_dpi = 300,
  rasterize_dev = "cairo"
)
```

## Arguments

- plot:

  A plotit object

- xintercept:

  x-intercept for vertical line(s)

- yintercept:

  y-intercept for horizontal line(s)

- slope:

  Line slope for abline

- intercept:

  Line intercept for abline

- x:

  Start x coordinate(s) for segment

- xend:

  End x coordinate(s) for segment

- y:

  Start y coordinate(s) for segment

- yend:

  End y coordinate(s) for segment

- colour:

  Line colour

- linetype:

  Line type

- linewidth:

  Line width in mm

- ...:

  Other arguments passed to the underlying geom

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

- `xintercept` →
  [ggplot2::geom_vline](https://ggplot2.tidyverse.org/reference/geom_abline.html)

- `yintercept` →
  [ggplot2::geom_hline](https://ggplot2.tidyverse.org/reference/geom_abline.html)

- `slope` + `intercept` →
  [ggplot2::geom_abline](https://ggplot2.tidyverse.org/reference/geom_abline.html)

- `x`/`xend`/`y`/`yend` →
  [ggplot2::geom_segment](https://ggplot2.tidyverse.org/reference/geom_segment.html)

Dispatch priority: vline/hline \> abline \> segment.

## References

Vega-Lite: [Rule](https://vega.github.io/vega-lite/docs/rule.html)

AntV G2: [LineX](https://g2.antv.antgroup.com/en/api/mark/line-x) /
[LineY](https://g2.antv.antgroup.com/en/api/mark/line-y) /
[Range](https://g2.antv.antgroup.com/en/api/mark/range)

## Examples

``` r
plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
  mark_rule(xintercept = 3, colour = "red", linetype = "dashed")
```
