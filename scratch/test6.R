library(plotit)

# Monkey-patch to add debugging
original_method <- S7::method(label_axis, plotit_class)
S7::method(label_axis, plotit_class) <- function(plot, text = NULL, aes = NULL, ...) {
  cat("DEBUG label_axis called\n")
  cat("DEBUG text:", deparse(text), "\n")
  cat("DEBUG aes:", deparse(aes), "\n")
  
  # Run original logic step by step
  if (is.null(aes) || !(aes %in% c("x", "y"))) {
    cat("DEBUG: would abort\n")
  }
  
  r <- if (is.null(text)) list(action = "skip") else if (isTRUE(text)) list(action = "default") else if (isFALSE(text)) list(action = "hide") else if (is.character(text)) list(action = "set", value = text) else stop("bad")
  
  cat("DEBUG r action:", r$action, "\n")
  if (r$action == "skip") return(plot)
  
  elem <- paste0("axis.title.", aes)
  gg <- plot@gg
  lbl <- plot@meta@labels
  
  if (r$action == "set") {
    cat("DEBUG: set branch\n")
    gg$theme[[elem]] <- NULL
    gg <- gg + ggplot2::labs(!!aes := r$value)
    cat("DEBUG after labs, gg labels x:", deparse(gg$labels$x), "\n")
    if (aes == "x") lbl@x <- r$value else lbl@y <- r$value
    cat("DEBUG after lbl assign, lbl x:", deparse(lbl@x), "\n")
  }
  
  plot@gg <- gg
  plot@meta@labels <- lbl
  cat("DEBUG final gg x:", deparse(plot@gg$labels$x), "\n")
  cat("DEBUG final meta x:", deparse(plot@meta@labels@x), "\n")
  plot
}

p <- plotit(iris, encode(x = Sepal.Width, y = Sepal.Length))
p2 <- label_axis(p, text = "X轴", aes = "x")
cat("\nRESULT meta x:", deparse(p2@meta@labels@x), "\n")
cat("RESULT gg x:", deparse(p2@gg$labels$x), "\n")
