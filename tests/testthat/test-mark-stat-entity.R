# ============================================================
# Statistical entity matrix (D-01, design/03 §2) -- BDD tests
# mark_errorbar(stat=) + mark_ribbon
# AGENTS.md 4.8
# ============================================================
library(plotit)

# Fixed sample (n = 10); expected interval endpoints were computed once
# with base R and are asserted to 1e-8.
stat_y <- c(5.1, 4.9, 5.3, 5.0, 5.2, 4.8, 5.4, 5.1, 4.7, 5.0)
stat_df <- data.frame(group = rep("A", 10), y = stat_y)

grab_interval <- function(p) {
  b <- ggplot2::ggplot_build(p@gg)
  d <- b$data[[length(b$data)]]
  d[1, c("y", "ymin", "ymax")]
}

# ---- mark_errorbar stat entities ----
test_that("[BDD] mark_errorbar stat=mean_sem asserts exact sem half-width", {
  p <- plotit(stat_df, encode(x = group, y = y)) |>
    mark_errorbar(stat = "mean_sem")
  d <- grab_interval(p)
  expect_equal(d$ymin, 4.9812815729, tolerance = 1e-8)
  expect_equal(d$ymax, 5.1187184271, tolerance = 1e-8)
  expect_equal(d$y, mean(stat_y), tolerance = 1e-8)
})

test_that("[BDD] mark_errorbar stat=mean_sd asserts exact sd half-width", {
  p <- plotit(stat_df, encode(x = group, y = y)) |>
    mark_errorbar(stat = "mean_sd")
  d <- grab_interval(p)
  expect_equal(d$ymin, 4.8326932532, tolerance = 1e-8)
  expect_equal(d$ymax, 5.2673067468, tolerance = 1e-8)
})

test_that("[BDD] mark_errorbar stat=mean_range spans min/max", {
  p <- plotit(stat_df, encode(x = group, y = y)) |>
    mark_errorbar(stat = "mean_range")
  d <- grab_interval(p)
  expect_equal(d$ymin, 4.7, tolerance = 1e-8)
  expect_equal(d$ymax, 5.4, tolerance = 1e-8)
})

test_that("[BDD] mark_errorbar stat=mean_ci95 asserts exact t half-width", {
  p <- plotit(stat_df, encode(x = group, y = y)) |>
    mark_errorbar(stat = "mean_ci95")
  d <- grab_interval(p)
  expect_equal(d$ymin, 4.8945481179, tolerance = 1e-8)
  expect_equal(d$ymax, 5.2054518821, tolerance = 1e-8)
})

test_that("[BDD] mark_errorbar stat=mean_ci95 level=0.9 widens vs narrows", {
  p95 <- grab_interval(plotit(stat_df, encode(x = group, y = y)) |>
    mark_errorbar(stat = "mean_ci95"))
  p90 <- grab_interval(plotit(stat_df, encode(x = group, y = y)) |>
    mark_errorbar(stat = "mean_ci95", level = 0.9))
  expect_gt(p95$ymax - p95$ymin, p90$ymax - p90$ymin)
})

test_that("[BDD] mark_errorbar boot path is reproducible with seed=1", {
  mk <- function() {
    grab_interval(plotit(stat_df, encode(x = group, y = y)) |>
      mark_errorbar(stat = "mean_ci95", ci_method = "boot", seed = 1))
  }
  b1 <- mk()
  b2 <- mk()
  expect_identical(b1$ymin, b2$ymin)
  expect_identical(b1$ymax, b2$ymax)
  # bootstrap percentile CI stays near the normal CI (loose sanity band)
  expect_gt(b1$ymin, 4.6)
  expect_lt(b1$ymax, 5.5)
})

test_that("[BDD] mark_errorbar stat entities validate parameters", {
  p <- plotit(stat_df, encode(x = group, y = y))
  expect_error(mark_errorbar(p, stat = "bogus"), "must be one of")
  expect_error(mark_errorbar(p, stat = "mean_ci95", level = 1.2), "level")
  expect_error(
    mark_errorbar(p, stat = "mean_ci95", ci_method = "boot"),
    "seed"
  )
  # seed without boot is ignored with a warning
  expect_warning(
    mark_errorbar(p, stat = "mean_sem", seed = 5),
    "ignored"
  )
})

# ---- mark_ribbon ----
test_that("[BDD] mark_ribbon identity mode renders ymin/ymax band", {
  band <- data.frame(
    x = 1:5, ymin = c(1, 2, 3, 4, 5), ymax = c(3, 4, 5, 6, 7)
  )
  p <- plotit(band, encode(x = x, ymin = ymin, ymax = ymax)) |>
    mark_ribbon()
  b <- ggplot2::ggplot_build(p@gg)
  expect_true(inherits(p@gg$layers[[1]]$geom, "GeomRibbon"))
  expect_equal(b$data[[1]]$ymin, band$ymin)
  expect_equal(b$data[[1]]$ymax, band$ymax)
})

test_that("[BDD] mark_ribbon stat=mean_sem matches errorbar interval", {
  pr <- plotit(stat_df, encode(x = group, y = y)) |>
    mark_ribbon(stat = "mean_sem")
  pe <- plotit(stat_df, encode(x = group, y = y)) |>
    mark_errorbar(stat = "mean_sem")
  dr <- grab_interval(pr)
  de <- grab_interval(pe)
  expect_equal(dr$ymin, de$ymin, tolerance = 1e-8)
  expect_equal(dr$ymax, de$ymax, tolerance = 1e-8)
})

test_that("[BDD] mark_ribbon default alpha uses the alpha_ci token", {
  band <- data.frame(x = 1:3, ymin = 1:3, ymax = 2:4)
  p <- plotit(band, encode(x = x, ymin = ymin, ymax = ymax)) |>
    mark_ribbon()
  expect_equal(p@gg$layers[[1]]$stat_params$alpha %||% p@gg$layers[[1]]$aes_params$alpha,
    0.25)
  p2 <- plotit(band, encode(x = x, ymin = ymin, ymax = ymax)) |>
    mark_ribbon(alpha = 0.5)
  expect_equal(
    p2@gg$layers[[1]]$stat_params$alpha %||% p2@gg$layers[[1]]$aes_params$alpha,
    0.5
  )
})

test_that("[BDD] spaghetti + mean/sem overlay renders end to end", {
  set.seed(7)
  raw <- data.frame(
    group = rep(c("ctl", "trt"), each = 12),
    y = c(rnorm(12, 5), rnorm(12, 6))
  )
  p <- plotit(raw, encode(x = group, y = y, colour = group)) |>
    mark_point(alpha = 0.4) |>
    mark_errorbar(stat = "mean_sem", colour = "grey30") |>
    mark_ribbon(stat = "mean_ci95", colour = NA)
  b <- ggplot2::ggplot_build(p@gg)
  expect_equal(length(b$data), 3)
})

# ---- B5: force-layout canvas margin (design/03 §5.4) ----
test_that("[BDD] layout_force keeps nodes inside the 10 percent canvas margin", {
  set.seed(1)
  edges <- data.frame(
    source = sample(LETTERS[1:30], 60, replace = TRUE),
    target = sample(LETTERS[1:30], 60, replace = TRUE)
  )
  edges <- edges[edges$source != edges$target, ]
  g <- as_graph(edges) |> layout_force(seed = 1)
  expect_gte(min(g$nodes$x), 0.05 - 1e-9)
  expect_lte(max(g$nodes$x), 0.95 + 1e-9)
  expect_gte(min(g$nodes$y), 0.05 - 1e-9)
  expect_lte(max(g$nodes$y), 0.95 + 1e-9)
})

# ---- B3: polygon default fill is the brand primary (design/03 §5.3) ----
test_that("[BDD] mark_polygon without fill mapping wears the brand primary", {
  tri <- data.frame(x = c(0, 1, 0.5), y = c(0, 0, 1))
  p <- plotit(tri, encode(x = x, y = y)) |> mark_polygon()
  b <- ggplot2::ggplot_build(p@gg)
  expect_identical(unique(b$data[[1]]$fill), "#4E79A7")
})
