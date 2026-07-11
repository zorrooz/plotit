# Rectangle layer

Adds a rectangle or tile layer. Use for heatmaps, grid cells, Gantt
charts, or any plot where both x and y span a range.

## Usage

``` r
mark_rect(
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

  Other arguments passed to `geom_tile`

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

Vega-Lite: [Rect](https://vega.github.io/vega-lite/docs/rect.html)

AntV G2: [Cell](https://g2.antv.antgroup.com/en/api/mark/cell) /
[Rect](https://g2.antv.antgroup.com/en/api/mark/rect)

## Examples

``` r
df <- expand.grid(x = 1:5, y = 1:5)
df$z <- df$x * df$y
plotit(df, encode(x = x, y = y, fill = z)) |> mark_rect()
```
