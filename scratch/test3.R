library(plotit)
p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
r <- list(action = "set", value = "X轴")
aes <- "x"
gg <- p@gg
gg <- gg + ggplot2::labs(x = r$value)
cat("gg label x:", deparse(gg$labels$x), "\n")
p@gg <- gg
cat("final gg x:", deparse(p@gg$labels$x), "\n")
