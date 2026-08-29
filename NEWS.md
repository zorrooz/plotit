# plotit 1.0.0

Initial CRAN release. plotit is a declarative, pipeline-first plotting
package built on ggplot2 4.x and S7: one verb per concept (`mark_*`,
`scale_*`, `project_*`, `split_*`, `label_*`, `compose_*`), curated
defaults everywhere, and a WYSIWYG panel contract shared by every render
path.  This release systematises the whole API surface after a review of
Vega / Vega-Lite, AntV G2 5.0, tidyplots, tidyheatmaps, and Observable
Plot (see `.agent/design/`).

## plotit() and encode()

* **WYSIWYG panel sizing.** `width`/`height` describe the *panel area*
  and are baked into the chart (`theme(panel.widths=)`, ggplot2 4.0.0+
  capability) so every device — IDE, knitr, pkgdown, ggsave — renders the
  same proportions.  Facet grids re-spread the same declared footprint
  across cells; fixed-aspect coordinates (CoordFixed) take precedence via a
  letterboxed export gtable instead of stretching.
* **Matrix input accepted.** `plotit()` coerces plain or dimnamed matrices
  to a data frame at the boundary (dimnames become column/row names), so
  `plotit(matrix, encode(x = 1, y = 2))` works without the ggplot2 4.0
  "uniquely named columns" error (TBD-7).
* `encode()` keeps the full `aes()` vocabulary; factor-wrapped mappings get
  clean default axis titles (`encode(x = factor(cyl))` labels the axis
  "cyl").
* `default_color` single-colour injection drives both `colour` and `fill`;
  any explicit colour/fill mapping or `scale_color()`/`scale_fill()` call
  disables it automatically (managed registry).
* `size_unit` (`"in"`/`"cm"`/`"mm"`) always validated; `dodge` auto-set to
  0.8 when a discrete axis is mapped; `autofit = TRUE` switches to option
  defaults.

## mark_* — geometric layers

### New marks

* `mark_image()` — image scatter / ISOTYPE: custom `GeomPlotitImage`
  (rasterGrob + circular alpha-masked thumbnails, `src` channel,
  png/jpeg/magick-array sources, SVG-safe embedding).
* `mark_encircle()` — group envelopes: convex hull or confidence-ellipse
  engine with uniform padding and Chaikin-rounded corners.
* `mark_ribbon()` — statistical interval bands (SE/SD/t-CI/bootstrap),
  same entity machinery as `mark_errorbar()`.
* `mark_spoke()`, `mark_curve()`, `mark_rug()` (sides/length),
  `mark_step()` (vh/hv/mid) complete the VL/G2 primitive vocabulary.
* `mark_heatmap()` — matrix heatmap: internal melt + `geom_tile`, with
  `cluster=` (hclust / list(row=, col=) / enum), z-score scaling,
  `show_numbers=` auto-contrast text overlay, `na_color=`.

### Statistical marks

* `mark_errorbar(stat=)` — entity matrix: identity / SE / SD /
  t-CI / percentile bootstrap-CI via `level=`, `ci_method=`, `seed=`
  (reproducible); `caps=`, `orientation=` routing (ggplot2 4.x native
  orientation, no `geom_errorbarh`).
* `mark_smooth()`, `mark_hex()`, `mark_bin2d()`, `mark_density_2d()`,
  `mark_contour()` (filled/bins), `mark_ecdf(n=)`, `mark_qq()`,
  `mark_qq_line()`, `mark_corr()` — curated engines, optional
  `rasterize` via `ggrastr`.

### Behaviour and fixes

* Unified style tokens (`._MARK_STYLE`): hairline borders, per-family line
  widths, curated alphas — one decision point for every mark default.
* Canvas chrome registry (`._MARK_CHROME`): heatmap/corr blank-canvas with
  row labels; tile/bin2d/hex keep light axes; relational sugars blank the
  axes; explicit `project_*()`/`style()` always wins.
* `mark_boxplot()` slim boxes + hairline strokes + staple caps;
  `mark_polygon()` defaults to the brand fill; `mark_significance()`
  auto-stacks brackets; `mark_network()` gains canvas margins;
  `mark_text()`/`mark_label()` full ggrepel passthrough
  (`max.overlaps`, `seed`, `force`, ...) with documented defaults.
* `mark_text()` `...` forwarding restored after a refactor regression.

## mark_* — relational sugars and layout_*

* Four sugars (`mark_sankey()`, `mark_chord()`, `mark_treemap()`,
  `mark_network()`) share one static-channel vocabulary:
  `node_color`, `edge_color`/`edge_width`/`edge_alpha`, `show_labels`;
  ribbon/canvas/label/legend rendering is shared internally
  (`._rel_*`), edges canonicalisation through one `._rel_canon_edges()`
  contract.
* `as_graph()` — normalise edge tables, matrices/xtabs, hclust/dendrogram,
  parent-id hierarchies, or `tbl_graph` into a named table collection;
  `data = ~table` formula references bind geometry columns automatically.
* Layout engines are all pure R (igraph/tidygraph/circlize/treemapify
  retired): `layout_force()` (seeded Fruchterman-Reingold),
  `layout_circle()`, `layout_tree()` (`leaf_spacing=`, straight/elbow
  edges), `layout_dendrogram()`, `layout_chord()`, `layout_sankey()`
  (deterministic layered + Bézier ribbons), `layout_treemap()`
  (Bruls squarify).  Re-layout is idempotent (last wins); random layouts
  mandate a `seed`.
* `mark_beeswarm()` — `ggbeeswarm` collision detection (the one allowed
  external algorithm).

## scale_*

* One verb per aesthetic: `scale_color/fill/size/alpha/shape/linetype/x/y`
  with Vega-aligned `trans`/`limits`/`range`/`name`; `trans`
  (`identity`/`log`/`log10`/`log2`/`sqrt`/`reverse`/`discrete`/`binned`)
  validated per channel type.
* Curated palette catalog via `range=`: 8 sequential + 7 qualitative +
  6 diverging named schemes (viridis, friendly Okabe-Ito colour-blind-safe
  six-colour, brewer, hue, plus diverging anchors).
* Default routing through one decision point: discrete (factor/character)
  colour/fill → friendly; continuous → viridis.  Derived mark channels
  (corr value, hex count, density level, sankey/chord/treemap ribbons,
  network nodes) follow the same rule.
* Thin parameters: `na_color=`, `n_bins=` (binned), `mid=` (diverging
  anchor).
* Managed registry: auto-attached defaults are the *first* scale; any
  user `scale_*()` replaces them (last wins).
* `scale_radius()` is **defunct** since 1.0 — radius/area encoding belongs
  to `scale_size(range=)`.
* `range` for x/y expresses the data's visual footprint on the panel
  (implemented via `limits` + `expand = c(0, 0)`).

## project_* and split_*

* `project_polar()` — `start`/`end`/`reverse` (+ deprecation cycle for
  `direction`), `inner_radius` radial mode and `r.axis.inside` via
  ggplot2 4.0 `coord_radial` (dotted spelling); polar canvas blanks axis
  chrome unless user overrides.
* `project_parallel()` — `order`/`recenter`/`aggregate` modes with
  per-column axes (`"std"`/`"global"`/`"none"`), `axis_labels=` toggle.
* `project_cartesian()` — `flip`/`fixed`/`coord_trans`/`xlim`/`ylim`;
  `project_map()` — `coord_sf` default, `coord_map` on `projection=`.
* `split_wrap(dir=)` — 8-direction facet flow; `split_grid(axes=)`;
  WYSIWYG panel sizes re-baked across the new grid after faceting.

## label_* and style()

* Three-parameter protocol (`text`/`hide`/`reset`) with fixed precedence
  (reset > hide > text), removing call-order dependence.
* `label_legend(aes = NULL)` global default mode for all mapped
  aesthetics.
* `style()` — academic default theme (white paper, ink hairline
  axes/ticks, no gridlines, transparent background, tiered type sizes)
  driven by `._STYLE_TOKENS`; `style(p)` restores the built-in default;
  token-driven `base_size`/`base_family`/`base_theme` support.
* Parallel-coordinate "none" mode renders per-column axes from the active
  theme properties.

## compose_*

* `compose_grid()` — design strings/area syntax (patchwork areas),
  three-state sizes (fixed/null/auto), shared axes and collected guides,
  `tag_levels`.
* `compose_annot()` — annotation strips (group / heatmap sidebars) with
  aligned tree bars and spacer gaps — the flagship complex-heatmap
  recipe.
* `compose_inset()` / `compose_marginal()` — alignment and axis-hiding
  hardened; composite default sizing derived from subplot meta
  (patchworkGrob is never measured directly).

## export()

* Device from file extension; explicit `width`/`height` honour
  `size_unit`; WYSIWYG gtable path with letterboxed aspect-true panels.
* `export(list)` — multipage PDF via explicit `grDevices::pdf` +
  per-page `grid.newpage()`; composite pages normalised to a single
  `patchworkGrob` (PDF only — svg/png silently keep only the last page,
  so they are rejected with a targeted message, DEC-1).

## Extension surface

* `make_mark()` / `make_theme()` — register custom marks/themes from any
  ggplot2 geom/theme; stable signatures (extension contract tier);
  custom marks outside the chrome registry default to `axis = "keep"`
  (zero behavioural difference).
* `add_ggplot()` — the single explicit escape hatch, replacing the former
  S3 `+` on plotit/composite objects.  Any ggplot2 component (annotate,
  guides, labs, custom layers, `stat_manual(fun=)` recipes, facets) can
  be attached and the pipeline continues.

## Error handling

* Three-part structured messages (problem / cause / remedy) across the
  whole package, built from `._abort_*` / `._warn_*` constructors;
  enum errors list every legal value; interval constraints rendered
  without cli glue crashes.

## Breaking changes and migration

* `+` on `plotit` / `plotit_composite` removed → use `add_ggplot()`.
* `style_default()` removed → `style()`.
* `transform_corr()` removed → `mark_corr()`.
* `mark_sankey(position=)` removed (never used).
* `mark_treemap(rasterize=)` removed (relational sugars do not rasterize).
* `scale_radius()` defunct → `scale_size(range=)`.
* `mark_arc` / `mark_tick` / `mark_tree` removed → composition recipes
  (bar+polar donut, point+jitter strip, rect+hierarchy icicle).
* `as_graph(directed=)` warns when the input type decides directedness.
* Requires **ggplot2 >= 4.0.0** (panel-sizing theme elements, coord_radial
  spelling, native orientation).

## Documentation

* Six vignette-style articles (getting started, customizing, composing,
  relational charts, design philosophy, transform recipes).
* Gallery pages: comparisons, distributions, relationships, time &
  coordinates, trends, matrix, proportions, geo, relational, annotations,
  and annotation & composition; use-case pages (bioinformatics,
  publishing).
* README / README_ZH in sync (43 marks across three tiers); pkgdown site
  in release mode.

## Development and QA

* 1209 BDD-style assertions across 22 test files, 0 failures;
  `lintr::lint_package()` clean; `R CMD check --as-cran` 0 ERROR /
  0 WARNING / 0 NOTE; pkgdown local build EXIT = 0.
* CI matrix (ubuntu/windows/macOS × release + ubuntu devel) on dev and
  main.
* The "1089/978 PASS" baseline figures from earlier drafts are corrected
  to the measured 1201 (prompt §2/§7 wording updated).