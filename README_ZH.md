# plotit

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

> [English version](README.md)

## 概述

plotit 是一个基于 [ggplot2](https://ggplot2.tidyverse.org) 的**声明式、管道友好**的 R 绘图包。通过统一的动词前缀 API（`mark_*`、`scale_*`、`label_*` 等），只需一条管道即可从数据到出版级图表——预设美观主题，无需样板代码。

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
encode() → plotit() → mark_*() → scale_*() → label_*() → style() → export()
```

| 步骤 | 函数 | 说明 |
|------|------|------|
| 1. 映射 | `encode()` | 声明美学映射（`x`、`y`、`colour`、`fill` 等） |
| 2. 创建 | `plotit()` | 初始化图表对象，设置数据、尺寸、默认值 |
| 3. 图层 | `mark_*()` | 添加几何图层（点、线、柱、箱线图等） |
| 4. 标度 | `scale_*()` | 控制数据到视觉属性的映射（变换、配色、范围） |
| 5. 标签 | `label_*()` | 设置标题、轴名、图例名 |
| 6. 主题 | `style()` | 应用 ggplot2 主题并进行微调 |
| 7. 导出 | `export()` | 渲染为文件（PDF、PNG、SVG 等） |

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

### 几何图层 `mark_*`

| 函数 | ggplot2 对应 | 说明 |
|------|-------------|------|
| `mark_point()` | `geom_point()` | 散点图 |
| `mark_line()` | `geom_line()` | 折线 / 趋势线 |
| `mark_bar()` | `geom_bar()` / `geom_col()` | 柱状图 |
| `mark_boxplot()` | `geom_boxplot()` | 箱线图 |

### 标度函数 `scale_*`

八个标度函数共享完全相同的参数签名，仅 `trans` 默认值不同：

```r
scale_color(p,   name, trans, limits, range, breaks, labels, ...)
scale_fill(p,    name, trans, limits, range, breaks, labels, ...)
scale_size(p,    name, trans, limits, range, breaks, labels, ...)
scale_alpha(p,   name, trans, limits, range, breaks, labels, ...)
scale_shape(p,      name, trans = "discrete", limits, range, breaks, labels, ...)
scale_linetype(p,   name, trans = "discrete", limits, range, breaks, labels, ...)
scale_x(p,          name, trans = "identity", limits, range, breaks, labels, ...)
scale_y(p,          name, trans = "identity", limits, range, breaks, labels, ...)
```

#### 配色方案 (`range`)

| `range` 值 | 说明 |
|------------|------|
| `"viridis"` | 色盲友好，感知均匀（连续变量默认） |
| `"brewer"` | ColorBrewer 定性调色板 |
| `"grey"` | 灰度 |
| `"hue"` | ggplot2 默认色相环（离散变量默认） |
| `c("blue", "red")` | 自定义颜色渐变或手动颜色向量 |

#### 变换方式 (`trans`)

| `trans` | 效果 | 适用标度 |
|---------|------|----------|
| `"identity"` | 线性映射（默认） | 全部 |
| `"log"` / `"log10"` / `"log2"` | 对数变换 | 仅 x, y |
| `"sqrt"` | 平方根变换 | 仅 x, y |
| `"reverse"` | 翻转顺序 | 全部 |
| `"discrete"` | 按分类处理 | 全部 |
| `"binned"` | 分箱离散化 | 除 shape, linetype 外全部 |

无效组合（如 `scale_color(trans = "log")`）会给出明确的中文错误提示。

### 标签函数 `label_*`

三参数协议（`text`、`hide`、`reset`）：

```r
label_title(p, "自定义标题")                # 设置
label_axis(p, hide = TRUE, aes = "x")       # 隐藏
label_axis(p, reset = TRUE, aes = "x")      # 恢复为变量名
```

| 函数 | 作用范围 |
|------|----------|
| `label_title()` | 主标题 |
| `label_subtitle()` | 副标题 |
| `label_caption()` | 脚注 |
| `label_axis()` | 轴标题（需指定 `aes = "x"` 或 `"y"`） |
| `label_legend()` | 图例标题（`aes = "colour"`、`"fill"` 等） |

标签函数优先于 `scale_*(name = …)`：后执行者胜。

### 坐标系与分面

```r
# 坐标系
project_cartesian(p, xlim = c(0, 100), expand = FALSE)
project_flip(p)
project_polar(p)

# 分面
split_wrap(p, Species, ncol = 3, scales = "free")
split_grid(p, rows = ggplot2::vars(Species))
```

### 主题与导出

```r
# 应用主题
style(p, ggplot2::theme_minimal(base_size = 14))
style(p, ggplot2::theme_bw(), plot.title = ggplot2::element_text(face = "bold"))

# 导出文件（设备由扩展名自动推断）
export(p, "plot.pdf",  width = 8, height = 6, dpi = 300)
export(p, "plot.png",  width = 8, height = 6, dpi = 150)
export(p, "plot.svg")
```

## 设计理念

- **动词前缀命名** — 每个函数族有独特的前缀：`mark_*`、`scale_*`、`project_*`、`split_*`、`label_*`。看函数名就知道它做什么。
- **管道原生** — 每个函数都返回 `plotit` 对象，整个绘图流程是一条 `|>` 链，从数据直达文件。
- **开箱即美观** — Viridis 配色、简洁主题、出版级尺寸。无需手动调整即可直接使用。
- **ggplot2 完全透明** — plotit 不是隐藏 ggplot2 的封装，而是为其增加结构。`...` 直接透传给底层的 `geom_*()` 和 `scale_*()`，随时可以使用 ggplot2 的全部能力。
- **提前验证，延迟委托** — 包层自定义约束（单位合法性、`trans` × aesthetic 兼容性）通过 [cli](https://cli.r-lib.org) 提供结构化错误。通用参数校验交由 ggplot2 自然处理。
