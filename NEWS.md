# plotit (development version)

* Active development stage — frequent breaking changes expected.
* See [GitHub releases](https://github.com/zorrooz/plotit/releases) for version history.

## Refactoring pass: completeness, consistency, defaults

### Bug fixes

- `mark_network()` node defaults now respect mapped aesthetics: `node_colour`
  is applied to the `colour` channel (previously only `fill`, which default
  shape 19 ignores, so nodes rendered black) and `node_size` no longer
  overrides a user-mapped `size` variable. Each static is injected per
  channel, only when that channel is unmapped.
- `mark_corr()` and `mark_treemap()` now route through the shared mark path,
  gaining white hairline separators consistent with `mark_rect()`.
- `layout_force(seed = ...)` no longer perturbs the caller's global RNG
  stream (`.Random.seed` is saved/restored around the simulation).
- Removed 26 literal `<U+XXXX>` mojibake sequences from comments/roxygen
  (one of which leaked into `scale_color()` docs), a stray ESC control
  character in `label_axis()` docs, and a typo (`lement_blank`).

### API

- **Breaking (extension contract):** `project_parallel()` drops its dead
  `clip` parameter; it was documented as unused.
- `tidygraph` is now declared in `Suggests`: `as_graph()` accepts
  `tbl_graph` input but the dependency was previously undeclared.

### Internal

- Standard marks declare their S7 generic through a `._make_mark_generic()`
  factory; layouts register both pipeline and bare-graph methods through
  `._register_layout_methods()`.
- Shared helpers extracted: render preparation (`._prepare_render()`), grob
  measurement/device sizing (`._measure_inches()` / `._open_sized_device()`),
  composite annotation setter, sankey/chord first-occurrence fill, and
  `label_axis()` reuses `._set_text_label()`.
- Internal helper naming normalized to the `._` prefix (e.g.
  `.theme_default()` → `._theme_default()`); zero lint findings restored.
