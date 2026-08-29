# Initialize a plotit object

Initialize a plotit object

## Usage

``` r
plotit(
  data,
  mapping = encode(),
  autofit = FALSE,
  width = 5,
  height = 3.5,
  size_unit = "in",
  dodge = NULL,
  default_color = "#4E79A7"
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

  Logical; if `TRUE`, plot dimensions are determined automatically.

- width, height:

  Numeric; default width and height (ignored if `autofit = TRUE`).
  Defaults give a compact academic canvas (5 x 3.5 in panel) whose total
  footprint – panel plus axes/legend – fits standard 7-inch devices
  without clipping, keeping WYSIWYG previews and exports aligned.

- size_unit:

  Unit for width/height: `"in"`, `"cm"`, `"mm"`.

- dodge:

  Numeric; global default dodge width. If `NULL`, heuristically set.

- default_color:

  Single color string. Applied as default color mapping if no color/fill
  aesthetic is present in `mapping`. Adding any
  [`scale_color()`](https://zorrooz.github.io/plotit/reference/scale_color.md)
  or
  [`scale_fill()`](https://zorrooz.github.io/plotit/reference/scale_fill.md)
  later will automatically disable this single-color mapping.

## Value

A `plotit` object.

## Examples

``` r
plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))

plotit(mtcars, encode(x = wt, y = mpg, colour = cyl))
```
