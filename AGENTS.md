# plotit 开发约定

## 1. 设计原则

### 1.1 核心价值

- **简化语法**：动词前缀命名（`mark_*`、`scale_*`、`project_*` 等），支持管道。
- **默认美观**：预设主题、配色与尺寸，开箱即出版/报告可用。
- **一致性**：统一的 API 风格、参数命名和错误处理策略。
- **可扩展性**：基于 ggplot2 及其扩展包构造，通过 `...` 透传底层能力，不作过度封装。
- **Mark 多样性**：对标 **Vega-Lite** / **AntV-G2** 的视觉通道丰富度，超越原生 ggplot2 几何图层类型范围。规划 22+ 种 mark 类型（§3.2），覆盖基础几何、分布展示、关系层次和地理空间四大领域。
- **默认美观与低配置成本**：调色板（离散/连续/定性）精心选择并持续扩展。`scale_*` 的 `range` 参数保持 `"scheme_name"` 字符串接口简便性，用户无需掌握色彩理论即可产出出版可用图表。

### 1.2 元数据集中管理

所有图表配置（尺寸、autofit、单位、dodge 宽度、default_color、标签文本等）统一存储于 `meta` 组件。

`label_*` 写入 `meta@labels` 并标记 dirty（惰性模式），不立即修改 `gg`。通过 `._sync_labels()` 在 `print()`/`export()` 时统一将 `meta@labels` 同步到 `gg$labels` 和 theme。直接操作 `plot@gg` 绕过 label 函数会导致 `meta$labels` 过时。当前 `._sync_labels()` 含 5 个几乎相同的 if 块处理 title/subtitle/caption/x/y，后续可抽象为循环（AD-3）。

### 1.3 分域验证

- **包层自定义约束** → `cli::cli_abort`：`encode()` 类检查、`size_unit` 合法性、`autofit` 与 `width`/`height` 关联约束
- **透传底层通用参数** → 交由 ggplot2 / grDevices 自然报错，包层不添加冗余验证

### 1.4 契约分层

| 层级 | 稳定性 | 内容 |
|------|--------|------|
| 核心契约 | 1.0 后主版本稳定 | 函数名（`plotit`、`encode`、`mark_*`、`scale_*`、`label_*`、`compose_*`、`style`、`export`）、返回类型 `plotit` 支持管道、`plotit()` 的 `data` 和 `mapping` 参数 |
| 扩展契约 | 2.0 可调整 | `scale_*` 的 `trans` 合法值集合（可增加不删除）、`label_*` 参数协议（`text`/`hide`/`reset`）、`project_*`/`split_*` 参数签名 |
| 可迭代 | 不破坏上述两层 | 默认主题参数、启发式算法、默认调色板、内部工具函数实现 |

例外：1.x 期间发现扩展契约中的设计缺陷允许经弃用→警告→移除周期（跨至少一个次版本）修正，不视为破坏性变更。

### 1.5 自动生成不手动维护

| 自动 | 手动 |
|---|---|
| `NAMESPACE`（roxygen2 `@export`）、`man/*.Rd`（roxygen2）、DESCRIPTION Collate（`@include`） | `R/*.R` 源码、`tests/`、DESCRIPTION 元信息 |

新建 `.R` 文件头部必须用 `@include` 声明内部依赖。每次增删文件或修改 roxygen 注释后执行 `roxygen2::roxygenize()`。

### 1.6 约定文档动态更新

实现与约定偏离时：判断偏离方向——实现改进则修约定，实现退化则修实现。以下情况必须同步更新：新增/删除/修改导出函数、修改参数签名或默认值、修改返回类型或管道行为、修改契约分层、引入/废止设计原则。

---

## 2. 技术选型

- **OOP**：**S7**。核心类：`plotit_labels`（文本字段）、`plotit_metadata`（配置项）、`plotit`（持有 `gg` + `meta`）。若 S7 发生不兼容变更，锁定版本或评估迁移至 S3/R6。
- **核心依赖**：ggplot2、S7、cli、patchwork。`ggrastr` 为可选增强（图层栅格化）。
- **未来扩展**（按需引入）：ggrepel、ggbeeswarm、treemapify、ggsankey、sf。

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

对标 Vega-Lite / AntV-G2 的视觉通道丰富度，不限于 ggplot2 原生几何。新 mark 按需引入，遵循统一 S7 泛型+方法模式（`mark_<type>` + `geom_<底层>`），支持 `rasterize`。

**已实现**（6）：

| 函数 | 对应 | 用途 |
|---|---|---|
| `mark_point` | `geom_point` | 散点 |
| `mark_line` | `geom_line` | 折线/趋势 |
| `mark_bar` | `geom_bar`/`geom_col` | 柱状图（有 y 映射→`geom_col`，无 y→`geom_bar`） |
| `mark_boxplot` | `geom_boxplot` | 箱线图 |
| `mark_histogram` | `geom_histogram` | 直方图 |
| `mark_density` | `geom_density` | 密度曲线 |

**规划中**：基础几何（area/path/rect/tile/polygon/text/rule）、分布展示（violin/beeswarm）、关系层次（network/tree/sankey/chord/treemap/sunburst/circlepacking/venn）、地理空间（map/link）

### 3.3 函数签名概要

#### 3.3.1 `plotit()` — 初始化

```
plotit(data, mapping = encode(), autofit = FALSE,
       width = 7, height = 5, size_unit = "in",
       dodge = NULL, default_color = "#4E79A7")
```

- `size_unit`：`"in"`/`"cm"`/`"mm"`，始终验证合法性，不受 `autofit` 影响
- `dodge`：NULL 时离散 X/Y 自动设为 0.8（有离散映射才设，否则 0）
- `default_color`：无 `colour`/`fill` 映射时同时注入两侧 + `guides(colour="none", fill="none")`。添加任何 colour/fill scale 后自动失效。清除逻辑统一为 `._clear_default_color()`（`utils.R`），mark_*/scale_*/project_parallel 三处共用。

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

**`_cf` 辅助函数**：`._cf(aes, fun_c, fun_f)` 根据 `aes` 是 `colour` 还是 `fill` 选择对应版本 scale 函数，消除 aes 分支样板代码。17 处引用集中于 scale.R。

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
| colour/fill | 离散→hue，连续→viridis | `"viridis"` `"brewer"` `"grey"`(仅离散) `"hue"` | 颜色向量 |
| size | `c(1, 6)` | — | 数值范围 |
| alpha | `c(0.1, 1)` | — | 数值范围 |
| shape | 默认形状集 | — | 形状编号 |
| linetype | 默认线型集 | — | 线型名称 |
| x/y | `c(0, 1)`（铺满面板） | — | 归一化面板占比 |

x/y 的 `range` 表示数据在面板上的视觉占比，通过 `limits` + `expand=c(0,0)` 精确实现。

**格式推断**：包层根据输入格式自动判断意图——单字符串→调色板方案，颜色向量→渐变，数值向量→值域，整数向量→形状编号，非颜色字符向量→线型。

**x/y 的 `range`**：表示数据在面板上的视觉占比（Vega-aligned：`range: [0, width]`），而非数据值。通过 `limits` + `expand=c(0,0)` 精确实现。与 `limits` 同时非 NULL 时后设置者胜，冲突时警告。

**`default_color` 覆盖**：任何用户提供的 `colour`/`fill` 映射都触发清除 `default_color` 注入的 `mapping$colour`/`mapping$fill` 和 `guides(colour="none", fill="none")`。当前三处清除点（`._clear_default_color()`）：mark_*（传入 layer mapping 时）、scale_color/fill（无条件）、project_parallel（group 引入 colour 时）。均已对称处理两侧，待统一收归（1.0 前待办）。

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
| `"none"` | 无 | 抑制原生 y 轴 | 每列手动渲染（`geom_vline`+`geom_segment`+`geom_text`） |

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

`style(plot, ..., base_size=11, base_family="", base_theme=<定制theme_minimal>)`：先应用基础主题，再叠加 `theme(...)` 覆盖。`style_default()` 为便捷别名。

#### 3.3.9 `export()` — 导出

`export(plot, filename, width=NULL, height=NULL, dpi=300, device=NULL, ...)`

尺寸优先级链：显式传参 > meta 存储值 > autofit 自适应。

- `autofit=FALSE` + 未传尺寸：通过 gtable 测量获得总尺寸（面板尺寸来自 meta，已在构造时由 `plot_layout()` 固定；轴/标签/图例由当前主题决定）
- `autofit=TRUE` + 未传尺寸：回退 `getOption("plotit.default_width", 7)` / `getOption("plotit.default_height", 5)`（英寸）
- 显式传入的 `width`/`height` 遵循 `plotit()` 时设定的 `size_unit` 换算。单位统一为英寸后传给 `ggsave()`
- `device` 从文件名扩展名推断（`.pdf` / `.png` / `.svg` 等）

#### 3.3.10 图片尺寸算法

`plotit()` 的 `width`/`height` 指面板尺寸（非总尺寸）。`autofit=FALSE` 时通过 `patchwork::plot_layout()` 固定面板为绝对单位。

**契约边界**：面板尺寸遵守 ±1% 浮点误差。总尺寸（面板+轴+标签+图例+边距）为衍生值，不在 API 契约内，可能随主题/字体/设备版本变化。

> **Patchwork 剥离规划**（设计文档）：
> 当前 `autofit=FALSE` 时 `@gg` 存储 `patchwork` 对象而非纯 `ggplot`，违背"完全基于 ggplot2 构造"的声明。
> 1. 单图：`plotit()` 不再调用 `plot_layout()`。改为 `export()`/`print()` 时通过 `ggplot_build()` 获得 gtable，用 `grid` 锁定面板尺寸。
> 2. 组合图：`compose_*` 改用 `grid` 纯组装，替代 `patchwork::wrap_plots()`。
> 3. 影响：`._reset_sizing()` 和 `._assemble_plots()` 需移除；`compose_*` 核心重写。

### 3.4 `compose_*` 组合

全部返回 `plotit_composite`（`@gg` + `@plots` + `@layout` + `@annotations`）。

**`compose_grid(..., ncol=NULL, nrow=NULL, byrow=TRUE, widths=NULL, heights=NULL, guides=NULL, axes="keep", tag_levels=NULL)`**
- 默认 `ncol=NULL, nrow=NULL` → `ncol=1`（纵向堆叠）。仅设 `nrow=1` 则横向并排
- `axes` 封装 `patchwork::plot_layout(axes=)`
- 嵌套：接受 `plotit_composite`，组合可嵌套

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
R/：class.R encode.R utils.R plot.R mark.R scale.R project.R split.R label.R style.R output.R compose.R
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

**允许直接访问**：`gg$mapping`、`gg$data`、`gg$labels`、`gg$theme`（只读）。

**禁止**：`gg$scales$scales`、`gg$layers` 等未文档化的内部结构。测试中也禁止检查这些。

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

p <- style(p, ggplot2::theme_minimal(base_size = 12))

export(p, "output.pdf", dpi = 300)
```

---

## 6. 默认美观要求

属于 §1.4 可迭代范围，具体参数可随版本调整。

- **主题**：基于 `theme_minimal`，背景透明，无网格线，保留浅灰轴线，无衬线字体，层级分明字号。极坐标系自动关闭轴线/刻度线/轴文本。平行坐标系：`std`/`global` 模式共享原生 y 轴，`none` 模式每列渲染主题匹配轴线。
- **调色板**：保持多样性与简便性并重。无映射时默认 Tableau 蓝 `#4E79A7`（同时 `colour`+`fill`，图例隐藏）。有映射默认 viridis（色盲友好）。`range="scheme_name"` 接口持续扩展（brewer/viridis/tableau/更多），最小配置成本获得美观默认值。
- **图例**：右侧，背景透明，简洁边框。
- **尺寸**：自适应关闭时默认约 7×5 英寸，导出 300 dpi。

---

## 7. 补充约定

- **空数据与缺失值**：空 data.frame 由 ggplot2 决定。`NA` 由 ggplot2 默认静默移除。
- **S7 槽位**：`plotit_labels`（title/subtitle/caption/x/y/legend）、`plotit_metadata`（autofit/width/height/dodge/unit/default_color/labels）、`plotit`（gg/meta）。
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
| 7 | 有状态默认值对称清除 | `default_color` 双向注入 + 双向 `guides()`。`._clear_default_color()` 三处共用 |
| 8 | 契约边界可验证 | 契约必须用用户可见指标定义（如面板尺寸 ±1%），不能用无法验证的免责声明。 |

---

## 9. 现状评估与 1.0 路线图

### 8.1 API 完成度

| 层级 | 函数族 | 规划 | 已实现 |
|------|--------|------|--------|
| 内层 | plotit() + encode() | 2 | 2 (100%) |
| 内层 | mark_* | 22 | 6 (27%) |
| 内层 | scale_* / project_* / split_* / label_* / style+export | 8+4+2+5+3=22 | 22 (100%) |
| 最外层 | compose_* | 3 | 3 (100%) |
| **总计** | | **~49** | **33 (67%)** |

### 8.2 1.0 前必做检查项

- [ ] mark_* 扩至至少 15 个（重点：area, violin, text, tile, path）
- [x] 3 篇 vignette（"Getting Started" / "Customizing Plots" / "Composing Figures"）
- [x] pkgdown 网站 + GitHub Actions CI
- [ ] 所有导出函数补充 `@examples`
- [x] BDD 测试覆盖率提到 ~55%
- [x] S7 版本锁定
- [x] styler + roxygenize 每次 PR 前执行

---

## 10. 技术债务

| # | 事项 | 优先级 | 状态 |
|---|------|--------|------|
| AD-1 | Patchwork 剥离（§3.3.10） | 中 | 路线图已设计，未实施 |
| AD-2 | `._collect_aes_names` 不再扫描 layers | 低 | label_legend(aes=NULL) 的图例标题不应用到图层级美学映射 |
| AD-3 | `._sync_labels` 5 个几乎相同 if 块 | 低 | 可抽象为循环 |
| AD-4 | S7 版本锁定 | 低 | DESCRIPTION 已限制 |
| AD-5 | mark_* 样板代码 | 低 | 每个 ~15 行 S7 泛型+方法，可用代码生成简化 |
| DI-1 | @examples 缺失 | 中 | 每个导出函数缺少可运行示例 |
| DI-2 | AGENTS.md 不生成 HTML | 低 | ✅ `_pkgdown.yml` exclude + CI 后处理移除 `docs/AGENTS*.html` |
| DI-3 | roxygen 链接警告 | 低 | ✅ `[0,1]` 已包裹为 `\code{[0,1]}` |

---

## 11. 开发陷阱

### 10.1 PowerShell 字符串展开

`@"..."@` 展开 `$variable` 和 `` `e ``。使用 `@'...'@` **单引号** here-string 保留字面文本。少量文本中用 `` `$ `` 或 `$$` 转义。

### 10.2 `-replace` 的 .NET 正则替换陷阱

替换字符串中 `$` 被解释为组引用（`$labels`→`abels`）。替换中字面 `$` 用 `$$`。非正则替换优先用 `[string]::Replace()`。

### 10.3 `git index.lock` 持久锁定

前序 git 中断后 `.git/index.lock` 残留。`Remove-Item -Force .git/index.lock`。反复出现则 `Get-Process git | Stop-Process -Force`。

### 10.4 S7 方法注册的加载顺序依赖

引用尚未定义的 generic 时报错。调整 Collate 顺序或在 `.onLoad()` 中注册。

### 10.5 styler 致代码结构变化

styler 修改缩进/换行后行号索引失效。**作为最后一步执行**——所有逻辑修改完成后运行，验证测试通过，再提交。

### 10.6 `c(0, 1)` vs roxygen 链接解析

roxygen2 将 `c(0, 1)` 中的 `0,1` 误认为链接目标。使用 `\code{c(0, 1)}` 或在 backtick 换行前加空格。`[0,1]`（方括号）同理——包裹在 `` `[0,1]` `` 中。

### 10.7 DCF 编码值不加引号

`.lintr` 中 `encoding: UTF-8`（非 `"UTF-8"`）。DCF 格式中引号为字面值，`encoding: "UTF-8"` 实际编码变为 `"UTF-8"`（含引号）。

### 10.8 `._` 前缀函数 lintr 配置

`object_name_linter(regexes = c("^[a-z][a-z0-9._]*$", "^[.]_[a-z][a-z0-9._]*$"))`——第一个匹配普通 snake_case，第二个匹配 `._` 前缀内部函数。

### 10.9 `line_length_linter` 放宽

roxygen 示例中管道链天然超 80 字符，放宽至 120 字符。代码行（非注释）仍应尽量遵守 80 字符。

### 10.10 `\donttest{}` vs `\dontrun{}` 在 R CMD check 中

`\donttest{}` **仍然执行**（仅 CRAN 跳过），`\dontrun{}` **完全不执行**。需外部数据包（sf、mapproj）用 `\dontrun{}`。自包含示例（iris/mtcars）可用 `\donttest{}`。

### 10.11 `is.element_blank()` 不存在

ggplot2 无此导出函数。正确方式：`inherits(x, "element_blank")`。

### 10.12 GitHub Actions Node.js 弃用

`actions/checkout@v4` 依赖 Node 20（已弃用）。全部升级至 `v5`。`r-lib/actions` 当前最新为 `v2`。

### 10.13 S7 `@export` 泛型 vs 方法

`@export` 标记在 S7 方法上**只导出该方法**，不自动导出泛型。泛型定义（`new_generic`）需要自己单独的 `@export`。

### 10.14 testthat 中访问内部函数

`test_check()` 在包命名空间中运行——内部函数可直接访问（无需 `:::`）。`test_dir()` 在全局环境运行——需要 `:::`。测试中优先通过公开 API 验证行为。

---

## 12. CI/CD 通用实践

### 11.1 CI 故障诊断树

```
CI 步骤失败？
├─ 0 秒完成（startedAt≈completedAt）→ Action 初始化报错（检查 inputs 定义）
├─ 比预期快得多 → 被跳过（条件 if: 提前退出 / 缓存命中）
├─ 正常耗时但失败 → 读日志 / 缺 continue-on-error
└─ 弃用警告 → GitHub Actions Node 版本升级
```

### 11.2 配置陷阱

- **YAML 标量**：多行参数必须用 `|`（block scalar），不能用缩进列表
- **continue-on-error 分层**：step 级（建议性检查）/ job 级（R-devel）。不要在 `steps:` 列表中间放置 job 级属性
- **deploy 步骤**：只在 main 分支触发

### 11.3 预提交本地验证 SOP

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

### 11.4 CI 预提交检查清单

新增/修改 CI workflow 前对照：
- [ ] `with:` 下的多行参数使用 `|`（block scalar）？
- [ ] `continue-on-error: true` 不在 `steps:` 列表中间？
- [ ] `on:` 的分支名与实际开发分支一致？
- [ ] `actions/checkout` 使用 v5、`upload-artifact` 使用 v4？
- [ ] 信息性 job（lint、coverage）使用 step 级 `continue-on-error: true`？
- [ ] R-devel 矩阵项包含 `http-user-agent: release`？
- [ ] deploy 步骤只在 main 分支触发？

### 11.4 CI 日志获取

```powershell
gh run list --limit 5 --json name,conclusion,status
gh api repos/{owner}/{repo}/actions/jobs/{job_id}/logs  # 不需要等整个 workflow 完成
```

### 11.5 Rd 示例解析错误定位

```r
tools::Rd2ex("man/<file>.Rd", "test.R")
parse(file = "test.R")
```

### 11.6 本地与 CI 环境差异

| 本地现象 | CI 相关性 | 原因 |
|----------|-----------|------|
| file.rename 失败 | 无关 | Windows Defender 拦截 staged install |
| CRAN URL 检查失败 | 无关 | 公司代理拦截出站 |
| 工作流触发失败 | 相关 | 用 act 本地模拟 |

本地复现 CI 失败优先使用 `gh api` 获取真实日志（§11.4），不要在本地 Windows 直接运行 R CMD check——差异太多。
