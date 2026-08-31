# Gallery System: Pipeline Chains (v2)

> **本页解决什么问题**：按**意图**索引的 usage 管道链——每个 API
> 一族最小可运行管道 （参考 tidyplots
> 风格：`data |> plotit(encode(...)) |> mark_*(...)`）。只给管道链，
> 不渲染图；数据全部取自内置数据集，确保确定性（seed 固定）、单链 \<5s。
> **前置**：[API System
> Reference](https://zorrooz.github.io/plotit/articles/api-system.md)。
> **下一步**：→ [Transform
> Recipes](https://zorrooz.github.io/plotit/articles/transform-recipes.md)。

## 0 数据集适配表

| 数据集 | 类型 | 适合族 |
|:---|:---|:---|
| `iris` | 150×4 数值 + 3 类 | 分布/矩阵/相关性/平行坐标/注释 |
| `mtcars` | 32×11 数值 | 比较/关系/森林图 |
| [`ggplot2::mpg`](https://ggplot2.tidyverse.org/reference/mpg.html) | 234 行分类+连续 | 比较/关系/分面/热力 |
| [`ggplot2::diamonds`](https://ggplot2.tidyverse.org/reference/diamonds.html) | 53940 行 | 2D 分箱/六边形/密度 |
| [`ggplot2::economics`](https://ggplot2.tidyverse.org/reference/economics.html) | 574 行日期序列 | 趋势/面积/step |
| [`ggplot2::economics_long`](https://ggplot2.tidyverse.org/reference/economics.html) | 日期×变量长表 | 堆叠面积 |
| `Orange` | 5 树×7 观测 | 增长曲线/step/趋势 |
| `ToothGrowth` | 60 行 2 因子 | 比较/箱线/小提琴 |
| `faithful` | 272 行 2 数值 | 直方/密度/2D |
| `chickwts` | 71 行 6 组 | 比较/箱线 |
| `PlantGrowth` | 30 行 3 组 | 比较/显著性 |
| `airquality` | 153 行 | 关系/平滑/分面 |
| [`ggplot2::txhousing`](https://ggplot2.tidyverse.org/reference/txhousing.html) | 8602 行城市×月 | 趋势/分面 |

## 1 入门与语法

``` r

# 最小管道：初始化 + 一个 mark
iris |> plotit(encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()

# 逃生舱：追加原生 ggplot2 层
iris |> plotit(encode(x = Sepal.Width, y = Sepal.Length)) |>
  mark_point() |> add_ggplot(ggplot2::geom_smooth(method = "lm", se = FALSE))
```

## 2 比较（comparisons）

``` r

# 分组箱线
ToothGrowth |> plotit(encode(x = supp, y = len)) |> mark_boxplot()
# 带 fill 分组的小提琴
ToothGrowth |> plotit(encode(x = supp, y = len, fill = supp)) |> mark_violin()
# 蜂群散点
iris |> plotit(encode(x = Species, y = Sepal.Length)) |> mark_beeswarm()
# 棒棒糖（排序值）
mtcars |> plotit(encode(x = reorder(rownames(mtcars), mpg), y = mpg)) |> mark_lollipop()
# 哑铃对比（前后两值）
ggplot2::mpg |> plotit(encode(x = class, y = cty, yend = hwy)) |> mark_dumbbell()
# 森林图：效应量 + 95%CI + 参考线
mtcars |> plotit(encode(x = mpg, y = names(mtcars), xmin = mpg - 2, xmax = mpg + 2)) |> mark_forest(ref = 18)
# 误差棒：分组均值 ± SD
ToothGrowth |> plotit(encode(x = supp, y = len, colour = dose)) |> mark_errorbar(stat = "mean_sd")
# 计数散点（重叠感知）
diamonds_sample |> plotit(encode(x = depth, y = table)) |> mark_count()

# 显著性括号
PlantGrowth |> plotit(encode(x = group, y = weight)) |> mark_boxplot() |>
  mark_significance(comparisons = data.frame(group1 = "ctrl", group2 = "trt1", label = "*"),
                    y_position = 7)
```

## 3 分布（distributions）

``` r

# 直方图（显式 bins，避免 stat_bin 提示）
faithful |> plotit(encode(x = eruptions)) |> mark_histogram(bins = 25)
# 密度曲线
faithful |> plotit(encode(x = eruptions)) |> mark_density()
# 经验累积分布
faithful |> plotit(encode(x = eruptions)) |> mark_ecdf()
# QQ 诊断
data.frame(v = rnorm(200)) |> plotit(encode(x = v)) |> mark_qq()
faithful |> plotit(encode(x = eruptions)) |> mark_qq()
# 一维地毯
iris |> plotit(encode(x = Sepal.Length)) |> mark_rug(sides = "b")
# 分组直方（叠层）
iris |> plotit(encode(x = Sepal.Length, fill = Species)) |>
  mark_histogram(bins = 20, alpha = 0.5)
```

## 4 关系（relationships）

``` r

# 散点 + 回归平滑 + 置信带
airquality |> plotit(encode(x = Temp, y = Ozone)) |> mark_point() |> mark_smooth()
# 分组离散线
ggplot2::mpg |> plotit(encode(x = displ, y = hwy, colour = class)) |> mark_point()
# 2D 六边形分箱（binned 断点，T5.5）
ggplot2::diamonds |> plotit(encode(x = carat, y = price)) |> mark_hex(bins = 20)
# 矩形 2D 分箱
ggplot2::diamonds |> plotit(encode(x = carat, y = price)) |> mark_bin2d(bins = 20)
# 2D 密度等高线
faithful |> plotit(encode(x = eruptions, y = waiting)) |> mark_density_2d(filled = TRUE)
# 观测标量场等高线
volcano |> as.data.frame() |> plotit(encode(x = row(volcano), y = col(volcano), z = value)) |>
  mark_contour()
```

## 5 趋势（trends）

``` r

# 日期折线（Date 列自动走日期轴）
ggplot2::economics |> plotit(encode(x = date, y = unemploy)) |> mark_line()
# 面积
ggplot2::economics |> plotit(encode(x = date, y = psavert)) |> mark_area(alpha = 0.6)
# 阶梯线
Orange |> plotit(encode(x = age, y = circumference, group = Tree)) |> mark_step()
# 置信带（ribbon）
ggplot2::economics |> plotit(encode(x = date, y = unemploy, ymin = unemploy - 200, ymax = unemploy + 200)) |>
  mark_ribbon()
# 多序列对比
ggplot2::economics_long |> plotit(encode(x = date, y = value, colour = variable)) |> mark_line()
```

## 6 坐标（coordinates）

``` r

# 翻转
iris |> plotit(encode(x = Species, y = Sepal.Length, fill = Species)) |> mark_boxplot() |> project_cartesian(flip = TRUE)
# 固定纵横比
data.frame(x = rnorm(120), y = rnorm(120)) |> plotit(encode(x = x, y = y)) |> mark_point() |>
  project_cartesian(fixed = 1)
# 缩放不丢数据
mtcars |> plotit(encode(x = wt, y = mpg)) |> mark_point() |> project_cartesian(xlim = c(2, 4))
# 饼/环/玫瑰（组合优先，非新 mark）
data.frame(seg = c("A","B","C"), val = c(45,30,25)) |>
  plotit(encode(x = 1, y = val, fill = seg)) |> mark_bar(width = 1) |> project_polar(theta = "y")
data.frame(seg = c("A","B","C"), val = c(45,30,25)) |>
  plotit(encode(x = 1, y = val, fill = seg)) |> mark_bar(width = 1) |>
  project_polar(theta = "y", inner_radius = 0.4)
data.frame(day = c("Mon","Tue","Wed"), v = c(12,19,15)) |>
  plotit(encode(x = day, y = v, fill = day)) |> mark_bar(width = 0.9) |> project_polar()
# 圆形直方
data.frame(a = rnorm(200)) |> plotit(encode(x = a)) |> mark_histogram(bins = 24) |> project_polar(theta = "x")
# 平行坐标（std 模式，低 alpha）
iris |> plotit(encode()) |>
  project_parallel(columns = c("Sepal.Length","Sepal.Width","Petal.Length","Petal.Width"), group = "Species")
```

## 7 占比（proportions）

``` r

# 堆叠柱（fill 分组）
ggplot2::mpg |> plotit(encode(x = class, fill = drv)) |> mark_bar()
# 百分比占比（fill 归一）
ggplot2::mpg |> plotit(encode(x = class, fill = drv)) |> mark_bar(position = "fill")
# 极坐标占比（饼/环）见 §6
```

## 8 矩阵（matrix）

``` r

# 相关性矩阵（默认发散 rdbu，T5.1）
plotit(mtcars, encode()) |> mark_corr()
# 矩阵热图：行聚类 + z-score
mat |> plotit(encode()) |> mark_heatmap(cluster = "both", scale = "row")
# RdBu 发散热图
mat |> plotit(encode()) |> mark_heatmap(scale = "row", range = "RdBu")
# 旗舰：热图 + 树条 + 注释（compose_annot）
h <- hclust(dist(mat))
hm <- plotit(mat, encode()) |> mark_heatmap(cluster = h)
tree <- as_graph(h) |> plotit() |> layout_dendrogram(direction = "up") |> mark_rule(data = ~edges)
hm |> compose_annot(top = tree)
```

## 9 地理（geo）

``` r

# 若 sf 可用：县级面 + 数值填充
nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
nc |> plotit(encode(geometry = geometry, fill = BIR74)) |> mark_map() |> project_map()
```

## 10 注释（annotations）

``` r

# 文本标签
lab_df |> plotit(encode(x = x, y = y, label = label)) |> mark_text(repel = TRUE)
lab_df |> plotit(encode(x = x, y = y, label = label)) |> mark_label(repel = TRUE)
# 参考线
volc_df |> plotit(encode(x = lfc, y = p)) |> mark_point() |>
  mark_rule(xintercept = c(-1, 1)) |> mark_rule(yintercept = 2)
# 数据段（箭头/连接）
df |> plotit(encode(x = x, y = y)) |> mark_rule(data = segs, mapping = encode(x = x, y = y, xend = xend, yend = yend))
# 圈注簇
iris |> plotit(encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |> mark_point() |> mark_encircle()
# 图像点/ISOTYPE
df_img |> plotit(encode(x = x, y = y)) |> mark_image(src = "icon.png", size = 2)
```

## 11 组合（composing）

``` r

p1 <- iris |> plotit(encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point(alpha = 0.5)
p2 <- iris |> plotit(encode(x = Species, y = Sepal.Length)) |> mark_boxplot()
compose_grid(p1, p2, ncol = 2)
compose_grid(p1, p2, ncol = 2, guides = "keep")
# 边际分布
main <- iris |> plotit(encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |> mark_point()
top <- iris |> plotit(encode(x = Sepal.Width, fill = Species)) |> mark_histogram(bins = 15, alpha = 0.5)
right <- iris |> plotit(encode(x = Sepal.Length, fill = Species)) |> mark_histogram(bins = 15, alpha = 0.5) |> project_cartesian(flip = TRUE)
compose_marginal(main, top, right)
# 嵌套 inset
compose_inset(p1, p2, left = 0.6, bottom = 0.6, right = 0.95, top = 0.95)
```

## 12 分面（split）

``` r

# wrap
ggplot2::mpg |> plotit(encode(x = displ, y = hwy)) |> mark_point(alpha = 0.4) |> split_wrap(drv, ncol = 3)
# grid 公式（T11.1）
ggplot2::mpg |> plotit(encode(x = displ, y = hwy)) |> mark_point(alpha = 0.4) |> split_grid(drv ~ cyl)
# 自由刻度
ggplot2::mpg |> plotit(encode(x = displ, y = hwy)) |> mark_point(alpha = 0.4) |> split_wrap(drv, scales = "free")
```

## 13 缩放与调色板（scale）

``` r

# 连续色板 + log 轴 + 气泡尺寸
mtcars |> plotit(encode(x = wt, y = mpg, colour = hp, size = hp)) |> mark_point() |>
  scale_color(range = "viridis") |> scale_x(trans = "log10") |> scale_size(range = c(1, 9))
# 定性离散（friendly 默认；brewer 可换）
iris |> plotit(encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |> mark_point() |> scale_color(range = "brewer")
# 发散色板（mid=0）
mtcars |> plotit(encode(x = wt, y = mpg, colour = hp)) |> mark_point() |> scale_color(range = "rdbu", mid = 0)
# binned 连续
iris |> plotit(encode(x = Sepal.Width, y = Sepal.Length, colour = Sepal.Length)) |> mark_point() |> scale_color(trans = "binned", n_bins = 5)
# 形状/线型离散
ggplot2::mpg |> plotit(encode(x = displ, y = hwy, shape = drv)) |> mark_point() |> scale_shape(range = c(16, 17, 18))
# 日期轴（自动）
ggplot2::economics |> plotit(encode(x = date, y = unemploy)) |> mark_line()
```

## 14 关系图表（relational）

``` r

# 桑基（edges 表）
flows |> plotit(encode(source = source, target = target, value = value, fill = source)) |> mark_sankey()
# 显式布局管道
as_graph(flows) |> plotit() |> layout_sankey() |> mark_polygon(data = ~ribbons) |> mark_rect(data = ~nodes)
# 矩形树图
tree_df |> plotit(encode(fill = id)) |> mark_treemap()
# 力导向网络
nodes |> plotit(encode(colour = type, label = id)) |> mark_network(edges = edges, seed = 4)
# 弦图
mat2 |> plotit(encode(fill = Var1)) |> mark_chord()
# 树/系统树
as_graph(hclust(dist(iris[, 1:4]))) |> plotit() |> layout_dendrogram(direction = "down") |>
  mark_rule(data = ~edges) |> mark_point(data = ~nodes)
```

## 15 标签、主题、导出、扩展

``` r

# 完整装饰管道
iris |> plotit(encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |> mark_point() |>
  label_title("Iris Sepal Dimensions") |> label_subtitle("Fisher's iris") |>
  label_axis("Sepal width (cm)", aes = "x") |> label_axis("Sepal length (cm)", aes = "y") |>
  label_legend("Species", aes = "colour") |> label_caption("Data: Anderson (1935)")
# 主题
iris |> plotit(encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point() |> style(base_size = 12)
iris |> plotit(encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |> mark_point() |>
  style(base_theme = ggplot2::theme_minimal(12), legend.position = "bottom")
# 导出
p |> export("figure.png", width = 8, height = 5, dpi = 300)
# 自定义 mark / 主题
make_mark("mark_spoke", ggplot2::geom_spoke)
style_dark <- make_theme("style_dark", plot.background = ggplot2::element_rect(fill = "#1a1a1a"),
  text = ggplot2::element_text(colour = "white"))
```

## 下一步

→ [Transform
Recipes](https://zorrooz.github.io/plotit/articles/transform-recipes.md)：管道前的数据整形；
→ [Use Case:
Bioinformatics](https://zorrooz.github.io/plotit/articles/use-case-bioinformatics.md)
/
[Publishing](https://zorrooz.github.io/plotit/articles/use-case-publishing.md)。
