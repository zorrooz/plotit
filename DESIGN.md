# plotit Documentation Design

Design goals that drive the pkgdown site structure. Visual identity
(tidyplots-inspired CSS/theme) is a later pass; this file owns IA and content rules.

## Identity

Editorial cookbook for a declarative ggplot2 grammar — closer to tidyplots
pkgdown + cookbook than to a function encyclopedia.

## Audience & jobs

| Reader | Arrives wanting | Lands on |
|---|---|---|
| New user | first plot in 5 minutes | Get Started |
| Chart seeker | "I need to compare groups / show a trend" | Gallery |
| Power user | multi-panel, relational, recipes, escape hatch | Advanced |
| API designer / contributor | how verb families fit together | API |
| Reviewer / adopter | why the grammar looks this way | Design Goals |

## Hard rules (IA)

1. **Five articles, no more.** Anything that would become article #6 belongs
   in Reference, AGENTS.md, or NEWS — not a new vignette.
2. **Intent-first gallery.** Gallery sections are chart goals (compare,
   distribute, relate, trend, proportion, matrix, map, network, annotate),
   not function names.
3. **API is a system view.** One page maps every verb family, shared
   signatures, and contract tiers. Function examples live in Reference.
4. **Rendered proof in Gallery; signatures in API.** Do not mix long
   parameter tables into gallery pages, and do not bury the only plot of a
   chart type in API docs.
5. **Composition-first.** Recipes that are pure composition (pie = bar +
   polar) appear as gallery recipes, not as new marks or new articles.
6. **No cross-link chains of doom.** Each article stands alone. "Next"
   pointers at most one hop; no circular prerequisites.

## Navigation

```
Get Started | Reference | Articles▾ (Gallery, Advanced, API, Design Goals) | News | GitHub
```

Home page: short pitch + 4–5 documentation cards (mirrors tidyplots.org card
layout) + install + one pipeline example.

## Content budgets

| Article | Target length | Must include |
|---|---|---|
| Get Started | ~200 lines | pipeline grammar, first scatter/bar/box, export |
| Gallery | ~800–1200 lines | one canonical example per major chart family |
| Advanced | ~400–600 lines | compose, relational layouts, scales deep-dive, escape hatch |
| API | ~200 lines | family tables + shared signatures (no long examples) |
| Design Goals | ~80 lines | composition-first, zero-dep layouts, out-of-scope list |

## Anti-goals

- Nested navbar menus with 15+ links
- Separate vignette per mark family
- Internal design docs (`gallery-system`, `api-system` v2 drafts) as published articles
- Circular "前置/下一步" chains across gallery pages

## Decision Trace

| Decision | Reason | Alternatives | Tradeoff |
|---|---|---|---|
| Merge 11 gallery-* into one Visualizing Data | tidyplots model; intent-first search | keep goal galleries + umbrella page | one long page; need clear H2 anchors |
| Fold composing + relational + customizing into Advanced | these are workflow techniques, not first-day content | 3 separate advanced articles | Advanced is denser |
| Design Goals stays but off primary nav | documents why; low traffic after adoption | delete; promote to top nav | slightly hidden |
| API article ≠ Reference index | article explains system; reference is per-function | drop API article, beef up reference intro | loses the "map of the grammar" |
| Retire use-case-* and transform-recipes as standalone | recipes fold into Advanced / Gallery | keep as sixth/seventh articles | domain demos less discoverable |
