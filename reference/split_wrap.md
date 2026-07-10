# Generic for wrapping facets

Generic for wrapping facets

## Usage

``` r
split_wrap(plot, ..., nrow = NULL, ncol = NULL, scales = "fixed")
```

## Arguments

- plot:

  A plotit object.

- ...:

  Unnamed arguments are faceting variables (e.g. `Species`); named
  arguments (`labeller`, `strip.position`, `dir`, `drop`, ...) are
  passed through to
  [`ggplot2::facet_wrap()`](https://ggplot2.tidyverse.org/reference/facet_wrap.html).

- nrow:

  Number of rows in the facet grid (optional).

- ncol:

  Number of columns in the facet grid (optional).

- scales:

  Should scales be fixed ("fixed"), free ("free"), or free in one
  dimension ("free_x", "free_y")?

## Value

A modified `plotit` object.

## Examples

``` r
plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
  mark_point() |>
  split_wrap(Species, ncol = 3)
```
