# plotit 1.0.0

First stable API release of the declarative plotit pipeline on top of ggplot2
(>= 4.0.0). The 1.0 contract covers verb-prefix construction (`plotit` /
`encode`), 43 `mark_*` layers, scale/project/split/label/style/export, graph
layouts, and multi-panel `compose_*`.

## Plot construction

* `plotit()` / `encode()`: WYSIWYG Nature single-column panel default
  (89 x 56 mm), tidyplots-calibrated theme tokens, friendly/viridis default
  palettes via a single colour-scale decision point.
* Discrete colour/fill mirroring attaches the twin channel with
  `guide = "none"` so one group variable never renders two legends.
* `add_ggplot()` escape hatch for raw ggplot2 components without leaving the
  pipe.

## Marks (43)

* **Basic geometry**: point, line, area, bar, rect, polygon, text, label,
  rule, path, step, rug, spoke, curve, histogram, density, boxplot, violin,
  map.
* **Statistical**: smooth, hex, bin2d, density_2d, contour, count, corr,
  heatmap, ecdf, qq, qq_line.
* **Composite / relational**: significance, errorbar, ribbon, lollipop,
  dumbbell, forest, beeswarm, image, encircle, sankey, treemap, network,
  chord.
* `mark_errorbar` / `mark_ribbon`: statistical entities
  (`mean_sem` / `mean_sd` / `mean_range` / `mean_ci95`); cap width is
  method-injected only for `caps = TRUE` (token 0.4).
* `mark_bar` no longer replaces a pre-installed continuous y scale when
  applying the tidyplots lower-expand flush.
* `mark_rule` segment path shares the reference-line linewidth default.
* `mark_map` layer-level colour/fill mappings use the curated default
  palette decision point.
* `make_mark()` registers methods under the requested mark name so style
  defaults and chrome lookups resolve correctly.

## Scales, projects, splits, labels

* `scale_*`: Vega-style trans/range matrix; colour schemes include sequential
  viridis family and diverging anchors (`mid=`); `scale_radius()` is defunct
  in favour of `scale_size()`.
* `project_polar()` supports `start`/`end`/`reverse`/`rotate_angle`;
  `direction` is deprecated in favour of `reverse`.
* `project_parallel()`, `project_cartesian()`, `project_map()`.
* `label_*` three-parameter protocol (`reset` > `hide` > `text`); hide is
  logical FALSE only (literal `"FALSE"` is text).
* `style()` accepts a theme object or a theme function; font args forwarded
  to theme functions and warned when a complete theme object is also given.

## Graph data and layouts

* `as_graph()`, `layout_force()`, `layout_circle()`, `layout_tree()`,
  `layout_dendrogram()`, `layout_sankey()`, `layout_chord()`,
  `layout_treemap()` — pure-R engines (no igraph/ggraph/circlize/ggsankey).
* Relational sugar marks: `mark_sankey`, `mark_treemap`, `mark_network`,
  `mark_chord` over edges-table API; formula `data = ~nodes` / `~edges`
  against `@graph`.

## Composition

* `compose_grid()` (design layouts, axis-title sharing),
  `compose_inset()`, `compose_marginal()`, `compose_annot()`.
* Nested composites apply inner annotations before outer assembly.
* `compose_annot(gap=)` no longer absorbs spacer rows into the base cell.
* Default composite canvas sizes account for present marginal sides, annot
  strips + gaps, and design grid geometry.
* Inset legend parking uses patchwork `&` for composite insets.

## Export

* `export()` for single plots and composites; `dpi` default **600**;
  multipage PDF when given a list of plotit objects.

## Documentation

* Five-article pkgdown IA (Get Started, Gallery, Advanced, API, Design Goals).
* NEWS.md summarises the 1.0 surface; README lifecycle set to maturing.
