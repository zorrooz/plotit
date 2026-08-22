# Circular layout

Places all nodes on a unit circle, optionally sorted by connectivity.

## Usage

``` r
layout_circle(plot, order_by = c("id", "degree"))
```

## Arguments

- plot:

  A `plotit` object holding graph data, or a bare `plotit_graph`.

- order_by:

  `"id"` keeps node-table order; `"degree"` sorts nodes by descending
  degree before placement.

## Value

A modified `plotit` object (pipeline form), or a new `plotit_graph` when
called on raw graph data.

## Examples

``` r
e <- data.frame(source = c("a", "a", "b"), target = c("b", "c", "c"))
g <- as_graph(e) |> layout_circle()
g$nodes
#>   id          x    y
#> 1  a  0.0000000  1.0
#> 2  b  0.8660254 -0.5
#> 3  c -0.8660254 -0.5
```
