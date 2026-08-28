# ============================================================
# mark_image (D-02, design/03 §3) -- BDD tests
# AGENTS.md 4.8
# ============================================================
library(plotit)

make_png <- function(col = c(0.2, 0.4, 0.8)) {
  skip_if_not_installed("png")
  f <- tempfile(fileext = ".png")
  png::writePNG(array(col, dim = c(4, 4, 3)), f)
  f
}

test_that("[BDD] mark_image renders one image grob per row from a png file", {
  f_png <- make_png()
  df <- data.frame(x = c(1, 2), y = c(1, 2), src = f_png)
  p <- plotit(df, encode(x = x, y = y, src = src)) |>
    mark_image(size = 0.2)
  expect_s3_class(p, "plotit::plotit")
  b <- ggplot2::ggplot_build(p@gg)
  expect_equal(nrow(b$data[[1]]), 2)
  expect_true(inherits(p@gg$layers[[1]]$geom, "GeomPlotitImage"))
})

test_that("[BDD] mark_image drops rows with NA or empty src", {
  f_png <- make_png()
  df <- data.frame(
    x = c(1, 2, 3), y = c(1, 2, 3),
    src = c(f_png, NA_character_, "")
  )
  p <- plotit(df, encode(x = x, y = y, src = src)) |> mark_image()
  b <- ggplot2::ggplot_build(p@gg)
  # build keeps rows; the draw layer drops the two bad ones
  expect_no_error(ggplot2::ggplot_gtable(b))
})

test_that("[BDD] mark_image accepts raster arrays without extra packages", {
  arr <- array(c(0.1, 0.5, 0.9), dim = c(2, 2, 3))
  df2 <- data.frame(x = 1, y = 1, src = I(list(arr)))
  p2 <- plotit(df2, encode(x = x, y = y, src = src)) |> mark_image()
  expect_no_error(ggplot2::ggplot_build(p2@gg))
})

test_that("[BDD] mark_image clip=circle renders and bad clip/size abort", {
  f_png <- make_png()
  df <- data.frame(x = 1, y = 1, src = f_png)
  p <- plotit(df, encode(x = x, y = y, src = src)) |>
    mark_image(clip = "circle", size = 0.3)
  expect_no_error(ggplot2::ggplot_build(p@gg))
  expect_error(mark_image(p, clip = "oval"), "must be one of")
  expect_error(mark_image(p, size = 2), "size")
  expect_error(mark_image(p, size = -1), "size")
})

test_that("[BDD] mark_image rejects unknown file types with legal values", {
  txt <- tempfile(fileext = ".txt")
  writeLines("not an image", txt)
  df <- data.frame(x = 1, y = 1, src = txt)
  p <- plotit(df, encode(x = x, y = y, src = src)) |> mark_image()
  # the src is decoded at draw time, so the error surfaces on gtable build
  expect_error(
    ggplot2::ggplot_gtable(ggplot2::ggplot_build(p@gg)),
    "must be one of"
  )
})

test_that("[BDD] mark_image raster embeds in SVG export", {
  skip_if_not_installed("svglite")
  f_png <- make_png()
  df <- data.frame(x = 1, y = 1, src = f_png)
  p <- plotit(df, encode(x = x, y = y, src = src)) |> mark_image()
  out <- tempfile(fileext = ".svg")
  export(p, out)
  svg <- paste(readLines(out, warn = FALSE), collapse = "\n")
  expect_true(grepl("base64", svg, fixed = TRUE))
  unlink(out)
})
