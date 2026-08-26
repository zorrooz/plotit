# plotit

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/zorrooz/plotit/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/zorrooz/plotit/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/zorrooz/plotit/actions/workflows/pkgdown.yaml/badge.svg)](https://zorrooz.github.io/plotit/)
[![lint](https://github.com/zorrooz/plotit/actions/workflows/lint.yaml/badge.svg)](https://github.com/zorrooz/plotit/actions/workflows/lint.yaml)
<!-- badges: end -->

<p align="center"><b>简体中文</b> | <a href="https://zorrooz.github.io/plotit/">English</a></p>

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
  style(base_theme = ggplot2::theme_minimal(base_size = 14)) |>
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

# 由边表绘制桑基流向图
flows <- data.frame(
  source = c("A", "A", "B", "B", "C"),
  target = c("B", "C", "C", "D", "D"),
  value  = c(10, 5, 8, 3, 6)
)
flows |>
  plotit(encode(source = source, target = target,
                value = value, fill = source)) |>
  mark_sankey()
```

## 管道模式

每个 plotit 图表都遵循一致的管道：

```
data |> plotit(encode(...)) |> mark_*() |> scale_*() |> layout_*() |> split_*() |> project_*() |> label_*() |> style() |> export()
```

| 步骤 | 动词 | 职责 |
|:---|:---|:---|
| 1. 初始化 | `plotit()` + `encode()` | 绑定数据与美学映射 |
| 2. 图层 | `mark_*()` | 添加几何图层（点、线、柱等） |
| 3. 标度 | `scale_*()` | 控制数据到视觉属性的映射 |
| 4. 布局 | `layout_*()` | 计算关系图布局（可选；桑基、网络、弦图、树图） |
| 5. 分面 | `split_*()` | 拆分为小倍数图 |
| 6. 坐标 | `project_*()` | 选择坐标系（笛卡尔、极坐标、地图） |
| 7. 标签 | `label_*()` | 设置标题、轴标签、图例标题 |
| 8. 主题 | `style()` | 应用主题样式 |
| 9. 导出 | `export()` | 渲染为文件 |

多图组合遵循最外层管道：

```
compose_*(p1, p2, ...) |> label_*() |> style() |> export()
```

## 函数族

### `mark_*` — 几何图层

共 27 种 mark，分三层体系：基础几何、统计、复合/关系。
复合与关系 mark 均为下层原语的文档化语法糖
（如 `mark_significance()` ≈ `mark_rule()` + `mark_text()`）。

| 函数 | 底层引擎 | 说明 |
|:---|:---|:---|
| `mark_point()` | `geom_point()` | 散点/气泡图 |
| `mark_line()` | `geom_line()` | 折线与趋势线 |
| `mark_area()` | `geom_area()` / `geom_ribbon()` | 面积图 |
| `mark_bar()` | `geom_bar()` / `geom_col()` | 柱状图 |
| `mark_rect()` | `geom_tile()` / `geom_rect()` | 热力图单元格/矩形 |
| `mark_polygon()` | `geom_polygon()` | 多边形/自定义形状 |
| `mark_text()` | `geom_text()` / ggrepel | 文本标签与数据标注 |
| `mark_rule()` | `geom_hline/vline/abline/segment` | 参考线/参考区域 |
| `mark_path()` | `geom_path()` | 路径/轨迹 |
| `mark_histogram()` | `geom_histogram()` | 直方图 |
| `mark_density()` | `geom_density()` | 1D 核密度曲线 |
| `mark_boxplot()` | `geom_boxplot()` | 箱线图 |
| `mark_violin()` | `geom_violin()` | 小提琴图 |
| `mark_map()` | sf + `geom_sf()` | 地图/地理空间 |
| `mark_smooth()` | `geom_smooth()` | 回归拟合 + 置信带 |
| `mark_hex()` | `geom_hex()` | 2D 六边形分箱热力图 |
| `mark_density_2d()` | `geom_density_2d()` | 2D 密度等高线 |
| `mark_corr()` | 内部相关性变换 + `geom_tile()` | 相关性矩阵热力图 |
| `mark_errorbar()` | `geom_errorbar()` / `-h` | 误差棒 |
| `mark_significance()` | 语法糖：rule + text | 显著性标记（括号+星号） |
| `mark_lollipop()` | 语法糖：point + 线段 | 棒棒糖图 |
| `mark_dumbbell()` | 语法糖：双 point + 线段 | 哑铃对比图 |
| `mark_beeswarm()` | ggbeeswarm | 蜂群散点（碰撞检测） |
| `mark_sankey()` | `layout_sankey()` 语法糖 | 桑基流向图 |
| `mark_treemap()` | `layout_treemap()` 语法糖 | 矩形树图 |
| `mark_network()` | `layout_force()/circle()` 语法糖 | 力导向网络图 |
| `mark_chord()` | `layout_chord()` 语法糖 | 弦图 |

### 关系数据 — `as_graph()` + `layout_*()`

关系数据遵循 Vega 风格的数据变换模型：先将数据收编为 graph 对象，
再把布局坐标烘焙进表，最后通过 `data = ~table` 引用任意子表渲染。

| 函数 | 说明 |
|:---|:---|
| `as_graph()` | 将边表、矩阵、hclust 或层次表收编为 graph 对象 |
| `layout_force()` | 力导向节点布局（强制 seed，可复现） |
| `layout_circle()` | 环形节点布局 |
| `layout_tree()` | 树布局 |
| `layout_dendrogram()` | 基于 hclust 的树状图布局 |
| `layout_chord()` | 弦图扇区布局（arcs + ribbons） |
| `layout_sankey()` | 确定性分层桑基布局（nodes/edges/ribbons） |
| `layout_treemap()` | squarified 矩形树图布局 |

```r
edges <- data.frame(source = c("A", "A", "B"),
                    target = c("B", "C", "C"),
                    value  = c(3, 1, 2))
edges |>
  as_graph() |>
  plotit() |>
  layout_circle() |>
  mark_point(data = ~nodes) |>
  mark_rule(data = ~edges)
```

`as_graph()` 按列名自动识别 `source`/`target`/`value`
（可用同名参数显式指定列）。

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

### 主题

| 函数 | 说明 |
|:---|:---|
| `style()` | 应用 ggplot2 主题（`style(p)` 恢复 plotit 内置默认） |

### 导出

| 函数 | 说明 |
|:---|:---|
| `export()` | 渲染为文件（pdf、png、svg 等） |

### 自定义扩展

| 函数 | 说明 |
|:---|:---|
| `make_mark()` | 基于任意 ggplot2 geom 注册自定义 Mark |
| `make_theme()` | 创建可复用的主题预设函数 |

## 文档

完整文档见 [zorrooz.github.io/plotit](https://zorrooz.github.io/plotit/)。

## 贡献

plotit 处于早期开发阶段。欢迎在 [GitHub Issues](https://github.com/zorrooz/plotit/issues)
上提交 bug 报告、功能请求和 Pull Request。

## 许可证

plotit 基于 MIT 许可证发布。详见 [LICENSE](LICENSE)。
