# Fill scale

Maps data values to fill colours. Same semantics as
[`scale_color()`](https://zorrooz.github.io/plotit/reference/scale_color.md)
but for the `fill` aesthetic (bars, boxes, polygons, etc.).

## Usage

``` r
scale_fill(
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
  [`ggplot2::waiver()`](https://ggplot2.tidyverse.org/reference/waiver.html)
  = use variable name.

- trans:

  Scale transformation. `NULL` auto-detects, otherwise one of:
  `"identity"`, `"discrete"`, `"reverse"`, `"binned"`. Unsupported
  values (e.g. `"log"`) produce a targeted error message.

- limits:

  Data domain.

- range:

  Output range. Same as
  [`scale_color()`](https://zorrooz.github.io/plotit/reference/scale_color.md):
  colour vector, or `"viridis"`, `"brewer"`, `"grey"`, `"friendly"`,
  `"hue"`.

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
plotit(iris, encode(x = Species, fill = Species)) |>
  mark_bar() |>
  scale_fill(range = "viridis")
#> Scale for fill is already present.
#> Adding another scale for fill, which will replace the existing scale.
```
