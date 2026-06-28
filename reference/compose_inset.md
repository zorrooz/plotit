# Overlay an inset plot on a base plot

Places a smaller plot (`inset`) as a floating panel on top of a base
`plotit` via
[`patchwork::inset_element()`](https://patchwork.data-imaginist.com/reference/inset_element.html).
Position is specified in normalised parent coordinates (0-1 relative to
the panel or plot area). The returned composite accepts
[`label_title()`](https://zorrooz.github.io/plotit/reference/label_title.md)
/ [`style()`](https://zorrooz.github.io/plotit/reference/style.md) /
[`export()`](https://zorrooz.github.io/plotit/reference/export.md) in
the usual way.

## Usage

``` r
compose_inset(
  base,
  inset,
  left = 0,
  bottom = 0,
  right = 1,
  top = 1,
  align_to = "panel",
  on_top = TRUE,
  ...
)
```

## Arguments

- base:

  A `plotit` object serving as the background.

- inset:

  A `plotit` or `plotit_composite` object to overlay.

- left, right, bottom, top:

  Inset edges in npc (0-1).

- align_to:

  Coordinate reference: `"panel"` (default) or `"plot"`.

- on_top:

  Logical; `TRUE` (default) = inset rendered above base.

- ...:

  Passed through to
  [`patchwork::inset_element()`](https://patchwork.data-imaginist.com/reference/inset_element.html).

## Value

A `plotit_composite` object.

## Examples

``` r
p1 <- plotit(mtcars, encode(x = wt, y = mpg)) |> mark_point()
p2 <- plotit(mtcars, encode(x = factor(cyl))) |> mark_bar()
compose_inset(p1, p2, left = 0.6, bottom = 0.6, right = 0.95, top = 0.95)
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
#>  @ layout     :List of 7
#>  .. $ type    : chr "inset"
#>  .. $ left    : num 0.6
#>  .. $ bottom  : num 0.6
#>  .. $ right   : num 0.95
#>  .. $ top     : num 0.95
#>  .. $ align_to: chr "panel"
#>  .. $ on_top  : logi TRUE
#>  @ annotations:List of 4
#>  .. $ title     : NULL
#>  .. $ subtitle  : NULL
#>  .. $ caption   : NULL
#>  .. $ tag_levels: NULL
```
