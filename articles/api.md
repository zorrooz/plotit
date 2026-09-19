# API

This page is the **system map** of plotit: how the verb families fit
together, what they share, and which contract tier each surface sits in.
Rendered recipes live in the
[Gallery](https://zorrooz.github.io/plotit/articles/visualizing-data.md);
per-function arguments live in
[Reference](https://zorrooz.github.io/plotit/reference/index.md).

## Pipeline skeleton

``` r
data |> plotit(encode(...)) |>
  mark_*(...) |>
  layout_*(...) |>               # relational graphs only
  split_*(...) |>
  project_*(...) |>
  scale_*(...) |>
  label_*(...) |>
  style(...) |>
  export(...)
```

Every verb returns a `plotit` (or `plotit_composite`) object, so the
native pipe `|>` is the only composition operator. Single-plot verbs do
not accept `plotit_composite`; build panels first, then `compose_*()`.

| Family | Job | ggplot2 analogue |
|:---|:---|:---|
| [`plotit()`](https://zorrooz.github.io/plotit/reference/plotit.md) / [`encode()`](https://zorrooz.github.io/plotit/reference/encode.md) | init + aesthetics | `ggplot()` / `aes()` |
| `mark_*` | geometric layers | `geom_*` |
| `layout_*` | relational data transforms | — |
| `scale_*` | data → visual mapping | `scale_*` |
| `project_*` | coordinate systems | `coord_*` |
| `split_*` | facets | `facet_*` |
| `label_*` | text | `labs()` + `theme()` |
| [`style()`](https://zorrooz.github.io/plotit/reference/style.md) | theme | `theme()` |
| [`export()`](https://zorrooz.github.io/plotit/reference/export.md) | file output | `ggsave()` |
| `compose_*` | multi-panel assembly | patchwork |
| [`add_ggplot()`](https://zorrooz.github.io/plotit/reference/add_ggplot.md) | escape hatch | arbitrary ggplot2 layer |
| [`make_mark()`](https://zorrooz.github.io/plotit/reference/make_mark.md) / [`make_theme()`](https://zorrooz.github.io/plotit/reference/make_theme.md) | user extension | — |

## Init and encoding

``` r

plotit(data, mapping = encode(), autofit = FALSE,
       width = 89, height = 56, size_unit = "mm",
       dodge = NULL, default_color = "#0072B2")

encode(...)                 # forwarded to aes(); returns plotit_encode
add_ggplot(plot, gg_obj)    # append any ggplot2 layer, keep the pipe
```

`width`/`height` are **panel** sizes (WYSIWYG baked into the plot).
Without a colour/fill mapping, `default_color` injects a single hue on
both channels; any colour/fill scale clears it automatically.

## Marks

Shared signature for standard marks:

``` r
mark_<type>(plot, mapping = NULL, data = NULL, position = NULL,
            ..., rasterize = FALSE, rasterize_dpi = 300, rasterize_dev = "cairo")
```

| Parameter   | Default | Meaning                                               |
|:------------|:--------|:------------------------------------------------------|
| `mapping`   | `NULL`  | layer-level `encode(...)`; inherits global map        |
| `data`      | `NULL`  | layer data; relational graphs accept `~table`         |
| `position`  | `NULL`  | defaults from global dodge                            |
| `...`       | —       | forwarded to the underlying `geom_*`                  |
| `rasterize` | `FALSE` | `ggrastr` rasterisation (not on composite/relational) |

Three tiers:

| Tier | Contents | Notes |
|:---|:---|:---|
| Basic geometry | point, line, area, bar, rect, polygon, text, label, rule, path, histogram, density, boxplot, violin, step, rug, spoke, curve, image, map | thin wrappers over ggplot2 geoms |
| Statistical | smooth, hex, bin2d, density_2d, contour, count, corr, ecdf, qq, qq_line, heatmap | non-trivial stats baked in |
| Composite sugar | errorbar, ribbon, significance, lollipop, dumbbell, forest | documented as sugar over basic marks |
| Relational | beeswarm, encircle, sankey, treemap, network, chord | layouts are package engines; sugar marks call the same `layout_*` |

Named parameters worth knowing: `mark_step(direction=)`,
`mark_rug(sides=)`, `mark_curve(curvature=)`, `mark_text(repel=)`,
`mark_errorbar(stat=, level=)`, `mark_heatmap(cluster=, scale=)`,
`mark_network(edge_shape=)`. Full lists live in Reference.

## Scales

``` r
scale_<aes>(plot, name = waiver(), trans = <default>, limits = NULL,
            range = NULL, breaks = NULL, labels = NULL, ...)
```

| Family | Default `trans` | `range` semantics |
|:---|:---|:---|
| `scale_x` / `scale_y` | identity | panel span (Vega `range:[0,w]`) |
| `scale_color` / `scale_fill` | auto | discrete → friendly, continuous → viridis |
| `scale_size` / `scale_alpha` | auto | numeric output domain |
| `scale_shape` / `scale_linetype` | discrete | shape codes / linetype names |

Legal `trans` values are filtered per aesthetic: `identity` / `log` /
`log10` / `log2` / `sqrt` / `reverse` / `discrete` / `binned`.
Colour/fill also accept `na_color`, `n_bins`, and a diverging `mid`
anchor. Date/POSIXct columns auto-route to a date axis — do not force
`trans = "identity"` on them.

## Graph data and layouts

``` r

as_graph(data, source, target, value, nodes)

layout_force(plot, iterations, seed, weights)   # seed required
layout_circle(plot, order_by)
layout_tree(plot, direction, leaf_spacing, edge)
layout_dendrogram(plot, direction)
layout_chord(plot, inner_radius, pad_angle, curvature, order_by)
layout_sankey(plot, node_width, padding, curvature, ...)
layout_treemap(plot)
```

A layout is a **data transform**, not a layer: it bakes coordinates into
`@graph` sub-tables (`nodes`, `edges`, `ribbons`, …). Marks render those
tables with `data = ~nodes` / `~edges` / `~ribbons`. Sugar marks
(`mark_sankey`, `mark_treemap`, `mark_network`, `mark_chord`) call the
same engines — drop to `layout_*` when you need custom marks on
sub-tables.

## Project, split, label

``` r

project_cartesian(xlim, ylim, expand, flip, fixed, coord_trans, clip)
project_polar(theta, start, end, reverse, inner_radius, r_axis_inside, clip)
project_parallel(columns, group, scale = c("std", "global", "none"), ...)
project_map(projection, xlim, ylim, clip)

split_wrap(plot, ..., nrow, ncol, scales, dir)
split_grid(plot, ..., rows, cols, scales, space, axes)

label_title(text, hide, reset)
label_subtitle(text, hide, reset)
label_caption(text, hide, reset)
label_axis(text, aes = "x"|"y", hide, reset)
label_legend(text, aes, hide, reset)    # aes = NULL → global default
```

`label_*` uses one priority protocol: `reset` \> `hide` \> `text`. Call
order does not matter.

## Theme, export, composition, extension

``` r

style(plot, ..., base_size, base_family, base_theme)
export(plot, filename, width, height, dpi = 300, device)

compose_grid(..., ncol, nrow, byrow, widths, heights,
             guides = "collect", axes, design, tag_levels)
compose_marginal(main, top, right, ...)
compose_inset(base, inset, left, bottom, right, top, ...)
compose_annot(base, top, bottom, left, right, ...)

make_mark(name, geom_fun)
make_theme(name, ..., base_theme = ggplot2::theme_minimal)
```

Composers return `plotit_composite`, which continues into `label_title`
/ `label_subtitle` / `label_caption`, `style`, and `export`. Per-panel
geometry verbs still run on the child plots before composition.

## Contract tiers and conventions

| Tier | Stable through | Examples |
|:---|:---|:---|
| Core | 1.0 major | function names, `plotit`/`plotit_composite` return types, `plotit(data, mapping)` |
| Extended | adjustable in 2.0 | `trans` legal set, `label_*` protocol, `project_*`/`split_*`/`layout_*` signatures |
| Iterative | any release | default theme, palettes, canvas tokens, internals |

Naming and error UX:

- Verb prefixes only: one verb, one meaning.
- `color`/`colour` accepted; function names use American spelling.
- Package-level validation uses
  [`cli::cli_abort`](https://cli.r-lib.org/reference/cli_abort.html)
  with legal values in the remedy. Silent argument swallowing is a
  defect, not a feature.

## Next

- [Get Started](https://zorrooz.github.io/plotit/articles/plotit.md) —
  first pipelines
- [Gallery](https://zorrooz.github.io/plotit/articles/visualizing-data.md)
  — chart families by intent
- [Design
  Goals](https://zorrooz.github.io/plotit/articles/design-goals.md) —
  why the grammar looks this way
