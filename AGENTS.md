# plotit 开发约定

## 1. 设计原则

### 1.1 核心价值
- **简化语法**：动词前缀命名（`mark_*`、`scale_*`、`project_*` 等），支持管道。
- **默认美观**：预设主题、配色与尺寸，开箱即出版/报告可用。
- **一致性**：统一的 API 风格、参数命名和错误处理策略。
- **可扩展性**：完全基于 ggplot2 构造，通过 `...` 透传底层能力，不作过度封装。

### 1.2 元数据集中管理
- 所有图表配置（尺寸、自适应标志、单位、躲避宽度、单色默认、标签文本等）统一存储于返回对象的 `meta` 组件中。
- 标签类函数（`label_*`）**同步更新 `meta` 和 `gg` 对象**：先将文本写入 `meta$labels`，随后立即通过 `ggplot2::labs()` 应用到 `gg`，确保打印、预览时所见即所得。任何之前已有的同级设置将被本次调用覆盖。
- `meta$labels` 始终作为标签的权威记录，可供导出或其他后处理使用，但不再承担延迟注入的角色。

  > **警告**：`meta$labels` 仅在通过 `label_*` 函数修改时保持同步。如果用户直接操作 `plot@gg <- plot@gg + ggplot2::labs(...)` 绕过 label 函数，`meta$labels` 将过时且不会自动修复。

### 1.3 分域验证原则
- **本包 API 设计决定的约束** → 主动验证，使用 `cli::cli_abort` 提供结构化错误信息。包括但不限于：
  - `encode()` 结果类检查（`plotit()` 入口守卫）
  - `unit` 合法性（包层自定义的单位参数，ggplot2 无同等校验）
  - `autofit` 与 `width`/`height` 的关联约束：`autofit = FALSE` 时要求两者均非 `NULL`（报错）；`autofit = TRUE` 时静默忽略 `width`/`height` 并将其置为 `NULL`
  - 其他包层自定义参数或行为约束
- **透传给底层库的通用参数**（类型、范围、有效性）→ 交由底层库（ggplot2、grDevices 等）自然报错，包层绝不添加冗余验证。

### 1.4 不可变契约与可实验的边界

> **注意**：当前版本为 0.x，API 仍在演进中。以下"不可变"契约面向 1.0 发布后生效。在 1.0 之前，函数名和参数签名仍可基于实际使用反馈调整。

- **以下为不可变 API 契约**，1.0 发布后任何版本更新都不得修改：
  - 函数名（`mark_*`、`scale_*`、`project_*`、`split_*`、`label_*`、`plotit()`、`encode()`、`style()`、`export()`）
  - 每个函数的参数名及其语义（如 `mark_*` 的 `mapping`、`data`、`...`；`label_*` 的同步 `meta`+`gg` 行为）
  - 返回类型：所有操作均返回 `plotit` 对象，支持管道链式调用
  - 后端实现可在不破坏上述契约的前提下任意替换、优化或扩展

- 以下方面的具体实现可在不破坏 API 契约的前提下迭代优化：
  - 默认主题参数（base_size、字体、网格线颜色）
  - 启发式算法（dodge 宽度默认值计算等）
  - 默认调色板选择
  - `print()` 的设备创建策略
  - 内部工具函数实现（`%||%`、`is_discrete` 等）
  - 测试用例组织方式

### 1.5 可自动生成的内容绝不手动维护
- **自动管理清单**：
  - `NAMESPACE` — 由 `roxygen2::roxygenize()` 通过 `@export` 标签自动生成，永不手动编辑
  - `man/*.Rd` — 由 roxygen2 从 roxygen 注释自动生成
  - `DESCRIPTION` 的 `Collate` 字段 — 由 roxygen2 通过 `@include` 标签自动管理
- **手动维护**：`R/*.R` 源码、`tests/`、`DESCRIPTION` 的元信息（包名、版本、依赖列表等）
- 每次增删 `.R` 文件后，执行 `roxygen2::roxygenize()` 同步 NAMESPACE + Collate + Rd，无需手动编辑上述文件
- 新建 `.R` 文件时必须在文件头部 roxygen 块中添加 `@include` 标签声明其全部内部依赖，格式：`#' @include 依赖文件1.R 依赖文件2.R`

### 1.6 约定文档的动态更新

- **本约定文档（AGENTS.md）是一个活跃文档**，应与实现保持同步。
- **用户提出新需求或变更时**，必须同时在 AGENTS.md 中记录：新增/修改了什么、对应的约定或理由。不允许只改代码不更新约定。
- 以下情况必须同步更新 AGENTS.md：
  - 新增、删除或修改导出函数（含函数族表 §3.1 和对应 §3.3.x 详细说明）
  - 修改参数签名或默认值
  - 修改返回类型或管道行为
  - 修改不可变契约（§1.4 列表），此类变更需额外审视
  - 引入新的设计原则或废止旧原则
- 代码中修复自洽性缺陷（如补齐 `@include`、修正与约定描述不符的行为）时，若约定与实现间的偏离是约定先描述了对的行为而实现尚未跟上，则以约定为准修实现；若约定描述的是过时或不准确的理想，则修约定。
- 被标记为"可实验区域"（§1.4）的细节可先在实践中试错，找到稳定方案后再固化到约定中。

### 1.7 主动迭代直至满意

- **每次修改后主动跟进的规则**：完成一次修改后，不等待用户提出下一轮需求，而是主动询问效果是否符合预期、是否需要调整、是否发现新的问题。
- 迭代过程：
  1. 完成修改后，说明改了什么、为什么这么改、预期效果
  2. 主动询问"是否符合预期"、"是否需要调整方向"、"是否发现了新的问题"
  3. 根据反馈继续调整，直至用户明确表示满意
  4. 用户说"ok"、"可以"、"好"等确认性回应时，迭代终止
- 此原则适用于代码实现、约定文档更新、测试编写等所有产出类型。

### 1.8 主动审查与质量迭代

- **触发条件**：当用户说"审查一下"、"review"、"检查一下"等信号时，或当连续修改积累到你觉得有必要时就主动提出。
- **审查范围（默认全包含）**：
  - **约定与实现一致性**：AGENTS.md 各章节描述的行为是否与实际代码一致，已被修复或过时的约定是否已同步更新
  - **代码质量**：命名风格、函数签名一致性、管道兼容性、重复代码、复杂度
  - **正确性与安全性**：逻辑 bug、边界条件未处理、输入验证缺失、静默吞错
  - **约定遵循度**：是否遵循了本约定的各条原则（不可变契约、分域验证、meta 集中管理、`pkg::fun()` 显式调用等）
  - **测试覆盖**：是否有未覆盖的关键路径、遗漏的 `@include`、未同步的约定文档
  - **设计退化**：是否存在隐藏的耦合、过度工程或不必要的抽象
- **审查输出**：以结构化列表列出每个发现，标注严重性（断裂/退化/建议），并给出修复方案或询问是否合并为计划。
- **提醒时机**：当我觉得改动积累到值得审查的程度时，主动询问"改动积累较多，是否需要做一次全局审查？"


## 2. 技术选型

- **面向对象系统**：采用 **S7** 包进行类定义与方法分发。
  - 核心类：
    - `plotit_labels`：装载标题、副标题、脚注、轴标题、图例标题等文本字段。
    - `plotit_metadata`：装载 `autofit`、`width`、`height`、`unit`、`dodge`、`default_color`、`labels` 等配置项。
    - `plotit`（类变量 `plotit_class`）：主对象，持有原始 `ggplot` 对象（`gg`）和元数据实例（`meta`）。所有添加图层、比例尺等操作均返回该对象自身。
  - 方法定义：各 `mark_*`、`scale_*`、`project_*`、`split_*`、`label_*`、`style()`、`export()` 等函数通过 S7 泛型实现针对 `plotit` 类的方法。
- **核心依赖**：ggplot2、S7、cli、patchwork（图形组合与固定面板尺寸）；可选图形设备在导出时动态检测，`ggrastr` 为可选增强依赖（用于图层栅格化）。
- **未来扩展依赖**（按需引入，非强制）：
  - `ggrepel` — 文本标签防重叠
  - `ggbeeswarm` — 蜂群图
  - `treemapify` — 矩形树图
  - `ggsankey` / `circlize` — 关系图
  - `sf` — 地理空间数据
  - `ggrastr` — 图层栅格化（大规模散点图 PDF 优化）

---

## 3. API 函数族体系

### 3.1 函数族总览

| 函数族 | 职责 | 对应 ggplot2 机制 |
|---|---|---|
| `plotit()` | 初始化图表对象 | `ggplot()` |
| `encode()` | 构造美学映射 | `aes()` |
| `mark_*` | 添加几何图层 | `geom_*` |
| `scale_*` | 数据→视觉映射 + 显示 | `scale_*` |
| `project_*` | 坐标系变换 | `coord_*` |
| `split_*` | 分面布局 | `facet_*` |
| `label_*` | 文本标签 | `labs()` |
| `style()` | 主题设置 | `theme()` / 预设主题 |
| `export()` | 图表导出 | `ggsave()` |
| `compose_*` | 图形组合 | patchwork / `gridExtra` |
| `transform_*` | 数据计算/统计变换 | 数据预处理 |

### 3.2 `mark_*` 类型完整目录

按视觉语义归类。当前已实现的函数作为参考，未实现函数的签名与行为可能在开发中调整。

#### 3.2.1 基础几何

| 函数 | 对应 geom | 用途 |
|---|---|---|
| **`mark_point`** | `geom_point` | 散点 |
| **`mark_line`** | `geom_line` | 折线 / 趋势线 |
| `mark_area` | `geom_area` | 面积图 |
| `mark_path` | `geom_path` | 路径图（按数据顺序连线） |
| `mark_rect` | `geom_rect` | 矩形高亮区域 |
| `mark_tile` | `geom_tile` | 瓦片热力图 |
| `mark_polygon` | `geom_polygon` | 多边形（如阴影区域） |
| `mark_text` | `geom_text` / `geom_label` | 文本标注（规划支持 `ggrepel` 自动躲避） |
| `mark_image` | `ggimage::geom_image` | 图片标注 |
| `mark_rule` | `geom_hline` / `geom_vline` / `geom_abline` | 参考线 / 阈值线 |

#### 3.2.2 分布展示

| 函数 | 对应 geom | 用途 |
|---|---|---:|
| **`mark_bar`** | `geom_bar` / `geom_col` | 条形图 / 柱状图 |
| **`mark_boxplot`** | `geom_boxplot` | 箱线图 |
| `mark_histogram` | `geom_histogram` | 直方图 |
| `mark_violin` | `geom_violin` | 提琴图 |
| `mark_beeswarm` | `ggbeeswarm::geom_beeswarm` | 蜂群图 |

#### 3.2.3 关系网络

| 函数 | 对应机制 | 用途 |
|---|---|---|
| `mark_network` | 自定义图层 / `igraph` | 网络图（节点-边） |
| `mark_tree` | 自定义图层 / `ggtree` | 树形图（层次聚类、决策树） |
| `mark_sankey` | `ggsankey` | 桑基图（流量/转移） |
| `mark_chord` | `circlize` | 弦图（关系矩阵） |

#### 3.2.4 层次结构

| 函数 | 对应机制 | 用途 |
|---|---|---|
| `mark_treemap` | `treemapify` | 矩形树图 |
| `mark_sunburst` | `sunburstR` / 自定义 | 旭日图 |
| `mark_circlepacking` | `packcircles` | 圆堆图 |
| `mark_venn` | `ggvenn` / `eulerr` | 韦恩图 |

#### 3.2.5 地理空间

| 函数 | 对应机制 | 用途 |
|---|---|---|
| `mark_map` | `ggplot2::geom_map` / `sf::geom_sf` | 地图（多边形边界） |
| `mark_link` | `geom_segment` / `geom_curve` | 地图连线/流向线 |

---

### 3.3 各函数族详细约定

#### 3.3.1 初始化函数 `plotit()`

**职责**：创建基础图表对象并存储元数据。

**签名**：
```r
plotit(data, mapping = encode(), autofit = FALSE,
       width = 7, height = 5, size_unit = "in",
       dodge = NULL, default_color = "black")
```

**关键参数**：
- `data`：数据框（必填）。
- `mapping`：美学映射，由 `encode()` 产生，包层做类检查。
- `autofit`：逻辑值，是否采用自适应尺寸。
- `width`、`height`、`size_unit`：定义后续导出与预览的默认尺寸及单位。`autofit = TRUE` 时 `width`/`height` 置为 `NULL` 交由设备自适应，但 `size_unit` 始终存储于 `meta` 中，供 `export()` 按用户声明的单位进行换算。`size_unit` 始终验证合法性（不受 `autofit` 影响）。
- `dodge`：全局默认躲避宽度。若未提供，实施启发式判断（离散 X/Y 则设置躲避，连续则无躲避）。各 `mark_*` 函数自动将该值注入 `position_dodge()`，用户可通过显式 `position` 参数覆盖。
- `default_color`：若提供且映射中无 `colour`/`fill`，则自动生成单色映射并隐藏对应图例；一旦后续添加任何颜色或填充比例尺，该单色映射自动失效。

**行为**：
1. 验证 `mapping` 的类（本包自约束，按 1.3 分域原则）。
2. 检查 `autofit` 与 `width`/`height` 的依赖关系。
3. 使用 `data` 和 `mapping` 构造内部 `ggplot` 对象。
4. 初始化 `meta` 并填充各字段（含启发式 dodge 计算）。
5. 应用包级默认主题（`style_default()`），设置 `plotit_theme_managed` 标记。`print()` 和 `style()` 均检测该标记以避免重复叠加。
6. 若 `patchwork` 包可用且非 `autofit` 模式，调用 `patchwork::plot_layout()` 固定面板尺寸。完整的尺寸算法（面板 vs 总尺寸、阶段 1-3）详见 §3.3.10。
7. 返回 `plotit` 对象。

#### 3.3.2 美学映射构造函数 `encode()`

**职责**：生成带特定类的美学映射对象。

**签名**：`encode(...)` — 全部透传给 `ggplot2::aes()`。

**行为**：为返回结果附加 `"plotit_encode"` 类，供 `plotit()` 进行检查。

#### 3.3.3 图层函数族 `mark_*`

**职责**：向图表添加一个几何图层。

**统一契约**：
- 第一个参数为 `plotit` 对象，返回修改后的 `plotit` 对象。
- 拥有 `mapping`、`data` 和 `position` 参数：`data = NULL` 时继承 `plotit()` 的基础数据；`data` 提供时用于图层局部数据（如注释）；`position = NULL` 时自动读取 `meta@dodge`，若 `dodge > 0` 则注入 `position_dodge()`，否则透传 `NULL`（保留 geom 默认行为）。显式传入 `position`（如 `"stack"`、`"dodge2"`、`position_dodge(0.5)`）将覆盖全局 `dodge`。
- 通过 `...` 接收并透明传递给对应的 `ggplot2::geom_*` 函数。
- 所有 `mark_*` 函数支持 `rasterize`、`rasterize_dpi` 和 `rasterize_dev` 参数（需安装 `ggrastr` 包），用于大数据点图层的栅格化。`rasterize_dev` 默认为 `"cairo"`（通过 `grDevices` 内置支持），可设为 `"ragg"` 等（需对应设备包已安装）。

**实现原则**：
- 每个 `mark_*` 函数命名与 §3.2 目录一致。
- 非 ggplot2 原生几何（如 network、sankey）需封装外部包接口，确保返回 `plotit` 对象。
- `mark_text` 可选项支持 `ggrepel` 自动防重叠。

#### 3.3.4 比例尺函数族 `scale_*`

**职责**：数据→视觉映射 + 显示控制（参考 Vega 的 `type`/`domain`/`range` 四维模型）。

**统一签名** (8 函数, 8 参数):

```r
scale_<aes>(p, name = waiver(), trans = <默认>,
            limits = NULL, range = NULL,
            breaks = NULL, labels = NULL, ...)
```

| 参数 | 作用层 | 对应 Vega | 描述 |
|---|---|---|---|
| `name` | 命名 | axis.title | 该 scale 的名称, `waiver()` 沿用变量名, `"str"` 覆盖 |
| `trans` | 映射算法 | `type` | 选择变换方式, 各 scale 默认值不同 |
| `limits` | 数据边界 | `domain` | 裁剪输入数据范围 |
| `range` | 视觉边界 | `range` + `scheme` | 输出视觉值范围, color/size/alpha 由类型自适应 |
| `breaks` | 显示-刻度位 | axis.tickValues | 刻度/图例键位置 |
| `labels` | 显示-刻度字 | axis.tickLabels | 刻度/图例键文字 |
| `...` | 后端 | — | 透传底层 ggplot2 scale 专属参数 |

**8 函数完整签名**:

```r
scale_color   (p, name, trans=NULL,       limits, range, breaks, labels, ...)
scale_fill    (p, name, trans=NULL,       limits, range, breaks, labels, ...)
scale_size    (p, name, trans=NULL,       limits, range, breaks, labels, ...)
scale_alpha   (p, name, trans=NULL,       limits, range, breaks, labels, ...)
scale_shape   (p, name, trans="discrete", limits, range, breaks, labels, ...)
scale_linetype(p, name, trans="discrete", limits, range, breaks, labels, ...)
scale_x       (p, name, trans="identity", limits, range, breaks, labels, ...)
scale_y       (p, name, trans="identity", limits, range, breaks, labels, ...)
```

仅 `trans` 默认值不同——反映各 scale 的自然语义, 不破坏 API 一致性。

**`trans` — 映射算法**:

| `trans` | 算法 | color/fill/size/alpha | shape/linetype | x/y |
|---|---|---|---|---|
| `NULL` | 自动检测 (`is_discrete()`) | ✅ 默认 | — | — |
| `"identity"` | 连续线性 | ✅ | ❌ | ✅ 默认 |
| `"discrete"` | 离散查找表 | ✅ | ✅ 默认 | ✅ |
| `"log"` | 对数 (自然) | — | — | ✅ |
| `"log10"` | 以 10 为底对数 | — | — | ✅ |
| `"log2"` | 以 2 为底对数 | — | — | ✅ |
| `"sqrt"` | 平方根 | — | — | ✅ |
| `"reverse"` | 翻转 | ✅ | — | ✅ |
| `"binned"` | 分箱离散化 | ✅ | ✅ | ✅ |

`trans` 在包中统一表示"对输入数据的变换"，但其具体形式取决于标度的性质：
- **位置标度 (x/y)**：`trans` 对应数值变换函数（如 `"log"`、`"sqrt"`、`"reverse"`），直接传递给 ggplot2 的坐标变换机制。
- **视觉标度 (color/fill/size/alpha/shape/linetype)**：`trans` 表示数据类型的离散化策略（`"identity"`、`"discrete"`、`"binned"`），实质选择连续、离散或分箱标度。

这种设计保持 API 表面统一：`trans` 回答"如何将数据映射为视觉属性"——位置靠坐标变换，视觉靠离散化策略。

**`range` — 视觉输出边界**:

| aesthetic | `range=NULL` 默认 | `range="scheme"` | `range=c(a,b)` |
|---|---|---|---|
| colour/fill | hue(离散)/viridis(连续) | `"viridis"` `"brewer"` `"grey"` `"hue"` | `c("blue","red")` |
| size | `c(1,6)` | — | `c(0.5,10)` |
| alpha | `c(0.1,1)` | — | `c(0,0.8)` |
| shape | 默认形状集 | — | `c(1,16)` |
| linetype | 默认线型集 | — | `c("solid","dashed")` |
| x/y | `c(0,1)` | — | 归一化比例 (0–1) |

`range` 统一了 color 的调色板、size 的尺寸范围、alpha 的透明度范围——语义一致："输出到什么视觉值上"。

**位置标度 (x/y) 的 `range`**：归一化的面板视觉区间，`c(0, 1)` 表示数据铺满面板，`c(0.1, 0.9)` 表示数据占据面板中间 80%。与 `limits`（数据裁剪）和 `project_cartesian(xlim/ylim)`（视口平移）正交。初始版本可转化为 `ggplot2::scale_*_continuous(expand = ...)` 近似实现，精确控制属于可实验区域。

**双层命名: `name` vs `label_*`**:

```
encode(x = Sepal.Width)     → 变量名
scale_x(name = "Width")     → scale 层覆盖
label_axis(text = "花萼宽") → label 层最终覆盖 (优先级最高, 四态协议)
```

**覆盖机制**: 添加颜色/填充 scale 时自动取消 `plotit()` 中 `default_color` 注入的单色映射。

#### 3.3.5 坐标系函数族 `project_*`

**职责**：更改绘图坐标系。

**约定**：接收 `plotit` 对象，返回该对象。

**已定义**：
- `project_polar` → `coord_polar`
- `project_cartesian` → `coord_cartesian`（支持 `xlim`/`ylim`、`expand`、`clip`）
- `project_flip` → `coord_flip`（坐标轴翻转）

**待定义**：
- `project_trans` → `coord_trans`
- `project_fixed` → `coord_fixed`
- `project_map` → `coord_map` / `coord_sf`

#### 3.3.6 分面函数族 `split_*`

**职责**：定义分面布局。

**约定**：接收 `plotit` 对象，返回该对象。

**已定义**：
- `split_wrap` → `facet_wrap`
- `split_grid` → `facet_grid`（支持 `rows`、`cols`、`scales`、`space`；`...` 可作为 `rows` 的简写，同时使用 `...` 和 `rows` 时以 `...` 为准并报警告）

**待定义**：
- `split_matrix` → 自定义矩阵分面布局

#### 3.3.7 标签函数族 `label_*`

**职责**：设置图表的文本标签。

**统一行为**：
1. 将用户指定的文本更新到 `plot@meta@labels` 的对应字段；
2. 立即将相同的标签应用到 `plot@gg`，覆盖任何已有同级设置。

**`text` + `hide` 双参数协议**（所有函数通用）：

| 调用 | 行为 |
|---|---|
| `label_*(text = "str")` | 显示自定义文本 |
| `label_*(text = NULL)` | **重置**：轴/图例恢复为变量名，标题/副标题/脚注移除 |
| `label_*(hide = TRUE)` | **隐藏**：从布局中彻底移除（`element_blank()`） |
| 不调用该函数 | **跳过**：保留现有状态 |

- `text` 始终为 `NULL`（重置）或字符串（自定义）；`hide` 始终为逻辑值。
- `text = NULL` 与 R 惯例一致（`ggplot2::labs(x = NULL)` 即恢复默认变量名）。
- `hide = TRUE` 与 `text = NULL` 不同：前者移除元素及其占位空间，后者仅重置文本内容。

**限制**：`meta@labels` 各字段类型：`title`/`subtitle`/`caption` 为 `character | NULL`；`x`/`y` 为 `character | logical | NULL`（`FALSE` = 隐藏，`NULL` = 未设置/使用默认）；`legend` 为 `list | NULL`。文本参数不支持 `expression()` 对象。

**具体函数**：

| 函数 | 参数 | 用途 |
|---|---|---|
| `label_title` | `text`, `hide` | 设置主标题 |
| `label_subtitle` | `text`, `hide` | 设置副标题 |
| `label_caption` | `text`, `hide` | 设置脚注 |
| `label_axis` | `text`, `aes`, `hide` | `aes` = `"x"` 或 `"y"`（必填） |
| `label_legend` | `text`, `aes`, `hide` | `aes` = `"colour"`/`"fill"` 等（`NULL` = 所有已映射美学） |

**`label_*` 与 `scale_*(name=)` 的关系**：
- `scale_*(name=)` 负责该 scale 的默认名称（仅 `waiver()` / `"str"` 两种状态）。
- `label_axis` / `label_legend` 负责最终显示文本（`text` + `hide` 协议）。
- 两者同时设置时 `label_*` 优先级更高。

  > **注意**：`label_axis(text = NULL)` 会**重置**轴标题为变量名，覆盖此前 `scale_x(name = "Width")` 的设置。这是因为 `NULL` 的语义是"恢复默认"。如需保留已有标题，不调用该函数即可。

**缺省值定义**：
- 标题、副标题、脚注：无默认值（不调用时不存在）。`label_title(text = "")` 可设空字符串保留布局占位。
- 轴标题：缺省为对应映射中的变量名。`label_axis(text = NULL)` 恢复此默认。
- 图例标题：缺省为对应美学的变量名。`label_legend(text = NULL)` 恢复此默认。

#### 3.3.8 主题函数 `style()`

**职责**：应用主题。分为两个函数：

- **`style_default(plot, base_size, base_family)`** — 应用包级默认主题（基于 `theme_minimal` 调整）。`plotit()` 在构造时自动调用，用户也可手动调用覆盖。
- **`style(plot, theme, ...)`** — 应用任意 ggplot2 主题对象（如 `theme_minimal()`），`...` 传递额外 `theme()` 参数进行微调。`theme` 为必填参数。

**行为**：
- 操作 `plotit` 对象，向内部 `gg` 追加主题
- 返回该对象
- `style_default` 和 `style` 都会更新 `plotit_theme_managed` 标记，防止 `print()` 重复注入默认主题

**包级默认主题约定**：
- 基于 `theme_minimal` 调整
- **背景透明**（`fill = NA`），配合 `patchwork::plot_layout()` 固定面板尺寸时多余区域透明
- 仅保留主要网格线（浅灰色），无次要网格线
- 无衬线字体（Arial / Helvetica / 系统默认）
- 字体大小层次分明（标题加粗、轴标签略大）
- 图例默认右侧，背景透明

#### 3.3.9 导出函数 `export()`

**职责**：将图表渲染为文件。

**关键参数**：
- `plotit` 对象、文件名、输出尺寸（`width`/`height`）、分辨率、设备类型

**全局选项**：`export()` 在 `width`/`height` 为 `NULL` 且 `meta` 中无存储值时，回退到以下 `getOption()` 键：
- `getOption("plotit.default_width", 7)` — 默认宽度（英寸）
- `getOption("plotit.default_height", 5)` — 默认高度（英寸）
- `getOption("plotit.default_unit", "in")` — 默认单位（`"in"` / `"cm"` / `"mm"`）

用户可通过 `options(plotit.default_width = 10)` 等全局配置默认导出尺寸。

#### 3.3.10 图片尺寸算法（核心设计）

顶层概念区分：

| 术语 | 含义 | 来源 |
|---|---|---|
| **面板尺寸** | 数据绘图区域的宽×高 | `plotit(width, height, size_unit)` 用户指定 |
| **总尺寸** | 面板 + 坐标轴 + 标题 + 图例 + 边距 | `patchwork::patchworkGrob()` 构建 gtable 后测量 |

`plotit()` 的 `width`/`height` 始终指**面板尺寸**，存储于 `meta@width`/`meta@height`。

---

**阶段 1：构造时固定面板**（`plotit()`）

1. 用户指定 `width`/`height`/`size_unit` → 存储到 `meta`。
2. 若 `autofit = FALSE`，调用：
   ```r
   p + patchwork::plot_layout(
     widths  = unit(width,  size_unit),
     heights = unit(height, size_unit)
   )
   ```
   将 gtable 面板列/行设为**绝对单位**（如 `50mm`），非 `"null"` 弹性单位。
   此后无论设备多大，面板始终为该物理尺寸。

3. 若 `autofit = TRUE`，不注入 `plot_layout()`，面板保持弹性。

---

**阶段 2：预览时测量总尺寸**（`print()`）

| 条件 | 算法 |
|---|---|
| 尺寸非 NULL | `patchworkGrob()` 构建 gtable → `sum(gt$widths) + 1mm` → `dev.new()` 以该英寸值打开设备 → `print()` |
| 尺寸为 NULL | 不控制设备，直接 `print()`（使用当前默认设备） |

**1mm 边距**：参考 tidyplots 的 `get_layout_size()`，防止边缘描边/外延元素被设备边界裁切。

---

**阶段 3：导出时测量总尺寸**（`export()`）

| 条件 | 算法 |
|---|---|
| 尺寸非 NULL | `patchworkGrob()` 测量总尺寸（英寸）→ 若用户未传 `width`/`height` 则用测量值；用户传了则用用户值换算为英寸 |
| autofit = TRUE | `NA`（交由 `ggsave()` 自动决定）。若用户显式传入 `width`/`height`，以用户值为准（autofit 不覆盖显式尺寸）。 |

**单位统一为英寸**：所有路径最终传给 `ggsave(units = "in")`。`svglite` 等设备不接受 `units` 参数，统一换算避免了兼容性问题。

**PDF 背景**：通过 `ggsave(bg = "white")` 参数统一设定，避免跨调用 `mode(bg) differs` 警告。

> **实验性声明**：上述尺寸算法深度依赖 `patchwork::plot_layout()` 和 `patchwork::patchworkGrob()` 的内部实现细节。patchwork 的 gtable 结构变更或 ggplot2 升级可能导致测量偏差。"1mm 边距" 为当前经验值，不同设备/字体/主题下可能需要调整。此算法是当前最佳实践，但属于可替代的实现路径——若未来出现更可靠的面板尺寸控制方案，应在不破坏 API 契约的前提下切换。

**参考**：[tidyplots](https://github.com/jbengler/tidyplots) 的 `adjust_size()` + `get_layout_size()` 策略；[ggplot2](https://github.com/tidyverse/ggplot2) 的 gtable 渲染机制。

---

### 3.4 补充约定

#### 3.4.1 空数据与缺失值
- `plotit()` 接受非空 data.frame。空数据框的行为由 ggplot2 自然决定，包层不做额外验证。
- 因子水平：scale 的 `limits` 参数可强制包含未出现的因子水平，具体行为由底层 ggplot2 scale 决定。
- 缺失值（`NA`）：ggplot2 默认静默移除，包层不改变此行为。

#### 3.4.2 `export()` 完整参数

```r
export(plot, filename, width = NULL, height = NULL, dpi = 300, device = NULL, ...)
```

| 参数 | 默认 | 说明 |
|---|---|---|
| `plot` | 必填 | plotit 对象 |
| `filename` | 必填 | 输出路径，扩展名决定设备 |
| `width` | `NULL` | 输出宽度（meta 单位）；`NULL` = 自动 |
| `height` | `NULL` | 输出高度（meta 单位）；`NULL` = 自动 |
| `dpi` | `300` | 栅格格式分辨率 |
| `device` | `NULL` | 图形设备；`NULL` = 从扩展名推断 |
| `...` | — | 透传给 `ggplot2::ggsave()` |

#### 3.4.3 S7 类定义槽位

- `plotit_labels`：`title`、`subtitle`、`caption`（均为 `character | NULL`）；`x`、`y`（`character | logical | NULL`）；`legend`（`list | NULL`）
- `plotit_metadata`：`autofit`（`logical`）；`width`、`height`、`dodge`（`numeric | NULL`）；`unit`、`default_color`（`character | NULL`）；`labels`（`plotit_labels`）
- `plotit`：`gg`（`ggplot` 或 patchwork 包装对象）；`meta`（`plotit_metadata`）

#### 3.4.4 打印与设备策略
- `print()` 在交互模式下通过 `grDevices::dev.new(noRStudioGD = TRUE)` 打开新设备。
- 导出时通过 `ggsave()` 指定设备；未指定时从文件名扩展名推断。
- 默认使用 Cairo 图形设备（通过 `grDevices` 内置支持）。跨平台一致性由 ggplot2/grDevices 保证。

---

## 4. 代码风格要求

### 4.1 代码分割
- **一个函数族一个 `.R` 文件**，禁止单函数单文件：

  ```
  R/
  ├── class.R      # S7 类定义
  ├── utils.R      # 内部工具函数
  ├── encode.R     # encode()
  ├── plot.R       # plotit()
  ├── mark.R       # 所有 mark_* 泛型 + 方法
  ├── label.R      # 所有 label_* 泛型 + 方法
  ├── scale.R      # 所有 scale_* 泛型 + 方法
  ├── project.R    # 所有 project_* 泛型 + 方法
  ├── split.R      # 所有 split_* 泛型 + 方法
  ├── style.R      # style() + 默认主题
  ├── output.R     # print() + export()
  ```

- 文件名必须 `snake_case.R`，禁止连字符
- `R/` 下只放包源码，禁止测试脚本和可执行的示例代码

- 测试目录结构：

  ```
  tests/testthat/
  ├── test-encode.R     # encode()
  ├── test-plot.R       # plotit() 构造、守卫、default_color、autofit
  ├── test-mark.R       # 所有 mark_* + dodge 自动注入
  ├── test-scale.R      # 所有 scale_*：全部 trans × range × scheme
  ├── test-label.R      # 所有 label_*：四态协议、meta 同步
  ├── test-project.R    # 所有 project_*
  ├── test-split.R      # 所有 split_*
  ├── test-style.R      # style_default() + style()
  └── test-export.R     # export() + print()
  ```

- 项目根目录下的 `playground.R` 是专门用于快速手动测试的脚本文件，已加入 `.gitignore`，不纳入版本管理。
  - **永远为新**：`playground.R` 不累积历史测试用例，每次只保留当前需要的测试段。新请求写入时覆盖旧内容。
  - **有价值的用例应移入 `tests/testthat/`**：当一段测试需要作为回归上下文保留时，必须转化为正式的 testthat 测试文件（`tests/testthat/test-*.R`），使用 `devtools::test()` 运行。
  - 该文件仅用于交互式快速验证，不得包含任何可重复的回归测试逻辑；此类逻辑必须移至 `tests/testthat/`。
  - **用户触发"绘制"类 prompt 时的响应规则**：当用户说"绘制一个某某图"，意味着需要在 `playground.R` 中写入对应的测试段，供用户手动运行观察输出，而非在当前上下文中执行。每段测试应包括完整构造代码和观测要点注释。

### 4.2 命名与格式
- 函数名和参数名统一使用 **snake_case**。
- 函数族采用一致的动词前缀（`mark_`、`scale_`、`project_`、`split_`、`label_`）。
- **`color`/`colour` 等价**：包层 API 同时接受美式拼写 `color` 和英式拼写 `colour`，例如 `encode(color = Species)` 与 `encode(colour = Species)` 等效。函数命名及参数默认值统一采用美式拼写（`scale_color`、`default_color`）。内部通过 ggplot2 的自动归一化保证一致性，包层不做二次处理。
- 代码缩进为 **2 个空格**，行宽度控制在 **80 字符**以内（注释可适当放宽）。

### 4.3 注释语言
- **所有注释（包括 roxygen 文档、函数体内注释）均使用英文**。提交信息等外部文本可酌情使用中文，但代码中注释一律英文。
- 注释应清晰说明意图，而非重复代码。

### 4.4 管道与可读性
- 所有对象修改函数均返回对象自身，以支持 `%>%` 或 `|>` 管道链式调用。
- 每个管道步骤放置于独立行，提高可读性。

### 4.5 错误信息
- 主动验证点使用 `cli::cli_abort()` 提供结构化、友好的错误消息，给出问题原因和可能的修复建议。
- 其他位置的错误由底层 API 自然抛出，不在包层进行额外捕获或二次封装。

### 4.6 依赖与命名空间
- 使用 `pkg::fun()` 显式调用外部函数，避免通过 `@import` 或全局加载污染搜索路径。
- 内部工具函数使用 `%||%` 处理 `NULL` 默认值，保持代码简洁。

### 4.7 Roxygen 文档完整度

每个导出函数必须包含完整的 roxygen 文档块，至少包括：
- **标题**（一行简述）和**描述**（一段详细说明）
- **`@param`** 对每个参数，必须列出：
  - 参数含义
  - 对于 `trans` 参数：该 scale 允许的所有取值列表
  - 对于 `range` 参数：该 aesthetic 的 range 语义（scheme 名称 / 颜色向量 / 数值范围 / 忽略原因）
- **`@return`** 和 **`@export`**

**反例**：仅有 `#' @export` 无任何说明性文档的导出函数。

### 4.8 测试组织

- **按函数族分文件**：每个函数族一个 `tests/testthat/test-<family>.R` 文件，对应表如下：

  | 文件 | 覆盖 |
  |---|---|
  | `test-encode.R` | `encode()` |
  | `test-plot.R` | `plotit()` 构造、守卫、default_color、autofit |
  | `test-mark.R` | 所有 `mark_*` + dodge 自动注入 |
  | `test-scale.R` | 所有 `scale_*`：全部 trans × range × scheme 组合 |
  | `test-label.R` | 所有 `label_*`：四态协议、meta 同步 |
  | `test-project.R` | 所有 `project_*` |
  | `test-split.R` | 所有 `split_*` |
  | `test-style.R` | `style_default()` + `style()` |
  | `test-export.R` | `export()` + `print()` |

- **禁止单体测试文件**：不得将所有测试堆在一个文件中。
- **合法路径**：覆盖所有参数的有效取值及关键组合。对 `trans` × `range` 等乘法式参数，可使用参数化测试减少重复代码。
- **错误路径**：覆盖每个函数族中应抛出明确错误的非法输入（如 `scale_shape(trans = "identity")` 应报错，`label_axis(aes = "z")` 应报错），确保分域验证生效。
- **集成场景**：每个函数族至少包含一个管道链测试，模拟真实使用顺序。

### 4.9 代码格式化

- **Push 前必须格式化**：每次 `git push` 前执行 `styler::style_pkg()` 统一代码风格。
- 缩进 2 空格，行宽 80 字符（注释可放宽）。

### 4.10 函数体内注释

- 函数体内部避免重复代码的注释；对非显而易见的算法或设计决策必须注释，使用英文。
- 文件顶部的 section 分隔注释（`# ---- name ----`）和 roxygen 文档块（`#'`）不受上述限制。

---

## 5. 默认美观要求

> 本章描述当前版本的默认主题规格。这些规格属于 §1.4 的可迭代优化范围——在不破坏 API 契约的前提下，具体参数值（字号、颜色、间距等）可随版本调整。

### 5.1 主题基础
- 默认主题应基于 **简洁、无冗余元素** 的 ggplot2 内置主题（如 `theme_minimal`）进行优化，保证背景干净、网格线淡雅。
- 默认背景透明（`fill = NA`），配合 `patchwork::plot_layout()` 固定面板尺寸时多余区域透明。
- 必须为专业交流场景（研究报告、出版物）提供直接可用的外观，无需用户手动调整。

### 5.2 字体与排版
- 默认使用**无衬线字体**（如 Arial、Helvetica 或系统对应的默认无衬线字体），保证屏幕与打印的清晰度。
- 标题、轴标题、轴文本、图例文本等应有层次分明的字体大小和粗细（如标题加粗），形成清晰的视觉层级。
- 确保刻度标签在必要时可自动旋转，避免文本重叠。

### 5.3 颜色策略
- 当用户未指定任何颜色映射时，默认采用**单一颜色**绘制几何对象（颜色值可配置，如黑色或灰色），并隐藏图例。
- 当用户提供了颜色/填充美学映射，启用合适的**默认调色板**（建议优先考虑色盲友好、高区分度的方案，如 viridis 或 ColorBrewer 的定性调色板）。

### 5.4 网格与轴线
- 默认仅保留**主要网格线**（不要次要网格线），颜色使用浅灰色或淡色调，避免干扰数据展示。
- 轴线应清晰可见，坐标轴标题放置位置合理。

### 5.5 图例
- 图例默认放置在图表外部，通常为右侧或顶部。
- 图例背景透明，边框尽量简洁或不显示。

### 5.6 默认尺寸与比例
- 当不启用自适应尺寸时，导出的默认物理尺寸应适合学术或报告单栏排版（例如宽度约 80mm 左右），并维持合理的高宽比。
- 导出分辨率应默认适合打印（如 300 dpi）。
- 提供自适应选项，可令图表尺寸自动适应内容或设备。

---

## 6. 实现 Demo（API 协作流程）

```r
# 1. 构造映射
mapping <- encode(x = 变量1, y = 变量2, fill = 分组)

# 2. 创建基础图表
p <- plotit(data, mapping,
  autofit = FALSE, width = 6, height = 4,
  size_unit = "in", default_color = NULL
)

# 3. 添加几何图层
p <- mark_point(p, size = 2.5, alpha = 0.7)
p <- mark_boxplot(p)       # 箱线图
p <- mark_bar(p)           # 柱状图

# 4. 调整比例尺
p <- scale_fill(p, name = "组别")
p <- scale_x(p, trans = "log10")  # 对数坐标

# 5. 变换坐标系
p <- project_flip(p)           # 坐标轴翻转
p <- project_cartesian(p, xlim = c(0, 100))  # 限定范围

# 6. 分面
p <- split_wrap(p, 分组变量, ncol = 2)
p <- split_grid(p, rows = ggplot2::vars(行变量), cols = ggplot2::vars(列变量))

# 7. 设置标签
p <- label_title(p, "主标题")
p <- label_subtitle(p, "副标题")
p <- label_caption(p, "数据来源")
p <- label_axis(p, text = "自变量", aes = "x")
p <- label_axis(p, text = "应变量", aes = "y")
p <- label_legend(p, text = "图例标题", aes = "fill")

# 8. 应用主题
p <- style(p, theme_minimal(base_size = 12))

# 9. 导出文件
export(p, "output.pdf", dpi = 300)
```

**扩展性示例**：若用户需自行更改后端（如替换导出的渲染引擎、修改默认主题细节），只需保证新的实现仍然遵循上述流程与参数的语义约定，前端代码无需任何改动。

---

## 7. Bug 审查经验

以下原则来自开发过程中反复出现的缺陷模式，用于审查代码时系统性地发现问题。原则并非穷举——审查中发现的任何可复用经验都应追加到此列表中。

### 原则 0：区分特性与 Bug

审查发现必须首先甄别是缺陷还是设计意图。

**通常是特性（非 bug）**：

| 报告模式 | 判断依据 |
|---|---|
| "静默忽略某参数" | 若文档/注释明确说明该参数在此上下文中不适用，且无运行时错误 |
| "默认值策略保守" | 如 `.detect_discrete_aes` 找不到变量时默认返回离散——安全回退 |
| "似乎可以更高效/更简洁" | 风格偏好，非功能缺陷 |
| "XX 和 YY 行为不一致" | 需验证两种行为是否各有意图（如 shape↔linetype 的 range→manual 本应对称，不对称才是 bug） |

**通常是 bug**：

| 报告模式 | 判断依据 |
|---|---|
| "参数传入但不生效" | 用户调用后无预期效果 |
| "特定参数组合崩溃" | 运行时报错 |
| "对称函数行为不同且无意为之" | 例如 color↔fill 一侧生效一侧不生效 |

### 原则 1：参数全链路追踪

新增参数时必须验证其 **完整传递链**：用户 API → 泛型 → 方法 → 内部 dispatcher → 底层库。

每个中转节点回答：该参数在此处是 (a) 直接转发、(b) 转换为另一种形式、(c) 被条件分支丢弃？若丢弃，是设计意图还是遗漏？

### 原则 2：枚举值分支穷举

参数有 N 个合法值时，N 条路径必须全部显式存在。反例：`if (discrete) ... else ...` 只处理了二态，新增 `binned` / `reverse` 后被静默吞没。

### 原则 3：对称抽象一致性

存在镜像函数/分支时（color↔fill、size↔alpha、shape↔linetype、x↔y），修复一侧后必须检查另一侧。

### 原则 4：默认值分叉

参数默认值在不同条件下取不同值时，新增条件分支必须同步更新默认值逻辑。

### 原则 5：底层接口兼容性

透传参数前确认底层函数真正接受该参数。不接受时需切换底层函数（如 `range` 迫使 shape/linetype 从 `*_discrete()` 切换为 `*_manual()`），且所有对称分支须同步切换。

### 原则 6：内部概念不泄漏

包层参数名和底层参数名可能同名但语义不同。如 `trans = "binned"` 是包层的"映射算法选择"，不应透传给 ggplot2 的 `trans`/`transform` 参数——底层期待坐标变换名。选择了 `scale_*_binned()` 后不应再传 `trans = "binned"`。

