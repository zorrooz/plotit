# Changelog

## plotit 1.0.0

Initial CRAN release. plotit is a declarative, pipeline-first plotting
package built on ggplot2 4.x and S7: one verb per concept (`mark_*`,
`scale_*`, `project_*`, `split_*`, `label_*`, `compose_*`), curated
defaults everywhere, and a WYSIWYG panel contract shared by every render
path. This release systematises the whole API surface after a review of
Vega / Vega-Lite, AntV G2 5.0, tidyplots, tidyheatmaps, and Observable
Plot (see `.agent/design/`).

### plotit() and encode()

- **WYSIWYG panel sizing.** `width`/`height` describe the *panel area*
  and are baked into the chart (`theme(panel.widths=)`, ggplot2 4.0.0+
  capability) so every device — IDE, knitr, pkgdown, ggsave — renders
  the same proportions. Facet grids re-spread the same declared
  footprint across cells; fixed-aspect coordinates (CoordFixed) take
  precedence via a letterboxed export gtable instead of stretching.
- **Matrix input accepted.**
  [`plotit()`](https://zorrooz.github.io/plotit/reference/plotit.md)
  coerces plain or dimnamed matrices to a data frame at the boundary
  (dimnames become column/row names), so
  `plotit(matrix, encode(x = 1, y = 2))` works without the ggplot2 4.0
  “uniquely named columns” error (TBD-7).
- [`encode()`](https://zorrooz.github.io/plotit/reference/encode.md)
  keeps the full `aes()` vocabulary; factor-wrapped mappings get clean
  default axis titles (`encode(x = factor(cyl))` labels the axis “cyl”).
- `default_color` single-colour injection drives both `colour` and
  `fill`; any explicit colour/fill mapping or
  [`scale_color()`](https://zorrooz.github.io/plotit/reference/scale_color.md)/[`scale_fill()`](https://zorrooz.github.io/plotit/reference/scale_fill.md)
  call disables it automatically (managed registry).
- `size_unit` (`"in"`/`"cm"`/`"mm"`) always validated; `dodge` auto-set
  to 0.8 when a discrete axis is mapped; `autofit = TRUE` switches to
  option defaults.

### mark\_\* — geometric layers

#### New marks

- [`mark_image()`](https://zorrooz.github.io/plotit/reference/mark_image.md)
  — image scatter / ISOTYPE: custom `GeomPlotitImage` (rasterGrob +
  circular alpha-masked thumbnails, `src` channel, png/jpeg/magick-array
  sources, SVG-safe embedding).
- [`mark_encircle()`](https://zorrooz.github.io/plotit/reference/mark_encircle.md)
  — group envelopes: convex hull or confidence-ellipse engine with
  uniform padding and Chaikin-rounded corners.
- [`mark_ribbon()`](https://zorrooz.github.io/plotit/reference/mark_ribbon.md)
  — statistical interval bands (SE/SD/t-CI/bootstrap), same entity
  machinery as
  [`mark_errorbar()`](https://zorrooz.github.io/plotit/reference/mark_errorbar.md).
- [`mark_spoke()`](https://zorrooz.github.io/plotit/reference/mark_spoke.md),
  [`mark_curve()`](https://zorrooz.github.io/plotit/reference/mark_curve.md),
  [`mark_rug()`](https://zorrooz.github.io/plotit/reference/mark_rug.md)
  (sides/length),
  [`mark_step()`](https://zorrooz.github.io/plotit/reference/mark_step.md)
  (vh/hv/mid) complete the VL/G2 primitive vocabulary.
- [`mark_heatmap()`](https://zorrooz.github.io/plotit/reference/mark_heatmap.md)
  — matrix heatmap: internal melt + `geom_tile`, with `cluster=` (hclust
  / list(row=, col=) / enum), z-score scaling, `show_numbers=`
  auto-contrast text overlay, `na_color=`.

#### Statistical marks

- `mark_errorbar(stat=)` — entity matrix: identity / SE / SD / t-CI /
  percentile bootstrap-CI via `level=`, `ci_method=`, `seed=`
  (reproducible); `caps=`, `orientation=` routing (ggplot2 4.x native
  orientation, no `geom_errorbarh`).
- [`mark_smooth()`](https://zorrooz.github.io/plotit/reference/mark_smooth.md),
  [`mark_hex()`](https://zorrooz.github.io/plotit/reference/mark_hex.md),
  [`mark_bin2d()`](https://zorrooz.github.io/plotit/reference/mark_bin2d.md),
  [`mark_density_2d()`](https://zorrooz.github.io/plotit/reference/mark_density_2d.md),
  [`mark_contour()`](https://zorrooz.github.io/plotit/reference/mark_contour.md)
  (filled/bins), `mark_ecdf(n=)`,
  [`mark_qq()`](https://zorrooz.github.io/plotit/reference/mark_qq.md),
  [`mark_qq_line()`](https://zorrooz.github.io/plotit/reference/mark_qq_line.md),
  [`mark_corr()`](https://zorrooz.github.io/plotit/reference/mark_corr.md)
  — curated engines, optional `rasterize` via `ggrastr`.

#### Behaviour and fixes

- Unified style tokens (`._MARK_STYLE`): hairline borders, per-family
  line widths, curated alphas — one decision point for every mark
  default.
- Canvas chrome registry (`._MARK_CHROME`): heatmap/corr blank-canvas
  with row labels; tile/bin2d/hex keep light axes; relational sugars
  blank the axes; explicit
  `project_*()`/[`style()`](https://zorrooz.github.io/plotit/reference/style.md)
  always wins.
- [`mark_boxplot()`](https://zorrooz.github.io/plotit/reference/mark_boxplot.md)
  slim boxes + hairline strokes + staple caps;
  [`mark_polygon()`](https://zorrooz.github.io/plotit/reference/mark_polygon.md)
  defaults to the brand fill;
  [`mark_significance()`](https://zorrooz.github.io/plotit/reference/mark_significance.md)
  auto-stacks brackets;
  [`mark_network()`](https://zorrooz.github.io/plotit/reference/mark_network.md)
  gains canvas margins;
  [`mark_text()`](https://zorrooz.github.io/plotit/reference/mark_text.md)/[`mark_label()`](https://zorrooz.github.io/plotit/reference/mark_label.md)
  full ggrepel passthrough (`max.overlaps`, `seed`, `force`, …) with
  documented defaults.
- [`mark_text()`](https://zorrooz.github.io/plotit/reference/mark_text.md)
  `...` forwarding restored after a refactor regression.

### mark\_\* — relational sugars and layout\_\*

- Four sugars
  ([`mark_sankey()`](https://zorrooz.github.io/plotit/reference/mark_sankey.md),
  [`mark_chord()`](https://zorrooz.github.io/plotit/reference/mark_chord.md),
  [`mark_treemap()`](https://zorrooz.github.io/plotit/reference/mark_treemap.md),
  [`mark_network()`](https://zorrooz.github.io/plotit/reference/mark_network.md))
  share one static-channel vocabulary: `node_color`,
  `edge_color`/`edge_width`/`edge_alpha`, `show_labels`;
  ribbon/canvas/label/legend rendering is shared internally (`._rel_*`),
  edges canonicalisation through one `._rel_canon_edges()` contract.
- [`as_graph()`](https://zorrooz.github.io/plotit/reference/as_graph.md)
  — normalise edge tables, matrices/xtabs, hclust/dendrogram, parent-id
  hierarchies, or `tbl_graph` into a named table collection;
  `data = ~table` formula references bind geometry columns
  automatically.
- Layout engines are all pure R (igraph/tidygraph/circlize/treemapify
  retired):
  [`layout_force()`](https://zorrooz.github.io/plotit/reference/layout_force.md)
  (seeded Fruchterman-Reingold),
  [`layout_circle()`](https://zorrooz.github.io/plotit/reference/layout_circle.md),
  [`layout_tree()`](https://zorrooz.github.io/plotit/reference/layout_tree.md)
  (`leaf_spacing=`, straight/elbow edges),
  [`layout_dendrogram()`](https://zorrooz.github.io/plotit/reference/layout_dendrogram.md),
  [`layout_chord()`](https://zorrooz.github.io/plotit/reference/layout_chord.md),
  [`layout_sankey()`](https://zorrooz.github.io/plotit/reference/layout_sankey.md)
  (deterministic layered + Bézier ribbons),
  [`layout_treemap()`](https://zorrooz.github.io/plotit/reference/layout_treemap.md)
  (Bruls squarify). Re-layout is idempotent (last wins); random layouts
  mandate a `seed`.
- [`mark_beeswarm()`](https://zorrooz.github.io/plotit/reference/mark_beeswarm.md)
  — `ggbeeswarm` collision detection (the one allowed external
  algorithm).

### scale\_\*

- One verb per aesthetic:
  `scale_color/fill/size/alpha/shape/linetype/x/y` with Vega-aligned
  `trans`/`limits`/`range`/`name`; `trans`
  (`identity`/`log`/`log10`/`log2`/`sqrt`/`reverse`/`discrete`/`binned`)
  validated per channel type.
- Curated palette catalog via `range=`: 8 sequential + 7 qualitative + 6
  diverging named schemes (viridis, friendly Okabe-Ito colour-blind-safe
  six-colour, brewer, hue, plus diverging anchors).
- Default routing through one decision point: discrete
  (factor/character) colour/fill → friendly; continuous → viridis.
  Derived mark channels (corr value, hex count, density level,
  sankey/chord/treemap ribbons, network nodes) follow the same rule.
- Thin parameters: `na_color=`, `n_bins=` (binned), `mid=` (diverging
  anchor).
- Managed registry: auto-attached defaults are the *first* scale; any
  user `scale_*()` replaces them (last wins).
- [`scale_radius()`](https://zorrooz.github.io/plotit/reference/scale_radius.md)
  is **defunct** since 1.0 — radius/area encoding belongs to
  `scale_size(range=)`.
- `range` for x/y expresses the data’s visual footprint on the panel
  (implemented via `limits` + `expand = c(0, 0)`).

### project\_\* and split\_\*

- [`project_polar()`](https://zorrooz.github.io/plotit/reference/project_polar.md)
  — `start`/`end`/`reverse` (+ deprecation cycle for `direction`),
  `inner_radius` radial mode and `r.axis.inside` via ggplot2 4.0
  `coord_radial` (dotted spelling); polar canvas blanks axis chrome
  unless user overrides.
- [`project_parallel()`](https://zorrooz.github.io/plotit/reference/project_parallel.md)
  — `order`/`recenter`/`aggregate` modes with per-column axes
  (`"std"`/`"global"`/`"none"`), `axis_labels=` toggle.
- [`project_cartesian()`](https://zorrooz.github.io/plotit/reference/project_cartesian.md)
  — `flip`/`fixed`/`coord_trans`/`xlim`/`ylim`;
  [`project_map()`](https://zorrooz.github.io/plotit/reference/project_map.md)
  — `coord_sf` default, `coord_map` on `projection=`.
- `split_wrap(dir=)` — 8-direction facet flow; `split_grid(axes=)`;
  WYSIWYG panel sizes re-baked across the new grid after faceting.

### label\_\* and style()

- Three-parameter protocol (`text`/`hide`/`reset`) with fixed precedence
  (reset \> hide \> text), removing call-order dependence.
- `label_legend(aes = NULL)` global default mode for all mapped
  aesthetics.
- [`style()`](https://zorrooz.github.io/plotit/reference/style.md) —
  academic default theme (white paper, ink hairline axes/ticks, no
  gridlines, transparent background, tiered type sizes) driven by
  `._STYLE_TOKENS`; `style(p)` restores the built-in default;
  token-driven `base_size`/`base_family`/`base_theme` support.
- Parallel-coordinate “none” mode renders per-column axes from the
  active theme properties.

### compose\_\*

- [`compose_grid()`](https://zorrooz.github.io/plotit/reference/compose_grid.md)
  — design strings/area syntax (patchwork areas), three-state sizes
  (fixed/null/auto), shared axes and collected guides, `tag_levels`.
- [`compose_annot()`](https://zorrooz.github.io/plotit/reference/compose_annot.md)
  — annotation strips (group / heatmap sidebars) with aligned tree bars
  and spacer gaps — the flagship complex-heatmap recipe.
- [`compose_inset()`](https://zorrooz.github.io/plotit/reference/compose_inset.md)
  /
  [`compose_marginal()`](https://zorrooz.github.io/plotit/reference/compose_marginal.md)
  — alignment and axis-hiding hardened; composite default sizing derived
  from subplot meta (patchworkGrob is never measured directly).

### export()

- Device from file extension; explicit `width`/`height` honour
  `size_unit`; WYSIWYG gtable path with letterboxed aspect-true panels.
- `export(list)` — multipage PDF via explicit
  [`grDevices::pdf`](https://rdrr.io/r/grDevices/pdf.html) + per-page
  `grid.newpage()`; composite pages normalised to a single
  `patchworkGrob` (PDF only — svg/png silently keep only the last page,
  so they are rejected with a targeted message, DEC-1).

### Extension surface

- [`make_mark()`](https://zorrooz.github.io/plotit/reference/make_mark.md)
  /
  [`make_theme()`](https://zorrooz.github.io/plotit/reference/make_theme.md)
  — register custom marks/themes from any ggplot2 geom/theme; stable
  signatures (extension contract tier); custom marks outside the chrome
  registry default to `axis = "keep"` (zero behavioural difference).
- [`add_ggplot()`](https://zorrooz.github.io/plotit/reference/add_ggplot.md)
  — the single explicit escape hatch, replacing the former S3 `+` on
  plotit/composite objects. Any ggplot2 component (annotate, guides,
  labs, custom layers, `stat_manual(fun=)` recipes, facets) can be
  attached and the pipeline continues.

### Error handling

- Three-part structured messages (problem / cause / remedy) across the
  whole package, built from `._abort_*` / `._warn_*` constructors; enum
  errors list every legal value; interval constraints rendered without
  cli glue crashes.

### Breaking changes and migration

- `+` on `plotit` / `plotit_composite` removed → use
  [`add_ggplot()`](https://zorrooz.github.io/plotit/reference/add_ggplot.md).
- `style_default()` removed →
  [`style()`](https://zorrooz.github.io/plotit/reference/style.md).
- `transform_corr()` removed →
  [`mark_corr()`](https://zorrooz.github.io/plotit/reference/mark_corr.md).
- `mark_sankey(position=)` removed (never used).
- `mark_treemap(rasterize=)` removed (relational sugars do not
  rasterize).
- [`scale_radius()`](https://zorrooz.github.io/plotit/reference/scale_radius.md)
  defunct → `scale_size(range=)`.
- `mark_arc` / `mark_tick` / `mark_tree` removed → composition recipes
  (bar+polar donut, point+jitter strip, rect+hierarchy icicle).
- `as_graph(directed=)` warns when the input type decides directedness.
- Requires **ggplot2 \>= 4.0.0** (panel-sizing theme elements,
  coord_radial spelling, native orientation).

### Documentation

- Six vignette-style articles (getting started, customizing, composing,
  relational charts, design philosophy, transform recipes).
- Gallery pages: comparisons, distributions, relationships, time &
  coordinates, trends, matrix, proportions, geo, relational,
  annotations, and annotation & composition; use-case pages
  (bioinformatics, publishing).
- README / README_ZH in sync (43 marks across three tiers); pkgdown site
  in release mode.

### Development and QA

- 1209 BDD-style assertions across 22 test files, 0 failures;
  `lintr::lint_package()` clean; `R CMD check --as-cran` 0 ERROR / 0
  WARNING / 0 NOTE; pkgdown local build EXIT = 0.
- CI matrix (ubuntu/windows/macOS × release + ubuntu devel) on dev and
  main.
- The “1089/978 PASS” baseline figures from earlier drafts are corrected
  to the measured 1201 (prompt §2/§7 wording updated).
