# plotit

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/zorrooz/plotit/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/zorrooz/plotit/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/zorrooz/plotit/actions/workflows/pkgdown.yaml/badge.svg)](https://zorrooz.github.io/plotit/)
[![lint](https://github.com/zorrooz/plotit/actions/workflows/lint.yaml/badge.svg)](https://github.com/zorrooz/plotit/actions/workflows/lint.yaml)

**简体中文** \| [English](https://zorrooz.github.io/plotit/)

> ⚠️ **早期开发阶段**  
> plotit 处于活跃的预发布开发中。每次更新都**极有可能**带来破坏性变更。
> API 实现不完整，大量计划功能尚未实现，可能存在许多
> bug。请勿用于生产环境。 使用风险自负。欢迎反馈和贡献。

------------------------------------------------------------------------

## 概述

**plotit** 是一个基于 [ggplot2](https://ggplot2.tidyverse.org)
的声明式、管道优先 R 绘图包。它用统一的**动词前缀 API** 替代了基于 `+`
的图层叠加，支持原生管道
（`|>`）。合理的默认设置消除了样板代码——颜色、主题和尺寸开箱即用。

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

## 安装

你可以直接从 GitHub 安装 plotit 的开发版本：

``` r

# install.packages("pak")
pak::pak("zorrooz/plotit")
```

## 快速入门

``` r

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

    data |> plotit(encode(...)) |> mark_*() |> scale_*() |> split_*() |> project_*() |> label_*() |> style() |> export()

| 步骤 | 动词 | 职责 |
|:---|:---|:---|
| 1\. 初始化 | [`plotit()`](https://zorrooz.github.io/plotit/reference/plotit.md) + [`encode()`](https://zorrooz.github.io/plotit/reference/encode.md) | 绑定数据与美学映射 |
| 2\. 图层 | `mark_*()` | 添加几何图层（点、线、柱等） |
| 3\. 标度 | `scale_*()` | 控制数据到视觉属性的映射 |
| 4\. 分面 | `split_*()` | 拆分为小倍数图 |
| 5\. 坐标 | `project_*()` | 选择坐标系（笛卡尔、极坐标、地图） |
| 6\. 标签 | `label_*()` | 设置标题、轴标签、图例标题 |
| 7\. 主题 | [`style()`](https://zorrooz.github.io/plotit/reference/style.md) | 应用主题样式 |
| 8\. 导出 | [`export()`](https://zorrooz.github.io/plotit/reference/export.md) | 渲染为文件 |

多图组合遵循最外层管道：

    compose_*(p1, p2, ...) |> label_*() |> style() |> export()

## 函数族

### `mark_*` — 几何图层

| 函数 | ggplot2 | 说明 |
|:---|:---|:---|
| [`mark_point()`](https://zorrooz.github.io/plotit/reference/mark_point.md) | `geom_point()` | 散点图 |
| [`mark_line()`](https://zorrooz.github.io/plotit/reference/mark_line.md) | `geom_line()` | 折线与趋势线 |
| [`mark_area()`](https://zorrooz.github.io/plotit/reference/mark_area.md) | `geom_area()` | 面积图/河流图 |
| [`mark_bar()`](https://zorrooz.github.io/plotit/reference/mark_bar.md) | `geom_bar()` / `geom_col()` | 柱状图 |
| [`mark_text()`](https://zorrooz.github.io/plotit/reference/mark_text.md) | `geom_text()` / `ggrepel` | 文本标签与数据标注 |
| [`mark_boxplot()`](https://zorrooz.github.io/plotit/reference/mark_boxplot.md) | `geom_boxplot()` | 箱线图 |
| [`mark_histogram()`](https://zorrooz.github.io/plotit/reference/mark_histogram.md) | `geom_histogram()` | 直方图 |
| [`mark_density()`](https://zorrooz.github.io/plotit/reference/mark_density.md) | `geom_density()` | 1D 核密度估计 |
| [`mark_violin()`](https://zorrooz.github.io/plotit/reference/mark_violin.md) | `geom_violin()` | 小提琴图 |
| [`mark_map()`](https://zorrooz.github.io/plotit/reference/mark_map.md) | `geom_sf()` | 地图/地理空间 |

### `scale_*` — 数据到视觉的映射

| 函数 | 美学属性 |
|:---|:---|
| [`scale_color()`](https://zorrooz.github.io/plotit/reference/scale_color.md) | 颜色 |
| [`scale_fill()`](https://zorrooz.github.io/plotit/reference/scale_fill.md) | 填充 |
| [`scale_size()`](https://zorrooz.github.io/plotit/reference/scale_size.md) | 大小 |
| [`scale_alpha()`](https://zorrooz.github.io/plotit/reference/scale_alpha.md) | 透明度 |
| [`scale_shape()`](https://zorrooz.github.io/plotit/reference/scale_shape.md) | 形状 |
| [`scale_linetype()`](https://zorrooz.github.io/plotit/reference/scale_linetype.md) | 线型 |
| [`scale_x()`](https://zorrooz.github.io/plotit/reference/scale_x.md) | x 轴 |
| [`scale_y()`](https://zorrooz.github.io/plotit/reference/scale_y.md) | y 轴 |

### `label_*` — 文本标签

| 函数 | 作用范围 |
|:---|:---|
| [`label_title()`](https://zorrooz.github.io/plotit/reference/label_title.md) | 主标题 |
| [`label_subtitle()`](https://zorrooz.github.io/plotit/reference/label_subtitle.md) | 副标题 |
| [`label_caption()`](https://zorrooz.github.io/plotit/reference/label_caption.md) | 脚注 |
| [`label_axis()`](https://zorrooz.github.io/plotit/reference/label_axis.md) | 轴标题 |
| [`label_legend()`](https://zorrooz.github.io/plotit/reference/label_legend.md) | 图例标题 |

### `project_*` — 坐标系

| 函数 | 说明 |
|:---|:---|
| [`project_cartesian()`](https://zorrooz.github.io/plotit/reference/project_cartesian.md) | 笛卡尔（缩放、翻转、比例、变换） |
| [`project_polar()`](https://zorrooz.github.io/plotit/reference/project_polar.md) | 极坐标 |
| [`project_parallel()`](https://zorrooz.github.io/plotit/reference/project_parallel.md) | 平行坐标 |
| [`project_map()`](https://zorrooz.github.io/plotit/reference/project_map.md) | 地理投影 |

### `split_*` — 分面

| 函数 | 说明 |
|:---|:---|
| [`split_wrap()`](https://zorrooz.github.io/plotit/reference/split_wrap.md) | 环绕分面 |
| [`split_grid()`](https://zorrooz.github.io/plotit/reference/split_grid.md) | 网格分面 |

### `compose_*` — 多图组合

| 函数 | 说明 |
|:---|:---|
| [`compose_grid()`](https://zorrooz.github.io/plotit/reference/compose_grid.md) | 网格排列 |
| [`compose_inset()`](https://zorrooz.github.io/plotit/reference/compose_inset.md) | 浮动嵌入 |
| [`compose_marginal()`](https://zorrooz.github.io/plotit/reference/compose_marginal.md) | 散点 + 边际分布 |

### 主题

| 函数 | 说明 |
|:---|:---|
| [`style()`](https://zorrooz.github.io/plotit/reference/style.md) | 应用 ggplot2 主题 |
| [`style_default()`](https://zorrooz.github.io/plotit/reference/style_default.md) | 恢复 plotit 内置主题 |

### 导出

| 函数 | 说明 |
|:---|:---|
| [`export()`](https://zorrooz.github.io/plotit/reference/export.md) | 渲染为文件（pdf、png、svg 等） |

### 自定义扩展

| 函数 | 说明 |
|:---|:---|
| [`make_mark()`](https://zorrooz.github.io/plotit/reference/make_mark.md) | 基于任意 ggplot2 geom 注册自定义 Mark |
| [`make_theme()`](https://zorrooz.github.io/plotit/reference/make_theme.md) | 创建可复用的主题预设函数 |

## 文档

完整文档见
[zorrooz.github.io/plotit](https://zorrooz.github.io/plotit/)。

## 贡献

plotit 处于早期开发阶段。欢迎在 [GitHub
Issues](https://github.com/zorrooz/plotit/issues) 上提交 bug
报告、功能请求和 Pull Request。

## 许可证

plotit 基于 MIT 许可证发布。详见
[LICENSE](https://zorrooz.github.io/plotit/LICENSE)。
