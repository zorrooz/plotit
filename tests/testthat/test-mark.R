# ============================================================
# mark_* function family — layer addition, auto-dodge, rasterization
# ============================================================
library(plotit)

# ---- mark_point ----
test_that("mark_point adds scatter layer and returns plotit", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p2 <- mark_point(p, size = 2)
  expect_s3_class(p2, "plotit::plotit")
  expect_length(p2@gg$layers, 1)
})

test_that("mark_point supports local mapping", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p2 <- mark_point(p, mapping = encode(colour = Species))
  expect_s3_class(p2, "plotit::plotit")
  expect_length(p2@gg$layers, 1)
})

test_that("mark_point supports local data", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  p2 <- mark_point(p, data = iris[1:50, ])
  expect_s3_class(p2, "plotit::plotit")
})

# ---- mark_line ----
test_that("mark_line adds line layer and returns plotit", {
  p <- plotit(ggplot2::economics, encode(x = date, y = unemploy))
  p2 <- mark_line(p, linewidth = 0.8)
  expect_s3_class(p2, "plotit::plotit")
  expect_length(p2@gg$layers, 1)
})

test_that("mark_line supports local data and mapping", {
  p <- plotit(ggplot2::economics, encode(x = date, y = unemploy))
  sub <- ggplot2::economics[1:10, ]
  p2 <- mark_line(p, data = sub, mapping = encode(x = date, y = unemploy))
  expect_s3_class(p2, "plotit::plotit")
  expect_length(p2@gg$layers, 1)
})

# ---- mark_bar ----
test_that("mark_bar adds bar layer and returns plotit", {
  p <- plotit(iris, encode(x = Species))
  p2 <- mark_bar(p)
  expect_s3_class(p2, "plotit::plotit")
  expect_length(p2@gg$layers, 1)
})

test_that("mark_bar with y mapping switches to geom_col", {
  df <- data.frame(cat = c("A", "B"), val = c(10, 20))
  p <- plotit(df, encode(x = cat, y = val)) |>
    mark_bar()
  expect_s3_class(p, "plotit::plotit")
  expect_length(p@gg$layers, 1)
})

test_that("mark_bar supports layer-level data", {
  p <- plotit(iris, encode(x = Species)) |>
    mark_bar(data = iris[1:100, ])
  expect_s3_class(p, "plotit::plotit")
  expect_length(p@gg$layers, 1)
})

test_that("mark_bar supports fill mapping for stacking", {
  p <- plotit(iris, encode(x = Species, fill = Species)) |>
    mark_bar(position = "stack")
  expect_s3_class(p, "plotit::plotit")
})

# ---- mark_boxplot ----
test_that("mark_boxplot adds boxplot layer and returns plotit", {
  p <- plotit(iris, encode(x = Species, y = Sepal.Length))
  p2 <- mark_boxplot(p)
  expect_s3_class(p2, "plotit::plotit")
  expect_length(p2@gg$layers, 1)
})

test_that("mark_boxplot supports local data", {
  p <- plotit(iris, encode(x = Species, y = Sepal.Length))
  p2 <- mark_boxplot(p, data = iris[1:100, ])
  expect_s3_class(p2, "plotit::plotit")
})

# ---- dodge auto-injection ----
test_that("mark_bar auto-injects position_dodge with discrete x", {
  p <- plotit(iris, encode(x = Species, fill = Species)) |>
    mark_bar()
  pos <- p@gg$layers[[1]]$position
  expect_true(inherits(pos, "PositionDodge"))
})

test_that("mark_bar does not inject dodge with continuous x (dodge=0)", {
  p <- plotit(mtcars, encode(x = wt)) |>
    mark_bar()
  pos <- p@gg$layers[[1]]$position
  expect_true(inherits(pos, "PositionStack"))
})

test_that("mark_bar explicit position overrides global dodge", {
  p <- plotit(iris, encode(x = Species, fill = Species)) |>
    mark_bar(position = "stack")
  pos <- p@gg$layers[[1]]$position
  expect_false(inherits(pos, "PositionDodge"))
})

test_that("mark_bar explicit position_dodge(0.5) overrides global dodge", {
  p <- plotit(iris, encode(x = Species, fill = Species)) |>
    mark_bar(position = ggplot2::position_dodge(0.5))
  pos <- p@gg$layers[[1]]$position
  expect_true(inherits(pos, "PositionDodge"))
})

test_that("mark_boxplot auto-injects position_dodge with discrete x", {
  p <- plotit(iris, encode(x = Species, y = Sepal.Length, fill = Species)) |>
    mark_boxplot()
  pos <- p@gg$layers[[1]]$position
  expect_true(inherits(pos, "PositionDodge"))
})

test_that("mark_boxplot explicit position=\"dodge2\" overrides global dodge", {
  p <- plotit(iris, encode(x = Species, y = Sepal.Length, fill = Species)) |>
    mark_boxplot(position = "dodge2")
  pos <- p@gg$layers[[1]]$position
  # dodge2 inherits from PositionDodge → check for PositionDodge2 not PositionDodge
  expect_true(inherits(pos, "PositionDodge2"))
})

test_that("mark_point auto-injects position_dodge with discrete x", {
  p <- plotit(iris, encode(x = Species, y = Sepal.Length, colour = Species)) |>
    mark_point()
  pos <- p@gg$layers[[1]]$position
  expect_true(inherits(pos, "PositionDodge"))
})

test_that("mark_line auto-injects position_dodge with discrete x", {
  p <- plotit(iris, encode(x = Species, y = Sepal.Length, colour = Species)) |>
    mark_line()
  pos <- p@gg$layers[[1]]$position
  expect_true(inherits(pos, "PositionDodge"))
})

test_that("plotit() explicit dodge=0 suppresses dodge for all marks", {
  p <- plotit(iris, encode(x = Species, fill = Species), dodge = 0) |>
    mark_bar()
  pos <- p@gg$layers[[1]]$position
  expect_false(inherits(pos, "PositionDodge"))
})

test_that("bar with discrete y (no y mapping) also triggers dodge", {
  # Species is discrete → dodge heuristic returns 0.8
  p <- plotit(iris, encode(x = Species)) |>
    mark_bar()
  pos <- p@gg$layers[[1]]$position
  expect_true(inherits(pos, "PositionDodge"))
})

# ---- rasterize ----
test_that("rasterize default FALSE does not trigger ggrastr check", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  expect_no_error(mark_point(p))
})

test_that("rasterize=TRUE triggers ggrastr and renders without error", {
  skip_if_not_installed("ggrastr")
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
  expect_no_error(mark_point(p, rasterize = TRUE, rasterize_dpi = 72))
})

# ---- pipeline with mark ----
test_that("pipeline mark_point + scale + label does not crash", {
  p <- iris |>
    plotit(encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    mark_point(size = 2) |>
    scale_color(name = "Species") |>
    label_title("Test") |>
    style_default()
  expect_s3_class(p, "plotit::plotit")
})

test_that("pipeline mark_boxplot + scale_fill + label + project does not crash", {
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
  expect_s3_class(p, "plotit::plotit")
})
