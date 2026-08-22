# Tests for as_graph / plotit_graph coercion and validation

test_that("[BDD] as_graph: canonical edgelist generates implicit nodes and unit values", {
  e <- data.frame(source = c("a", "a", "b"), target = c("b", "c", "c"))
  g <- as_graph(e)

  expect_s3_class(g, "plotit_graph")
  expect_true(is_graph(g))
  expect_setequal(names(g), c("nodes", "edges"))
  expect_identical(g$nodes$id, c("a", "b", "c")) # first-appearance order
  expect_identical(g$edges$source, c("a", "a", "b"))
  expect_identical(g$edges$value, c(1, 1, 1))
  expect_false(attr(g, "directed"))
})

test_that("[BDD] as_graph: column names accepted as symbols or strings", {
  e <- data.frame(from = "x", to = "y", weight = 5)
  g1 <- as_graph(e, source = from, target = to, value = weight)
  g2 <- as_graph(e, source = "from", target = "to", value = "weight")

  expect_identical(g1$edges$source, "x")
  expect_identical(g2$edges$value, 5)
})

test_that("as_graph: missing endpoint columns abort with guidance", {
  e <- data.frame(a = "x", b = "y")
  expect_error(as_graph(e), "no column")
  expect_error(as_graph(e, source = a), '"target"')
})

test_that("as_graph: NA endpoints abort", {
  e <- data.frame(source = c("a", NA), target = c("b", "c"))
  expect_error(as_graph(e), "must not contain")
})

test_that("as_graph: non-numeric value column aborts", {
  e <- data.frame(source = "a", target = "b", value = "heavy")
  expect_error(as_graph(e, value = value), "numeric")
})

test_that("[BDD] as_graph: node table requires unique id and keeps attributes", {
  nodes <- data.frame(id = c("a", "b"), label = c("A!", "B!"))
  e <- data.frame(source = "a", target = "b")
  g <- as_graph(e, nodes = nodes)

  expect_identical(names(g$nodes)[1], "id") # id-first convention
  expect_identical(g$nodes$label, c("A!", "B!"))

  dup <- data.frame(id = c("a", "a"))
  expect_error(as_graph(e, nodes = dup), "unique")

  no_id <- data.frame(key = "a")
  expect_error(as_graph(e, nodes = no_id), "id")

  unknown <- data.frame(id = "z")
  expect_error(as_graph(e, nodes = unknown), "missing from")
})

test_that("[BDD] as_graph: adjacency matrix melts (row -> source) and drops zeros", {
  m <- matrix(c(0, 2, 0, 0), nrow = 2, dimnames = list(c("u", "v"), c("u", "v")))
  g <- as_graph(m)

  expect_equal(nrow(g$edges), 1) # zero cells dropped
  expect_identical(g$edges$source, "v") # M[row = v, col = u] == 2
  expect_identical(g$edges$target, "u")
  expect_identical(g$edges$value, 2)

  m2 <- matrix(1:4, nrow = 2) # no dimnames
  g2 <- as_graph(m2)
  expect_setequal(g2$nodes$id, c("n1", "n2"))
  expect_equal(nrow(g2$edges), 4)
})

test_that("[BDD] as_graph: contingency table coerces via Freq", {
  tab <- xtabs(~ cyl + am, data = mtcars) # proper 2-dim contingency table
  g <- as_graph(tab)

  expect_true(all(c("source", "target", "value") %in% names(g$edges)))
  expect_setequal(
    g$nodes$id,
    as.character(c(unique(mtcars$cyl), unique(mtcars$am)))
  )
})

test_that("[BDD] as_graph: hclust produces merge tree with heights", {
  hc <- hclust(dist(USArrests[, 1:3]))
  n_leaves <- length(hc$labels)
  g <- as_graph(hc)

  expect_equal(nrow(g$nodes), 2 * n_leaves - 1)
  expect_equal(sum(g$nodes$leaf), n_leaves)
  expect_equal(nrow(g$edges), 2 * (n_leaves - 1))
  expect_false(anyNA(g$nodes$height))
  expect_true(attr(g, "directed"))
  # every edge points parent -> child
  expect_true(all(g$edges$target %in% g$nodes$id))
})

test_that("[BDD] as_graph: dendrogram matches hclust conversion", {
  hc <- hclust(dist(USArrests[1:8, ]))
  gd <- as.dendrogram(hc)
  expect_identical(
    as_graph(hc)$edges[, c("source", "target")],
    as_graph(gd)$edges[, c("source", "target")]
  )
})

test_that("as_graph: unsupported input aborts listing formats", {
  expect_error(as_graph(list(a = 1)), "edge data.frame|matrix|table|hclust")
})

test_that("[BDD] plotit accepts graph data and rejects global mappings", {
  g <- as_graph(data.frame(source = "a", target = "b"))

  p <- plotit(g)
  expect_true(is_graph(p@graph))

  expect_error(plotit(g, encode(x = id)), "mark level")
  expect_warning(plotit(g, default_color = "red"), "ignored")
})

test_that("[BDD] as_graph: hierarchy tables (id/parent) synthesize edges", {
  h <- data.frame(
    id = c("root", "A", "B", "a1"),
    parent = c(NA, "root", "root", "A"),
    value = c(NA, NA, 50, 30)
  )
  g <- as_graph(h)

  expect_true(attr(g, "directed"))
  expect_equal(nrow(g$edges), 3)
  # edges point parent -> child
  expect_true(all(g$edges$source %in% g$nodes$id))
  expect_setequal(g$edges$target, c("A", "B", "a1"))
  # node attributes survive (value stays on the node table)
  expect_true("value" %in% names(g$nodes))
})

test_that("as_graph: hierarchy guards unknown parents, self-parent, dup ids", {
  bad_parent <- data.frame(id = c("a"), parent = c("ghost"))
  expect_error(as_graph(bad_parent), "unknown ids")

  selfp <- data.frame(id = c("a"), parent = c("a"))
  expect_error(as_graph(selfp), "own")

  dup <- data.frame(id = c("a", "a"), parent = c(NA, NA))
  expect_error(as_graph(dup), "unique")
})

test_that("[BDD] as_graph: hclust edges carry merge sides for leaf order", {
  hc <- hclust(dist(USArrests[1:8, ]))
  g <- as_graph(hc)
  expect_true(".side" %in% names(g$edges))
  # every internal node has exactly one left (.side==1) and one right child
  tab <- table(g$edges$source, g$edges$.side)
  expect_true(all(tab[, "1"] == 1 & tab[, "2"] == 1))
})
