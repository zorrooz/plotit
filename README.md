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
  style(ggplot2::theme_minimal(base_size = 14)) |>
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
```

## The pipeline

Every plotit chart follows a consistent pipeline:

```
data |> plotit(encode(...)) |> mark_*() |> scale_*() |> label_*() |> project_*() |> split_*() |> style() |> export()
```

| Step | Verb | Role |
|:---|:---|:---|
| 1. Initialise | `plotit()` + `encode()` | Bind data and aesthetic mappings |
| 2. Layer | `mark_*()` | Add geometric layers (points, lines, bars, …) |
| 3. Scale | `scale_*()` | Control how data maps to visual properties |
| 4. Label | `label_*()` | Set titles, axis labels, legend titles |
| 5. Coordinate | `project_*()` | Choose coordinate system (cartesian, polar, map) |
| 6. Facet | `split_*()` | Split into small multiples |
| 7. Theme | `style()` | Apply a complete theme |
| 8. Export | `export()` | Render to file |

Multi-plot compositions follow their own outermost pipeline:

```
compose_*(p1, p2, ...) |> label_*() |> style() |> export()
```

## Function families

### `mark_*` — Geometric layers

| Function | ggplot2 | Description |
|:---|:---|:---|
| `mark_point()` | `geom_point()` | Scatter plots |
| `mark_line()` | `geom_line()` | Lines and trends |
| `mark_bar()` | `geom_bar()` / `geom_col()` | Bar charts |
| `mark_boxplot()` | `geom_boxplot()` | Box-and-whisker plots |
| `mark_histogram()` | `geom_histogram()` | Histograms |
| `mark_density()` | `geom_density()` | Kernel density estimates |

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

### Theme & export

| Function | Description |
|:---|:---|
| `style()` | Apply a ggplot2 theme |
| `style_default()` | Restore plotit's built-in theme |
| `export()` | Render to file (pdf, png, svg, …) |

## Documentation

Full documentation is available at [zorrooz.github.io/plotit](https://zorrooz.github.io/plotit/).

## Contributing

plotit is in early development. Bug reports, feature requests, and pull
requests are welcome on [GitHub Issues](https://github.com/zorrooz/plotit/issues).

## License

plotit is licensed under the MIT License. See [LICENSE](LICENSE) for details.
