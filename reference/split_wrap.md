# Generic for wrapping facets

Generic for wrapping facets

## Usage

``` r
split_wrap(plot, ..., nrow = NULL, ncol = NULL, scales = "fixed", dir = NULL)
```

## Arguments

- plot:

  A plotit object.

- ...:

  Unnamed arguments are faceting variables (e.g. `Species`); named
  arguments (`labeller`, `strip.position`, `drop`, ...) are passed
  through to
  [`ggplot2::facet_wrap()`](https://ggplot2.tidyverse.org/reference/facet_wrap.html).

- nrow:

  Number of rows in the facet grid (optional).

- ncol:

  Number of columns in the facet grid (optional).

- scales:

  Should scales be fixed ("fixed"), free ("free"), or free in one
  dimension ("free_x", "free_y")?

- dir:

  Facet fill direction code passed to
  [`ggplot2::facet_wrap()`](https://ggplot2.tidyverse.org/reference/facet_wrap.html):
  ggplot2 4.0 supports the eight-direction codes `"lt"`, `"tl"`, `"lb"`,
  `"bl"`, `"rt"`, `"tr"`, `"rb"`, `"br"` (first letter = first-panel
  corner, second letter = fill direction). `NULL` = ggplot2 default.

## Value

A modified `plotit` object.

## Examples

``` r
plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
  mark_point() |>
  split_wrap(Species, ncol = 3)
```
