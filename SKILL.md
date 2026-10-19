---
name: academic-plots
description: "Create, review, or restyle academic figures in R with ggplot2: charts, coefficient plots, maps, multi-panel layouts, accessible palettes, readable labels, and publication exports. Use for ggplot code and figure-quality requests."
license: MIT
---

# academic-plots

Build figures that are readable at their final size, with redundant encoding
for greyscale and colour-vision deficiency. Treat the following as house defaults;
explicit user instructions take precedence.

## Workflow

1. Establish palette, destination/size and audience together, once. Use information
   already supplied. If the user says to proceed or does not answer, use Okabe-Ito,
   7in reference width, `base_size = 14`, a research audience and the title version; state
   those assumptions. Preserve requested chart types, variables and emphasis.
2. Choose an honest encoding. If the requested chart would misrepresent the data,
   explain the issue briefly and offer an alternative; follow the user's decision.
3. Read [scripts/style.R](scripts/style.R). Copy the needed helpers into the
   user's plotting script, or copy this file into their project and source it
   relative to that project. Do not leave a dependency on your installed skill
   directory or a machine-specific path in the delivered code.
4. Read the relevant reference below. Start with [core plot templates](references/core-plots.md)
   for standard charts and [detailed guidance](references/style-guide.md) for sizing,
   axes, typography, labels and export decisions. Examples require the helper
   preamble and may require the illustrative data defined earlier in that section.
5. Render and inspect at the intended dimensions, then inspect the final export.
   Check clipping, label collisions, legends, contrast, units, panel alignment
   and the chosen title version. Fix observed problems and render again.
6. Deliver reproducible code, figures, caption/source copy, paths and assumptions.
   If R or a necessary dependency is unavailable, say which checks were not run.
   For a review request, deliver prioritised findings instead of unsolicited edits.

## Title and no title versions

### Choosing a title version

| Destination | Default version | Text inside the exported figure |
|---|---|---|
| Papers, journal articles, manuscripts, presentations and slide decks | **no title** | No overall title, subtitle, caption, source note or footnote |
| Everything else, including reports, posters, blog posts, standalone figures and an unspecified destination | **title** | A finding-led title, plus useful subtitle/footnote text |

Explicit user instructions override the destination default. Name versions
**title** and **no title**, with `_title` and `_no_title` filename suffixes when
distinguishing them. Create both only if requested.

### Applying titles and annotations

Use `figure_version(destination, version)` and `figure_labels()` from the helper
file for ordinary ggplot labels. These helpers do not remove text drawn through
custom annotation layers or patchwork's `plot_annotation()`: remove those notes
and overall annotations separately for no title exports. An explicit request to
retain a particular note also overrides the default; implement that after the
helper rather than silently discarding the user's text.

### Captions, footnotes and panel headings

For no title versions, supply explanatory and source text separately for the
manuscript caption, slide text or speaker notes. Preserve axis labels, units,
legends, data labels and descriptive panel headings/facet strips. A panel heading
identifies its data and is distinct from the overall title; retain it unless the
user asks otherwise. Remove subtitles and footnotes from every panel as well.

## Essential style rules

### Fonts

- Use Libre Franklin as the default font. For PDFs, make fonts visible to the export backend and
  verify the embedded font, not just the requested family. See the font setup in
  [detailed guidance](references/style-guide.md); do not silently substitute an
  explicitly requested font.

### Colours and accessibility

- Use Okabe-Ito for categories and Paul Tol schemes for ordered data. Never
  interpolate a categorical palette. Use named colours consistently across
  figures. Check a user-specified palette instead of replacing it silently.
- Encode categories with shape, line type, direct labels or facets as well as
  colour. Text needs at least 4.5:1 contrast; thin marks need 3:1. Compute label
  colours from the actual scaled fills, including missing-value fills.

### Plot sizes and aspect ratios

- Bank ordered lines and fitted curves by median absolute slope using the final
  displayed ranges. Use a common ratio and equal panel dimensions for comparable
  multipanel figures. Do not invent segments for unordered points; use readable
  fallback dimensions for plots without bankable segments. Preserve map geometry
  and square heatmap cells. User dimensions override banking.
- Size text, points, strokes, margins and legends relative to the overall figure.
  The templates specify reference sizes at 7 x 5.5in (14pt base text, roughly
  3mm points). `save_figure()` and `preview_figure()` scale these uniformly by
  `sqrt((width / 7) * (height / 5.5))`. Do not apply the export factor manually as well.
  Preserve data coordinates, category widths and geometry. Scale a composition
  once as a whole. Use `reference = NULL` for explicitly fixed physical sizes;
  see [sizing guidance](references/style-guide.md) for custom references.
- Render at the destination's physical dimensions. No essential text should be
  below 7pt at final size; if proportional reduction makes text too small,
  simplify the layout or increase reference sizes explicitly. Fix clipping with layout, wrapping or headroom before
  shrinking text; never widen a mandated single-column figure.

### Axes, grids and ticks

- Omit titles on categorical axes (for example `labs(y = NULL)` on horizontal
  bars or `labs(x = NULL, y = NULL)` on categorical heatmaps), keeping category
  tick labels. Retain numeric-axis titles and units; user requests override.
- Use no internal grid by default, draw both axis lines, and put ticks on axes
  that carry numeric values. Leave a visible tail beyond the last tick without
  extending either axis past a shared zero origin.
- Include zero on bar/coefplot numeric axes and both scatter axes by default,
  retaining all negative observations and interval endpoints. Honour requested
  ranges; dates and log scales are exceptions. Label zero as `0`; wholly
  nonnegative x/y regions use one shared corner zero without duplicate ticks.

### Labels and number formatting

- Use sentence case, explicit units and meaningful category order. Round once
  per set of labels: 3 decimals below 1, 2 below 100, 1 below 1000, integers
  above; whole numbers stay whole, and thousands use separators. Preserve
  meaningful differences rather than rounding distinct values to identical labels.
- Keep coefficient labels above their own points, with space for intervals and
  adjacent rows. Repel scatter labels against all observations. Leader lines
  must visibly differ in colour from the marks they identify.

### Legends

- Put legends at the top in one horizontal row; wrap only if measured space
  requires it. Omit legend titles on titled figures/panels, retaining essential
  variable names and units in headings or axes. Direct labels can replace legends.

### Uncertainty and intervals

- Draw confidence intervals with visible caps, full-opacity dark or series-coloured
  strokes (default `linewidth = 0.7`); keep uncertainty bands visible behind data.

### Panels and headings

- Size multipanel point markers for each panel's allocated area, rather than
  copying standalone marker sizes. Start with diameter and stroke multiplied by
  the square root of that panel's share of the composition; see
  [multi-panel sizing](references/multi-panel.md#sizing-a-composed-figure).
- Give each composed panel a descriptive heading, centred over its full plot
  region. Align heading baselines and reserve equal space for wrapped headings.

### Maps

- For maps, data-driven or explicitly requested fills take precedence over the
  white-country/grey-land/blue-water defaults. Preserve geographic context,
  actual shorelines and projection geometry; see [maps](references/maps.md).

### Export and inspection

- Export final rasters at 800 dpi and previews at 150 dpi unless requested
  otherwise. Prefer vector PDF/SVG where accepted. Inspect each delivered
  format; a successful save is not a visual quality check.

## References and runtime

Read supporting material only when relevant:

| Resource | Use it for |
|---|---|
| [Plotting helpers](scripts/style.R) | Themes, palettes, formatting, banking, contrast, variants and export |
| [Detailed guidance](references/style-guide.md) | Fonts, sizing, axes, labels, title variants, inspection, export and misleading-chart traps |
| [Core plots](references/core-plots.md) | Standard chart templates, highlighted series, coefficient plots and heatmaps |
| [Multi-panel figures](references/multi-panel.md) | Composition, shared legends/scales, equal panels and headings |
| [Aspect ratio](references/aspect-ratio.md) | MAS banking, transformed scales and fallback cases |
| [Maps](references/maps.md) | Choropleths, context, labels, water, projections and insets |
| [Accessibility](references/accessibility.md) | Contrast, greyscale and colour-vision checks |

R >= 4.3, ggplot2 >= 4.0.0 and scales >= 1.4.0 are required for the supplied helpers
and templates. Check installed versions before rendering. Optional packages
are documented in [README.md](README.md); use them only for the features needed.
Use available fallbacks (for example manually positioned text without ggrepel)
and disclose substitutions. Package installation follows the user's existing
authorization. Bundled fonts keep their separate OFL license; see [NOTICE.md](NOTICE.md).
