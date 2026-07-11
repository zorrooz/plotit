# Correlation matrix heatmap

Computes a correlation matrix from numeric data columns, optionally
reorders by hierarchical clustering, and renders it as a tile heatmap.

## Usage

``` r
mark_corr(
  plot,
  method = c("pearson", "spearman", "kendall"),
  reorder = TRUE,
  ...,
  rasterize = FALSE,
  rasterize_dpi = 300,
  rasterize_dev = "cairo"
)
```

## Arguments

- plot:

  A plotit object. Numeric columns are extracted from the plot data for
  correlation computation.

- method:

  Correlation method: `"pearson"` (default), `"spearman"`, or
  `"kendall"`.

- reorder:

  If `TRUE` (default), reorder rows and columns by hierarchical
  clustering.

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

AntV G2: [Cell](https://g2.antv.antgroup.com/en/api/mark/cell)
(correlation matrix expression)

## Examples

``` r
plotit(mtcars, encode()) |> mark_corr()
```
