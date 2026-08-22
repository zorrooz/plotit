# Correlation preprocessing transform

Computes pairwise correlations over the numeric columns of `data` and
melts the matrix into a long-form table (`Var1`, `Var2`, `value`),
optionally reordering rows/columns by hierarchical clustering.
[`mark_corr()`](https://zorrooz.github.io/plotit/reference/mark_corr.md)
is sugar over this transform plus a tile layer; call it directly when
you need the table for custom rendering or inspection.

## Usage

``` r
transform_corr(
  data,
  method = c("pearson", "spearman", "kendall"),
  reorder = TRUE
)
```

## Arguments

- data:

  A data.frame with at least two numeric columns.

- method:

  Correlation method: `"pearson"` (default), `"spearman"`, or
  `"kendall"`.

- reorder:

  If `TRUE` (default), reorder rows and columns by hierarchical
  clustering. Skipped with a warning when the matrix contains NA (e.g.
  zero-variance columns).

## Value

A data.frame with columns `Var1`, `Var2` (factors) and `value` (numeric
correlation).

## Examples

``` r
head(transform_corr(mtcars[, c("mpg", "disp", "hp")]))
#>   Var1 Var2      value
#> 1   hp   hp  1.0000000
#> 2  mpg   hp -0.7761684
#> 3 disp   hp  0.7909486
#> 4   hp  mpg -0.7761684
#> 5  mpg  mpg  1.0000000
#> 6 disp  mpg -0.8475514
```
