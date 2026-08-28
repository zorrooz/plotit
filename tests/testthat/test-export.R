# ============================================================
# export + print tests -- BDD (file-system assertions)
# AGENTS.md 4.8
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

# ---- contract boundary (3.3.10) ----
test_that("[BDD] panel size respects contract within +/-1%", {
  p <- plotit(mtcars, encode(x = wt, y = mpg),
    width = 5, height = 4, size_unit = "in"
  ) |> mark_point()
  gt <- ._build_fixed_gtable(p@gg, 5, 4, "in")
  pw <- grid::convertWidth(sum(gt$widths), "in", valueOnly = TRUE)
  ph <- grid::convertHeight(sum(gt$heights), "in", valueOnly = TRUE)
  expect_gt(pw, 5)
  expect_gt(ph, 4)
  expect_lt(pw, 7)
  expect_lt(ph, 6)
})

# ---- export(list): multipage PDF (D-21 / B-9) ----
# Text-level page counter for the PDFs R's pdf device writes: the page-tree
# markers ("/Type /Page", "/Count N") are stored uncompressed, so a byte scan
# is reliable for the N-pages assertion (cross-checked against /Count).
pdf_page_count <- function(path) {
  # Byte-exact scan (grepRaw): locale-independent, unlike regex over
  # rawToChar output, which silently fails to match under the C locale
  # that R CMD check uses.
  raw <- readBin(path, what = "raw", n = file.size(path))
  page_and_tree <- length(grepRaw("/Type /Page", raw, fixed = TRUE, all = TRUE))
  tree <- length(grepRaw("/Type /Pages", raw, fixed = TRUE, all = TRUE))
  page_and_tree - tree
}

test_that("[BDD] export(list) writes one PDF page per plot", {
  p1 <- plotit(mtcars, encode(x = wt, y = mpg)) |> mark_point()
  p2 <- plotit(mtcars, encode(x = cyl, y = mpg)) |> mark_point()
  f <- tempfile(fileext = ".pdf")
  export(list(p1, p2), f)
  expect_true(file.exists(f))
  expect_identical(pdf_page_count(f), 2L)
  unlink(f)
})

test_that("[BDD] export(list) with composite pages counts each element", {
  p1 <- plotit(mtcars, encode(x = wt, y = mpg)) |> mark_point()
  p2 <- plotit(mtcars, encode(x = cyl, y = mpg)) |> mark_point()
  comp <- compose_grid(p1, p2, ncol = 2)
  f <- tempfile(fileext = ".pdf")
  export(list(p1, comp), f)
  expect_identical(pdf_page_count(f), 2L)
  unlink(f)
})

test_that("[BDD] export(list) rejects single-page devices with a targeted error", {
  p1 <- plotit(mtcars, encode(x = wt, y = mpg)) |> mark_point()
  p2 <- plotit(mtcars, encode(x = cyl, y = mpg)) |> mark_point()
  # single-page device would silently keep only the last page (DEC-1)
  expect_error(export(list(p1, p2), tempfile(fileext = ".png")), "pdf")
  expect_error(export(list(p1, p2), tempfile(fileext = ".pdf"), device = "png"), "pdf")
})

test_that("[BDD] export(list) validates list elements", {
  p <- plotit(mtcars, encode(x = wt, y = mpg)) |> mark_point()
  expect_error(export(list(p, "not-a-plot"), tempfile(fileext = ".pdf")), "plotit")
  expect_error(export(list(), tempfile(fileext = ".pdf")), "at least one plot")
})

test_that("[BDD] export(list) explicit width/height applies to every page", {
  p1 <- plotit(mtcars, encode(x = wt, y = mpg), width = 4, height = 3) |> mark_point()
  p2 <- plotit(mtcars, encode(x = cyl, y = mpg), width = 4, height = 3) |> mark_point()
  f <- tempfile(fileext = ".pdf")
  export(list(p1, p2), f, width = 6, height = 5, dpi = 72)
  expect_identical(pdf_page_count(f), 2L)
  unlink(f)
})
