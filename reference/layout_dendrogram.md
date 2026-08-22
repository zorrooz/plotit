# Dendrogram layout

Positions a merge tree (from
[`as_graph()`](https://zorrooz.github.io/plotit/reference/as_graph.md)
applied to an `hclust` or `dendrogram` object) using node heights as the
depth axis. Leaf order follows the original merge sides, so label
ordering matches the cluster analysis output.

## Usage

``` r
layout_dendrogram(plot, direction = c("down", "up", "left", "right"))
```

## Arguments

- plot:

  A `plotit` object holding graph data, or a bare `plotit_graph`.

- direction:

  Direction the tree grows: `"down"` (root on top), `"up"`, `"right"`,
  or `"left"`.

## Value

A modified `plotit` object (pipeline form), or a new `plotit_graph` when
called on raw graph data.

## Examples

``` r
hc <- hclust(dist(USArrests[1:6, ]))
g <- as_graph(hc) |> layout_dendrogram()
head(g$nodes)
#>           id leaf height x y
#> 1    Alabama TRUE      0 5 0
#> 2     Alaska TRUE      0 6 0
#> 3    Arizona TRUE      0 3 0
#> 4   Arkansas TRUE      0 1 0
#> 5 California TRUE      0 4 0
#> 6   Colorado TRUE      0 2 0

as_graph(hc) |>
  plotit() |>
  layout_dendrogram(direction = "down") |>
  mark_rule(data = ~edges) |>
  mark_point(data = ~nodes)
```
