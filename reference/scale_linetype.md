# Linetype scale

Maps data values to line types. Supports discrete and reverse scales;
continuous variables are not supported.

## Usage

``` r
scale_linetype(
  plot,
  name = ggplot2::waiver(),
  trans = "discrete",
  limits = NULL,
  range = NULL,
  breaks = NULL,
  labels = NULL,
  ...
)
```

## Arguments

- plot:

  A plotit object.

- name:

  Scale title (legend name).

- trans:

  Scale transformation. Default `"discrete"`. Allowed: `"discrete"`,
  `"reverse"`. `"identity"` and `"binned"` are rejected with targeted
  error messages.

- limits:

  Data domain.

- range:

  Linetype names or codes (`c("solid","dashed")`). `NULL` = ggplot2
  defaults.

- breaks:

  Legend key positions.

- labels:

  Legend key labels.

- ...:

  Passed to the underlying ggplot2 scale function.

## Value

A modified plotit object.

## Examples

``` r
plotit(ggplot2::economics, encode(x = date, y = unemploy)) |>
  mark_line() |>
  scale_linetype()
```
