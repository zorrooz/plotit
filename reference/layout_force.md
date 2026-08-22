# Force-directed layout

Positions nodes with a Fruchterman-Reingold force simulation
([igraph::layout_with_fr](https://r.igraph.org/reference/layout_with_fr.html)).
Node table gains `x`/`y`; edge table gains `x`, `y`, `xend`, `yend`.

## Usage

``` r
layout_force(plot, iterations = 500, seed = NULL, ...)
```

## Arguments

- plot:

  A `plotit` object holding graph data (created via
  [`as_graph()`](https://zorrooz.github.io/plotit/reference/as_graph.md) +
  [`plotit()`](https://zorrooz.github.io/plotit/reference/plotit.md)),
  or a bare `plotit_graph`.

- iterations:

  Number of simulation steps.

- seed:

  Random seed; pass one for reproducible output.

- ...:

  Passed to
  [igraph::layout_with_fr](https://r.igraph.org/reference/layout_with_fr.html)
  (e.g. `weights`, `area`).

## Value

A modified `plotit` object (pipeline form), or a new `plotit_graph` when
called on raw graph data.

## Examples

``` r
e <- data.frame(source = c("a", "a", "b"), target = c("b", "c", "c"))
g <- as_graph(e) |> layout_force(seed = 1)
g$nodes
#>   id          x         y
#> 1  a -0.4025036 0.3069924
#> 2  b -1.0921567 1.0286396
#> 3  c -0.1223654 1.2650731

as_graph(e) |> plotit() |>
  layout_force(seed = 1) |>
  mark_point(data = ~nodes) |>
  mark_rule(data = ~edges, colour = "grey70")
```
