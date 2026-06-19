# plotit

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

> [English version](README.md)

## 概述

plotit 是一个基于 [ggplot2](https://ggplot2.tidyverse.org) 的**声明式、管道友好**的 R 绘图包。通过统一的动词前缀 API，只需一条管道即可从数据到出版级图表——预设美观主题，无需样板代码。

**为什么选择 plotit？** 不是 ggplot2 的替代品，而是其结构化封装。每个函数都有直接对应的 ggplot2 底层，`...` 透传确保灵活性不受限制。核心价值在于**管道原生 API**、**开箱即美观的默认值**（viridis 配色、出版级尺寸）和**统一的函数签名**（8 个 scale 共享 8 个参数）。

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

## 安装

```r
# install.packages("pak")
pak::pak("zorrooz/plotit")
```

## 核心工作流

每一步都返回 `plotit` 对象，天然支持管道 `|>`：

```
data |> plotit(encode(...)) |> mark_*() |> scale_*() |> label_*() |> style() |> export()
```

| 步骤 | 函数 | 说明 |
|------|------|------|
| 1. 创建 | `plotit()` | 初始化图表对象；通过 `encode()` 传入美学映射 |
| 2. 图层 | `mark_*()` | 添加几何图层（点、线、柱、箱线图等） |
| 3. 标度 | `scale_*()` | 控制数据到视觉属性的映射（变换、配色、范围） |
| 4. 标签 | `label_*()` | 设置标题、轴名、图例名 |
| 5. 主题 | `style()` | 应用 ggplot2 主题并进行微调 |
| 6. 导出 | `export()` | 渲染为文件（PDF、PNG、SVG 等） |

## 分步示例

```r
library(plotit)

# 1. 构造美学映射
mapping <- encode(
  x = displ,
  y = hwy,
  colour = class,
  size = cty
)

# 2. 初始化图表
p <- plotit(
  mpg,
  mapping,
  autofit   = FALSE,
  width     = 7,
  height    = 5,
  size_unit = "in"
)

# 3. 添加几何图层
p <- p |>
  mark_point(alpha = 0.7) |>
  mark_line(mapping = encode(x = displ, y = hwy), colour = "grey50")

# 4. 配置标度
p <- p |>
  scale_x(trans = "log10") |>
  scale_y(limits = c(10, 45)) |>
  scale_color(range = "viridis") |>
  scale_size(range = c(1, 8))

# 5. 设置标签
p <- p |>
  label_title("Fuel Economy by Engine Size") |>
  label_subtitle("Highway MPG vs. Displacement") |>
  label_caption("Source: EPA (mpg dataset)") |>
  label_axis(text = "Engine Displacement (L)", aes = "x") |>
  label_axis(text = "Highway MPG", aes = "y") |>
  label_legend(text = "Vehicle Class", aes = "colour")

# 6. 应用主题
p <- style(p, ggplot2::theme_minimal(base_size = 12))

# 7. 导出文件
export(p, "fuel_economy.pdf", dpi = 300)
```

## 函数族速览

| 函数族 | 前缀 | 职责 | 示例 |
|--------|------|------|------|
| 图层 | `mark_*` | 添加几何图层 | `mark_point()`, `mark_line()`, `mark_bar()`, `mark_boxplot()` |
| 标度 | `scale_*` | 数据 → 视觉映射 | `scale_x(trans = "log")`, `scale_color(range = "viridis")` |
| 标签 | `label_*` | 标题、轴名、图例名 | `label_title("标题")`, `label_axis("X轴", aes = "x")` |
| 坐标系 | `project_*` | 坐标变换 | `project_cartesian(flip=TRUE)`, `project_polar()`, `project_parallel()` |
| 分面 | `split_*` | 分面布局 | `split_wrap(Species)`, `split_grid(rows = vars(cyl))` |
| 主题 | `style()` | 应用 ggplot2 主题 | `style(theme_minimal(base_size = 14))` |
| 导出 | `export()` | 渲染为文件 | `export("plot.pdf", dpi = 300)` |

---

### `mark_*` — 几何图层

目前实现四个 mark 函数，共享统一签名（`mapping`、`data`、`position`、`rasterize`、`...`）。`plotit()` 设置的全局 dodge 自动注入，可通过显式 `position` 覆盖。

| 函数 | ggplot2 | 用途 |
|------|---------|------|
| `mark_point()` | `geom_point()` | 散点图 |
| `mark_line()` | `geom_line()` | 折线、趋势线、时间序列 |
| `mark_bar()` | `geom_bar()` / `geom_col()` | 柱状图 |
| `mark_boxplot()` | `geom_boxplot()` | 分组分布展示 |

---

### `scale_*` — 数据到视觉的映射

八个函数，参数签名完全一致。用 `range` 设定**输出成什么样子**，用 `trans` 设定**数据如何变换**。

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

| 参数 | 回答的问题 | 示例 |
|------|-----------|------|
| `range` | 映射到**什么**视觉值？ | `"viridis"`, `c("blue","red")`, `c(0, 100)` |
| `trans` | **如何**变换数据？ | `"log"`, `"reverse"`, `"binned"` |
| `limits` | 包含哪些数据范围？ | `c(0, 100)` |
| `breaks` | 刻度/图例键放在哪里？ | `c(2, 4, 6)` |
| `labels` | 刻度/图例键叫什么？ | `c("low", "mid", "high")` |
| `name` | 标度/坐标轴叫什么？ | `"Engine Size"` |

**`range` 速查：**

| 美学属性 | `range = NULL`（默认） | `range = "name"` | `range = c(a, b)` |
|----------|----------------------|-------------------|--------------------|
| colour, fill | 自动：离散→hue，连续→viridis | `"viridis"`, `"brewer"`, `"grey"`, `"hue"` | `c("blue", "red")` |
| size | `c(1, 6)` | — | `c(0.5, 10)` |
| alpha | `c(0.1, 1)` | — | `c(0, 0.8)` |
| shape | 默认形状集 | — | `c(1, 16)` |
| linetype | 默认线型集 | — | `c("solid", "dashed")` |
| x, y | 数据自身范围（无裁剪） | — | `c(0, 100)`（设 `limits` + `expand = c(0, 0)`） |

**`trans` 速查：**

| `trans` | 效果 | 适用范围 |
|---------|------|----------|
| `"identity"` | 线性（默认） | 全部 |
| `"log"`, `"log10"`, `"log2"` | 对数 | x, y |
| `"sqrt"` | 平方根 | x, y |
| `"reverse"` | 翻转顺序 | 全部 |
| `"discrete"` | 按分类处理 | 全部 |
| `"binned"` | 分箱后离散化 | 除 shape, linetype 外全部 |

无效组合如 `scale_color(trans = "log")` 会给出明确的中文错误提示，而非晦涩的底层报错。

---

### `label_*` — 文本标签

五个函数，三参数协议：

| 调用方式 | 行为 |
|----------|------|
| `label_*(text = "字符串")` | 设置自定义文本 |
| `label_*(hide = TRUE)` | 移除元素及占位空间 |
| `label_*(reset = TRUE)` | 恢复为变量名（轴/图例）或移除（标题） |
| 不调用 | 保持当前状态 |

| 函数 | 作用范围 |
|------|----------|
| `label_title()` | 主标题 |
| `label_subtitle()` | 副标题 |
| `label_caption()` | 脚注 |
| `label_axis()` | 轴标题 — 必须指定 `aes = "x"` 或 `"y"` |
| `label_legend()` | 图例标题 — `aes = "colour"`, `"fill"` 等 |

标签函数覆盖 `scale_*(name = …)`：后执行者胜。
`text = NULL` 是安全的空操作——**不会**覆盖已有标签。

---

### `project_*` — 坐标系 & `split_*` — 分面

```r
# 翻转、缩放、极坐标
project_cartesian(p, flip = TRUE)
project_cartesian(p, xlim = c(0, 100), expand = FALSE)
project_polar(p, start = pi / 2)

# wrap 和 grid 分面
split_wrap(p, Species, ncol = 3, scales = "free")
split_grid(p, rows = ggplot2::vars(Species), cols = ggplot2::vars(cyl))
```

### `style()` — 主题 & `export()` — 导出

```r
style(p, ggplot2::theme_minimal(base_size = 14))
style(p, ggplot2::theme_bw(), plot.title = ggplot2::element_text(face = "bold"))

export(p, "plot.pdf",  width = 8, height = 6, dpi = 300)
export(p, "plot.png",  dpi = 150)
export(p, "plot.svg")
```


