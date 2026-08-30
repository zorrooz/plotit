# Use Case: Publishing

> **本页解决什么问题**：Publication-quality figures: canvas, fonts,
> export. **前置**：已完成
> [use-case-bioinformatics](https://zorrooz.github.io/plotit/articles/articles/use-case-bioinformatics.md)

> **下一步**：→
> [philosophy](https://zorrooz.github.io/plotit/articles/articles/philosophy.md)

``` r

library(plotit)
```

The paper workflow end to end: canvas size -\> theme -\> labels -\>
export.

## Sized canvas and theme

``` r

p <- ggplot2::mpg |>
  plotit(encode(x = displ, y = hwy, colour = class),
    autofit = FALSE, width = 6, height = 4, size_unit = "in"
  ) |>
  mark_point(size = 2, alpha = 0.7) |>
  scale_color(range = "friendly")
#> Scale for colour is already present.
#> Adding another scale for colour, which will replace the existing scale.
```

## Publication labels

``` r

p <- p |>
  label_title("Fuel Economy by Class") |>
  label_subtitle("EPA 1999-2008, compact academic canvas") |>
  label_axis(text = "Displacement (L)", aes = "x") |>
  label_axis(text = "Highway MPG", aes = "y") |>
  label_caption("Source: ggplot2::mpg")
```

## Export (size chain + formats)

``` r

export(p, "out.pdf", dpi = 300)
export(p, "out.tiff", width = 7.2, height = 4.6, dpi = 600) # two-column journal spec
export(p, "out.svg")
```

## Multi-page PDF report (stage 2: export(list))

``` r

export(list(p, p |> style(base_size = 8)), "report.pdf")
```

[`export()`](https://zorrooz.github.io/plotit/reference/export.md)
accepts a list of `plotit`/`plotit_composite` objects and writes one
page per plot (PDF only, decisions.md DEC-1).
