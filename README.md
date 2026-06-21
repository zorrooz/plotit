# plotit

[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

<p align="center"><a href="README_ZH.md">简体中文</a> · <b>English</b></p>

---

**plotit** is a declarative, pipeline-friendly plotting package built on
[ggplot2](https://ggplot2.tidyverse.org). It provides a unified **verb-prefix
API** that turns data into publication-ready charts in a single pipeline —
sensible defaults, zero boilerplate.

```r
library(plotit)

iris |>
 plotit(encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
 mark_point(size = 2, alpha = 0.7) |>
 scale_color(range = "viridis") |>
 label_title("Iris Sepal Dimensions") |>
 label_axis(text = "Sepal Width", aes = "x") |>
 label_axis(text = "Sepal Length", aes = "y") |>
 style(ggplot2::theme_minimal(base_size = 14)) |>
 export("iris_plot.pdf")
```

<details>
<summary>vs base ggplot2</summary>

```r
# plotit — 4 lines
iris |>
 plotit(encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
 mark_point(size = 2, alpha = 0.7) |>
 scale_color(range = "viridis") |>
 label_title("Iris Sepal Dimensions")

# base ggplot2 — 3 lines
ggplot(iris, aes(x = Sepal.Width, y = Sepal.Length, colour = Species)) +
 geom_point(size = 2, alpha = 0.7) +
 scale_colour_viridis_d() +
 labs(title = "Iris Sepal Dimensions")
```
</details>

---

## Installation

```r
# install.packages("pak")
pak::pak("zorrooz/plotit")
```

---

## Usage

### Pipeline pattern

Every plotit pipeline follows the same grammar:

```
data |> plotit(encode(...)) |> mark_*() |> scale_*() |> label_*() |> style() |> export()
```

| Step | Function | Job |
|:---|:---|:---|
| 1. Create | `plotit()` | Initialise the plot with data & aesthetic mappings |
| 2. Layer | `mark_*()` | Add geometric layers |
| 3. Scale | `scale_*()` | Control data-to-visual mapping |
| 4. Label | `label_*()` | Set titles, axis labels, legend titles |
| 5. Theme | `style()` | Apply a ggplot2 theme |
| 6. Export | `export()` | Render to file |

### Function families

| Family | Prefix | Purpose | Examples |
|:---|:---|:---|:---|
| Layer | `mark_*` | Geometric layers | `mark_point()`, `mark_line()`, `mark_bar()`, `mark_boxplot()`, `mark_histogram()`, `mark_density()` |
| Compose | `compose_*` | Multi-panel layouts | `compose_grid()`, `compose_inset()`, `compose_marginal()` |
| Scale | `scale_*` | Data → visual mapping | `scale_x(trans = "log")`, `scale_color(range = "viridis")` |
| Label | `label_*` | Titles & labels | `label_title("Title")`, `label_axis("X", aes = "x")` |
| Project | `project_*` | Coordinate systems | `project_cartesian(flip = TRUE)`, `project_polar()` |
| Split | `split_*` | Facet layouts | `split_wrap(Species)`, `split_grid(rows = vars(cyl))` |
| Style | `style()` | Theme | `style(theme_minimal(base_size = 14))` |
| Export | `export()` | Output to file | `export("plot.pdf", dpi = 300)` |

---

## `mark_*` — Geometric Layers

Six mark functions, unified signature (`mapping`, `data`, `position`, `rasterize`, `...`).

| Function | ggplot2 | Use for |
|:---|:---|:---|
| `mark_point()` | `geom_point()` | Scatter plots |
| `mark_line()` | `geom_line()` | Lines, trends, time series |
| `mark_bar()` | `geom_bar()` / `geom_col()` | Bar charts |
| `mark_boxplot()` | `geom_boxplot()` | Distributions by group |
| `mark_histogram()` | `geom_histogram()` | Histograms |
| `mark_density()` | `geom_density()` | Density curves |

---

## `compose_*` — Multi-Panel Layouts

Assemble multiple plots into compound layouts. All return a `plotit_composite`
that pipes seamlessly into `label_*()` / `style()` / `export()`.

| Function | Description | Key params |
|:---|:---|:---|
| `compose_grid()` | Grid arrangement | `...`, `ncol`, `nrow`, `widths`, `heights`, `guides`, `axes`, `tag_levels` |
| `compose_inset()` | Floating overlay | `base`, `inset`, `left`, `bottom`, `right`, `top` |
| `compose_marginal()` | Scatter + marginal distributions | `main`, `top`, `right`, `widths`, `heights` |

```r
# 2×2 dashboard with auto-tags
compose_grid(p1, p2, p3, p4, ncol = 2, tag_levels = "A") |>
 label_title("Dashboard") |>
 export("dashboard.png")

# Scatter plot with marginal histograms
compose_marginal(main, top_hist, right_hist) |>
 label_title("Iris") |>
 export("marginal.png")
```

---

## `scale_*` — Data-to-Visual Mapping

Eight functions with identical parameters — only the `trans` default varies.

| Function | Aesthetic | `trans` default |
|:---|:---|:---|
| `scale_color()` | colour | `NULL` (auto-detect) |
| `scale_fill()` | fill | `NULL` (auto-detect) |
| `scale_size()` | size | `NULL` (auto-detect) |
| `scale_alpha()` | alpha | `NULL` (auto-detect) |
| `scale_shape()` | shape | `"discrete"` |
| `scale_linetype()` | linetype | `"discrete"` |
| `scale_x()` | x | `"identity"` |
| `scale_y()` | y | `"identity"` |

All accept `name`, `limits`, `range`, `breaks`, `labels`, `...`.

| Parameter | Answers | Example |
|:---|:---|:---|
| `range` | Map to **what** visual values? | `"viridis"`, `c("blue","red")` |
| `trans` | **How** to transform the data? | `"log"`, `"reverse"`, `"binned"` |
| `limits` | What data range to include? | `c(0, 100)` |
| `breaks` | Where to place ticks / keys? | `c(2, 4, 6)` |
| `labels` | What to call them? | `c("low", "mid", "high")` |
| `name` | What to call the scale? | `"Engine Size"` |

### `range` quick reference

| Aesthetic | `range = NULL` | `range = "name"` | `range = c(a, b)` |
|:---|:---|:---|:---|
| colour, fill | auto (discrete→hue, continuous→viridis) | `"viridis"`, `"brewer"`, `"grey"`, `"hue"` | `c("blue", "red")` |
| size | `c(1, 6)` | — | `c(0.5, 10)` |
| alpha | `c(0.1, 1)` | — | `c(0, 0.8)` |
| shape | default shapes | — | `c(1, 16)` |
| linetype | default linetypes | — | `c("solid", "dashed")` |
| x, y | data-driven | — | `c(0, 100)` |

### `trans` quick reference

| `trans` | Effect | Works on |
|:---|:---|:---|
| `"identity"` | Linear (default) | All |
| `"log"`, `"log10"`, `"log2"` | Logarithmic | x, y |
| `"sqrt"` | Square-root | x, y |
| `"reverse"` | Reverse order | All |
| `"discrete"` | Treat as categories | All |
| `"binned"` | Bin, then discretize | All except shape, linetype |

---

## `label_*` — Text Labels

Five functions with a three-parameter protocol:

| Call | Behaviour |
|:---|:---|
| `label_*(text = "str")` | Set custom text |
| `label_*(hide = TRUE)` | Remove element and its space |
| `label_*(reset = TRUE)` | Restore variable name (axis/legend) or remove (title) |
| _(not called)_ | Preserve current state |

| Function | Scope |
|:---|:---|
| `label_title()` | Main title |
| `label_subtitle()` | Subtitle |
| `label_caption()` | Caption |
| `label_axis()` | Axis titles — `aes = "x"` or `"y"` (required) |
| `label_legend()` | Legend titles — `aes = "colour"`, `"fill"`, … |

---

## `project_*` — Coordinate Systems

| Function | Description | Key params |
|:---|:---|:---|
| `project_cartesian()` | Cartesian (zoom, flip, fixed ratio, transform) | `xlim`, `ylim`, `expand`, `flip`, `fixed`, `coord_trans`, `clip` |
| `project_polar()` | Polar | `theta`, `start`, `direction`, `clip` |
| `project_parallel()` | Parallel coordinates | `columns`, `group`, `scale`, `alpha`, `size` |
| `project_map()` | Geographic projection | `projection`, `xlim`, `ylim`, `clip` |

## `split_*` — Facets

| Function | Description | Key params |
|:---|:---|:---|
| `split_wrap()` | Wrapped facets | `...` (variables), `ncol`, `nrow`, `scales` |
| `split_grid()` | Grid facets | `rows`, `cols`, `scales`, `space` |

## `style()` & `export()`

| Function | Description | Key params |
|:---|:---|:---|
| `style()` | Apply ggplot2 theme | `...`, `base_size`, `base_family`, `base_theme` |
| `export()` | Render to file | `filename`, `width`, `height`, `dpi`, `device` |
