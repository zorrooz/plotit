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
#> <plotit::plotit>
#>  @ gg  :A patchwork composed of 1 patches
#> - Autotagging is turned off
#> - Guides are kept
#> 
#> Layout:
#> 1 patch areas, spanning 1 columns and 1 rows
#> 
#>     t l b r
#> 1:  1 1 1 1
#>  @ meta: <plotit::plotit_metadata>
#>  .. @ autofit      : logi FALSE
#>  .. @ width        : num 7
#>  .. @ height       : num 5
#>  .. @ unit         : chr "in"
#>  .. @ dodge        : num 0
#>  .. @ default_color: chr "#4E79A7"
#>  .. @ labels       : <plotit::plotit_labels>
#>  .. .. @ title   : NULL
#>  .. .. @ subtitle: NULL
#>  .. .. @ caption : NULL
#>  .. .. @ x       : NULL
#>  .. .. @ y       : NULL
#>  .. .. @ legend  : NULL
#>  .. .. @ dirty   : list()
```
