# Tree layout

Arranges a rooted hierarchy with
[igraph::layout_as_tree](https://r.igraph.org/reference/layout_as_tree.html).
Edges must point from parent to child; multiple roots (forests) are
supported.

## Usage

``` r
layout_tree(plot, direction = c("down", "up", "left", "right"))
```

## Arguments

- plot:

  A `plotit` object holding graph data (created via
  [`as_graph()`](https://zorrooz.github.io/plotit/reference/as_graph.md) +
  [`plotit()`](https://zorrooz.github.io/plotit/reference/plotit.md)),
  or a bare `plotit_graph`.

- direction:

  Direction the tree grows: `"down"` (root on top), `"up"`, `"right"`,
  or `"left"`.

## Value

A modified `plotit` object (pipeline form), or a new `plotit_graph` when
called on raw graph data.

## Examples

``` r
hc <- hclust(dist(USArrests[, 1:3]))
as_graph(hc) |>
  plotit() |>
  layout_tree(direction = "down") |>
  mark_rule(data = ~edges) |>
  mark_point(data = ~nodes)
```
