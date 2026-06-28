# Generic for setting axis titles

Generic for setting axis titles

## Usage

``` r
label_axis(plot, text = NULL, aes = NULL, hide = FALSE, reset = FALSE, ...)
```

## Arguments

- plot:

  A plotit object

- text:

  Axis title text. NULL = don't modify. "str" = custom title.

- aes:

  Which axis to apply to: "x" or "y" (required).

- hide:

  If TRUE, hide the axis title entirely (�lement_blank()).

- reset:

  If TRUE, restore the axis title to the variable name.

- ...:

  Currently unused

## Value

Modified plotit object

## Examples

``` r
plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
  label_axis(text = "Width", aes = "x") |>
  label_axis(text = "Length", aes = "y")
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
#>  .. .. @ x       : chr "Width"
#>  .. .. @ y       : chr "Length"
#>  .. .. @ legend  : NULL
#>  .. .. @ dirty   :List of 2
#>  .. .. .. $ x: logi TRUE
#>  .. .. .. $ y: logi TRUE
```
