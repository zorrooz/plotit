# Generic for setting axis titles

Generic for setting axis titles

## Usage

``` r
label_axis(plot, text = NULL, aes = NULL, hide = FALSE, reset = FALSE, ...)
```

## Arguments

- plot:

  A plotit object

- text:

  Axis title text. NULL = don't modify. "str" = custom title.

- aes:

  Which axis to apply to: "x" or "y" (required).

- hide:

  If TRUE, hide the axis title entirely (�lement_blank()).

- reset:

  If TRUE, restore the axis title to the variable name.

- ...:

  Currently unused

## Value

Modified plotit object

## Examples

``` r
plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |>
  label_axis(text = "Width", aes = "x") |>
  label_axis(text = "Length", aes = "y")
```
