# Network / force-directed graph layer

Creates a network visualization with nodes and edges. Requires the
ggraph and igraph packages.

## Usage

``` r
mark_network(
  plot,
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

  A plotit object. The data should be an `igraph` object.

- layout:

  Layout algorithm: `"auto"` (default, uses `layout_with_fr`),
  `"circle"`, `"linear"`, `"bipartite"`, or `"manual"`.

- edge_colour:

  Colour for edges (default `"grey70"`).

- edge_width:

  Width for edges (default 0.5).

- node_colour:

  Fill colour for nodes (default `"#4E79A7"`).

- node_size:

  Size for nodes (default 5).

- ...:

  Other arguments passed to
  [`ggraph::geom_edge_link`](https://ggraph.data-imaginist.com/reference/geom_edge_link.html)
  and
  [`ggraph::geom_node_point`](https://ggraph.data-imaginist.com/reference/geom_node_point.html)

## Value

Modified plotit object

## References

AntV G2:
[ForceGraph](https://g2.antv.antgroup.com/en/api/mark/force-graph)
(graphlib)

## Examples

``` r
if (FALSE) { # \dontrun{
if (requireNamespace("ggraph", quietly = TRUE) &&
    requireNamespace("igraph", quietly = TRUE)) {
  gr <- igraph::sample_pa(30)
  plotit(gr, encode()) |> mark_network()
}
} # }
```
