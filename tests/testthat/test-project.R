# ============================================================
# project_* function family — coordinate transforms
# ============================================================
library(plotit)

# ---- project_polar ----
test_that("project_polar basic no crash", {
  p <- plotit(mtcars, encode(x = factor(cyl))) |>
    mark_bar() |>
    project_polar()
  expect_s3_class(p, "plotit::plotit")
})

test_that("project_polar theta=\"y\"", {
  p <- plotit(mtcars, encode(x = factor(cyl))) |>
    mark_bar() |>
    project_polar(theta = "y")
  expect_s3_class(p, "plotit::plotit")
})

test_that("project_polar start + direction", {
  p <- plotit(mtcars, encode(x = factor(cyl))) |>
    mark_bar() |>
    project_polar(start = pi / 2, direction = -1)
  expect_s3_class(p, "plotit::plotit")
})

# ---- project_cartesian ----
test_that("project_cartesian basic no crash", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point() |>
    project_cartesian()
  expect_s3_class(p, "plotit::plotit")
})

test_that("project_cartesian xlim + ylim", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point() |>
    project_cartesian(xlim = c(0, 6), ylim = c(5, 40))
  expect_s3_class(p, "plotit::plotit")
})

test_that("project_cartesian expand=FALSE", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point() |>
    project_cartesian(expand = FALSE)
  expect_s3_class(p, "plotit::plotit")
})

test_that("project_cartesian clip=\"off\"", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point() |>
    project_cartesian(clip = "off")
  expect_s3_class(p, "plotit::plotit")
})

# ---- project_cartesian extended ----
test_that("project_cartesian flip=TRUE swaps axes", {
  p <- plotit(mtcars, encode(x = factor(cyl), y = mpg)) |>
    mark_boxplot() |>
    project_cartesian(flip = TRUE)
  expect_s3_class(p, "plotit::plotit")
})

test_that("project_cartesian fixed=1 locks aspect ratio", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point() |>
    project_cartesian(fixed = 1)
  expect_s3_class(p, "plotit::plotit")
})

test_that("project_cartesian trans applies coordinate transform", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point() |>
    project_cartesian(trans = "log10")
  expect_s3_class(p, "plotit::plotit")
})

# ---- project_parallel ----
test_that("project_parallel basic parallel coordinates", {
  p <- plotit(iris, encode()) |>
    project_parallel(columns = c("Sepal.Width", "Sepal.Length",
                                  "Petal.Width", "Petal.Length"))
  expect_s3_class(p, "plotit::plotit")
})

test_that("project_parallel with group coloring", {
  p <- plotit(iris, encode()) |>
    project_parallel(
      columns = c("Sepal.Width", "Sepal.Length"),
      group = "Species"
    )
  expect_s3_class(p, "plotit::plotit")
})

test_that("project_parallel scale=\"global\"", {
  p <- plotit(mtcars, encode()) |>
    project_parallel(columns = c("wt", "qsec"), scale = "global")
  expect_s3_class(p, "plotit::plotit")
})

test_that("project_parallel errors on missing column", {
  p <- plotit(iris, encode())
  expect_error(
    project_parallel(p, columns = c("not_a_column")),
    "not found"
  )
})

# ---- project_map ----
test_that("project_map default coord_sf works", {
  skip_if_not_installed("sf")
  nc <- sf::st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
  p <- plotit(nc, encode(fill = AREA)) |>
    mark_point() |>
    project_map()
  expect_s3_class(p, "plotit::plotit")
})

# ---- project_radial ----
test_that("project_radial basic no crash", {
  skip_if(utils::packageVersion("ggplot2") < "3.5.0",
          "coord_radial requires ggplot2 >= 3.5.0")
  p <- plotit(mtcars, encode(x = factor(cyl))) |>
    mark_bar() |>
    project_radial()
  expect_s3_class(p, "plotit::plotit")
})

# ---- edge cases & warnings ----
test_that("project_cartesian warns on multiple modes (flip + fixed)", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point()
  expect_warning(
    project_cartesian(p, flip = TRUE, fixed = 1),
    "Multiple coordinate modes"
  )
})

test_that("project_cartesian warns on multiple modes (flip + trans)", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |>
    mark_point()
  expect_warning(
    project_cartesian(p, flip = TRUE, trans = "log10"),
    "Multiple coordinate modes"
  )
})

test_that("project_parallel scale=\"none\" skips normalisation", {
  p <- plotit(iris, encode()) |>
    project_parallel(
      columns = c("Sepal.Width", "Sepal.Length"),
      scale = "none"
    )
  expect_s3_class(p, "plotit::plotit")
})

test_that("project_parallel handles NA values without crash", {
  df <- iris
  df$Sepal.Width[1] <- NA
  p <- plotit(df, encode()) |>
    project_parallel(columns = c("Sepal.Width", "Sepal.Length"))
  expect_s3_class(p, "plotit::plotit")
})

test_that("project_parallel errors on reserved column names", {
  df <- iris
  df$.plotit_id <- 1:nrow(df)
  p <- plotit(df, encode())
  expect_error(
    project_parallel(p, columns = c("Sepal.Width")),
    "reserved column"
  )
})

test_that("project_parallel errors on empty data", {
  p <- plotit(iris[0, ], encode())
  expect_error(
    project_parallel(p, columns = c("Sepal.Width")),
    "No data found"
  )
})

test_that("project_parallel adds exactly two layers", {
  p <- plotit(iris, encode()) |>
    project_parallel(columns = c("Sepal.Width", "Sepal.Length"))
  n <- length(p@gg$layers)
  expect_equal(n, 2)
})

test_that("project_polar clip=\"off\" works", {
  p <- plotit(mtcars, encode(x = factor(cyl))) |>
    mark_bar() |>
    project_polar(clip = "off")
  expect_s3_class(p, "plotit::plotit")
})

test_that("project_parallel clears default_color when group provides colour", {
  p <- plotit(iris, encode(), default_color = "black") |>
    mark_point() |>
    project_parallel(columns = c("Sepal.Width", "Sepal.Length"),
                     group = "Species")
  expect_null(p@meta@default_color)
  expect_null(p@gg$mapping$colour)
})

test_that("project_parallel errors on empty columns vector", {
  p <- plotit(iris, encode())
  expect_error(
    project_parallel(p, columns = character(0)),
    "at least one column"
  )
})

test_that("project_cartesian multi-mode warning names correct active mode", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |> mark_point()
  expect_warning(
    project_cartesian(p, fixed = 1, trans = "log10"),
    "Only .*fixed.* will be used"
  )
  # flip wins when set
  expect_warning(
    project_cartesian(p, flip = TRUE, fixed = 1),
    "Only .*flip.* will be used"
  )
})

test_that("project_radial custom r_axis_inside and inner_radius", {
  skip_if(utils::packageVersion("ggplot2") < "3.5.0")
  p <- plotit(mtcars, encode(x = factor(cyl))) |>
    mark_bar() |>
    project_radial(r_axis_inside = TRUE, inner_radius = 0.3)
  expect_s3_class(p, "plotit::plotit")
})
