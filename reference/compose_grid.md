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
  guides = NULL,
  axes = "keep",
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

  `"collect"` to merge legends, `"keep"` to separate, `NULL` (default)
  for patchwork auto-detect.

- axes:

  `"collect"` to share all axes, `"collect_x"` or `"collect_y"` for a
  single direction, `"keep"` (default) to keep axes independent.

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
