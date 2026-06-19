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

# ---- project_flip ----
test_that("project_flip flips coordinates", {
  p <- plotit(mtcars, encode(x = factor(cyl), y = mpg)) |>
    mark_boxplot() |>
    project_flip()
  expect_s3_class(p, "plotit::plotit")
})

test_that("project_flip xlim", {
  p <- plotit(mtcars, encode(x = factor(cyl), y = mpg)) |>
    mark_boxplot() |>
    project_flip(xlim = c(5, 40))
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
