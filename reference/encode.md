# Create aesthetic mapping

Create aesthetic mapping

## Usage

``` r
encode(...)
```

## Arguments

- ...:

  List of aesthetic mappings (e.g., x = wt, y = mpg, color = cyl).

## Value

An object of class "plotit_encode" (a list).

## Examples

``` r
encode(x = mpg, y = wt)
#> Aesthetic mapping: 
#> * `x` -> `mpg`
#> * `y` -> `wt`
encode(x = Sepal.Width, y = Sepal.Length, colour = Species)
#> Aesthetic mapping: 
#> * `x`      -> `Sepal.Width`
#> * `y`      -> `Sepal.Length`
#> * `colour` -> `Species`
encode() # empty mapping
#> Aesthetic mapping: 
#> <empty>
```
