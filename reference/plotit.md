# Initialize a plotit object

Initialize a plotit object

## Usage

``` r
plotit(
  data,
  mapping = encode(),
  autofit = FALSE,
  width = 89,
  height = 56,
  size_unit = "mm",
  dodge = NULL,
  default_color = "#0072B2"
)
```

## Arguments

- data:

  A data frame, a matrix (coerced with
  [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html)), or a
  `plotit_graph` (relational pipeline; see
  [`as_graph()`](https://zorrooz.github.io/plotit/reference/as_graph.md)).

- mapping:

  An object created by
  [`encode()`](https://zorrooz.github.io/plotit/reference/encode.md).

- autofit:

  Logical; if `TRUE`, panel size is not baked (follows the device). If
  `FALSE` (default) the panel is baked WYSIWYG at `width`/`height`.

- width, height:

  Numeric; panel size in `size_unit`. Default is a Nature single-column
  canvas (89 x 56 mm). Ignored when `autofit = TRUE`.

- size_unit:

  Unit for width/height: `"in"`, `"cm"`, `"mm"`.

- dodge:

  Numeric; global default dodge width. If `NULL`, heuristically set to
  `0.8` when a discrete axis is present, else `0`.

- default_color:

  Single color string. Applied as default color mapping if no color/fill
  aesthetic is present in `mapping`. Adding any
  [`scale_color()`](https://zorrooz.github.io/plotit/reference/scale_color.md)
  or
  [`scale_fill()`](https://zorrooz.github.io/plotit/reference/scale_fill.md)
  later will automatically disable this single-color mapping. Default is
  the first friendly palette anchor (`#0072B2`).

## Value

A `plotit` object.

## Examples

``` r
plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))

plotit(mtcars, encode(x = wt, y = mpg, colour = cyl))
```
