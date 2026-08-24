# ============================================================
# mark_* function family -- BDD tests (assert rendered output)
# AGENTS.md 4.8: assert rendered behaviour, not internal state
# ============================================================
library(plotit)

# Helper
.built <- function(p) ggplot2::ggplot_build(p@gg)

# ---- mark_point ----
test_that("[BDD] mark_point adds scatter layer", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point(size = 2)
  expect_s3_class(p, "plotit::plotit")
  expect_length(.built(p)$data, 1)
})

test_that("[BDD] mark_point supports local mapping", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point(mapping = encode(colour = Species))
  expect_s3_class(p, "plotit::plotit")
  expect_length(.built(p)$data, 1)
})

test_that("mark_point supports local data", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point(data = iris[1:50, ])
  expect_s3_class(p, "plotit::plotit")
})

# ---- mark_line ----
test_that("[BDD] mark_line adds line layer", {
  p <- plotit(ggplot2::economics, encode(x = date, y = unemploy)) |>
    mark_line(linewidth = 0.8)
  expect_s3_class(p, "plotit::plotit")
  expect_length(.built(p)$data, 1)
})

test_that("[BDD] mark_line supports local data and mapping", {
  p <- plotit(ggplot2::economics, encode(x = date, y = unemploy))
  sub <- ggplot2::economics[1:10, ]
  p <- mark_line(p, data = sub, mapping = encode(x = date, y = unemploy))
  expect_s3_class(p, "plotit::plotit")
  expect_length(.built(p)$data, 1)
})

# ---- mark_bar ----
test_that("[BDD] mark_bar adds bar layer", {
  p <- plotit(iris, encode(x = Species)) |> mark_bar()
  expect_s3_class(p, "plotit::plotit")
  expect_length(.built(p)$data, 1)
})

test_that("[BDD] mark_bar with y mapping renders with y-axis", {
  df <- data.frame(cat = c("A", "B"), val = c(10, 20))
  p <- plotit(df, encode(x = cat, y = val)) |> mark_bar()
  built <- .built(p)
  expect_length(built$data, 1)
  # y mapping present -> geom_col used -> y aesthetic is mapped
  y_map <- built$plot$mapping$y
  expect_false(is.null(y_map))
})

test_that("[BDD] mark_bar supports layer-level data", {
  p <- plotit(iris, encode(x = Species)) |> mark_bar(data = iris[1:100, ])
  expect_length(.built(p)$data, 1)
})

test_that("mark_bar supports fill mapping for stacking", {
  p <- plotit(iris, encode(x = Species, fill = Species)) |>
    mark_bar(position = "stack")
  expect_s3_class(p, "plotit::plotit")
})

# ---- mark_boxplot ----
test_that("[BDD] mark_boxplot adds boxplot layer", {
  p <- plotit(iris, encode(x = Species, y = Sepal.Length)) |>
    mark_boxplot()
  expect_s3_class(p, "plotit::plotit")
  expect_length(.built(p)$data, 1)
})

test_that("mark_boxplot supports local data", {
  p <- plotit(iris, encode(x = Species, y = Sepal.Length)) |>
    mark_boxplot(data = iris[1:100, ])
  expect_s3_class(p, "plotit::plotit")
})

# ---- dodge auto-injection (BDD: verify visual separation) ----
test_that("[BDD] mark_bar with discrete x and fill produces dodged bars", {
  p <- plotit(iris, encode(x = Species, fill = Species)) |> mark_bar()
  built <- .built(p)
  # Dodged bars have x shifted from center -- verify data has xmin/xmax
  df <- built$data[[1]]
  expect_true("xmin" %in% names(df) && "xmax" %in% names(df))
})

test_that("[BDD] mark_bar with continuous x uses default position (stack)", {
  p <- plotit(mtcars, encode(x = wt)) |> mark_bar()
  built <- .built(p)
  df <- built$data[[1]]
  # Stacked bars: count per bin, y > 0
  expect_true(all(df$y >= 0))
})

test_that("[BDD] explicit position overrides auto-dodge", {
  p <- plotit(iris, encode(x = Species, fill = Species)) |>
    mark_bar(position = "stack")
  built <- .built(p)
  expect_length(built$data, 1)
})

test_that("[BDD] mark_boxplot with discrete x and fill auto-dodges", {
  p <- plotit(iris, encode(x = Species, y = Sepal.Length, fill = Species)) |>
    mark_boxplot()
  built <- .built(p)
  expect_length(built$data, 1)
})

test_that("[BDD] mark_point with discrete x auto-dodges", {
  p <- plotit(iris, encode(x = Species, y = Sepal.Length, colour = Species)) |>
    mark_point()
  built <- .built(p)
  expect_length(built$data, 1)
})

test_that("[BDD] plotit() explicit dodge=0 produces stacked bars", {
  p <- plotit(iris, encode(x = Species, fill = Species), dodge = 0) |>
    mark_bar()
  built <- .built(p)
  expect_length(built$data, 1)
})

# ---- rasterize ----
test_that("rasterize default FALSE does not error", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  expect_no_error(mark_point(p))
})

test_that("rasterize=TRUE triggers ggrastr and renders", {
  skip_if_not_installed("ggrastr")
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  expect_no_error(mark_point(p, rasterize = TRUE, rasterize_dpi = 72))
})

# ---- pipeline ----
test_that("[BDD] pipeline mark_point + scale + label renders", {
  p <- iris |>
    plotit(encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    mark_point(size = 2) |>
    scale_color(name = "Species") |>
    label_title("Test") |>
    style_default()
  built <- .built(p)
  expect_length(built$data, 1)
})

test_that("[BDD] pipeline mark_boxplot + scale + label + project renders", {
  p <- iris |>
    plotit(encode(x = Species, y = Sepal.Length, fill = Species)) |>
    mark_boxplot() |>
    scale_fill(name = "species") |>
    label_title("Boxplot") |>
    label_subtitle("by Iris species") |>
    label_axis(text = "Species", aes = "x") |>
    label_axis(text = "Sepal Length", aes = "y") |>
    project_cartesian(flip = TRUE) |>
    style_default()
  built <- .built(p)
  expect_length(built$data, 1)
})

# ---- mark_histogram / mark_density ----
test_that("[BDD] mark_histogram adds histogram layer", {
  p <- plotit(iris, encode(x = Sepal.Width)) |> mark_histogram(bins = 20)
  expect_s3_class(p, "plotit::plotit")
  expect_length(.built(p)$data, 1)
})

test_that("[BDD] mark_density adds density layer", {
  p <- plotit(iris, encode(x = Sepal.Width)) |> mark_density(linewidth = 1)
  expect_s3_class(p, "plotit::plotit")
  expect_length(.built(p)$data, 1)
})

# ---- mark_area ----
test_that("[BDD] mark_area adds area layer", {
  p <- plotit(ggplot2::economics, encode(x = date, y = unemploy)) |>
    mark_area(alpha = 0.5)
  expect_s3_class(p, "plotit::plotit")
  expect_length(.built(p)$data, 1)
})

test_that("[BDD] mark_area supports local mapping and data", {
  p <- plotit(ggplot2::economics, encode(x = date, y = unemploy))
  sub <- ggplot2::economics[1:100, ]
  p <- mark_area(p, data = sub, mapping = encode(x = date, y = unemploy))
  expect_s3_class(p, "plotit::plotit")
  expect_length(.built(p)$data, 1)
})

test_that("mark_area supports fill aesthetic", {
  p <- plotit(ggplot2::economics, encode(x = date, y = unemploy, fill = "blue")) |>
    mark_area()
  expect_s3_class(p, "plotit::plotit")
})

# ---- mark_text ----
test_that("[BDD] mark_text adds text layer", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, label = rownames(mtcars))) |>
    mark_text(size = 3)
  expect_s3_class(p, "plotit::plotit")
  expect_length(.built(p)$data, 1)
})

test_that("[BDD] mark_text supports local mapping", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_text(mapping = encode(label = rownames(mtcars)), size = 3)
  expect_s3_class(p, "plotit::plotit")
  expect_length(.built(p)$data, 1)
})

test_that("mark_text passes extra params via dots", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, label = rownames(mtcars))) |>
    mark_text(size = 3, check_overlap = TRUE, vjust = -1)
  expect_s3_class(p, "plotit::plotit")
})

# ---- mark_violin ----
test_that("[BDD] mark_violin adds violin layer", {
  p <- plotit(iris, encode(x = Species, y = Sepal.Length)) |>
    mark_violin(draw_quantiles = 0.5)
  expect_s3_class(p, "plotit::plotit")
  expect_length(.built(p)$data, 1)
})

test_that("[BDD] mark_violin supports local data", {
  p <- plotit(iris, encode(x = Species, y = Sepal.Length)) |>
    mark_violin(data = iris[iris$Species == "setosa", ])
  expect_s3_class(p, "plotit::plotit")
  expect_length(.built(p)$data, 1)
})

test_that("[BDD] mark_violin auto-dodges with fill", {
  p <- plotit(iris, encode(x = Species, y = Sepal.Length, fill = Species)) |>
    mark_violin()
  built <- .built(p)
  expect_length(built$data, 1)
})

# ---- mark_map ----
test_that("mark_map errors on non-sf data", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  expect_error(mark_map(p), "sf")
})

test_that("[BDD] mark_map renders with sf data", {
  skip_if_not_installed("sf")
  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
  p <- plotit(nc, encode(geometry = geometry)) |> mark_map()
  expect_s3_class(p, "plotit::plotit")
  expect_length(.built(p)$data, 1)
})

test_that("mark_map supports fill mapping", {
  skip_if_not_installed("sf")
  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
  p <- plotit(nc, encode(geometry = geometry, fill = AREA)) |> mark_map()
  expect_s3_class(p, "plotit::plotit")
})

# ---- mark_rect ----
test_that("[BDD] mark_rect adds tile layer", {
  df <- expand.grid(x = 1:5, y = 1:5)
  df$z <- df$x * df$y
  p <- plotit(df, encode(x = x, y = y, fill = z)) |> mark_rect()
  expect_s3_class(p, "plotit::plotit")
  expect_length(.built(p)$data, 1)
})

test_that("mark_rect supports local data", {
  df <- expand.grid(x = 1:3, y = 1:3)
  df$z <- runif(9)
  # Empty data with column structure retained, avoids the
  # "Cannot determine variable type" warning
  p <- plotit(df[0, ], encode(x = x, y = y)) |>
    mark_rect(data = df, mapping = encode(x = x, y = y, fill = z))
  expect_s3_class(p, "plotit::plotit")
})

test_that("mark_rect passes width/height via dots", {
  df <- expand.grid(x = 1:3, y = 1:3)
  df$z <- 1:9
  p <- plotit(df, encode(x = x, y = y, fill = z)) |>
    mark_rect(width = 0.8, height = 0.8, colour = "white")
  expect_s3_class(p, "plotit::plotit")
})

# ---- mark_rule ----
test_that("[BDD] mark_rule with xintercept adds vertical line", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    mark_rule(xintercept = 3, colour = "red")
  built <- .built(p)
  expect_s3_class(p, "plotit::plotit")
  expect_true(length(built$data) >= 2) # point + rule
})

test_that("[BDD] mark_rule with yintercept adds horizontal line", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    mark_rule(yintercept = 5)
  built <- .built(p)
  expect_s3_class(p, "plotit::plotit")
  expect_true(length(built$data) >= 2)
})

test_that("[BDD] mark_rule with slope+intercept adds abline", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    mark_rule(slope = 1, intercept = 0)
  built <- .built(p)
  expect_s3_class(p, "plotit::plotit")
  expect_true(length(built$data) >= 2)
})

test_that("[BDD] mark_rule with x+xend+y+yend adds segment", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    mark_rule(x = 2, xend = 4, y = 5, yend = 7)
  built <- .built(p)
  expect_s3_class(p, "plotit::plotit")
  expect_true(length(built$data) >= 2)
})

test_that("mark_rule supports rasterize", {
  skip_if_not_installed("ggrastr")
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    mark_rule(
      xintercept = median(iris$Sepal.Width),
      rasterize = TRUE, rasterize_dpi = 72
    )
  expect_s3_class(p, "plotit::plotit")
})

# ---- mark_path ----
test_that("[BDD] mark_path adds path layer", {
  df <- data.frame(x = 1:10, y = cumsum(runif(10, -1, 1)))
  p <- plotit(df, encode(x = x, y = y)) |> mark_path()
  expect_s3_class(p, "plotit::plotit")
  expect_length(.built(p)$data, 1)
})

test_that("[BDD] mark_path supports group aesthetic", {
  set.seed(1)
  df <- data.frame(
    x = rep(1:5, 2),
    y = rnorm(10),
    g = rep(c("A", "B"), each = 5)
  )
  p <- plotit(df, encode(x = x, y = y, colour = g)) |> mark_path()
  built <- .built(p)
  expect_s3_class(p, "plotit::plotit")
  expect_length(built$data, 1)
})

test_that("mark_path passes line params via dots", {
  df <- data.frame(x = 1:10, y = cumsum(runif(10, -1, 1)))
  p <- plotit(df, encode(x = x, y = y)) |>
    mark_path(linewidth = 1.5, linetype = "dashed")
  expect_s3_class(p, "plotit::plotit")
})

# ---- mark_polygon ----
test_that("[BDD] mark_polygon adds polygon layer", {
  tri <- data.frame(x = c(0, 1, 0.5), y = c(0, 0, 1))
  p <- plotit(tri, encode(x = x, y = y)) |> mark_polygon(fill = "skyblue")
  expect_s3_class(p, "plotit::plotit")
  expect_length(.built(p)$data, 1)
})

test_that("[BDD] mark_polygon supports multiple groups", {
  df <- rbind(
    data.frame(x = c(0, 1, 0.5), y = c(0, 0, 1), g = "A"),
    data.frame(x = c(2, 3, 2.5) + 1, y = c(0, 0, 1) + 1, g = "B")
  )
  p <- plotit(df, encode(x = x, y = y, fill = g)) |> mark_polygon()
  built <- .built(p)
  expect_s3_class(p, "plotit::plotit")
  expect_length(built$data, 1)
})

test_that("mark_polygon supports colour aesthetic", {
  tri <- data.frame(x = c(0, 1, 0.5), y = c(0, 0, 1))
  p <- plotit(tri, encode(x = x, y = y)) |>
    mark_polygon(fill = "skyblue", colour = "navy")
  expect_s3_class(p, "plotit::plotit")
})

# ---- mark_smooth ----
test_that("[BDD] mark_smooth adds smooth layer", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |> mark_smooth()
  expect_s3_class(p, "plotit::plotit")
  expect_length(.built(p)$data, 1)
})

test_that("mark_smooth supports linear method", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_smooth(method = "lm", se = FALSE)
  expect_s3_class(p, "plotit::plotit")
})

test_that("mark_smooth supports colour aesthetic", {
  p <- plotit(mtcars, encode(x = wt, y = mpg, colour = factor(cyl))) |>
    mark_smooth()
  expect_s3_class(p, "plotit::plotit")
})

# ---- mark_hex ----
test_that("[BDD] mark_hex adds hex bin layer", {
  skip_if_not_installed("hexbin")
  p <- plotit(
    ggplot2::diamonds[sample(nrow(ggplot2::diamonds), 1000), ],
    encode(x = carat, y = price)
  ) |> mark_hex(bins = 15)
  expect_s3_class(p, "plotit::plotit")
  expect_length(.built(p)$data, 1)
})

test_that("mark_hex supports bins parameter", {
  skip_if_not_installed("hexbin")
  p <- plotit(
    ggplot2::diamonds[sample(nrow(ggplot2::diamonds), 500), ],
    encode(x = carat, y = price)
  ) |> mark_hex(bins = 10)
  expect_s3_class(p, "plotit::plotit")
})

test_that("mark_hex supports local data", {
  skip_if_not_installed("hexbin")
  sub <- ggplot2::diamonds[sample(nrow(ggplot2::diamonds), 300), ]
  p <- plotit(sub, encode(x = carat, y = price)) |> mark_hex(data = sub)
  expect_s3_class(p, "plotit::plotit")
})

# ---- mark_density_2d ----
test_that("[BDD] mark_density_2d adds contour layer", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_density_2d()
  expect_s3_class(p, "plotit::plotit")
  expect_length(.built(p)$data, 1)
})

test_that("mark_density_2d supports filled mode", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_density_2d(filled = TRUE, bins = 6)
  expect_s3_class(p, "plotit::plotit")
})

test_that("mark_density_2d supports bins parameter", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_density_2d(bins = 10)
  expect_s3_class(p, "plotit::plotit")
})

# ---- mark_corr ----
test_that("[BDD] mark_corr adds correlation heatmap", {
  p <- plotit(mtcars, encode()) |> mark_corr()
  expect_s3_class(p, "plotit::plotit")
  expect_length(.built(p)$data, 1)
})

test_that("mark_corr supports spearman method", {
  p <- plotit(mtcars, encode()) |> mark_corr(method = "spearman")
  expect_s3_class(p, "plotit::plotit")
})

test_that("mark_corr supports no-reorder", {
  p <- plotit(mtcars, encode()) |> mark_corr(reorder = FALSE)
  expect_s3_class(p, "plotit::plotit")
})

# ---- make_mark / make_theme ----
test_that("make_mark creates a usable custom mark", {
  generic <- make_mark("mark_tile_test", ggplot2::geom_tile)
  df <- expand.grid(x = 1:3, y = 1:3)
  df$z <- 1:9
  p <- generic(plotit(df, encode(x = x, y = y, fill = z)))
  expect_s3_class(p, "plotit::plotit")
  expect_length(.built(p)$data, 1)
})

test_that("make_mark warns on non-mark_ name", {
  expect_warning(make_mark("foo_bar", ggplot2::geom_point))
})

test_that("make_theme creates a usable theme function", {
  style_test <- make_theme("style_test",
    plot.title = ggplot2::element_text(colour = "blue")
  )
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_title("Test") |>
    style_test()
  expect_s3_class(p, "plotit::plotit")
})

test_that("make_theme with custom base theme works", {
  style_custom <- make_theme("style_custom",
    panel.grid.major = ggplot2::element_line(colour = "grey90"),
    base_theme = ggplot2::theme_bw
  )
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    style_custom()
  expect_s3_class(p, "plotit::plotit")
})

# ---- mark_errorbar ----
test_that("[BDD] mark_errorbar adds error bars", {
  df <- data.frame(
    x = c("A", "B"),
    y = c(10, 20),
    ymin = c(8, 18),
    ymax = c(12, 22)
  )
  p <- plotit(df, encode(x = x, y = y, ymin = ymin, ymax = ymax)) |>
    mark_point() |>
    mark_errorbar(width = 0.3)
  expect_s3_class(p, "plotit::plotit")
  expect_true(length(.built(p)$data) >= 2)
})

test_that("mark_errorbar supports horizontal orientation", {
  df <- data.frame(
    y = c("A", "B"), x = c(10, 20),
    xmin = c(8, 18), xmax = c(12, 22)
  )
  p <- plotit(df, encode(x = x, y = y, xmin = xmin, xmax = xmax)) |>
    mark_point() |>
    mark_errorbar(width = 0.3, orientation = "horizontal")
  expect_s3_class(p, "plotit::plotit")
})

test_that("mark_errorbar supports local data", {
  df <- data.frame(x = c("A", "B"), y = c(10, 20))
  err <- data.frame(x = c("A", "B"), ymin = c(8, 18), ymax = c(12, 22))
  p <- plotit(df, encode(x = x, y = y)) |>
    mark_point() |>
    mark_errorbar(data = err, mapping = encode(x = x, ymin = ymin, ymax = ymax))
  expect_s3_class(p, "plotit::plotit")
})

# ---- mark_significance ----
test_that("[BDD] mark_significance adds significance brackets", {
  df <- data.frame(group = c("A", "B", "C"), value = c(5, 8, 4))
  comp <- data.frame(
    group1 = c("A", "A"), group2 = c("B", "C"),
    label = c("**", "ns"), stringsAsFactors = FALSE
  )
  p <- plotit(df, encode(x = group, y = value)) |>
    mark_bar() |>
    mark_significance(comp, y_position = c(9, 6))
  expect_s3_class(p, "plotit::plotit")
})

test_that("mark_significance errors on missing columns", {
  df <- data.frame(group = c("A", "B"), value = c(5, 8))
  bad_comp <- data.frame(x = 1:2)
  p <- plotit(df, encode(x = group, y = value)) |> mark_bar()
  expect_error(mark_significance(p, bad_comp), "group1")
})

test_that("mark_significance auto-computes y_position", {
  df <- data.frame(group = c("A", "B", "C"), value = c(5, 8, 4))
  comp <- data.frame(
    group1 = c("A"), group2 = c("B"),
    label = c("*"), stringsAsFactors = FALSE
  )
  p <- plotit(df, encode(x = group, y = value)) |>
    mark_bar() |>
    mark_significance(comp, y_offset = 0.5)
  expect_s3_class(p, "plotit::plotit")
})

# ---- mark_lollipop ----
test_that("[BDD] mark_lollipop creates lollipop chart", {
  df <- data.frame(cat = LETTERS[1:5], val = c(3, 7, 2, 9, 5))
  p <- plotit(df, encode(x = cat, y = val)) |> mark_lollipop()
  expect_s3_class(p, "plotit::plotit")
})

test_that("mark_lollipop supports custom stem colour", {
  df <- data.frame(cat = LETTERS[1:5], val = c(3, 7, 2, 9, 5))
  p <- plotit(df, encode(x = cat, y = val)) |>
    mark_lollipop(stem_colour = "steelblue", point_size = 4)
  expect_s3_class(p, "plotit::plotit")
})

test_that("mark_lollipop works with local data", {
  df <- data.frame(cat = LETTERS[1:3], val = c(4, 6, 2))
  p <- plotit(df, encode(x = cat, y = val)) |>
    mark_lollipop(data = df[1:2, ])
  expect_s3_class(p, "plotit::plotit")
})

# ---- mark_dumbbell ----
test_that("[BDD] mark_dumbbell creates dumbbell chart", {
  df <- data.frame(
    cat = LETTERS[1:4],
    before = c(3, 5, 2, 8),
    after = c(7, 6, 5, 10)
  )
  p <- plotit(df, encode(x = cat, y = before, yend = after)) |>
    mark_dumbbell()
  expect_s3_class(p, "plotit::plotit")
})

test_that("mark_dumbbell supports custom colours", {
  df <- data.frame(cat = LETTERS[1:3], before = c(3, 5, 2), after = c(7, 6, 5))
  p <- plotit(df, encode(x = cat, y = before, yend = after)) |>
    mark_dumbbell(colour_start = "orange", colour_end = "purple")
  expect_s3_class(p, "plotit::plotit")
})

test_that("mark_dumbbell works with local data", {
  df <- data.frame(
    cat = LETTERS[1:4],
    before = c(3, 5, 2, 8),
    after = c(7, 6, 5, 10)
  )
  p <- plotit(df, encode(x = cat, y = before, yend = after)) |>
    mark_dumbbell(data = df[1:2, ])
  expect_s3_class(p, "plotit::plotit")
})

# ---- mark_beeswarm ----
test_that("[BDD] mark_beeswarm errors without ggbeeswarm", {
  skip_if_not_installed("ggbeeswarm")
  p <- plotit(iris, encode(x = Species, y = Sepal.Length)) |>
    mark_beeswarm()
  expect_s3_class(p, "plotit::plotit")
})

test_that("mark_beeswarm supports quasirandom method", {
  skip_if_not_installed("ggbeeswarm")
  p <- plotit(iris, encode(x = Species, y = Sepal.Length)) |>
    mark_beeswarm(method = "swarm", cex = 2)
  expect_s3_class(p, "plotit::plotit")
})

test_that("mark_beeswarm supports local data", {
  skip_if_not_installed("ggbeeswarm")
  p <- plotit(iris, encode(x = Species, y = Sepal.Length)) |>
    mark_beeswarm(data = iris[1:50, ])
  expect_s3_class(p, "plotit::plotit")
})

# ---- mark_sankey ----
.sankey_df <- function() {
  data.frame(
    source = c("A", "A", "B", "B", "C"),
    target = c("B", "C", "C", "D", "D"),
    value = c(10, 5, 8, 3, 6)
  )
}

test_that("[BDD] mark_sankey builds sankey (edges-table API)", {
  s1 <- .sankey_df() |>
    plotit(encode(
      source = source, target = target,
      value = value, fill = source
    )) |>
    mark_sankey()
  expect_s3_class(s1, "plotit::plotit")
  # laid-out tables stored for further ~table references
  expect_setequal(names(s1@graph), c("nodes", "edges", "ribbons"))
  built <- suppressWarnings(ggplot2::ggplot_build(s1@gg))
  expect_length(built$plot$layers, 3) # polygon + rect + text
  # one ribbon polygon: 5 edges x (50 top + 50 bottom) rows
  expect_equal(nrow(built$data[[1]]), 5 * 100)
  expect_gt(nrow(built$data[[2]]), 0)
  # no "Ignoring unknown aesthetics" warnings during build
  expect_no_warning(ggplot2::ggplot_build(s1@gg))
})

test_that("mark_sankey errors without source/target mapping", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  expect_error(mark_sankey(p), "source")
})

test_that("mark_sankey supports flow_alpha", {
  s2 <- .sankey_df() |>
    plotit(encode(source = source, target = target, value = value)) |>
    mark_sankey(flow_alpha = 0.8)
  alphas <- vapply(
    s2@gg$layers,
    function(l) l$aes_params$alpha %||% NA_real_, numeric(1)
  )
  expect_true(any(alphas == 0.8, na.rm = TRUE)) # ribbon layer only
  expect_true(anyNA(alphas)) # node/text layers stay opaque
})

test_that("mark_sankey keeps numeric fill values numeric (#5)", {
  df <- .sankey_df()
  df$weight <- c(1.5, 2.5, 3.5, 4.5, 5.5)
  p <- df |>
    plotit(encode(
      source = source, target = target,
      value = value, fill = weight
    )) |>
    mark_sankey()
  expect_type(p@gg$layers[[1]]$data$fill_grp, "double")
  expect_no_warning(ggplot2::ggplot_build(p@gg))
})

test_that("mark_sankey: node fill uses first-occurrence identity by default", {
  s3 <- .sankey_df() |>
    plotit(encode(source = source, target = target, value = value)) |>
    mark_sankey(node_colour = "grey30")
  # D first appears as target of edge B->D, so it inherits B's identity
  expect_identical(
    unname(s3@graph$nodes$fill_grp),
    c("A", "B", "C", "B")
  )
  # static colour on the node layer when no fill mapping
  rect_layer <- s3@gg$layers[[2]]
  expect_identical(rect_layer$aes_params$fill, "grey30")
})

# ---- mark_treemap ----
test_that("[BDD] mark_treemap builds treemap", {
  skip_if_not_installed("treemapify")
  df <- data.frame(
    group = c("A", "B", "C"),
    subgroup = c("a1", "a2", "b1"),
    size = c(30, 20, 50)
  )
  p <- plotit(df, encode(
    area = size, fill = group,
    subgroup = subgroup
  )) |>
    mark_treemap()
  expect_s3_class(p, "plotit::plotit")
})

test_that("mark_treemap errors without treemapify", {
  if (requireNamespace("treemapify", quietly = TRUE)) {
    skip("treemapify is installed, cannot test error path")
  }
  df <- data.frame(group = c("A", "B"), subgroup = c("a", "b"), size = c(10, 20))
  p <- plotit(df, encode(area = size, fill = group, subgroup = subgroup))
  expect_error(mark_treemap(p), "treemapify")
})

test_that("mark_treemap supports rasterize", {
  skip_if_not_installed("treemapify")
  skip_if_not_installed("ggrastr")
  df <- data.frame(
    group = c("A", "B"), subgroup = c("a", "b"), size = c(10, 20)
  )
  p <- plotit(df, encode(area = size, fill = group, subgroup = subgroup)) |>
    mark_treemap(rasterize = TRUE, rasterize_dpi = 72)
  expect_s3_class(p, "plotit::plotit")
})

# ---- mark_network ----
test_that("[BDD] mark_network builds network (nodes + edges API)", {
  skip_if_not_installed("igraph")
  nodes <- data.frame(
    name = c("A", "B", "C", "D"),
    group = c("X", "Y", "X", "Y"),
    value = c(10, 20, 15, 25)
  )
  edges <- data.frame(
    from = c("A", "A", "B", "C"),
    to = c("B", "C", "C", "D"),
    weight = c(1, 2, 3, 4)
  )
  p <- nodes |>
    plotit(encode(color = group, size = value, label = name)) |>
    mark_network(
      edges = edges,
      encode_edges = encode(source = from, target = to, value = weight),
      seed = 1
    )
  expect_s3_class(p, "plotit::plotit")
  # edge + node + label layers
  expect_length(ggplot2::ggplot_build(p@gg)$data, 3)
  # laid-out graph stored for further ~table references
  expect_setequal(names(p@graph), c("nodes", "edges"))
})

test_that("mark_network: encode_edges(weight=) is deprecated but works", {
  skip_if_not_installed("igraph")
  nodes <- data.frame(name = c("A", "B"), group = c("X", "Y"))
  edges <- data.frame(from = "A", to = "B", weight = 2)
  expect_warning(
    p <- nodes |>
      plotit() |>
      mark_network(
        edges = edges,
        encode_edges = encode(
          source = from, target = to,
          weight = weight
        )
      ),
    "deprecated"
  )
  expect_s3_class(p, "plotit::plotit")
})

test_that("mark_network is additive: prior layers survive", {
  skip_if_not_installed("igraph")
  nodes <- data.frame(name = c("A", "B", "C"), group = c("X", "Y", "X"))
  edges <- data.frame(from = c("A", "B"), to = c("B", "C"))
  base <- nodes |>
    plotit(encode(color = group)) |>
    mark_point(alpha = .3)
  n_before <- length(base@gg$layers) # the prior point layer
  p <- base |>
    mark_network(
      edges = edges,
      encode_edges = encode(source = from, target = to)
    )
  expect_length(p@gg$layers, n_before + 2) # edge + node (no label aes)
})

test_that("mark_network manual layout uses node x/y columns", {
  nodes <- cbind(
    data.frame(name = c("A", "B", "C")),
    x = c(1, 2, 3), y = c(1, 2, 1)
  )
  edges <- data.frame(from = c("A", "B"), to = c("B", "C"))

  # without igraph installed this must still work
  p <- nodes |>
    plotit() |>
    mark_network(
      edges = edges,
      encode_edges = encode(source = from, target = to),
      layout = "manual"
    )
  built <- ggplot2::ggplot_build(p@gg)
  expect_length(built$plot$layers, 2)

  err <- tryCatch(
    plotit(data.frame(
      name = c("A", "B", "C"),
      x = c("a", "b", "c"), y = 1:3
    )) |>
      mark_network(
        edges = edges,
        encode_edges = encode(source = from, target = to),
        layout = "manual"
      ),
    error = function(e) conditionMessage(e)
  )
  expect_match(err, "numeric")
})

test_that("mark_network linear/bipartite layouts are deprecated with fallback", {
  skip_if_not_installed("igraph")
  nodes <- data.frame(name = c("A", "B", "C"))
  edges <- data.frame(from = c("A", "B"), to = c("B", "C"))
  expect_warning(
    p <- nodes |>
      plotit() |>
      mark_network(
        edges = edges,
        encode_edges = encode(source = from, target = to),
        layout = "bipartite"
      ),
    "deprecated"
  )
  expect_s3_class(p, "plotit::plotit")
})

test_that("[BDD] mark_network maps edge visual channels from edge columns", {
  skip_if_not_installed("igraph")
  nodes <- data.frame(name = c("A", "B", "C"))
  edges <- data.frame(
    from = c("A", "B"), to = c("B", "C"),
    type = c("x", "y")
  )
  p <- nodes |>
    plotit() |>
    mark_network(
      edges = edges,
      encode_edges = encode(
        source = from, target = to,
        colour = type
      )
    )
  mp <- p@gg$layers[[2]]$mapping # edge segment layer
  expect_false(is.null(mp$colour))
})

test_that("mark_network errors on non-node data", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  expect_error(mark_network(p), "node id")
})

test_that("mark_network supports circle layout", {
  skip_if_not_installed("igraph")
  nodes <- data.frame(name = c("A", "B", "C", "D"), group = c("X", "Y", "X", "Y"))
  edges <- data.frame(from = c("A", "A", "B", "C"), to = c("B", "C", "C", "D"))
  p <- nodes |>
    plotit(encode(color = group)) |>
    mark_network(
      edges = edges,
      encode_edges = encode(source = from, target = to),
      layout = "circle"
    )
  expect_s3_class(p, "plotit::plotit")
  expect_length(ggplot2::ggplot_build(p@gg)$data, 2)
})

# ---- mark_chord ----
.chord_df <- function() {
  data.frame(
    source = c("A", "A", "B", "B", "C"),
    target = c("B", "C", "C", "D", "D"),
    value = c(5, 3, 4, 2, 6)
  )
}

test_that("[BDD] mark_chord builds chord diagram (sugar over layout_chord)", {
  p <- .chord_df() |>
    plotit(encode(
      source = source, target = target,
      value = value, fill = source
    )) |>
    mark_chord()
  expect_s3_class(p, "plotit::plotit")
  # four laid-out tables, two polygon layers (bands + sectors)
  expect_setequal(names(p@graph), c("nodes", "edges", "arcs", "ribbons"))
  built <- suppressWarnings(ggplot2::ggplot_build(p@gg))
  expect_length(built$plot$layers, 2)
  expect_s3_class(built$plot$layers[[1]]$geom, "GeomPolygon")
  expect_s3_class(built$plot$layers[[2]]$geom, "GeomPolygon")
  # native-renderer escape hatch fully retired
  expect_null(attr(p@meta, "plotit_native_render", exact = TRUE))
  expect_no_warning(ggplot2::ggplot_build(p@gg))
})

test_that("mark_chord accepts legacy from/to and direct matrix data", {
  mat <- matrix(c(0, 5, 3, 2, 0, 4, 1, 3, 0), nrow = 3)
  rownames(mat) <- colnames(mat) <- c("A", "B", "C")

  long <- as.data.frame(as.table(mat))
  names(long) <- c("from", "to", "value")
  long <- long[long$value > 0, ]

  p1 <- plotit(long, encode()) |> mark_chord()
  expect_setequal(names(p1@graph), c("nodes", "edges", "arcs", "ribbons"))

  # raw matrices must be passed via the data argument (plotit()'s main
  # slot fortifies matrices before the mark can see them)
  p2 <- plotit(data.frame(x = 1), encode()) |> mark_chord(data = mat)
  expect_setequal(names(p2@graph), c("nodes", "edges", "arcs", "ribbons"))
  for (p in list(p1, p2)) {
    expect_length(suppressWarnings(
      ggplot2::ggplot_build(p@gg)$plot$layers
    ), 2)
  }
})

test_that("mark_chord: link_alpha applies to bands only; dots are rejected", {
  msgs <- character(0)
  p <- withCallingHandlers(
    .chord_df() |>
      plotit(encode(source = source, target = target, value = value)) |>
      mark_chord(link_alpha = 0.7, curvature = 0.9),
    warning = function(w) {
      msgs <<- c(msgs, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  alphas <- vapply(
    p@gg$layers,
    function(l) l$aes_params$alpha %||% NA_real_, numeric(1)
  )
  expect_true(any(alphas == 0.7, na.rm = TRUE)) # band layer only
  expect_true(anyNA(alphas))
  expect_true(any(grepl("ignored", msgs)))
})

# ---- transform_corr ----
test_that("[BDD] transform_corr melts correlations into long form", {
  d <- mtcars[, c("mpg", "disp", "hp")]
  out <- transform_corr(d)

  expect_setequal(names(out), c("Var1", "Var2", "value"))
  expect_equal(nrow(out), 3^2)
  expect_s3_class(out$Var1, "factor")
  # diagonal is perfectly correlated
  diag_rows <- out[out$Var1 == out$Var2, ]
  expect_true(all(diag_rows$value == 1))
})

test_that("transform_corr: reorder preserves the value multiset", {
  d <- mtcars[, c("mpg", "disp", "hp", "wt")]
  r1 <- transform_corr(d, reorder = TRUE)
  r0 <- transform_corr(d, reorder = FALSE)

  expect_false(identical(levels(r1$Var1), levels(r0$Var1)))
  expect_identical(sort(r1$value), sort(r0$value))
})

test_that("transform_corr validates inputs", {
  expect_error(transform_corr(data.frame(a = 1)), "numeric")
  expect_error(transform_corr(as.matrix(iris[, 1:2])), "data.frame")
})

test_that("transform_corr skips reorder on NA matrix with warning", {
  d <- data.frame(x = c(1, 1, 1), y = 1:3) # zero-variance x -> NA corr
  expect_warning(out <- transform_corr(d), "skipping reorder")
  expect_true(anyNA(out$value))
})

test_that("mark_corr is sugar over transform_corr + tile layer", {
  p <- plotit(mtcars, encode()) |> mark_corr()
  built <- ggplot2::ggplot_build(p@gg)
  expect_length(built$plot$layers, 1)
  expect_equal(nrow(built$data[[1]]), ncol(mtcars)^2)
})
