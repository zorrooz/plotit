# Initialize a plotit object

Initialize a plotit object

## Usage

``` r
plotit(
  data,
  mapping = encode(),
  autofit = FALSE,
  width = 7,
  height = 5,
  size_unit = "in",
  dodge = NULL,
  default_color = "#4E79A7"
)
```

## Arguments

- data:

  A data frame.

- mapping:

  An object created by
  [`encode()`](https://zorrooz.github.io/plotit/reference/encode.md).

- autofit:

  Logical; if `TRUE`, plot dimensions are determined automatically.

- width, height:

  Numeric; default width and height (ignored if `autofit = TRUE`).

- size_unit:

  Unit for width/height: `"in"`, `"cm"`, `"mm"`.

- dodge:

  Numeric; global default dodge width. If `NULL`, heuristically set.

- default_color:

  Single color string. Applied as default color mapping if no color/fill
  aesthetic is present in `mapping`. Adding any
  [`scale_color()`](https://zorrooz.github.io/plotit/reference/scale_color.md)
  or
  [`scale_fill()`](https://zorrooz.github.io/plotit/reference/scale_fill.md)
  later will automatically disable this single-color mapping.

## Value

A `plotit` object.

## Examples

``` r
plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
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
plotit(mtcars, encode(x = wt, y = mpg, colour = cyl))
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
