# Add a ggplot2 component to a plot

Escape hatch for advanced ggplot2 usage:
`add_ggplot(p, ggplot2::annotate(...))`,
`add_ggplot(p, ggplot2::guides(...))`,
`add_ggplot(p, ggplot2::labs(...))` etc. modify the underlying ggplot
and return the `plotit` object so the pipeline continues. Prefer the
verb API (`mark_*`, `scale_*`, `label_*`, `style`) for reproducible,
well-validated plots.

## Usage

``` r
add_ggplot(plot, component)
```

## Arguments

- plot:

  A `plotit` object (or a `plotit_composite`).

- component:

  Any object ggplot2's `+` accepts (layer, scale, coord, facet, theme,
  labs, or a ggplot2 object).

## Value

A modified `plotit` (or `plotit_composite`) object.

## Stability

Extension surface (contract tier: extensible). The signature is stable
as documented; it is the supported replacement for the former S3 `+`
operator on `plotit` objects, which is intentionally not defined so that
ggplot2 components are only added through this single explicit entry
point.

ggplot2 4.0's
[`ggplot2::stat_manual()`](https://ggplot2.tidyverse.org/reference/stat_manual.html)
slots in here as a custom data-transformation layer without a dedicated
plotit verb:
`add_ggplot(p, ggplot2::stat_manual(fun = function(d) ...))`.

## Examples

``` r
p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
  mark_point() |>
  add_ggplot(ggplot2::annotate("text", x = 2.5, y = 7.9, label = "high", size = 3))
```
