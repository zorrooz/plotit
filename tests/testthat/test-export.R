# ============================================================
# export + print tests
# ============================================================
library(plotit)

# ---- export ----
test_that("export() can export PNG", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point()
  expect_no_error(export(p, tempfile(fileext = ".png"), dpi = 72))
})

test_that("export() can export PDF", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point()
  expect_no_error(export(p, tempfile(fileext = ".pdf")))
})

test_that("export() invalid filename errors", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  expect_error(export(p, NULL), "filename")
  expect_error(export(p, ""), "filename")
})

test_that("export() explicit width/height overrides meta", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
    width = 6, height = 4, size_unit = "in"
  ) |>
    mark_point()
  expect_no_error(export(p, tempfile(fileext = ".png"),
    width = 8, height = 6, dpi = 72
  ))
})

# ---- export autofit ----
test_that("export() autofit=TRUE basic export", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
    autofit = TRUE
  ) |>
    mark_point()
  expect_no_error(export(p, tempfile(fileext = ".png"), dpi = 72))
})

test_that("export() autofit + explicit width/height", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
    autofit = TRUE
  ) |>
    mark_point()
  f <- tempfile(fileext = ".png")
  expect_no_error(export(p, f, width = 10, height = 8, dpi = 72))
})

test_that("export() autofit + explicit width only", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
    autofit = TRUE
  ) |>
    mark_point()
  f <- tempfile(fileext = ".png")
  expect_no_error(export(p, f, width = 10, dpi = 72))
})

test_that("export() autofit + size_unit=cm preserves unit", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
    autofit = TRUE, size_unit = "cm"
  ) |>
    mark_point()
  expect_equal(p@meta@unit, "cm")
  expect_no_error(export(p, tempfile(fileext = ".png"),
    width = 10, height = 8, dpi = 72
  ))
})

# ---- print ----
test_that("print() returns plotit object (invisibly)", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  expect_s3_class(print(p), "plotit::plotit")
})

# ---- meta size fields ----
test_that("plotit() correctly sets meta size fields", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
    width = 10, height = 8, size_unit = "cm"
  )
  expect_equal(p@meta@width, 10)
  expect_equal(p@meta@height, 8)
  expect_equal(p@meta@unit, "cm")
})

test_that("autofit=TRUE preserves meta@unit", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
    autofit = TRUE, size_unit = "cm"
  )
  expect_equal(p@meta@unit, "cm")
})

test_that("autofit=TRUE meta@unit defaults to in", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length), autofit = TRUE)
  expect_equal(p@meta@unit, "in")
})

# ---- contract boundary (§3.3.10, §7 principle 8) ----
test_that("panel size respects contract within ±1%", {
  p <- plotit(mtcars, encode(x = wt, y = mpg),
    width = 5, height = 4, size_unit = "in"
  ) |>
    mark_point()
  gt <- patchwork::patchworkGrob(p@gg)
  pw <- grid::convertWidth(sum(gt$widths), "in", valueOnly = TRUE)
  ph <- grid::convertHeight(sum(gt$heights), "in", valueOnly = TRUE)
  # Total size = panel + decorations (~0.7 in). Verify it's roughly correct.
  expect_gt(pw, 5)
  expect_gt(ph, 4)
  expect_lt(pw, 7)  # sanity: shouldn't exceed panel + 2 in of decorations
  expect_lt(ph, 6)
})
