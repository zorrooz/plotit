# plotit

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

> [中文版本](README_ZH.md)

## Overview

plotit is a **declarative, pipeline-friendly plotting package** built on top of
[ggplot2](https://ggplot2.tidyverse.org). It provides a simplified, consistent
verb-prefix API that makes creating publication-ready visualizations fast and
intuitive — sensible defaults, no boilerplate.

**Why plotit?**  plotit is not a ggplot2 replacement — it is a structured layer
on top.  Every function maps directly to a ggplot2 counterpart, and `...`
passes through to the underlying `geom_*()` / `scale_*()` calls.  The value is
in the **pipeline-native API**, **sensible defaults** (viridis colours,
publication-ready sizing), and **unified signatures** (8 scale functions share
identical parameters).

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
# plotit
iris |>
  plotit(encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
  mark_point(size = 2, alpha = 0.7) |>
  scale_color(range = "viridis") |>
  label_title("Iris Sepal Dimensions")

# base ggplot2
ggplot(iris, aes(x = Sepal.Width, y = Sepal.Length, colour = Species)) +
  geom_point(size = 2, alpha = 0.7) +
  scale_colour_viridis_d() +
  labs(title = "Iris Sepal Dimensions")
```
</details>"}

## Installation

Install the development version from GitHub:

```r
# install.packages("pak")
pak::pak("zorrooz/plotit")
```

## Usage

### Core workflow

Every plotit pipeline follows the same pattern:

```
data |> plotit(encode(...)) |> mark_*() |> scale_*() |> label_*() |> style() |> export()
```

| Step | Function | Purpose |
|------|----------|---------|
| 1. Create | `plotit()` | Initialize the plot; pass aesthetic mappings via `encode()` |
| 2. Layer | `mark_*()` | Add geometric layers (points, lines, bars, boxplots, …) |
| 3. Scale | `scale_*()` | Control data-to-visual mapping (transformations, colour schemes, limits) |
| 4. Label | `label_*()` | Set titles, axis labels, and legend titles |
| 5. Theme | `style()` | Apply a ggplot2 theme and tweak details |
| 6. Export | `export()` | Render to file (PDF, PNG, SVG, …) |

### Step-by-step

```r
library(plotit)

# 1. Create aesthetic mappings
mapping <- encode(
  x = displ,
  y = hwy,
  colour = class,
  size = cty
)

# 2. Initialise the plot
p <- plotit(
  mpg,
  mapping,
  autofit  = FALSE,
  width    = 7,
  height   = 5,
  size_unit = "in"
)

# 3. Add geometric layers
p <- p |>
  mark_point(alpha = 0.7) |>
  mark_line(mapping = encode(x = displ, y = hwy), colour = "grey50")

# 4. Configure scales
p <- p |>
  scale_x(trans = "log10") |>
  scale_y(limits = c(10, 45)) |>
  scale_color(range = "viridis") |>
  scale_size(range = c(1, 8))

# 5. Set labels
p <- p |>
  label_title("Fuel Economy by Engine Size") |>
  label_subtitle("Highway MPG vs. Displacement") |>
  label_caption("Source: EPA (mpg dataset)") |>
  label_axis(text = "Engine Displacement (L)", aes = "x") |>
  label_axis(text = "Highway MPG", aes = "y") |>
  label_legend(text = "Vehicle Class", aes = "colour")

# 6. Apply a theme
p <- style(p, ggplot2::theme_minimal(base_size = 12))

# 7. Export
export(p, "fuel_economy.pdf", dpi = 300)
```

### Function family overview

| Family | Prefix | Purpose | Quick example |
|--------|--------|---------|---------------|
| Layer | `mark_*` | Add geometric layers | `mark_point()`, `mark_line()`, `mark_bar()`, `mark_boxplot()` |
| Scale | `scale_*` | Data → visual mapping | `scale_x(trans = "log")`, `scale_color(range = "viridis")` |
| Label | `label_*` | Titles, axis & legend labels | `label_title("Title")`, `label_axis("X", aes = "x")` |
| Project | `project_*` | Coordinate system | `project_cartesian(flip=TRUE)`, `project_polar()`, `project_parallel()` |
| Split | `split_*` | Facet layout | `split_wrap(Species)`, `split_grid(rows = vars(cyl))` |
| Theme | `style()` | Apply ggplot2 theme | `style(theme_minimal(base_size = 14))` |
| Export | `export()` | Render to file | `export("plot.pdf", dpi = 300)` |

---

### `mark_*` — Geometric layers

Four mark functions are currently implemented, sharing a unified signature
(`mapping`, `data`, `position`, `rasterize`, `...`). Global dodge from
`plotit()` is applied automatically unless overridden.

| Function | ggplot2 | Use for |
|----------|---------|---------|
| `mark_point()` | `geom_point()` | Scatter plots |
| `mark_line()` | `geom_line()` | Lines, trends, time series |
| `mark_bar()` | `geom_bar()` / `geom_col()` | Bar charts, histograms |
| `mark_boxplot()` | `geom_boxplot()` | Distributions by group |

---

### `scale_*` — Data-to-visual mapping

Eight functions with identical parameter signatures. Set **what the output
looks like** with `range`, **how the data is transformed** with `trans`.

```r
# All eight share the same parameters:
scale_color   (p, name, trans = NULL,       limits, range, breaks, labels, ...)
scale_fill    (p, name, trans = NULL,       limits, range, breaks, labels, ...)
scale_size    (p, name, trans = NULL,       limits, range, breaks, labels, ...)
scale_alpha   (p, name, trans = NULL,       limits, range, breaks, labels, ...)
scale_shape   (p, name, trans = "discrete", limits, range, breaks, labels, ...)
scale_linetype(p, name, trans = "discrete", limits, range, breaks, labels, ...)
scale_x       (p, name, trans = "identity", limits, range, breaks, labels, ...)
scale_y       (p, name, trans = "identity", limits, range, breaks, labels, ...)
```

| Parameter | Answers | Example |
|-----------|---------|---------|
| `range` | Map to **what** visual values? | `"viridis"`, `c("blue","red")`, `c(0, 100)` |
| `trans` | **How** to transform the data? | `"log"`, `"reverse"`, `"binned"` |
| `limits` | What data range to include? | `c(0, 100)` |
| `breaks` | Where to place ticks / keys? | `c(2, 4, 6)` |
| `labels` | What to call the ticks / keys? | `c("low", "mid", "high")` |
| `name` | What to call the scale / axis? | `"Engine Size"` |

**`range` quick reference:**

| Aesthetic | `range = NULL` (default) | `range = "name"` | `range = c(a, b)` |
|-----------|--------------------------|-------------------|--------------------|
| colour, fill | auto: discrete→hue, continuous→viridis | `"viridis"`, `"brewer"`, `"grey"`, `"hue"` | `c("blue", "red")` |
| size | `c(1, 6)` | — | `c(0.5, 10)` |
| alpha | `c(0.1, 1)` | — | `c(0, 0.8)` |
| shape | default shapes | — | `c(1, 16)` |
| linetype | default linetypes | — | `c("solid", "dashed")` |
| x, y | data-driven (no clipping) | — | `c(0, 100)` (sets `limits` + `expand = c(0, 0)`) |

**`trans` quick reference:**

| `trans` | Effect | Works on |
|---------|--------|----------|
| `"identity"` | Linear (default) | All |
| `"log"`, `"log10"`, `"log2"` | Logarithmic | x, y |
| `"sqrt"` | Square-root | x, y |
| `"reverse"` | Reverse order | All |
| `"discrete"` | Treat as categories | All |
| `"binned"` | Bin, then discretize | All except shape, linetype |

Invalid combos like `scale_color(trans = "log")` produce a clear error message
instead of a cryptic ggplot2 failure.

---

### `label_*` — Text labels

Five functions with a three-parameter protocol:

| Call | Behaviour |
|------|-----------|
| `label_*(text = "str")` | Set custom text |
| `label_*(hide = TRUE)` | Remove element and its space |
| `label_*(reset = TRUE)` | Restore variable name (axis/legend) or remove (title) |
| (not called) | Preserve current state |

| Function | Scope |
|----------|-------|
| `label_title()` | Main title |
| `label_subtitle()` | Subtitle |
| `label_caption()` | Caption |
| `label_axis()` | Axis titles — `aes = "x"` or `"y"` (required) |
| `label_legend()` | Legend titles — `aes = "colour"`, `"fill"`, … |

Label functions override `scale_*(name = …)`: the last one set wins.
`text = NULL` is a safe no-op — it will **not** overwrite an existing label.

---

### `project_*` — Coordinate systems & `split_*` — Facets

```r
# Flip, zoom, polar
project_cartesian(p, flip = TRUE)
project_cartesian(p, xlim = c(0, 100), expand = FALSE)
project_polar(p, start = pi / 2)

# Wrap and grid faceting
split_wrap(p, Species, ncol = 3, scales = "free")
split_grid(p, rows = ggplot2::vars(Species), cols = ggplot2::vars(cyl))
```

### `style()` — Themes & `export()` — Output

```r
style(p, ggplot2::theme_minimal(base_size = 14))
style(p, ggplot2::theme_bw(), plot.title = ggplot2::element_text(face = "bold"))

export(p, "plot.pdf",  width = 8, height = 6, dpi = 300)
export(p, "plot.png",  dpi = 150)
export(p, "plot.svg")
```


