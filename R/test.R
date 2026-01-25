library(tidyplots)

study |>
  tidyplot(x = score, y = treatment, color = treatment) |>
  add_mean_bar(alpha = 0.3) |>
  add_sem_errorbar() |>
  add_data_points()
