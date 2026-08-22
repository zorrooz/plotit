# Sankey flow diagram layer

Creates a Sankey diagram showing directed flows between nodes. Requires
the ggsankey package.

## Usage

``` r
mark_sankey(
  plot,
  mapping = NULL,
  data = NULL,
  position = NULL,
  ...,
  node_colour = "grey30",
  flow_alpha = 0.5
)
```

## Arguments

- plot:

  A plotit object

- mapping:

  Aesthetics. Structural aesthetics: `source` (required), `target`
  (required), `value` (optional). Visual aesthetics: `fill` (node
  colour, default maps to node identity, compatible with
  `scale_fill_*`).

- data:

  Optional data for this layer

- position:

  Position adjustment.

- ...:

  Other arguments passed to the underlying sankey layers (`width`,
  `smooth`, `type`, `flow.*`, `node.*`)

- node_colour:

  Default colour for node rectangles (used when no `fill` mapping is
  present, default `"grey30"`).

- flow_alpha:

  Alpha transparency for flow ribbons (default 0.5).

## Value

Modified plotit object

## Details

Accepts an **edges table** (data.frame) with `source`, `target`, and
optionally `value` columns. The mark internally builds the node-link
structure — no need for
[`ggsankey::make_long()`](https://rdrr.io/pkg/ggsankey/man/make_long.html)
preprocessing.

## References

AntV G2: [Sankey](https://g2.antv.antgroup.com/en/api/mark/sankey)
(graphlib)

## Examples

``` r
df <- data.frame(
  source = c("A", "A", "B", "B", "C"),
  target = c("B", "C", "C", "D", "D"),
  value  = c(10, 5, 8, 3, 6)
)
df |> plotit(encode(source = source, target = target,
                    value = value, fill = source)) |>
  mark_sankey() |>
  scale_fill(range = "viridis")
```
