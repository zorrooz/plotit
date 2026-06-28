# ============================================================
# ._sync_labels() integration tests (TE-2)
# Verify that lazy labels are correctly synced to gg at
# print()/export() time, producing identical output to
# direct gg modification.
# ============================================================
library(plotit)

# ---- helpers ----
.sync <- function(p) plotit:::._sync_labels(p)

# ---- basic sync: text labels ----
test_that("[BDD] ._sync_labels applies title to gg$labels", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_title("Synced Title")
  p <- .sync(p)
  built <- ggplot2::ggplot_build(p@gg)
  expect_equal(built$plot$labels$title, "Synced Title")
})

test_that("[BDD] ._sync_labels applies subtitle and caption", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_subtitle("Sub") |>
    label_caption("Cap")
  p <- .sync(p)
  built <- ggplot2::ggplot_build(p@gg)
  expect_equal(built$plot$labels$subtitle, "Sub")
  expect_equal(built$plot$labels$caption, "Cap")
})

# ---- basic sync: axis labels ----
test_that("[BDD] ._sync_labels applies axis labels", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_axis("X Label", aes = "x") |>
    label_axis("Y Label", aes = "y")
  p <- .sync(p)
  built <- ggplot2::ggplot_build(p@gg)
  expect_equal(built$plot$labels$x, "X Label")
  expect_equal(built$plot$labels$y, "Y Label")
})

# ---- chained labels ----
test_that("[BDD] ._sync_labels applies all label slots simultaneously", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_title("T") |>
    label_subtitle("S") |>
    label_caption("C") |>
    label_axis("X", aes = "x") |>
    label_axis("Y", aes = "y")
  p <- .sync(p)
  built <- ggplot2::ggplot_build(p@gg)
  expect_equal(built$plot$labels$title, "T")
  expect_equal(built$plot$labels$subtitle, "S")
  expect_equal(built$plot$labels$caption, "C")
  expect_equal(built$plot$labels$x, "X")
  expect_equal(built$plot$labels$y, "Y")
})

# ---- hide behaviour after sync ----
test_that("[BDD] ._sync_labels hide=TRUE creates element_blank in theme", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_title("Visible") |>
    label_title(hide = TRUE)
  p <- .sync(p)
  built <- ggplot2::ggplot_build(p@gg)
  expect_true(inherits(built$plot$theme$plot.title, "element_blank"))
})

test_that("[BDD] ._sync_labels axis hide=TRUE creates element_blank", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_axis(hide = TRUE, aes = "x")
  p <- .sync(p)
  built <- ggplot2::ggplot_build(p@gg)
  expect_true(inherits(built$plot$theme$axis.title.x, "element_blank"))
})

# ---- reset behaviour after sync ----
test_that("[BDD] ._sync_labels reset=TRUE removes label from gg$labels", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_title("Custom") |>
    label_title(reset = TRUE)
  p <- .sync(p)
  built <- ggplot2::ggplot_build(p@gg)
  expect_null(built$plot$labels$title)
})

test_that("[BDD] ._sync_labels axis reset restores variable name", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_axis("Custom", aes = "x") |>
    label_axis(reset = TRUE, aes = "x")
  p <- .sync(p)
  built <- ggplot2::ggplot_build(p@gg)
  expect_equal(built$plot$labels$x, "Sepal.Width")
})

# ---- export triggers sync implicitly ----
test_that("[BDD] export() triggers ._sync_labels implicitly", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_title("Export Sync") |>
    label_subtitle("via export()")
  f <- tempfile(fileext = ".png")
  expect_no_error(export(p, f, dpi = 72))
  expect_true(file.exists(f))
  unlink(f)
})

# ---- labels are NOT synced before print/export ----
test_that("[BDD] labels NOT applied to gg before sync", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_title("Deferred Title")
  # Before sync, gg$labels$title should not have the deferred value
  built <- ggplot2::ggplot_build(p@gg)
  expect_null(built$plot$labels$title)
})

# ---- re-sync after label change produces updated output ----
test_that("[BDD] re-sync after label change updates gg", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
    mark_point() |>
    label_title("First")
  p <- .sync(p)
  built1 <- ggplot2::ggplot_build(p@gg)
  expect_equal(built1$plot$labels$title, "First")

  p <- label_title(p, "Second")
  p <- .sync(p)
  built2 <- ggplot2::ggplot_build(p@gg)
  expect_equal(built2$plot$labels$title, "Second")
})

# ---- legend sync ----
test_that("[BDD] ._sync_labels applies legend title", {
  p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
    mark_point() |>
    label_legend("Iris Species", aes = "colour")
  p <- .sync(p)
  built <- ggplot2::ggplot_build(p@gg)
  expect_equal(built$plot$labels$colour, "Iris Species")
})
