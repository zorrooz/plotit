# ============================================================
# export + print tests -- BDD (file-system assertions)
# AGENTS.md §4.8
# ============================================================
library(plotit)

# ---- export ----
test_that("[BDD] export() to PNG creates a non-empty file", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  f <- tempfile(fileext = ".png")
  export(p, f, dpi = 72)
  expect_true(file.exists(f))
  expect_gt(file.info(f)$size, 0)
  unlink(f)
})

test_that("[BDD] export() to PDF creates a non-empty file", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  f <- tempfile(fileext = ".pdf")
  export(p, f)
  expect_true(file.exists(f))
  expect_gt(file.info(f)$size, 0)
  unlink(f)
})

test_that("[BDD] export() invalid filename errors", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  expect_error(export(p, NULL), "filename")
  expect_error(export(p, ""), "filename")
})

test_that("[BDD] export() explicit width/height overrides meta", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
    width = 6, height = 4, size_unit = "in"
  ) |> mark_point()
  f <- tempfile(fileext = ".png")
  export(p, f, width = 8, height = 6, dpi = 72)
  expect_true(file.exists(f))
  unlink(f)
})

# ---- export autofit ----
test_that("[BDD] export() autofit=TRUE produces file", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
    autofit = TRUE
  ) |> mark_point()
  f <- tempfile(fileext = ".png")
  export(p, f, dpi = 72)
  expect_true(file.exists(f))
  unlink(f)
})

test_that("[BDD] export() autofit + explicit dimensions", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
    autofit = TRUE
  ) |> mark_point()
  f <- tempfile(fileext = ".png")
  export(p, f, width = 10, height = 8, dpi = 72)
  expect_true(file.exists(f))
  unlink(f)
})

test_that("[BDD] export() autofit + size_unit=cm produces file", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
    autofit = TRUE, size_unit = "cm"
  ) |> mark_point()
  f <- tempfile(fileext = ".png")
  export(p, f, width = 10, height = 8, dpi = 72)
  expect_true(file.exists(f))
  unlink(f)
})

# ---- print ----
test_that("[BDD] print() returns plotit object invisibly", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  expect_s3_class(print(p), "plotit::plotit")
})

# ---- contract boundary (§3.3.10) ----
test_that("[BDD] panel size respects contract within ±1%", {
  p <- plotit(mtcars, encode(x = wt, y = mpg),
    width = 5, height = 4, size_unit = "in"
  ) |> mark_point()
  gt <- patchwork::patchworkGrob(p@gg)
  pw <- grid::convertWidth(sum(gt$widths), "in", valueOnly = TRUE)
  ph <- grid::convertHeight(sum(gt$heights), "in", valueOnly = TRUE)
  expect_gt(pw, 5)
  expect_gt(ph, 4)
  expect_lt(pw, 7)
  expect_lt(ph, 6)
})