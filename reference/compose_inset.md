# Overlay an inset plot on a base plot

Places a smaller plot (`inset`) as a floating panel on top of a base
`plotit` via
[`patchwork::inset_element()`](https://patchwork.data-imaginist.com/reference/inset_element.html).
Position is specified in normalised parent coordinates (0-1 relative to
the panel or plot area). The returned composite accepts
[`label_title()`](https://zorrooz.github.io/plotit/reference/label_title.md)
/ [`style()`](https://zorrooz.github.io/plotit/reference/style.md) /
[`export()`](https://zorrooz.github.io/plotit/reference/export.md) in
the usual way.

## Usage

``` r
compose_inset(
  base,
  inset,
  left = 0,
  bottom = 0,
  right = 1,
  top = 1,
  align_to = "panel",
  on_top = TRUE,
  ...
)
```

## Arguments

- base:

  A `plotit` object serving as the background.

- inset:

  A `plotit` or `plotit_composite` object to overlay.

- left, right, bottom, top:

  Inset edges in npc (0-1).

- align_to:

  Coordinate reference: `"panel"` (default) or `"plot"`.

- on_top:

  Logical; `TRUE` (default) = inset rendered above base.

- ...:

  Passed through to
  [`patchwork::inset_element()`](https://patchwork.data-imaginist.com/reference/inset_element.html).

## Value

A `plotit_composite` object.

## Examples

``` r
p1 <- plotit(mtcars, encode(x = wt, y = mpg)) |> mark_point()
p2 <- plotit(mtcars, encode(x = factor(cyl))) |> mark_bar()
compose_inset(p1, p2, left = 0.6, bottom = 0.6, right = 0.95, top = 0.95)
```
