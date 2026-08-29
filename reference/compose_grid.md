# Assemble multiple plots into a grid layout

`compose_grid()` arranges `plotit` or `plotit_composite` objects into a
grid via
[`patchwork::wrap_plots()`](https://patchwork.data-imaginist.com/reference/wrap_plots.html).
The default vertical stack (`ncol = 1` when neither `ncol` nor `nrow` is
given) is the most common layout for report figures. Pipe the result to
[`label_title()`](https://zorrooz.github.io/plotit/reference/label_title.md)
/ [`style()`](https://zorrooz.github.io/plotit/reference/style.md) /
[`export()`](https://zorrooz.github.io/plotit/reference/export.md) just
as with a single `plotit`.

## Usage

``` r
compose_grid(
  ...,
  ncol = NULL,
  nrow = NULL,
  byrow = TRUE,
  widths = NULL,
  heights = NULL,
  guides = "collect",
  axes = "keep",
  axis_titles = axes,
  design = NULL,
  tag_levels = NULL
)
```

## Arguments

- ...:

  `plotit` or `plotit_composite` objects to arrange.

- ncol:

  Number of columns. `NULL` (default) = auto; if both `ncol` and `nrow`
  are `NULL` defaults to 1 (vertical stack).

- nrow:

  Number of rows. `NULL` (default) = inferred from `ncol` and the number
  of plots.

- byrow:

  Fill direction: `TRUE` (default) = row-major.

- widths:

  Relative column widths, e.g. `c(1, 2)`.

- heights:

  Relative row heights.

- guides:

  `"collect"` (default) to merge identical legends into one, `"keep"` to
  keep per-panel legends, `NULL` for patchwork auto-detect.

- axes:

  `"collect"` to share all axes, `"collect_x"` or `"collect_y"` for a
  single direction, `"keep"` (default) to keep axes independent.

- axis_titles:

  Axis-title sharing: defaults to the `axes` value; `"collect"` merges
  repeated axis titles onto one panel, `"collect_x"`/`"collect_y"` per
  direction, `"keep"` independent.

- design:

  Layout specification replacing `ncol`/`nrow`/`byrow`: either a text
  layout (one row per line, digits = plot order, `#` = empty cell, e.g.
  the two-row layout "122" / "133") or a list of numeric area vectors
  `c(top, left, bottom, right)`. When given, it wins over
  `ncol`/`nrow`/`byrow` (a warning flags the overlap).

- tag_levels:

  Sub-figure tag scheme: `"A"` for uppercase letters, `"a"` for
  lowercase, `"1"` for numbers, `"i"` for roman numerals, or a custom
  character vector (e.g. `c("(a)", "(b)")`). `NULL` = no tags.

## Value

A `plotit_composite` object. Pipe it to
[`label_title()`](https://zorrooz.github.io/plotit/reference/label_title.md),
[`style()`](https://zorrooz.github.io/plotit/reference/style.md), or
[`export()`](https://zorrooz.github.io/plotit/reference/export.md).

## Examples

``` r
p1 <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
p2 <- plotit(iris, encode(x = Species, y = Sepal.Length)) |> mark_boxplot()
compose_grid(p1, p2)
```
