# plotit

[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

<p align="center"><b>简体中文</b> · <a href="README.md">English</a></p>

---

**plotit** 是一个基于 [ggplot2](https://ggplot2.tidyverse.org) 的**声明式、管道友好**的 R 绘图包。统一的**动词前缀 API**，一条管道从数据直达出版级图表——开箱即美观，零样板代码。

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
<summary>对比原生 ggplot2</summary>

```r
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
</details>

---

## 安装

```r
# install.packages("pak")
pak::pak("zorrooz/plotit")
```

---

## 使用指南

### 管道模式

每条 plotit 管道遵循同一套语法：

```
data |> plotit(encode(...)) |> mark_*() |> scale_*() |> label_*() |> style() |> export()
```

| 步骤 | 函数 | 职责 |
|:---|:---|:---|
| 1. 创建 | `plotit()` | 初始化图表，传入数据与美学映射 |
| 2. 图层 | `mark_*()` | 添加几何图层 |
| 3. 标度 | `scale_*()` | 控制数据到视觉属性的映射 |
| 4. 标签 | `label_*()` | 设置标题、轴名、图例名 |
| 5. 主题 | `style()` | 应用 ggplot2 主题 |
| 6. 导出 | `export()` | 渲染为文件 |

### 函数族速览

| 家族 | 前缀 | 职责 | 示例 |
|:---|:---|:---|:---|
| 图层 | `mark_*` | 几何图层 | `mark_point()`, `mark_line()`, `mark_bar()`, `mark_boxplot()`, `mark_histogram()`, `mark_density()` |
| 组合 | `compose_*` | 多图布局 | `compose_grid()`, `compose_inset()`, `compose_marginal()` |
| 标度 | `scale_*` | 数据 → 视觉映射 | `scale_x(trans = "log")`, `scale_color(range = "viridis")` |
| 标签 | `label_*` | 标题与标注 | `label_title("标题")`, `label_axis("X轴", aes = "x")` |
| 坐标系 | `project_*` | 坐标变换 | `project_cartesian(flip = TRUE)`, `project_polar()` |
| 分面 | `split_*` | 分面布局 | `split_wrap(Species)`, `split_grid(rows = vars(cyl))` |
| 主题 | `style()` | 主题 | `style(theme_minimal(base_size = 14))` |
| 导出 | `export()` | 输出文件 | `export("plot.pdf", dpi = 300)` |

---

## `mark_*` — 几何图层

六个 mark 函数，统一签名（`mapping`, `data`, `position`, `rasterize`, `...`）。

| 函数 | ggplot2 | 用途 |
|:---|:---|:---|
| `mark_point()` | `geom_point()` | 散点图 |
| `mark_line()` | `geom_line()` | 折线、趋势线、时间序列 |
| `mark_bar()` | `geom_bar()` / `geom_col()` | 柱状图 |
| `mark_boxplot()` | `geom_boxplot()` | 分组分布展示 |
| `mark_histogram()` | `geom_histogram()` | 直方图 |
| `mark_density()` | `geom_density()` | 密度曲线 |

---

## `compose_*` — 多图组合布局

将多个图表组装为复合布局。全部返回 `plotit_composite` 对象，
支持 `label_*()` / `style()` / `export()` 管道延续。

| 函数 | 说明 | 关键参数 |
|:---|:---|:---|
| `compose_grid()` | 网格排列 | `...`, `ncol`, `nrow`, `widths`, `heights`, `guides`, `axes`, `tag_levels` |
| `compose_inset()` | 浮动嵌入 | `base`, `inset`, `left`, `bottom`, `right`, `top` |
| `compose_marginal()` | 散点 + 边际分布 | `main`, `top`, `right`, `widths`, `heights` |

```r
# 2×2 仪表盘 + 自动子图标签
compose_grid(p1, p2, p3, p4, ncol = 2, tag_levels = "A") |>
 label_title("仪表盘") |>
 export("dashboard.png")

# 散点图 + 边际直方图
compose_marginal(main, top_hist, right_hist) |>
 label_title("Iris") |>
 export("marginal.png")
```

---

## `scale_*` — 数据到视觉的映射

八个函数，参数完全一致——仅 `trans` 默认值不同。

| 函数 | 美学属性 | `trans` 默认值 |
|:---|:---|:---|
| `scale_color()` | colour | `NULL`（自动检测） |
| `scale_fill()` | fill | `NULL`（自动检测） |
| `scale_size()` | size | `NULL`（自动检测） |
| `scale_alpha()` | alpha | `NULL`（自动检测） |
| `scale_shape()` | shape | `"discrete"` |
| `scale_linetype()` | linetype | `"discrete"` |
| `scale_x()` | x | `"identity"` |
| `scale_y()` | y | `"identity"` |

均接受 `name`, `limits`, `range`, `breaks`, `labels`, `...`。

| 参数 | 回答的问题 | 示例 |
|:---|:---|:---|
| `range` | 映射到**什么**视觉值？ | `"viridis"`, `c("blue","red")` |
| `trans` | **如何**变换数据？ | `"log"`, `"reverse"`, `"binned"` |
| `limits` | 包含哪些数据范围？ | `c(0, 100)` |
| `breaks` | 刻度/图例键放在哪里？ | `c(2, 4, 6)` |
| `labels` | 刻度/图例键叫什么？ | `c("低", "中", "高")` |
| `name` | 标度/坐标轴叫什么？ | `"发动机排量"` |

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

| `trans` | 效果 | 适用范围 |
|:---|:---|:---|
| `"identity"` | 线性（默认） | 全部 |
| `"log"`, `"log10"`, `"log2"` | 对数 | x, y |
| `"sqrt"` | 平方根 | x, y |
| `"reverse"` | 翻转顺序 | 全部 |
| `"discrete"` | 按分类处理 | 全部 |
| `"binned"` | 分箱后离散化 | 除 shape, linetype 外全部 |

---

## `label_*` — 文本标签

五个函数，三参数协议：

| 调用方式 | 行为 |
|:---|:---|
| `label_*(text = "字符串")` | 设置自定义文本 |
| `label_*(hide = TRUE)` | 移除元素及占位空间 |
| `label_*(reset = TRUE)` | 恢复为变量名（轴/图例）或移除（标题） |
| _不调用_ | 保持当前状态 |

| 函数 | 作用范围 |
|:---|:---|
| `label_title()` | 主标题 |
| `label_subtitle()` | 副标题 |
| `label_caption()` | 脚注 |
| `label_axis()` | 轴标题 — 必须指定 `aes = "x"` 或 `"y"` |
| `label_legend()` | 图例标题 — `aes = "colour"`, `"fill"` 等 |

---

## `project_*` — 坐标系

| 函数 | 说明 | 关键参数 |
|:---|:---|:---|
| `project_cartesian()` | 笛卡尔（缩放/翻转/固定比例/坐标变换） | `xlim`, `ylim`, `expand`, `flip`, `fixed`, `coord_trans`, `clip` |
| `project_polar()` | 极坐标 | `theta`, `start`, `direction`, `clip` |
| `project_parallel()` | 平行坐标 | `columns`, `group`, `scale`, `alpha`, `size` |
| `project_map()` | 地理投影 | `projection`, `xlim`, `ylim`, `clip` |

## `split_*` — 分面

| 函数 | 说明 | 关键参数 |
|:---|:---|:---|
| `split_wrap()` | 环绕分面 | `...`（分面变量）, `ncol`, `nrow`, `scales` |
| `split_grid()` | 网格分面 | `rows`, `cols`, `scales`, `space` |

## `style()` & `export()`

| 函数 | 说明 | 关键参数 |
|:---|:---|:---|
| `style()` | 应用 ggplot2 主题 | `...`, `base_size`, `base_family`, `base_theme` |
| `export()` | 渲染为文件 | `filename`, `width`, `height`, `dpi`, `device` |
