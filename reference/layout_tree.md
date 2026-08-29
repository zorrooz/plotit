# Tree layout

Arranges a rooted hierarchy: leaves spread left-to-right in merge-side
order and internal nodes sit at the mean leaf position of their
children. Self-contained (no external dependency). Edges must point from
parent to child; multiple roots (forests) are supported.

## Usage

``` r
layout_tree(
  plot,
  direction = c("down", "up", "left", "right"),
  leaf_spacing = "count",
  edge = "straight"
)
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

- leaf_spacing:

  Leaf placement: `"count"` packs leaves one unit apart in merge-side
  order (d3 tidy-tree); `"equal"` normalises leaves onto `[0, 1]` so
  leaf slots align with split-facet panels.

- edge:

  Edge shape: `"straight"` (direct parent-child segments) or `"elbow"`
  (right-angle bend via a midpoint row pair; each edge becomes two rows
  in the edges table so
  [`mark_rule()`](https://zorrooz.github.io/plotit/reference/mark_rule.md)
  renders the polyline).

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


as_graph(h) |>
  plotit() |>
  layout_tree(direction = "right", edge = "elbow") |>
  mark_rule(data = ~edges) |>
  mark_point(data = ~nodes)
```
