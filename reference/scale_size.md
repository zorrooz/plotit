# Size scale

Maps data values to point/line sizes.

## Usage

``` r
scale_size(
  plot,
  name = ggplot2::waiver(),
  trans = NULL,
  limits = NULL,
  range = NULL,
  breaks = NULL,
  labels = NULL,
  ...
)
```

## Arguments

- plot:

  A plotit object.

- name:

  Scale title (legend name).

- trans:

  Scale transformation. `NULL` auto-detects, otherwise one of:
  `"identity"`, `"discrete"`, `"reverse"`, `"binned"`. Unsupported
  values (e.g. `"log"`) produce a targeted error message.

- limits:

  Data domain.

- range:

  Output size range as `c(min, max)`. `NULL` = default `c(1, 6)`. Only
  meaningful for continuous scales (ignored for discrete/binned).

- breaks:

  Legend key positions.

- labels:

  Legend key labels.

- ...:

  Passed to the underlying ggplot2 scale function.

## Value

A modified plotit object.

## Examples

``` r
plotit(mtcars, encode(x = wt, y = mpg, size = hp)) |>
  mark_point() |>
  scale_size(range = c(1, 6))
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
