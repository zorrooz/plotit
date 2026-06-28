# Polar / radial coordinate system

Maps one axis to angle and the other to radius. Default (full circle,
zero inner radius) uses `coord_polar()`. Set `inner_radius > 0` or
`r_axis_inside = TRUE` to switch to the radial variant (requires ggplot2
\>= 3.5.0).

## Usage

``` r
project_polar(
  plot,
  theta = "x",
  start = 0,
  direction = 1,
  inner_radius = 0,
  r_axis_inside = FALSE,
  clip = "on",
  ...
)
```

## Arguments

- plot:

  A plotit object.

- theta:

  Variable mapped to angle: `"x"` or `"y"`.

- start:

  Starting angle in radians (0 = 12 o'clock).

- direction:

  `1` = clockwise, `-1` = anti-clockwise.

- inner_radius:

  Inner radius as a fraction of the panel (0-1). `0` = polar (full
  circle). `>0` = radial (hollow centre, needs ggplot2 \>= 3.5.0).

- r_axis_inside:

  If `TRUE`, place the radial axis inside the panel (radial mode only).

- clip:

  Should drawing be clipped? `"on"` or `"off"`.

- ...:

  Passed to the underlying `coord_polar()` or `coord_radial()`.

## Value

Modified plotit object.

## Examples

``` r
plotit(mtcars, encode(x = factor(cyl))) |>
  mark_bar() |> project_polar()
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
