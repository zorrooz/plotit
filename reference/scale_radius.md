# Radius scale (area-proportional bubble size)

Maps the data value to the circle **radius**, so perceived bubble area
grows quadratically with the value – the correct encoding for magnitude
comparisons (Vega-Lite's `scaleRadius`). Where
[`scale_size()`](https://zorrooz.github.io/plotit/reference/scale_size.md)
maps to ggplot2's area-like size unit linearly, `scale_radius()`
emphasizes relative magnitudes.

## Usage

``` r
scale_radius(
  plot,
  name = ggplot2::waiver(),
  trans = "identity",
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

  Scale transformation. Default `"identity"`. Allowed: `"identity"`,
  `"log"`, `"log10"`, `"log2"`, `"sqrt"`, `"reverse"`. Discrete/binned
  routes are rejected with guidance toward
  [`scale_size()`](https://zorrooz.github.io/plotit/reference/scale_size.md).

- limits:

  Data domain.

- range:

  Output radius range as `c(min, max)`. `NULL` = default `c(1, 6)`.

- breaks:

  Legend key positions.

- labels:

  Legend key labels.

- ...:

  Passed to the underlying ggplot2 scale function.

## Value

A modified plotit object.

## References

Vega-Lite: [Radius](https://vega.github.io/vega-lite/docs/radius.html)

## Examples

``` r
plotit(
  ggplot2::midwest,
  encode(x = popdensity, y = percollege, size = poptotal)
) |>
  mark_point(alpha = 0.5) |>
  scale_radius(range = c(1, 10))
```
