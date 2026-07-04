# plotit

[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

<p align="center"><a href="README_ZH.md">简体中文</a> | <b>English</b></p>

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

plotit has two levels of operation:

**Single-plot pipeline** — build one chart from data:

```
data |> plotit(encode(...)) |> mark_*() |> scale_*() |> label_*() |> project_*() |> split_*() |> style() |> export()
```

| Step | Function | Job |
|:---|:---|:---|
| 1. Create | `plotit()` | Initialise the plot with data & aesthetic mappings |
| 2. Layer | `mark_*()` | Add geometric layers |
| 3. Scale | `scale_*()` | Control data-to-visual mapping |
| 4. Label | `label_*()` | Set titles, axis labels, legend titles |
| 5. Coordinate | `project_*()` | Set coordinate system |
| 6. Facet | `split_*()` | Split into small multiples |
| 7. Theme | `style()` | Apply a ggplot2 theme |
| 8. Export | `export()` | Render to file |

**Multi-plot composition** — assemble multiple `plotit` objects into one layout (outermost layer):

```
compose_*(p1, p2, ...) |> label_*() |> style() |> export()
```

| Step | Function | Job |
|:---|:---|:---|
| 1. Assemble | `compose_*()` | Combine multiple `plotit` objects into a composite layout |
| 2. Label | `label_title()` / `label_subtitle()` / `label_caption()` | Set composite-level titles |
| 3. Theme | `style()` | Apply a ggplot2 theme to the composite |
| 4. Export | `export()` | Render the composite to file |

> **Key difference**: Single-plot functions (`mark_*`, `scale_*`, `project_*`, `split_*`, `label_axis`, `label_legend`) operate on **one `plotit` object with data**. `compose_*` operates on **multiple `plotit` objects** and returns a `plotit_composite` — it is the outermost layer, applied after individual plots are built.

### Function families

**Single-plot families** (inner layer):

| Family | Prefix | Purpose | Examples |
|:---|:---|:---|:---|
| Create | `plotit()` + `encode()` | Initialise plot with data & aesthetic mappings | `plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))` |
| Layer | `mark_*` | Geometric layers | `mark_point()`, `mark_line()`, `mark_bar()`, `mark_boxplot()`, `mark_histogram()`, `mark_density()` |
| Scale | `scale_*` | Data → visual mapping | `scale_x(trans = "log")`, `scale_color(range = "viridis")` |
| Label | `label_*` | Titles, axis & legend labels | `label_title("Title")`, `label_axis("X", aes = "x")`, `label_legend("Species", aes = "colour")` |
| Coordinate | `project_*` | Coordinate systems | `project_cartesian(flip = TRUE)`, `project_polar()` |
| Facet | `split_*` | Facet layouts | `split_wrap(Species)`, `split_grid(rows = vars(cyl))` |
| Theme | `style()` | Apply ggplot2 theme | `style(theme_minimal(base_size = 14))` |
| Export | `export()` | Render to file | `export("plot.pdf", dpi = 300)` |

**Multi-plot composition** (outermost layer — operates on `plotit` objects, not data):

| Family | Prefix | Purpose | Examples |
|:---|:---|:---|:---|
| Compose | `compose_*` | Assemble multiple `plotit` objects into one layout | `compose_grid()`, `compose_inset()`, `compose_marginal()` |

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

---

## `compose_*` — Multi-Plot Composition (Outermost Layer)

Assemble multiple `plotit` objects into compound layouts. Unlike single-plot
functions that operate on data, `compose_*` takes **already-built `plotit` objects**
as input and returns a `plotit_composite`. This is the **outermost layer** in
the plotit architecture — build individual plots first, then compose them together.

The returned composite pipes seamlessly into `label_title()` / `label_subtitle()` /
`label_caption()` / `style()` / `export()`.

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
