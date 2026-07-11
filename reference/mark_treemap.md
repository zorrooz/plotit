# Treemap layer

Creates a treemap showing hierarchical data as nested rectangles.
Requires the treemapify package. Data should contain `area`, `subgroup`,
and optionally `subgroup2` columns.

## Usage

``` r
mark_treemap(
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

  Optional new aesthetics. Must include `area` for rectangle sizing.

- data:

  Optional data for this layer

- position:

  Position adjustment.

- ...:

  Other arguments passed to `geom_treemap`

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

AntV G2: [Treemap](https://g2.antv.antgroup.com/en/api/mark/treemap)
(graphlib)

## Examples

``` r
if (FALSE) { # \dontrun{
if (requireNamespace("treemapify", quietly = TRUE)) {
  df <- data.frame(
    group = c("A", "B", "C"),
    subgroup = c("a1", "a2", "b1"),
    size = c(30, 20, 50))
  plotit(df, encode(area = size, fill = group,
                    subgroup = subgroup)) |>
    mark_treemap()
}
} # }
```
