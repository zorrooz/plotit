---
feature: pkgdown-ia
status: delivered
updated: 2026-02-14
branch: dev
commits: 0523286..HEAD
spec_path_note: >-
  compose-next default docs/compose/spec/ conflicts with pkgdown output dir
  docs/; canonical tracked location is spec/
---

# pkgdown IA: five-article documentation site

## Report

**What was built** — The pkgdown site now publishes exactly five articles plus
per-function Reference, following the tidyplots-style intent-first IA in
`DESIGN.md`: Get Started (`plotit.Rmd`), Gallery (`visualizing-data.Rmd`),
Advanced (`advanced.Rmd`), API (`api.Rmd`, new system map), Design Goals
(`design-goals.Rmd`). Twenty retired vignettes (goal-split galleries,
composing/customizing/relational, philosophy, use-case-*, transform-recipes,
gallery-system, api-system) were deleted from the package. Navbar, README
documentation cards, AGENTS §4.9 IA rule, `.Rbuildignore`, and the pkgdown CI
post-build strip (AGENTS + DESIGN) were aligned to that structure. Visual
identity/CSS and R API redesign remain out of scope for later passes.

**Verification** — `pkgdown::build_site()` on Windows R 4.5.2 returned
`BUILD_OK`; `docs/articles/` contains only the five article HTML files plus
index; relative link check across the five articles reported 0 broken links;
navbar hrefs on built `plotit.html` include all five destinations and
Reference. After review, `api.Rmd` pipeline skeleton pipes were fixed and
`plotit.Rmd` mark count updated to 43; those two articles were rebuilt
(`REBUILD_OK`). Independent reviewer: spec compliance all PASS; no
merge-blocking criticals.

**Journey log** —

1. Prior session already drafted DESIGN.md, three consolidated articles, and
   `_pkgdown.yml` nav rewrite on uncommitted `dev`; this feature completed the
   missing `api.Rmd`, deleted the retired set, and verified the build.
2. compose-next default `docs/compose/spec/` collides with pkgdown’s `docs/`
   output directory on R packages — feature docs live in `spec/` and are
   `.Rbuildignore`d.
3. pkgdown `exclude:` does not stop `build_home()` from rendering root `.md`
   files; keep the dual exclude + CI `rm` pattern for AGENTS/DESIGN.
4. Reviewer caught a copy-paste pipeline skeleton in `api.Rmd` (missing `|>`)
   and a stale “Thirty-nine marks” count on Get Started — both fixed before
   finalize.
5. User chose continue-on-current-dev (no worktree) and delete-retired-files
   (not exclude).

## [S1] Problem

The pkgdown site published 20+ vignettes (11 goal-split galleries, separate
composing/relational/customizing articles, philosophy, use-case-*,
transform-recipes, gallery-system, api-system). Navigation was a 15-link
nested menu; readers could not find the chart they needed, and contributors
could not tell where new content belonged. tidyplots-style sites use a short
intent-first article set (Get Started / Visualizing data / Advanced /
schemes / Reference) and stay discoverable.

## [S2] Design

Information architecture (source of truth `DESIGN.md`):

```
Get Started | Reference | Articles▾ (Gallery, Advanced, API, Design Goals) | News | GitHub
```

Five published articles only:

| File | Title | Role |
|---|---|---|
| `vignettes/plotit.Rmd` | Get Started | first pipeline, grammar skeleton, export |
| `vignettes/visualizing-data.Rmd` | Gallery (Visualizing Data) | intent-first rendered recipes |
| `vignettes/advanced.Rmd` | Advanced | compose, relational layouts, scales, escape hatch, data-prep |
| `vignettes/api.Rmd` | API | verb-family system map + shared signatures (no long examples) |
| `vignettes/design-goals.Rmd` | Design Goals | why the grammar; composition-first; out of scope |

Contracts:

1. **Navbar** (`_pkgdown.yml`): tidyverse-style left structure
   `[intro, reference, articles, news]`. Get Started is a top-level
   intro link; Gallery/Advanced/API/Design Goals sit under Articles.
   Reference stays per-function; the API article is the system view.
2. **Retired content**: delete the superseded vignette files from
   `vignettes/` and `vignettes/articles/` (user choice: delete, not
   exclude). History remains in git.
3. **Language**: published articles are English (match package docs).
4. **Cross-links**: each article ends with at most one-hop "Next"
   pointers; no circular prerequisite chains.
5. **AGENTS.md §4.9**: five-article IA rule + no-revive list; stage-5
   checklist reflects five articles.
6. **Home page** (`README.md`): structural doc-card table linking the five
   destinations. Full tidyplots CSS/theme art pass is out of scope.
7. **Reference `_pkgdown.yml` groups** stay as-is; only article IA changes.
8. **CI**: pkgdown workflow strips `AGENTS*` and `DESIGN*` root pages and
   filters them from `search.json` after build.

## [S3] Out of Scope

- Visual identity / CSS / bootstrap theme redesign (later art-style pass)
- R API refactoring (later API pass)
- Adding or removing exported functions
- Chinese mirror site content
- Publishing/deploying the built site (local build verification only)

## Tasks

- [x] T1: Write `vignettes/api.Rmd` (~200 lines English system map distilled from api-system.Rmd) — acceptance: file exists, no long function examples, links Get Started / Gallery / Design Goals (covers: S2)
- [x] T2: Finish gallery/advanced/get-started polish (English framing, Next links, intent H2s) — acceptance: five article files consistent, no Chinese prose blocks (covers: S2; depends: T1)
- [x] T3: Delete retired vignettes from `vignettes/` and `vignettes/articles/` — acceptance: only the five article sources remain under `vignettes/` (covers: S2; depends: T1)
- [x] T4: Align `_pkgdown.yml` navbar + exclude with the five-article IA — acceptance: navbar points at existing HTML slugs; DESIGN.md excluded (covers: S2; depends: T3)
- [x] T5: Update `AGENTS.md` with documentation-IA convention and DESIGN.md pointer — acceptance: durable rule present; stage-5 vignette checklist reflects five articles (covers: S2)
- [x] T6: Structural README doc-cards pointing at the five destinations — acceptance: Get Started/Gallery/Advanced/API/Reference links resolve to site paths (covers: S2; depends: T4)
- [x] T7: Verify `pkgdown::build_site()` succeeds — acceptance: local build produces exactly the five articles under `docs/articles/` (covers: S2; depends: T2,T3,T4)
- [x] T8: Extend pkgdown CI post-build strip for DESIGN pages — acceptance: workflow removes DESIGN html/md and filters search.json (covers: S2)
