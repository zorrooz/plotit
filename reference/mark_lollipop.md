# Lollipop chart layer

Creates a lollipop chart: a point anchored by a stem to a reference
line. This is a **syntax-sugar composite mark** combining `geom_segment`
and `geom_point`.

## Usage

``` r
mark_lollipop(
  plot,
  mapping = NULL,
  data = NULL,
  stem_colour = "grey50",
  stem_width = 0.5,
  point_size = 3,
  ref = 0,
  ...
)
```

## Arguments

- plot:

  A plotit object

- mapping:

  Optional new aesthetics

- data:

  Optional data for this layer

- stem_colour:

  Colour for the stem lines (default `"grey50"`).

- stem_width:

  Line width for stems (default 0.5).

- point_size:

  Point size for the lollipop head (default 3).

- ref:

  Baseline value for the stems (default 0).

- ...:

  Other arguments passed to
  [`mark_point()`](https://zorrooz.github.io/plotit/reference/mark_point.md)

## Value

Modified plotit object

## Details

Equivalent expansion:


      p |> mark_rule(x = x, xend = x, y = ref, yend = y) |>
           mark_point(x = x, y = y)

## Examples

``` r
df <- data.frame(cat = LETTERS[1:5], val = c(3, 7, 2, 9, 5))
plotit(df, encode(x = cat, y = val)) |>
  mark_lollipop(point_size = 4, stem_colour = "grey70")
```
