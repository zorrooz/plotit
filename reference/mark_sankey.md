# Sankey flow diagram layer (sugar)

Creates a Sankey diagram showing directed flows between nodes.
Equivalent to the pipeline
`as_graph() |> layout_sankey() |> mark_polygon(data = ~ribbons) |> mark_rect(data = ~nodes)`
– see \<U+00A7\>3.3.4a. Accepts an **edges table** with `source`,
`target`, and optionally `value` columns (either mapped via structural
aesthetics or present as literal columns); node and ribbon geometry come
from the built-in layered layout (deterministic, dependency-free). The
derived flow/node fill channel defaults to source identity and ships
with the curated token palette – friendly qualitative for categories,
viridis sequential for continuous values; chain
[`scale_fill()`](https://zorrooz.github.io/plotit/reference/scale_fill.md)
to replace it (last call wins).

## Usage

``` r
mark_sankey(
  plot,
  mapping = NULL,
  data = NULL,
  ...,
  node_color = ._MARK_STYLE$ink,
  edge_alpha = ._MARK_STYLE$alpha_link,
  show_labels = TRUE
)
```

## Arguments

- plot:

  A plotit object

- mapping:

  Structural aesthetics: `source` (required), `target` (required),
  `value` (optional). Visual: `fill` colours ribbons and nodes alike;
  ribbons default to source identity.

- data:

  Optional edges data.frame for this layer

- ...:

  Unused; fine-tuning (padding, curvature, node width) lives on
  [`layout_sankey()`](https://zorrooz.github.io/plotit/reference/layout_sankey.md)
  in the explicit pipeline form.

- node_color:

  Default colour for node rectangles (used when no `fill` mapping is
  present, default `._MARK_STYLE$ink` = `"grey30"`).

- edge_alpha:

  Alpha transparency for flow ribbons (default `._MARK_STYLE$alpha_link`
  = 0.5).

- show_labels:

  If `TRUE` (default), draw node ids inside the strips.

## Value

Modified plotit object; `@graph` holds the laid-out tables.

## Details

The laid-out graph (`nodes` / `edges` / `ribbons` tables) is stored on
`@graph`, so subsequent marks can reference any table directly for
tuning beyond this sugar's two parameters.

## References

AntV G2: [Sankey](https://g2.antv.antgroup.com/en/api/mark/sankey)
(graphlib)

## Examples

``` r
df <- data.frame(
  source = c("A", "A", "B", "B", "C"),
  target = c("B", "C", "C", "D", "D"),
  value  = c(10, 5, 8, 3, 6)
)
df |>
  plotit(encode(
    source = source, target = target,
    value = value, fill = source
  )) |>
  mark_sankey() |>
  scale_fill(range = "viridis")
#> Coordinate system already present.
#> ℹ Adding new coordinate system, which will replace the existing one.
#> Warning: `range` = "viridis" with a discrete "fill" variable uses the discrete "viridis"
#> variant.
#> ℹ For a continuous gradient, map a numeric column instead.
#> Scale for fill is already present.
#> Adding another scale for fill, which will replace the existing scale.
```
