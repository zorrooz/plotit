# Label layer

Adds a text layer where every label sits inside a rounded box – the
readable-over-data sibling of
[`mark_text()`](https://zorrooz.github.io/plotit/reference/mark_text.md).
For collision-avoiding placement, install the optional ggrepel package
and set `repel = TRUE`.

## Usage

``` r
mark_label(
  plot,
  mapping = NULL,
  data = NULL,
  position = NULL,
  ...,
  repel = FALSE,
  rasterize = FALSE,
  rasterize_dpi = 300,
  rasterize_dev = "cairo"
)
```

## Arguments

- plot:

  A plotit object

- mapping:

  Optional new aesthetics (e.g. `encode(label = ...)`)

- data:

  Optional data for this layer

- position:

  Position adjustment.

- ...:

  Other arguments passed to `geom_label` or `geom_label_repel`. With
  `repel = TRUE` the ggrepel passthrough parameters are the same as
  [`mark_text()`](https://zorrooz.github.io/plotit/reference/mark_text.md)
  (see its `@param ...` for the full list with defaults);
  `geom_label_repel` additionally styles the box with
  `label.padding = 0.25`, `label.r = 0.15`, `label.size = 0.25`. Without
  repel, ggplot2 4.0 styles the box with the `linewidth` aesthetic (the
  old `label.size` argument is deprecated): use
  `mark_label(linewidth = 0.4)`; `border.colour`/`text.colour` style the
  box and text independently.

- repel:

  If `TRUE`, use
  [`ggrepel::geom_label_repel`](https://ggrepel.slowkow.com/reference/geom_text_repel.html)
  instead of `geom_label`. Requires the ggrepel package.

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

AntV G2: [Text](https://g2.antv.antgroup.com/en/api/mark/text) (`badge`
state)

## Examples

``` r
agg <- aggregate(mpg ~ cyl, data = mtcars, FUN = mean)
plotit(agg, encode(x = cyl, y = mpg, label = round(mpg, 1))) |>
  mark_point() |>
  mark_label(nudge_y = 1.5, size = 3)
```
