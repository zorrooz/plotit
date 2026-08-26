# Significance annotation layer

Adds statistical significance brackets and labels between groups. This
is a **syntax-sugar composite mark** that combines `mark_rule` and
`mark_text` internally.

## Usage

``` r
mark_significance(
  plot,
  comparisons,
  y_position = NULL,
  y_offset = NULL,
  line_color = ._MARK_STYLE$ink,
  line_width = ._MARK_STYLE$lw_thin,
  text_size = ._MARK_STYLE$txt_note,
  tip_length = 0.02,
  ...
)
```

## Arguments

- plot:

  A plotit object

- comparisons:

  A data frame with columns: `group1`, `group2`, `label`, and optionally
  `y_position`. Character columns are matched against the x-axis
  variable.

- y_position:

  Numeric vector of y-positions for the brackets. If omitted,
  auto-computed from data range.

- y_offset:

  Text offset above the bracket line (default 0.5). In data units.

- line_color:

  Colour for the bracket lines (default `._MARK_STYLE$ink` =
  `"grey30"`).

- line_width:

  Width of bracket lines (default 0.5).

- text_size:

  Size of significance label text (default 3.2).

- tip_length:

  Length of bracket end-tick lines (default 0.02 as fraction of x-axis
  range).

- ...:

  Additional arguments passed to
  [`mark_text()`](https://zorrooz.github.io/plotit/reference/mark_text.md)

## Value

Modified plotit object

## Details

Equivalent expansion:


      p |> mark_rule(x = comp$group1, xend = comp$group2,
                     y = comp$y_position, yend = comp$y_position) |>
           mark_text(x = midpoint, y = comp$y_position + y_offset,
                     label = comp$label)

## Examples

``` r
df <- data.frame(group = c("A", "B", "C"), value = c(5, 8, 4))
comp <- data.frame(
  group1 = c("A", "A"), group2 = c("B", "C"),
  label = c("**", "ns")
)
plotit(df, encode(x = group, y = value)) |>
  mark_bar() |>
  mark_significance(comp, y_position = c(9, 6))
```
