# Tests for layout_* engines and pipeline integration

mk_graph <- function() {
  as_graph(data.frame(
    source = c("a", "a", "b", "c"),
    target = c("b", "c", "c", "d")
  ))
}

test_that("[BDD] layout_force is deterministic under a fixed seed", {
  g1 <- mk_graph() |> layout_force(seed = 42)
  g2 <- mk_graph() |> layout_force(seed = 42)

  expect_identical(g1$nodes$x, g2$nodes$x)
  expect_identical(g1$nodes$y, g2$nodes$y)
})

test_that("layout_force: nodes and edges gain geometry columns", {
  g <- layout_force(mk_graph(), seed = 1)

  expect_true(all(c("x", "y") %in% names(g$nodes)))
  expect_true(all(c("x", "y", "xend", "yend") %in% names(g$edges)))
  # edge endpoints resolve to the same coordinates as their nodes
  x_of <- stats::setNames(g$nodes$x, g$nodes$id)
  expect_equal(g$edges$x, unname(x_of[g$edges$source]))
})

test_that("[BDD] layouts are idempotent: chaining equals last-wins", {
  fresh <- layout_force(mk_graph(), seed = 7)
  chained <- layout_circle(mk_graph()) |> layout_force(seed = 7)

  expect_identical(chained$nodes$x, fresh$nodes$x)
  expect_false(is.null(chained$nodes$y))
})

test_that("[BDD] layout_circle places nodes on a unit circle; degree sorts", {
  g_id <- layout_circle(mk_graph())
  r <- sqrt(g_id$nodes$x^2 + g_id$nodes$y^2)
  expect_equal(r, rep(1, nrow(g_id$nodes)))

  # 'c' has degree 3 (a-c, b-c, c-d) -> first when order_by = "degree"
  g_deg <- layout_circle(mk_graph(), order_by = "degree")
  expect_identical(g_deg$nodes$id[1], "c")
})

test_that("[BDD] layout_tree orients root per direction and supports hclust", {
  hc <- hclust(dist(USArrests[, 1:3]))
  down <- as_graph(hc) |> layout_tree(direction = "down")
  up <- as_graph(hc) |> layout_tree(direction = "up")

  root_down <- down$nodes$id[!down$nodes$leaf]
  leaves <- down$nodes$id[down$nodes$leaf]
  expect_length(leaves, sum(down$nodes$leaf))
  expect_false(anyNA(c(down$nodes$x, up$nodes$x)))
  # root on top for "down": maximal y among internal nodes
  internal <- down$nodes[!down$nodes$leaf, ]
  expect_identical(internal$id[which.max(internal$y)], root_down[1])
  # flipped direction puts the root at the bottom
  internal_up <- up$nodes[!up$nodes$leaf, ]
  expect_identical(internal_up$id[which.min(internal_up$y)], root_down[1])
})

test_that("layout_tree: cyclic graph aborts with guidance", {
  cyclic <- data.frame(
    source = c("a", "b", "c"), target = c("b", "c", "a")
  )
  expect_error(layout_tree(as_graph(cyclic, directed = TRUE)), "root|cycle")
})

test_that("[BDD] pipeline: plotit(graph) |> layout_* |> marks builds layers", {
  skip_if_not_installed("igraph")

  p <- plotit(mk_graph()) |>
    layout_force(seed = 3) |>
    mark_point(data = ~nodes) |>
    mark_rule(data = ~edges, colour = "grey70")

  gb <- ggplot2::ggplot_build(p@gg)
  expect_length(gb$plot$layers, 2)

  # auto-bind: point layer mapping has implicit x/y
  mp <- gb$plot$layers[[1]]$mapping
  expect_identical(rlang::as_label(mp$x), "x")
  expect_identical(rlang::as_label(mp$y), "y")
  # rule layer binds all four endpoint aesthetics
  mr <- gb$plot$layers[[2]]$mapping
  expect_setequal(
    intersect(names(mr), c("x", "y", "xend", "yend")),
    c("x", "y", "xend", "yend")
  )
  # graph layers never inherit the global mapping
  expect_false(gb$plot$layers[[1]]$inherit.aes)
})

test_that("[BDD] auto-bind precedence: explicit mappings win", {
  p <- plotit(mk_graph()) |>
    layout_circle() |>
    mark_point(data = ~nodes, encode(x = id))

  mp <- ggplot2::ggplot_build(p@gg)$plot$layers[[1]]$mapping
  expect_identical(rlang::as_label(mp$x), "id") # not overwritten by autobind
  expect_identical(rlang::as_label(mp$y), "y") # still bound implicitly
})

test_that("resolver errors name available tables and required setup", {
  g <- plotit(mk_graph()) |> layout_circle()

  expect_error(mark_point(g, data = ~nope), "nope")
  expect_error(mark_point(g, data = NULL), "~nodes")
  tabular_err <- tryCatch(
    mark_point(plotit(iris, encode(x = Species)), data = ~nodes),
    error = function(e) conditionMessage(e)
  )
  expect_match(tabular_err, "as_graph")
  # two-sided formulas rejected
  expect_error(mark_point(g, data = nodes ~ edges), "one-sided")
})

test_that("[BDD] mark_rule segment mode works with plain data.frames too", {
  segs <- data.frame(x0 = 1, y0 = 2, x1 = 4, y1 = 5)

  p <- plotit(segs, encode()) |>
    mark_rule(
      data = segs,
      mapping = encode(x = x0, y = y0, xend = x1, yend = y1),
      colour = "grey50"
    )

  gb <- ggplot2::ggplot_build(p@gg)
  expect_s3_class(gb$plot$layers[[1]]$geom, "GeomSegment")
  expect_false(gb$plot$layers[[1]]$inherit.aes)
})

test_that("mark_rule segment mode guards conflicting usage", {
  segs <- data.frame(x0 = 1, y0 = 2, x1 = 4, y1 = 5)
  p <- plotit(segs, encode())

  expect_error(
    mark_rule(p, data = segs, x = 1),
    "conflict"
  )
  expect_error(
    mark_rule(p, data = segs),
    "requires aesthetics"
  )
})

test_that("layout_* on non-graph plots aborts with setup hint", {
  expect_error(layout_force(plotit(iris, encode(x = Species))), "as_graph")
  expect_error(layout_circle(plotit(iris, encode(x = Species))), "as_graph")
})
