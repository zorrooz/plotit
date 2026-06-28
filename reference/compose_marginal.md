# Scatter plot with marginal distributions

Arranges a main scatter plot with marginal histogram or density plots on
the top (x-axis distribution) and right (y-axis distribution). The axes
are shared so that the marginal bins align exactly with the scatter
axes.

## Usage

``` r
compose_marginal(
  main,
  top,
  right,
  widths = c(4, 1),
  heights = c(1, 4),
  guides = "collect"
)
```

## Arguments

- main:

  A `plotit` scatter plot (must have both x and y mapped).

- top:

  A `plotit` histogram or density plot for the x variable. Typically
  built from the same data and x mapping as `main`, with the same
  `fill`/`colour` aesthetic to match.

- right:

  A `plotit` histogram or density plot for the y variable. Same
  conventions as `top`. Call `project_cartesian(flip = TRUE)` on this
  plot before passing it so the y-axis aligns with the scatter.

- widths:

  Relative column widths for the main and right-marginal panels. Default
  `c(4, 1)` = right marginal is 1/5 of total width.

- heights:

  Relative row heights for the top-marginal and main panels. Default
  `c(1, 4)` = top marginal is 1/5 of total height.

- guides:

  `"collect"` (default) to merge legends across all panels, `"keep"` to
  keep them separate, `NULL` for patchwork auto-detect.

## Value

A `plotit_composite` object. Pipe to
[`label_title()`](https://zorrooz.github.io/plotit/reference/label_title.md),
[`style()`](https://zorrooz.github.io/plotit/reference/style.md),
[`export()`](https://zorrooz.github.io/plotit/reference/export.md) as
usual.

## Examples

``` r
main <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |> mark_point()
top <- plotit(iris, encode(x = Sepal.Width, fill = Species)) |> mark_histogram(bins = 15, alpha = 0.5)
right <- plotit(iris, encode(x = Sepal.Length, fill = Species)) |>
  mark_histogram(bins = 15, alpha = 0.5) |>
  project_cartesian(flip = TRUE)
compose_marginal(main, top, right)
#> <plotit::plotit_composite>
#>  @ gg         :A patchwork composed of 4 patches
#> - Autotagging is turned off
#> - Guides are collected
#> 
#> Layout:
#> 4 patch areas, spanning 2 columns and 2 rows
#> 
#>     t l b r
#> 1:  1 1 1 1
#> 2:  2 1 2 1
#> 3:  1 2 1 2
#> 4:  2 2 2 2
#>  @ meta       : <plotit::plotit_metadata>
#>  .. @ autofit      : logi TRUE
#>  .. @ width        : NULL
#>  .. @ height       : NULL
#>  .. @ unit         : chr "in"
#>  .. @ dodge        : NULL
#>  .. @ default_color: NULL
#>  .. @ labels       : <plotit::plotit_labels>
#>  .. .. @ title   : NULL
#>  .. .. @ subtitle: NULL
#>  .. .. @ caption : NULL
#>  .. .. @ x       : NULL
#>  .. .. @ y       : NULL
#>  .. .. @ legend  : NULL
#>  .. .. @ dirty   : list()
#>  @ plots      :List of 3
#>  .. $ : <plotit::plotit>
#>  ..  ..@ gg  :A patchwork composed of 1 patches
#> - Autotagging is turned off
#> - Guides are kept
#> 
#> Layout:
#> 1 patch areas, spanning 1 columns and 1 rows
#> 
#>     t l b r
#> 1:  1 1 1 1
#>  ..  ..@ meta: <plotit::plotit_metadata>
#>  .. .. .. @ autofit      : logi FALSE
#>  .. .. .. @ width        : num 7
#>  .. .. .. @ height       : num 5
#>  .. .. .. @ unit         : chr "in"
#>  .. .. .. @ dodge        : num 0
#>  .. .. .. @ default_color: NULL
#>  .. .. .. @ labels       : <plotit::plotit_labels>
#>  .. .. .. .. @ title   : NULL
#>  .. .. .. .. @ subtitle: NULL
#>  .. .. .. .. @ caption : NULL
#>  .. .. .. .. @ x       : NULL
#>  .. .. .. .. @ y       : NULL
#>  .. .. .. .. @ legend  : NULL
#>  .. .. .. .. @ dirty   : list()
#>  .. $ : <plotit::plotit>
#>  ..  ..@ gg  :A patchwork composed of 1 patches
#> - Autotagging is turned off
#> - Guides are kept
#> 
#> Layout:
#> 1 patch areas, spanning 1 columns and 1 rows
#> 
#>     t l b r
#> 1:  1 1 1 1
#>  ..  ..@ meta: <plotit::plotit_metadata>
#>  .. .. .. @ autofit      : logi FALSE
#>  .. .. .. @ width        : num 7
#>  .. .. .. @ height       : num 5
#>  .. .. .. @ unit         : chr "in"
#>  .. .. .. @ dodge        : num 0
#>  .. .. .. @ default_color: NULL
#>  .. .. .. @ labels       : <plotit::plotit_labels>
#>  .. .. .. .. @ title   : NULL
#>  .. .. .. .. @ subtitle: NULL
#>  .. .. .. .. @ caption : NULL
#>  .. .. .. .. @ x       : NULL
#>  .. .. .. .. @ y       : NULL
#>  .. .. .. .. @ legend  : NULL
#>  .. .. .. .. @ dirty   : list()
#>  .. $ : <plotit::plotit>
#>  ..  ..@ gg  :A patchwork composed of 1 patches
#> - Autotagging is turned off
#> - Guides are kept
#> 
#> Layout:
#> 1 patch areas, spanning 1 columns and 1 rows
#> 
#>     t l b r
#> 1:  1 1 1 1
#>  ..  ..@ meta: <plotit::plotit_metadata>
#>  .. .. .. @ autofit      : logi FALSE
#>  .. .. .. @ width        : num 7
#>  .. .. .. @ height       : num 5
#>  .. .. .. @ unit         : chr "in"
#>  .. .. .. @ dodge        : num 0
#>  .. .. .. @ default_color: NULL
#>  .. .. .. @ labels       : <plotit::plotit_labels>
#>  .. .. .. .. @ title   : NULL
#>  .. .. .. .. @ subtitle: NULL
#>  .. .. .. .. @ caption : NULL
#>  .. .. .. .. @ x       : NULL
#>  .. .. .. .. @ y       : NULL
#>  .. .. .. .. @ legend  : NULL
#>  .. .. .. .. @ dirty   : list()
#>  @ layout     :List of 3
#>  .. $ type   : chr "marginal"
#>  .. $ widths : num [1:2] 4 1
#>  .. $ heights: num [1:2] 1 4
#>  @ annotations:List of 4
#>  .. $ title     : NULL
#>  .. $ subtitle  : NULL
#>  .. $ caption   : NULL
#>  .. $ tag_levels: NULL
```
