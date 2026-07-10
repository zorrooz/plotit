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
  style(ggplot2::theme_minimal(base_size = 14)) |>
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
```

## The pipeline

Every plotit chart follows a consistent pipeline:

    data |> plotit(encode(...)) |> mark_*() |> scale_*() |> label_*() |> project_*() |> split_*() |> style() |> export()

| Step | Verb | Role |
|:---|:---|:---|
| 1\. Initialise | [`plotit()`](https://zorrooz.github.io/plotit/reference/plotit.md) + [`encode()`](https://zorrooz.github.io/plotit/reference/encode.md) | Bind data and aesthetic mappings |
| 2\. Layer | `mark_*()` | Add geometric layers (points, lines, bars, …) |
| 3\. Scale | `scale_*()` | Control how data maps to visual properties |
| 4\. Label | `label_*()` | Set titles, axis labels, legend titles |
| 5\. Coordinate | `project_*()` | Choose coordinate system (cartesian, polar, map) |
| 6\. Facet | `split_*()` | Split into small multiples |
| 7\. Theme | [`style()`](https://zorrooz.github.io/plotit/reference/style.md) | Apply a complete theme |
| 8\. Export | [`export()`](https://zorrooz.github.io/plotit/reference/export.md) | Render to file |

Multi-plot compositions follow their own outermost pipeline:

    compose_*(p1, p2, ...) |> label_*() |> style() |> export()

## Function families

### `mark_*` — Geometric layers

| Function | ggplot2 | Description |
|:---|:---|:---|
| [`mark_point()`](https://zorrooz.github.io/plotit/reference/mark_point.md) | `geom_point()` | Scatter plots |
| [`mark_line()`](https://zorrooz.github.io/plotit/reference/mark_line.md) | `geom_line()` | Lines and trends |
| [`mark_bar()`](https://zorrooz.github.io/plotit/reference/mark_bar.md) | `geom_bar()` / `geom_col()` | Bar charts |
| [`mark_boxplot()`](https://zorrooz.github.io/plotit/reference/mark_boxplot.md) | `geom_boxplot()` | Box-and-whisker plots |
| [`mark_histogram()`](https://zorrooz.github.io/plotit/reference/mark_histogram.md) | `geom_histogram()` | Histograms |
| [`mark_density()`](https://zorrooz.github.io/plotit/reference/mark_density.md) | `geom_density()` | Kernel density estimates |

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

### Theme & export

| Function | Description |
|:---|:---|
| [`style()`](https://zorrooz.github.io/plotit/reference/style.md) | Apply a ggplot2 theme |
| [`style_default()`](https://zorrooz.github.io/plotit/reference/style_default.md) | Restore plotit’s built-in theme |
| [`export()`](https://zorrooz.github.io/plotit/reference/export.md) | Render to file (pdf, png, svg, …) |

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
