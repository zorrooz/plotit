# Chord diagram layer

Creates a chord diagram showing pairwise relationships between groups.
Requires the circlize package.

## Usage

``` r
mark_chord(
  plot,
  mapping = NULL,
  data = NULL,
  gap_width = 4,
  link_alpha = 0.5,
  rasterize = FALSE,
  rasterize_dpi = 300,
  rasterize_dev = "cairo",
  ...
)
```

## Arguments

- plot:

  A plotit object

- mapping:

  Aesthetics. Structural aesthetics: `source` (required), `target`
  (required), `value` (optional). Visual aesthetics: `fill` (sector
  colour, default maps to source identity, compatible with
  `scale_fill_*`).

- data:

  Optional data for this layer

- gap_width:

  Gap between sectors in degrees (default 4).

- link_alpha:

  Alpha transparency for links (default 0.5).

- rasterize:

  If `TRUE`, rasterize via
  [`ggrastr::rasterise()`](https://rdrr.io/pkg/ggrastr/man/rasterise.html).

- rasterize_dpi:

  DPI for rasterization (default 300).

- rasterize_dev:

  Graphics device for rasterization (default `"cairo"`).

- ...:

  Other arguments passed to
  [`circlize::chordDiagram`](https://rdrr.io/pkg/circlize/man/chordDiagram.html)

## Value

Modified plotit object

**Renderer note**: `mark_chord` renders natively with `circlize` on the
current graphics device (not through the ggplot2 build system) and
replaces the plot's `gg` with an empty ggplot. Layers added before or
after it therefore do not share a coordinate system – treat it as a
standalone renderer.

## Details

Accepts an **edges table** (data.frame) with `source`, `target`, and
optionally `value` columns. The mark internally builds the adjacency
matrix.

## References

AntV G2: [Chord](https://g2.antv.antgroup.com/en/api/mark/chord)
(graphlib)

## Examples

``` r
df <- data.frame(
  source = c("A", "A", "B", "B", "C"),
  target = c("B", "C", "C", "D", "D"),
  value  = c(5, 3, 4, 2, 6)
)
df |> plotit(encode(source = source, target = target,
                    value = value)) |>
  mark_chord()
```
