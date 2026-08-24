# Tree layout

Arranges a rooted hierarchy: leaves spread left-to-right in merge-side
order and internal nodes sit at the mean leaf position of their
children. Self-contained (no external dependency). Edges must point from
parent to child; multiple roots (forests) are supported.

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
h <- data.frame(
  id     = c("root", "A", "B", "a1", "a2"),
  parent = c(NA, "root", "root", "A", "A")
)
as_graph(h) |>
  plotit() |>
  layout_tree(direction = "down") |>
  mark_rule(data = ~edges) |>
  mark_point(data = ~nodes)
```
