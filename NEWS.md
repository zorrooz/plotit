# plotit (development version)

* Active development stage — frequent breaking changes expected.
* See [GitHub releases](https://github.com/zorrooz/plotit/releases) for version history.

## Default visual system overhaul (tidyplots-inspired)

### Fix: reference-example clipping on the docs site

- Baked WYSIWYG panels previously used a 7x5 in canvas whose total
  footprint (~8.6 in wide with legend) exceeded pkgdown's default figure
  device (~7.29 in), cropping plot edges on the documentation site.
- `plotit()` now defaults to a compact academic panel of **5 x 3.5 in**
  (total footprint ~6.6 x 4.1 in), which fits every standard render path
  (pkgdown, knitr, RStudio preview, ggsave) without clipping.
  `_pkgdown.yml` additionally pins an 8.5 x 5.5 in example canvas for
  wide legends and compose examples.
- Base font drops from 11 to 10 pt to keep type density harmonious with
  the smaller canvas (`_STYLE_TOKENS$base_size`).

### Visual coordination: slim boxplots

- `mark_boxplot()` gains curated defaults calibrated against tidyplots'
  `add_boxplot()`: box width 0.5 of each slot (was ~0.9, boxes nearly
  touching), hairline stroke 0.25, staple caps 0.4, outlier dots shrunk
  to size 0.6. Inter-box breathing room goes from ~0.1 to ~0.38 slot
  widths. All values remain overridable through `...`.

### New: centralised style module

- New `R/theme.R` — single source of truth for every global default visual
  decision (`._STYLE_TOKENS` tokens, ink/paper anchors, palette sampling,
  theme builder, WYSIWYG panel sizing). Changing the package look now
  requires editing one file. `style.R` keeps only the user-facing
  `style()` / `style_default()` generics.

### WYSIWYG sizing (IDE preview == export)

- `plotit()` bakes absolute panel dimensions into the ggplot object via
  ggplot2 >= 3.5 `theme(panel.widths =, panel.heights =)`. The physical
  panel size is now identical on every render path — IDE device, knitr,
  pkgdown reference examples, and `ggsave()`/`export()`. Verified: a
  7x5 in plot renders its panel at exactly 7x5 in on 6x6, 9x7 and 14x10
  inch devices (previously the content stretched with the device).
- Composites strip the constraint before patchwork assembly
  (`._reset_sizing()` -> `._strip_panel_size()`), using only the public
  `+ theme(panel.widths = NULL)` reset for ggplot2 4.x S7-theme safety.
- Graceful degradation when ggplot2 < 3.5 is installed.

### Academic-minimal default theme

- Pure-ink hairline axis lines and ticks at linewidth 0.25 (was grey50 at
  0.3); gridless paper panel; fully transparent chrome.
- Calibrated type hierarchy: plain left-aligned title at rel(1.15)
  (was bold), muted subtitle/caption, axis.title rel(0.95), axis.text
  rel(0.85), legend text rel(0.85) with 3.5 mm keys.

### Curated default palettes (constructed-in, override-friendly)

- Mapped discrete `colour`/`fill` aesthetics now receive the colourblind-
  safe "friendly" scheme by default (Okabe-Ito six-colour set with the
  bright yellow darkened to `#F5C710`; even subsampling up to six levels,
  interpolation beyond). Previously fell through to the raw hue wheel.
- Mapped continuous aesthetics default to viridis.
- Defaults attach at construction time; any later user `scale_*()` still
  wins (last-wins). AsIs constants (`encode(colour = I("red"))`) bypass
  the default scales and keep identity rendering; the unmapped
  single-colour injection stays Tableau blue `#4E79A7`.
- `scale_color()`/`scale_fill()` gain the explicit `"friendly"` scheme;
  `"hue"` remains opt-in. Discrete defaults route through
  `discrete_scale(palette=)` because ggplot2 >= 4.0's backward-compatibility
  layer mis-executes palette functions passed to `scale_*_discrete(type=)`.

## Relational charts: full self-implementation

### Breaking

- `igraph` removed from Suggests entirely:
  - `layout_force()` now runs a self-contained Fruchterman-Reingold engine
    (pairwise repulsion, edge attraction with optional `weights`, linear
    cooling). Unknown passthrough arguments are ignored with a warning
    (previously forwarded to `igraph::layout_with_fr`).
  - `layout_tree()` now uses an in-house leaf-ordering walk shared with
    `layout_dendrogram()` (`._hierarchy_leaf_x`). Leaf x positions are
    sequential left-to-right; internal nodes sit at mean child position.
    Orientation semantics per `direction` are unchanged.
  - `as_graph()` tbl_graph input detects directedness via igraph when
    available and degrades to undirected otherwise.
- `treemapify` removed from Suggests; `mark_treemap()` rewritten as sugar
  over the self-contained `layout_treemap()` squarify engine. It now takes
  a hierarchy table (`id`/`parent`/leaf `value`) instead of treemapify's
  `area`/`subgroup` aesthetics, renders through `mark_rect(data = ~leaves)`
  with white hairline separators, draws centred leaf labels, blanks the
  coordinate axes, and stores nodes/edges/leaves on `@graph`.

### Default style consistency / beauty (relational family)

- `mark_network()`: edges render **beneath** node points (previously lines
  crossed over markers), labels float above points instead of overlapping,
  the panel gains `coord_fixed()` so layouts are not stretched, and axis
  blanking moves to the shared helper.
- `mark_chord()`: sector ids are labelled outside the ring on the layout's
  anchors, and the panel gets `coord_fixed(clip = "off")` so sectors stay
  circular without cropping.
- `mark_sankey()`: node labels switch to contrast-aware colours (white over
  the default ink fill, near-black over mapped fills); axes blanked.
- New shared helper `._theme_blank_axes()` unifies the coordinate-free look
  across network/sankey/chord/treemap.
- Derived fill/colour channels on relational sugars now ship plotit's
  curated viridis default instead of raw ggplot2 hues (last call wins):
  sankey flows/nodes always; chord/treemap when a `fill` is mapped;
  network when node `colour` is mapped. Unmapped chord keeps its neutral
  band/arc greys; unmapped treemap/network keep the brand-blue static.

### Types

- Relational type coverage audited against ECharts/G6-G2/D3/Plotly/
  Highcharts (see AGENTS.md §3.2c). Core relational domain fully covered;
  sunburst/icicle/radial-tree documented as composition recipes
  (radial-tree recipe added to §3.2b); bubble packing (`layout_pack`)
  remains explicitly deferred.

## Refactoring pass: completeness, consistency, defaults

### Bug fixes

- `mark_network()` node defaults now respect mapped aesthetics: `node_colour`
  is applied to the `colour` channel (previously only `fill`, which default
  shape 19 ignores, so nodes rendered black) and `node_size` no longer
  overrides a user-mapped `size` variable. Each static is injected per
  channel, only when that channel is unmapped.
- `mark_corr()` and `mark_treemap()` now route through the shared mark path,
  gaining white hairline separators consistent with `mark_rect()`.
- `layout_force(seed = ...)` no longer perturbs the caller's global RNG
  stream (`.Random.seed` is saved/restored around the simulation).
- Removed 26 literal `<U+XXXX>` mojibake sequences from comments/roxygen
  (one of which leaked into `scale_color()` docs), a stray ESC control
  character in `label_axis()` docs, and a typo (`lement_blank`).

### API

- **Breaking (extension contract):** `project_parallel()` drops its dead
  `clip` parameter; it was documented as unused.
- `tidygraph` is now declared in `Suggests`: `as_graph()` accepts
  `tbl_graph` input but the dependency was previously undeclared.

### Internal

- Standard marks declare their S7 generic through a `._make_mark_generic()`
  factory; layouts register both pipeline and bare-graph methods through
  `._register_layout_methods()`.
- Shared helpers extracted: render preparation (`._prepare_render()`), grob
  measurement/device sizing (`._measure_inches()` / `._open_sized_device()`),
  composite annotation setter, sankey/chord first-occurrence fill, and
  `label_axis()` reuses `._set_text_label()`.
- Internal helper naming normalized to the `._` prefix (e.g.
  `.theme_default()` → `._theme_default()`); zero lint findings restored.
