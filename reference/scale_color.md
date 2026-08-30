# Color scale

Maps data values to colours. Auto-detects discrete vs continuous
variables; supports manual colour vectors and named colour schemes.

## Usage

``` r
scale_color(
  plot,
  name = ggplot2::waiver(),
  trans = NULL,
  limits = NULL,
  range = NULL,
  breaks = NULL,
  labels = NULL,
  na_color = NULL,
  n_bins = NULL,
  mid = NULL,
  ...
)
```

## Arguments

- plot:

  A plotit object.

- name:

  Scale title (legend name).
  [`ggplot2::waiver()`](https://ggplot2.tidyverse.org/reference/waiver.html)
  = use variable name.

- trans:

  Scale transformation. `NULL` auto-detects, otherwise one of:
  `"identity"`, `"discrete"`, `"reverse"`, `"binned"`. Unsupported
  values (e.g. `"log"`) produce a targeted error message.

- limits:

  Data domain. `c(min, max)` for continuous; character vector for
  discrete limits.

- range:

  Output range. `NULL` = auto (discrete-\>friendly,
  continuous-\>viridis). A colour vector (`c("blue","red")`) for manual
  colours, or a scheme name: `"viridis"`, `"brewer"`, `"grey"`,
  `"friendly"`, `"hue"`. For binned: only `"viridis"`, `"brewer"`. For
  continuous: only `"viridis"`, `"brewer"`.

- breaks:

  Legend key positions.

- labels:

  Legend key labels.

- na_color:

  Colour used for `NA` values (passed to `na.value`). `NULL` = ggplot2
  default.

- n_bins:

  Bin a continuous scale into this many legend steps
  (`guide_coloursteps`; shorthand for `trans = "binned"`). `NULL` =
  continuous.

- mid:

  Centre of a diverging colour scale (e.g. `0` for correlation
  matrices). Requires a continuous scale and a diverging scheme in
  `range` (`"rdbu"` default); mutually exclusive with `n_bins`.

- ...:

  Passed to the underlying ggplot2 scale function.

## Value

A modified plotit object.

## Examples

``` r
plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
  mark_point() |>
  scale_color(range = "viridis")
#> Warning: `range` = "viridis" with a discrete "colour" variable uses the discrete
#> "viridis" variant.
#> ℹ For a continuous gradient, map a numeric column instead.
#> Scale for colour is already present.
#> Adding another scale for colour, which will replace the existing scale.
```
