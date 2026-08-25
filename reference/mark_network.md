# Network / force-directed graph layer (sugar)

Creates a network visualization from a **nodes** table (main data) plus
an **edges** table. Equivalent to the pipeline
`as_graph() |> layout_force()/layout_circle() |> mark_point(data = ~nodes) |> mark_rule(data = ~edges)`
– the composite form exists so common network plots stay one-call
simple. The laid-out graph is stored on `@graph`, so subsequent marks
can reference `~nodes` / `~edges` directly, and layers/scales/theme
added *before* this call are preserved (additive composition).

## Usage

``` r
mark_network(
  plot,
  edges = NULL,
  encode_edges = NULL,
  layout = c("auto", "circle", "linear", "bipartite", "manual"),
  seed = NULL,
  edge_colour = ._MARK_STYLE$faint,
  edge_width = ._MARK_STYLE$lw_thin,
  node_colour = ._MARK_STYLE$primary,
  node_size = 5,
  ...
)
```

## Arguments

- plot:

  A plotit object. The data should be a data.frame of **nodes** whose
  first column is a unique id.

- edges:

  A data.frame of **edges**.

- encode_edges:

  An [`encode()`](https://zorrooz.github.io/plotit/reference/encode.md)
  object with `source` (required), `target` (required), `value`
  (optional magnitude; `weight` is a deprecated alias). Visual channels
  supported on edges: `colour`/`linewidth`/`linetype`/`alpha`,
  referenced against original edge columns. When omitted, `edges` may
  carry literal `source`/`target`/`value` columns.

- layout:

  Layout algorithm: `"auto"` (force-directed), `"circle"`, or
  `"manual"`. `"linear"` and `"bipartite"` are deprecated and fall back
  to `"auto"`.

- seed:

  Random seed for the force layout (reproducibility).

- edge_colour:

  Default edge colour when no edge colour channel is mapped (default
  `._MARK_STYLE$faint` = `"grey70"`).

- edge_width:

  Default edge width when no edge linewidth channel is mapped (default
  `._MARK_STYLE$lw_thin` = 0.5).

- node_colour:

  Default node colour, applied to the `colour` and `fill` channels only
  where they are not mapped (default `._MARK_STYLE$primary` =
  `"#4E79A7"`).

- node_size:

  Default node size when `size` is not mapped (default 5).

- ...:

  Other arguments passed to the edge segment layer (e.g. `arrow`).

## Value

Modified plotit object; `@graph` holds the laid-out tables.

## Details

Fully self-contained: the force/circle layouts run on plotit's own
deterministic engines and rendering is plain ggplot2 layers. Edges
render as straight segments; curved edges are a known limitation of the
sugar form. Mapped node colour/fill channels ship with the curated token
palette (friendly qualitative / viridis sequential, chain
[`scale_color()`](https://zorrooz.github.io/plotit/reference/scale_color.md)
to replace).

## References

AntV G2:
[ForceGraph](https://g2.antv.antgroup.com/en/api/mark/force-graph)

## Examples

``` r
nodes <- data.frame(
  name  = c("A", "B", "C", "D"),
  group = c("X", "Y", "X", "Y"),
  value = c(10, 20, 15, 25)
)
edges <- data.frame(
  from   = c("A", "A", "B", "C"),
  to     = c("B", "C", "C", "D"),
  weight = c(1, 2, 3, 4)
)
nodes |>
  plotit(encode(color = group, size = value, label = name)) |>
  mark_network(
    edges = edges,
    encode_edges = encode(source = from, target = to, value = weight),
    seed = 1
  ) |>
  scale_color(range = "viridis") |>
  scale_size(range = c(5, 20))
#> Scale for colour is already present.
#> Adding another scale for colour, which will replace the existing scale.
```
