# plotit

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

> [中文版本](#chinese)

## Overview

plotit is a **declarative, pipeline-friendly plotting package** built on top of
[ggplot2](https://ggplot2.tidyverse.org). It provides a simplified, consistent
verb-prefix API (`mark_*`, `scale_*`, `label_*`, …) that makes creating
publication-ready visualizations fast and intuitive — sensible defaults,
no boilerplate.

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
encode() → plotit() → mark_*() → scale_*() → label_*() → style() → export()
```

| Step | Function | Purpose |
|------|----------|---------|
| 1. Map | `encode()` | Declare aesthetic mappings (`x`, `y`, `colour`, `fill`, …) |
| 2. Create | `plotit()` | Initialize the plot object with data, defaults, and metadata |
| 3. Layer | `mark_*()` | Add geometric layers (points, lines, bars, boxplots, …) |
| 4. Scale | `scale_*()` | Control data-to-visual mapping (transformations, colour schemes, limits) |
| 5. Label | `label_*()` | Set titles, axis labels, and legend titles |
| 6. Theme | `style()` | Apply a ggplot2 theme and tweak details |
| 7. Export | `export()` | Render to file (PDF, PNG, SVG, …) |

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

### Mark types

Eight geometric layers with a unified interface:

| Function | ggplot2 equivalent | Description |
|----------|-------------------|-------------|
| `mark_point()` | `geom_point()` | Scatter plot |
| `mark_line()` | `geom_line()` | Line / trend |
| `mark_bar()` | `geom_bar()` / `geom_col()` | Bar chart |
| `mark_boxplot()` | `geom_boxplot()` | Boxplot |

All `mark_*` functions share the same signature (`mapping`, `data`, `position`, …)
and automatically apply global dodge settings from `plotit()`.

### Scale functions

Eight scale functions, identical signature — only the `trans` default differs:

```r
scale_color(p, name, trans, limits, range, breaks, labels, ...)
scale_fill(p,  name, trans, limits, range, breaks, labels, ...)
scale_size(p,  name, trans, limits, range, breaks, labels, ...)
scale_alpha(p, name, trans, limits, range, breaks, labels, ...)
scale_shape(p,    name, trans = "discrete", limits, range, breaks, labels, ...)
scale_linetype(p, name, trans = "discrete", limits, range, breaks, labels, ...)
scale_x(p,        name, trans = "identity", limits, range, breaks, labels, ...)
scale_y(p,        name, trans = "identity", limits, range, breaks, labels, ...)
```

#### Colour schemes (`range`)

| `range` value | Description |
|---------------|-------------|
| `"viridis"` | Colourblind-friendly, perceptually uniform (default for continuous) |
| `"brewer"` | ColorBrewer qualitative palette |
| `"grey"` | Greyscale |
| `"hue"` | ggplot2 default hue wheel (default for discrete) |
| `c("blue", "red")` | Custom colour gradient or manual vector |

#### Transformations (`trans`)

| `trans` | Effect | Applicable scales |
|---------|--------|-------------------|
| `"identity"` | Linear mapping (default) | All |
| `"log"` / `"log10"` / `"log2"` | Logarithmic | x, y only |
| `"sqrt"` | Square-root | x, y only |
| `"reverse"` | Reverse order | All |
| `"discrete"` | Treat as categorical | All |
| `"binned"` | Bin continuous data | All except shape, linetype |

Invalid combinations (e.g., `scale_color(trans = "log")`) produce clear,
targeted error messages.

### Label functions

Three-parameter protocol (`text`, `hide`, `reset`):

```r
label_title(p, "My Title")             # Set
label_axis(p, hide = TRUE, aes = "x")  # Hide
label_axis(p, reset = TRUE, aes = "x") # Reset to variable name
```

| Function | Scope |
|----------|-------|
| `label_title()` | Main title |
| `label_subtitle()` | Subtitle |
| `label_caption()` | Caption / footnote |
| `label_axis()` | Axis titles (`aes = "x"` or `"y"`) |
| `label_legend()` | Legend titles (`aes = "colour"`, `"fill"`, …) |

Label functions take priority over `scale_*(name = …)`: the last one set wins.

### Coordinate systems & faceting

```r
# Coordinate systems
project_cartesian(p, xlim = c(0, 100), expand = FALSE)
project_flip(p)
project_polar(p)

# Faceting
split_wrap(p, Species, ncol = 3, scales = "free")
split_grid(p, rows = ggplot2::vars(Species))
```

### Theme & export

```r
# Apply a theme
style(p, ggplot2::theme_minimal(base_size = 14))
style(p, ggplot2::theme_bw(), plot.title = ggplot2::element_text(face = "bold"))

# Export to file (device auto-detected from extension)
export(p, "plot.pdf",  width = 8, height = 6, dpi = 300)
export(p, "plot.png",  width = 8, height = 6, dpi = 150)
export(p, "plot.svg")
```

## Design principles

- **Verb-prefix naming** — Every function family has a distinct prefix: `mark_*`,
  `scale_*`, `project_*`, `split_*`, `label_*`. You always know what a function does
  from its name.
- **Pipeline-native** — Every function returns the `plotit` object, so the entire
  plot is a single `|>` chain from data to file.
- **Sensible defaults** — Viridis colours, clean minimal theme, publication-ready
  sizing. You get a good-looking plot without configuration.
- **Transparent to ggplot2** — plotit is not a wrapper that hides ggplot2; it
  adds structure. `...` is passed directly to the underlying `geom_*()` and
  `scale_*()` calls. Use full ggplot2 power when you need it.
- **Validate early, delegate late** — Package-level constraints (unit validity,
  `trans` × aesthetic compatibility) are checked with structured errors via
  [cli](https://cli.r-lib.org). Generic ggplot2 parameter validation is left to
  ggplot2.

## Code of Conduct

Please note that the plotit project is released with a [Contributor Code of
Conduct](https://contributor-covenant.org/version/2/1/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.

---

## Chinese

### 概述

plotit 是一个基于 [ggplot2](https://ggplot2.tidyverse.org) 的**声明式、管道友好**的 R 绘图包。通过统一的动词前缀 API（`mark_*`、`scale_*`、`label_*` 等），只需一条管道即可从数据到出版级图表——预设美观主题，无需样板代码。

```r
library(plotit)

iris |>
  plotit(encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
  mark_point(size = 2, alpha = 0.7) |>
  scale_color(range = "viridis") |>
  label_title("Iris Sepal Dimensions") |>
  export("iris_plot.pdf")
```

### 安装

```r
# install.packages("pak")
pak::pak("zorrooz/plotit")
```

### 核心工作流

每一步都返回 `plotit` 对象，天然支持管道 `|>`：

```
encode() → plotit() → mark_*() → scale_*() → label_*() → style() → export()
```

### 函数族速览

| 函数族 | 职责 | 示例 |
|--------|------|------|
| `plotit()` | 初始化图表 | `plotit(mpg, encode(x = displ, y = hwy, colour = class))` |
| `mark_*` | 几何图层 | `mark_point()`, `mark_line()`, `mark_bar()`, `mark_boxplot()` |
| `scale_*` | 视觉映射 | `scale_x(trans = "log10")`, `scale_color(range = "viridis")` |
| `label_*` | 文本标签 | `label_title("标题")`, `label_axis(text = "X轴", aes = "x")` |
| `project_*` | 坐标系 | `project_flip()`, `project_polar()`, `project_cartesian()` |
| `split_*` | 分面 | `split_wrap(Species)`, `split_grid(rows = vars(cyl))` |
| `style()` | 主题 | `style(theme_minimal(base_size = 14))` |
| `export()` | 导出 | `export("plot.pdf", dpi = 300)` |

### 设计理念

- **动词前缀命名** — 看函数名就知道做什么：`mark_*` 添加图层，`scale_*` 控制映射，`label_*` 设置标签。
- **管道原生** — 每个函数都返回 `plotit` 对象，整个绘图流程是一条 `|>` 链。
- **开箱即美观** — Viridis 配色、简洁主题、合理的默认尺寸，无需手动调整即可用于报告和出版。
- **ggplot2 完全透明** — `...` 直接透传给底层 `geom_*()` 和 `scale_*()`，随时可以使用 ggplot2 的全部能力。
- **提前验证，延迟委托** — 包层自定义约束（单位合法性、`trans` × aesthetic 兼容性）主动报错；通用参数校验交由 ggplot2 自然处理。
By contributing to this project, you agree to abide by its terms.
