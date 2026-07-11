# Text layer

Adds a text label layer. For automatic label placement with collision
avoidance, install the optional ggrepel package and set `repel = TRUE`.

## Usage

``` r
mark_text(
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

  Other arguments passed to `geom_text` or `geom_text_repel`

- repel:

  If `TRUE`, use `ggrepel::geom_text_repel` instead of `geom_text`.
  Requires the ggrepel package.

- rasterize:

  If `TRUE`, rasterize via
  [`ggrastr::rasterise()`](https://rdrr.io/pkg/ggrastr/man/rasterise.html).

- rasterize_dpi:

  DPI for rasterization (default 300).

- rasterize_dev:

  Graphics device for rasterization (default `"cairo"`).

## Value

Modified plotit object

## Examples

``` r
plotit(mtcars, encode(x = wt, y = mpg, label = rownames(mtcars))) |>
  mark_text(size = 3)
```
