# plotit

[简体中文](https://zorrooz.github.io/plotit/README_ZH.html) \|
**English**

> ⚠️ **Early development stage.**  
> plotit is under active, pre-release development. Breaking changes are
> **extremely likely** with every update. The API is incomplete, many
> planned features are missing, and bugs are expected. Do not use in
> production. Use at your own risk. Feedback and contributions are
> welcome.

------------------------------------------------------------------------

## Overview

**plotit** is a declarative, pipeline-first R package for creating
publication-quality visualisations. Built on
[ggplot2](https://ggplot2.tidyverse.org), it replaces `+`-based layering
with a unified **verb-prefix API** powered by the native pipe (`|>`).
Sensible defaults eliminate boilerplate — colour, theme, and sizing work
out of the box.

``` r

library(plotit)

iris |>
  plotit(encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
  mark_point(size = 2, alpha = 0.7) |>
  scale_color(range = "viridis") |>
  label_title("Iris Sepal Dimensions") |>
  style(base_theme = ggplot2::theme_minimal(base_size = 14)) |>
  export("iris_plot.pdf")
```

## Installation

You can install the development version of plotit from GitHub:

``` r

# install.packages("pak")
pak::pak("zorrooz/plotit")
```

## Quick start

``` r

library(plotit)

# Scatter plot with colour mapping
iris |>
  plotit(encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
  mark_point()

# Bar chart of counts
mtcars |>
  plotit(encode(x = factor(cyl))) |>
  mark_bar()

# Line chart for time series
ggplot2::economics |>
  plotit(encode(x = date, y = unemploy)) |>
  mark_line()

# Multi-plot dashboard
p1 <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
p2 <- plotit(iris, encode(x = Species, y = Sepal.Length)) |> mark_boxplot()
compose_grid(p1, p2, tag_levels = "A") |>
  label_title("Iris Dashboard") |>
  export("dashboard.png")

# Sankey flow diagram from an edge table
flows <- data.frame(
  source = c("A", "A", "B", "B", "C"),
  target = c("B", "C", "C", "D", "D"),
  value  = c(10, 5, 8, 3, 6)
)
flows |>
  plotit(encode(source = source, target = target,
                value = value, fill = source)) |>
  mark_sankey()
```

## The pipeline

Every plotit chart follows a consistent pipeline:

    data |> plotit(encode(...)) |> mark_*() |> scale_*() |> layout_*() |> split_*() |> project_*() |> label_*() |> style() |> export()

| Step | Verb | Role |
|:---|:---|:---|
| 1\. Initialise | [`plotit()`](https://zorrooz.github.io/plotit/reference/plotit.md) + [`encode()`](https://zorrooz.github.io/plotit/reference/encode.md) | Bind data and aesthetic mappings |
| 2\. Layer | `mark_*()` | Add geometric layers (points, lines, bars, …) |
| 3\. Scale | `scale_*()` | Control how data maps to visual properties |
| 4\. Layout | `layout_*()` | Compute relational layouts (optional; sankey, network, chord, treemap) |
| 5\. Facet | `split_*()` | Split into small multiples |
| 6\. Coordinate | `project_*()` | Choose coordinate system (cartesian, polar, map) |
| 7\. Label | `label_*()` | Set titles, axis labels, legend titles |
| 8\. Theme | [`style()`](https://zorrooz.github.io/plotit/reference/style.md) | Apply a complete theme |
| 9\. Export | [`export()`](https://zorrooz.github.io/plotit/reference/export.md) | Render to file |

Multi-plot compositions follow their own outermost pipeline:

    compose_*(p1, p2, ...) |> label_*() |> style() |> export()

## Function families

### `mark_*` — Geometric layers

27 marks across three tiers: basic geometry, statistical, and
composite/relational. Composite and relational marks are documented
syntax sugar over the primitives below
(e.g. [`mark_significance()`](https://zorrooz.github.io/plotit/reference/mark_significance.md)
≈
[`mark_rule()`](https://zorrooz.github.io/plotit/reference/mark_rule.md) +
[`mark_text()`](https://zorrooz.github.io/plotit/reference/mark_text.md)).

| Function | Engine | Description |
|:---|:---|:---|
| [`mark_point()`](https://zorrooz.github.io/plotit/reference/mark_point.md) | `geom_point()` | Scatter / bubble plots |
| [`mark_line()`](https://zorrooz.github.io/plotit/reference/mark_line.md) | `geom_line()` | Lines and trends |
| [`mark_area()`](https://zorrooz.github.io/plotit/reference/mark_area.md) | `geom_area()` / `geom_ribbon()` | Filled area charts |
| [`mark_bar()`](https://zorrooz.github.io/plotit/reference/mark_bar.md) | `geom_bar()` / `geom_col()` | Bar charts |
| [`mark_rect()`](https://zorrooz.github.io/plotit/reference/mark_rect.md) | `geom_tile()` / `geom_rect()` | Heatmap cells / rectangles |
| [`mark_polygon()`](https://zorrooz.github.io/plotit/reference/mark_polygon.md) | `geom_polygon()` | Polygons / custom shapes |
| [`mark_text()`](https://zorrooz.github.io/plotit/reference/mark_text.md) | `geom_text()` / ggrepel | Text labels and annotations |
| [`mark_rule()`](https://zorrooz.github.io/plotit/reference/mark_rule.md) | `geom_hline/vline/abline/segment` | Reference lines and ranges |
| [`mark_path()`](https://zorrooz.github.io/plotit/reference/mark_path.md) | `geom_path()` | Paths and trajectories |
| [`mark_histogram()`](https://zorrooz.github.io/plotit/reference/mark_histogram.md) | `geom_histogram()` | Histograms |
| [`mark_density()`](https://zorrooz.github.io/plotit/reference/mark_density.md) | `geom_density()` | 1D kernel density curves |
| [`mark_boxplot()`](https://zorrooz.github.io/plotit/reference/mark_boxplot.md) | `geom_boxplot()` | Box-and-whisker plots |
| [`mark_violin()`](https://zorrooz.github.io/plotit/reference/mark_violin.md) | `geom_violin()` | Violin plots |
| [`mark_map()`](https://zorrooz.github.io/plotit/reference/mark_map.md) | sf + `geom_sf()` | Geographic maps |
| [`mark_smooth()`](https://zorrooz.github.io/plotit/reference/mark_smooth.md) | `geom_smooth()` | Regression fits with confidence bands |
| [`mark_hex()`](https://zorrooz.github.io/plotit/reference/mark_hex.md) | `geom_hex()` | 2D hexagonal binning |
| [`mark_density_2d()`](https://zorrooz.github.io/plotit/reference/mark_density_2d.md) | `geom_density_2d()` | 2D density contours |
| [`mark_corr()`](https://zorrooz.github.io/plotit/reference/mark_corr.md) | [`transform_corr()`](https://zorrooz.github.io/plotit/reference/transform_corr.md) + `geom_tile()` | Correlation heatmap |
| [`mark_errorbar()`](https://zorrooz.github.io/plotit/reference/mark_errorbar.md) | `geom_errorbar()` / `-h` | Error bars |
| [`mark_significance()`](https://zorrooz.github.io/plotit/reference/mark_significance.md) | sugar: rule + text | Significance brackets |
| [`mark_lollipop()`](https://zorrooz.github.io/plotit/reference/mark_lollipop.md) | sugar: point + stem | Lollipop charts |
| [`mark_dumbbell()`](https://zorrooz.github.io/plotit/reference/mark_dumbbell.md) | sugar: two points + stem | Dumbbell comparison charts |
| [`mark_beeswarm()`](https://zorrooz.github.io/plotit/reference/mark_beeswarm.md) | ggbeeswarm | Beeswarm scatter (collision detection) |
| [`mark_sankey()`](https://zorrooz.github.io/plotit/reference/mark_sankey.md) | [`layout_sankey()`](https://zorrooz.github.io/plotit/reference/layout_sankey.md) sugar | Sankey flow diagrams |
| [`mark_treemap()`](https://zorrooz.github.io/plotit/reference/mark_treemap.md) | treemapify | Treemaps |
| [`mark_network()`](https://zorrooz.github.io/plotit/reference/mark_network.md) | `layout_force()/circle()` sugar | Force-directed network graphs |
| [`mark_chord()`](https://zorrooz.github.io/plotit/reference/mark_chord.md) | [`layout_chord()`](https://zorrooz.github.io/plotit/reference/layout_chord.md) sugar | Chord diagrams |

### Relational data — `as_graph()` + `layout_*()`

Relational data follows a Vega-style transform model: normalise your
data into a graph, bake layout coordinates into it, then render any
sub-table via `data = ~table`.

| Function | Description |
|:---|:---|
| [`as_graph()`](https://zorrooz.github.io/plotit/reference/as_graph.md) | Normalise edge tables, matrices, hclust, or hierarchical data into a graph object |
| [`layout_force()`](https://zorrooz.github.io/plotit/reference/layout_force.md) | Force-directed node placement (seeded, reproducible) |
| [`layout_circle()`](https://zorrooz.github.io/plotit/reference/layout_circle.md) | Circular node placement |
| [`layout_tree()`](https://zorrooz.github.io/plotit/reference/layout_tree.md) | Tree layout |
| [`layout_dendrogram()`](https://zorrooz.github.io/plotit/reference/layout_dendrogram.md) | Dendrogram from `hclust` |
| [`layout_chord()`](https://zorrooz.github.io/plotit/reference/layout_chord.md) | Chord sector layout (arcs + ribbons) |
| [`layout_sankey()`](https://zorrooz.github.io/plotit/reference/layout_sankey.md) | Deterministic layered sankey layout (nodes/edges/ribbons) |
| [`layout_treemap()`](https://zorrooz.github.io/plotit/reference/layout_treemap.md) | Squarified treemap layout |
| [`transform_corr()`](https://zorrooz.github.io/plotit/reference/transform_corr.md) | Correlation-matrix preprocessing for [`mark_corr()`](https://zorrooz.github.io/plotit/reference/mark_corr.md) |

``` r

edges <- data.frame(source = c("A", "A", "B"),
                    target = c("B", "C", "C"),
                    value  = c(3, 1, 2))
edges |>
  as_graph() |>
  plotit() |>
  layout_circle() |>
  mark_point(data = ~nodes) |>
  mark_rule(data = ~edges)
```

[`as_graph()`](https://zorrooz.github.io/plotit/reference/as_graph.md)
picks up `source`/`target`/`value` by column name (override via the
like-named arguments).

### `scale_*` — Data-to-visual mapping

| Function | Aesthetic |
|:---|:---|
| [`scale_color()`](https://zorrooz.github.io/plotit/reference/scale_color.md) | colour |
| [`scale_fill()`](https://zorrooz.github.io/plotit/reference/scale_fill.md) | fill |
| [`scale_size()`](https://zorrooz.github.io/plotit/reference/scale_size.md) | size |
| [`scale_alpha()`](https://zorrooz.github.io/plotit/reference/scale_alpha.md) | alpha |
| [`scale_shape()`](https://zorrooz.github.io/plotit/reference/scale_shape.md) | shape |
| [`scale_linetype()`](https://zorrooz.github.io/plotit/reference/scale_linetype.md) | linetype |
| [`scale_x()`](https://zorrooz.github.io/plotit/reference/scale_x.md) | x-axis |
| [`scale_y()`](https://zorrooz.github.io/plotit/reference/scale_y.md) | y-axis |

### `label_*` — Text labels

| Function | Scope |
|:---|:---|
| [`label_title()`](https://zorrooz.github.io/plotit/reference/label_title.md) | Main title |
| [`label_subtitle()`](https://zorrooz.github.io/plotit/reference/label_subtitle.md) | Subtitle |
| [`label_caption()`](https://zorrooz.github.io/plotit/reference/label_caption.md) | Caption |
| [`label_axis()`](https://zorrooz.github.io/plotit/reference/label_axis.md) | Axis titles |
| [`label_legend()`](https://zorrooz.github.io/plotit/reference/label_legend.md) | Legend titles |

### `project_*` — Coordinate systems

| Function | Description |
|:---|:---|
| [`project_cartesian()`](https://zorrooz.github.io/plotit/reference/project_cartesian.md) | Cartesian (zoom, flip, ratio, transform) |
| [`project_polar()`](https://zorrooz.github.io/plotit/reference/project_polar.md) | Polar |
| [`project_parallel()`](https://zorrooz.github.io/plotit/reference/project_parallel.md) | Parallel coordinates |
| [`project_map()`](https://zorrooz.github.io/plotit/reference/project_map.md) | Geographic projection |

### `split_*` — Facets

| Function | Description |
|:---|:---|
| [`split_wrap()`](https://zorrooz.github.io/plotit/reference/split_wrap.md) | Wrapped facets |
| [`split_grid()`](https://zorrooz.github.io/plotit/reference/split_grid.md) | Grid facets |

### `compose_*` — Multi-plot assembly

| Function | Description |
|:---|:---|
| [`compose_grid()`](https://zorrooz.github.io/plotit/reference/compose_grid.md) | Grid arrangement |
| [`compose_inset()`](https://zorrooz.github.io/plotit/reference/compose_inset.md) | Floating inset overlay |
| [`compose_marginal()`](https://zorrooz.github.io/plotit/reference/compose_marginal.md) | Scatter with marginal distributions |

### Theme

| Function | Description |
|:---|:---|
| [`style()`](https://zorrooz.github.io/plotit/reference/style.md) | Apply a ggplot2 theme |
| [`style_default()`](https://zorrooz.github.io/plotit/reference/style_default.md) | Restore plotit’s built-in theme |

### Export

| Function | Description |
|:---|:---|
| [`export()`](https://zorrooz.github.io/plotit/reference/export.md) | Render to file (pdf, png, svg, …) |

### Custom extensions

| Function | Description |
|:---|:---|
| [`make_mark()`](https://zorrooz.github.io/plotit/reference/make_mark.md) | Register a custom mark from any ggplot2 geom |
| [`make_theme()`](https://zorrooz.github.io/plotit/reference/make_theme.md) | Create a reusable theme preset function |

## Documentation

Full documentation is available at
[zorrooz.github.io/plotit](https://zorrooz.github.io/plotit/).

## Contributing

plotit is in early development. Bug reports, feature requests, and pull
requests are welcome on [GitHub
Issues](https://github.com/zorrooz/plotit/issues).

## License

plotit is licensed under the MIT License. See
[LICENSE](https://zorrooz.github.io/plotit/LICENSE) for details.
