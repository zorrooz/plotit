# Apply the default plotit theme (convenience wrapper for style())

Apply the default plotit theme (convenience wrapper for style())

## Usage

``` r
style_default(plot, base_size = NULL, base_family = NULL)
```

## Arguments

- plot:

  A plotit object.

- base_size:

  Base font size in pts (default 11).

- base_family:

  Base font family (default `""` = system sans-serif).

## Value

Modified plotit object.

## Examples

``` r
plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
  mark_point() |>
  style_default()
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
