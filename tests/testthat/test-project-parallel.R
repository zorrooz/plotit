# ============================================================
# project_parallel redo (D-13, design/05 §4) -- BDD tests
# AGENTS.md 4.8
# ============================================================
library(plotit)

pp_df <- data.frame(
  a = c(1, 2, 3, 4),
  b = c(4, 3, 2, 1),
  c = c(2, 3, 5, 7),
  grp = rep(c("X", "Y"), each = 2)
)

test_that("[BDD] project_parallel defaults to the numeric columns", {
  p <- plotit(pp_df, encode()) |> project_parallel()
  b <- ggplot2::ggplot_build(p@gg)
  # axis labels a/b/c in data order
  labs <- as.character(b$layout$panel_scales$x$get_labels())
  expect_identical(labs, c("a", "b", "c"))
})

test_that("[BDD] project_parallel order reorders and drops axes", {
  p <- plotit(pp_df, encode()) |>
    project_parallel(columns = c("a", "b", "c"), order = c("c", "a"))
  b <- ggplot2::ggplot_build(p@gg)
  labs <- as.character(b$layout$panel_scales$x$get_labels())
  expect_identical(labs, c("c", "a"))
  expect_error(
    plotit(pp_df, encode()) |> project_parallel(order = c("nope")),
    "must be a subset"
  )
})

test_that("[BDD] project_parallel recenter flattens the reference axis to zero", {
  p <- plotit(pp_df, encode()) |>
    project_parallel(columns = c("a", "b", "c"), recenter = "a")
  b <- ggplot2::ggplot_build(p@gg)
  # line layer: all values on the reference axis are exactly 0
  d <- b$data[[1]]
  pos_a <- d$x == 1 # first discrete position = reference axis
  expect_equal(max(abs(d$y[pos_a])), 0, tolerance = 1e-12)
  # other axes carry non-zero differences
  expect_gt(max(abs(d$y[d$x == 2])), 0.01)
})

test_that("[BDD] project_parallel aggregate draws one thick line per group", {
  p <- plotit(pp_df, encode()) |>
    project_parallel(columns = c("a", "b"), group = "grp",
                     aggregate = "mean")
  b <- ggplot2::ggplot_build(p@gg)
  expect_gte(length(b$data), 3) # individual lines + points + aggregate
  agg <- b$data[[3]]
  expect_equal(length(unique(agg$group)), 2) # one aggregate line per group
  # median form runs
  p2 <- plotit(pp_df, encode()) |>
    project_parallel(columns = c("a", "b"), group = "grp",
                     aggregate = "median")
  expect_no_error(ggplot2::ggplot_build(p2@gg))
})

test_that("[BDD] project_parallel axis_labels=FALSE blanks the labels", {
  p <- plotit(pp_df, encode()) |>
    project_parallel(columns = c("a", "b", "c"), axis_labels = FALSE)
  thm <- ggplot2::ggplot_build(p@gg)$plot$theme
  expect_s3_class(thm$axis.text.x, "element_blank")
})

test_that("[BDD] project_parallel three modes x aggregate smoke", {
  for (sc in c("std", "global", "none")) {
    p <- plotit(pp_df, encode()) |>
      project_parallel(columns = c("a", "b", "c"), scale = sc,
                       group = "grp", aggregate = "mean")
    expect_no_error(ggplot2::ggplot_build(p@gg))
  }
})
