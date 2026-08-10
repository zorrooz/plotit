# Network / force-directed graph layer

Creates a network visualization with nodes and edges. Requires the
ggraph and igraph packages.

## Usage

``` r
mark_network(
  plot,
  edges = NULL,
  encode_edges = NULL,
  layout = c("auto", "circle", "linear", "bipartite", "manual"),
  edge_colour = "grey70",
  edge_width = 0.5,
  node_colour = "#4E79A7",
  node_size = 5,
  ...
)
```

## Arguments

- plot:

  A plotit object. The data should be a data.frame of **nodes**.

- edges:

  A data.frame of **edges**.

- encode_edges:

  An [`encode()`](https://zorrooz.github.io/plotit/reference/encode.md)
  object with `source` (required), `target` (required), `weight`
  (optional).

- layout:

  Layout algorithm: `"auto"`, `"circle"`, `"linear"`, `"bipartite"`, or
  `"manual"`.

- edge_colour:

  Default colour for edges (default `"grey70"`).

- node_colour:

  Default fill colour for nodes (default `"#4E79A7"`).

- node_size:

  Default size for nodes (default 5).

- ...:

  Other arguments passed to
  [`ggraph::geom_edge_link`](https://ggraph.data-imaginist.com/reference/geom_edge_link.html)

## Value

Modified plotit object

## Details

**Dual data source design**: The main data (passed to
[`plotit()`](https://zorrooz.github.io/plotit/reference/plotit.md)) is a
**nodes** data.frame. Edges are passed via the `edges` parameter with
their own `encode_edges`. Node aesthetics (`color`, `size`, `label`)
work with standard `scale_*` functions.

## References

AntV G2:
[ForceGraph](https://g2.antv.antgroup.com/en/api/mark/force-graph)

## Examples

``` r
if (FALSE) { # \dontrun{
if (requireNamespace("ggraph", quietly = TRUE) &&
    requireNamespace("igraph", quietly = TRUE)) {
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
  nodes |> plotit(encode(color = group, size = value, label = name)) |>
    mark_network(
      edges = edges,
      encode_edges = encode(source = from, target = to, weight = weight)
    ) |>
    scale_color(range = "viridis") |>
    scale_size(range = c(5, 20))
}
} # }
```
