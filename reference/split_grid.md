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
