# Matrix heatmap layer (sugar)

Renders a tidyheatmaps-style matrix heatmap as a plotit mark. Accepts a
numeric matrix, a wide numeric data.frame (columns become heatmap
columns), or a tidy long mapping (`encode(x =, y =, fill =)`).
Optionally z-score normalises rows/columns
([`base::scale()`](https://rdrr.io/r/base/scale.html)) and reorders them
by hierarchical clustering
([`stats::hclust()`](https://rdrr.io/r/stats/hclust.html)). The tile
grid reuses the shared mark path, so it inherits the white-hairline cell
chrome (tiles hug the panel, no 0-origin whitespace) and the
colour-blind-safe viridis fill default; chain
[`scale_fill()`](https://zorrooz.github.io/plotit/reference/scale_fill.md)
to replace it (last call wins). This is a mark, not a separate system:
combine it with
[`layout_dendrogram()`](https://zorrooz.github.io/plotit/reference/layout_dendrogram.md)
and
[`compose_marginal()`](https://zorrooz.github.io/plotit/reference/compose_marginal.md)
for a full annotated heatmap.

## Usage

``` r
mark_heatmap(
  plot,
  cluster = c("both", "row", "column", "none"),
  scale = c("none", "row", "column"),
  show_numbers = FALSE,
  number_format = "%.2f",
  number_color = NULL,
  na_color = "grey85",
  range = NULL,
  ...,
  rasterize = FALSE,
  rasterize_dpi = 300,
  rasterize_dev = "cairo"
)
```

## Arguments

- plot:

  A plotit object carrying the matrix / data.frame / tidy mapping.

- cluster:

  Reorder axes by hierarchical clustering: `"both"` (default), `"row"`,
  `"column"`, or `"none"`.

- scale:

  z-score normalisation: `"none"` (default), `"row"`, or `"column"`.

- show_numbers:

  Print the value of each cell inside the tile (default `FALSE`);
  implemented as a `mark_text` overlay.

- number_format:

  Format string for the cell numbers (default `"%.2f"`).

- number_color:

  Cell number colour; `NULL` (default) applies auto-contrast (white on
  dark cells, ink on light cells).

- na_color:

  Fill colour for `NA` cells (default `"grey85"`; the tidyheatmaps
  `color_na` counterpart).

- range:

  Fill scale for the cell values: a scheme name (`"viridis"` default for
  sequential data; `"rdbu"`/`"spectral"`/`"brbg"` etc. for diverging
  data), a colour vector, or `NULL` for the default.

- ...:

  Other arguments passed to
  [`ggplot2::geom_tile()`](https://ggplot2.tidyverse.org/reference/geom_tile.html).

- rasterize:

  If `TRUE`, rasterize via
  [`ggrastr::rasterise()`](https://rdrr.io/pkg/ggrastr/man/rasterise.html).

- rasterize_dpi:

  DPI for rasterization (default 300).

- rasterize_dev:

  Graphics device for rasterization (default `"cairo"`).

## Value

Modified plotit object.

## References

R: [`stats::hclust()`](https://rdrr.io/r/stats/hclust.html) /
[`stats::dist()`](https://rdrr.io/r/stats/dist.html) (row/column
clustering) tidyheatmaps: [Heatmaps from Tidy
Data](https://jbengler.github.io/tidyheatmaps/)

## Examples

``` r
mat <- matrix(rnorm(30),
  nrow = 6,
  dimnames = list(paste0("g", 1:6), paste0("s", 1:5))
)
plotit(mat, encode()) |> mark_heatmap()

plotit(mat, encode()) |> mark_heatmap(cluster = "both", scale = "row")
```
