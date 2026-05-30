test_that("encode() creates a plotit_encode object", {
  # 基础用法
  e <- encode(x = mpg, y = wt)
  expect_s3_class(e, "plotit_encode")
  expect_true(is.call(e$x))
  expect_true(is.call(e$y))
  expect_null(e$colour)

  # 带颜色映射
  e2 <- encode(x = mpg, y = wt, colour = cyl)
  expect_true(is.call(e2$colour))

  # 空调用
  e3 <- encode()
  expect_true(is.list(e3))
  expect_named(e3, NULL) # 空列表
})
