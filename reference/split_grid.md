# Generic for grid facets

Generic for grid facets

## Usage

``` r
split_grid(
  plot,
  ...,
  rows = NULL,
  cols = NULL,
  scales = "fixed",
  space = "fixed"
)
```

## Arguments

- plot:

  A plotit object.

- ...:

  Unnamed arguments are shorthand for `rows` (e.g. `Species` becomes
  `rows = vars(Species)`). Named arguments (`labeller`, `switch`, ...)
  are passed through to
  [`ggplot2::facet_grid()`](https://ggplot2.tidyverse.org/reference/facet_grid.html).

- rows, cols:

  Variables to facet by, wrapped in
  [`ggplot2::vars()`](https://ggplot2.tidyverse.org/reference/vars.html).

- scales:

  Should scales be fixed ("fixed"), free ("free"), or free in one
  dimension ("free_x", "free_y")?

- space:

  Should the space be fixed ("fixed"), free ("free"), or free in one
  dimension ("free_x", "free_y")?

## Value

A modified `plotit` object.

## Examples

``` r
plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
  mark_point() |>
  split_grid(rows = ggplot2::vars(Species))
```
