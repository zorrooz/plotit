library(plotit)
p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
r <- list(action = "set", value = "X轴")
aes <- "x"
gg <- p@gg
gg <- gg + ggplot2::labs(!!aes := r$value)
cat("gg label x:", deparse(gg$labels$x), "\n")
