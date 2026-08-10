# plotit 代码审查报告

审查日期: 2026-07-19
审查范围: `R/` 目录下的全部源代码及 `tests/testthat/` 测试文件
基线: `dev` 分支, 最新提交 `42231fd`

复审日期: 2026-08-10
复审基线: `dev` @ `42231fd` + 未提交的 `R/mark.R` 重写（mark_sankey / mark_chord 改为 edges-table API）
复审环境: R 4.5.2 / ggplot2 4.0.3 / ggsankey 0.0.99999 (HEAD)
复审验证: 源码全读 + `pkgload::load_all` 行为实测 + 完整 testthat 套件（3 失败）

---

## 概览

plotit 是一个声明式 ggplot2 封装 R 包，使用实验性 S7 OOP 系统。整体代码组织清晰，文档完善，提供约 30 个 `mark_*` 几何层函数、完整的标度/标签/主题/合成系统，以及工厂函数用于扩展。架构简洁，统一了 `plotit()` → `mark_*()` → `scale_*()` → `label_*()` → `style()` → `export()` 的管道化工作流程。

---

## 严重缺陷

### 1. `mark_sankey` / `mark_network` / `mark_chord` 替换整个 `gg` 对象

**文件**: `R/mark.R:1268`, `R/mark.R:1468`, `R/mark.R:1582`

这三个 marks 通过 `plot@gg <- gg` 完全替换底层的 ggplot 对象，丢弃之前添加的所有层、主题和标度。这与系统其余部分（`._mark_impl` 使用 `plot@gg + geom` 增量构建）形成严重不一致。

```r
mark_sankey:
  plot@gg <- gg   # 丢弃所有之前的层！

mark_network:
  plot@gg <- gg   # 同上

mark_chord:
  plot@gg <- gg   # 同上
```

**影响**: 以下代码会静默丢失第一个 `mark_point()`:
```r
plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
  mark_point() |>
  mark_sankey(...)   # 丢弃 point 层
```

**建议**:
- `mark_network` 和 `mark_sankey`: 将现有 `plot@gg$layers` 和 `plot@gg$theme` 继承到新构建的 gg 对象中，而非完全替换。
- `mark_chord`: `circlize` 通过 base R 图形系统（非 ggplot2）渲染，应重新设计为 `annotation_custom()` + grid 封装，或明确归类为"原生渲染器"并记录其不兼容性。

---

### 2. `mark_chord` 绕过 ggplot2 的渲染系统

**文件**: `R/mark.R:1544, 1554, 1584-1590`

`mark_chord` 直接调用 `circlize::chordDiagram()`，绘制到当前图形设备，不参与 ggplot2 的构建系统。它然后替换为一个空的 `theme_void()` ggplot。结果是一个混合体——`print()` 会创建两个绘图设备。

```r
circlize::chordDiagram(mat, ...)  # 直接绘制到设备
gg <- ggplot2::ggplot() + ggplot2::theme_void()
plot@gg <- gg
```

`rasterize` 参数实际上毫无意义——该函数不添加任何 ggplot geom。

**建议**: 使用 `annotation_custom()` + `grid::grid.grab()` 封装 circlize 的输出，使其与 ggplot2 的构建系统兼容。或将其从标准 mark 中移除，作为独立函数提供。

---

## 高优先级

### 3. `mark_corr` 中 `stats::cor()` 缺少 `use` 参数

**文件**: `R/mark.R:761`

```r
mat <- stats::cor(raw_data[, num_cols, drop = FALSE], method = method)
```

默认 `use = "everything"` 意味着任何列中包含 NA 都会使整个相关系数矩阵为 NA。

**建议**: 改为：
```r
mat <- stats::cor(raw_data[, num_cols, drop = FALSE], method = method,
                  use = "pairwise.complete.obs")
```

---

### 4. `mark_density_2d` 重复 `._mark_impl` 逻辑

**文件**: `R/mark.R:692-716`

该方法的 ~25 行几乎逐字复制了 `._mark_impl()`（第 11-30 行），添加的唯一逻辑是 `filled` 参数切换 `geom_fun`。可直接调用 `._mark_impl` 并仅传递 `dots` 参数。

**建议**: 重构为调用 `._mark_impl`，只保留 filled/bins 逻辑。

---

### 5. `mark_sankey` 新 edges-table API 的 fill 颜色问题

**文件**: `R/mark.R:1236-1241`

```r
sankey_data$fill_grp <- c(fill_vals, fill_vals)
```

如果 `fill` 映射到数值列（例如连续型颜色映射），`as.character()` 强制转换会丢失语义。

---

### 6. `make_theme` 使用 `assign()` 到 `parent.frame()`

**文件**: `R/factory.R:80`

```r
assign(name, fun, envir = parent.frame())
```

如果用户在函数内部调用 `make_theme()`，主题变量分配到该函数的本地环境，在函数返回时丢失。

**建议**: 明确分配位置，记录该函数默认分配到 `.GlobalEnv`，并返回该函数让用户可自行赋值。

---

### 7. 测试中 `mark_network` 使用 `skip()` 覆盖功能测试

**文件**: `tests/testthat/test-mark.R:704, 720`

三个 mark_network 测试中有两个被跳过。这与新的 data.frame 节点 API 不一致——这些测试应该更新以使用新的 API 并移除 skip。

**建议**: 用新的 `nodes` data.frame + `edges` 参数 API 重写被跳过的测试。

---

## 中优先级

### 8. `mark_lollipop` 硬编码 y=0 参考线

**文件**: `R/mark.R:1004`

```r
stem_mapping <- encode(x = x_col, xend = x_col, y = 0, yend = y_col)
```

对于具有负值的数据或非中心化数据，会产生误导性视觉。

**建议**: 添加 `ref = 0` 参数。

---

### 9. `mark_smooth` 的 `do.call()` 闭包陷阱

**文件**: `R/mark.R:602-609`

```r
do.call(function(...) { ._mark_impl(plot, mapping, data, position, ...) }, params)
```

如果用户 `...` 中传递名为 `plot` 或 `mapping` 的参数，会覆盖闭包变量。

**建议**: 显式传递已知参数，将剩余参数作为命名列表传递。

---

### 10. `mark_significance` 使用数值位置而非比例位置

**文件**: `R/mark.R:919-954`

使用 `seq_along(x_levels)` 整数索引。对于非均匀间距的分类轴（如 `scale_x_discrete(limits=...)` 跳过某些水平）会失效。

---

### 11. `mark_chord` 中重复的源/目标对

**文件**: `R/mark.R:1564-1566`

fill 映射（第 1571-1575 行）对于同一来源多次出现时使用最后写入，但累积矩阵使用求和。当同一源行有不同 fill 值时行为不一致。

---

## 低优先级

### 12. S7 属性访问不一致: `@` vs `S7::prop()`

**文件**: 多处

- `R/mark.R:18`: `plot@meta@dodge` —— 直接 `@` 访问
- `R/utils.R:46`: `S7::prop(plot@meta, "default_color") <- NULL` —— 通过 `prop()`
- `R/label.R:37`: `S7::prop(plot@meta@labels, slot_name)` —— 混合

S7 文档推荐 `prop()` 用于可维护性。建议全库统一。

---

### 13. `._sync_labels` 的 legend 处理对 patchwork 对象修复不完全

**文件**: `R/label.R:171-178`

直接修改 `plot@gg$plots[[.i]]$labels` 绕过 ggplot2 公共 API，且仅处理 `FALSE`/`NULL` 情况，未处理 `text` 设置。

---

### 14. 默认主题的 `plotit_theme_managed` 属性保护不完全

**文件**: `R/output.R:62-64`

```r
if (is.null(attr(x@meta, "plotit_theme_managed", exact = TRUE))) { ... }
```

如果用户通过 `plot@gg$theme <- ...` 直接绕过 `style()`，该属性不会被设置，导致 `print()` 时默认主题被重复应用。

---

### 15. `project_parallel` 内部列名冲突检测

**文件**: `R/project.R:406-417`

预留 `.plotit_id` / `.plotit_val` / `.plotit_var` 作为内部列名，检测到冲突时报错。建议报错信息列出具体冲突的列名。

---

## 设计评价

### 优秀设计

| 设计 | 文件 | 评价 |
|------|------|------|
| `._register_mark_method` 工厂模式 | `R/mark.R:55-67` | 减少 15+ 个标准 mark 的样板代码 |
| `._clear_default_color` 条件清除 | `R/utils.R:23-57` | 巧妙地解决了"映射前单色"语义 |
| 惰性标签系统 | `R/label.R` | 在 `meta@labels` 中存储，`print()`/`export()` 时同步，允许任意调用顺序 |
| 标度转换验证 | `R/scale.R:41-65` | 为常见错误组合提供针对性错误信息，优于通用 "must be one of" |
| 工厂函数 `make_mark` / `make_theme` | `R/factory.R` | 扩展性良好，文档完善 |

### 一致性检查清单

- [x] 标准 mark 使用统一签名 `(plot, mapping, data, position, ..., rasterize, ...)`
- [x] 错误使用 `cli::cli_abort` 带 `i`/`x` 前缀提示
- [x] 内部函数以 `._` 或点号开头且标注 `@noRd`
- [x] S7 generic + method 分离为 `@export` generic + `@export` method
- [ ] ⚠️ 非标准 mark（sankey、network、chord）不一致
- [ ] ⚠️ `@` vs `prop()` 不一致

---

## 总结

总体代码质量评分: **B+**

**主要优势**:
- 一致且可预测的管道 API
- 优秀的错误/警告用户体验
- 良好的测试覆盖率（含 BDD 风格测试）
- 惰性评价系统避免打印时问题
- 工厂函数使扩展可开箱即用

**首要修复事项**:
1. 修复 `mark_sankey` / `mark_network` / `mark_chord` 的"替换 gg"模式
2. 重构 `mark_chord` 以与 ggplot2 渲染系统兼容
3. 修复 `mark_corr` 的 NA 处理
4. 消除 `mark_density_2d` 的代码重复
5. 更新 `mark_network` 测试以匹配新 API

---

## 2026-08-10 复审（第二轮）

> 第一轮报告（上文）问题全部保留——截至本复审，15 项**无一修复**。
> 工作树唯一的改动是 `R/mark.R`（sankey/chord 重写），而该重写本身引入了新的阻断级缺陷（见下文）。
> 行号均指复审当时的文件位置。

### 0. 原 15 项问题状态核验

| # | 原问题 | 状态 | 当前证据 |
|---|--------|------|----------|
| 1 | sankey/network/chord 替换整个 `@gg` | ❌ 未修复 | `R/mark.R:1268` / `:1468` / `:1582` 仍 `plot@gg <- gg` |
| 2 | chord 绕过 ggplot2 渲染系统 | ❌ 未修复 | `R/mark.R:1543-1545, 1553-1557, 1584-1590` 仍直绘设备 |
| 3 | mark_corr 缺 `use=` 参数 | ❌ 未修复 | `R/mark.R:761`：`stats::cor(..., method = method)`，NA 列 → 全 NA 矩阵 |
| 4 | mark_density_2d 复制 `._mark_impl` | ❌ 未修复 | `R/mark.R:692-716` 仍为逐字副本 |
| 5 | sankey fill 强制 `as.character` | ⚠️ 重写中仍存在 | `R/mark.R:1237-1238`：数值型 fill 列仍丢失连续语义 |
| 6 | make_theme `assign(parent.frame())` | ❌ 未修复 | `R/factory.R:80` |
| 7 | network 测试 skip 覆盖功能测试 | ❌ 未修复 | `tests/testthat/test-mark.R:704, 720` 仍 `skip()` |
| 8 | lollipop 硬编码 y=0 基线 | ❌ 未修复 | `R/mark.R:1004`；另有死代码 `fill_val`（`:1013-1017`） |
| 9 | smooth do.call 闭包陷阱 | ⚠️ 复审判定为**误报** | `function(...)` 内引用 `plot` 走词法作用域，`do.call` 参数不遮蔽；仅当用户 `...` 显式传 `plot=`/`mapping=` 才会触发多重匹配错误（概率极低） |
| 10 | significance 整数位 x 定位 | ❌ 未修复 | `R/mark.R:913-920`，`scale_x_discrete(limits=...)` 收缩时错位 |
| 11 | chord 重复源/目标 fill 覆盖 | ❌ 未修复 | `R/mark.R:1573-1575`：同一源多次出现时 last-write-wins，与求和矩阵不一致 |
| 12 | `@` vs `S7::prop()` 混用 | ❌ 未修复 | 全库（`mark.R:18` `@`、`utils.R:46` `prop()`、`label.R:37` 混合） |
| 13 | legend 的 patchwork 分支不完整 | ❌ 未修复 | `R/label.R:171-179` 只处理标签不处理主题，且只读 patchwork 内部 `$plots` |
| 14 | theme_managed 绕过路径 | ❌ 未修复 | `R/output.R:62-64`；sankey/chord 替换 `@gg` 后问题加剧（新图无标记且丢主题） |
| 15 | parallel 预留列名报错 | ⚠️ 部分满足 | `R/project.R:408-412` 的 `i` 提示已列出全部预留名（未列出数据中实际冲突列） |

### 1. 阻断级回归（未提交的 `R/mark.R` 重写引入）

| # | 缺陷 | 证据 |
|---|------|------|
| A1 | **mark_sankey 不回落全局 mapping**：`mapping=NULL` 时直接 `mapping$source`（NULL）而不读 `plot@gg$mapping`，文档示例（plotit 层 `encode(source=...)`）渲染**空图**且无报错 | `R/mark.R:1215-1221`；实测 `layers: 3, nrow: 0` |
| A2 | **mark_sankey 显式传 mapping 仍渲染 0 行**：`ggplot_build` 首层 0 行，伴随 "Ignoring unknown aesthetics: next_x, node, next_node, and value"。根因 `ggplot2 4.0.3` 下 ggsankey HEAD（0.0.99999）的旧式 `aesthetics` 字段失效，关键美学被静默丢弃 | 实测 `first-layer-rows: 0`；纯 ggsankey 直接使用同样报错 "object 'value' not found" |
| A3 | **mark_chord 不回落全局 mapping**：文档示例 `plotit(encode(source=...,target=...,value=...,fill=...)) |> mark_chord()` 直接报错 "mark_chord needs encode(source=, target=, value=) or Var1/Var2/Freq columns." | `R/mark.R:1536`；实测 ERROR |
| A4 | **`@gg` 整对象替换导致默认美观契约破碎**：新构建的 ggplot 为默认 `theme_grey`；`plotit_theme_managed` 标记在 meta 上，print 补丁不触发；先前图层/scale/label 全丢 | 实测 `theme: theme`（非 plotit 默认主题） |
| A5 | **测试套件 3 失败 + 1 组虚过**：`test-mark.R:716`（network 错误消息不匹配 igraph 原文）、`:736/:754`（chord 旧 `from/to/value` API 被删除）；`:642-666` sankey 测试仍用旧 make_long API 且只断言类名，空渲染也"通过" | 完整 testthat 运行 |

### 2. 新发现（第一轮未覆盖）

| # | 缺陷 | 位置 | 证据 |
|---|------|------|------|
| B1 | **compose_* 子图惰性标签不同步**：组装只取 `@gg`，composite 的 print/export 只应用 annotations，从不 `._sync_labels()`——子图 `label_axis` 等设置静默丢失（违反约定 §1.2） | `R/compose.R` 全组装路径 | 实测 `label_axis(text="My Width")` 后 compose，`comp@plots[[1]]@gg$labels$x` 仍 NULL |
| B2 | **mark_corr 不清除 default_color → fill 图例被抑制**：内部构建 `fill=value` 映射但未调用 `._clear_default_color()`，`plotit()` 注入的 `guides(fill="none")` 仍在，热力图默认无图例 | `R/mark.R:750-780` | 对比 mark_rect/treemap 均有清除逻辑 |
| B3 | **mark_beeswarm 警告泄漏**："Ignoring unknown parameters: position"——全局 dodge 自动注入 `position_dodge` 不被 `ggbeeswarm::geom_beeswarm` 接受 | `R/mark.R:17-20` + beeswarm | 测试运行警告 |
| B4 | **mark_network 两个隐式假设**：`node_id_col <- names(nodes)[1]` 首列即 id（未文档化，出错时是 igraph 原始报错）；`layout="manual"` 映射到 `"nicely"`（语义不符，manual 未实现） | `R/mark.R:1421`, `:1444` | `test-mark.R:716` 失败即证 |

### 3. 与 AGENTS.md 约定的偏离（按 §1.6 属"实现改进则修约定"）

| 约定条款 | 现状 | 偏离 |
|---|---|---|
| §3.2 已实现 mark 表（18 种） | 实际 27 种（+9 复合/关系） | 表未更新 |
| §9.4 完成度（mark 6 个 / 30%） | 实际 27 个 | 严重过时 |
| §9.2 阶段 1-4 "未开始" | 全部已实现 | 状态未标 ✅ |
| §3.3b 复合 Mark 原则 3 "不接受 rasterize" | `mark_errorbar` 签名含 `rasterize`（`R/mark.R:812`） | 设计偏离 |
| §3.3b `mark_errorbar` 典型参数 `stat`("ci"/"stderr"/"stdev") | 实现仅包装 `geom_errorbar`，无 stat 参数 | 文档承诺未实现 |
| §4.6 `gg$labels` 标注"只读" | `R/label.R:99/102/124/176` 直接写入 | 行为与文档不符（懒标签设计依赖写入，建议约定改为"可写"并注明理由） |
| §3.3.5 parallel "none" 模式文档写 `geom_vline` | 实现用 `geom_segment`（更好） | 文档文字过时 |

### 4. 已排除的疑点（防误修）

- **sankey `val` 逻辑并非反转**：`R/mark.R:1221` 为 `if (is.null(val))`，正确。
- **mark_smooth do.call 闭包**：为误报（见上方 #9 核验）。
- **"hue" scheme 的 `direction` 参数**：ggplot2 4.0.3 下 `scale_colour_discrete` 首参为 `...`，实测无错，跨版本风险低。

### 5. 复审结论与修复优先级

**首要修复事项**（P0，恢复功能与测试）：

1. mark_sankey：`mapping` 回落 `plot@gg$mapping`；缺 source/target 时 `cli_abort`；同步更新 3 个测试为 edges-table API 并增加"渲染行数 > 0"断言（若 ggsankey × ggplot2 4.0 不兼容，测试加版本 guard）
2. mark_chord：同样回落全局 mapping；保留旧 `from/to/value` 分支或更新测试二选一（倾向保留兼容）
3. mark_network：首列作 id 失败时给出定向错误消息（替代 igraph 原始报错）
4. compose_*：组装前对子图调用 `._sync_labels()`

**P1（一致性收尾）**：

5. mark_corr：补 `use="pairwise.complete.obs"` + `._clear_default_color(plot)`
6. mark_beeswarm：跳过自动 dodge 注入
7. 按 §1.6 同步更新 AGENTS.md §3.2 / §9.2 / §9.4 / §3.3b；修复 mark_sankey roxygen 重复标题（`R/mark.R:1154, 1156`）

**P2（低优先级）**：

8. lollipop 增加 `ref=` 参数（默认 0）、删除死代码 `fill_val`
9. mark_errorbar 的 `rasterize` 参数与 §3.3b 对齐
10. mark_density_2d 复用 `._mark_impl`
11. `make_theme` 返回函数并文档化分配位置

---

## 2026-08-10 复审（第三轮）

> 工作树与第二轮相同（`dev` @ `42231fd` + 未提交 `R/mark.R` 重写），15 项问题仍无一修复。
> 本轮方法：R 源码全读 + **15 项行为实测**（`pkgload::load_all` 加载工作树）+ 完整 testthat 套件运行。
> 行号均指本轮审查时的文件位置（与第二轮一致）。

### 0. 前两轮问题状态核验（实测）

| # | 原问题 | 状态 | 本轮实测证据 |
|---|--------|------|--------------|
| 1 | sankey/network/chord 替换整个 `@gg` | ❌ 未修复 | `R/mark.R:1268/:1468/:1582` 仍 `plot@gg <- gg`；实测 sankey 后 `theme` 为 `theme`（默认 theme_grey） |
| 2 | chord 绕过 ggplot2 渲染系统 | ❌ 未修复 | `R/mark.R:1543-1544/:1553-1554/:1584-1590` 仍直绘设备 |
| 3 | mark_corr 缺 `use=` | ❌ 未修复 | `R/mark.R:761`：`stats::cor(..., method = method)`，NA 列 → 全 NA 矩阵 |
| 4 | mark_density_2d 复制 `._mark_impl` | ❌ 未修复 | `R/mark.R:692-716` 仍为逐字副本 |
| 5 | sankey fill 强制 `as.character` | ❌ 未修复 | `R/mark.R:1237-1238`：数值型 fill 列丢失连续语义 |
| 6 | make_theme `assign(parent.frame())` | ❌ 未修复 | `R/factory.R:80` |
| 7 | network 测试 skip 覆盖功能测试 | ❌ 未修复 | `tests/testthat/test-mark.R:704, 720` 仍 `skip()`，且仍用已废弃的 igraph 对象 API |
| 8 | lollipop 硬编码 y=0 + 死代码 | ❌ 未修复 | `R/mark.R:1004`（y=0 基线）、`:1013-1017`（`fill_val` 死代码仍存在） |
| 9 | smooth do.call 闭包陷阱 | ⚠️ 误报（维持） | 词法作用域不遮蔽；仅用户显式传 `plot=` 才触发多重匹配（概率极低） |
| 10 | significance 整数位 x 定位 | ❌ 未修复 | `R/mark.R:913-920`，`scale_x_discrete(limits=...)` 收缩时错位 |
| 11 | chord 重复源/目标 fill 覆盖 | ❌ 未修复 | `R/mark.R:1573-1575` last-write-wins 与求和矩阵不一致 |
| 12 | `@` vs `S7::prop()` 混用 | ❌ 未修复 | `mark.R:18` `@`、`utils.R:46` `prop()`、`label.R:37` 混合 |
| 13 | `._sync_labels` legend patchwork 分支不完整 | ❌ 未修复 | `R/label.R:171-179` 仍直接改 `$plots[[.i]]$labels` 且仅处理 FALSE/NULL |
| 14 | theme_managed 绕过路径 | ❌ 未修复 | `R/output.R:62-64`；实测 sankey 新图 `theme` 为默认 theme_grey 且 `attr(meta, "plotit_theme_managed") == TRUE` 阻止 print 补丁 |
| 15 | parallel 预留列名报错 | ⚠️ 部分满足 | `R/project.R:408-412` 列出预留名，未列出数据中实际冲突列 |

### 1. 阻断级回归（A 组）实测核验

| # | 缺陷 | 实测结果 |
|---|------|----------|
| A1 | **mark_sankey 不回落全局 mapping**：`mapping=NULL` 时 `mapping$source` 为 NULL → `as.character(NULL)` → 空数据 | **确认**：文档示例（plotit 层 `encode(source=...)`）无报错，`layers: 3` 但 `first-layer-rows: 0`，渲染空图 |
| A2 | **sankey 显式 mapping 仍 0 行**（ggsankey HEAD × ggplot2 4.0.3 不兼容） | **确认**：显式 mapping 后 `first-layer-rows: 0`，伴随 "Ignoring unknown aesthetics: next_x, node, next_node, and value"；另有 `NAs introduced by coercion` 警告 |
| A3 | **mark_chord 不回落全局 mapping** | **确认**：文档示例直接报错 `mark_chord needs encode(source=, target=, value=) or Var1/Var2/Freq columns.` |
| A4 | **`@gg` 整对象替换破坏默认美观契约** | **确认**：sankey 后 `theme class: theme`（theme_grey）；`theme_managed` 标记在 meta 上为 TRUE，print 补丁不触发 |
| A5 | **测试 3 失败 + 1 组虚过** | **确认**：完整 testthat 运行恰 3 失败——`:716`（`vertices contains duplicated vertex names`，不含 "igraph"）、`:736/:754`（chord 旧 from/to/value API 报错）；`:642-666` sankey 测试用旧 make_long API，只断言类名，空渲染也通过 |

### 2. 新发现（第三轮，B/C 组）

B 组（第二轮发现，本轮实测确认）：

| # | 缺陷 | 实测证据 |
|---|------|----------|
| B1 | compose_* 子图惰性标签不同步 | **确认**：`label_axis(text="My Width", aes="x")` 后 compose，`plots[[1]]@gg$labels$x` 为 NULL，composite print（`._apply_annotations`）后仍 NULL——标签静默丢失（违反约定 §1.2） |
| B2 | mark_corr 不清除 default_color → fill 图例被抑制 | **确认**：`guides$guides` 仍为 `list(colour="none", fill="none")`，`gg$mapping$fill` 仍为 `I("#4E79A7")`，`meta@default_color` 未清；对照 `default_color=NULL` 时图例正常 |
| B3 | mark_beeswarm 警告泄漏 | **确认**：实测警告 `Ignoring unknown parameters: position`（自动 dodge 注入不被 geom_beeswarm 接受） |
| B4 | mark_network 首列即 id / manual→nicely | **确认**：iris 数据报 igraph 原始错误 `vertices contains duplicated vertex names`（无定向提示）；`:1444` `manual` 仍映射 `"nicely"` |

C 组（第三轮新增）：

| # | 缺陷 | 位置 | 证据 |
|---|------|------|------|
| C1 | **mark_map 的 layer 级 fill 映射不清除 default_color**（只检查 `mapping$colour`，`:357`；与 B2 同类） | `R/mark.R:357-359` | 实测 `plotit(nc, encode(geometry=geometry)) |> mark_map(mapping=encode(fill=AREA))` 后 `mapping$fill` 仍 `I("#4E79A7")`、`meta@default_color` 保留、`guides$guides$fill="none"` 残留 → fill 图例被抑制 |
| C2 | **mark_sankey 的 `flow_alpha` 未映射到 ggsankey `flow.alpha`**：实现传 `alpha = flow_alpha`（`:1254/:1257`），而 ggsankey 的 `prepare_params` 用 `flow.` 前缀拆分 flow/node 参数 | `R/mark.R:1254, 1257` | 实测 `alpha=0.5` 同时进入 flow 层（GeomPolygon `aes_params$alpha=0.5`）和 node 层（GeomRect `aes_params$alpha=0.5`）——节点矩形也半透明，与 `flow_alpha` 语义不符 |
| C3 | **mark_significance 无 y 映射时强制计算 y_range**：即使提供 `y_position` 也在 `:902-904` 无条件 `range(y_var)` | `R/mark.R:901-904` | 实测 `plotit(df, encode(x=group)) |> mark_significance(comp, y_position=c(9))` 产生 `no non-missing arguments to min/max` 警告 + Inf/-Inf 垃圾坐标 |
| C4 | **mark_dumbbell 缺 `yend` 映射时无定向校验** | `R/mark.R:1074` | 实测 `encode(x=cat, y=before)` 无 yend 时构建期不报错，print/build 时抛底层错误 `geom_point() requires the following missing aesthetics: y`（用户无法定位原因） |
| C5 | **mark_chord 用 `rlang::f_rhs()` 剥离 quosure 环境**：`:1537-1539/:1571` 先取表达式再 `eval_tidy(expr, edges)`，与 mark_sankey 的 `eval_tidy(quosure, edges)`（`:1218-1220`）不一致，丢失词法环境，外部变量引用可能解析错误 | `R/mark.R:1537-1539, 1571` | 静态分析；两函数风格不一致，sankey 写法正确，chord 应统一 |

另（杂项）：`R/mark.R:1154, 1156` sankey roxygen 重复标题仍存在；`mark_text`（`:272-274`）与 `._mark_impl`（`:14-16`）双重 `._clear_default_color` 冗余（幂等无害）；仓库根目录与 `tests/testthat/` 下残留 `Rplots.pdf` 垃圾文件。

### 3. 与 AGENTS.md 约定的偏离（复核）

| 约定条款 | 现状 | 偏离状态 |
|---|---|---|
| §3.2 已实现 mark 表（18 种） | 实际 27 种（errorbar/lollipop/dumbbell/significance/beeswarm/sankey/treemap/network/chord 共 9 个已实现未标 ✅） | ❌ 表未更新 |
| §3.3b 复合 Mark 原则 3 "不接受 rasterize" | `mark_errorbar` 签名含 `rasterize`（`R/mark.R:812`） | ❌ 设计偏离 |
| §3.3b `mark_errorbar` 典型参数 `stat`("ci"/"stderr"/"stdev") | 实现仅包装 `geom_errorbar`，无 stat 参数 | ❌ 文档承诺未实现（修复时二选一：实现 stat 或删文档） |
| §3.3.5 parallel "none" 模式写 `geom_vline`+`geom_segment`+`geom_text` | 实现仅 `geom_segment`+`geom_text`（`._pp_draw_axes`） | ⚠️ 文档文字过时（去掉 `geom_vline`） |
| §4.6 `gg$labels` 标注"只读" | `R/label.R:99/102/124/176` 直接写入 | ⚠️ 行为与文档不符（懒标签设计依赖写入；建议约定改为"可写"并注明理由） |
| §3.2 关系类 mark 的 API 描述 | sankey/chord 已改为 edges-table API、network 改为 nodes+edges 双数据源，约定表仅列函数名与底层实现 | ⚠️ API 描述未同步（建议补注） |

### 4. 深度扫描新发现（D/E/F 组，第三轮扩展）

> 本轮在 A/B/C 组核验之外，补充了 20 项边界场景实测与全库模式扫描（grep 定位：`plot@gg <- gg` 5 处、`eval_tidy(mapping$...)` 10 处、`expect_s3_class` 25+ 处）。

#### 5.1 新确认的问题

| # | 问题 | 位置 | 实测证据 | 严重度 |
|---|------|------|----------|--------|
| **F1** | **包加载产生 50 个 S7 警告**：zzz.R 循环注册 composite 拒绝方法时，方法签名 `function(plot, ...)` 与泛型完整签名（mapping/data/position/rasterize 等）不一致，S7 对每个缺失参数发出 "mark_point(<plotit::plotit_composite>) doesn't have argument 'mapping'" 警告 | `R/zzz.R:68-95` | `load_all()` 后 `warnings()` 计数 = 50；此前所有核验脚本中 "There were 50 or more warnings" 噪声均源于此（非 treemap 等） | **高**（用户 `library(plotit)` 第一印象即警告刷屏） |
| D1 | **mark_hex 依赖 hexbin 未声明且无检查**：`stat_bin_hex` 需要 hexbin，DESCRIPTION Suggests 缺 hexbin，mark_hex 也无数值 requireNamespace（其余可选依赖 mark 均有）→ 底层警告 "The package hexbin is required for stat_bin_hex" | `R/mark.R:647-657` + `DESCRIPTION` | 实测未装 hexbin 时 build 警告；`test-mark.R:418` 测试只查类名未暴露 | 中 |
| D2 | **mark_sankey / mark_network 的 roxygen 示例使用不存在的 scheme**：示例 `scale_fill(range = "tableau")`、`scale_color(range = "category10")`，而 `._scale_colour_fun` 仅支持 viridis/brewer/grey/hue | `R/mark.R:1193, 1381` | 实测两示例均报错 `"tableau"/"category10" is not a known colour scheme name`——文档示例（用户第一入口）运行即失败 | 中 |
| D3 | **mark_significance 标量 aes 层警告泄漏**：`geom_segment`/`geom_text` 用 `encode(x = x1, ...)` 常量标量（长度 1）且未指定单行 data → build 时 "All aesthetics have length 1, but the data has 3 rows" | `R/mark.R:924-953` | 实测每次 build 4 条警告；`test-mark.R:537` 只查类名未暴露 | 中 |
| D4 | **复合 mark 用"值即表达式"构造 mapping（静默错位/崩溃）**：`mark_lollipop`/`mark_dumbbell`/`mark_significance` 将求值后的值向量/标量直接传入 `encode(x = x_col)`——`aes()` 捕获的是表达式 `x_col`，eval_tidy 先查数据列，**若用户数据恰好含同名列则静默错位** | `R/mark.R:1004, 1011, 1076-1093, 924-953` | 实测：数据含 `x_col`/`y_col` 列时 `mark_lollipop` build **崩溃**（"Discrete value supplied to a continuous scale"）；无同名列时恰好依赖环境回退才正常——脆弱且不可预测 | **高** |
| D5 | **mark_network 复制 default_color 常量到 layer mapping → scale_color 失效**：plotit 注入的 `I("#4E79A7")` 被复制进 `node_mapping$colour`（layer 级），`scale_color` 的 `._clear_default_color` 只清 `plot@gg$mapping` 不清 layer → 后加 scale 节点颜色不变（单图 mark_point 无此问题，行为不一致） | `R/mark.R:1450-1456` | 实测：无 colour 映射时 node layer colour = `I("#4E79A7")`，加 `scale_color(range="viridis")` 后 build 通过但节点颜色仍恒为 `#4E79A7` | 中 |
| D6 | **mark_treemap 显式传 position_dodge 冗余**：自动 dodge 注入被 treemapify 内部覆盖为 `PositionIdentity`（无害但误导）；与 beeswarm 同源（R1） | `R/mark.R:1322-1330` | 实测 layer position = PositionIdentity，无警告 | 低 |

#### 5.2 已排除的疑点（防误修）

- **mark_treemap 警告**：误报——"There were 50 or more warnings" 噪声全部来自 F1 的 `load_all()` 警告（stderr 缓冲错位）；treemap build 无警告、position 正确解析为 PositionIdentity。
- **`split_wrap()` 无分面变量**：实测 OK（`vars()` 空被 ggplot2 4.0 容忍），无需处理。
- **`mark_text(repel=TRUE)` 正常路径**：有 label 映射时渲染 OK。
- **`scale_x(trans="discrete")` 连续变量**：不报错（离散化 32 个级别），属用户显式意图，非缺陷。
- **`scale_x(range=)+limits=` 冲突警告**：实测警告 "range takes precedence"，与 §3.3.4 约定一致，设计行为。

### 5. 根本原因分析与归类

> 26 项确认问题（前两轮 15 + A5 + B4 + C5 + 本轮 F1/D1-D6）可归为 **8 类根因**。归类是修复计划的基础——同一根因的问题应一次性修复，避免逐点打补丁。

| 根因 | 描述 | 涉及问题 | 证据（模式） |
|------|------|----------|--------------|
| **R1 手写 mark 绕过统一实现层** | 非 `._register_mark_method` 注册的 9 个手写 mark（sankey/chord/network/corr/map/beeswarm/treemap/significance/lollipop/dumbbell）各自实现 mapping 解析、position 解析、default_color 清除、@gg 构建，未共享 `._mark_impl` 的统一逻辑——同一类错误在不同 mark 重复出现 | A1/A3（不回落 mapping）、A4（@gg 替换）、B3/D6（dodge 注入不适用）、#4（density_2d 复制）、C2（flow.alpha 参数名错） | grep：`eval_tidy(mapping$...)` 10 处全部在无回落的手写 mark 中；`plot@gg <- gg` 5 处全在 sankey/chord/network |
| **R2 测试断言只验类名不验渲染** | 25+ 处 `expect_s3_class(p, "plotit::plotit")` 只断言类不断言渲染——空图、警告、构建错误全部漏检 | A5（sankey 空图虚过）、D1（hexbin 缺失未暴露）、D3（significance 警告未暴露）、#7（network skip） | grep：`expect_s3_class` 25+ 处，其中 mark 测试过半无 `ggplot_build` 断言 |
| **R3 可选依赖检查不一致** | 各可选依赖 mark 的 `requireNamespace` 检查有 11 处（sf/ggrepel/ggbeeswarm/ggraph/igraph/circlize/treemapify/ggrastr/mapproj），唯独 hexbin 遗漏；DESCRIPTION Suggests 亦缺 | D1 | 对比 `mark_hex` 与其余 mark 的依赖检查代码 |
| **R4 S7 方法注册签名不一致** | zzz.R 用 `function(plot, ...)` 注册 composite 拒绝方法，与泛型完整签名不匹配，S7 逐参数警告 | F1 | 实测 `load_all` 50 警告，消息格式 "doesn't have argument ..." |
| **R5 文档/示例与实现漂移** | roxygen 示例、AGENTS.md 约定表与实现脱节：示例 scheme 名不存在、§3.2 表 18 vs 实际 27、errorbar stat 承诺未实现、parallel "none" 描述过时 | D2、§3 偏离 6 项、A2（ggsankey×ggplot2 4.0 不兼容无版本约束） | 示例运行即报错（实测）；AGENTS.md 与源码对照 |
| **R6 复合 mark 值即表达式构造** | 复合 mark 把求值结果（值向量/标量）作为 `aes()` 表达式传入，违反 `encode()` 的"列名引用"语义：数据同名列静默遮蔽、标量触发长度警告 | D4（崩溃）、D3（警告）、C3（y_range 无 y 也计算）、#10（整数位 x 定位） | 实测 D4 崩溃；`encode(x = x_col)` 模式 10+ 处 |
| **R7 compose 生命周期缺失** | composite 组装只取 `@gg`，不触发子图 `._sync_labels()`，惰性标签在组装路径上丢失 | B1 | 实测 `label_axis` 后 compose 标签为 NULL |
| **R8 default_color 清除点不完整** | `._clear_default_color` 只覆盖全局 `plot@gg$mapping`，且调用点遗漏（corr/map fill/network layer 级复制） | B2、C1、D5 | 实测 `guides$guides$fill="none"` 残留、layer 常量残留 |

**根因层级关系**：R1 是最大根因（10 项问题）；R6 是 R1 手写 mark 内部的子模式，但因修复方式独立（`!!` 注入）单列；R8 是 R1 的 default_color 维度，因影响面横跨标准 mark（corr/map）单列。R2 是**过程性根因**——若测试断言到位，A2/A5/D1/D3 等问题在第一轮就该被发现，不会累积三轮。

### 6. 分阶段修复计划（按根因重组）

> 原则不变：**不改 API 设计**。修复按根因分批：每批完成后跑完整 testthat 套件回归，并对照本报告各问题项的验证点逐项确认。

#### 阶段 1（P0 阻断级：加载即见的错误 + 功能恢复）

| # | 根因 | 任务 | 文件 | 验证 |
|---|------|------|------|------|
| 1.1 | R4 | **F1**：zzz.R 循环注册时动态对齐方法签名（构造 `function(plot, ...)` 后 `formals(fun) <- formals(generic)`），消除 50 个 S7 警告 | `R/zzz.R:68-95` | `load_all()` 后 `warnings()` 计数为 0 |
| 1.2 | R1 | **mark_sankey**：`mapping %||% plot@gg$mapping` 回落；source/target 缺失 `cli_abort`；`flow_alpha` → `flow.alpha`；删 roxygen 重复标题 | `R/mark.R:1215-1221, 1254, 1257, 1154-1156` | 文档示例渲染行数 > 0 或定向报错；node 层 `aes_params$alpha` 为 NULL、flow 层为 `flow_alpha` |
| 1.3 | R1 | **mark_chord**：mapping 回落全局；保留旧 `from/to/value` 兼容分支 | `R/mark.R:1536-1558` | 文档示例与旧 API 均可用 |
| 1.4 | R1 | **mark_network**：首列 id 失败时定向 `cli_abort`（替代 igraph 原始错误） | `R/mark.R:1421-1423` | `test-mark.R:716` 匹配新消息 |
| 1.5 | R2 | **测试修复**：sankey 3 个测试改 edges-table API + 渲染行数断言（版本 guard）；network 2 个 skip 重写；chord 2 个按 1.3 更新 | `tests/testthat/test-mark.R:642-666, 704-726, 729-756` | 全套件 0 失败 |

#### 阶段 2（P1 一致性：行为修复）

| # | 根因 | 任务 | 文件 | 验证 |
|---|------|------|------|------|
| 2.1 | R8 | **default_color 清除点补全**：mark_corr 加 `._clear_default_color(plot)` + `use="pairwise.complete.obs"`；mark_map 的 fill 分支补齐；mark_network 不再复制常量进 layer（或清除 layer 常量） | `R/mark.R:761, 774, 357-359, 1450-1456` | B2/C1/D5 场景图例与 scale 生效 |
| 2.2 | R7 | **compose 子图同步**：`._assemble_plots` 组装前对子图 `._sync_labels()` | `R/compose.R:46-48` | B1 场景标签生效 |
| 2.3 | R1 | **mark_beeswarm 跳过自动 dodge**（position 强制 NULL）；mark_treemap 同步处理（D6） | `R/mark.R:1147-1150, 1322-1330` | 无 position 警告 |
| 2.4 | R3 | **mark_hex**：`requireNamespace("hexbin")` 定向检查 + DESCRIPTION Suggests 补 hexbin | `R/mark.R:647-657` + `DESCRIPTION` | 未装 hexbin 时定向报错 |
| 2.5 | R5 | **示例与约定同步**：sankey/network 示例 scheme 改合法值（viridis/brewer）；AGENTS.md §3.2 表 18→27、§3.3b errorbar stat 承诺（实现或删文档）、§3.3.5 parallel 去 `geom_vline` 字样、§9.2/§9.4 状态、§3.2 关系 mark API 描述补注；DESCRIPTION 增 ggsankey×ggplot2 兼容性说明（A2） | `R/mark.R:1193, 1381` + `AGENTS.md` + `DESCRIPTION` | 示例可运行；约定与实现一致 |
| 2.6 | R6 | **mark_significance/mark_dumbbell 防御**：y 映射缺失跳过 y_range（C3）；缺 yend 定向报错（C4） | `R/mark.R:901-904, 1074` | 无 min/max 警告；定向错误 |

#### 阶段 3（P2 收尾：防御性、架构级、代码卫生）

| # | 根因 | 任务 | 文件 | 验证 |
|---|------|------|------|------|
| 3.1 | R6 | **复合 mark 值即表达式重构**：`encode(x = x_col)` → `encode(x = !!x_col)`（或构造含值的 data.frame 传入），消除同名列遮蔽（D4）与标量警告（D3） | `R/mark.R:1004, 1011, 1076-1093, 924-953` | D4 崩溃场景修复；无长度警告 |
| 3.2 | R1 | **mark_density_2d 复用 `._mark_impl`** | `R/mark.R:692-716` | 行为不变代码去重 |
| 3.3 | R1 | **架构级：`@gg` 替换重构**——mark_sankey/mark_network 改为在 `plot@gg` 上增量 `+ layer`（继承主题/层/scale）；mark_chord 用 `annotation_custom`+`grid.grab` 封装或文档化"原生渲染器"定位 | `R/mark.R:1268, 1468, 1582` | A4 场景保留默认主题与先前层 |
| 3.4 | 杂项 | mark_lollipop：新增可选参数 `ref = 0` + 删除死代码 `fill_val` | `R/mark.R:1004, 1013-1017` | 负值数据可设 ref；无死代码 |
| 3.5 | 杂项 | mark_errorbar：`rasterize` 参数与 §3.3b 对齐（删参数或改约定，与 2.5 联动） | `R/mark.R:812` | 与约定一致 |
| 3.6 | 杂项 | make_theme：文档化分配位置；`assign` 前检查目标环境可写 | `R/factory.R:80` | 函数内调用不丢变量 |
| 3.7 | 杂项 | mark_chord：`f_rhs`+`eval_tidy` 改为与 sankey 一致的 `eval_tidy(quosure, edges)`（C5） | `R/mark.R:1537-1539, 1571` | 风格统一 |
| 3.8 | 杂项 | 全库 `@`/`S7::prop()` 统一为 `prop()`（#12） | 多处 | grep 无混用 |
| 3.9 | 杂项 | `._sync_labels` legend patchwork 分支完善：用公共 API 处理 text 设置（#13） | `R/label.R:171-179` | 行为等价、不读内部 `$plots` |
| 3.10 | 杂项 | theme_managed 绕过路径兜底（#14） | `R/output.R:62-64` | 直接改 theme 不丢默认主题 |
| 3.11 | 杂项 | project_parallel：报错列出实际冲突列名（#15） | `R/project.R:408-412` | 报错含冲突列 |
| 3.12 | 杂项 | 清理垃圾文件 `Rplots.pdf`（根目录 + `tests/testthat/`），检查 `.Rbuildignore`（已于 2026-08-10 完成） | 仓库 | 无残留 |

**执行顺序与回归方式**：阶段 1 完成后立即跑完整 testthat（目标：0 失败、无 sankey/beeswarm 警告）；阶段 2 逐项验证后回归；阶段 3 为低风险收尾，可与文档同步并行。每阶段结束执行 `roxygen2::roxygenize()` 并核对 NAMESPACE/man 变更（§1.5）。临时核验脚本已于审查结束后按约定（AGENTS.md §1.7）清理；修复时按本报告各表"验证"列执行，并以完整 testthat 套件（目标 0 失败、0 警告噪声）为准。
