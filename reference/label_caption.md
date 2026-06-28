# Generic for setting plot caption

Generic for setting plot caption

## Usage

``` r
label_caption(plot, text = NULL, hide = FALSE, reset = FALSE, ...)
```

## Arguments

- plot:

  A plotit object

- text:

  Caption text. NULL = don't modify. "str" = custom caption.

- hide:

  If TRUE, remove caption element from layout entirely.

- reset:

  If TRUE, remove the caption text (restore to no caption).

- ...:

  Currently unused

## Value

Modified plotit object

## Examples

``` r
plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> label_caption("Caption")
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
#>  .. .. @ caption : chr "Caption"
#>  .. .. @ x       : NULL
#>  .. .. @ y       : NULL
#>  .. .. @ legend  : NULL
#>  .. .. @ dirty   :List of 1
#>  .. .. .. $ caption: logi TRUE
```
