# Generic for setting legend title(s)

Generic for setting legend title(s)

## Usage

``` r
label_legend(plot, text = NULL, aes = NULL, hide = FALSE, reset = FALSE, ...)
```

## Arguments

- plot:

  A plotit object

- text:

  Legend title text. NULL = don't modify. "str" = custom title.

- aes:

  Aesthetic to apply to (e.g. "colour", "fill"). NULL = all mapped
  aesthetics.

- hide:

  If TRUE, hide the legend title.

- reset:

  If TRUE, restore the legend title to the variable name.

- ...:

  Currently unused

## Value

Modified plotit object

## Examples

``` r
plotit(iris, encode(x = Sepal.Width, y = Sepal.Length, colour = Species)) |>
  mark_point() |>
  scale_color() |>
  label_legend(text = "Species", aes = "colour")
#> Scale for colour is already present.
#> Adding another scale for colour, which will replace the existing scale.
```
