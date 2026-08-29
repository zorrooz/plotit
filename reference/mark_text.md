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

  Other arguments passed to `geom_text` or `geom_text_repel`. With
  `repel = TRUE` the frequently used ggrepel passthrough parameters are
  (defaults from the ggrepel docs): `max.overlaps` (plural! labels
  overlapping more than this many others are dropped; default
  `getOption("ggrepel.max.overlaps", 10)`; `Inf` keeps every label),
  `min.segment.length = 0.5` (leader-line threshold, `0` draws all),
  `force = 1`, `force_pull = 1`, `direction = "both"`, `seed = NA` (set
  a number for reproducible placement), `nudge_x = 0`, `nudge_y = 0`,
  `point.padding = 1e-6`, `box.padding = 0.25`, `max.time = 0.5`,
  `max.iter = 10000`, `xlim = c(NA, NA)`, `ylim = c(NA, NA)`.

- repel:

  If `TRUE`, use
  [`ggrepel::geom_text_repel`](https://ggrepel.slowkow.com/reference/geom_text_repel.html)
  instead of `geom_text`. Requires the ggrepel package.

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

Observable Plot: `Plot.text`

ggrepel:
[geom_text_repel](https://ggrepel.slowkow.com/reference/geom_text_repel.html)

## Examples

``` r
plotit(mtcars, encode(x = wt, y = mpg, label = rownames(mtcars))) |>
  mark_text(size = 3)
```
