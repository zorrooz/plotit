# Generic for setting plot title

Generic for setting plot title

## Usage

``` r
label_title(plot, text = NULL, hide = FALSE, reset = FALSE, ...)
```

## Arguments

- plot:

  A plotit object

- text:

  Title text. NULL = don't modify. "str" = custom title.

- hide:

  If TRUE, remove title element from layout entirely.

- reset:

  If TRUE, remove the title text (restore to no title).

- ...:

  Currently unused

## Value

Modified plotit object

## Examples

``` r
plotit(iris, encode(x = Sepal.Width, y = Sepal.Length)) |> label_title("My Title")
```
