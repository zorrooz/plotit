# API System Reference (v2)

> **本页解决什么问题**：给 plotit 的 82 个导出函数一套系统化的 API
> 参考——按族归并、 每族一个共享签名＋参数列表，并对标 Vega-Lite / AntV
> G2 / tidyplots / tidyheatmaps。 **前置**：[Getting
> Started](https://zorrooz.github.io/plotit/articles/plotit.md)。
> **下一步**：逐意图的管道链索引见 [Gallery
> System](https://zorrooz.github.io/plotit/articles/gallery-system.md)。

## 1 设计原则（对照表）

| 参考体系 | 组织方式 | plotit 的对应 |
|:---|:---|:---|
| Vega-Lite | 单一 spec：mark/encode/scale/project | 动词族：`mark_*`/`scale_*`/`project_*` |
| AntV G2 | 复合 Mark 展开为子 Mark | `mark_errorbar`/`mark_forest` 等复合语法糖 |
| tidyplots (`add_*`) | 数据管道逐层 `add_` | `|> plotit(...) |> mark_*(...)` 全管道 |
| tidyheatmaps | 矩阵长表化 + 聚类注释 | `mark_heatmap` + `layout_dendrogram` + `compose_annot` |

三条总则（契约分层，AGENTS §1.4）：

1.  **核心契约**（1.0 主版本内稳定）：函数名、返回类型
    `plotit`/`plotit_composite`、
    [`plotit()`](https://zorrooz.github.io/plotit/reference/plotit.md)
    的 `data`/`mapping`、以及数据管道形态；
2.  **扩展契约**（2.0 可调整）：`scale_*` 的 `trans`/`range`
    合法集合、`label_*` 协议、 `project_*`/`split_*`/`layout_*`
    参数签名、关系数据体系；
3.  **可迭代**：默认主题/色板/画布参数与内部实现。

## 2 管道骨架

``` r
data |> plotit(encode(...)) |>
  mark_*(...)  |> layout_*(...) | split_*(...) | project_*(...) |>
  scale_*(...)  |> label_*(...) | style(...) | export(...)
```

单图动词族不接受 `plotit_composite`；多图一律先建子图再 `compose_*`。

## 3 初始化与编码

``` r

plotit(data, mapping = encode(), autofit = FALSE,
       width = 5, height = 3.5, size_unit = "in",
       dodge = NULL, default_color = "#4E79A7")
```

| 参数 | 默认 | 说明 |
|:---|:---|:---|
| `data` | — | 数据框/矩阵（矩阵自动 `as.data.frame` 收编） |
| `mapping` | [`encode()`](https://zorrooz.github.io/plotit/reference/encode.md) | 美学映射，须为 `plotit_encode` |
| `autofit` | `FALSE` | 面板尺寸是否自适应容器 |
| `width`,`height` | `5`,`3.5` | 面板尺寸（配合 `size_unit`） |
| `size_unit` | `"in"` | `"in"`/`"cm"`/`"mm"` |
| `dodge` | `NULL` | 全局 dodge 宽度；离散轴自动 0.8 |
| `default_color` | `"#4E79A7"` | 无 colour/fill 映射时双通道注入单色 |

``` r

encode(...)                 # 透传 aes()，返回 plotit_encode
add_ggplot(plot, gg_obj)    # 逃生舱：追加任意 ggplot2 层/主题
```

## 4 Mark 家族（43）

所有标准 mark 共享签名：

``` r
mark_<type>(plot, mapping = NULL, data = NULL, position = NULL,
            ..., rasterize = FALSE,
            rasterize_dpi = 300, rasterize_dev = "cairo")
```

| 共享参数    | 默认    | 说明                                    |
|:------------|:--------|:----------------------------------------|
| `mapping`   | `NULL`  | 图层级 `encode(...)`；缺省继承全局映射  |
| `data`      | `NULL`  | 图层数据；关系图可传 `~table` 公式      |
| `position`  | `NULL`  | 显式 position；缺省按全局 dodge 自动    |
| `...`       | —       | 透传底层 `geom_*`                       |
| `rasterize` | `FALSE` | `ggrastr` 栅格化（复合/关系 mark 除外） |

### 4.1 基础几何（19）

`mark_point` / `mark_line` / `mark_area`（ymin/ymax 自动路由） /
`mark_bar`（宽 0.7、白发丝边框） / `mark_rect` / `mark_polygon` /
`mark_text`(repel=) / `mark_label`(repel=) / `mark_rule`(color=,
数据段模式) / `mark_path` / `mark_histogram`(bins=) / `mark_density` /
`mark_boxplot` / `mark_violin` / `mark_step`(direction=vh/hv/mid) /
`mark_rug`(sides=, length=) / `mark_spoke` / `mark_curve`(curvature=,
angle=) / `mark_image`(size=, clip=, interpolate=)

### 4.2 统计（10）

`mark_smooth`(method/span 透传) / `mark_hex`(bins=) /
`mark_density_2d`(filled=) / `mark_corr`(method=, reorder=, range=) /
`mark_count` / `mark_bin2d`(bins=, binwidth=) / `mark_contour`(filled=,
bins=, breaks=) / `mark_ecdf`(n=) / `mark_qq`(distribution=) /
`mark_qq_line`(distribution=)

### 4.3 复合语法糖（5）

`mark_significance`(comparisons=, y_position=, y_offset=) /
`mark_errorbar`(stat=, level=, ci_method=, caps=) /
`mark_lollipop`(ref=) / `mark_dumbbell` / `mark_forest`(ref=) /
`mark_ribbon`(stat=, level=)

### 4.4 关系（8）

`mark_sankey` / `mark_treemap` / `mark_network`(edges=,
edge_shape=straight/curved) / `mark_chord` —— 四者共享
`node_color`/`edge_color`/`edge_width`/`edge_alpha`/`show_labels` 词汇；
`mark_beeswarm`（碰撞检测） / `mark_encircle`(shape=hull/ellipse) /
`mark_heatmap`(cluster=, scale=, range=, show_numbers=)

## 5 Scale 家族（8）

``` r
scale_<aes>(plot, name = waiver(), trans = <默认>, limits = NULL,
            range = NULL, breaks = NULL, labels = NULL, ...)
```

| 族 | 默认 trans | range 语义 |
|:---|:---|:---|
| `scale_x`/`scale_y` | identity | 面板占比（Vega `range:[0,w]`） |
| `scale_color`/`scale_fill` | 自动 | 离散→friendly，连续→viridis；方案名白名单 20 |
| `scale_size`/`scale_alpha` | 自动 | 数值输出域，默认 `c(1,6)`/`c(0.1,1)` |
| `scale_shape`/`scale_linetype` | discrete | 形状编号/线型名 |

color/fill 额外扩展参数：`na_color=`、`n_bins=`（转
binned）、`mid=`（发散锚点）。 `trans`
合法矩阵：identity/log/log10/log2/sqrt/reverse/discrete/binned（按美学期过滤）。
Date/POSIXct 列自动路由日期轴（T9.1，显式 identity 会告警）。
离散变量＋顺序方案名自动告警（T5.3）。

## 6 关系数据与布局（7 layout + as_graph）

``` r

as_graph(data, source, target, value, nodes)   # 收编为命名表集合
layout_force(plot, iterations, seed, weights)  # Fruchterman-Reingold，seed 必填
layout_circle(plot, order_by = c("id", "degree"))
layout_tree(plot, direction, leaf_spacing, edge = c("straight", "elbow"))
layout_dendrogram(plot, direction)
layout_chord(plot, inner_radius, pad_angle, curvature, order_by)
layout_sankey(plot, node_width, padding, curvature, n_points, max_sweeps)
layout_treemap(plot)
```

布局是数据变换：坐标烘焙进 `@graph` 子表，mark 以 `data=~table` 引用。

## 7 Project 家族（4）

`project_cartesian(xlim, ylim, expand, flip, fixed, coord_trans, clip)`
/
`project_polar(theta, start, end, direction, inner_radius, r_axis_inside, clip, reverse, rotate_angle)`
/
`project_parallel(columns, group, scale=std/global/none, order, recenter, aggregate, alpha=0.2)`
/ `project_map(projection, xlim, ylim, clip)`

极坐标轴预算由包统一管理（T1.1）：全模式清轴、边框守卫、渲染路径防复活。

## 8 Split 家族（2）

`split_wrap(plot, ..., nrow, ncol, scales, dir)` —— 无名参数＝分面变量；
`split_grid(plot, ..., rows, cols, scales, space, axes)` —— 支持
`rows ~ cols` 公式。 分面变量与 colour/fill
相同时自动隐藏冗余图例（T2.4）。

## 9 Label 家族（5）

三参数协议：`reset` \> `hide` \> `text`。

`label_title(text, hide, reset)` / `label_subtitle` / `label_caption` /
`label_axis(text, aes=x/y, hide, reset)` /
`label_legend(text, aes, hide, reset)`（`aes=NULL`＝全局）。

## 10 主题、导出、组合、扩展

``` r

style(plot, ..., base_size, base_family, base_theme)
export(plot, filename, width, height, dpi = 300, device)
compose_grid(..., ncol, nrow, byrow, widths, heights,
             guides = "collect", axes, axis_titles, design, tag_levels)
compose_marginal(main, top, right, widths = c(4,1), heights = c(1,4), guides, align)
compose_annot(base, top, bottom, left, right, heights, widths, gap, guides, align)
compose_inset(base, inset, left, bottom, right, top, align_to, on_top, ...)
make_mark(name, geom_fun)
make_theme(name, ..., base_theme = ggplot2::theme_minimal)
```

## 11 命名与错误 UX 公约

- 动词前缀：`mark_`/`scale_`/`project_`/`split_`/`label_`/`compose_`/`layout_`；单动词单义；
- color/colour 等价接受，函数名统一美式；
- 主动校验点用
  [`cli::cli_abort`](https://cli.r-lib.org/reference/cli_abort.html)
  三段式（问题→原因→对策含合法值）， 经 `._abort_*/._warn_*`
  构造器收敛（SM7）；
- 静默吞参视为缺陷：不可用参数给出定向警告或报错（D-19/T5.2/T6）。

## 下一步

→ [Gallery
System](https://zorrooz.github.io/plotit/articles/gallery-system.md)：每个
API 的 usage 管道链索引（无渲染图）。
