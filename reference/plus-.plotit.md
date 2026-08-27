# Add a ggplot2 component to a plotit object

Escape hatch for advanced ggplot2 usage: `p + ggplot2::annotate(...)`,
`p + ggplot2::guides(...)`, `p + ggplot2::labs(...)` etc. modify the
underlying ggplot and return the `plotit` object so the pipeline
continues. Prefer the verb API (`mark_*`, `scale_*`, `label_*`, `style`)
for reproducible, well-validated plots.

## Usage

``` r
# S3 method for class 'plotit'
e1 + e2
```

## Arguments

- e1:

  A `plotit` object.

- e2:

  Any object ggplot2's `+` accepts (layer, scale, coord, facet, theme,
  labs, or a ggplot2 object).

## Value

A modified `plotit` object.

## Examples

``` r
plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
  mark_point() +
  ggplot2::annotate("text", x = 2.5, y = 7.9, label = "high", size = 3)
```
