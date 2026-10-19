# academic-plots

An Agent Skill for creating and reviewing academic figures in **R and ggplot2**.
It provides a consistent house style, accessible colour choices, chart and map
templates, and a render-and-inspect workflow. It can be installed as a local skill in Codex
and Claude Code; it is not an R package or an automatic accessibility certification.

## Install the skill

Build the lightweight bundle from a source checkout (Python 3.9+):

```sh
git clone https://github.com/sarimzaf/academic-plots.git
cd academic-plots
python scripts/package_skill.py
```

Unzip `dist/academic-plots.zip` and put its **academic-plots** folder in one of
these locations. Do not copy only `SKILL.md`; keep its supporting files together.
Do not install duplicate copies under both user and project locations.

| Host | Personal installation | Project installation | Explicit invocation |
|---|---|---|---|
| Codex | `~/.agents/skills/academic-plots/` | `.agents/skills/academic-plots/` | `$academic-plots` |
| Claude Code | `~/.claude/skills/academic-plots/` | `.claude/skills/academic-plots/` | `/academic-plots` |

On Windows, `~` means your user profile directory. Host locations and reload
behaviour are documented by [OpenAI](https://learn.chatgpt.com/docs/build-skills)
and [Anthropic](https://code.claude.com/docs/en/skills). The skill can also be
selected automatically for relevant requests; no API key or connector is required
by this skill. Your agent must have access to R to render and verify plots.

The builder normalises text line endings and ZIP metadata while preserving font
bytes. GitHub Actions builds the ZIP and SHA-256 checksum as a downloadable
`academic-plots-bundle` artifact after successful validation. The bundle excludes
development tests and CI configuration; it contains the skill, helpers,
references, example, fonts and license notices.

Try: **"Use academic-plots to plot these estimates and confidence intervals for
a 3.5-inch journal column. Use Okabe-Ito and label the outcomes."**

## Requirements and a runnable example

Use R >= 4.3, ggplot2 >= 4.0.0 and scales >= 1.4.0. Install these explicitly in R:

```r
install.packages(c("ggplot2", "scales"), repos = "https://cloud.r-project.org")
```

Optional packages are feature-specific:

| Package | Feature |
|---|---|
| `ragg`, `systemfonts` | Raster text rendering and font discovery |
| `svglite` | SVG export |
| `ggrepel` | Collision-aware direct labels |
| `patchwork` | Composed figures |
| `sf`, `ggspatial`, `rnaturalearth` | Spatial data, map annotations and optional basemaps |
| `colorspace` | Colour-vision and greyscale checks |

The ordinary helpers need only ggplot2 and scales. Missing optional packages
require a fallback or an explicit installation; complex spatial/composition
templates cannot all run unchanged without their dependencies.

Run [the example](examples/quickstart.R) from the checkout or extracted bundle:

```sh
Rscript examples/quickstart.R output
```

This demonstration deliberately writes both `heatmap_title.png` and
`heatmap_no_title.png`, plus separate caption text. The output directory is
relative to your working directory; an absolute path is also accepted.
All data are generated inside the example. The script finds its helpers relative
to its own location, so it also runs from another working directory.

For your own project, copy `scripts/style.R` into the project and source that
local copy, or paste the helpers you need into your plotting script. Do not
depend on another user's skill-installation path. There is no package installer
inside the plotting helpers.

## Libre Franklin in PDF exports

The bundled fonts must be visible to the PDF renderer, not only to `systemfonts`.
On Windows, install the four faces for your current user and restart R:

```powershell
./scripts/install-fonts-windows.ps1
```

Use R >= 4.6.0 on Windows when exporting all font styles through Cairo. Set
`figure_family <- "Libre Franklin"` before constructing plots and verify actual
embedding with `pdffonts figure.pdf`. The detailed
[font guidance](references/style-guide.md) covers backend differences and other
platforms. The installer is explicit; plotting helpers never install fonts or
modify user settings when sourced.

## Proportional sizing

Text, points, line widths, margins and legends scale with the overall export size.
The template values describe a 7 x 5.5in reference figure; the export factor is
`sqrt((width / 7) * (height / 5.5))`. For example, 14 x 11in exports double every
visual size. Use `save_figure()` / `preview_figure()` so this also applies to
mapped sizes and compositions. Supply `reference = c(width, height)` for another
design size, or `reference = NULL` for explicitly fixed physical sizes.

### Panel marker sizes

Choose multipanel marker sizes for each panel's share of the total area first:
start with diameter and outline width multiplied by the square root of that
share (one half for four equal panels). The export helper then scales the whole
composition once; it does not infer or apply this panel adjustment automatically.
Keep text and confidence intervals readable. See [sizing guidance](references/style-guide.md)
and [multi-panel sizing](references/multi-panel.md#sizing-a-composed-figure).

## Defaults

### Titles, captions and footnotes

- **No title** for papers and presentations: no overall title, subtitle,
  caption, source note or footnotes in the image. Explanatory copy is supplied
  separately. Axis labels, units, legends and descriptive panel headings remain.
- **Title** for everything else, including an unspecified destination.
  Explicit user instructions override either default. Both versions are produced
  only when requested, with `_title` / `_no_title` suffixes when needed.

### Fonts and colours

- Libre Franklin typography, with actual font embedding checked for PDFs.
- Okabe-Ito categorical colours; Paul Tol continuous schemes; redundant encoding
  and contrast checks. Heatmap labels use the actual scaled fill colour.

### Axes, labels and uncertainty

- Omit categorical-axis titles while retaining category tick labels and numeric
  axis titles/units. This includes both axes of categorical heatmaps.
- Visible confidence intervals: full-opacity dark or series-coloured strokes,
  0.7 reference linewidth and end caps; black over coloured bars. Uncertainty
  ribbons start at alpha 0.28.

### Legends, panels and export

- Clean axes, deliberate legends and labels, and consistent panel dimensions.
  Banking applies to ordered lines/curves, with explicit geometry exceptions.
- 800 dpi final rasters and 150 dpi previews; vector output where appropriate.

These are configurable house preferences. The agent preserves your stated
dimensions, palette, destination and content choices.

## What is included

| Path | Purpose |
|---|---|
| [SKILL.md](SKILL.md) | Short entrypoint and essential decisions |
| [scripts/style.R](scripts/style.R) | Maintained R helpers, used by the current tests |
| [references/style-guide.md](references/style-guide.md) | Detailed rules, sizing and export guidance |
| [references/core-plots.md](references/core-plots.md) | Chart templates |
| [references/multi-panel.md](references/multi-panel.md), [maps.md](references/maps.md) | Composition and spatial guidance |
| [references/aspect-ratio.md](references/aspect-ratio.md), [accessibility.md](references/accessibility.md) | Banking and accessibility |
| [examples/quickstart.R](examples/quickstart.R) | Portable, generated-data example |
| `fonts/` | Libre Franklin; the bundle includes four static styles and the OFL notice |

The source repository includes `tests/` and a Windows/Linux validation workflow.
Tests use generated or built-in example data. Development files are excluded
from the installable ZIP.

## Validate a source checkout

```sh
Rscript --vanilla tests/run-tests.R tests/output
python tests/check-release.py
python scripts/package_skill.py
```

The R suite sources the current `scripts/style.R`, executes current chart
templates, tests low-range heatmap contrast and title/no title overrides,
and renders PNG/PDF smoke outputs. It does not rely on saved plot objects.
See the [development test guide](https://github.com/sarimzaf/academic-plots/blob/main/tests/README.md)
for dependencies, clean-environment runs and behavioural prompts.

Current local release checks pass on Windows with R 4.6.0 / ggplot2 4.0.3 /
scales 1.4.0, including ggrepel 0.9.8 and patchwork 1.3.2 integrations. CI
checks Windows and Linux with R release, bundled Libre Franklin selection,
and installation from the ZIP. Require a green run for the exact commit
before attaching a bundle to a release.

Codex discovery and six figure scenarios were checked with Codex CLI
0.163.0-alpha.10.2: journal, presentation, report, explicit title overrides,
panels and a retained note. Claude Code behavioural verification is pending.
Inspect every delivered figure at its final size; automated checks cannot
guarantee the layout of arbitrary user figures.

## License and contributions

Original code and guidance are [MIT licensed](LICENSE.md). See [NOTICE.md](NOTICE.md)
for copyright attribution, Paul Tol's palette notice, Libre Franklin's OFL
license. Those third-party terms are preserved in
the appropriate source files and bundle.

Bug reports should include a minimal dataset (synthetic where possible), the
plotting code, expected result and `sessionInfo()`. For changes, run the current
checks and inspect affected renders. Keep generated outputs under ignored
`tests/output/` or another temporary directory.
