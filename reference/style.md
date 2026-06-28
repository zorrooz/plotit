# Modify plot theme (aligns with ggplot2::theme)

Applies plotit's default theme and overrides individual elements via
`...`. Call `style(p)` without arguments to apply the default theme, or
pass theme-element overrides like
`style(p, plot.title = element_text(face="bold"))`. Use `base_theme` to
switch to an entirely different base theme (e.g.,
`style(p, base_theme = ggplot2::theme_bw())`).

## Usage

``` r
style(plot, ..., base_size = NULL, base_family = NULL, base_theme = NULL)
```

## Arguments

- plot:

  A plotit object.

- ...:

  Theme element overrides, passed to
  [`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html).

- base_size:

  Base font size in pts (default 11).

- base_family:

  Base font family (default `""` = system sans-serif).

- base_theme:

  A complete ggplot2 theme object to use instead of the default (e.g.,
  [`ggplot2::theme_bw()`](https://ggplot2.tidyverse.org/reference/ggtheme.html)).
  `NULL` = use plotit default.

## Value

Modified plotit object.

## Examples

``` r
plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
  mark_point() |>
  style()
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
