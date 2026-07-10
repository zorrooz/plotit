# Generic for setting plot caption

Generic for setting plot caption

## Usage

``` r
label_caption(plot, text = NULL, hide = FALSE, reset = FALSE, ...)
```

## Arguments

- plot:

  A plotit object

- text:

  Caption text. NULL = don't modify. "str" = custom caption.

- hide:

  If TRUE, remove caption element from layout entirely.

- reset:

  If TRUE, remove the caption text (restore to no caption).

- ...:

  Currently unused

## Value

Modified plotit object

## Examples

``` r
plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> label_caption("Caption")
```
