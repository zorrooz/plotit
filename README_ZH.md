# plotit

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/zorrooz/plotit/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/zorrooz/plotit/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/zorrooz/plotit/actions/workflows/pkgdown.yaml/badge.svg)](https://zorrooz.github.io/plotit/)
[![lint](https://github.com/zorrooz/plotit/actions/workflows/lint.yaml/badge.svg)](https://github.com/zorrooz/plotit/actions/workflows/lint.yaml)
<!-- badges: end -->

<p align="center"><b>简体中文</b> | <a href="README.html">English</a></p>

> ⚠️ **早期开发阶段**  
> plotit 处于活跃的预发布开发中。每次更新都**极有可能**带来破坏性变更。
> API 实现不完整，大量计划功能尚未实现，可能存在许多 bug。请勿用于生产环境。
> 使用风险自负。欢迎反馈和贡献。

---

## 概述

**plotit** 是一个基于 [ggplot2](https://ggplot2.tidyverse.org) 的声明式、管道优先
R 绘图包。它用统一的**动词前缀 API** 替代了基于 `+` 的图层叠加，支持原生管道
（`|>`）。合理的默认设置消除了样板代码——颜色、主题和尺寸开箱即用。

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

## 安装

你可以直接从 GitHub 安装 plotit 的开发版本：

```r
# install.packages("pak")
pak::pak("zorrooz/plotit")
```

## 快速入门

```r
library(plotit)

# 带颜色映射的散点图
iris |>
  plotit(encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
  mark_point()

# 计数柱状图
mtcars |>
  plotit(encode(x = factor(cyl))) |>
  mark_bar()

# 时间序列折线图
ggplot2::economics |>
  plotit(encode(x = date, y = unemploy)) |>
  mark_line()

# 多图仪表盘
p1 <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
p2 <- plotit(iris, encode(x = Species, y = Sepal.Length)) |> mark_boxplot()
compose_grid(p1, p2, tag_levels = "A") |>
  label_title("Iris Dashboard") |>
  export("dashboard.png")
```

## 管道模式

每个 plotit 图表都遵循一致的管道：

```
data |> plotit(encode(...)) |> mark_*() |> scale_*() |> label_*() |> project_*() |> split_*() |> style() |> export()
```

| 步骤 | 动词 | 职责 |
|:---|:---|:---|
| 1. 初始化 | `plotit()` + `encode()` | 绑定数据与美学映射 |
| 2. 图层 | `mark_*()` | 添加几何图层（点、线、柱等） |
| 3. 标度 | `scale_*()` | 控制数据到视觉属性的映射 |
| 4. 标签 | `label_*()` | 设置标题、轴标签、图例标题 |
| 5. 坐标 | `project_*()` | 选择坐标系（笛卡尔、极坐标、地图） |
| 6. 分面 | `split_*()` | 拆分为小倍数图 |
| 7. 主题 | `style()` | 应用完整主题 |
| 8. 导出 | `export()` | 渲染为文件 |

多图组合遵循最外层管道：

```
compose_*(p1, p2, ...) |> label_*() |> style() |> export()
```

## 函数族

### `mark_*` — 几何图层

| 函数 | ggplot2 | 说明 |
|:---|:---|:---|
| `mark_point()` | `geom_point()` | 散点图 |
| `mark_line()` | `geom_line()` | 折线与趋势线 |
| `mark_bar()` | `geom_bar()` / `geom_col()` | 柱状图 |
| `mark_boxplot()` | `geom_boxplot()` | 箱线图 |
| `mark_histogram()` | `geom_histogram()` | 直方图 |
| `mark_density()` | `geom_density()` | 核密度估计 |

### `scale_*` — 数据到视觉的映射

| 函数 | 美学属性 |
|:---|:---|
| `scale_color()` | 颜色 |
| `scale_fill()` | 填充 |
| `scale_size()` | 大小 |
| `scale_alpha()` | 透明度 |
| `scale_shape()` | 形状 |
| `scale_linetype()` | 线型 |
| `scale_x()` | x 轴 |
| `scale_y()` | y 轴 |

### `label_*` — 文本标签

| 函数 | 作用范围 |
|:---|:---|
| `label_title()` | 主标题 |
| `label_subtitle()` | 副标题 |
| `label_caption()` | 脚注 |
| `label_axis()` | 轴标题 |
| `label_legend()` | 图例标题 |

### `project_*` — 坐标系

| 函数 | 说明 |
|:---|:---|
| `project_cartesian()` | 笛卡尔（缩放、翻转、比例、变换） |
| `project_polar()` | 极坐标 |
| `project_parallel()` | 平行坐标 |
| `project_map()` | 地理投影 |

### `split_*` — 分面

| 函数 | 说明 |
|:---|:---|
| `split_wrap()` | 环绕分面 |
| `split_grid()` | 网格分面 |

### `compose_*` — 多图组合

| 函数 | 说明 |
|:---|:---|
| `compose_grid()` | 网格排列 |
| `compose_inset()` | 浮动嵌入 |
| `compose_marginal()` | 散点 + 边际分布 |

### 主题与导出

| 函数 | 说明 |
|:---|:---|
| `style()` | 应用 ggplot2 主题 |
| `style_default()` | 恢复 plotit 内置主题 |
| `export()` | 渲染为文件（pdf、png、svg 等） |

## 文档

完整文档见 [zorrooz.github.io/plotit](https://zorrooz.github.io/plotit/)。

## 贡献

plotit 处于早期开发阶段。欢迎在 [GitHub Issues](https://github.com/zorrooz/plotit/issues)
上提交 bug 报告、功能请求和 Pull Request。

## 许可证

plotit 基于 MIT 许可证发布。详见 [LICENSE](LICENSE)。
