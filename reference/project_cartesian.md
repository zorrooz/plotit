# Cartesian coordinate system

The primary coordinate function. Supports zooming, flipping, fixed
aspect ratio, and coordinate transformations – all through parameters.

## Usage

``` r
project_cartesian(
  plot,
  xlim = NULL,
  ylim = NULL,
  expand = TRUE,
  flip = FALSE,
  fixed = NULL,
  coord_trans = NULL,
  clip = "on",
  ...
)
```

## Arguments

- plot:

  A plotit object.

- xlim, ylim:

  Axis limits (zoom). `NULL` = auto.

- expand:

  If `TRUE`, add default expansion padding; `FALSE` or `c(0, 0)` to
  remove.

- flip:

  If `TRUE`, swap the x and y axes.

- fixed:

  Aspect ratio (`y / x`). `NULL` = free; `1` = square.

- coord_trans:

  Transformer for coordinate system (e.g. `"log10"`, `"sqrt"`,
  [`scales::exp_trans()`](https://scales.r-lib.org/reference/transform_exp.html)).
  `NULL` = identity.

- clip:

  Should drawing be clipped to the panel? `"on"` or `"off"`.

- ...:

  Passed to the underlying `coord_*` function.

## Value

Modified plotit object.

## Examples

``` r
plotit(iris, encode(x = Species, y = Sepal.Length)) |>
  mark_boxplot() |> project_cartesian(flip = TRUE)
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
#>  .. @ dodge        : num 0.8
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
