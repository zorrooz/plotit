library(dplyr)

# 准备数据：按 Species 汇总花瓣长宽（折线图需要至少两个点）
iris_line <- iris %>%
  group_by(Species) %>%
  summarise(
    Petal.Length = mean(Petal.Length),
    Petal.Width = mean(Petal.Width),
    .groups = "drop"
  )

# 构造 plotit 对象并添加图层/标度/分面/标签
p <- plot(
  iris %>% mutate(Species = as.factor(Species)),
  encode(x = Petal.Length, y = Petal.Width, colour = Species),
  default_color = "gray50",
  # width = 4,
  # height = 3
) %>%
  mark_point(size = 2.5, alpha = 0.7) %>%
  # 在汇总数据上叠加折线，展示分组趋势
  mark_line(
    data = iris_line,
    mapping = encode(x = Petal.Length, y = Petal.Width, colour = Species)
  ) %>%
  scale_color(name = "Species") %>%
  split_wrap(Species, nrow = 2) %>%
  label_title("Iris: Petal dimensions by Species") %>%
  label_axis(x = "Petal Length (cm)", y = "Petal Width (cm)")

# 预览
p

# 导出
p %>% export("iris_plot.svg")
