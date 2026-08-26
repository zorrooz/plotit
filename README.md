# plotit

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/zorrooz/plotit/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/zorrooz/plotit/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/zorrooz/plotit/actions/workflows/pkgdown.yaml/badge.svg)](https://zorrooz.github.io/plotit/)
[![lint](https://github.com/zorrooz/plotit/actions/workflows/lint.yaml/badge.svg)](https://github.com/zorrooz/plotit/actions/workflows/lint.yaml)
<!-- badges: end -->

<p align="center"><a href="https://zorrooz.github.io/plotit/README_ZH.html">简体中文</a> | <b>English</b></p>

> ⚠️ **Early development stage.**  
> plotit is under active, pre-release development. Breaking changes are
> **extremely likely** with every update. The API is incomplete, many
> planned features are missing, and bugs are expected. Do not use in
> production. Use at your own risk. Feedback and contributions are welcome.

---

## Overview

**plotit** is a declarative, pipeline-first R package for creating
publication-quality visualisations. Built on [ggplot2](https://ggplot2.tidyverse.org),
it replaces `+`-based layering with a unified **verb-prefix API** powered
by the native pipe (`|>`). Sensible defaults eliminate boilerplate —
colour, theme, and sizing work out of the box.

```r
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

```r
# install.packages("pak")
pak::pak("zorrooz/plotit")
```

## Quick start

```r
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

```
data |> plotit(encode(...)) |> mark_*() |> scale_*() |> layout_*() |> split_*() |> project_*() |> label_*() |> style() |> export()
```

| Step | Verb | Role |
|:---|:---|:---|
| 1. Initialise | `plotit()` + `encode()` | Bind data and aesthetic mappings |
| 2. Layer | `mark_*()` | Add geometric layers (points, lines, bars, …) |
| 3. Scale | `scale_*()` | Control how data maps to visual properties |
| 4. Layout | `layout_*()` | Compute relational layouts (optional; sankey, network, chord, treemap) |
| 5. Facet | `split_*()` | Split into small multiples |
| 6. Coordinate | `project_*()` | Choose coordinate system (cartesian, polar, map) |
| 7. Label | `label_*()` | Set titles, axis labels, legend titles |
| 8. Theme | `style()` | Apply a complete theme |
| 9. Export | `export()` | Render to file |

Multi-plot compositions follow their own outermost pipeline:

```
compose_*(p1, p2, ...) |> label_*() |> style() |> export()
```

## Function families

### `mark_*` — Geometric layers

27 marks across three tiers: basic geometry, statistical, and composite/relational.
Composite and relational marks are documented syntax sugar over the primitives
below (e.g. `mark_significance()` ≈ `mark_rule()` + `mark_text()`).

| Function | Engine | Description |
|:---|:---|:---|
| `mark_point()` | `geom_point()` | Scatter / bubble plots |
| `mark_line()` | `geom_line()` | Lines and trends |
| `mark_area()` | `geom_area()` / `geom_ribbon()` | Filled area charts |
| `mark_bar()` | `geom_bar()` / `geom_col()` | Bar charts |
| `mark_rect()` | `geom_tile()` / `geom_rect()` | Heatmap cells / rectangles |
| `mark_polygon()` | `geom_polygon()` | Polygons / custom shapes |
| `mark_text()` | `geom_text()` / ggrepel | Text labels and annotations |
| `mark_rule()` | `geom_hline/vline/abline/segment` | Reference lines and ranges |
| `mark_path()` | `geom_path()` | Paths and trajectories |
| `mark_histogram()` | `geom_histogram()` | Histograms |
| `mark_density()` | `geom_density()` | 1D kernel density curves |
| `mark_boxplot()` | `geom_boxplot()` | Box-and-whisker plots |
| `mark_violin()` | `geom_violin()` | Violin plots |
| `mark_map()` | sf + `geom_sf()` | Geographic maps |
| `mark_smooth()` | `geom_smooth()` | Regression fits with confidence bands |
| `mark_hex()` | `geom_hex()` | 2D hexagonal binning |
| `mark_density_2d()` | `geom_density_2d()` | 2D density contours |
| `mark_corr()` | internal corr transform + `geom_tile()` | Correlation heatmap |
| `mark_errorbar()` | `geom_errorbar()` / `-h` | Error bars |
| `mark_significance()` | sugar: rule + text | Significance brackets |
| `mark_lollipop()` | sugar: point + stem | Lollipop charts |
| `mark_dumbbell()` | sugar: two points + stem | Dumbbell comparison charts |
| `mark_beeswarm()` | ggbeeswarm | Beeswarm scatter (collision detection) |
| `mark_sankey()` | `layout_sankey()` sugar | Sankey flow diagrams |
| `mark_treemap()` | `layout_treemap()` sugar | Treemaps |
| `mark_network()` | `layout_force()/circle()` sugar | Force-directed network graphs |
| `mark_chord()` | `layout_chord()` sugar | Chord diagrams |

### Relational data — `as_graph()` + `layout_*()`

Relational data follows a Vega-style transform model: normalise your data into
a graph, bake layout coordinates into it, then render any sub-table via
`data = ~table`.

| Function | Description |
|:---|:---|
| `as_graph()` | Normalise edge tables, matrices, hclust, or hierarchical data into a graph object |
| `layout_force()` | Force-directed node placement (seeded, reproducible) |
| `layout_circle()` | Circular node placement |
| `layout_tree()` | Tree layout |
| `layout_dendrogram()` | Dendrogram from `hclust` |
| `layout_chord()` | Chord sector layout (arcs + ribbons) |
| `layout_sankey()` | Deterministic layered sankey layout (nodes/edges/ribbons) |
| `layout_treemap()` | Squarified treemap layout |

```r
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

`as_graph()` picks up `source`/`target`/`value` by column name
(override via the like-named arguments).

### `scale_*` — Data-to-visual mapping

| Function | Aesthetic |
|:---|:---|
| `scale_color()` | colour |
| `scale_fill()` | fill |
| `scale_size()` | size |
| `scale_alpha()` | alpha |
| `scale_shape()` | shape |
| `scale_linetype()` | linetype |
| `scale_x()` | x-axis |
| `scale_y()` | y-axis |

### `label_*` — Text labels

| Function | Scope |
|:---|:---|
| `label_title()` | Main title |
| `label_subtitle()` | Subtitle |
| `label_caption()` | Caption |
| `label_axis()` | Axis titles |
| `label_legend()` | Legend titles |

### `project_*` — Coordinate systems

| Function | Description |
|:---|:---|
| `project_cartesian()` | Cartesian (zoom, flip, ratio, transform) |
| `project_polar()` | Polar |
| `project_parallel()` | Parallel coordinates |
| `project_map()` | Geographic projection |

### `split_*` — Facets

| Function | Description |
|:---|:---|
| `split_wrap()` | Wrapped facets |
| `split_grid()` | Grid facets |

### `compose_*` — Multi-plot assembly

| Function | Description |
|:---|:---|
| `compose_grid()` | Grid arrangement |
| `compose_inset()` | Floating inset overlay |
| `compose_marginal()` | Scatter with marginal distributions |

### Theme

| Function | Description |
|:---|:---|
| `style()` | Apply a ggplot2 theme (`style(p)` restores the plotit default) |

### Export

| Function | Description |
|:---|:---|
| `export()` | Render to file (pdf, png, svg, …) |

### Custom extensions

| Function | Description |
|:---|:---|
| `make_mark()` | Register a custom mark from any ggplot2 geom |
| `make_theme()` | Create a reusable theme preset function |

## Documentation

Full documentation is available at [zorrooz.github.io/plotit](https://zorrooz.github.io/plotit/).

## Contributing

plotit is in early development. Bug reports, feature requests, and pull
requests are welcome on [GitHub Issues](https://github.com/zorrooz/plotit/issues).

## License

plotit is licensed under the MIT License. See [LICENSE](LICENSE) for details.
