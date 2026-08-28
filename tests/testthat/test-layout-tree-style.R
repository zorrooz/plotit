# ============================================================
# layout_tree style parameters (D-16, design/07 <U+00A7>2) -- BDD tests
# AGENTS.md 4.8
# ============================================================
library(plotit)

mk_tree <- function() {
  h <- data.frame(
    id = c("root", "A", "B", "C", "a1", "a2", "a3", "b1"),
    parent = c(NA, "root", "root", "root", "A", "A", "A", "B")
  )
  as_graph(h)
}

test_that("[BDD] layout_tree equal mode spaces leaves in an arithmetic sequence", {
  g <- mk_tree() |> layout_tree(direction = "down", leaf_spacing = "equal")
  internal <- c("root", "A", "B")
  lx <- sort(g$nodes$x[!g$nodes$id %in% internal])
  expect_equal(length(lx), 5) # a1 a2 a3 b1 C
  diffs <- diff(lx)
  expect_true(all(abs(diffs - diffs[1]) < 1e-12)) # arithmetic sequence
  expect_equal(range(lx), c(0, 1)) # normalised onto [0, 1]
})

test_that("[BDD] layout_tree count mode keeps integer leaf positions", {
  g <- mk_tree() |> layout_tree(direction = "down", leaf_spacing = "count")
  lx <- sort(g$nodes$x[!g$nodes$id %in% c("root", "A", "B")])
  expect_equal(lx, 1:5)
})

test_that("[BDD] layout_tree elbow edges produce two rows per edge", {
  g <- mk_tree() |> layout_tree(direction = "down", edge = "elbow")
  # 7 tree edges -> 14 polyline rows
  expect_equal(nrow(g$edges), 14)
  # each bend is a right angle: either x or y matches on the first leg...
  leg1_dx <- abs(g$edges$x[1:7] - g$edges$xend[1:7])
  leg1_dy <- abs(g$edges$y[1:7] - g$edges$yend[1:7])
  expect_true(all(leg1_dx < 1e-12 | leg1_dy < 1e-12))
  # ...and the second leg continues from the elbow to the child
  expect_identical(g$edges$xend[1:7], g$edges$x[8:14])
  expect_identical(g$edges$yend[1:7], g$edges$y[8:14])
  # chain ends at the child position
  child_y <- g$nodes$y[match(sub("\\*$", "", g$edges$target[8:14]), g$nodes$id)]
  expect_identical(g$edges$yend[8:14], child_y)
})

test_that("[BDD] layout_tree elbow bends per direction", {
  # horizontal growth bends at the parent x
  g <- mk_tree() |> layout_tree(direction = "right", edge = "elbow")
  expect_true(all(abs(g$edges$x[1:7] - g$edges$xend[1:7]) < 1e-12))
})

test_that("[BDD] layout_tree renders the 4x2 direction x edge matrix", {
  for (dir in c("down", "up", "right", "left")) {
    for (ed in c("straight", "elbow")) {
      p <- plotit(mk_tree()) |>
        layout_tree(direction = dir, leaf_spacing = "equal", edge = ed) |>
        mark_rule(data = ~edges) |>
        mark_point(data = ~nodes)
      b <- ggplot2::ggplot_build(p@gg)
      expect_no_error(ggplot2::ggplot_gtable(b))
    }
  }
})

test_that("[BDD] layout_tree validates new enums", {
  expect_error(
    mk_tree() |> layout_tree(leaf_spacing = "dense"),
    "must be one of"
  )
  expect_error(
    mk_tree() |> layout_tree(edge = "curvy"),
    "must be one of"
  )
})
