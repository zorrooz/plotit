# plotit 开发约定

## 1. 设计原则

### 1.1 核心价值

- **简化语法**：动词前缀命名（`mark_*`、`scale_*`、`project_*` 等），支持管道。
- **默认美观**：预设主题、配色与尺寸，开箱即出版/报告可用。
- **一致性**：统一的 API 风格、参数命名和错误处理策略。
- **可扩展性**：基于 ggplot2 及其扩展包构造，通过 `...` 透传底层能力，不作过度封装。
- **Mark 多样性**：对标 **Vega-Lite** / **AntV-G2** 的视觉通道丰富度，超越原生 ggplot2 几何图层类型范围。已实现 27 种 mark 类型（§3.2），覆盖基础几何、分布展示、关系层次和地理空间四大领域。
- **默认美观与低配置成本**：调色板（离散/连续/定性）精心选择并持续扩展。`scale_*` 的 `range` 参数保持 `"scheme_name"` 字符串接口简便性，用户无需掌握色彩理论即可产出出版可用图表。
- **最小化实现**：能用已有原语组合实现的图表效果，不新增 mark。mark 是语法糖的最终边界——之前所有组合（mark + project + scale + split）都应该是有效的管道链。新增 mark 的唯一理由是无法用已有原语在合理管道内表达该视觉形态。

### 1.1a 组合优先原则

> **核心规则**：如果一个视觉效果可以通过 `mark_* + project_* + scale_* + split_*` 的管道组合实现，则**不新增 mark 类型**。
>
> **判断流程**：
> 1. 目标视觉效果能否通过已有 mark + project 组合实现？
> 2. 该组合能否保持在单条管道链内（`data |> plotit(encode(...)) |> mark_*(...) |> project_*(...) |> ...`）？
> 3. 如果能 → 在 README/recipes 中提供组合示例，不新增 mark
> 4. 如果不能（需要外部布局算法 / 非 ggplot2 原生渲染 / 新型数据表达）→ 考虑新增 mark
>
> **典型例子**：
> - `mark_arc`（饼图/环形图/玫瑰图）→ **删除**。等价于 `mark_bar() |> project_polar(inner_radius = ...)`，不新增
> - `mark_beeswarm` → **保留**。需要 `ggbeeswarm` 的碰撞检测排列算法，无法用已有 mark 模拟
> - `mark_violin` → **保留**。`geom_violin` 的核密度估计形状无法由 `mark_area` 等价表达
>
> **组合收录**（§3.2b）：有价值的组合模式在约定中作为 recipe 记录，包含等价的 mark-free 管道示例。

### 1.2 元数据集中管理

所有图表配置（尺寸、autofit、单位、dodge 宽度、default_color、标签文本等）统一存储于 `meta` 组件。

`label_*` 写入 `meta@labels` 并标记 dirty（惰性模式），不立即修改 `gg`。通过 `._sync_labels()` 在 `print()`/`export()` 时统一将 `meta@labels` 同步到 `gg$labels` 和 theme。直接操作 `plot@gg` 绕过 label 函数会导致 `meta$labels` 过时。

### 1.3 分域验证

- **包层自定义约束** → `cli::cli_abort`：`encode()` 类检查、`size_unit` 合法性、`autofit` 与 `width`/`height` 关联约束
- **透传底层通用参数** → 交由 ggplot2 / grDevices 自然报错，包层不添加冗余验证

### 1.4 契约分层

| 层级 | 稳定性 | 内容 |
|------|--------|------|
| 核心契约 | 1.0 后主版本稳定 | 函数名（`plotit`、`encode`、`mark_*`、`scale_*`、`label_*`、`compose_*`、`style`、`export`）、返回类型 `plotit` 支持管道、`plotit()` 的 `data` 和 `mapping` 参数；mark 的 `data` 参数接受 data.frame / `~table` 公式（兼容扩展） |
| 扩展契约 | 2.0 可调整 | `scale_*` 的 `trans` 合法值集合（可增加不删除）、`label_*` 参数协议（`text`/`hide`/`reset`）、`project_*`/`split_*` 参数签名、关系数据体系（`as_graph()`、`layout_*`、`transform_corr()`、`plotit_graph`、`@graph` 槽） |
| 可迭代 | 不破坏上述两层 | 默认主题参数、启发式算法、默认调色板、内部工具函数实现 |

例外：1.x 期间发现扩展契约中的设计缺陷允许经弃用→警告→移除周期（跨至少一个次版本）修正，不视为破坏性变更。

### 1.5 自动生成不手动维护

| 自动 | 手动 |
|---|---|
| `NAMESPACE`（roxygen2 `@export`）、`man/*.Rd`（roxygen2）、DESCRIPTION Collate（`@include`） | `R/*.R` 源码、`tests/`、DESCRIPTION 元信息 |

新建 `.R` 文件头部必须用 `@include` 声明内部依赖。每次增删文件或修改 roxygen 注释后执行 `roxygen2::roxygenize()`。

### 1.6 约定文档动态更新

实现与约定偏离时：判断偏离方向——实现改进则修约定，实现退化则修实现。以下情况必须同步更新：新增/删除/修改导出函数、修改参数签名或默认值、修改返回类型或管道行为、修改契约分层、引入/废止设计原则。

### 1.7 临时脚本与工作区清洁

- 审查、验证、调试等一次性用途的临时脚本应写入忽略目录（如 `.reasonix/`）或系统临时目录，**不写入根目录**。
- 临时脚本运行完成后**必须手动清理**（删除文件本身），不得保留在仓库中；结论应提炼写入正式文档（如 `CODE_REVIEW.md`、`NEWS.md`）而非依赖脚本留存。
- 运行测试/示例产生的垃圾产物（`Rplots.pdf`、`*.svg` 等）应及时删除，保持根目录清洁。

---

## 2. 技术选型

- **OOP**：**S7**。核心类：`plotit_labels`（文本字段）、`plotit_metadata`（配置项）、`plotit`（持有 `gg` + `meta`）。若 S7 发生不兼容变更，锁定版本或评估迁移至 S3/R6。
- **核心依赖**：ggplot2、S7、cli、rlang、patchwork。`ggrastr` 为可选增强（图层栅格化）。
- **可选依赖**（Suggests，按 mark 按需加载）：ggrepel、ggbeeswarm（唯一保留外部算法的关系类 mark：碰撞检测排列）、tidygraph（仅 `as_graph()` 收编 tbl_graph 输入）、hexbin、sf、mapproj、ggrastr、knitr、rmarkdown。（ggsankey/ggraph/circlize 已于关系数据体系改造中退役；igraph 已随力导向/树布局自研而移除；treemapify 已随 mark_treemap 原生化而移除：sankey/network/chord/treemap/tree/dendrogram 均为 `layout_*` 自研引擎 + 原语图层语法糖。）

---

## 3. API 约定

### 3.1 函数族总览

**内层**（单图管道，从数据构建一个图表）：

| 函数族 | 职责 | ggplot2 对应 |
|---|---|---|
| `plotit()` | 初始化 | `ggplot()` |
| `encode()` | 美学映射 | `aes()` |
| `mark_*` | 几何图层 | `geom_*` |
| `scale_*` | 数据→视觉映射 + 显示控制 | `scale_*`（Vega 四要素：`type`/`domain`/`range`/`scheme` → `trans`/`limits`/`range`/`name`） |
| `layout_*` | 关系图布局变换（坐标烘焙进数据，非图层） | ggplot2 无对应（Vega transform 模式） |
| `project_*` | 坐标系变换 | `coord_*` |
| `split_*` | 分面布局 | `facet_*` |
| `label_*` | 文本标签 | `labs()` + `theme()` |
| `style()` | 主题 | `theme()` |
| `export()` | 图表导出 | `ggsave()` |

**最外层**（多图组合，操作 `plotit` 对象而非数据）：

| 函数族 | 职责 |
|---|---|
| `compose_*` | 组装多个 `plotit` 为多面板布局；返回 `plotit_composite`，支持 `label_title`/`label_subtitle`/`label_caption`/`style`/`export` 管道延续 |

单图函数（`mark_*`/`scale_*`/`project_*`/`split_*`/`label_axis`/`label_legend`）不接受 `plotit_composite`——先分别构建各子图，最后用 `compose_*` 组合。

### 3.2 `mark_*` 目录

对标 Vega-Lite / AntV-G2 的视觉通道丰富度，不限于 ggplot2 原生几何。
新 mark 按需引入，遵循统一 S7 泛型+方法模式（`mark_<type>` + `geom_<底层>`）。标准/统计 mark 支持 `rasterize`；复合与关系类 mark 不接受（§3.3b 原则 3）。

**已实现**（27）：

| 函数 | 对应 | 用途 |
|---|---|---|
| `mark_point` | `geom_point` | 散点 ✅ |
| `mark_line` | `geom_line` | 折线/趋势 ✅ |
| `mark_bar` | `geom_bar`/`geom_col` | 柱状图 ✅ |
| `mark_boxplot` | `geom_boxplot` | 箱线图 ✅ |
| `mark_histogram` | `geom_histogram` | 直方图 ✅ |
| `mark_density` | `geom_density` | 密度曲线 ✅ |
| `mark_area` | `geom_area` | 面积图 ✅ |
| `mark_text` | `geom_text`/`geom_text_repel` | 文本标签 ✅ |
| `mark_violin` | `geom_violin` | 小提琴图 ✅ |
| `mark_map` | `geom_sf` | 地图 ✅ |
| `mark_rect` | `geom_tile` | 矩形/热力图 ✅ |
| `mark_rule` | `geom_hline/vline/abline/segment` | 参考线/参考区域 ✅ |
| `mark_path` | `geom_path` | 路径/轨迹 ✅ |
| `mark_polygon` | `geom_polygon` | 多边形 ✅ |
| `mark_smooth` | `geom_smooth` | 回归平滑+置信带 ✅ |
| `mark_hex` | `geom_hex` | 2D 六边形热力图 ✅ |
| `mark_density_2d` | `geom_density_2d`/`geom_density_2d_filled` | 2D 密度等高线 ✅ |
| `mark_corr` | `transform_corr()` + `geom_tile` 语法糖 | 相关性矩阵热力图 ✅ |
| `mark_errorbar` | `geom_errorbar`/`geom_errorbarh` | 误差棒 ✅ |
| `mark_significance` | `mark_rule` + `mark_text` 语法糖 | 显著性标记 ✅ |
| `mark_lollipop` | `mark_point` + 线段语法糖 | 棒棒糖图 ✅ |
| `mark_dumbbell` | `mark_point`×2 + 线段语法糖 | 哑铃对比图 ✅ |
| `mark_beeswarm` | `ggbeeswarm::geom_beeswarm` | 蜂群散点 ✅ |
| `mark_sankey` | `layout_sankey()` + polygon/rect 语法糖（edges-table API） | 桑基流向图 ✅ |
| `mark_treemap` | `layout_treemap()` + rect/text 语法糖（自研 squarify） | 矩形树图 ✅ |
| `mark_network` | `layout_force/circle()` + point/rule 语法糖（nodes+edges 双数据源） | 力导向网络图 ✅ |
| `mark_chord` | `layout_chord()` + polygon 语法糖（edges-table API） | 弦图 ✅ |

#### Vega-Lite vs AntV G2 复合 Mark 全量对比

Vega-Lite 和 AntV G2 采用不同策略处理统计/复合 Mark，plotit 取两者之长：

| 引擎 | 基础 Mark 数量 | 复合/统计 Mark 策略 | 典型复合 Mark |
|---|---|---|---|
| **Vega-Lite** | 11 原语 (`area`/`bar`/`line`/`point`/`rect`/`rule`/`text`/`tick`/`circle`/`square`/`geoshape`) | 3 个复合 Mark 宏观展开为多层原语 | `boxplot`(5 层)、`errorbar`(2 层)、`errorband`(2 层) |
| **AntV G2 5.0** | 24 基础 (corelib) | 3 层库体系：基础→统计(3)→复合(10) | `boxplot`/`gauge`/`liquid`(plotlib) + `sankey`/`treemap`/`chord`/`forceGraph` 等(graphlib) |
| **plotit** | 27 已实现（14 基础 + 4 统计 + 9 复合） | **三层体系**：基础 Mark → 统计 Mark → 复合 Mark（语法糖）+ 关系类 | 见下表 |

G2 的每个复合 Mark 内部展开为 2-5 个基础 Mark 的组合，这与 plotit "组合优先"原则一致。参考两方经验，plotit 新增两类：

- **统计 Mark**：对标 Vega-Lite 复合 Mark (`boxplot`/`errorbar`/`errorband`)的统计聚合能力 + G2 corelib 的 `density`/`heatmap`/`beeswarm`
- **复合 Mark**：对标 Vega-Lite `layer` 运算符和 G2 graphlib/plotlib 的组合模式，封装 2+ 已有 Mark 的固定搭配

**完整规划**（27 种，对标 Vega-Lite 15+ 种 + AntV G2 30+ 种，三层体系：基础 → 统计 → 复合；已全部实现）：

| # | 层级 | 函数 | 类别 | 底层 R 实现 | 对标来源 | 用途 |
|---|---|---|---|---|---|---|
| | **第一层：基础 Mark** | | | | | |
| 1 | 基础 | `mark_point` | 几何 | `geom_point` | VL `point`/G2 `point` | 散点/气泡 ✅ |
| 2 | 基础 | `mark_line` | 几何 | `geom_line` | VL `line`/G2 `line` | 折线/趋势 ✅ |
| 3 | 基础 | `mark_area` | 几何 | `geom_area`/`geom_ribbon` | VL `area`/G2 `area` | 面积图/堆叠面积 ✅ |
| 4 | 基础 | `mark_bar` | 几何 | `geom_bar`/`geom_col` | VL `bar`/G2 `interval` | 柱状/条形图 ✅ |
| 5 | 基础 | `mark_rect` | 几何 | `geom_tile`/`geom_rect` | VL `rect`/G2 `cell` `rect` | 矩形/热力图单元格 ✅ |
| 6 | 基础 | `mark_polygon` | 几何 | `geom_polygon` | G2 `polygon` | 多边形/自定义形状 ✅ |
| 7 | 基础 | `mark_text` | 几何 | `geom_text`/`ggrepel` | VL `text`/G2 `text` | 文本标签/数据标注 ✅ |
| 8 | 基础 | `mark_rule` | 几何 | `geom_hline`/`geom_vline`/`geom_abline`/`geom_segment` | VL `rule`/G2 `lineX` `lineY` `rangeX` `rangeY` | 参考线/参考区域/误差线 ✅ |
| 9 | 基础 | `mark_path` | 几何 | `geom_path` | G2 `path` | 路径/轨迹 ✅ |
| 10 | 基础 | `mark_histogram` | 分布 | `geom_histogram` | VL `bar`(binned) | 直方图 ✅ |
| 11 | 基础 | `mark_density` | 分布 | `geom_density` | G2 `density` | 1D 核密度曲线 ✅ |
| 12 | 基础 | `mark_boxplot` | 分布 | `geom_boxplot` | VL `boxplot`/G2 `boxplot` | 箱线图 ✅ |
| 13 | 基础 | `mark_violin` | 分布 | `geom_violin` | G2 `density`(violin) | 小提琴图 ✅ |
| 14 | 基础 | `mark_map` | 地理 | `sf`+`geom_sf` | VL `geoshape`/G2 `geoPath` | 地图/地理空间 ✅ |
| | **第二层：统计 Mark** | | | | | |
| 15 | 统计 | `mark_smooth` | 统计 | `geom_smooth` | VL: layer组合/G2: transform | 回归平滑+置信带 ✅ |
| 16 | 统计 | `mark_hex` | 统计 | `geom_hex` | G2 `heatmap`(corelib) | 2D 六边形分箱热力图 ✅ |
| 17 | 统计 | `mark_density_2d` | 统计 | `geom_density_2d`/`geom_density_2d_filled` | G2 `density`(contour) | 2D 密度等高线 ✅ |
| 18 | 统计 | `mark_corr` | 统计 | `geom_tile` + corr预处理 | G2 `cell`(相关性矩阵) | 相关性矩阵热力图 ✅ |
| | **第三层：复合 Mark** | | | | | |
| 19 | 复合 | `mark_significance` | 标注 | `mark_rule` + `mark_text` 语法糖 | VL: layer组合 | 显著性标记（括号+星号） ✅ |
| 20 | 复合 | `mark_errorbar` | 标注 | `geom_errorbar`/`geom_errorbarh` 包装 | VL `errorbar`(复合Mark) | 误差棒 ✅ |
| 21 | 复合 | `mark_lollipop` | 图表 | `mark_point` + `mark_line` 语法糖 | — | 棒棒糖图 ✅ |
| 22 | 复合 | `mark_dumbbell` | 图表 | `mark_point`×2 + `mark_line` 语法糖 | G2 `link`(corelib) | 哑铃对比图 ✅ |
| | **第三层（关系）** | | | | | |
| 23 | 复合 | `mark_beeswarm` | 分布 | `ggbeeswarm::geom_beeswarm` | G2 `beeswarm`(corelib) | 蜂群散点（碰撞检测） ✅ |
| 24 | 复合 | `mark_sankey` | 关系 | `layout_sankey()` + polygon/rect 语法糖（edges-table API） | G2 `sankey`(graphlib) | 桑基流向图 ✅ |
| 25 | 复合 | `mark_treemap` | 关系 | `layout_treemap()` + rect/text 语法糖（自研 Bruls squarify） | G2 `treemap`(graphlib) | 矩形树图 ✅ |
| 26 | 复合 | `mark_network` | 关系 | `layout_force/circle()` + point/rule 语法糖（nodes+edges 双数据源） | G2 `forceGraph`(graphlib) | 力导向网络图 ✅ |
| 27 | 复合 | `mark_chord` | 关系 | `layout_chord()` + polygon 语法糖（edges-table API） | G2 `chord`(graphlib) | 弦图 ✅ |

**三层判断规则**：

| 层级 | 可以新增 | 不可新增 |
|---|---|---|
| **基础 Mark** | 底层 `geom` 没有 plotit 封装，通过 `._register_mark_method` 标准化 | 已有 Mark 能表达；或纯坐标/分面变化效果 |
| **统计 Mark** | `geom+stat` 自带非平凡算法（回归/KDE/分箱），对标 VL 复合Mark 或 G2 统计Mark | 单纯 `stat_summary()` → 用户可直接 `mark_point(stat="summary")` |
| **复合 Mark** | 2+ 已有 Mark 的固定组合模式，显著减少 3+ 层管道，必须标注"语法糖"并在文档注明等价展开 | 组合仅用于一次 edge case、或 `scale_*`/`project_*` 可替代 |

> **组合优先移除的 mark**（3 个）：
> - ~~`mark_arc`~~（饼图/环形图/玫瑰图）→ `mark_bar() |> project_polar(inner_radius = ...)`，见 §3.2b
> - ~~`mark_tick`~~（一维分布 strip plot）→ `mark_point() |> project_cartesian(expand = ...)` + `position_jitter()` 或 `geom_rug` 可通过 `scale_x/y(position=)` 替代
> - ~~`mark_tree`~~（树图/冰柱图/旭日图）→ `mark_rect` + 层次树数据预处理 + `split_*` 分面可表达冰柱图；旭日图回退到 `mark_bar() |> project_polar()` 的极坐标层次表达

### 3.2b 组合 Recipes

按组合优先原则，以下视觉形态不新增 mark，通过已有原语组合实现：

#### 饼图 / 环形图 / 玫瑰图（替代 `mark_arc`）

```r
# 饼图 — mark_bar + project_polar
data |> plotit(encode(theta = count, colour = category)) |>
  mark_bar(position = "stack", width = 1) |>
  project_polar(theta = "y")

# 环形图 — 加 inner_radius
data |> plotit(encode(theta = count, colour = category)) |>
  mark_bar(position = "stack", width = 1) |>
  project_polar(theta = "y", inner_radius = 0.4)

# 玫瑰图 / 南丁格尔玫瑰图 — 无堆叠 + project_polar
data |> plotit(encode(x = category, y = value)) |>
  mark_bar(width = 1) |>
  project_polar()
```

#### 一维分布 strip plot（替代 `mark_tick`）

```r
# Strip plot — mark_point + position_jitter
data |> plotit(encode(x = category, y = value)) |>
  mark_point(position = "jitter", alpha = 0.5, size = 1.5)

# Rug — 用 ggplot2::geom_rug 通过 mark 的 ... 透传
# （若需要，可封装为 mark_rug，但属于 theme 辅助非核心 mark）
```

#### 雷达图

```r
# 雷达图 — mark_line + project_polar
data |> plotit(encode(x = variable, y = value, colour = group)) |>
  mark_line() |>
  project_polar()
```

#### 树图 / 冰柱图（替代 `mark_tree`）

```r
# 冰柱图 — mark_bar + 层次树数据预处理
# prepared_data |> plotit(encode(x = level, y = size, fill = category)) |>
#   mark_bar(position = "stack") |>
#   split_wrap(top_level_var, scales = "free_x")
# 注：需要上游数据预处理将层次树展平为矩形数据

# 旭日图 — mark_bar + project_polar（等价于环形图的分层版）
# prepared_data |> plotit(encode(theta = size, fill = category)) |>
#   mark_bar(position = "stack") |>
#   project_polar(theta = "y") |>
#   split_wrap(top_level_var)
```

#### 径向树

```r
# 径向树 — layout_tree("right") 的 x=深度、y=叶子序，经 project_polar 映射为半径/角度
h <- data.frame(id = c("root","A","B","a1","a2"),
                parent = c(NA,"root","root","A","A"))
as_graph(h) |> plotit() |>
  layout_tree(direction = "right") |>
  mark_rule(data = ~edges) |>
  mark_point(data = ~nodes) |>
  project_polar(theta = "y")
```

### 3.2c 主流关系图表类型对照

对标 ECharts 5 / AntV G6·G2(graphlib) / D3 v7(hierarchy/chord/force) / Plotly / Vega-Lite：

| 类型 | ECharts | D3 | Plotly | Highcharts | G6/G2 | plotit |
|---|---|---|---|---|---|---|
| 力导向网络 | graph(force) | d3-force | 手工散点 | networkgraph | force/GForce | ✅ 自研 `layout_force` |
| 环形网络 | graph(circular) | — | — | — | circular/radial | ✅ `layout_circle` |
| 正交树 | tree(orthogonal) | tree/cluster | — | orgchart | dagre/mindmap | ✅ `layout_tree` |
| 径向树 | tree(radial) | 旋转组合 | — | — | radial | 🧩 recipe（tree+polar，§3.2b） |
| 树状图 | cluster | cluster | — | — | dendrogram | ✅ `layout_dendrogram` |
| 桑基 | sankey | d3-sankey(插件) | sankey | sankey | G6 流向 | ✅ 自研 `layout_sankey` |
| 弦图/依赖环 | —（graph 变体） | d3-chord | — | dependencywheel | arc(v5) | ✅ 自研 `layout_chord`（依赖环=chord 特例） |
| 矩形树图 | treemap | treemap | treemap | treemap | G2 treemap | ✅ 自研 `layout_treemap` |
| 旭日 sunburst | sunburst | partition(+arc) | sunburst | sunburst | — | 🧩 recipe（bar+polar 分层，§3.2b） |
| 冰柱 icicle | —（sunburst 变体） | partition | icicle | icicle(v11) | — | 🧩 recipe（rect 层次预处理 + split） |
| 气泡填充 pack | — | pack | — | — | — | ⏳ `layout_pack` 显式延期（可自研简单 place 算法） |
| 平行类别 alluvial | themeRiver | — | parcats | — | — | ➖ 超出核心关系域（多元类别流） |

结论：核心关系域（网络/树系/流/环/层次矩形）**全覆盖且零外部依赖**（beeswarm 为约定豁免）；旭日/冰柱/径向树按组合优先原则以 recipe 收录而非新增 mark；唯一缺口是气泡填充 pack，已显式延期并标注可自研。
### 3.3 函数签名概要

#### 3.3.1 `plotit()` — 初始化

```
plotit(data, mapping = encode(), autofit = FALSE,
       width = 5, height = 3.5, size_unit = "in",
       dodge = NULL, default_color = "#4E79A7")
```

- `width`/`height`：紧凑学术画布（面板 5×3.5in）。烘焙 WYSIWYG 后含轴/图例的总足迹 ≈6.6in，装进 pkgdown/knitr/RStudio 全部标准设备不截断
- `size_unit`：`"in"`/`"cm"`/`"mm"`，始终验证合法性，不受 `autofit` 影响
- `dodge`：NULL 时离散 X/Y 自动设为 0.8（有离散映射才设，否则 0）
- `default_color`：无 `colour`/`fill` 映射时同时注入两侧 + `guides(colour="none", fill="none")`。添加任何 colour/fill scale 后自动失效。清除逻辑统一为 `._clear_default_color()`（`utils.R`），调用点：统一 mark 路径（`._mark_impl`）、手写 mark（`mark_map`/`mark_corr`/`mark_treemap`/`mark_sankey`）、`scale_color`/`scale_fill`、`project_parallel`（见 §3.3.4）。

**尺寸优先级链**：显式传参 > meta 存储 > autofit 自适应。

#### 3.3.2 `encode()` — 美学映射

`encode(...)` 全部透传给 `aes()`，返回 `"plotit_encode"` 类。包层做类检查。

#### 3.3.3 `mark_*` — 几何图层

`mark_<type>(plot, mapping=NULL, data=NULL, position=NULL, ..., rasterize=FALSE, rasterize_dpi=300, rasterize_dev="cairo")`

- 第一参数 `plot`，返回 `plotit`
- `mapping`、`data`、`position`：`data=NULL` 继承全局数据；`position=NULL` 自动读取全局 dodge
- `...` 透传底层 `geom_*`
- `rasterize` 需 `ggrastr`
- 内部通过 `._mark_impl()` 共享逻辑：resolve position、构建 geom、条件栅格化
- **签名特例**（按 §3.3b 三层体系）：复合 Mark `mark_significance`/`mark_lollipop`/`mark_dumbbell` 无 `position`/`rasterize`（内层 Mark 各自处理）；关系类 `mark_sankey`/`mark_chord` 无 `rasterize`；统计 Mark `mark_corr` 无 `mapping`/`data`/`position`（自算相关性矩阵）；`mark_network` 用专用双数据源签名（`edges`/`encode_edges`）

#### 3.3.3a `make_mark()` / `make_theme()` — 用户可扩展工厂

plotit 暴露两个工厂函数，允许用户在不修改包源码的情况下自定义 Mark 和 Theme：

**`make_mark(name, geom_fun)`** — 创建自定义 Mark

```r
make_mark <- function(name, geom_fun) {
  # name: 字符，Mark 名（如 "mark_spoke"）
  # geom_fun: ggplot2 geom 函数（如 ggplot2::geom_spoke）
  # 返回: 注册 S7 泛型 + 方法，全局可用
}

# 示例：创建 mark_spoke（径向线段图）
make_mark("mark_spoke", ggplot2::geom_spoke)
# 现在可以在管道中使用：
# df |> plotit(encode(x=x, y=y, radius=r, angle=a)) |> mark_spoke()
```

- 自动注册 S7 泛型 + 方法（与内置 Mark 共享 `._register_mark_method`）
- 支持 `rasterize` 参数（与内置 Mark 一致）
- `name` 必须 `mark_` 前缀；否则 `cli::cli_warn`
- 不写入 NAMESPACE（在用户命名空间中注册）

**`make_theme(name, ..., base_theme)`** — 创建自定义 Theme 预设

```r
make_theme <- function(name, ..., base_theme = ggplot2::theme_minimal) {
  # name: 字符，函数名（如 "style_dark"）
  # ...: ggplot2::theme() 元素
  # base_theme: 基础主题（默认 theme_minimal）
  # 返回: 创建并注册的函数到调用者环境
}

# 示例：暗色主题
style_dark <- make_theme("style_dark",
  plot.background = ggplot2::element_rect(fill = "#1a1a1a"),
  text = ggplot2::element_text(colour = "white"))
# df |> plotit(encode(...)) |> mark_point() |> style_dark()
```

- 函数创建到调用者环境（`parent.frame()`）
- 与内置 `style()` 相同签名：`function(plot, base_size=NULL, base_family=NULL)`
- 返回修改后的 plotit 对象

**设计理由**：
- Vega-Lite/G2 均支持自定义 Mark 注册（VL 的 `config.mark` 扩展、G2 的 `Chart.register`），plotit 的 `make_mark` 与之对齐
- 避免用户深入 S7 泛型注册细节
- 自定义 Mark 与内置 Mark 行为完全一致（position 解析、栅格化等共享逻辑）

#### 3.3.3b 统计 Mark 与 复合 Mark 详细约定

**第二层：统计 Mark（封装 geom + stat）**

这些 Mark 的底层 `geom` 自带统计算法，对标 Vega-Lite 的复合 Mark（`boxplot`/`errorbar`/`errorband`）和 G2 corelib 的统计 Mark（`density`/`heatmap`/`beeswarm`）：

| 统计 Mark | 自带算法 | Vega-Lite 对标 | G2 对标 | 输入 | 输出 |
|---|---|---|---|---|---|
| `mark_smooth` | `stat_smooth`（loess/lm/glm/gam） | 无原生，需 `layer` 组合 `point` + `line` + `transform(regression)` | 无原生，需 transform | x, y | 回归线 + 置信带 |
| `mark_hex` | `stat_bin_hex`（2D 六边形分箱） | 无原生，需 `rect` + `transform(bin2d)` | `mark.heatmap`(corelib) | x, y | 六边形计数/聚合网格 |
| `mark_density_2d` | `stat_density_2d`（2D KDE） | 无原生，需 `line` + `transform(density2d)` | `mark.density`(corelib, contour) | x, y | 密度等高线 |
| `mark_corr` | `geom_tile` + 内部 corr 预处理 | 无原生，需 `rect` + 外部计算 | `mark.cell`（相关性矩阵表达式） | 数值矩阵/df | 重新排序的相关矩阵热力图 |

**第三层：复合 Mark（语法糖，组合已有 Mark）**

这些 Mark **不引入新 geom**，内部组合 2+ 已有 Mark 和用户提供的注释数据：

| 复合 Mark | 展开等价管道 | 对标来源 | 典型参数 |
|---|---|---|---|
| `mark_significance` | `mark_rule(x=x, xend=x2, y=y, yend=y)` + `mark_text(x=mid(x,x2), y=y+offset, label=sig)` | Vega-Lite: layer(bar+rule+text) 社区惯用模式 | `comparisons`(data.frame，含 `group1`/`group2`/`label` 列), `y_position`, `y_offset` |
| `mark_errorbar` | `geom_errorbar`/`geom_errorbarh` 包装 | Vega-Lite `errorbar`（3大复合Mark 之一） | `width`, `orientation` |
| `mark_lollipop` | `mark_rule(x=x, xend=x, y=ref, yend=y)` + `mark_point(x=x, y=y)`（`ref` 默认 0） | 无直接对标 | `stem_colour`, `stem_width`, `point_size`, `ref` |
| `mark_dumbbell` | `mark_rule(x=x, xend=x, y=y_start, yend=y_end)` + `mark_point(x=x, y=y_start)` + `mark_point(x=x, y=y_end)` | G2 `mark.link` | `colour_start`, `colour_end`, `line_colour` |

**复合 Mark 实现原则**：
1. 必须在文档中注明等价展开（"该函数等价于 `mark_rule + mark_text` 的组合"）
2. `@export` 但标注为"语法糖"
3. 不接受 `rasterize` 参数（内层 Mark 各自处理）。例外：`mark_errorbar` 直接包装 `geom_errorbar`/`geom_errorbarh`，保留 `rasterize` 支持
4. 返回 `plotit` 对象，可继续链式调用其他函数

**第三层（关系类）：渲染定位**

关系类 mark 中仅 `mark_beeswarm` 引入外部算法（碰撞检测，约定豁免）；其余全部为自研确定性布局引擎 + ggplot2 原语图层：

| mark | 渲染方式 | 定位说明 |
|---|---|---|
| `mark_beeswarm` | `ggbeeswarm` geom | 标准 ggplot2 层；跳过全局自动 dodge（碰撞检测自排布） |
| `mark_sankey` | `layout_sankey()` + `mark_polygon(~ribbons)`/`mark_rect(~nodes)` 语法糖 | 纯 ggplot2 层增量构建；`@graph` 存 nodes/edges/ribbons 三表；确定性分层布局（无外部依赖）；节点填充取首次出现身份，数值 fill 保持 double（#5） |
| `mark_treemap` | `layout_treemap()` 自研 squarify + `mark_rect(~leaves)`/`mark_text(~leaves)` 语法糖 | 纯 ggplot2 层增量构建；`@graph` 存 nodes/edges/leaves 三表；白色发丝分隔 + 无轴画布 + 叶标签；输入层次表（id/parent/value）；treemapify 已退役 |
| `mark_network` | `layout_force/circle()` + point/rule/text 语法糖 | 普通 ggplot2 层**加法式**组合（先前层/scale 全保留）；`@graph` 可供后续 `~nodes/~edges` 引用；直边渲染为已知局限；`linear/bipartite` 弃用回退 force；`weight=` 弃用改 `value=`；`manual` 需节点表自带数值 x/y；边绘制于节点下层，标签悬浮于点上方，`coord_fixed` 保持真实比例 |
| `mark_chord` | `layout_chord()` + `mark_polygon(~ribbons)`/`mark_polygon(~arcs)` 语法糖 | 纯 ggplot2 层增量构建；`@graph` 存 nodes/edges/arcs/ribbons 四表；确定性环形布局（无外部依赖）；重复 (source,target) 对聚合为单带；自环占两个子弧段；`gap_width`(度) 映射布局角距 |

**新增 Mark 判断流程**（更新）：

```
目标视觉效果
├── 能用已有基础 Mark + project_* → 不新增，提供 combination recipe（§3.2b）
├── 能用已有 Mark + scale_*/split_* → 不新增
├── 底层 geom+stat 自带非平凡算法 → 新增「统计 Mark」
├── 2+ 已有 Mark 固定组合，减少 3+ 层管道 → 新增「复合 Mark」（语法糖）
└── 需要外部布局算法 / 非 ggplot2 渲染 → 新增「基础 Mark」（引入新 geom）
```

#### 3.3.3c 统一 Mark 默认样式（style tokens）

所有 mark 的样式字面量集中于 `R/mark_style.R`，单一事实来源：

- **`._MARK_STYLE`（token 表）**：`primary="#4E79A7"`、`secondary="#E15759"`；中性灰阶 `ink`(grey30，强注释：显著性括号/sankey 节点)、`soft`(grey50，中连接线：棒棒糖茎/哑铃连线/参考线)、`faint`(grey70，弱结构：network 边)、`band`(grey80)/`arc`(grey85)（保留 token，chord 已改走 source identity 派生通道不再使用）；线宽阶梯 `lw_data`(0.9，折线/路径/平滑) > `lw_thin`(0.5，细描边/括号/误差棒) > `lw_border`(0.25，柱/tile 白色发丝边框)；注释字号 `txt_note`(3.2)；半透明填充 `alpha_fill`(0.6，density/violin)、连接带 `alpha_link`(0.5，sankey/chord)；复合点径 `point_head`(3)。token 属 §1.4 可迭代层。
- **`._MARK_DEFAULTS`（按 mark 注入的静态默认）**：line/path（linewidth 0.9 + round 端点）、smooth（linewidth 0.9）、bar（白色发丝边框 + width 0.7——槽位 dodge 0.8 下留组间空气，替代 ggplot2 默认 0.9 的拥挤观感）/histogram/rect（白色发丝边框；histogram 相邻 bin 必须贴合故不设 width）、area/polygon（linewidth 0 去描边）、density/violin（alpha 0.6）、rule（colour soft + linewidth thin）、errorbar（linewidth 0.5）、boxplot（瘦箱 width 0.5 + 发丝描边 lw_border + staplewidth 0.4 横须盖 + outlier.size 0.6，tidyplots 校准——槽位 dodge 0.8 下留 ~0.38 组间空隙）、corr/treemap（白色发丝分隔；treemap 经旧式 `size` 通道，geom_treemap 不接受 linewidth）。经 `._mark_impl()` 统一注入，标准 mark 由工厂自动携带 mark 名，手写 mark 显式传 `mark_name=`。
- **合并规则**（`._apply_mark_defaults()`）：**用户显式参数 > 已映射美学（层或全局，含注入的 AsIs 常量）> mark 默认**。因此分组柱状图自动获得白色分隔边框、单色注入柱保持无边框、映射了 alpha 的图层不被默认覆盖。
- **特例**：
  - `mark_boxplot` 在 default_color 注入存活且用户未指定 colour 时自动改用 `ink` 描边（避免蓝底蓝线中位线不可读），见 `._user_owned_aes()` 对 AsIs 注入常量的豁免逻辑；
  - `mark_rule` 标量路径与 annotate 段路径同样只对「用户自有」美学让位（注入常量不渲染在参数型 geom 上，不应阻塞默认值）。
- **Mark 自有/派生通道按语义选板（单一决策点）**：全包所有默认 colour/fill scale 都经由 `theme.R` 的 `._default_colour_scale(aes, data, var)` 单一决策点——**恒等/分组通道（类别列）→ friendly 定性色板；量级通道（数值列）→ viridis 顺序色板**。覆盖三条路径：构造期全局映射（`._attach_default_colour_scale`）、图层映射（`._mark_impl` 自动挂载，仅当 managed 注册表无该通道时，显式关系管道因此与语法糖同板）、Mark 自有派生通道。派生通道语义归属：corr `value`/hex `count`/density_2d `level` 为量级 → viridis；sankey 流带与节点、chord 弧段与缎带、treemap 叶块（均默认 source identity）、network 节点 colour 按列类型路由。managed 追踪经 `attr(meta, "plotit_colour_managed")`（`._colour_managed_get/add/remove`）：`scale_color/scale_fill` 登记用户接管、`._clear_default_color` 注销被清通道。用户之后链式 `scale_*()` 即替换（后执行者胜）。chord 未映射 fill 时不再走灰色 token——与 sankey 同规则默认 source identity 彩色 + 图例。
- **make_mark 自定义 mark**：不在 `._MARK_DEFAULTS` 中时零行为差异。

#### 3.3.4 `scale_*` — 比例尺

设计对标 **Vega/Vega-Lite** 的 scale 模型（`type`/`domain`/`range`/`scheme` → `trans`/`limits`/`range`/`name`）。

`scale_<aes>(p, name=waiver(), trans=<默认>, limits=NULL, range=NULL, breaks=NULL, labels=NULL, ...)`

| 函数 | 默认 `trans` | `NULL` 含义 |
|---|---|---|
| `scale_x`/`scale_y` | `"identity"` | — |
| `scale_color`/`scale_fill` | `NULL` | 自动检测（离散→`discrete`，连续→`identity`） |
| `scale_size`/`scale_alpha` | `NULL` | 同上 |
| `scale_shape`/`scale_linetype` | `"discrete"` | — |

**`trans` 合法矩阵**：

| `trans` | x/y（位置） | colour/fill/size/alpha（视觉连续） | shape/linetype（视觉离散） |
|---|---|---|---|
| `NULL` | → identity | auto-detect | → discrete |
| `"identity"` | ✅ 默认 | ✅ 默认 | ❌ |
| `"log"`/`"log10"`/`"log2"`/`"sqrt"` | ✅ | ❌ | ❌ |
| `"reverse"` | ✅ | ✅ | ✅ |
| `"discrete"` | ✅ | ✅ | ✅ 默认 |
| `"binned"` | ✅ | ✅ | ❌ |

不支持的组合给出 `cli::cli_abort` 定向错误。

**`name` vs `label_*`**：`scale_*(name=)` 设置 scale 层默认名，`label_*` 设置最终显示名——后执行者胜。

**`_cf` 辅助函数**：`._cf(aes, fun_c, fun_f)` 根据 `aes` 是 `colour` 还是 `fill` 选择对应版本 scale 函数，消除 aes 分支样板代码。13 处引用集中于 scale.R。

内部校验矩阵：
```
trans_legal <- list(
  positional   = c("identity", "log", "log10", "log2", "sqrt", "reverse", "discrete", "binned"),
  visual_cont  = c("identity", "discrete", "binned", "reverse"),
  visual_disc  = c("discrete", "reverse")
)
```

**`trans` × `range` 协同**：包层根据组合选择底层 scale 函数。`trans="identity"/"binned"` + `range="viridis"` → `scale_colour_viridis_c/b()`；`trans="discrete"` + `range=c(...)` → `scale_colour_manual()`。

**`range` 语义**（Vega-aligned：视觉输出值域）：

| aesthetic | `range = NULL` | `range = "name"` | `range = c(a, b)` |
|---|---|---|---|
| colour/fill | 离散→friendly，连续→viridis | `"viridis"` `"brewer"` `"grey"`(仅离散) `"friendly"` `"hue"` | 颜色向量 |
| size | `c(1, 6)` | — | 数值范围 |
| alpha | `c(0.1, 1)` | — | 数值范围 |
| shape | 默认形状集 | — | 形状编号 |
| linetype | 默认线型集 | — | 线型名称 |
| x/y | `c(0, 1)`（铺满面板） | — | 归一化面板占比 |

x/y 的 `range` 表示数据在面板上的视觉占比，通过 `limits` + `expand=c(0,0)` 精确实现。

**格式推断**：包层根据输入格式自动判断意图——单字符串→调色板方案，颜色向量→渐变，数值向量→值域，整数向量→形状编号，非颜色字符向量→线型。

**x/y 的 `range`**：表示数据在面板上的视觉占比（Vega-aligned：`range: [0, width]`），而非数据值。通过 `limits` + `expand=c(0,0)` 精确实现。与 `limits` 同时非 NULL 时后设置者胜，冲突时警告。

**`default_color` 覆盖**：任何用户提供的 `colour`/`fill` 映射都触发清除 `default_color` 注入的 `mapping$colour`/`mapping$fill` 和 `guides(colour="none", fill="none")`。清除点（`._clear_default_color()`）：统一 mark 路径（`._mark_impl` 传入 layer mapping 时）、手写 mark（`mark_map`/`mark_corr`/`mark_treemap`/`mark_sankey`）、`scale_color`/`scale_fill`（无条件）、`project_parallel`（group 引入 colour 时）。均已对称处理两侧。

#### 3.3.4a `layout_*` — 关系图布局变换（Vega transform 模式）

关系数据走「布局即数据变换」路线：`as_graph()` 收编为 `plotit_graph`（命名表集合，canonical 表 `nodes`/`edges`），`layout_*()` 从拓扑计算坐标并烘焙进表，mark 通过公式引用子表渲染。

```
data |> as_graph() |> plotit() |>
  layout_force(seed = 1) |>
  mark_point(data = ~nodes) |>
  mark_rule(data = ~edges)
```

> `as_graph()` 按列名自动识别 `source`/`target`/`value`（可用同名参数显式指定列）。位置传列名非法——第二个位置参数是 `nodes` 节点表。

| 函数 | 引擎 | 关键参数 |
|---|---|---|
| `layout_force` | 自研 Fruchterman-Reingold（斥力矩阵 + 引力累加 + 线性降温，确定性 seed） | `iterations`, `seed`(可选), `weights`, `...`（仅 weights，未知参数警告） |
| `layout_circle` | 三角函数 | `order_by`（`"id"`/`"degree"`） |
| `layout_tree` | 自研叶子序后序遍历 + 深度轴（与 dendrogram 共享 `._hierarchy_leaf_x`） | `direction`（`down/up/right/left`） |
| `layout_dendrogram` | hclust 高度递归展开（`.side` 保序，免 igraph） | `direction`（`down/up/right/left`） |
| `layout_chord` | 扇区角度分配 + 贝塞尔带（纯 R，确定性）；输出第三/四表 `arcs`+`ribbons` | `inner_radius`, `pad_angle`(rad), `curvature`, `order_by`（`"total"`/`"appearance"`） |
| `layout_sankey` | 最长路径分层 + 重心扫描 + 贝塞尔带（纯 R，确定性免 seed） | `node_width`, `padding`, `curvature`, `n_points`, `max_sweeps`；输出第三表 `ribbons` |
| `layout_treemap` | Bruls squarify 递归（纯 R）；层次表经 `as_graph(id/parent/value)` 收编 | 输出 `xmin…ymax` + `leaf` 标记 + 派生表 `leaves` |

**核心约定**：

- **双轨制**：复合关系 mark（`mark_network` 等）保留为语法糖，内部必须调用与公开 `layout_*` 相同的引擎函数（`._layout_engine_*`），禁止重复实现。
- **公式引用**：mark 的 `data = ~table` 从 `plot@graph` 急切解析子表；`plotit_graph` 可含任意命名表（如 sankey 的 `ribbons`、treemap 的 `leaves`）。图数据上省略 `data` 报错。
- **几何自动绑定**：经 `~table` 解析的图层自动绑定表中存在的几何列（白名单：x/y/xend/yend/xmin…ymax），并按 mark 家族收窄作用域（`._MARK_BIND_AES`：text/point 等仅 x,y；rect 含角点）；显式映射优先。此类图层强制 `inherit.aes = FALSE`。
- **不可变槽**：`plotit@graph` 为可空属性（copy-on-write），禁止环境类共享状态；`layout_*` 返回新对象。
- **幂等重算**：引擎只读拓扑列（source/target/value、id、height/parent），执行前剥离残留几何列——链式换布局 last-wins。
- **确定性**：随机布局强制 `seed` 参数（出版复现）；sankey/treemap/dendrogram/chord 为纯确定性算法，无需 seed。
- **收编格式**：边表（canonical）、matrix/xtabs（M[row,col] → source=row）、hclust/dendrogram（节点携带 height）、层次表（`id`+`parent` 列，value 存于节点）、tbl_graph。键统一转 character；`nodes` 缺省时按首次出现序隐式生成。
- **已知局限**：图数据 + `split_*` 的边过滤语义未定义，v1 不支持。

规划中（延期评估）：`layout_pack`（packcircles 未入依赖）。关系类渲染器已 100% 收敛至 ggplot2 原语（circlize/ggsankey/ggraph 全部退役）。

#### 3.3.5 `project_*` — 坐标系

| 函数 | 底层 | 关键参数 |
|---|---|---|
| `project_cartesian` | `coord_cartesian`/`coord_flip`/`coord_fixed`/`coord_trans` | `xlim`, `ylim`, `expand`, `flip`, `fixed`, `coord_trans`, `clip` |
| `project_polar` | `coord_polar`/`coord_radial` | `theta`, `start`, `direction`, `inner_radius`, `r_axis_inside`, `clip` |
| `project_parallel` | 数据重塑+`geom_line`/`geom_point` | `columns`, `group`, `scale`（`"std"`/`"global"`/`"none"`） |
| `project_map` | `coord_sf`/`coord_map` | `projection`, `xlim`, `ylim`, `clip` |

`project_parallel` 三模式：

| 模式 | 归一化 | y 轴 | 每列轴 |
|---|---|---|---|
| `"std"` | 每列 min-max→[0,1] | 共享 `scale_y_continuous()` | 无 |
| `"global"` | 全局 min-max→[0,1] | 共享 `scale_y_continuous()` | 无 |
| `"none"` | 无 | 抑制原生 y 轴 | 每列手动渲染（`geom_segment`+`geom_text`） |

`"none"` 模式已知局限：非原生 guide，轴线颜色/线宽/字体从 `._parallel_theme_props()` 提取当前主题 `axis.*` 元素，不保证 100% 像素一致。推荐优先使用 `"std"` 或 `"global"`。

`project_map` 默认 `coord_sf()`，传 `projection` 时切换 `coord_map()`（需 mapproj）。`project_polar` 径向模式（`inner_radius>0` 或 `r_axis_inside=TRUE`）需 ggplot2 ≥ 3.5.0。

#### 3.3.6 `split_*` — 分面

`split_wrap(plot, ..., ncol=NULL, nrow=NULL, scales="fixed")`：`...` 无名参数=分面变量，命名参数透传 `facet_wrap`（如 `labeller`、`dir`）

`split_grid(plot, ..., rows=NULL, cols=NULL, scales="fixed", space="fixed")`：`...` 无名= `rows` 简写；同时提供时以 `...` 为准并警告

#### 3.3.7 `label_*` — 文本标签

三参数协议（优先级：reset > hide > text）：

| 优先级 | 参数 | 效果 |
|---|---|---|
| 1（最高） | `reset=TRUE` | 恢复变量名（轴/图例）或移除文本（标题/副标题/脚注）。无视 `text` 和 `hide`。 |
| 2 | `hide=TRUE` | `element_blank()` 移除元素及占位空间。无视 `text`。 |
| 3（最低） | `text="str"` | 设置自定义文本。仅前两者均为 FALSE 时生效。 |

`text` 非 NULL 与 `reset=TRUE` 同时提供时报错。优先级规则消除了调用顺序依赖。

| 函数 | 参数 | 用途 |
|---|---|---|
| `label_title(text, hide, reset)` | — | 主标题 |
| `label_subtitle(text, hide, reset)` | — | 副标题 |
| `label_caption(text, hide, reset)` | — | 脚注 |
| `label_axis(text, aes, hide, reset)` | `aes="x"` 或 `"y"`（必填） | 轴标题 |
| `label_legend(text, aes, hide, reset)` | `aes="colour"`/`"fill"` 等，`aes=NULL`=全局 | 图例标题 |

**`label_legend(aes=NULL)` 全局模式**：`aes=NULL` 时写入 `meta$legend[["default"]]` 并应用到当前所有已映射美学；后续对单个 aes 的调用覆盖之（后执行者胜）。`meta$legend` 中 `"default"` 条目与具体 aes 条目共存但后者优先生效。

#### 3.3.8 `style()` — 主题

`style(plot, ..., base_size=NULL, base_family=NULL, base_theme=NULL)`：先应用基础主题（空时内部 `%||%` 分发到 `._theme_default(base_size=10, base_family="")`，token 驱动），再叠加 `theme(...)` 覆盖。`style_default()` 为便捷别名。

#### 3.3.9 `export()` — 导出

`export(plot, filename, width=NULL, height=NULL, dpi=300, device=NULL, ...)`

尺寸优先级链：显式传参 > meta 存储值 > autofit 自适应。

- `autofit=FALSE` + 未传尺寸：通过 gtable 测量获得总尺寸（面板尺寸来自 meta，通过 `._build_fixed_gtable()` 固定；轴/标签/图例由当前主题决定）
- `autofit=TRUE` + 未传尺寸：回退 `getOption("plotit.default_width", 5)` / `getOption("plotit.default_height", 3.5)`（英寸）
- 显式传入的 `width`/`height` 遵循 `plotit()` 时设定的 `size_unit` 换算。单位统一为英寸后传给 `ggsave()`
- `device` 从文件名扩展名推断（`.pdf` / `.png` / `.svg` 等）

#### 3.3.10 图片尺寸算法

`plotit()` 的 `width`/`height` 指面板尺寸（非总尺寸）。`autofit=FALSE` 时通过 `patchwork::plot_layout()` 固定面板为绝对单位。

**契约边界**：面板尺寸遵守 ±1% 浮点误差。总尺寸（面板+轴+标签+图例+边距）为衍生值，不在 API 契约内，可能随主题/字体/设备版本变化。

> **Patchwork 剥离规划**（阶段 0.1，部分完成）：
> 单图侧已实现：`plotit()` 不再调用 `plot_layout()`，`@gg` 为纯 ggplot 对象；`print()`/`export()` 通过 `._build_fixed_gtable()` 固定面板尺寸。
> 组合图侧待实现：`compose_*` 仍依赖 `patchwork::wrap_plots()` / `plot_layout()`；`._reset_sizing()`、`._assemble_plots()` 仍以 patchwork 为核心。

#### 3.3.11 统一主题模块（`R/theme.R` — 单一风格源头）

全局默认视觉决策全部集中于 `R/theme.R`，高内聚低耦合：换风格只改此文件。Mark 级字面量仍归 `mark_style.R`（§3.3.3c），两表互不引用。

| 组件 | 职责 |
|---|---|
| `._STYLE_TOKENS` | 全局视觉 token：paper/ink 锚点、派生灰阶、轴线宽 0.25、字号相对层级、legend.key 3.5mm、离散/连续策划色板 |
| `._ink_mix(prop)` | ink→paper 颜色混合，token 派生灰阶的基础设施 |
| `._palette_discrete(n)` | friendly 六锚点取样：≤6 档均匀子采样保对比度，>6 档 `colorRampPalette` 插值 |
| `._theme_default(base_size, base_family)` | 学术简洁主题构建器（style.R 仅保留用户泛型，构建体已迁出） |
| `._attach_default_colour_scale(p, data, mapping)` | 构造期自动挂载策划色板：映射的离散 colour/fill→friendly、连续→viridis；AsIs 常量与解析失败静默跳过 |
| `._default_colour_scale(aes, data, var)` | **全包唯一色板决策点**：类别列→friendly 定性、数值列→viridis 顺序；构造期/图层/派生通道三条路径共用 |
| `._apply_panel_size(gg, w, h, unit)` / `._strip_panel_size(gg)` / `._panel_sizing_supported()` | WYSIWYG 烘焙/剥离/能力探测 |
| `._gg_aspect_conflict(gg)` | 检测固定纵横比坐标系（CoordFixed）与烘焙面板尺寸的冲突 |

**关键约定**：

- **WYSIWYG**：`autofit=FALSE` 时构造期把 meta 尺寸烘焙为 `theme(panel.widths=, panel.heights=)`（ggplot2 ≥3.5，旧版优雅降级）。任意渲染路径面板物理尺寸恒定；`export()` 的 gtable 测量与之数值一致。
- **纵横比优先于固定面板**（aspect-true outranks WYSIWYG）：绝对烘焙尺寸会拉伸 CoordFixed 坐标系（圆变椭圆）。两处对称修复——`_prepare_render()` 检测到冲突时剥离烘焙尺寸（knitr/pkgdown 路径）；`._build_fixed_gtable()` 按 `coordinates$aspect()` 信箱式缩放面板（print/export 路径）。多面板自由刻度取首面板范围（已文档化近似）。
- **组合图默认尺寸**：patchworkGrob 的 `1null` 单位在视口外不解析，直接测量得到垃圾值。`._composite_default_size()` 从子图 meta 面板尺寸 + 布局类型（grid/marginal/inset）+ 固定 chrome 余量（1.6in）计算默认画布，print/export 共用。
- **剥离**：组合图组装前 `._reset_sizing()` 先调 `._strip_panel_size()`（公开 API `+ theme(panel.widths=NULL)` 重置，不直改 `gg$theme`——ggplot2 ≥4.0 theme 为 S7 对象，list 子集赋值会校验失败）。
- **ggplot2 4.0 兼容**：默认离散 scale 用 `discrete_scale(aesthetics=, palette=fn)` 而非 `scale_*_discrete(type=fn)`——后者的 palette 函数会被 4.0 backward-compatibility 层当 scale 构造器误 exec。
- **覆盖语义**：构造期默认 scale 是"最先挂载"，任何用户 `scale_*()` 后执行者胜；`default_color` 注入路径（未映射）不受影响。

### 3.4 `compose_*` 组合

全部返回 `plotit_composite`（`@gg` + `@plots` + `@layout` + `@annotations`）。

**`compose_grid(..., ncol=NULL, nrow=NULL, byrow=TRUE, widths=NULL, heights=NULL, guides="collect", axes="keep", tag_levels=NULL)`**
- 默认 `ncol=NULL, nrow=NULL` → `ncol=1`（纵向堆叠）。仅设 `nrow=1` 则横向并排
- `guides="collect"` 默认合并相同图例（避免重复图例并排），可传 `"keep"` 独立
- `axes` 封装 `patchwork::plot_layout(axes=)`
- 嵌套：接受 `plotit_composite`，组合可嵌套

**组合图主题语义**：composite 上的 `style()` 经 patchwork `&` 作用到**全部**子面板（`+` 只作用于末图）；`plot_annotation()` 惰性渲染时附带 `._theme_default()`，标题/副标题/脚注层级与单图一致。print/export 未显式给尺寸时用 `._composite_default_size()`（子图 meta 面板 + chrome 余量）——禁止直接测量 patchworkGrob（null 单位视口外不解析）。

**`compose_inset(base, inset, left=0, bottom=0, right=1, top=1, align_to="panel", on_top=TRUE, ...)`**
- base 的 `@gg` 在组装前调用 `._reset_sizing()` 剥除固定面板尺寸防止裁切
- `align_to="panel"` 以面板为基准定位，`"plot"` 以整个绘图区域为基准

**`compose_marginal(main, top, right, widths=c(4,1), heights=c(1,4), guides="collect")`**
- 布局：`wrap_plots(design="AB\nCD")` 扁平 2×2（顶部直方图+角落空白 / 主散点+右侧直方图）
- 组装前自动隐藏边际图的重复轴（X 轴只出现在主散点底部，Y 轴只出现在左侧）
- 右侧直方图需用户调用 `project_cartesian(flip=TRUE)` 翻转以对齐 Y 轴
- 图例默认合并（`"collect"`），可传 `"keep"` 独立

`label_title`/`label_subtitle`/`label_caption` → 写入 `@annotations`，`print()`/`export()` 时通过 `plot_annotation()` 惰性渲染（消除调用顺序依赖）。不支持的操作：`mark_*`/`scale_*`/`project_*`/`split_*`/`label_axis`/`label_legend` 不接受 `plotit_composite`——先构建再组合。

##### `compose_grid` 细节
- 嵌套：接受 `plotit_composite`，组合可嵌套。单图：`compose_grid(p)` 合法。
- `tag_levels` 存入 `@annotations`，惰性注入：`"A"`/`"a"`/`"1"`/`"i"` 或自定义字符向量。

##### `compose_marginal` 细节
- 布局：`wrap_plots(design="AB\nCD")` 扁平 2×2。共享坐标轴：组装前对边际图隐藏重复轴。
- 右侧直方图需用户调用 `project_cartesian(flip=TRUE)` 翻转以对齐 Y 轴。

---

## 4. 代码风格

### 4.1 文件结构

```
R/：class.R encode.R utils.R plot.R mark.R scale.R project.R split.R label.R style.R output.R compose.R factory.R zzz.R
tests/testthat/：test-<func>.R 按函数族分文件
```

playground.R 用于临时手动测试，不纳入版本管理。

### 4.2 命名与格式

snake_case，动词前缀统一。color/colour 等价接受，函数命名统一美式。缩进 2 空格，行宽 120（`line_length_linter(120)`）。Push 前执行 `styler::style_pkg()`（**最后一步执行**——修改格式后行号索引失效）。

### 4.3 代码文本一律使用英文

注释、roxygen、错误消息、警告信息、commit message 用英文。（AGENTS.md 本身用中文。）

### 4.4 管道

所有修改函数返回 `plotit`，支持 `|>`。每个管道步骤独立一行。

### 4.5 错误信息

主动验证点用 `cli::cli_abort()`。警告信息明确说哪个参数生效、哪个被忽略。

### 4.6 命名空间与 ggplot2 交互

显式 `pkg::fun()`。内部用 `%||%` 处理 NULL 默认值。

**优先使用公开 API**：所有视觉修改首先尝试 `+ labs()`、`+ guides()`、`+ theme()`。

**允许直接访问**：`gg$mapping`、`gg$data`、`gg$theme`（只读）；`gg$labels`（可写——惰性标签设计依赖 `._sync_labels()` 在 `print()`/`export()` 时写入，见 §1.2）。

**禁止**：`gg$scales$scales` 等未文档化的内部结构。测试中也禁止检查这些。
`gg$layers` 同样为 ggplot2 内部槽位不保证兼容——`._collect_aes_names` 中存在访问为已知例外，计划在 AD-2 中移除。

**非标准求值只用 rlang**：`rlang::eval_tidy()`，禁止 `eval()` + `baseenv()`。

### 4.7 Roxygen

每个导出函数：标题+描述、`@param`（每个参数含合法取值）、`@return`、`@export`。

### 4.8 测试

按函数族分文件。覆盖合法值及关键组合、非法输入错误路径、管道链集成场景。

**断言行为而非内部状态**：使用 `ggplot2::ggplot_build(p@gg)` 提取渲染数据断言。BDD 测试以 `[BDD]` 前缀标注。

---

## 5. 实现 Demo

```r
library(plotit)

mapping <- encode(x = displ, y = hwy, colour = class)

p <- plotit(mpg, mapping, autofit = FALSE, width = 6, height = 4, size_unit = "in")

p <- p |>
  mark_point(size = 2, alpha = 0.7) |>
  scale_x(trans = "log10") |>
  scale_color(range = "viridis") |>
  label_title("Fuel Economy") |>
  label_axis(text = "Displacement", aes = "x") |>
  label_axis(text = "Highway MPG", aes = "y")

p <- style(p, base_theme = ggplot2::theme_minimal(base_size = 12))

export(p, "output.pdf", dpi = 300)
```

---

## 6. 默认美观要求

属于 §1.4 可迭代范围，具体参数可随版本调整。全部默认视觉决策集中于 `R/theme.R` 单一源头模块（§3.3.11），改一处全局生效。

- **主题**：学术简洁风（对标 tidyplots `theme_tidyplot` 配方并适配 plotit 画布）——基于 `theme_minimal`，白色纸面 + 纯黑 ink 发丝轴线/刻度线（linewidth 0.25），无网格线，背景全透明，层级分明字号（title rel(1.15) plain 左对齐 / subtitle rel(0.95) 灰 / axis.title rel(0.95) / axis.text rel(0.85) 灰 / legend rel(0.85)，legend.key 3.5mm）。极坐标系自动关闭轴线/刻度线/轴文本。平行坐标系：`std`/`global` 模式共享原生 y 轴，`none` 模式每列渲染主题匹配轴线。
- **WYSIWYG 所见即所得**：`plotit()` 构造时把 meta 面板尺寸经 ggplot2 ≥3.5 的 `theme(panel.widths=, panel.heights=)` 烘焙进 `@gg`——IDE 设备、knitr、pkgdown、ggsave 任意渲染路径下面板物理尺寸恒定，内容比例与导出完全一致（实测 6×6/9×7/14×10 英寸设备上面板恒等于声明值）。组合图组装前由 `._reset_sizing()` 剥离该约束交由 patchwork 布局。**纵横比优先**：固定纵横比坐标系（CoordFixed）下烘焙尺寸让位——渲染前剥离（`._prepare_render`）或信箱式缩放（`._build_fixed_gtable`），圆不因面板形状变椭圆。
- **调色板**：无映射时默认 Tableau 蓝 `#4E79A7`（同时 `colour`+`fill`，图例隐藏）。有映射时自动挂载策划色板，**全包唯一决策点** `._default_colour_scale()`：**恒等/分组通道（类别列）→ friendly**（Okabe-Ito 色盲安全六色，黄位加深为 `#F5C710`：`#0072B2 #56B4E9 #009E73 #F5C710 #E69F00 #D55E00`；>6 档锚点插值，<6 档均匀取样），**量级通道（数值列）→ viridis 顺序色板**。三条挂载路径共享同一规则：构造期全局映射、图层映射（`._mark_impl` 自动挂载 + managed 注册表防覆盖用户 scale）、Mark 派生通道。用户之后链式 `scale_*()` 即替换（后执行者胜）；`encode(colour = I(...))` AsIs 常量走 identity 不被劫持；hue 色相轮退居可选方案 `range="hue"`。
- **Mark 统一默认样式**：全部 mark 的样式字面量集中于 `R/mark_style.R`（详见 §3.3.3c）——品牌色 primary `#4E79A7` / secondary `#E15759`；中性灰阶 ink(grey30)/soft(grey50)/faint(grey70)；线宽阶梯 lw_data(0.9) > lw_thin(0.5) > lw_border(0.25)；注释字号 txt_note(3.2)；半透明填充 alpha_fill(0.6)、连接带 alpha_link(0.5)。柱宽默认槽位的 0.7（slot=dodge 0.8，留出组间空气）。用户显式参数与已映射美学始终优先于默认。
- **封闭统计 Mark 自动 viridis**：量级派生通道（corr `value` / hex `count` / density_2d(filled) `level`）语义为数值大小 → viridis 顺序色板；关系类语法糖的恒等派生通道（sankey 流带/节点、chord 弧段/缎带、treemap 叶块均默认 source identity，network 节点 colour）按列类型路由 friendly/viridis——与全局映射同一规则、同一色板。用户之后链式调用 `scale_*()` 即替换（后执行者胜）。
- **域驱动画布 chrome**：graph 数据 ⇒ 坐标自由画布（构造期即关闭全部轴元素，语法糖与显式管道同貌）；封闭单元格 mark（`mark_rect`/`mark_corr`）⇒ cell-chrome（无轴线/刻度 + 零 expand，类别文本保留，corr 另去合成轴标题 Var1/Var2）；用户显式 `project_*()` 始终优先。
- **默认轴标题清理**：`factor()`/`as.factor()`/`ordered()`/`as.character()` 包裹的映射在构造期解包为纯列名（`encode(x=factor(cyl))` → 轴标题 "cyl"）；其余表达式保持 ggplot2 deparse 行为。
- **图例**：右侧，无边框透明背景，紧凑 key 尺寸。
- **尺寸**：自适应关闭时默认紧凑学术面板 5×3.5 英寸（总足迹 ≈6.6in 装进标准设备），导出 300 dpi。组合图默认画布 = 子图 meta 面板 × 布局维度 + 1.6in chrome 余量（禁止测量 patchworkGrob）。

---

## 7. 补充约定

- **空数据与缺失值**：空 data.frame 由 ggplot2 决定。`NA` 由 ggplot2 默认静默移除。
- **S7 槽位**：`plotit_labels`（title/subtitle/caption/x/y/legend/dirty）、`plotit_metadata`（autofit/width/height/dodge/unit/default_color/labels）、`plotit`（gg/meta）。
- **打印与设备**：`print()` 交互模式通过 `grDevices::dev.new(noRStudioGD=TRUE)` 打开独立设备窗口保证面板尺寸物理呈现。`options(plotit.device)`：`"default"` / `"rstudio"` / `NULL`（禁用自动设备打开）。`export()` 从文件名推断设备。

---

## 8. Bug 审查原则

| # | 原则 | 检查点 |
|---|------|--------|
| 0 | 区分特性与 Bug | 静默忽略若无注释说明意图→Bug。参数传入不生效是 Bug 的充分条件。 |
| 1 | 参数全链路追踪 | 每个中转节点：直接转发/转换/被丢弃？ |
| 2 | 枚举值分支穷举 | N 个合法值→N 条路径全部显式存在 |
| 3 | 对称抽象一致性 | color↔fill, size↔alpha, shape↔linetype, x↔y |
| 4 | 默认值分叉 | 新增条件分支→同步更新默认值逻辑 |
| 5 | 底层接口兼容性 | 透传前确认底层接受该参数；不接受时切换函数 |
| 6 | 内部概念不泄漏 | 包层参数名可能与底层同名但语义不同（如 `trans="binned"`） |
| 7 | 有状态默认值对称清除 | `default_color` 双向注入 + 双向 `guides()`。`._clear_default_color()` 统一共用（9 处调用点：`._mark_impl`/`mark_map`/`mark_corr`/`mark_treemap`/`mark_sankey`/`scale_color`/`scale_fill`/`project_parallel`） |
| 8 | 契约边界可验证 | 契约必须用用户可见指标定义（如面板尺寸 ±1%），不能用无法验证的免责声明。 |

---

## 9. 1.0 开发路线图

> **优先级策略**：纯优先级排序，无固定时间线。四类 mark 并行推进，每阶段各取 1-2 个。
> **推进顺序**：先固本（清债）→ 后扩展（mark）→ 最后收尾（文档+质量）。

### 9.0 阶段总览

| 阶段 | 名称 | 范围 | 状态 |
|---|---|---|---|
| 0 | 固本 | 架构清债 + 代码质量 | 🔄 进行中（单图侧 patchwork 剥离、`._sync_labels` 抽象、mark 工厂函数、@examples 均已 ✅；剩余：组合图 patchwork 剥离） |
| 1-4 | mark 扩展 | 13 种新 mark（20 种规划 − 6 已实现 − 1 已移除组合） | ✅ 已完成（实际 27 种，见 §3.2） |
| 5 | 收尾 | 文档补齐、全量验证、发布准备 | ⬜ 未开始 |

---

### 9.1 阶段 0：固本（基础设施清理）

在扩展 mark 之前清理架构债务和代码质量问题，确立干净的基线。

| # | 任务 | 优先级 | 说明 |
|---|------|--------|------|
| 0.1 | **Patchwork 剥离** | P0 | `@gg` 改为存储纯 ggplot（非 patchwork）。面板尺寸在 print/export 时通过 `ggplot_build()` + `grid` 修 gtable 实现。移除 `._reset_sizing()`、`._assemble_plots()` 中对 patchwork 的依赖。`plotit()` 构造函数简化（不再调用 `plot_layout()`）。**风险**：gtable 测量精度在不同 ggplot2 版本间可能漂移，需 ±1% 容差验证。 |
| 0.2 | **`._sync_labels` 重构** | P1 | ✅ 5 个重复 if 块（title/subtitle/caption/x/y）抽象为循环或统一辅助函数 `._sync_one_label(plot, slot, theme_el, labs_el)`。不改行为，只消除重复。 |
| 0.3 | **mark_* 工厂函数** | P1 | ✅ 创建 `._register_mark_method(generic, geom_fun)` 工厂函数，生成 S7 泛型+方法。每个 mark 定义从 ~15 行缩减到 1 行调用。不改对外 API 和文档。 |
| 0.4 | **补齐 `@examples`** | P2 | ✅ 当前所有导出函数补充可运行 `@examples`（需外部包如 sf/mapproj 的用 `\dontrun{}`，自包含的用 `\donttest{}`）。 |

**验收标准**：

| 任务 | 验收标准 |
|---|---|
| 0.1 | `@gg` 始终为纯 ggplot 对象；`plotit()` 不依赖 patchwork；所有已有测试全部通过 |
| 0.2 | `._sync_labels` 无重复代码；所有已有测试全部通过 |
| 0.3 | 每个 mark 定义 ≤5 行；无新增 lintr 警告；测试通过 |
| 0.4 | `R CMD check` 零 ERROR（允许 NOTE）；每个导出函数有 `@examples` |

**风险点**：

| 风险 | 缓解措施 |
|---|---|
| Patchwork 剥离导致 compose_* 需要重写 | 按照 §3.3.10 路线图分步实施；先在分支验证再合入 |
| gtable 测量跨版本漂移 | 契约容差设为 ±3%（放宽至 ≥1.0 版本收紧为 ±1%） |
| 工厂函数改变 S7 泛型的调试体验 | 保留 `@export` 标签让 roxygen2 正常生成文档 |

---

### 9.2 阶段 1–4：mark 类型扩展

每阶段从四个类别中各选 1-2 个最高价值的 mark。每个 mark 附带：S7 泛型+方法、roxygen 文档（`@examples`）、BDD 测试（≥3 个 test_that）。

**通用验收标准**（每个 mark）：

- [ ] S7 泛型 + 方法注册正确，管道兼容
- [ ] `@examples` 可独立运行（`\donttest{}` 或 `\dontrun{}` 按需）
- [ ] BDD 测试 ≥3 个（正常路径 + 参数变体 + 错误路径）
- [ ] `R CMD check` 零 ERROR
- [ ] 新增 mark 添加到 AGENTS.md §3.2 已实现表

---

#### 阶段 1：area / text / violin / map ✅ 已完成

| # | mark | 类别 | 依赖包 | 复杂度 | 状态 |
|---|---|---|---|---|---|
| 1.1 | `mark_area` | 基础几何 | ggplot2 | 低 | ✅ |
| 1.2 | `mark_text` | 基础几何 | ggplot2（可选 ggrepel） | 中 | ✅ |
| 1.3 | `mark_violin` | 分布展示 | ggplot2 | 低 | ✅ |
| 1.4 | `mark_map` | 地理空间 | sf（可选） | 中 | ✅ |

**阶段 1 风险**（已关闭）：

| 风险 | 缓解措施 |
|---|---|
| `mark_text` 参数复杂（hjust/vjust/nudge_x/check_overlap 等） | 只封装常用参数，其余通过 `...` 透传 |
| `mark_map` 依赖 sf → CRAN 上不是所有平台可用 | 设为 `Suggests`，示例用 `\dontrun{}` |

---

#### 阶段 2：rect / rule / treemap ✅ 已完成

| # | mark | 类别 | 依赖包 | 复杂度 | 对应实现 |
|---|---|---|---|---|---|
| 2.1 | `mark_rect` | 基础几何 | ggplot2 | 低 | `geom_tile`/`geom_rect` |
| 2.2 | `mark_rule` | 基础几何 | ggplot2 | 中 | `geom_hline`/`geom_vline`/`geom_abline`/`geom_segment` — 按 orientation 自动分发 |
| 2.3 | `mark_treemap` | 关系层次 | ~~treemapify~~ 已移除（原生化） | 中 | 初版 `treemapify::geom_treemap` 已退役，现为 `layout_treemap()` 自研语法糖（§3.3.4a） |

**阶段 2 风险**：

| 风险 | 缓解措施 |
|---|---|
| `mark_rule` 需处理 4 种底层 geom → API 设计复杂 | 统一为 `mark_rule(orientation, intercept, ...)` 签名 |
| treemapify 维护频率低（最后更新 2023） | ✅ 已关闭：treemapify 整体退役，`mark_treemap` 改走自研 `layout_treemap()` 引擎 |

---

#### 阶段 3：path / sankey / polygon ✅ 已完成

| # | mark | 类别 | 依赖包 | 复杂度 | 对应实现 |
|---|---|---|---|---|---|
| 3.1 | `mark_path` | 基础几何 | ggplot2 | 低 | `geom_path` |
| 3.2 | `mark_polygon` | 基础几何 | ggplot2 | 低 | `geom_polygon` |
| 3.3 | `mark_sankey` | 关系层次 | 无（纯 R 确定性布局引擎） | 高 | `layout_sankey()` + `mark_polygon(~ribbons)`/`mark_rect(~nodes)` 语法糖（初版 ggsankey 实现已退役，见 §3.3.4a） |

**阶段 3 风险**：

| 风险 | 缓解措施 |
|---|---|
| ggsankey API 不稳定 | ✅ 已关闭：ggsankey 已退役，改为内置确定性分层布局引擎，零外部依赖 |

---

#### 阶段 4：network / chord ✅ 已完成

| # | mark | 类别 | 依赖包 | 复杂度 | 对应实现 |
|---|---|---|---|---|---|
| 4.1 | `mark_network` | 关系层次 | ~~igraph~~ 已移除（布局自研） | 高 | `layout_force()`（自研 FR）/`layout_circle()` + rule/point/text 语法糖（初版 ggraph 实现已退役，见 §3.3.4a） |
| 4.2 | `mark_chord` | 关系层次 | 无（纯 R 确定性布局引擎） | 高 | `layout_chord()` + `mark_polygon(~ribbons)`/`mark_polygon(~arcs)` 语法糖（初版 circlize 实现已退役，见 §3.3.4a） |

**阶段 4 风险**：

| 风险 | 缓解措施 |
|---|---|
| `mark_network` 依赖两个重包（ggraph + igraph） | ✅ 已关闭：ggraph 已退役；igraph 亦已随力导向/树布局自研而整体移除，渲染与布局均为包内实现 |
| circlize 使用 base R 图形系统非 ggplot2 → 集成复杂 | ✅ 已关闭：circlize 已退役，改为纯 R 确定性环形布局（§3.3.4a） |

### 9.2a 组合收录（不新增 mark 的 recipe）

以下视觉效果通过已有 mark + project 组合实现，不新增独立 mark：

| 视觉效果 | 等价管道 | 说明 |
|---|---|---|
| 饼图/环形图/玫瑰图 | `mark_bar()` + `project_polar(inner_radius=...)` | 替代 VL `arc` / G2 `interval`(pie)。见 §3.2b 完整示例 |
| 雷达图 | `mark_line()` + `project_polar()` | 多维数据对比，见 §3.2b |
| 冰柱图/旭日图 | `mark_rect` / `mark_bar + project_polar()` + 层次树预处理 | 替代 G2 `tree`/`partition`。数据预处理方案见 §3.2b |
| 一维 strip plot | `mark_point(position="jitter")` | 替代 VL `tick`。若有需求可后续添加 `mark_rug` 作为 theme 辅助 |

---

### 9.3 阶段 5：收尾

| # | 任务 | 说明 |
|---|------|------|
| 5.1 | **全量 @examples 验证** | 所有导出函数 `@examples` 在 `R CMD check --as-cran` 下零 ERROR |
| 5.2 | **Vignette 更新** | "Customizing Plots" vignette 覆盖新增的 mark 类型和典型组合场景 |
| 5.3 | **README 更新** | README 用法表格反映当前 mark 总数 |
| 5.4 | **全量检查** | `R CMD check` + `lintr::lint_package()` + `styler::style_pkg()` 零问题 |
| 5.5 | **版本号** | DESCRIPTION 版本从 0.0.0.9000 → 1.0.0 |
| 5.6 | **NEWS.md** | 汇总所有变更，按函数族分组 |

**验收标准**：

- [x] 20 种 mark 至少 15 个已实现（≥75% mark 覆盖率）——实际 27 种已达成
- [ ] `R CMD check` 4 平台（Linux/macOS/Windows + R-devel）零 ERROR 零 WARNING
- [ ] `lintr::lint_package()` 零 lint 问题
- [ ] pkgdown 网站完整渲染所有函数参考页
- [ ] 3 篇 vignette 内容与当前 API 一致

---

### 9.4 当前 API 完成度

| 层级 | 函数族 | 1.0 目标 | 已实现 | 完成度 |
|------|--------|----------|--------|--------|
| 内层 | plotit + encode | 2 | 2 | 100% |
| 内层 | mark_* | 20（目标 ≥15） | 27 | 135%（超目标） |
| 内层 | scale_* + project_* + split_* + label_* + style+export | 22 | 22 | 100% |
| 最外层 | compose_* | 3 | 3 | 100% |
| **总计** | | **~49** | **54** | **110%** |

### 9.5 1.0 检查清单

**阶段 0（固本）**：
- [x] Patchwork 剥离（单图侧）：`@gg` 为纯 ggplot
- [ ] Patchwork 剥离（组合图侧）：`compose_*` 仍依赖 patchwork（AD-1）
- [x] `._sync_labels` 无重复代码（已抽象 `._sync_one_label` + `._LABEL_SYNC_MAP`，AD-3）
- [x] mark_* 工厂函数：10 个标准 mark 一行注册（AD-5）；手写 mark（rule/smooth/corr 等）保留专用签名
- [x] 所有导出函数有 `@examples`（外部依赖用 `@examplesIf`/`\dontrun{}`）

**阶段 1–4（mark 扩展）**：
- [x] mark_area
- [x] mark_text
- [x] mark_rect
- [x] mark_rule
- [x] mark_polygon
- [x] mark_path
- [x] mark_violin
- [x] mark_beeswarm
- [x] mark_treemap
- [x] mark_sankey
- [x] mark_network
- [x] mark_chord
- [x] mark_map

**阶段 5（收尾）**：
- [ ] `R CMD check` 4 平台零 ERROR 零 WARNING
- [ ] lintr 零问题
- [ ] pkgdown 完整渲染
- [ ] Vignette / README 更新
- [ ] 版本号 1.0.0
- [ ] NEWS.md 汇总

---

## 10. 技术债务

| # | 事项 | 优先级 | 状态 |
|---|------|--------|------|
| AD-1 | Patchwork 剥离（§3.3.10） | 中 | 单图侧已完成；组合图仍依赖 patchwork |
| AD-2 | `._collect_aes_names` 访问内部 `gg$layers` | 低 | 违反 §4.6 禁止规则。移除后 label_legend(aes=NULL) 的图例标题不应用到图层级美学映射，需评估替代方案。同类已知例外：`mark_significance` 读取 `plot@gg$scales$get_scales("x")` 检测离散 x 轴（无公开 API 可查询已安装 scale 的类/limits），已在源码注释标记 |
| AD-3 | `._sync_labels` 5 个几乎相同 if 块 | 低 | ✅ 已抽象为 `._sync_one_label()` + `._LABEL_SYNC_MAP` 查找表 |
| AD-4 | S7 版本锁定 | 低 | DESCRIPTION 已限制 |
| AD-5 | mark_* 样板代码 | 低 | ✅ 已引入 `._register_mark_method()` 工厂函数（`R/mark.R`），10 个标准 mark 从 ~200 行缩减为 1 行调用 |
| DI-1 | @examples 缺失 | 中 | ✅ 已补齐（自包含用 `@examples`，外部依赖用 `@examplesIf`/`\dontrun{}`） |
| DI-2 | AGENTS.md 不生成 HTML | 低 | ✅ `_pkgdown.yml` exclude + CI 后处理移除 `docs/AGENTS*.html` |
| DI-3 | roxygen 链接警告 | 低 | ✅ `[0,1]` 已包裹为 `\code{[0,1]}` |

---

## 11. 开发陷阱

### 11.1 PowerShell 字符串展开

`@"..."@` 展开 `$variable` 和 `` `e ``。使用 `@'...'@` **单引号** here-string 保留字面文本。少量文本中用 `` `$ `` 或 `$$` 转义。

### 11.2 `-replace` 的 .NET 正则替换陷阱

替换字符串中 `$` 被解释为组引用（`$labels`→`abels`）。替换中字面 `$` 用 `$$`。非正则替换优先用 `[string]::Replace()`。

### 11.3 `git index.lock` 持久锁定

前序 git 中断后 `.git/index.lock` 残留。`Remove-Item -Force .git/index.lock`。反复出现则 `Get-Process git | Stop-Process -Force`。

### 11.4 S7 方法注册的加载顺序依赖

引用尚未定义的 generic 时报错。调整 Collate 顺序或在 `.onLoad()` 中注册。

### 11.5 styler 致代码结构变化

styler 修改缩进/换行后行号索引失效。**作为最后一步执行**——所有逻辑修改完成后运行，验证测试通过，再提交。

### 11.6 `c(0, 1)` vs roxygen 链接解析

roxygen2 将 `c(0, 1)` 中的 `0,1` 误认为链接目标。使用 `\code{c(0, 1)}` 或在 backtick 换行前加空格。`[0,1]`（方括号）同理——包裹在 `` `[0,1]` `` 中。

### 11.7 `.lintr` 配置值随 lintr 版本求值

**已反转（2026-08）**：现行 lintr 将 `.lintr` 各配置值按 **R 表达式**求值——`encoding: UTF-8` 被解析为 `UTF - 8`（object 'UTF' not found），必须写 `encoding: "UTF-8"`；同理 `cyclocomp_linter = NULL` 在新 defaults 中已不存在，引用会致配置加载失败。旧版「DCF 字面值」约定仅适用于历史 lintr。升级 lintr 后先跑一次 `lintr::lint()` 验证配置可加载。

### 11.8 `._` 前缀函数 lintr 配置

`object_name_linter(regexes = c("^[a-z][a-z0-9._]*$", "^[.]_[a-z][a-z0-9._]*$"))`——第一个匹配普通 snake_case，第二个匹配 `._` 前缀内部函数。

### 11.9 `line_length_linter` 放宽

roxygen 示例中管道链天然超 80 字符，放宽至 120 字符。代码行（非注释）仍应尽量遵守 80 字符。

### 11.10 `\donttest{}` vs `\dontrun{}` 在 R CMD check 中

`\donttest{}` **仍然执行**（仅 CRAN 跳过），`\dontrun{}` **完全不执行**。需外部数据包（sf、mapproj）用 `\dontrun{}`。自包含示例（iris/mtcars）可用 `\donttest{}`。

### 11.11 `is.element_blank()` 不存在

ggplot2 无此导出函数。正确方式：`inherits(x, "element_blank")`。

### 11.12 GitHub Actions Node.js 弃用

`actions/checkout@v4` 依赖 Node 20（已弃用）。全部升级至 `v5`。`r-lib/actions` 当前最新为 `v2`。

### 11.13 S7 `@export` 泛型 vs 方法

`@export` 标记在 S7 方法上**只导出该方法**，不自动导出泛型。泛型定义（`new_generic`）需要自己单独的 `@export`。

### 11.14 testthat 中访问内部函数

`test_check()` 在包命名空间中运行——内部函数可直接访问（无需 `:::`）。`test_dir()` 在全局环境运行——需要 `:::`。测试中优先通过公开 API 验证行为。

---

## 12. CI/CD 通用实践

### 12.1 CI 故障诊断树

```
CI 步骤失败？
├─ 0 秒完成（startedAt≈completedAt）→ Action 初始化报错（检查 inputs 定义）
├─ 比预期快得多 → 被跳过（条件 if: 提前退出 / 缓存命中）
├─ 正常耗时但失败 → 读日志 / 缺 continue-on-error
└─ 弃用警告 → GitHub Actions Node 版本升级
```

### 12.2 配置陷阱

- **YAML 标量**：多行参数必须用 `|`（block scalar），不能用缩进列表
- **continue-on-error 分层**：step 级（建议性检查）/ job 级（R-devel）。不要在 `steps:` 列表中间放置 job 级属性
- **deploy 步骤**：只在 main 分支触发

### 12.3 预提交本地验证 SOP

**Layer 1（秒级语法检查）**：
```
git diff --name-only --cached -- *.R | ForEach-Object { Rscript -e "parse(file='$_')" }
```
**Layer 2（分钟级构建验证，改动 DESCRIPTION/NAMESPACE 时）**：
```
R CMD build . --no-build-vignettes
R CMD INSTALL *.tar.gz --library=<tmp_lib> --no-staged-install
```
**Layer 3（可选：lint + 风格检查）**：
```r
lintr::lint_package()
styler::style_pkg(dry = "on")
```

### 12.4 CI 预提交检查清单

新增/修改 CI workflow 前对照：
- [ ] `with:` 下的多行参数使用 `|`（block scalar）？
- [ ] `continue-on-error: true` 不在 `steps:` 列表中间？
- [ ] `on:` 的分支名与实际开发分支一致？
- [ ] `actions/checkout` 使用 v5、`upload-artifact` 使用 v4？
- [ ] 信息性 job（lint、coverage）使用 step 级 `continue-on-error: true`？
- [ ] R-devel 矩阵项包含 `http-user-agent: release`？
- [ ] deploy 步骤只在 main 分支触发？

### 12.5 CI 日志获取

```powershell
gh run list --limit 5 --json name,conclusion,status
gh api repos/{owner}/{repo}/actions/jobs/{job_id}/logs  # 不需要等整个 workflow 完成
```

### 12.6 Rd 示例解析错误定位

```r
tools::Rd2ex("man/<file>.Rd", "test.R")
parse(file = "test.R")
```

### 12.7 本地与 CI 环境差异

| 本地现象 | CI 相关性 | 原因 |
|----------|-----------|------|
| file.rename 失败 | 无关 | Windows Defender 拦截 staged install |
| CRAN URL 检查失败 | 无关 | 公司代理拦截出站 |
| 工作流触发失败 | 相关 | 用 act 本地模拟 |

本地复现 CI 失败优先使用 `gh api` 获取真实日志（§12.5），不要在本地 Windows 直接运行 R CMD check——差异太多。
