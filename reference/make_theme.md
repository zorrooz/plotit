# Create a reusable theme preset

Builds a theme function from
[`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html)
elements and an optional base theme. The returned function applies the
theme to a plotit object and can be used anywhere
[`style()`](https://zorrooz.github.io/plotit/reference/style.md) is
used.

## Usage

``` r
make_theme(name, ..., base_theme = ggplot2::theme_minimal)
```

## Arguments

- name:

  Name for the theme function as a string (e.g. `"style_dark"`).

- ...:

  Theme elements passed to
  [`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html).

- base_theme:

  A base ggplot2 theme function (default: ggplot2::theme_minimal).

## Value

Invisibly returns the created function.

## Details

The theme function is assigned to `name` in the calling environment
([`parent.frame()`](https://rdrr.io/r/base/sys.parent.html)) and also
returned invisibly. When calling `make_theme()` inside another function,
assign the return value explicitly – the
[`parent.frame()`](https://rdrr.io/r/base/sys.parent.html) assignment is
lost when that function returns.

## Examples

``` r
style_dark <- make_theme("style_dark",
  plot.background = ggplot2::element_rect(fill = "#1a1a1a"),
  text = ggplot2::element_text(colour = "white")
)
plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
  mark_point() |>
  style_dark()
```
