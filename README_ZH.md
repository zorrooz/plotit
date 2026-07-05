# plotit

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

**简体中文** \| [English](https://zorrooz.github.io/plotit/README.md)

**plotit** 是一个基于 [ggplot2](https://ggplot2.tidyverse.org)
的**声明式、管道友好**的 R 绘图包。统一的**动词前缀
API**，一条管道从数据直达出版级图表——开箱即美观，零样板代码。

``` r

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

对比原生 ggplot2

``` r

# plotit — 4 行
iris |>
 plotit(encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
 mark_point(size = 2, alpha = 0.7) |>
 scale_color(range = "viridis") |>
 label_title("Iris Sepal Dimensions")

# 原生 ggplot2 — 3 行
ggplot(iris, aes(x = Sepal.Width, y = Sepal.Length, colour = Species)) +
 geom_point(size = 2, alpha = 0.7) +
 scale_colour_viridis_d() +
 labs(title = "Iris Sepal Dimensions")
```

------------------------------------------------------------------------

## 安装

``` r

# install.packages("pak")
pak::pak("zorrooz/plotit")
```

------------------------------------------------------------------------

## 使用指南

### 管道模式

plotit 有两层操作：

**单图管道** — 从数据构建一个图表：

    data |> plotit(encode(...)) |> mark_*() |> scale_*() |> label_*() |> project_*() |> split_*() |> style() |> export()

| 步骤 | 函数 | 职责 |
|:---|:---|:---|
| 1\. 创建 | [`plotit()`](https://zorrooz.github.io/plotit/reference/plotit.md) | 初始化图表，传入数据与美学映射 |
| 2\. 图层 | `mark_*()` | 添加几何图层 |
| 3\. 标度 | `scale_*()` | 控制数据到视觉属性的映射 |
| 4\. 标签 | `label_*()` | 设置标题、轴名、图例名 |
| 5\. 坐标系 | `project_*()` | 设置坐标系 |
| 6\. 分面 | `split_*()` | 拆分为小倍数图 |
| 7\. 主题 | [`style()`](https://zorrooz.github.io/plotit/reference/style.md) | 应用 ggplot2 主题 |
| 8\. 导出 | [`export()`](https://zorrooz.github.io/plotit/reference/export.md) | 渲染为文件 |

**多图组合** — 将多个 `plotit` 对象组装为一个布局（最外层）：

    compose_*(p1, p2, ...) |> label_*() |> style() |> export()

| 步骤 | 函数 | 职责 |
|:---|:---|:---|
| 1\. 组装 | `compose_*()` | 将多个 `plotit` 对象组合为复合布局 |
| 2\. 标签 | [`label_title()`](https://zorrooz.github.io/plotit/reference/label_title.md) / [`label_subtitle()`](https://zorrooz.github.io/plotit/reference/label_subtitle.md) / [`label_caption()`](https://zorrooz.github.io/plotit/reference/label_caption.md) | 设置组合级标题 |
| 3\. 主题 | [`style()`](https://zorrooz.github.io/plotit/reference/style.md) | 对组合应用 ggplot2 主题 |
| 4\. 导出 | [`export()`](https://zorrooz.github.io/plotit/reference/export.md) | 将组合渲染为文件 |

> **关键区别**：单图函数（`mark_*`、`scale_*`、`project_*`、`split_*`、`label_axis`、`label_legend`）操作**一个包含数据的
> `plotit` 对象**。`compose_*` 操作**多个 `plotit` 对象**并返回
> `plotit_composite`——它是最外层，在各子图构建完成后才应用。

### 函数族速览

**单图函数族**（内层）：

| 家族 | 前缀 | 职责 | 示例 |
|:---|:---|:---|:---|
| 创建 | [`plotit()`](https://zorrooz.github.io/plotit/reference/plotit.md) + [`encode()`](https://zorrooz.github.io/plotit/reference/encode.md) | 初始化图表，传入数据与美学映射 | `plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))` |
| 图层 | `mark_*` | 几何图层 | [`mark_point()`](https://zorrooz.github.io/plotit/reference/mark_point.md), [`mark_line()`](https://zorrooz.github.io/plotit/reference/mark_line.md), [`mark_bar()`](https://zorrooz.github.io/plotit/reference/mark_bar.md), [`mark_boxplot()`](https://zorrooz.github.io/plotit/reference/mark_boxplot.md), [`mark_histogram()`](https://zorrooz.github.io/plotit/reference/mark_histogram.md), [`mark_density()`](https://zorrooz.github.io/plotit/reference/mark_density.md) |
| 标度 | `scale_*` | 数据 → 视觉映射 | `scale_x(trans = "log")`, `scale_color(range = "viridis")` |
| 标签 | `label_*` | 标题与轴/图例标注 | `label_title("标题")`, `label_axis("X轴", aes = "x")`, `label_legend("种类", aes = "colour")` |
| 坐标系 | `project_*` | 坐标变换 | `project_cartesian(flip = TRUE)`, [`project_polar()`](https://zorrooz.github.io/plotit/reference/project_polar.md) |
| 分面 | `split_*` | 分面布局 | `split_wrap(Species)`, `split_grid(rows = vars(cyl))` |
| 主题 | [`style()`](https://zorrooz.github.io/plotit/reference/style.md) | 应用 ggplot2 主题 | `style(theme_minimal(base_size = 14))` |
| 导出 | [`export()`](https://zorrooz.github.io/plotit/reference/export.md) | 渲染为文件 | `export("plot.pdf", dpi = 300)` |

**多图组合**（最外层——操作 `plotit` 对象，而非数据）：

| 家族 | 前缀 | 职责 | 示例 |
|:---|:---|:---|:---|
| 组合 | `compose_*` | 将多个 `plotit` 对象组装为一个布局 | [`compose_grid()`](https://zorrooz.github.io/plotit/reference/compose_grid.md), [`compose_inset()`](https://zorrooz.github.io/plotit/reference/compose_inset.md), [`compose_marginal()`](https://zorrooz.github.io/plotit/reference/compose_marginal.md) |

------------------------------------------------------------------------

## `mark_*` — 几何图层

六个 mark 函数，统一签名（`mapping`, `data`, `position`, `rasterize`,
`...`）。

| 函数 | ggplot2 | 用途 |
|:---|:---|:---|
| [`mark_point()`](https://zorrooz.github.io/plotit/reference/mark_point.md) | `geom_point()` | 散点图 |
| [`mark_line()`](https://zorrooz.github.io/plotit/reference/mark_line.md) | `geom_line()` | 折线、趋势线、时间序列 |
| [`mark_bar()`](https://zorrooz.github.io/plotit/reference/mark_bar.md) | `geom_bar()` / `geom_col()` | 柱状图 |
| [`mark_boxplot()`](https://zorrooz.github.io/plotit/reference/mark_boxplot.md) | `geom_boxplot()` | 分组分布展示 |
| [`mark_histogram()`](https://zorrooz.github.io/plotit/reference/mark_histogram.md) | `geom_histogram()` | 直方图 |
| [`mark_density()`](https://zorrooz.github.io/plotit/reference/mark_density.md) | `geom_density()` | 密度曲线 |

------------------------------------------------------------------------

## `scale_*` — 数据到视觉的映射

八个函数，参数完全一致——仅 `trans` 默认值不同。

| 函数 | 美学属性 | `trans` 默认值 |
|:---|:---|:---|
| [`scale_color()`](https://zorrooz.github.io/plotit/reference/scale_color.md) | colour | `NULL`（自动检测） |
| [`scale_fill()`](https://zorrooz.github.io/plotit/reference/scale_fill.md) | fill | `NULL`（自动检测） |
| [`scale_size()`](https://zorrooz.github.io/plotit/reference/scale_size.md) | size | `NULL`（自动检测） |
| [`scale_alpha()`](https://zorrooz.github.io/plotit/reference/scale_alpha.md) | alpha | `NULL`（自动检测） |
| [`scale_shape()`](https://zorrooz.github.io/plotit/reference/scale_shape.md) | shape | `"discrete"` |
| [`scale_linetype()`](https://zorrooz.github.io/plotit/reference/scale_linetype.md) | linetype | `"discrete"` |
| [`scale_x()`](https://zorrooz.github.io/plotit/reference/scale_x.md) | x | `"identity"` |
| [`scale_y()`](https://zorrooz.github.io/plotit/reference/scale_y.md) | y | `"identity"` |

均接受 `name`, `limits`, `range`, `breaks`, `labels`, `...`。

| 参数     | 回答的问题             | 示例                             |
|:---------|:-----------------------|:---------------------------------|
| `range`  | 映射到**什么**视觉值？ | `"viridis"`, `c("blue","red")`   |
| `trans`  | **如何**变换数据？     | `"log"`, `"reverse"`, `"binned"` |
| `limits` | 包含哪些数据范围？     | `c(0, 100)`                      |
| `breaks` | 刻度/图例键放在哪里？  | `c(2, 4, 6)`                     |
| `labels` | 刻度/图例键叫什么？    | `c("低", "中", "高")`            |
| `name`   | 标度/坐标轴叫什么？    | `"发动机排量"`                   |

### `range` 速查

| 美学属性 | `range = NULL` | `range = "name"` | `range = c(a, b)` |
|:---|:---|:---|:---|
| colour, fill | 自动（离散→hue，连续→viridis） | `"viridis"`, `"brewer"`, `"grey"`, `"hue"` | `c("blue", "red")` |
| size | `c(1, 6)` | — | `c(0.5, 10)` |
| alpha | `c(0.1, 1)` | — | `c(0, 0.8)` |
| shape | 默认形状集 | — | `c(1, 16)` |
| linetype | 默认线型集 | — | `c("solid", "dashed")` |
| x, y | 数据自身范围 | — | `c(0, 100)` |

### `trans` 速查

| `trans`                      | 效果         | 适用范围                  |
|:-----------------------------|:-------------|:--------------------------|
| `"identity"`                 | 线性（默认） | 全部                      |
| `"log"`, `"log10"`, `"log2"` | 对数         | x, y                      |
| `"sqrt"`                     | 平方根       | x, y                      |
| `"reverse"`                  | 翻转顺序     | 全部                      |
| `"discrete"`                 | 按分类处理   | 全部                      |
| `"binned"`                   | 分箱后离散化 | 除 shape, linetype 外全部 |

------------------------------------------------------------------------

## `label_*` — 文本标签

五个函数，三参数协议：

| 调用方式                   | 行为                                  |
|:---------------------------|:--------------------------------------|
| `label_*(text = "字符串")` | 设置自定义文本                        |
| `label_*(hide = TRUE)`     | 移除元素及占位空间                    |
| `label_*(reset = TRUE)`    | 恢复为变量名（轴/图例）或移除（标题） |
| *不调用*                   | 保持当前状态                          |

| 函数 | 作用范围 |
|:---|:---|
| [`label_title()`](https://zorrooz.github.io/plotit/reference/label_title.md) | 主标题 |
| [`label_subtitle()`](https://zorrooz.github.io/plotit/reference/label_subtitle.md) | 副标题 |
| [`label_caption()`](https://zorrooz.github.io/plotit/reference/label_caption.md) | 脚注 |
| [`label_axis()`](https://zorrooz.github.io/plotit/reference/label_axis.md) | 轴标题 — 必须指定 `aes = "x"` 或 `"y"` |
| [`label_legend()`](https://zorrooz.github.io/plotit/reference/label_legend.md) | 图例标题 — `aes = "colour"`, `"fill"` 等 |

------------------------------------------------------------------------

## `project_*` — 坐标系

| 函数 | 说明 | 关键参数 |
|:---|:---|:---|
| [`project_cartesian()`](https://zorrooz.github.io/plotit/reference/project_cartesian.md) | 笛卡尔（缩放/翻转/固定比例/坐标变换） | `xlim`, `ylim`, `expand`, `flip`, `fixed`, `coord_trans`, `clip` |
| [`project_polar()`](https://zorrooz.github.io/plotit/reference/project_polar.md) | 极坐标 | `theta`, `start`, `direction`, `clip` |
| [`project_parallel()`](https://zorrooz.github.io/plotit/reference/project_parallel.md) | 平行坐标 | `columns`, `group`, `scale`, `alpha`, `size` |
| [`project_map()`](https://zorrooz.github.io/plotit/reference/project_map.md) | 地理投影 | `projection`, `xlim`, `ylim`, `clip` |

## `split_*` — 分面

| 函数 | 说明 | 关键参数 |
|:---|:---|:---|
| [`split_wrap()`](https://zorrooz.github.io/plotit/reference/split_wrap.md) | 环绕分面 | `...`（分面变量）, `ncol`, `nrow`, `scales` |
| [`split_grid()`](https://zorrooz.github.io/plotit/reference/split_grid.md) | 网格分面 | `rows`, `cols`, `scales`, `space` |

## `style()` & `export()`

| 函数 | 说明 | 关键参数 |
|:---|:---|:---|
| [`style()`](https://zorrooz.github.io/plotit/reference/style.md) | 应用 ggplot2 主题 | `...`, `base_size`, `base_family`, `base_theme` |
| [`export()`](https://zorrooz.github.io/plotit/reference/export.md) | 渲染为文件 | `filename`, `width`, `height`, `dpi`, `device` |

------------------------------------------------------------------------

## `compose_*` — 多图组合（最外层）

将多个 `plotit` 对象组装为复合布局。与操作数据的单图函数不同，
`compose_*` 接收**已构建好的 `plotit` 对象**作为输入，返回
`plotit_composite`。 这是 plotit
架构中的**最外层**——先分别构建各子图，再组合到一起。

返回的复合对象支持管道连接到
[`label_title()`](https://zorrooz.github.io/plotit/reference/label_title.md)
/
[`label_subtitle()`](https://zorrooz.github.io/plotit/reference/label_subtitle.md)
/
[`label_caption()`](https://zorrooz.github.io/plotit/reference/label_caption.md)
/ [`style()`](https://zorrooz.github.io/plotit/reference/style.md) /
[`export()`](https://zorrooz.github.io/plotit/reference/export.md)。

| 函数 | 说明 | 关键参数 |
|:---|:---|:---|
| [`compose_grid()`](https://zorrooz.github.io/plotit/reference/compose_grid.md) | 网格排列 | `...`, `ncol`, `nrow`, `widths`, `heights`, `guides`, `axes`, `tag_levels` |
| [`compose_inset()`](https://zorrooz.github.io/plotit/reference/compose_inset.md) | 浮动嵌入 | `base`, `inset`, `left`, `bottom`, `right`, `top` |
| [`compose_marginal()`](https://zorrooz.github.io/plotit/reference/compose_marginal.md) | 散点 + 边际分布 | `main`, `top`, `right`, `widths`, `heights` |

``` r

# 2×2 仪表盘 + 自动子图标签
compose_grid(p1, p2, p3, p4, ncol = 2, tag_levels = "A") |>
 label_title("仪表盘") |>
 export("dashboard.png")

# 散点图 + 边际直方图
compose_marginal(main, top_hist, right_hist) |>
 label_title("Iris") |>
 export("marginal.png")
```
