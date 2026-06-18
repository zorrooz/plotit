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
