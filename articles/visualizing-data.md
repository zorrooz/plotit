# Visualizing Data

This gallery is organised by **intent**, not by function name. Find the
chart you need, copy the pipeline, adapt the aesthetics. Function-level
parameters live in
[Reference](https://zorrooz.github.io/plotit/reference/index.md);
grammar depth lives in
[API](https://zorrooz.github.io/plotit/articles/api.md).

## Comparing groups

### Counts by category

Map only `x` and
[`mark_bar()`](https://zorrooz.github.io/plotit/reference/mark_bar.md)
counts rows per category.

``` r

ggplot2::mpg |>
  plotit(encode(x = class)) |>
  mark_bar()
```

![](visualizing-data_files/figure-html/unnamed-chunk-2-1.png)

### Value bars and stacks

Map `y` for direct values. A second categorical to `fill` stacks
composition.

``` r

ggplot2::mpg |>
  plotit(encode(x = class, fill = drv)) |>
  mark_bar(position = "stack")
```

![](visualizing-data_files/figure-html/unnamed-chunk-3-1.png)

### Filled (100%) bars

``` r

ggplot2::mpg |>
  plotit(encode(x = class, fill = drv)) |>
  mark_bar(position = "fill")
```

![](visualizing-data_files/figure-html/unnamed-chunk-4-1.png)

### Boxplot and beeswarm

``` r

ToothGrowth |>
  plotit(encode(x = supp, y = len, fill = supp)) |>
  mark_boxplot()
```

![](visualizing-data_files/figure-html/unnamed-chunk-5-1.png)

``` r

iris |>
  plotit(encode(x = Species, y = Sepal.Length)) |>
  mark_beeswarm()
```

![](visualizing-data_files/figure-html/unnamed-chunk-6-1.png)

### Violin

``` r

ToothGrowth |>
  plotit(encode(x = supp, y = len, fill = supp)) |>
  mark_violin()
```

![](visualizing-data_files/figure-html/unnamed-chunk-7-1.png)

### Lollipop and dumbbell

``` r

mtcars |>
  plotit(encode(x = reorder(rownames(mtcars), mpg), y = mpg)) |>
  mark_lollipop() |>
  project_cartesian(flip = TRUE)
```

![](visualizing-data_files/figure-html/unnamed-chunk-8-1.png)

``` r

mpg_mean <- aggregate(cbind(cty, hwy) ~ class, data = ggplot2::mpg, FUN = mean)
mpg_mean |>
  plotit(encode(x = class, y = cty, yend = hwy)) |>
  mark_dumbbell()
```

![](visualizing-data_files/figure-html/unnamed-chunk-9-1.png)

### Forest plot

``` r

est <- data.frame(
  study = paste0("s", 1:5),
  est = c(0.9, 1.1, 0.8, 1.2, 1.0),
  lo = c(0.4, 0.7, 0.5, 0.9, 0.7),
  hi = c(1.6, 1.8, 1.3, 1.9, 1.4)
)
est |>
  plotit(encode(y = study, x = est, xmin = lo, xmax = hi)) |>
  mark_forest(ref = 1)
```

![](visualizing-data_files/figure-html/unnamed-chunk-10-1.png)

### Error bars and significance

``` r

ToothGrowth |>
  plotit(encode(x = supp, y = len, colour = dose)) |>
  mark_errorbar(stat = "mean_sd", width = 0.4)
```

![](visualizing-data_files/figure-html/unnamed-chunk-11-1.png)

``` r

set.seed(7)
d <- data.frame(
  g = rep(c("ctrl", "A", "B"), each = 20),
  v = rnorm(60, rep(c(0, 0.8, 1.6), each = 20))
)
d |>
  plotit(encode(x = g, y = v)) |>
  mark_boxplot() |>
  mark_significance(comparisons = data.frame(
    group1 = c("ctrl", "ctrl", "A"),
    group2 = c("A", "B", "B"),
    label = c("*", "***", "ns")
  ))
```

![](visualizing-data_files/figure-html/unnamed-chunk-12-1.png)

## Distributions

### Histogram and density

``` r

faithful |>
  plotit(encode(x = eruptions)) |>
  mark_histogram(bins = 30)
```

![](visualizing-data_files/figure-html/unnamed-chunk-13-1.png)

``` r

iris |>
  plotit(encode(x = Sepal.Length, colour = Species)) |>
  mark_density()
```

![](visualizing-data_files/figure-html/unnamed-chunk-14-1.png)

### Histogram + density overlay

``` r

faithful |>
  plotit(encode(x = eruptions)) |>
  mark_histogram(mapping = encode(y = ggplot2::after_stat(density)), bins = 30, alpha = 0.5) |>
  mark_density(bw = 0.15)
```

![](visualizing-data_files/figure-html/unnamed-chunk-15-1.png)

### ECDF and QQ

``` r

faithful |>
  plotit(encode(x = eruptions)) |>
  mark_ecdf()
```

![](visualizing-data_files/figure-html/unnamed-chunk-16-1.png)

``` r

faithful |>
  plotit(encode(x = eruptions)) |>
  mark_qq() |>
  mark_qq_line()
```

![](visualizing-data_files/figure-html/unnamed-chunk-17-1.png)

### Bivariate density and binning

``` r

faithful |>
  plotit(encode(x = eruptions, y = waiting)) |>
  mark_density_2d(filled = TRUE, bins = 10)
```

![](visualizing-data_files/figure-html/unnamed-chunk-18-1.png)

``` r

dmid <- ggplot2::diamonds[ggplot2::diamonds$carat < 2, ]
dmid |>
  plotit(encode(x = carat, y = price)) |>
  mark_hex(bins = 30)
```

![](visualizing-data_files/figure-html/unnamed-chunk-19-1.png)

``` r

dmid |>
  plotit(encode(x = carat, y = price)) |>
  mark_bin2d(bins = 20)
```

![](visualizing-data_files/figure-html/unnamed-chunk-20-1.png)

### Rug ticks

``` r

faithful |>
  plotit(encode(x = eruptions)) |>
  mark_density() |>
  mark_rug(sides = "b", colour = "grey30")
```

![](visualizing-data_files/figure-html/unnamed-chunk-21-1.png)

## Relationships

### Scatter + smooth

``` r

airquality |>
  plotit(encode(x = Temp, y = Ozone)) |>
  mark_point(alpha = 0.6) |>
  mark_smooth()
#> `geom_smooth()` using method = 'loess' and formula = 'y ~ x'
#> Warning: Removed 37 rows containing non-finite outside the scale range
#> (`stat_smooth()`).
#> Warning: Removed 37 rows containing missing values or values outside the scale range
#> (`geom_point()`).
```

![](visualizing-data_files/figure-html/unnamed-chunk-22-1.png)

### Grouped scatter

``` r

ggplot2::mpg |>
  plotit(encode(x = displ, y = hwy, colour = class)) |>
  mark_point(alpha = 0.7)
```

![](visualizing-data_files/figure-html/unnamed-chunk-23-1.png)

### Correlation matrix

``` r

plotit(stats::cor(iris[1:4])) |>
  mark_corr()
```

![](visualizing-data_files/figure-html/unnamed-chunk-24-1.png)

### Contour of a scalar field

``` r

volcano_df <- as.data.frame(as.table(volcano))
names(volcano_df) <- c("r", "c", "z")
volcano_df |>
  plotit(encode(x = as.numeric(r), y = as.numeric(c), z = z)) |>
  mark_contour(bins = 12)
```

![](visualizing-data_files/figure-html/unnamed-chunk-25-1.png)

## Trends

### Line and step

``` r

ggplot2::economics |>
  plotit(encode(x = date, y = unemploy)) |>
  mark_line()
```

![](visualizing-data_files/figure-html/unnamed-chunk-26-1.png)

``` r

ggplot2::economics |>
  plotit(encode(x = date, y = psavert)) |>
  mark_step(direction = "hv")
```

![](visualizing-data_files/figure-html/unnamed-chunk-27-1.png)

### Area, ribbon, stacked area

``` r

ggplot2::economics |>
  plotit(encode(x = date, y = psavert)) |>
  mark_area()
```

![](visualizing-data_files/figure-html/unnamed-chunk-28-1.png)

``` r

set.seed(7)
d <- data.frame(
  x = 1:20,
  y = cumsum(rnorm(20)),
  lo = 1:20 - 1.96,
  hi = 1:20 + 1.96
)
d |>
  plotit(encode(x = x, y = y)) |>
  mark_line() |>
  mark_ribbon(mapping = encode(ymin = lo, ymax = hi))
```

![](visualizing-data_files/figure-html/unnamed-chunk-29-1.png)

``` r

set.seed(7)
df <- expand.grid(t = 1:12, g = letters[1:4])
df$v <- rpois(nrow(df), 5)
df |>
  plotit(encode(x = t, y = v, fill = g)) |>
  mark_area(position = "stack")
```

![](visualizing-data_files/figure-html/unnamed-chunk-30-1.png)

### Slope chart (recipe)

``` r

sl <- data.frame(
  p = rep(c("before", "after"), each = 3),
  g = rep(letters[1:3], 2),
  v = c(3, 2, 1, 1.5, 2.5, 3)
)
sl |>
  plotit(encode(x = p, y = v, group = g, colour = g)) |>
  mark_line() |>
  mark_point()
```

![](visualizing-data_files/figure-html/unnamed-chunk-31-1.png)

## Proportions

All proportion charts are recipes: `mark_bar` + `project_polar`.

### Pie and donut

``` r

d <- data.frame(cat = c("A", "B", "C"), n = c(40, 35, 25))
d |>
  plotit(encode(x = 1, y = n, fill = cat)) |>
  mark_bar(position = "stack", width = 1) |>
  project_polar(theta = "y")
```

![](visualizing-data_files/figure-html/unnamed-chunk-32-1.png)

``` r

d |>
  plotit(encode(x = 1, y = n, fill = cat)) |>
  mark_bar(position = "stack", width = 1) |>
  project_polar(theta = "y", inner_radius = 0.4)
```

![](visualizing-data_files/figure-html/unnamed-chunk-33-1.png)

### Rose / Nightingale

``` r

d |>
  plotit(encode(x = cat, y = n, fill = cat)) |>
  mark_bar(width = 1) |>
  project_polar()
```

![](visualizing-data_files/figure-html/unnamed-chunk-34-1.png)

### Radar (recipe)

Precompute polar coordinates, then draw polygons in Cartesian space.

``` r

set.seed(7)
lv <- 4
rd <- data.frame(
  variable = rep(letters[1:lv], 2),
  person = rep(c("p1", "p2"), each = lv),
  value = runif(lv * 2, 4, 9)
)
rd$theta <- (as.numeric(factor(rd$variable)) - 1) / lv * 2 * pi
rd$px <- rd$value * sin(rd$theta)
rd$py <- rd$value * cos(rd$theta)
rd |>
  plotit(encode(x = px, y = py, group = person, colour = person), dodge = 0) |>
  mark_polygon(alpha = 0.2) |>
  project_cartesian(fixed = 1)
```

![](visualizing-data_files/figure-html/unnamed-chunk-35-1.png)

## Coordinates

### Flip, zoom, fixed aspect

``` r

iris |>
  plotit(encode(x = Species, y = Sepal.Length, fill = Species)) |>
  mark_boxplot() |>
  project_cartesian(flip = TRUE)
```

![](visualizing-data_files/figure-html/unnamed-chunk-36-1.png)

``` r

mtcars |>
  plotit(encode(x = wt, y = mpg)) |>
  mark_point() |>
  project_cartesian(xlim = c(2, 4), ylim = c(15, 25))
```

![](visualizing-data_files/figure-html/unnamed-chunk-37-1.png)

``` r

data.frame(x = rnorm(80), y = rnorm(80)) |>
  plotit(encode(x = x, y = y)) |>
  mark_point() |>
  project_cartesian(fixed = 1)
```

![](visualizing-data_files/figure-html/unnamed-chunk-38-1.png)

### Parallel coordinates

``` r

iris |>
  plotit(encode()) |>
  project_parallel(
    columns = c("Sepal.Length", "Sepal.Width", "Petal.Length", "Petal.Width"),
    group = "Species"
  )
```

![](visualizing-data_files/figure-html/unnamed-chunk-39-1.png)

### Facets

``` r

ggplot2::mpg |>
  plotit(encode(x = displ, y = hwy)) |>
  mark_point(alpha = 0.4) |>
  split_wrap(drv, ncol = 3)
```

![](visualizing-data_files/figure-html/unnamed-chunk-40-1.png)

``` r

ggplot2::mpg |>
  plotit(encode(x = displ, y = hwy)) |>
  mark_point(alpha = 0.4) |>
  split_grid(drv ~ cyl)
```

![](visualizing-data_files/figure-html/unnamed-chunk-41-1.png)

## Matrix heatmaps

### From long data

``` r

set.seed(7)
d <- expand.grid(r = paste0("r", 1:6), c = paste0("c", 1:6))
d$v <- rnorm(nrow(d))
d |>
  plotit(encode(x = c, y = r, fill = v)) |>
  mark_rect() |>
  scale_fill(mid = 0, range = "rdbu")
#> Scale for fill is already present.
#> Adding another scale for fill, which will replace the existing scale.
```

![](visualizing-data_files/figure-html/unnamed-chunk-42-1.png)

### From a matrix, clustered

``` r

set.seed(7)
mat <- matrix(rnorm(48), nrow = 6, dimnames = list(paste0("g", 1:6), paste0("s", 1:8)))
h <- stats::hclust(stats::dist(mat))
plotit(mat, encode()) |>
  mark_heatmap(cluster = h, show_numbers = TRUE, number_format = "%.1f")
```

![](visualizing-data_files/figure-html/unnamed-chunk-43-1.png)

### Heatmap + dendrogram (compose_annot)

``` r

hm <- plotit(mat, encode()) |> mark_heatmap(cluster = h)
tree <- as_graph(h) |>
  plotit() |>
  layout_dendrogram(direction = "up") |>
  mark_rule(data = ~edges)
hm |> compose_annot(top = tree)
```

![](visualizing-data_files/figure-html/unnamed-chunk-44-1.png)

## Geography

Requires **sf**.

``` r

if (requireNamespace("sf", quietly = TRUE)) {
  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
  nc |>
    plotit(encode(fill = AREA)) |>
    mark_map() |>
    scale_fill(range = "viridis") |>
    project_map()
}
#> Scale for fill is already present.
#> Adding another scale for fill, which will replace the existing scale.
```

![](visualizing-data_files/figure-html/unnamed-chunk-45-1.png)

## Networks and flows

### Sankey

``` r

flows <- data.frame(
  source = c("A", "A", "B", "B", "C"),
  target = c("B", "C", "C", "D", "D"),
  value = c(10, 5, 8, 3, 6)
)
flows |>
  plotit(encode(source = source, target = target, value = value, fill = source)) |>
  mark_sankey()
#> Coordinate system already present.
#> ℹ Adding new coordinate system, which will replace the existing one.
```

![](visualizing-data_files/figure-html/unnamed-chunk-46-1.png)

### Treemap

``` r

tree_df <- data.frame(
  id = c("root", "a", "b", "a1", "a2", "b1"),
  parent = c(NA, "root", "root", "a", "a", "b"),
  value = c(NA, NA, NA, 30, 20, 50)
)
tree_df |>
  plotit(encode(fill = id)) |>
  mark_treemap()
```

![](visualizing-data_files/figure-html/unnamed-chunk-47-1.png)

### Network

``` r

nodes <- data.frame(id = c("a", "b", "c", "d"), type = c("x", "y", "x", "y"))
edges <- data.frame(source = c("a", "a", "b", "c"), target = c("b", "c", "c", "d"))
nodes |>
  plotit(encode(colour = type, label = id)) |>
  mark_network(edges = edges, seed = 4)
```

![](visualizing-data_files/figure-html/unnamed-chunk-48-1.png)

### Chord

``` r

m <- matrix(c(0, 5, 2, 3, 5, 0, 4, 1, 2, 4, 0, 6, 3, 1, 6, 0), 4,
  dimnames = list(letters[1:4], letters[1:4])
)
as_graph(m) |>
  plotit() |>
  layout_chord() |>
  mark_polygon(data = ~ribbons) |>
  mark_polygon(data = ~arcs)
```

![](visualizing-data_files/figure-html/unnamed-chunk-49-1.png)

### Tree / dendrogram

``` r

as_graph(hclust(dist(iris[, 1:4]))) |>
  plotit() |>
  layout_dendrogram(direction = "down") |>
  mark_rule(data = ~edges) |>
  mark_point(data = ~nodes)
```

![](visualizing-data_files/figure-html/unnamed-chunk-50-1.png)

## Annotations

### Reference lines, labels, encircle

``` r

ggplot2::mpg |>
  plotit(encode(x = displ, y = hwy)) |>
  mark_point(alpha = 0.5) |>
  mark_rule(yintercept = 25, colour = "#E15759")
```

![](visualizing-data_files/figure-html/unnamed-chunk-51-1.png)

``` r

set.seed(7)
pts <- data.frame(
  x = rnorm(60), y = rnorm(60),
  g = rep(letters[1:3], each = 20)
)
pts |>
  plotit(encode(x = x, y = y, colour = g)) |>
  mark_point(alpha = 0.6) |>
  mark_encircle(shape = "hull", expand = 0.02)
```

![](visualizing-data_files/figure-html/unnamed-chunk-52-1.png)

``` r

lab <- data.frame(x = c(1, 2, 3), y = c(3, 1, 2), label = c("peak", "dip", "mid"))
lab |>
  plotit(encode(x = x, y = y, label = label)) |>
  mark_point() |>
  mark_text(repel = TRUE)
```

![](visualizing-data_files/figure-html/unnamed-chunk-53-1.png)

## Colour scales

``` r

mtcars |>
  plotit(encode(x = wt, y = mpg, colour = hp, size = hp)) |>
  mark_point() |>
  scale_color(range = "viridis") |>
  scale_size(range = c(1, 9))
#> Scale for colour is already present.
#> Adding another scale for colour, which will replace the existing scale.
```

![](visualizing-data_files/figure-html/unnamed-chunk-54-1.png)

``` r

iris |>
  plotit(encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
  mark_point() |>
  scale_color(range = "brewer")
#> Scale for colour is already present.
#> Adding another scale for colour, which will replace the existing scale.
```

![](visualizing-data_files/figure-html/unnamed-chunk-55-1.png)

## Next

- [Advanced](https://zorrooz.github.io/plotit/articles/advanced.md) —
  multi-panel composition, relational layouts, escape hatch
- [API](https://zorrooz.github.io/plotit/articles/api.md) — verb
  families and shared signatures
- [Reference](https://zorrooz.github.io/plotit/reference/index.md) —
  every function
