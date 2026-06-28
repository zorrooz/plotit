# Generic for setting legend title(s)

Generic for setting legend title(s)

## Usage

``` r
label_legend(plot, text = NULL, aes = NULL, hide = FALSE, reset = FALSE, ...)
```

## Arguments

- plot:

  A plotit object

- text:

  Legend title text. NULL = don't modify. "str" = custom title.

- aes:

  Aesthetic to apply to (e.g. "colour", "fill"). NULL = all mapped
  aesthetics.

- hide:

  If TRUE, hide the legend title.

- reset:

  If TRUE, restore the legend title to the variable name.

- ...:

  Currently unused

## Value

Modified plotit object

## Examples

``` r
plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
  mark_point() |>
  scale_color() |>
  label_legend(text = "Species", aes = "colour")
#> Warning: Aesthetic "colour" is not present in the plot mapping.
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
#>  .. @ default_color: NULL
#>  .. @ labels       : <plotit::plotit_labels>
#>  .. .. @ title   : NULL
#>  .. .. @ subtitle: NULL
#>  .. .. @ caption : NULL
#>  .. .. @ x       : NULL
#>  .. .. @ y       : NULL
#>  .. .. @ legend  : NULL
#>  .. .. @ dirty   : list()
```
