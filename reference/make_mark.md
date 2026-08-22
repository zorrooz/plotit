# Create a custom mark

Registers a new S7 generic + method from any ggplot2 geom function,
making it available in the plotit pipeline. The new mark behaves
identically to built-in marks: it supports `mapping`, `data`,
`position`, auto-dodge, and rasterization.

## Usage

``` r
make_mark(name, geom_fun)
```

## Arguments

- name:

  Mark name as a string (e.g. `"mark_spoke"`). Should start with
  `"mark_"`.

- geom_fun:

  A ggplot2 geom function (e.g.
  [`ggplot2::geom_spoke`](https://ggplot2.tidyverse.org/reference/geom_spoke.html)).

## Value

Invisibly returns the registered S7 generic.

## Examples

``` r
make_mark("mark_spoke", ggplot2::geom_spoke)
df <- data.frame(
  x = 1:5, y = 1:5,
  angle = seq(0, 2 * pi, length.out = 5),
  radius = rep(0.3, 5)
)
# Now usable in the pipeline:
df |>
  plotit(encode(x = x, y = y, angle = angle, radius = radius)) |>
  mark_spoke()
```
