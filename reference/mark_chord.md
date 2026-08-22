# Chord diagram layer (sugar)

Creates a chord diagram showing pairwise relationships between groups.
Equivalent to the pipeline
`as_graph() |> layout_chord() |> mark_polygon(data = ~ribbons) |> mark_polygon(data = ~arcs)`
– see §3.3.4a. Accepts an **edges table** with `source`, `target`, and
optionally `value` columns; sector arcs and bezier bands come from the
built-in circular layout (deterministic, dependency-free).

## Usage

``` r
mark_chord(
  plot,
  mapping = NULL,
  data = NULL,
  gap_width = 4,
  link_alpha = 0.5,
  ...
)
```

## Arguments

- plot:

  A plotit object

- mapping:

  Structural aesthetics: `source` (required), `target` (required),
  `value` (optional). Visual: `fill` colours sectors and bands alike;
  bands default to source identity, compatible with `scale_fill_*`.

- data:

  Optional edges data.frame for this layer. Legacy formats (`from`/`to`,
  `Var1`/`Var2`/`Freq`, adjacency matrix) are still auto-detected and
  coerced.

- gap_width:

  Gap between sectors in degrees (default 4); translated to the layout's
  angular padding.

- link_alpha:

  Alpha transparency for link bands (default 0.5).

- ...:

  Unused; fine-tuning (inner radius, curvature, sector order) lives on
  [`layout_chord()`](https://zorrooz.github.io/plotit/reference/layout_chord.md)
  in the explicit pipeline form.

## Value

Modified plotit object; `@graph` holds the laid-out tables.

## Details

The laid-out graph (`nodes` / `edges` / `arcs` / `ribbons` tables) is
stored on `@graph`, so subsequent marks can reference any table directly
for tuning beyond this sugar's two parameters.

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
                    value = value, fill = source)) |>
  mark_chord()
```
