# plotit 开发约定

## 1. 设计原则

### 1.1 核心价值

- **简化语法**：动词前缀命名（`mark_*`、`scale_*`、`project_*` 等），支持管道。
- **默认美观**：预设主题、配色与尺寸，开箱即出版/报告可用。
- **一致性**：统一的 API 风格、参数命名和错误处理策略。
- **可扩展性**：完全基于 ggplot2 构造，通过 `...` 透传底层能力，不作过度封装。

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
- 函数名：`plotit()`、`encode()`、`mark_*`、`scale_*`、`label_*`、`style()`、`export()`
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

- **面向对象**：**S7** 包。核心类：`plotit_labels`（文本字段）、`plotit_metadata`（配置项）、`plotit`（持有 `gg` + `meta`）。
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
| `export()` | 图表导出 | `ggsave()` |

### 3.2 `mark_*` 目录

**已实现**（4 个）：

| 函数 | 对应 | 用途 |
|---|---|---|
| `mark_point` | `geom_point` | 散点 |
| `mark_line` | `geom_line` | 折线 / 趋势 |
| `mark_bar` | `geom_bar` / `geom_col` | 柱状图（有 y 映射→`geom_col`，无 y→`geom_bar`） |
| `mark_boxplot` | `geom_boxplot` | 箱线图 |

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
       dodge = NULL, default_color = "black")
```

| 参数 | 说明 |
|---|---|
| `data` | 数据框（必填） |
| `mapping` | `encode()` 产生的美学映射，包层做类检查 |
| `autofit` | `TRUE` 时 `width`/`height` 置 `NULL` 交由设备自适应 |
| `width`, `height` | 面板尺寸（非总尺寸）；`autofit=FALSE` 时两者均非 NULL 才有效 |
| `size_unit` | `"in"` / `"cm"` / `"mm"`，始终验证合法性，不受 `autofit` 影响 |
| `dodge` | 全局默认躲避宽度；`NULL` 时启发式判断（离散 X/Y → 设 dodge） |
| `default_color` | 无 `colour`/`fill` 映射时注入单色；添加任何 colour/fill scale 后自动失效 |

**尺寸优先级链**：显式传参 > meta 存储 > autofit 自适应。

#### 3.3.2 `encode()` — 美学映射

`encode(...)` 全部透传给 `ggplot2::aes()`，返回带 `"plotit_encode"` 类的对象。

#### 3.3.3 `mark_*` — 几何图层

- 第一参数 `plotit`，返回 `plotit`
- `mapping`、`data`、`position`：`data=NULL` 继承全局数据；`position=NULL` 自动读取全局 dodge
- `...` 透传给底层 `geom_*`
- 所有函数支持 `rasterize`、`rasterize_dpi`、`rasterize_dev`（需 `ggrastr`）

#### 3.3.4 `scale_*` — 比例尺

8 函数，8 参数，仅 `trans` 默认值不同：

```r
scale_<aes>(p, name = waiver(), trans = <默认>,
            limits = NULL, range = NULL,
            breaks = NULL, labels = NULL, ...)
```

| 参数 | 职责 |
|---|---|
| `name` | scale 名称，`waiver()` = 沿用变量名 |
| `trans` | 数据变换方式，不支持的组合主动报错 |
| `limits` | 数据边界（裁剪输入范围） |
| `range` | 视觉输出值域，x/y 为语法糖（见下） |
| `breaks` | 刻度/图例键位置 |
| `labels` | 刻度/图例键文字 |
| `...` | 透传底层 ggplot2 scale 参数 |

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

> **决策**：保留 x/y 的 `range` 参数以维持 8 函数签名一致。对颜色/尺寸/形状，`range` 是真正的视觉输出值域；对 x/y，`range` 是语法糖——等价于同时设置 `limits` 和 `expand=c(0,0)`。面板留白应使用 `project_cartesian(expand=...)`。

| aesthetic | `range = NULL` | `range = "name"` | `range = c(a, b)` |
|---|---|---|---|
| colour/fill | 离散→hue，连续→viridis | `"viridis"` `"brewer"` `"grey"`(仅离散) `"hue"` | 颜色向量 |

> `"grey"` 仅适用于离散变量。`"brewer"` 对 binned 不可用（binned 仅支持 `"viridis"`）。
| size | `c(1, 6)` | — | 数值范围 |
| alpha | `c(0.1, 1)` | — | 数值范围 |
| shape | 默认形状集 | — | 形状编号 |
| linetype | 默认线型集 | — | 线型名称 |
| x/y | `NULL` | — | 数据值域（= `limits` + `expand=c(0,0)`） |

**格式推断**：包层根据输入格式自动判断意图——单字符串→调色板方案，颜色向量→渐变，数值向量→值域，整数向量→形状编号，非颜色字符向量→线型。

**`trans` × `range` 协同**：包层根据组合选择底层 scale 函数。核心规则：
- `trans="identity"/"binned"` + `range="viridis"` → `scale_colour_viridis_c/b()`
- `trans="discrete"` + `range=c(...)` → `scale_colour_manual()`
- `trans="reverse"` → 对应版本 + `direction=-1` 或 `guide_legend(reverse=TRUE)`

**`name` vs `label_*`**：`scale_*(name=)` 设置 scale 层默认名，`label_*` 设置最终显示名——后执行者胜。

**default_color 覆盖**：添加任何 colour/fill scale 时自动取消 `plotit()` 注入的单色映射。

#### 3.3.5 `project_*` — 坐标系

| 函数 | 底层 | 关键参数 |
|---|---|---|
| `project_cartesian` | `coord_cartesian` / `coord_flip` / `coord_fixed` / `coord_trans` | `xlim`, `ylim`, `expand`, `flip`, `fixed`, `trans`, `clip`, `...` |
| `project_polar` | `coord_polar` | `theta`, `start`, `direction`, `clip`, `...` |
| `project_parallel` | 数据重塑 + `geom_line` / `geom_point` | `columns`, `group`, `scale`, `alpha`, `size`, `clip`, `...` |
| `project_map` | `coord_sf` / `coord_map` | `projection`, `xlim`, `ylim`, `clip`, `...` |
| `project_radial` | `coord_radial`（ggplot2 ≥ 3.5.0） | `theta`, `start`, `direction`, `r_axis_inside`, `inner_radius`, `clip`, `...` |

`project_parallel` 将选定列重塑为长格式，绘制平行坐标折线。支持按列标准化 (`scale="std"`)、全局尺度 (`"global"`) 或无缩放 (`"none"`)。`project_map` 默认使用 `coord_sf()`；传入 `projection` 参数时切换到 `coord_map()`（需 `mapproj`）。`project_radial` 需要 ggplot2 ≥ 3.5.0。

> **注意**：`project_cartesian(trans=)` 与 `scale_*(trans=)` 同名但不同义。前者的 `trans` 是**坐标系变换**（如 `coord_trans(x="log10")`），改变的是坐标轴的物理缩放；后者的 `trans` 是**数据标度变换**（如对数刻度），改变的是数据到视觉属性的映射方式。两者互不替代——`scale_x(trans="log")` 修改的是 x 轴的标度，`project_cartesian(trans="log10")` 修改的是坐标系本身。

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

#### 3.3.8 `style()` — 主题

- `style_default(plot, base_size, base_family)`：包级默认主题（基于 `theme_minimal`，背景透明，仅主网格线，无衬线字体，图例右侧）。`plotit()` 构造时自动调用。
- `style(plot, theme, ...)`：应用任意 ggplot2 主题对象。`theme` 为必填参数。

#### 3.3.9 `export()` — 导出

```r
export(plot, filename, width = NULL, height = NULL, dpi = 300, device = NULL, ...)
```

尺寸优先级：显式传参 > meta 存储值 > autofit 自适应。

- `autofit = FALSE` + 未传尺寸：通过 gtable 测量获得总尺寸（面板尺寸来自 meta，已在构造时由 `plot_layout()` 固定；轴/标签/图例由当前主题决定）。
- `autofit = TRUE` + 未传尺寸：回退 `getOption("plotit.default_width", 7)` / `getOption("plotit.default_height", 5)`（单位始终为英寸，与 `size_unit` 无关——`size_unit` 仅在显式传参时用于换算）。

单位统一为英寸后传给 `ggsave()`。

#### 3.3.10 图片尺寸算法

- `plotit()` 的 `width`/`height` 指**面板尺寸**（非总尺寸）。
- `autofit = FALSE`：通过 `patchwork::plot_layout()` 固定面板为绝对单位。

**契约边界**：当 `autofit = FALSE` 时，面板尺寸将得到遵守（允许因设备精度导致的 ±1% 浮点误差）。总尺寸（面板 + 轴 + 标签 + 图例 + 边距）是衍生值，不在 API 契约内，可能随主题/字体/设备版本微小变化。替换实现只需遵守面板尺寸契约，不视为破坏性变更。

> 当前实现基于 patchwork gtable 测量。此为已知耦合点——patchwork 或 ggplot2 升级可能影响测量精度。替换方案允许，只要面板尺寸契约不被破坏。



---

### 3.4 补充约定

- **空数据与缺失值**：空 data.frame 行为由 ggplot2 决定。`NA` 由 ggplot2 默认静默移除。
- **S7 槽位**：`plotit_labels`（`title`/`subtitle`/`caption`/`x`/`y`/`legend`）、`plotit_metadata`（`autofit`/`width`/`height`/`dodge`/`unit`/`default_color`/`labels`）、`plotit`（`gg`/`meta`）。
- **打印与设备**：`print()` 在交互模式下通过 `grDevices::dev.new(noRStudioGD = TRUE)` 打开独立设备窗口（而非 RStudio 内置 Plots 面板），以保证 `plotit()` 设定的面板尺寸物理呈现。`export()` 从文件名推断设备。

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
├── style.R      # style() + 默认主题
├── output.R     # print() + export()

tests/testthat/
├── test-encode.R  test-plot.R    test-mark.R
├── test-scale.R   test-label.R   test-project.R
├── test-split.R   test-style.R   test-export.R
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

**禁止直接访问 ggplot2 内部结构**：不得操作 `gg$labels`、`gg$scales$scales`、`gg$theme` 等未在 ggplot2 文档中公开的内部槽位。所有视觉修改必须通过 `+ labs()`、`+ guides()`、`+ theme()` 等公开 API。`gg$mapping` 是 ggplot2 的公开槽位，读取和修改其元素属于合法操作。内部结构在 ggplot2 小版本升级时无兼容保证。

**非标准求值只用 rlang**：数据掩码场景（列名查找）必须使用 `rlang::eval_tidy()`，禁止 `eval()` + `baseenv()` 组合。

### 4.7 Roxygen 文档

每个导出函数必须包含：标题 + 描述、`@param`（每个参数，含合法取值列表）、`@return`、`@export`。

### 4.8 测试

按函数族分文件。覆盖合法值及关键组合、非法输入的错误路径、管道链集成场景。

**断言行为而非内部状态**：测试应验证用户可见结果（标签内容、图例是否显示），而非 `gg$labels` 的键存在性或 `scales$scales[[1]]$name` 的值。内部状态会因实现路径变更而合法改变，不应进入测试契约。

---

## 5. 默认美观要求

属于 §1.4 可迭代范围，具体参数可随版本调整。

- **主题**：基于 `theme_minimal`，背景透明，仅保留主网格线（浅灰），无衬线字体，层级分明的字号。
- **颜色**：无映射时单色 + 隐藏图例。有映射时默认 viridis（色盲友好）。
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
| 7 | 有状态默认值对称清除 | `default_color` 注入 `guides(colour="none")` 后，任何图层级 `colour`/`fill` 映射也必须触发清除，不能仅依赖 `scale_*`。 |
| 8 | 契约边界可验证 | 契约必须用用户可见的指标定义（如面板尺寸 ±1%），不能用"±5% 容差"等无法验证的免责声明。 |
