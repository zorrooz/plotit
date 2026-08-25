# Treemap layer (sugar)

Creates a treemap from a **hierarchy table** (`id`/`parent` columns,
leaf sizes in a `value` column) using plotit's self-contained squarified
tiling. Equivalent to the pipeline
`as_graph(hierarchy) |> layout_treemap() |> mark_rect(data = ~leaves)`;
the laid-out tables (`nodes`/`edges`/`leaves`) are stored on `@graph`
for further tuning.

## Usage

``` r
mark_treemap(
  plot,
  data = NULL,
  node_colour = ._MARK_STYLE$primary,
  show_labels = TRUE,
  ...,
  rasterize = FALSE,
  rasterize_dpi = 300,
  rasterize_dev = "cairo"
)
```

## Arguments

- plot:

  A plotit object whose data is a hierarchy table with `id`, `parent`,
  and leaf-level `value` columns (build via
  [`as_graph()`](https://zorrooz.github.io/plotit/reference/as_graph.md)
  on the same shape). A global `encode(fill = ...)` maps tile fill
  against any hierarchy column.

- data:

  Optional hierarchy table for this layer.

- node_colour:

  Default tile fill when no fill aesthetic is mapped (default
  `._MARK_STYLE$primary` = `"#4E79A7"`).

- show_labels:

  If `TRUE` (default), draw leaf ids at tile centres. Labels render
  white over the unmapped brand-blue fill; when a fill is mapped they
  fall back to near-black – chain
  `mark_text(data = ~leaves, colour = ...)` for full control.

- ...:

  Unused; tiling fine-tuning lives on
  [`layout_treemap()`](https://zorrooz.github.io/plotit/reference/layout_treemap.md)
  in the explicit pipeline form.

- rasterize:

  If `TRUE`, rasterize via
  [`ggrastr::rasterise()`](https://rdrr.io/pkg/ggrastr/man/rasterise.html).

- rasterize_dpi:

  DPI for rasterization (default 300).

- rasterize_dev:

  Graphics device for rasterization (default `"cairo"`).

## Value

Modified plotit object; `@graph` holds nodes/edges/leaves.

## Details

Fully self-contained: no treemapify dependency, deterministic Bruls
squarify layout. Tiles receive the unified white hairline separators and
coordinate axes are blanked (the diagram is coordinate-free). A mapped
`fill` column ships with the curated token palette – friendly
qualitative for categories, viridis sequential for continuous values
(chain
[`scale_fill()`](https://zorrooz.github.io/plotit/reference/scale_fill.md)
to replace it).

## References

AntV G2: [Treemap](https://g2.antv.antgroup.com/en/api/mark/treemap)
(graphlib)

## Examples

``` r
h <- data.frame(
  id     = c("root", "A", "B", "a1", "a2", "b1"),
  parent = c(NA, "root", "root", "A", "A", "B"),
  value  = c(NA, NA, NA, 30, 20, 50)
)
h |>
  plotit(encode(fill = id)) |>
  mark_treemap()
```
