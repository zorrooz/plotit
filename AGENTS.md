# plotit 开发约定

## 1. 设计原则

### 1.1 核心价值

- **简化语法**：动词前缀命名（`mark_*`、`scale_*`、`project_*` 等），支持管道。
- **默认美观**：预设主题、配色与尺寸，开箱即出版/报告可用。
- **一致性**：统一的 API 风格、参数命名和错误处理策略。
- **可扩展性**：基于 ggplot2 及其主流扩展包（patchwork、ggrastr、ggrepel 等）构造，通过 `...` 透传底层能力，不作过度封装。

### 1.2 元数据集中管理

所有图表配置（尺寸、autofit、单位、dodge 宽度、default_color、标签文本等）统一存储于 `meta` 组件中。

标签类函数（`label_*`）**同步更新 `meta` 和 `gg`**：先将文本写入 `meta$labels`，随后立即通过 `ggplot2::labs()` 应用到 `gg`。

> 直接操作 `plot@gg` 绕过 label 函数会导致 `meta$labels` 过时。

### 1.3 分域验证

- **包层自定义约束** → 主动验证，`cli::cli_abort`。包括：`encode()` 结果类检查、`size_unit` 合法性、`autofit` 与 `width`/`height` 关联约束。
- **透传给底层库的通用参数** → 交由 ggplot2 / grDevices 自然报错，包层不添加冗余验证。

### 1.4 契约分层与版本策略

> 当前为 0.x，API 仍在演进。

**核心契约**（跨主版本稳定，1.0 后修改需主版本号升级）：
- 函数名：`plotit()`、`encode()`、`mark_*`、`scale_*`、`label_*`、`compose_*`、`style()`、`export()`
- 返回类型：所有操作返回 `plotit`，支持管道
- `plotit()` 的 `data` 和 `mapping` 参数

**扩展契约**（1.0 后稳定，2.0 可调整）：
- `scale_*` 的 `trans` 合法值集合（可增加，不删除）
- `label_*` 的参数协议（`text`/`hide`/`reset`）
- `project_*`/`split_*` 的参数签名

**可迭代**（不破坏上述两层契约）：
- 默认主题参数、启发式算法、默认调色板、内部工具函数实现

> **例外**：若 1.x 期间发现扩展契约中的设计缺陷导致不可逆的错误输出，允许经由弃用→警告→移除的标准周期（跨至少一个次版本）修正。此种修正不视为破坏性变更。

### 1.5 自动生成的内容绝不手动维护

| 自动 | 手动 |
|------|------|
| `NAMESPACE`（roxygen2 `@export`） | `R/*.R` 源码 |
| `man/*.Rd`（roxygen2） | `tests/` |
| `DESCRIPTION` Collate（`@include`） | `DESCRIPTION` 元信息 |

每次增删 `.R` 文件或修改 roxygen 注释（`@param`、`@description`、`@return` 等）后，必须执行 `roxygen2::roxygenize()` 同步 `.Rd` 文件，且 `.Rd` 变更与源码在同一 commit 中提交。新建文件头部必须用 `@include` 声明内部依赖。

### 1.6 约定文档动态更新

以下情况必须同步更新 AGENTS.md：新增/删除/修改导出函数、修改参数签名或默认值、修改返回类型或管道行为、修改契约分层、引入新设计原则或废止旧原则。

约定与实现偏离时：首先判断偏离方向——实现是改进还是退化？若为改进，修约定以匹配实现；若为退化，修实现以匹配约定。约定是当前最佳理解的快照，实现可以反过来修正约定。

---

## 2. 技术选型

- **面向对象**：**S7** 包。核心类：`plotit_labels`（文本字段）、`plotit_metadata`（配置项）、`plotit`（持有 `gg` + `meta`）。S7 作为较新的 OOP 系统，若未来发生不兼容变更，项目将锁定版本或评估迁移至 S3/R6。
- **核心依赖**：ggplot2、S7、cli、patchwork。`ggrastr` 为可选增强依赖（图层栅格化）。
- **未来扩展**（按需引入）：ggrepel、ggbeeswarm、treemapify、ggsankey、sf。

---

## 3. API 函数族体系

### 3.1 函数族总览

| 函数族 | 职责 | ggplot2 对应 |
|---|---|---|
| `plotit()` | 初始化图表对象 | `ggplot()` |
| `encode()` | 构造美学映射 | `aes()` |
| `mark_*` | 添加几何图层 | `geom_*` |
| `scale_*` | 数据→视觉映射 + 显示控制 | `scale_*` |
| `project_*` | 坐标系变换 | `coord_*` |
| `split_*` | 分面布局 | `facet_*` |
| `label_*` | 文本标签 | `labs()` |
| `style()` | 主题设置 | `theme()` |
| `compose_*` | 多图组合布局 | `patchwork`（`wrap_plots` / `inset_element` / `plot_layout` / `plot_annotation`） |
| `export()` | 图表导出 | `ggsave()` |

### 3.2 `mark_*` 目录

**已实现**（6 个）：

| 函数 | 对应 | 用途 |
|---|---|---|
| `mark_point` | `geom_point` | 散点 |
| `mark_line` | `geom_line` | 折线 / 趋势 |
| `mark_bar` | `geom_bar` / `geom_col` | 柱状图（有 y 映射→`geom_col`，无 y→`geom_bar`） |
| `mark_boxplot` | `geom_boxplot` | 箱线图 |
| `mark_histogram` | `geom_histogram` | 直方图 |
| `mark_density` | `geom_density` | 密度曲线 |

**规划中**（签名与行为在开发中确定）：

| 类别 | 函数 | 对应机制 |
|---|---|---|
| 基础几何 | `mark_area`, `mark_path`, `mark_rect`, `mark_tile`, `mark_polygon`, `mark_text`, `mark_rule` | geom_* / ggrepel |
| 分布展示 | `mark_histogram`, `mark_violin`, `mark_beeswarm` | geom_* / ggbeeswarm |
| 关系与层次 | `mark_network`, `mark_tree`, `mark_sankey`, `mark_chord`, `mark_treemap`, `mark_sunburst`, `mark_circlepacking`, `mark_venn` | igraph / ggtree / ggsankey / treemapify 等 |
| 地理空间 | `mark_map`, `mark_link` | sf / geom_segment |

---

### 3.3 各函数族详细约定

#### 3.3.1 `plotit()` — 初始化

```r
plotit(data, mapping = encode(), autofit = FALSE,
       width = 7, height = 5, size_unit = "in",
       dodge = NULL, default_color = "#4E79A7")
```

| 参数 | 说明 |
|---|---|
| `data` | 数据框（必填） |
| `mapping` | `encode()` 产生的美学映射，包层做类检查 |
| `autofit` | `TRUE` 时 `width`/`height` 置 `NULL` 交由设备自适应（若同时提供尺寸值，警告并忽略） |
| `width`, `height` | 面板尺寸（非总尺寸）；`autofit=FALSE` 时两者均非 NULL 才有效 |
| `size_unit` | `"in"` / `"cm"` / `"mm"`，始终验证合法性，不受 `autofit` 影响 |
| `dodge` | 全局默认躲避宽度；`NULL` 时启发式判断（离散 X/Y → 设 dodge） |
| `default_color` | 无 `colour`/`fill` 映射时同时注入 `colour` 和 `fill`（默认 `"#4E79A7"` 蓝色）；添加任何 colour/fill scale 后自动失效 |

**尺寸优先级链**：显式传参 > meta 存储 > autofit 自适应。

#### 3.3.2 `encode()` — 美学映射

`encode(...)` 全部透传给 `ggplot2::aes()`，返回带 `"plotit_encode"` 类的对象。

#### 3.3.3 `mark_*` — 几何图层

- 第一参数 `plotit`，返回 `plotit`
- `mapping`、`data`、`position`：`data=NULL` 继承全局数据；`position=NULL` 自动读取全局 dodge
- `...` 透传给底层 `geom_*`
- 所有函数支持 `rasterize`、`rasterize_dpi`、`rasterize_dev`（需 `ggrastr`）

#### 3.3.4 `scale_*` — 比例尺

设计对标 **Vega/Vega-Lite** 的 scale 模型（`type`/`domain`/`range`/`scheme` 四要素）。`trans` 决定映射类型，`limits` 裁剪输入域，`range` 定义输出值域——三者构成完整的"数据→视觉"通道。`name`/`breaks`/`labels` 为显示层辅助，不属于 Vega scale 核心。positional `range` 语义对齐 Vega 的 `range: [0, width]`（归一化面板占比）。

8 函数，8 参数，仅 `trans` 默认值不同：

```r
scale_<aes>(p, name = waiver(), trans = <默认>,
            limits = NULL, range = NULL,
            breaks = NULL, labels = NULL, ...)
```

| 参数 | 对应 Vega | 职责 |
|---|---|
| `name` | — | 显示辅助：`waiver()` = 沿用变量名 |
| `trans` | `type` | 映射算法：linear / log / band / ordinal / bin |
| `limits` | `domain` | 数据边界，裁剪输入范围 |
| `range` | `range` + `scheme` | 视觉输出值域 + 调色板方案名 |
| `breaks` | — | 显示辅助：刻度/图例键位置 |
| `labels` | — | 显示辅助：刻度/图例键文字 |
| `...` | — | 透传底层 ggplot2 scale 参数 |

**`trans` 合法值**：

> **决策**：选择统一参数名 `trans` 而非拆分为 `trans_pos` / `trans_vis`——减少 API 表面积，一个词学会全部。代价：用户需知道 `log` 对颜色无效。若使用反馈显示用户频繁困惑，考虑在 2.0 中拆分。

| `trans` | x/y（位置标度） | colour/fill/size/alpha（视觉连续） | shape/linetype（视觉离散） |
|---|---|---|---|
| `NULL` | → identity | auto-detect | → discrete |
| `"identity"` | ✅ 默认 | ✅ 默认 | ❌ |
| `"log"` / `"log10"` / `"log2"` / `"sqrt"` | ✅ | ❌ | ❌ |
| `"reverse"` | ✅ | ✅ | ✅ |
| `"discrete"` | ✅ | ✅ | ✅ 默认 |
| `"binned"` | ✅ | ✅ | ❌ |

各函数默认 `trans`：

| 函数 | 默认 `trans` | 含义 |
|---|---|---|
| `scale_x` / `scale_y` | `"identity"` | 连续线性 |
| `scale_color` / `scale_fill` | `NULL` | 自动检测（离散→`"discrete"`，连续→`"identity"`） |
| `scale_size` / `scale_alpha` | `NULL` | 同上 |
| `scale_shape` / `scale_linetype` | `"discrete"` | 离散（连续无效） |

不支持的组合给出 `cli::cli_abort` 定向错误。

内部校验矩阵：
```r
trans_legal <- list(
  positional   = c("identity", "log", "log10", "log2", "sqrt", "reverse", "discrete", "binned"),
  visual_cont  = c("identity", "discrete", "binned", "reverse"),
  visual_disc  = c("discrete", "reverse")
)
```

**`range` 合法值**：

> **Vega 对齐**：所有 scale 的 `range` 语义统一为**视觉输出值域**——对标 Vega/D3 的 scale range 概念。对颜色，输出值是颜色向量；对坐标轴，输出值是面板占比（归一化比例 0–1）。这与 Vega 中 positional scale 的 `range: [0, width]` 设计一致。

| aesthetic | `range = NULL` | `range = "name"` | `range = c(a, b)` |
|---|---|---|---|
| colour/fill | 离散→hue，连续→viridis | `"viridis"` `"brewer"` `"grey"`(仅离散) `"hue"` | 颜色向量 |

> `"grey"` 仅适用于离散变量。`"brewer"` 对 binned 不可用（binned 仅支持 `"viridis"`）。
| size | `c(1, 6)` | — | 数值范围 |
| alpha | `c(0.1, 1)` | — | 数值范围 |
| shape | 默认形状集 | — | 形状编号 |
| linetype | 默认线型集 | — | 线型名称 |
| x/y | `c(0, 1)`（铺满面板） | — | 归一化面板占比如 `c(0.1, 0.9)`（数据占据中间 80%） |

**x/y 的 `range`**：表示数据在面板上的**视觉占比**，而非数据值。`range=c(0.1, 0.9)` 表示数据范围映射到面板的 10%–90% 区域。通过计算 `limits` + `expand=c(0,0)` 精确实现。与 `limits` 同时非 NULL 时后设置者胜，冲突时警告。

**格式推断**：包层根据输入格式自动判断意图——单字符串→调色板方案，颜色向量→渐变，数值向量→值域，整数向量→形状编号，非颜色字符向量→线型。

**`trans` × `range` 协同**：包层根据组合选择底层 scale 函数。核心规则：
- `trans="identity"/"binned"` + `range="viridis"` → `scale_colour_viridis_c/b()`
- `trans="discrete"` + `range=c(...)` → `scale_colour_manual()`
- `trans="reverse"` → 对应版本 + `direction=-1` 或 `guide_legend(reverse=TRUE)`

**`name` vs `label_*`**：`scale_*(name=)` 设置 scale 层默认名，`label_*` 设置最终显示名——后执行者胜。

**default_color 覆盖**：任何用户提供的 `colour`/`fill` 映射都必须触发清除 `default_color` 注入的 `mapping$colour`/`mapping$fill` 和 `guides(colour="none", fill="none")`。当前三处清除点（`._reset_default_color`、`._auto_reset_default_color`、`project_parallel`）均已对称处理 `colour`/`fill` 两侧，待统一收归为单一内部函数（1.0 前待办）。

#### 3.3.5 `project_*` — 坐标系

| 函数 | 底层 | 关键参数 |
|---|---|---|
| `project_cartesian` | `coord_cartesian` / `coord_flip` / `coord_fixed` / `coord_trans` | `xlim`, `ylim`, `expand`, `flip`, `fixed`, `coord_trans`, `clip`, `...` |
| `project_polar` | `coord_polar` / `coord_radial` | `theta`, `start`, `direction`, `inner_radius`, `r_axis_inside`, `clip`, `...` |
| `project_parallel` | 数据重塑 + `geom_line` / `geom_point` | `columns`, `group`, `scale`, `alpha`, `size`, `clip`, `...` |
| `project_map` | `coord_sf` / `coord_map` | `projection`, `xlim`, `ylim`, `clip`, `...` |

`project_parallel` 将选定列重塑为长格式，绘制平行坐标折线。架构参考 **Vega 平行坐标**的实现（`vega.github.io/vega/examples/parallel-coordinates/`）：Vega 为每列定义独立的 linear scale 并渲染真实原生 axis（`orient: "left"`），通过 ordinal scale 加 offset 将每列轴平移至对应 x 位置。plotit 等效实现采用三模式互斥设计：

| 模式 | 归一化 | y 轴 | 每列轴 |
|---|---|---|---|
| `scale="std"` | 每列 min-max → [0,1] | 共享原生 `scale_y_continuous()` | 无（原生 y 轴提供刻度和标签） |
| `scale="global"` | 全局 min-max → [0,1] | 共享原生 `scale_y_continuous()` | 无 |
| `scale="none"` | 无 | 抑制原生 y 轴 | 每列手动渲染轴线（`geom_vline` + `axis.line.y`）、单向刻度（`geom_segment` + `axis.ticks.y`）、首尾列数值标签（`geom_text` + `axis.text.y`）、顶部列名标题（`geom_text` + `axis.title`） |

横轴使用原生 `scale_x_discrete()` 显示列名标签，但通过 `theme(axis.line.x/axis.ticks.x = element_blank())` 关闭轴线与刻度。`std`/`global` 模式下刻度/标签由 ggplot2 guide 系统 100% 原生渲染；`none` 模式下的每列轴尽可能匹配 `axis.*` 主题属性以保持风格一致。`project_map` 默认使用 `coord_sf()`；传入 `projection` 参数时切换到 `coord_map()`（需 `mapproj`）。`project_polar` 的径向模式（`inner_radius > 0` 或 `r_axis_inside = TRUE`）需要 ggplot2 ≥ 3.5.0。

> **`scale="none"` 的已知局限性**：此模式下每列轴由包层通过 `geom_segment`（轴线+刻度）和 `geom_text`（标签）手动绘制，而非使用 ggplot2 原生 guide 系统。轴线颜色/线宽/字体从当前主题的 `axis.*` 元素提取（`._parallel_theme_props`），但**不保证与原生轴在所有 ggplot2 版本下 100% 像素一致**。推荐优先使用 `scale="std"` 或 `scale="global"`，仅在需要保留原始量纲时使用 `scale="none"`。此限制源于 ggplot2 不原生支持单一面板上的多个独立 y 轴——在一个面板上渲染多套坐标轴的唯一方式就是手动绘制。

> **注意**：`project_cartesian(coord_trans=)` 与 `scale_*(trans=)` 含义不同。前者是**坐标系变换**（`coord_trans`），改变坐标轴物理缩放；后者是**数据标度变换**，改变数据到视觉属性的映射。`trans` 参数名已在 0.x 中重命名为 `coord_trans`——旧名不再接受，无弃用过渡（0.x 版本不保证 API 稳定）。

> **注意**：`project_cartesian(coord_trans=)` 与 `scale_*(trans=)` 含义不同。前者是**坐标系变换**（`coord_trans`），改变坐标轴物理缩放；后者是**数据标度变换**，改变数据到视觉属性的映射。`trans` 参数名已在 0.x 中重命名为 `coord_trans`——旧名不再接受，无弃用过渡（0.x 版本不保证 API 稳定）。

#### 3.3.6 `split_*` — 分面

| 函数 | 底层 | 关键参数 |
|---|---|---|
| `split_wrap` | `facet_wrap` | `...`（无名参数=分面变量；命名参数透传如 `labeller`, `dir`）, `ncol`, `nrow`, `scales` |
| `split_grid` | `facet_grid` | `...`（无名参数=`rows`简写；命名参数透传如 `labeller`, `switch`）, `rows`, `cols`, `scales`, `space` |

`split_grid` 的 `...` 无名参数可作为 `rows` 的简写（单变量）。同时使用 `...` 和 `rows` 时以 `...` 为准并报警告。命名参数（如 `labeller`）透传给底层 `facet_wrap()`/`facet_grid()`。

#### 3.3.7 `label_*` — 文本标签

**统一行为**：写入 `meta$labels` 并立即应用到 `gg`。`label_*` 是标签修改的唯一入口。

**三参数协议**（`text` + `hide` + `reset`）：

> **决策**：旧版 `text=NULL` 重置变量名——简洁但反直觉（空参数产生副作用）。新版 `text=NULL` 是空操作，引入 `reset` 显式控制。代价是引入了第三个参数；通过优先级规则（见下）消除了调用顺序依赖。

**优先级规则**（调用顺序不影响结果）：

| 优先级 | 参数 | 效果 |
|---|---|---|
| 1（最高） | `reset = TRUE` | 恢复变量名（轴/图例）或移除文本（标题/副标题/脚注）。**无视** `text` 和 `hide`。 |
| 2 | `hide = TRUE` | 移除元素及占位空间（`element_blank()`）。无视 `text`。 |
| 3（最低） | `text = "str"` | 设置自定义文本。仅在前两者均为 FALSE 时生效。 |
| — | 所有默认 | 保持现状。 |

`text`（非 NULL）与 `reset=TRUE` 同时提供时报错（与优先级规则一致——reset 最高，text 不应该被提供）。

| 函数 | 参数 | 用途 |
|---|---|---|
| `label_title` | `text`, `hide`, `reset` | 主标题 |
| `label_subtitle` | `text`, `hide`, `reset` | 副标题 |
| `label_caption` | `text`, `hide`, `reset` | 脚注 |
| `label_axis` | `text`, `aes`, `hide`, `reset` | `aes = "x"` 或 `"y"`（必填） |
| `label_legend` | `text`, `aes`, `hide`, `reset` | `aes = "colour"`/`"fill"` 等 |

**与 `scale_*(name=)` 的关系**：`label_*` 优先级更高。`label_axis(aes="x")`（全默认）不覆盖 `scale_x(name="Width")`。缺省值：轴/图例标题缺省为变量名；标题/副标题/脚注无默认。

**`label_legend` 的 `aes = NULL` 全局模式**：当不指定 `aes` 时影响所有已映射美学。若后续对单个 aes 调用 `label_legend(aes = "colour")`，后者覆盖全局设置（后执行者胜）。`meta$legend` 中 `"default"` 条目与具体 aes 条目共存但后者优先生效。

> `default` 与具体 aes 的优先级由 `label_legend()` 方法统一处理：`aes=NULL` 时写入 `meta$legend[["default"]]` 并应用到当前所有已映射美学；后续对单个 aes 的调用会覆盖之（后执行者胜）。逻辑集中，无需额外抽象。

#### 3.3.8 `style()` — 主题

对齐 `ggplot2::theme()` 的调用方式。`style(p)` 应用默认主题，`style(p, plot.title = element_text(...))` 覆盖单个元素，`style(p, base_theme = theme_bw())` 切换基础主题。

- `style(plot, ..., base_size, base_family, base_theme)`：先应用基础主题（默认 `theme_minimal` 定制版），再叠加 `ggplot2::theme(...)` 覆盖。
- `style_default(plot, base_size, base_family)`：`style()` 的便捷别名，仅应用默认主题。

#### 3.3.9 `export()` — 导出

```r
export(plot, filename, width = NULL, height = NULL, dpi = 300, device = NULL, ...)
```

尺寸优先级：显式传参 > meta 存储值 > autofit 自适应。

- `autofit = FALSE` + 未传尺寸：通过 gtable 测量获得总尺寸（面板尺寸来自 meta，已在构造时由 `plot_layout()` 固定；轴/标签/图例由当前主题决定）。
- `autofit = TRUE` + 未传尺寸：回退 `getOption("plotit.default_width", 7)` / `getOption("plotit.default_height", 5)`（单位始终为英寸）。

> **`size_unit` 与导出**：`export()` 显式传入的 `width`/`height` 遵循 `plotit()` 时设定的 `size_unit` 进行换算。未传入时，`autofit=FALSE` 使用 gtable 测量（英寸），`autofit=TRUE` 使用全局选项默认值（英寸）。

单位统一为英寸后传给 `ggsave()`。

#### 3.3.10 图片尺寸算法

- `plotit()` 的 `width`/`height` 指**面板尺寸**（非总尺寸）。
- `autofit = FALSE`：通过 `patchwork::plot_layout()` 固定面板为绝对单位。

**契约边界**：当 `autofit = FALSE` 时，面板尺寸将得到遵守（允许因设备精度导致的 ±1% 浮点误差）。总尺寸（面板 + 轴 + 标签 + 图例 + 边距）是衍生值，不在 API 契约内，可能随主题/字体/设备版本微小变化。替换实现只需遵守面板尺寸契约，不视为破坏性变更。

> 当前实现基于 patchwork gtable 测量。此为已知耦合点——patchwork 或 ggplot2 升级可能影响测量精度。替换方案允许，只要面板尺寸契约不被破坏。
>
> **1.0 前待办**：移除 patchwork 依赖，改用 `ggplot2::ggplot_build()` + `grid` 手动修改 gtable 面板尺寸。当前 patchwork 方案使 `@gg` 存储的是 `patchwork` 对象而非纯 `ggplot`，违背"完全基于 ggplot2 构造"的声明。
>
> **剥离路线图（设计文档，非实现）**：
> 1. **单图面板尺寸**：`plotit()` 不再调用 `patchwork::plot_layout()`。改为在 `export()`/`print()` 时通过 `ggplot2::ggplot_build()` 获得 gtable，再使用 `grid::convertWidth` / `grid::convertHeight` 锁定面板为绝对单位。`@meta` 中的 `width`/`height`/`unit` 保持不变。
> 2. **组合图布局**：`compose_*` 函数改用 `gridExtra::grid.arrange()` 或纯 `grid` 组装多个 gtable，替代 `patchwork::wrap_plots()`。每个子图的 gtable 通过 `ggplot_build()` 获得。组合后的总尺寸从各子图 gtable 求和得出。
> 3. **影响评估**：`._reset_sizing()` 和 `._assemble_plots()` 将被移除；`compose_*` 的核心实现需要重写；`plotit()` 构造函数简化。



#### 3.3.11 `compose_*` — 图形组合

将多个 `plotit` 图表组装为多面板布局。与 `split_*`（一分多，数据层面）正交——`compose_*` 是"多合一"（图表层面），每个子图可有完全不同的数据、几何图层、坐标系和标度。

##### API 签名

```r
compose_grid(..., ncol = NULL, nrow = NULL, byrow = TRUE,
             widths = NULL, heights = NULL, guides = NULL,
             axes = "keep", tag_levels = NULL)

compose_inset(base, inset, left = 0, bottom = 0, right = 1, top = 1,
              align_to = "panel", on_top = TRUE, ...)

compose_marginal(main, top, right, widths = c(4, 1), heights = c(1, 4),
                 guides = "collect")
```

##### 参数说明

| 参数 | 适用函数 | 默认 | 说明 |
|---|---|---|---|
| `ncol` / `nrow` | `compose_grid` | `NULL` | 都 NULL → 默认 `ncol=1`（纵向堆叠）；仅设 `nrow=1` → 横向 |
| `widths` / `heights` | `compose_grid`, `compose_marginal` | `NULL` | 面板比例，如 `c(3, 1)` 左宽右窄 |
| `guides` | `compose_grid`, `compose_marginal` | `NULL` / `"collect"` | `"collect"` 合并图例，`"keep"` 独立，`NULL` 自动 |
| `axes` | `compose_grid` | `"keep"` | `"collect"` 共享全部轴，`"collect_x"`/`"collect_y"` 单方向 |
| `tag_levels` | `compose_grid` | `NULL` | `"A"`/`"a"`/`"1"`/`"i"` 或自定义字符向量 |
| `left`/`bottom`/`right`/`top` | `compose_inset` | `0,0,1,1` | 嵌入位置 (npc 0–1) |
| `align_to` | `compose_inset` | `"panel"` | `"panel"` 或 `"plot"` |
| `on_top` | `compose_inset` | `TRUE` | 嵌入置于前景 |

##### 返回类型与管道

全部返回 `plotit_composite`（S7 类）。槽位：
- `@gg` — 组装后的 patchwork ggplot（不含注释，注释惰性注入）
- `@plots` — list of 子 `plotit` / `plotit_composite`
- `@layout` — 布局参数 list
- `@annotations` — list(`title`, `subtitle`, `caption`, `tag_levels`)

以下现有函数通过 S7 多分派无缝衔接，管道不中断：
- `label_title()` / `label_subtitle()` / `label_caption()` → 写入 `@annotations`，`print()`/`export()` 时通过 `patchwork::plot_annotation()` 一次性渲染（惰性，消除调用顺序依赖）
- `style()` → `theme()` 应用到组装后的 patchwork
- `export(p, filename, width, height, dpi, device, ...)` → gtable 测量 + `ggsave()`；不传 `width`/`height` 则自动测量
- `print()` → 委托 RStudio Plots 窗格渲染

**不支持的操作**：`mark_*` / `scale_*` / `project_*` / `split_*` / `label_axis` / `label_legend` 不接受 `plotit_composite`——先构建再组合。

##### `compose_grid` 细节

- 默认 `ncol=NULL, nrow=NULL` → `ncol=1`（纵向堆叠）。仅设 `nrow=1` 则横向并排，`ncol` 保持 NULL 由 patchwork 推断。
- `axes` 封装 `patchwork::plot_layout(axes=)`，操作于组合层面。
- `tag_levels` 存入 `@annotations`，惰性注入。
- 嵌套：`compose_grid()` 接受 `plotit_composite`，组合可嵌套。
- 单图：`compose_grid(p)` 合法，返回包含单图的 composite（便于打 tag）。

##### `compose_inset` 细节

- base 的 `@gg` 在组装前调用 `._reset_sizing()` 剥除固定面板尺寸，防止嵌入图裁切。
- 返回 composite 接受 `label_*` / `style()` / `export()`。

##### `compose_marginal` 细节

- 布局：`wrap_plots(design="AB\nCD")` 扁平 2×2（顶部直方图 + 角落空白 / 主散点 + 右侧直方图）。
- **共享坐标轴**：组装前对 `top_gg` 隐藏 X 轴文字/标题/刻度，对 `right_gg` 隐藏 Y 轴文字/标题/刻度（`+ theme(axis.text.* = element_blank(), ...)`）。组装后 X 轴只出现在主散点底部，Y 轴只出现在主散点左侧，轴线完全对齐。右侧直方图需用户调用 `project_cartesian(flip=TRUE)` 翻转以对齐 Y 轴。
- 图例默认合并（`guides="collect"`），可传 `"keep"` 独立。

---

### 3.4 补充约定

- **空数据与缺失值**：空 data.frame 行为由 ggplot2 决定。`NA` 由 ggplot2 默认静默移除。
- **S7 槽位**：`plotit_labels`（`title`/`subtitle`/`caption`/`x`/`y`/`legend`）、`plotit_metadata`（`autofit`/`width`/`height`/`dodge`/`unit`/`default_color`/`labels`）、`plotit`（`gg`/`meta`）。
- **打印与设备**：`print()` 在交互模式下通过 `grDevices::dev.new(noRStudioGD = TRUE)` 打开独立设备窗口以保证面板尺寸物理呈现。用户可设置 `options(plotit.device = "rstudio")` 使用 RStudio 面板，或 `options(plotit.device = NULL)` 完全禁用自动设备打开。`export()` 从文件名推断设备。

---

## 4. 代码风格

### 4.1 文件结构

```
R/
├── class.R      # S7 类定义
├── encode.R     # encode()
├── utils.R      # 工具函数
├── plot.R       # plotit()
├── mark.R       # 所有 mark_*
├── scale.R      # 所有 scale_*
├── project.R    # 所有 project_*
├── split.R      # 所有 split_*
├── label.R      # 所有 label_*
├── compose.R    # compose_grid() + compose_inset() + composite 方法
├── style.R      # style() + 默认主题
├── output.R     # print() + export()

tests/testthat/
├── test-encode.R  test-plot.R    test-mark.R
├── test-scale.R   test-label.R   test-project.R
├── test-split.R   test-style.R   test-export.R
├── test-compose.R
```

文件名 `snake_case.R`。`R/` 下只放包源码。`playground.R` 用于临时手动测试，不纳入版本管理。

### 4.2 命名与格式

- `snake_case`，动词前缀统一。`color`/`colour` 等价接受，函数命名统一美式拼写。
- 缩进 2 空格，行宽 80 字符。Push 前执行 `styler::style_pkg()`。

### 4.3 代码文本一律使用英文

代码注释、roxygen 文档、错误消息、警告信息、提交信息一律使用英文。（AGENTS.md 本身以中文撰写，面向中文开发者。）

### 4.4 管道

所有对象修改函数返回 `plotit`，支持 `|>`。每个管道步骤独立一行。

### 4.5 错误信息

主动验证点使用 `cli::cli_abort()`。其他位置由底层 API 自然抛出。

警告信息必须无歧义：明确说出哪个参数生效、哪个被忽略，禁止"X overrides Y (latter wins)"等指代不明的措辞。

### 4.6 命名空间与 ggplot2 交互

使用 `pkg::fun()` 显式调用外部函数。内部用 `%||%` 处理 NULL 默认值。

**优先使用公开 API**：所有视觉修改首先尝试 `+ labs()`、`+ guides()`、`+ theme()` 等 ggplot2 公开函数。

**直接槽位访问（允许）**：
- `gg$mapping` — 公开槽位，可读写。
- `gg$data` — 公开槽位，可读写。
- `gg$labels` — 公开槽位（ggplot2 文档化的 `list of labels for the plot`），可读写。当 `labs(a = NULL)` 因 `modifyList` 的 `keep.null` 默认行为无法正确清空标签时，可直接操作此槽位。
- `gg$theme` — 公开槽位，允许只读访问（如 `calc_element()`）；修改必须通过 `+ theme()`。

**禁止直接访问**：`gg$scales$scales`、`gg$layers` 等未文档化的内部结构。这些在 ggplot2 小版本升级时无兼容保证。测试中也禁止检查这些内部槽位。

**非标准求值只用 rlang**：数据掩码场景（列名查找）必须使用 `rlang::eval_tidy()`，禁止 `eval()` + `baseenv()` 组合。

### 4.7 Roxygen 文档

每个导出函数必须包含：标题 + 描述、`@param`（每个参数，含合法取值列表）、`@return`、`@export`。

### 4.8 测试

按函数族分文件。覆盖合法值及关键组合、非法输入的错误路径、管道链集成场景。

**断言行为而非内部状态**：测试应验证用户可见结果，使用 `ggplot2::ggplot_build(p@gg)` 提取最终渲染数据进行断言。

**BDD 测试规范**（已全面应用）：
- **断言锚点**：`ggplot2::ggplot_build(p@gg)` 返回的 `$plot$labels`、`$plot$theme`、`$plot$scales`、`$layout`、`$data`。
- **禁止检查**：`@gg$layers`、`@gg$labels`、`@gg$theme`、`@meta@...` 等内部槽位（重构时内部表示可能合法变更）。
- **标记**：BDD 测试以 `[BDD]` 前缀标注，方便识别。
- **覆盖状态**：9/9 测试文件已完成 BDD 迁移，零内部槽位断言残留。✅ (278 tests, 0 fail, 0 warn)

---

## 5. 默认美观要求

属于 §1.4 可迭代范围，具体参数可随版本调整。

- **主题**：基于 `theme_minimal`，背景透明，无网格线，保留轴线（浅灰），无衬线字体，层级分明的字号。极坐标系自动关闭轴线、刻度线和轴文本。平行坐标系遵循 Vega 参考架构：`std`/`global` 模式使用共享原生 y 轴，`none` 模式每列渲染主题匹配轴线。
- **颜色**：无映射时默认 Tableau 蓝（`#4E79A7`），同时应用于 `colour` 和 `fill`，图例隐藏。有映射时默认 viridis（色盲友好）。
- **图例**：右侧，背景透明，边框简洁。
- **尺寸**：自适应关闭时默认约 7×5 英寸，导出 300 dpi。

---

## 6. 实现 Demo

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

p <- style(p, ggplot2::theme_minimal(base_size = 12))

export(p, "output.pdf", dpi = 300)
```

---

## 7. Bug 审查原则

| # | 原则 | 检查点 |
|---|------|--------|
| 0 | 区分特性与 Bug | 静默忽略若无注释或测试说明意图→视为 Bug。参数传入不生效是 Bug 的充分条件。 |
| 1 | 参数全链路追踪 | 每个中转节点：直接转发 / 转换 / 被丢弃？ |
| 2 | 枚举值分支穷举 | N 个合法值 → N 条路径全部显式存在 |
| 3 | 对称抽象一致性 | color↔fill, size↔alpha, shape↔linetype, x↔y |
| 4 | 默认值分叉 | 新增条件分支 → 同步更新默认值逻辑 |
| 5 | 底层接口兼容性 | 透传前确认底层接受该参数；不接受时切换函数 |
| 6 | 内部概念不泄漏 | 包层参数名可能与底层同名但语义不同（如 `trans="binned"`） |
| 7 | 有状态默认值对称清除 | `default_color` 同时注入 `mapping$colour`/`mapping$fill` + `guides(colour="none", fill="none")`。任何图层级 `colour`/`fill` 映射触发清除时必须对称处理两侧。已统一为 `._clear_default_color()`（`utils.R`），`mark_*`/`scale_*`/`project_parallel` 三处共用。✅ |
| 8 | 契约边界可验证 | 契约必须用用户可见的指标定义（如面板尺寸 ±1%），不能用"±5% 容差"等无法验证的免责声明。 |

---

## 8. 现状评估与 1.0 路线图

### 8.1 API 完成度

| 函数族 | 规划数 | 已实现 | 完成度 |
|---|---|---|---|
| plotit() + ncode() | 2 | 2 | 100% |
| mark_* | 22 | 6 | 27% |
| scale_* | 8 | 8 | 100% |
| project_* | 4 | 4 | 100% |
| split_* | 2 | 2 | 100% |
| label_* | 6 | 6 | 100% |
| style() + xport() | 3 | 3 | 100% |
| compose_* | 3 | 3 | 100% |
| **总计** | **~50** | **34** | **~68%** |

### 8.2 设计原则符合度

| 原则 | 状态 |
|---|---|
| 简化语法、动词前缀、管道 | ✅ 一致 |
| 元数据集中管理（§1.2） | ✅ meta@labels 集中存储，惰性同步 |
| 分域验证（§1.3） | ✅ cli::cli_abort 主动验证 |
| 契约分层（§1.4） | ✅ 三层结构清晰 |
| 自动生成不手动维护（§1.5） | ✅ roxygen2 驱动 |
| 约定文档动态更新（§1.6） | ✅ 持续同步 |

### 8.3 综合质量评分（2026-06-26）

`
维度         评分   说明
API 完整度    6.8   mark_* 覆盖率不足
架构设计      8.5   S7 + 惰性标签 + 集中元数据
代码质量      7.5   干净代码，但 mark_* 有大量样板代码
文档          6.5   AGENTS.md 强，缺 vignette / pkgdown
测试覆盖      6.0   278 测试，但深度不足（BDD 约 ~15%）
基础设施      5.0   无 CI/CD、无 pkgdown、无 @examples
              ────
综合          7.0   (0.x 阶段，重心在 API 设计正确性)
`

---

## 9. 已知技术债务与待办

### 9.1 架构债务

| # | 事项 | 优先级 | 说明 |
|---|---|---|---|
| AD-1 | **Patchwork 剥离**（§3.3.10） | 中 | utofit=FALSE 时 @gg 存储 patchwork 对象而非纯 ggplot。剥离路线图已设计，未实施。 |
| AD-2 | **._collect_aes_names 不再扫描 layers** | 低 | P7 修复后不再检测图层级美学映射。label_legend(aes=NULL) 的图例标题变更不会应用到仅在图层级出现的离散变量。 |
| AD-3 | **._sync_labels 函数结构** | 低 | 5 个几乎相同的 if 块（title/subtitle/caption/x/y），可抽象为循环。 |
| AD-4 | **S7 版本锁定** | 低 | DESCRIPTION 中无 S7 版本限制。S7 仍在 0.x 阶段，不兼容变更可能随时发生。 |
| AD-5 | **mark_* 样板代码** | 低 | 每个 ~15 行 S7 泛型+方法定义，可用代码生成简化。 |

### 9.2 功能缺口

| # | 事项 | 优先级 | 说明 |
|---|---|---|---|
| FG-1 | **mark_* 补充** | 高 | 规划 22 种几何，目前只实现 6 种。1.0 前重点：mark_area、mark_violin、mark_text、mark_tile、mark_path |
| FG-2 | **mark_histogram 已在已实现表中但规划表中重复** | 低 | §3.2 表格将 mark_histogram 同时列在已实现和规划中，需清理。 |

### 9.3 文档与基础设施

| # | 事项 | 优先级 | 说明 |
|---|---|---|---|
| DI-1 | **Vignette** | 高 | 至少 2-3 篇："Getting Started"、"Customizing Plots"、"Composing Figures" |
| DI-2 | **pkgdown 网站** | 中 | 函数参考 + vignette 集成 |
| DI-3 | **@examples** | 中 | 每个导出函数的 roxygen 文档缺少可运行示例 |
| DI-4 | **CI/CD** | 中 | GitHub Actions：R CMD check + testthat 自动化 |
| DI-5 | **roxygen 链接警告** | 低 | scale.R:538、scale.R:573 中 c(0, 1) 被误解析为链接目标 |

### 9.4 测试

| # | 事项 | 优先级 | 说明 |
|---|---|---|---|
| TE-1 | **BDD 渲染测试扩展** | 中 | 从 ~15% 提到 40%+。目前大部分 scale 测试只检查 xpect_s3_class（不崩溃），不验证实际视觉效果。 |
| TE-2 | **惰性标签集成测试** | 中 | 新增测试验证 ._sync_labels + xport() 的渲染结果与直接修改 gg 一致。 |

### 9.5 1.0 前必做检查项

- [ ] mark_* 扩至至少 15 个（重点：area, violin, text, tile, path）
- [ ] 2-3 篇 vignette（"Getting Started"、"Customizing Plots"、"Composing Figures"）
- [ ] pkgdown 网站 + GitHub Actions CI
- [ ] 为所有导出函数补充 @examples
- [ ] BDD 测试覆盖率提到 40%+
- [ ] 惰性标签集成测试（验证 ._sync_labels + xport() 渲染结果）
- [ ] Patchwork 剥离（§3.3.10 路线图）
- [ ] S7 版本锁定（Imports: S7 (>= 0.1.0)）
- [ ] 修复 scale.R roxygen 链接警告
- [ ] styler::style_pkg() + oxygen2::roxygenize()（每次 PR 前执行）
