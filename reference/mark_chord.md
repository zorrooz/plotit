# Chord diagram layer

Creates a chord diagram showing pairwise relationships between groups.
Requires the circlize package. Data should be an adjacency matrix or a
data frame with `from`, `to`, and `value` columns.

## Usage

``` r
mark_chord(
  plot,
  gap_width = 4,
  grid_colour = "grey80",
  link_colour = "grey30",
  link_alpha = 0.5,
  ...
)
```

## Arguments

- plot:

  A plotit object

- gap_width:

  Gap between sectors in degrees (default 4).

- grid_colour:

  Colour for the outer grid (default `"grey80"`).

- link_colour:

  Colour for the chord links (default `"grey30"`).

- link_alpha:

  Alpha transparency for links (default 0.5).

- ...:

  Other arguments passed to
  [`circlize::chordDiagram`](https://rdrr.io/pkg/circlize/man/chordDiagram.html)

## Value

Modified plotit object

## References

AntV G2: [Chord](https://g2.antv.antgroup.com/en/api/mark/chord)
(graphlib)

## Examples

``` r
if (FALSE) { # \dontrun{
if (requireNamespace("circlize", quietly = TRUE)) {
  mat <- matrix(c(0, 5, 3, 2, 0, 4, 1, 3, 0), nrow = 3)
  rownames(mat) <- colnames(mat) <- c("A", "B", "C")
  plotit(as.data.frame(as.table(mat)), encode()) |>
    mark_chord()
}
} # }
```
