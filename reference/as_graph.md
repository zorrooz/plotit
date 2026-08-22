# Convert relational data to a plotit graph

Coerces edge lists, adjacency matrices, contingency tables, cluster
trees, or `tbl_graph` objects into a `plotit_graph`: a named list of
data frames (`nodes`, `edges`) that can initialize
[`plotit()`](https://zorrooz.github.io/plotit/reference/plotit.md) and
be positioned by `layout_*()` transforms. Layout coordinates are never
mapped by hand – they are produced by layouts and bound automatically at
mark time.

## Usage

``` r
as_graph(
  edges,
  nodes = NULL,
  source = "source",
  target = "target",
  value = NULL,
  directed = FALSE
)
```

## Arguments

- edges:

  Primary relational input. One of:

  - a data.frame edge list (columns selected by
    `source`/`target`/`value`);

  - a matrix or `xtabs`/table of flows (melted automatically);

  - an `hclust` or `dendrogram` object;

  - a `tbl_graph`.

- nodes:

  Optional node attribute table. Must contain a column named `id`. When
  omitted, nodes are generated implicitly from the edge endpoints in
  first-appearance order.

- source, target:

  Column names (bare or quoted) locating the edge endpoints in `edges`.
  Defaults `"source"` / `"target"`.

- value:

  Column name (bare or quoted) holding flow magnitudes. Defaults to a
  column named `"value"` when present, otherwise unit weights are used.
  The output column is always named `value`.

- directed:

  Logical; whether the relation is directed.

## Value

An S3 `plotit_graph` object: a named list with at least `nodes` (`id`
column first) and `edges` (`source`, `target`, `value`).

## Examples

``` r
e <- data.frame(source = c("a", "b"), target = c("b", "c"))
g <- as_graph(e)
names(g)
#> [1] "nodes" "edges"
g$edges
#>   source target value
#> 1      a      b     1
#> 2      b      c     1
```
