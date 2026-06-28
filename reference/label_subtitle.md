# Generic for setting plot subtitle

Generic for setting plot subtitle

## Usage

``` r
label_subtitle(plot, text = NULL, hide = FALSE, reset = FALSE, ...)
```

## Arguments

- plot:

  A plotit object

- text:

  Subtitle text. NULL = don't modify. "str" = custom subtitle.

- hide:

  If TRUE, remove subtitle element from layout entirely.

- reset:

  If TRUE, remove the subtitle text (restore to no subtitle).

- ...:

  Currently unused

## Value

Modified plotit object

## Examples

``` r
plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> label_subtitle("Subtitle")
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
#>  .. .. @ subtitle: chr "Subtitle"
#>  .. .. @ caption : NULL
#>  .. .. @ x       : NULL
#>  .. .. @ y       : NULL
#>  .. .. @ legend  : NULL
#>  .. .. @ dirty   :List of 1
#>  .. .. .. $ subtitle: logi TRUE
```
