#' @include class.R
NULL

# ---- Package options ----
# Default values registered in .onLoad so they appear in options().
.plotit_options <- list(
  plotit.device = "default",
  plotit.default_width = 5,
  plotit.default_height = 3.5,
  plotit.default_unit = "in"
)

.onLoad <- function(libname, pkgname) {
  op <- options()
  toset <- !(names(.plotit_options) %in% names(op))
  if (any(toset)) options(.plotit_options[toset])

  ns <- asNamespace(pkgname)

  # Manually register S3 print method for plotit.
  # NAMESPACE S3method(print,plotit) is blocked by S7's own S3 method
  # registration on R 4.5.2 / Windows, so we register it here explicitly.
  registerS3method("print", "plotit",
    ns$print.plotit,
    envir = ns
  )

  # Register S3 knit_print methods once knitr is available.
  .register_knit_print <- function(ns) {
    tryCatch(
      {
        registerS3method("knit_print", "plotit",
          ns$knit_print.plotit,
          envir = ns
        )
        registerS3method("knit_print", "plotit_composite",
          ns$knit_print.plotit_composite,
          envir = ns
        )
      },
      error = function(e) NULL
    )
  }
  if ("knitr" %in% loadedNamespaces()) {
    .register_knit_print(ns)
  }
  setHook(packageEvent("knitr", "onLoad"), function(...) .register_knit_print(ns))

  invisible()
}

# ---- Unsupported operations on composites ----
# Registered here (loaded last) so all S7 generics exist.  The whole loop
# runs inside local() so loop variables never leak into the namespace.
#
# The generic list is assembled from per-family catalogs (._CATALOG_* in
# mark.R / layout.R / scale.R / project.R / split.R) plus the two bespoke
# label generics, so adding a new mark/layout/scale only requires updating
# its family catalog -- the composite guard follows automatically.  A name
# without a live generic warns at load time instead of silently skipping.
local({
  # Catalog vectors are defined by their family files, which the Collate
  # order guarantees are sourced before this file.  Lookup follows the
  # normal lexical chain into the namespace.
  .catalog <- function(name) {
    if (exists(name, inherits = TRUE)) get(name) else character(0)
  }
  .generics <- c(
    .catalog("._CATALOG_MARKS"),
    .catalog("._CATALOG_LAYOUTS"),
    .catalog("._CATALOG_SCALES"),
    .catalog("._CATALOG_PROJECTS"),
    .catalog("._CATALOG_SPLITS"),
    "label_axis", "label_legend"
  )
  .missing <- .generics[!vapply(
    .generics, function(nm) exists(nm, mode = "function"), logical(1)
  )]
  if (length(.missing) > 0) {
    cli::cli_warn(c(
      "Catalogued generics not found at load time: {.val {.missing}}.",
      "i" = "Composite rejection stubs were not registered for them."
    ))
  }

  # One factory call per generic: the stub closes over its own `.name`
  # binding via an explicit environment (S7 method capture during package
  # load is unreliable for plain closures).  The environment's parent is
  # this load-time frame, so {.}, cli:: and every namespace binding stay
  # reachable from the stub body.
  .make_stub <- function(name, generic) {
    .fun <- function(plot, ...) {
      cli::cli_abort(c(
        "{.fn {stub_name}} is not supported for {.cls plotit_composite} objects.",
        "i" = "Apply it to individual sub-plots before composing."
      ))
    }
    .stub_env <- new.env(parent = parent.frame())
    .stub_env$stub_name <- name
    environment(.fun) <- .stub_env
    # S7 requires method signatures to be compatible with the generic's;
    # a bare (plot, ...) signature triggers one warning per missing
    # argument at registration time.  Align the formals dynamically.
    formals(.fun) <- formals(generic)
    .fun
  }
  for (.generic_name in setdiff(.generics, .missing)) {
    .generic <- get(.generic_name)
    S7::method(.generic, plotit_composite) <-
      .make_stub(.generic_name, .generic)
  }
})
