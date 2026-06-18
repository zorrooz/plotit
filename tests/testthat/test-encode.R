library(plotit)

test_that("encode() creates a plotit_encode object", {
  # basic usage
  e <- encode(x = mpg, y = wt)
  expect_s3_class(e, "plotit_encode")
  expect_true(is.call(e$x))
  expect_true(is.call(e$y))
  expect_null(e$colour)

  # with colour mapping
  e2 <- encode(x = mpg, y = wt, colour = cyl)
  expect_true(is.call(e2$colour))

  # empty call
  e3 <- encode()
  expect_true(is.list(e3))
})
