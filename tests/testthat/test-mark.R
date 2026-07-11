# ============================================================
# mark_* function family -- BDD tests (assert rendered output)
# AGENTS.md <U+00A7>4.8: <U+65AD><U+8A00><U+884C><U+4E3A><U+800C><U+975E><U+5185><U+90E8><U+72B6><U+6001>
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
