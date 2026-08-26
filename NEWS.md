# plotit (development version)

* Active development stage — frequent breaking changes expected.
* See [GitHub releases](https://github.com/zorrooz/plotit/releases) for version history.

## API systematisation round (0.0.0.9001)

Reference-driven API refactor following Vega / Vega-Lite, AntV G2 5.0,
tidyplots and Observable Plot design pillars: one verb per concept, shared
modules per function family, curated defaults everywhere.

### Removed (globally inconsistent APIs)

* `style_default()` — pure alias of `style()`; removed (one verb, one meaning).
* `transform_corr()` — orphan single-verb family; folded back into the package
  interior as `._transform_corr()`. `mark_corr()` remains the public surface.
* `mark_sankey(position = )` — accepted but never used; removed from signature.
* `mark_treemap(rasterize = ...)` — violated the relational-sugar rule
  (no `rasterize`, AGENTS §3.3.3b principle 3); removed.
* `._MARK_DEFAULTS$mark_treemap` — dead entry (treemap renders through
  `mark_rect`); removed with the stale treemapify-era comment.

### Signature vocabulary normalised

* `mark_rule()` colour parameter renamed to American `color =` (the British
  spelling still works via `...` passthrough — geoms accept both).
* `mark_network()` gained `edge_alpha = NULL` and `show_labels = TRUE`;
  `mark_sankey()` / `mark_chord()` gained `show_labels = TRUE` — the four
  relational sugars now share one static-channel vocabulary
  (`node_color`, `edge_color`/`edge_width`/`edge_alpha`, `show_labels`).
* `as_graph(directed = )` now warns when the input type decides its own
  directedness instead of silently swallowing the argument.

### Componentisation (shared modules)

* `._impl_with()` — one entry point for merged extra-args dispatch
  (smooth / hex / density_2d / corr / errorbar / beeswarm).
* `._derived_fill()` — single managed fill installer for closed statistical
  marks, replacing three inline `suppressMessages(scale_fill(...))` copies.
* `._require_pkg()` — one optional-dependency guard (7 call sites).
* Relational sugars share `._rel_reject_dots()`, `._rel_ribbon_layer()`,
  `._rel_label_layer()`, `._rel_legend_title()`, `._rel_canvas()`; the
  network sugar's edge canonicalisation now routes through the same
  `._rel_canon_edges()` contract as sankey/chord (mechanically removes a
  ~50-line duplicate).
* `._cf()` moved to `theme.R` beside the palette decision point (it serves
  both theme and scale modules).
* Split family shares `._split_facet_dots()` and re-bakes WYSIWYG panel
  sizing after facets change the grid (`._split_rebake_size()`).
* Composite helpers: `._prep_subplot_gg()`, `._new_annotations()`,
  `._ggsave_inches()`, `._ensure_theme()`; `export()` now applies the
  theme fallback before rendering (print/export parity).
* zzz.R composite stubs are built from per-family catalogs
  (`._CATALOG_MARKS` / `_LAYOUTS` / `_SCALES` / `_PROJECTS` / `_SPLITS`)
  and verify every catalogued generic exists at load time.

### Bug fixes surfaced by rendered-image QA

* `mark_text()` dropped `...` forwarding during refactor — every label
  colour/size parameter silently vanished; restored.
* Composite `label_title()`/`label_subtitle()`/`label_caption()` wrote
  every annotation into the last field (title rendered bottom-right as a
  caption); reverted to three explicit thin methods over the shared setter.
* Composite rejection stubs had never registered (catalog lookup broke),
  and the stub environment had an empty parent chain (would crash on the
  first call) — single-plot verbs on composites now fail with the intended
  targeted message. Covered by new BDD tests.
* WYSIWYG panel sizing treated every facet cell as a full-size panel:
  `split_wrap(ncol = 3)` rendered ~15in wide inside a 7.5in canvas. Panel
  sizes now describe the whole panel area and are re-spread across the
  facet grid (baked theme + fixed-gtable paths).
* `label_legend()` no longer deletes untouched sibling legend titles when
  a single aesthetic gets an override.

### Documentation

* README / README_ZH / _pkgdown.yml / vignettes synced (removed API rows,
  corrected treemap engine row, `style_default` references).
* AGENTS.md updated: contract tiers, relational vocabulary, mark signature
  exceptions, panel-area sizing semantics, recipe notes (radar closure,
  donut axis chrome).
