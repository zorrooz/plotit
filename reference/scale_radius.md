# Radius scale (defunct)

`scale_radius()` is **defunct** as of plotit 1.0. Radius/size encoding
is the
[`scale_size()`](https://zorrooz.github.io/plotit/reference/scale_size.md)
domain.

## Usage

``` r
scale_radius(...)
```

## Arguments

- ...:

  Ignored. Present only for drop-in detection.

## Value

Never returns; aborts with migration guidance.

## Details

For bubble charts whose area should encode magnitude:

- `scale_size(range = c(1, 6))` maps linearly to ggplot2's area-like
  size unit (the size domain default), or

- `ggplot2::scale_radius(...)` maps to the circle radius directly
  (area-proportional emphasis, Vega-Lite's `scaleRadius` semantics).

## References

Vega-Lite: [Radius](https://vega.github.io/vega-lite/docs/radius.html)
