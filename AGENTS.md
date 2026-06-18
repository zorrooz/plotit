# plotit 开发约定

## 1. 设计原则

### 1.1 核心价值

- **简化语法**：动词前缀命名（`mark_*`、`scale_*`、`project_*` 等），支持管道。
- **默认美观**：预设主题、配色与尺寸，开箱即出版/报告可用。
- **一致性**：统一的 API 风格、参数命名和错误处理策略。
- **可扩展性**：完全基于 ggplot2 构造，通过 `...` 透传底层能力，不作过度封装。

### 1.2 元数据集中管理

所有图表配置（尺寸、autofit、单位、dodge 宽度、default_color、标签文本等）统一存储于 `meta` 组件中。

标签类函数（`label_*`）**同步更新 `meta` 和 `gg`**：先将文本写入 `meta$labels`，随后立即通过 `ggplot2::labs()` 应用到 `gg`。任何已有同级设置被本次调用覆盖。

> **注意**：`meta$labels` 仅在通过 `label_*` 修改时保持同步。直接操作 `plot@gg` 绕过 label 函数会导致 `meta$labels` 过时。

### 1.3 分域验证

- **包层自定义约束** → 主动验证，`cli::cli_abort`。包括：`encode()` 结果类检查、`size_unit` 合法性、`autofit` 与 `width`/`height` 关联约束。
- **透传给底层库的通用参数** → 交由 ggplot2 / grDevices 自然报错，包层不添加冗余验证。

### 1.4 契约分层与版本策略

> 当前为 0.x，API 仍在演进。

**核心契约**（跨主版本稳定，1.0 后修改需主版本号升级）：
- 函数名：`plotit()`、`encode()`、`mark_*`、`scale_*`、`label_*`、`style()`、`export()`
- 返回类型：所有操作返回 `plotit`，支持管道
- `plotit()` 的 `data` 和 `mapping` 参数

**扩展契约**（1.0 后稳定，2.0 可基于实际使用反馈调整）：
- 各 `scale_*` 的 `trans` 合法值集合（可增加，不删除）
- `label_*` 的参数协议（`text`/`hide`/`reset`）
- `project_*`/`split_*` 的参数签名

**可迭代**（不破坏上述两层契约的前提下）：
- 默认主题参数、启发式算法（dodge 默认值等）、默认调色板
- `print()` 设备策略、内部工具函数实现

分层目的：避免 1.0 前夜"最后一次机会"式的集中大改——核心契约在 0.x 期间充分验证后锁定，扩展契约允许在 2.0 中基于实际使用反馈调整。

### 1.5 自动生成的内容绝不手动维护

| 自动 | 手动 |
|------|------|
| `NAMESPACE`（roxygen2 `@export`） | `R/*.R` 源码 |
| `man/*.Rd`（roxygen2） | `tests/` |
| `DESCRIPTION` Collate（`@include`） | `DESCRIPTION` 元信息 |

每次增删 `.R` 文件后执行 `roxygen2::roxygenize()`。新建文件头部必须用 `@include` 声明内部依赖。

### 1.6 约定文档动态更新

以下情况必须同步更新 AGENTS.md：新增/删除/修改导出函数、修改参数签名或默认值、修改返回类型或管道行为、修改不可变契约、引入新设计原则或废止旧原则。

约定与实现偏离时：首先判断偏离方向——实现是改进还是退化？若为改进，修约定以匹配实现；若为退化，修实现以匹配约定。这要求约定不是预设为正确的权威文本，而是当前最佳理解的快照——实现可以反过来修正约定。

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
| `mark_bar` | `geom_bar` / `geom_col` | 柱状图 |
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

**行为**：验证 mapping → 检查 autofit → 构造 ggplot → 初始化 meta → 应用默认主题 → patchwork 固定面板（非 autofit）→ 返回。

#### 3.3.2 `encode()` — 美学映射

`encode(...)` 全部透传给 `ggplot2::aes()`，返回带 `"plotit_encode"` 类的对象。

#### 3.3.3 `mark_*` — 几何图层

**统一契约**：
- 第一参数 `plotit`，返回 `plotit`
- `mapping`、`data`、`position`：`data=NULL` 继承全局数据；`position=NULL` 自动读取全局 dodge
- `...` 透传给底层 `geom_*`
- 所有函数支持 `rasterize`、`rasterize_dpi`、`rasterize_dev`（需 `ggrastr`）

#### 3.3.4 `scale_*` — 比例尺

**统一签名**（8 函数，8 参数，仅 `trans` 默认值不同）：

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
| `range` | 视觉输出值域（颜色/尺寸/坐标区间），格式由包层推断 |
| `breaks` | 刻度/图例键位置 |
| `labels` | 刻度/图例键文字 |
| `...` | 透传底层 ggplot2 scale 参数 |

**`trans` 合法值**：

> **设计权衡**：8 个 scale 函数共享同一个 `trans` 参数名，但允许的值取决于 aesthetic 类别。这不是"统一语义"——它是**签名统一、语义分类**。用户代价：需要知道 `log` 对颜色无效；收益：学会一个参数名即可在所有 scale 中使用它，包层在非法组合时给出定向错误而非静默失败。

| `trans` | x/y（位置标度） | colour/fill/size/alpha（视觉连续） | shape/linetype（视觉离散） |
|---|---|---|---|
| `NULL` | → identity | auto-detect | → discrete |
| `"identity"` | ✅ 默认 | ✅ 默认（连续） | ❌ |
| `"log"` / `"log10"` / `"log2"` / `"sqrt"` | ✅ | ❌ | ❌ |
| `"reverse"` | ✅ | ✅ | ✅ |
| `"discrete"` | ✅ | ✅ | ✅ 默认 |
| `"binned"` | ✅ | ✅ | ❌ |

不支持的组合给出 `cli::cli_abort` 错误（如 `scale_color(trans="log")` → "visual aesthetic; log not applicable"）。

内部校验矩阵：
```r
trans_legal <- list(
  positional   = c("identity", "log", "log10", "log2", "sqrt", "reverse", "discrete", "binned"),
  visual_cont  = c("identity", "discrete", "binned", "reverse"),
  visual_disc  = c("discrete", "reverse")
)
```

**`range` 合法值**：

> **设计权衡**：对 colour/fill/size/alpha/shape/linetype，`range` 是真正的"输出值域"（映射到的颜色/尺寸/形状）。对 x/y，`range` 语义退化为数据值域——等价于同时设置 `limits` 和 `expand=c(0,0)`。这是为了保持 8 函数签名整齐而做的妥协：位置标度没有一个天然对应"输出值域"的概念（面板像素位置不直接暴露给用户）。面板留白控制应使用 `project_cartesian(expand=...)`。

| aesthetic | `range = NULL` | `range = "name"` | `range = c(a, b)` |
|---|---|---|---|
| colour/fill | 离散→hue，连续→viridis | `"viridis"` `"brewer"` `"grey"` `"hue"` | 颜色向量 |
| size | `c(1, 6)` | — | 数值范围 |
| alpha | `c(0.1, 1)` | — | 数值范围 |
| shape | 默认形状集 | — | 形状编号 |
| linetype | 默认线型集 | — | 线型名称 |
| x/y | `NULL`（无裁剪） | — | 数据值域（= `limits` + `expand=c(0,0)`） |

与 `limits` 同时非 NULL 时后设置者胜，冲突时警告。

**`range` 格式推断**：包层根据输入格式自动判断意图——单字符串 → 调色板方案，颜色向量 → 渐变，数值向量 → 连续值域，整数向量 → 形状编号，非颜色字符向量 → 线型。

**`trans` × `range` 协同**：包层根据组合选择底层 scale 函数。核心规则：
- `trans="identity"/"binned"` + `range="viridis"` → `scale_colour_viridis_c/b()`
- `trans="discrete"` + `range=c(...)` → `scale_colour_manual()`
- `trans="reverse"` → 对应版本 + `direction=-1` 或 `guide_legend(reverse=TRUE)`

**`name` vs `label_*`**：`scale_*(name=)` 设置 scale 层默认名，`label_*` 设置最终显示名——后执行者胜。

**default_color 覆盖**：添加任何 colour/fill scale 时自动取消 `plotit()` 注入的单色映射。

#### 3.3.5 `project_*` — 坐标系

接收 `plotit`，返回 `plotit`。

| 函数 | 底层 | 关键参数 |
|---|---|---|
| `project_cartesian` | `coord_cartesian` | `xlim`, `ylim`, `expand`, `clip` |
| `project_flip` | `coord_flip` | `xlim`, `ylim` |
| `project_polar` | `coord_polar` | `theta`, `start`, `direction` |

与 `scale_x/y(range=)` 的交互：`project_cartesian(expand=)` 后执行时覆盖 scale 设置的 `expand=c(0,0)`。

#### 3.3.6 `split_*` — 分面

| 函数 | 底层 | 关键参数 |
|---|---|---|
| `split_wrap` | `facet_wrap` | `...`（分面变量）, `ncol`, `nrow`, `scales` |
| `split_grid` | `facet_grid` | `rows`, `cols`（需 `ggplot2::vars()` 包裹）, `scales`, `space` |

`split_grid` 的 `...` 可作为 `rows` 的简写（单变量）。同时使用 `...` 和 `rows` 时以 `...` 为准并报警告。

#### 3.3.7 `label_*` — 文本标签

**统一行为**：写入 `meta$labels` 并立即应用到 `gg`。

**三参数协议**（`text` + `hide` + `reset`）：

> **设计权衡**：旧版 `text=NULL` 重置变量名——简洁但反直觉（"我没传 text 为什么要改我的标题？"）。新版 `text=NULL` 是空操作——直觉正确但引入了 `reset` 参数。代价是标签的最终状态现在由 `text`/`hide`/`reset` + `scale_*(name=)` 的调用顺序共同决定。用户需要理解：`reset` 恢复变量名，`hide` 隐藏元素，`text` 设置自定义文本，三者互不覆盖但可组合。

| 调用 | 行为 |
|---|---|
| `text = "str"` | 设置自定义文本 |
| `hide = TRUE` | 移除元素及占位空间（`element_blank()`） |
| `reset = TRUE` | 恢复变量名（轴/图例）或移除（标题/副标题/脚注） |
| 不调用 / 全默认 | 保持现状 |

`text=NULL` 不修改当前标签。`text`（非 NULL）与 `reset=TRUE` 互斥，同时提供时报错。

| 函数 | 参数 | 用途 |
|---|---|---|
| `label_title` | `text`, `hide`, `reset` | 主标题 |
| `label_subtitle` | `text`, `hide`, `reset` | 副标题 |
| `label_caption` | `text`, `hide`, `reset` | 脚注 |
| `label_axis` | `text`, `aes`, `hide`, `reset` | `aes = "x"` 或 `"y"`（必填） |
| `label_legend` | `text`, `aes`, `hide`, `reset` | `aes = "colour"`/`"fill"` 等 |

**与 `scale_*(name=)` 的关系**：`label_*` 优先级更高。调用 `label_axis(aes="x")`（全默认）不会覆盖 `scale_x(name="Width")`。

**缺省值**：标题/副标题/脚注无默认（不调用时不存在）；轴标题缺省为变量名，`reset=TRUE` 恢复。

#### 3.3.8 `style()` — 主题

- `style_default(plot, base_size, base_family)`：包级默认主题（基于 `theme_minimal`，背景透明，保留主网格线，无衬线字体，图例右侧）。`plotit()` 构造时自动调用。
- `style(plot, theme, ...)`：应用任意 ggplot2 主题对象，`...` 传递额外 `theme()` 微调。`theme` 为必填参数。

两个函数都更新 `plotit_theme_managed` 标记，防止 `print()` 重复注入。

#### 3.3.9 `export()` — 导出

```r
export(plot, filename, width = NULL, height = NULL, dpi = 300, device = NULL, ...)
```

尺寸优先级：显式传参 > meta 存储值 > autofit 自适应。未传入时回退 meta 或 `getOption("plotit.default_width", 7)` / `getOption("plotit.default_height", 5)`。单位统一为英寸后传给 `ggsave()`。

#### 3.3.10 图片尺寸算法

- `plotit()` 的 `width`/`height` 指**面板尺寸**（非总尺寸）。
- `autofit = FALSE`：通过 `patchwork::plot_layout()` 固定面板为绝对单位。
- 预览（`print()`）：非 NULL 时通过 `patchworkGrob()` 测量总尺寸后打开匹配设备。
- 导出（`export()`）：同上逻辑，用户显式尺寸优先。

> **实验性声明与契约边界**：面板尺寸算法深度依赖 patchwork 内部 gtable 结构。API 契约保证的是**面板尺寸的意图**（`width=6` 表示用户想要 6 英寸宽的面板），而非像素级精确输出（总尺寸 = 面板 + 轴 + 标签 + 图例 + 边距，后者随主题/字体/设备浮动）。因此实现路径可替换——只要替换方案在合理容差内（±5%）还原用户的尺寸意图，即不视为 API 破坏。

---

### 3.4 补充约定

- **空数据与缺失值**：空 data.frame 行为由 ggplot2 决定，包层不做额外验证。`NA` 由 ggplot2 默认静默移除。
- **S7 槽位**：`plotit_labels`（`title`/`subtitle`/`caption`/`x`/`y`/`legend`）、`plotit_metadata`（`autofit`/`width`/`height`/`dodge`/`unit`/`default_color`/`labels`）、`plotit`（`gg`/`meta`）。
- **打印与设备**：`print()` 在交互模式下通过 `grDevices::dev.new()` 打开新设备，默认使用 Cairo。`export()` 从文件名推断设备。

---

## 4. 代码风格

### 4.1 文件结构

```
R/
├── class.R      # S7 类定义
├── encode.R     # encode() 泛型 + 方法
├── utils.R      # 工具函数（%||%, is_discrete 等）
├── plot.R       # plotit()
├── mark.R       # 所有 mark_*
├── scale.R      # 所有 scale_*
├── project.R    # 所有 project_*
├── split.R      # 所有 split_*
├── label.R      # 所有 label_*
├── style.R      # style() + 默认主题
├── output.R     # print() + export()

tests/testthat/
├── test-encode.R
├── test-plot.R
├── test-mark.R
├── test-scale.R
├── test-label.R
├── test-project.R
├── test-split.R
├── test-style.R
└── test-export.R
```

文件名 `snake_case.R`。`R/` 下只放包源码。`playground.R` 用于临时手动测试，不纳入版本管理；有价值的用例移入 `tests/testthat/`。

### 4.2 命名与格式

- 函数名和参数名 `snake_case`。动词前缀统一（`mark_`、`scale_` 等）。
- `color`/`colour` 等价接受，函数命名统一美式拼写。
- 缩进 2 空格，行宽 80 字符。
- Push 前执行 `styler::style_pkg()`。

### 4.3 代码文本一律使用英文

所有代码注释、roxygen 文档、函数体内注释、错误消息、警告信息、提交信息一律使用英文。（AGENTS.md 本身以中文撰写，面向中文开发者。）

### 4.4 管道

所有对象修改函数返回 `plotit`，支持 `|>` 链式调用。每个管道步骤独立一行。

### 4.5 错误信息

主动验证点使用 `cli::cli_abort()` 提供结构化错误。其他位置由底层 API 自然抛出。

### 4.6 命名空间

使用 `pkg::fun()` 显式调用外部函数。内部用 `%||%` 处理 NULL 默认值。

### 4.7 Roxygen 文档

每个导出函数必须包含：标题 + 描述、`@param`（每个参数，含合法取值列表）、`@return`、`@export`。

### 4.8 测试

按函数族分文件（见 §4.1）。覆盖合法值及关键组合、非法输入的错误路径、管道链集成场景。

---

## 5. 默认美观要求

属于 §1.4 的可迭代范围，具体参数可随版本调整。

- **主题**：基于 `theme_minimal`，背景透明，仅保留主网格线（浅灰），无衬线字体，层级分明的字号。
- **颜色**：无映射时单色 + 隐藏图例。有映射时默认 viridis（色盲友好）。
- **图例**：右侧，背景透明，边框简洁。
- **尺寸**：自适应关闭时默认适合学术单栏排版（约 7×5 英寸），导出 300 dpi。

---

## 6. 实现 Demo

```r
library(plotit)

# 1. 构造映射
mapping <- encode(x = displ, y = hwy, colour = class)

# 2. 创建图表
p <- plotit(mpg, mapping, autofit = FALSE, width = 6, height = 4, size_unit = "in")

# 3. 添加图层
p <- p |>
  mark_point(size = 2, alpha = 0.7) |>
  mark_boxplot()

# 4. 调整比例尺
p <- p |>
  scale_x(trans = "log10") |>
  scale_color(range = "viridis")

# 5. 变换坐标系
p <- p |>
  project_cartesian(xlim = c(0, 100))

# 6. 分面
p <- split_wrap(p, cyl, ncol = 2)

# 7. 设置标签
p <- p |>
  label_title("Fuel Economy") |>
  label_axis(text = "Displacement", aes = "x") |>
  label_axis(text = "Highway MPG", aes = "y")

# 8. 应用主题
p <- style(p, ggplot2::theme_minimal(base_size = 12))

# 9. 导出
export(p, "output.pdf", dpi = 300)
```

---

## 7. Bug 审查原则

审查时按以下清单系统排查：

| # | 原则 | 检查点 |
|---|------|--------|
| 0 | 区分特性与 Bug | 静默忽略可能是设计意图；参数传入不生效才是 Bug |
| 1 | 参数全链路追踪 | 每个中转节点：直接转发 / 转换 / 被丢弃？ |
| 2 | 枚举值分支穷举 | N 个合法值 → N 条路径全部显式存在 |
| 3 | 对称抽象一致性 | color↔fill, size↔alpha, shape↔linetype, x↔y |
| 4 | 默认值分叉 | 新增条件分支 → 同步更新默认值逻辑 |
| 5 | 底层接口兼容性 | 透传前确认底层接受该参数；不接受时切换函数 |
| 6 | 内部概念不泄漏 | 包层参数名可能与底层同名但语义不同（如 `trans="binned"`） |
