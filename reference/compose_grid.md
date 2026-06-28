# Assemble multiple plots into a grid layout

`compose_grid()` arranges `plotit` or `plotit_composite` objects into a
grid via
[`patchwork::wrap_plots()`](https://patchwork.data-imaginist.com/reference/wrap_plots.html).
The default vertical stack (`ncol = 1` when neither `ncol` nor `nrow` is
given) is the most common layout for report figures. Pipe the result to
[`label_title()`](https://zorrooz.github.io/plotit/reference/label_title.md)
/ [`style()`](https://zorrooz.github.io/plotit/reference/style.md) /
[`export()`](https://zorrooz.github.io/plotit/reference/export.md) just
as with a single `plotit`.

## Usage

``` r
compose_grid(
  ...,
  ncol = NULL,
  nrow = NULL,
  byrow = TRUE,
  widths = NULL,
  heights = NULL,
  guides = NULL,
  axes = "keep",
  tag_levels = NULL
)
```

## Arguments

- ...:

  `plotit` or `plotit_composite` objects to arrange.

- ncol:

  Number of columns. `NULL` (default) = auto; if both `ncol` and `nrow`
  are `NULL` defaults to 1 (vertical stack).

- nrow:

  Number of rows. `NULL` (default) = inferred from `ncol` and the number
  of plots.

- byrow:

  Fill direction: `TRUE` (default) = row-major.

- widths:

  Relative column widths, e.g. `c(1, 2)`.

- heights:

  Relative row heights.

- guides:

  `"collect"` to merge legends, `"keep"` to separate, `NULL` (default)
  for patchwork auto-detect.

- axes:

  `"collect"` to share all axes, `"collect_x"` or `"collect_y"` for a
  single direction, `"keep"` (default) to keep axes independent.

- tag_levels:

  Sub-figure tag scheme: `"A"` for uppercase letters, `"a"` for
  lowercase, `"1"` for numbers, `"i"` for roman numerals, or a custom
  character vector (e.g. `c("(a)", "(b)")`). `NULL` = no tags.

## Value

A `plotit_composite` object. Pipe it to
[`label_title()`](https://zorrooz.github.io/plotit/reference/label_title.md),
[`style()`](https://zorrooz.github.io/plotit/reference/style.md), or
[`export()`](https://zorrooz.github.io/plotit/reference/export.md).

## Examples

``` r
p1 <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
p2 <- plotit(iris, encode(x = Species, y = Sepal.Length)) |> mark_boxplot()
compose_grid(p1, p2)
#> <plotit::plotit_composite>
#>  @ gg         :A patchwork composed of 2 patches
#> - Autotagging is turned off
#> - Guides are kept
#> 
#> Layout:
#> 2 patch areas, spanning 2 columns and 1 rows
#> 
#>     t l b r
#> 1:  1 1 1 1
#> 2:  1 2 1 2
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
#>  @ plots      :List of 2
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
#>  .. .. .. @ default_color: chr "#4E79A7"
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
#>  .. .. .. @ dodge        : num 0.8
#>  .. .. .. @ default_color: chr "#4E79A7"
#>  .. .. .. @ labels       : <plotit::plotit_labels>
#>  .. .. .. .. @ title   : NULL
#>  .. .. .. .. @ subtitle: NULL
#>  .. .. .. .. @ caption : NULL
#>  .. .. .. .. @ x       : NULL
#>  .. .. .. .. @ y       : NULL
#>  .. .. .. .. @ legend  : NULL
#>  .. .. .. .. @ dirty   : list()
#>  @ layout     :List of 8
#>  .. $ type   : chr "grid"
#>  .. $ ncol   : num 1
#>  .. $ nrow   : NULL
#>  .. $ byrow  : logi TRUE
#>  .. $ widths : NULL
#>  .. $ heights: NULL
#>  .. $ guides : NULL
#>  .. $ axes   : chr "keep"
#>  @ annotations:List of 4
#>  .. $ title     : NULL
#>  .. $ subtitle  : NULL
#>  .. $ caption   : NULL
#>  .. $ tag_levels: NULL
```
