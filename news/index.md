# Changelog

## plotit (development version)

- Active development stage — frequent breaking changes expected.
- See [GitHub releases](https://github.com/zorrooz/plotit/releases) for
  version history.

### Relational charts: full self-implementation

#### Breaking

- `igraph` removed from Suggests entirely:
  - [`layout_force()`](https://zorrooz.github.io/plotit/reference/layout_force.md)
    now runs a self-contained Fruchterman-Reingold engine (pairwise
    repulsion, edge attraction with optional `weights`, linear cooling).
    Unknown passthrough arguments are ignored with a warning (previously
    forwarded to
    [`igraph::layout_with_fr`](https://r.igraph.org/reference/layout_with_fr.html)).
  - [`layout_tree()`](https://zorrooz.github.io/plotit/reference/layout_tree.md)
    now uses an in-house leaf-ordering walk shared with
    [`layout_dendrogram()`](https://zorrooz.github.io/plotit/reference/layout_dendrogram.md)
    (`._hierarchy_leaf_x`). Leaf x positions are sequential
    left-to-right; internal nodes sit at mean child position.
    Orientation semantics per `direction` are unchanged.
  - [`as_graph()`](https://zorrooz.github.io/plotit/reference/as_graph.md)
    tbl_graph input detects directedness via igraph when available and
    degrades to undirected otherwise.
- `treemapify` removed from Suggests;
  [`mark_treemap()`](https://zorrooz.github.io/plotit/reference/mark_treemap.md)
  rewritten as sugar over the self-contained
  [`layout_treemap()`](https://zorrooz.github.io/plotit/reference/layout_treemap.md)
  squarify engine. It now takes a hierarchy table (`id`/`parent`/leaf
  `value`) instead of treemapify’s `area`/`subgroup` aesthetics, renders
  through `mark_rect(data = ~leaves)` with white hairline separators,
  draws centred leaf labels, blanks the coordinate axes, and stores
  nodes/edges/leaves on `@graph`.

#### Default style consistency / beauty (relational family)

- [`mark_network()`](https://zorrooz.github.io/plotit/reference/mark_network.md):
  edges render **beneath** node points (previously lines crossed over
  markers), labels float above points instead of overlapping, the panel
  gains `coord_fixed()` so layouts are not stretched, and axis blanking
  moves to the shared helper.
- [`mark_chord()`](https://zorrooz.github.io/plotit/reference/mark_chord.md):
  sector ids are labelled outside the ring on the layout’s anchors, and
  the panel gets `coord_fixed(clip = "off")` so sectors stay circular
  without cropping.
- [`mark_sankey()`](https://zorrooz.github.io/plotit/reference/mark_sankey.md):
  node labels switch to contrast-aware colours (white over the default
  ink fill, near-black over mapped fills); axes blanked.
- New shared helper `._theme_blank_axes()` unifies the coordinate-free
  look across network/sankey/chord/treemap.

#### Types

- Relational type coverage audited against ECharts/G6-G2/D3/Plotly/
  Highcharts (see AGENTS.md §3.2c). Core relational domain fully
  covered; sunburst/icicle/radial-tree documented as composition recipes
  (radial-tree recipe added to §3.2b); bubble packing (`layout_pack`)
  remains explicitly deferred.

### Refactoring pass: completeness, consistency, defaults

#### Bug fixes

- [`mark_network()`](https://zorrooz.github.io/plotit/reference/mark_network.md)
  node defaults now respect mapped aesthetics: `node_colour` is applied
  to the `colour` channel (previously only `fill`, which default shape
  19 ignores, so nodes rendered black) and `node_size` no longer
  overrides a user-mapped `size` variable. Each static is injected per
  channel, only when that channel is unmapped.
- [`mark_corr()`](https://zorrooz.github.io/plotit/reference/mark_corr.md)
  and
  [`mark_treemap()`](https://zorrooz.github.io/plotit/reference/mark_treemap.md)
  now route through the shared mark path, gaining white hairline
  separators consistent with
  [`mark_rect()`](https://zorrooz.github.io/plotit/reference/mark_rect.md).
- `layout_force(seed = ...)` no longer perturbs the caller’s global RNG
  stream (`.Random.seed` is saved/restored around the simulation).
- Removed 26 literal `<U+XXXX>` mojibake sequences from comments/roxygen
  (one of which leaked into
  [`scale_color()`](https://zorrooz.github.io/plotit/reference/scale_color.md)
  docs), a stray ESC control character in
  [`label_axis()`](https://zorrooz.github.io/plotit/reference/label_axis.md)
  docs, and a typo (`lement_blank`).

#### API

- **Breaking (extension contract):**
  [`project_parallel()`](https://zorrooz.github.io/plotit/reference/project_parallel.md)
  drops its dead `clip` parameter; it was documented as unused.
- `tidygraph` is now declared in `Suggests`:
  [`as_graph()`](https://zorrooz.github.io/plotit/reference/as_graph.md)
  accepts `tbl_graph` input but the dependency was previously
  undeclared.

#### Internal

- Standard marks declare their S7 generic through a
  `._make_mark_generic()` factory; layouts register both pipeline and
  bare-graph methods through `._register_layout_methods()`.
- Shared helpers extracted: render preparation (`._prepare_render()`),
  grob measurement/device sizing (`._measure_inches()` /
  `._open_sized_device()`), composite annotation setter, sankey/chord
  first-occurrence fill, and
  [`label_axis()`](https://zorrooz.github.io/plotit/reference/label_axis.md)
  reuses `._set_text_label()`.
- Internal helper naming normalized to the `._` prefix (e.g.
  `.theme_default()` → `._theme_default()`); zero lint findings
  restored.
