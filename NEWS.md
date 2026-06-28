# plotit (development version)

## Design improvements (2026-06-26)

* **Tidy evaluation infrastructure**: added zzz.R for package options registration;
  package defaults are now visible via options().

* **Dependency hygiene**: added NEWS.md for changelog tracking.

## Bug fixes and design changes

* plotit_composite now inherits from plotit_class (S7 parent), enabling
  uniform dispatch for shared methods and clear error messages for unsupported
  operations.
* Label system migrated to lazy evaluation: labels are stored in meta@labels
  and synced to gg at print()/export() time via ._sync_labels().
  This eliminates the dual-write pattern and ensures label operations are
  order-independent.
* print(plotit_composite) now manages device sizing (opens dev.new())
  consistent with print(plotit).
* _detect_discrete_aes no longer accesses gg (per §4.6).
  Only global mapping is inspected; layer-only aesthetics default to discrete.
* compose_inset and compose_marginal now sync sub-plot labels before
  assembly, preventing label loss in composite figures.
* _collect_aes_names simplified to only check global mapping (no gg).

## Documentation

* AGENTS.md (§3.3.4): brewer scheme documented as available for binned scales
  (via scale_colour_fermenter).
* AGENTS.md (§3.3.11): label_axis/label_legend added to unsupported
  operations for plot composites.
