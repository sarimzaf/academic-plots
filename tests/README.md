# Validation

## Current release checks

From a source checkout, install the core R dependencies explicitly:

```r
install.packages(c("ggplot2", "scales"), repos = "https://cloud.r-project.org")
# Optional integration checks and preferred raster renderer:
install.packages(c("ggrepel", "patchwork", "ragg", "systemfonts"),
                 repos = "https://cloud.r-project.org")
```

Then run in fresh R processes:

```sh
Rscript --vanilla tests/run-tests.R tests/output
python tests/check-release.py
Rscript --vanilla examples/quickstart.R tests/output/example
```

R >= 4.3, ggplot2 >= 4.0.0, scales >= 1.4.0 and Python >= 3.9 are required.
The checks do not install packages, read a personal library path, load saved plot
objects or depend on previous exports. `--vanilla` avoids user startup files.
Package lookup follows normal R library configuration. Optional integration
tests report `SKIP` when their package is absent; CI installs those packages.
CI also installs the four bundled font faces in its temporary runner and requires
Libre Franklin to be selected by default before exercising portable fallback renders.

`run-tests.R` sources the current `scripts/style.R`, parses all current reference
R blocks, executes data-complete chart templates, and checks:

- Contrast against actual scaled heatmap fills at 0.25, 0.5 and 1 ceilings,
  including missing-value colours.
- Title/no title destination defaults, both directions of explicit override,
  removal of rendered title/subtitle/caption grobs, and retained facet strips.
- Coefficient and scatter templates, optional labelled-scatter/composition
  integration, zero/number helpers and the actual size of an 800 dpi PNG.
- Omitted categorical-axis titles with tick labels and numeric units retained;
  full-opacity confidence intervals with contrast checks.
- Proportional text, points, line widths, guides and compositions at three sizes;
  mapped-size scales, unchanged source plots/data, and fixed-size overrides.
- PNG/PDF exports and a recorded `sessionInfo()` for the run.

Inspect the generated images and PDFs before release. Automated checks cannot
prove that arbitrary user figures have good layouts. The example intentionally
exports both variants; normal skill use creates both only on request.

`check-release.py` uses Python's standard library. It verifies local document
links and heading anchors, package contents, required license files, portable
paths, unchanged font bytes, platform-independent member ordering and ZIP bytes across LF/CRLF checkouts,
and the checksum. Run the example from an extracted bundle in a
different working directory as an installation smoke check. GitHub Actions
performs that check on Windows and Linux in addition to the source tests.

## Publishing a validated release

1. Run the checks above and inspect affected renders. Test the behavioural prompts
   below in each host for which you claim support; helper tests alone do not test
   agent discovery or instruction following.
2. Commit the intended source, then require the Windows and Linux jobs to pass
   for that exact commit. Do not use an artifact from an older successful run.
3. Download `academic-plots-bundle` from the successful Linux job and verify the
   ZIP against its adjacent SHA-256 file (`sha256sum` or PowerShell `Get-FileHash`).
4. Attach that ZIP and checksum to the release for the tested commit. Describe
   changes and tested versions, including any untested platforms or features.
   Use the curated ZIP for installation; the source archive also contains
   development tests and CI configuration.

## Behavioural prompts for a release review

Use generated data and evaluate the delivered result, not just the prose:

1. Make a 3.5-inch journal figure: expect no overall title/subtitle/footnotes and
   separate caption copy.
2. Make presentation figures from the same data: expect the same no title default.
3. Make a standalone report figure: expect a title and useful explanatory text.
4. Ask for a title on the journal figure, then no title on the report figure:
   each explicit request takes precedence.
5. Ask for a two-panel no title figure: preserve descriptive panel headings,
   axes and legends while removing overall labels and each panel's footnotes.
6. Explicitly ask to keep a note on an otherwise untitled figure: retain it as
   the requested exception and do not claim the default was applied unchanged.

The helper tests encode these selection rules, but are not a substitute for
testing an agent's natural-language interpretation in its host environment.
