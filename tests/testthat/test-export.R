# ============================================================
# export + print 测试 — 导出和打印
# ============================================================
library(plotit)

# ---- export ----
test_that("export() 可导出 PNG", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point()
  expect_no_error(export(p, tempfile(fileext = ".png"), dpi = 72))
})

test_that("export() 可导出 PDF", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point()
  expect_no_error(export(p, tempfile(fileext = ".pdf")))
})

test_that("export() 非法 filename 报错", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  expect_error(export(p, NULL), "filename")
  expect_error(export(p, ""), "filename")
})

test_that("export() 用户显式 width/height 覆盖 meta", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
    width = 6, height = 4, size_unit = "in"
  ) |>
    mark_point()
  expect_no_error(export(p, tempfile(fileext = ".png"),
    width = 8, height = 6, dpi = 72
  ))
})

# ---- export autofit ----
test_that("export() autofit=TRUE 基础导出", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
    autofit = TRUE
  ) |>
    mark_point()
  expect_no_error(export(p, tempfile(fileext = ".png"), dpi = 72))
})

test_that("export() autofit + 用户显式 width/height", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
    autofit = TRUE
  ) |>
    mark_point()
  f <- tempfile(fileext = ".png")
  expect_no_error(export(p, f, width = 10, height = 8, dpi = 72))
})

test_that("export() autofit + 用户只传 width", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
    autofit = TRUE
  ) |>
    mark_point()
  f <- tempfile(fileext = ".png")
  expect_no_error(export(p, f, width = 10, dpi = 72))
})

test_that("export() autofit + size_unit=cm 保留单位", {
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
test_that("print() 返回 plotit 对象（不可见）", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> mark_point()
  expect_s3_class(print(p), "plotit::plotit")
})

# ---- meta 尺寸字段 ----
test_that("plotit() 正确设置 meta 尺寸字段", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
    width = 10, height = 8, size_unit = "cm"
  )
  expect_equal(p@meta@width, 10)
  expect_equal(p@meta@height, 8)
  expect_equal(p@meta@unit, "cm")
})

test_that("autofit=TRUE 时 meta@unit 保留", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length),
    autofit = TRUE, size_unit = "cm"
  )
  expect_equal(p@meta@unit, "cm")
})

test_that("autofit=TRUE 时 meta@unit 默认为 in", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length), autofit = TRUE)
  expect_equal(p@meta@unit, "in")
})
