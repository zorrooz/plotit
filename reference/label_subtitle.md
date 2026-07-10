# Generic for setting plot subtitle

Generic for setting plot subtitle

## Usage

``` r
label_subtitle(plot, text = NULL, hide = FALSE, reset = FALSE, ...)
```

## Arguments

- plot:

  A plotit object

- text:

  Subtitle text. NULL = don't modify. "str" = custom subtitle.

- hide:

  If TRUE, remove subtitle element from layout entirely.

- reset:

  If TRUE, remove the subtitle text (restore to no subtitle).

- ...:

  Currently unused

## Value

Modified plotit object

## Examples

``` r
plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> label_subtitle("Subtitle")
```
