library(plotit)
p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))

# Call the method directly without S7 dispatch
text <- "X轴"
aes <- "x"

r <- if (is.null(text)) list(action = "skip") else if (isTRUE(text)) list(action = "default") else if (isFALSE(text)) list(action = "hide") else if (is.character(text)) list(action = "set", value = text) else stop("bad")
cat("r action:", r$action, "value:", r$value, "\n")

elem <- paste0("axis.title.", aes)
gg <- p@gg
lbl <- p@meta@labels

if (r$action == "set") {
  gg$theme[[elem]] <- NULL
  cat("before labs, gg labels x:", deparse(gg$labels$x), "\n")
  gg <- gg + ggplot2::labs(!!aes := r$value)
  cat("after labs, gg labels x:", deparse(gg$labels$x), "\n")
  if (aes == "x") {
    lbl@x <- r$value
  } else {
    lbl@y <- r$value
  }
  cat("after lbl assign, lbl x:", deparse(lbl@x), "\n")
}

p2 <- p
p2@gg <- gg
p2@meta@labels <- lbl
cat("final meta x:", deparse(p2@meta@labels@x), "\n")
cat("final gg x:", deparse(p2@gg$labels$x), "\n")
