# bambu-h2c

Customizations and documentation for the Bambu Lab H2C printer profiles in [BambuStudio](https://github.com/bambulab/BambuStudio).

## Purpose

This repo tracks:

- **Machine G-code overrides** — modified start/end G-code for the H2C toolhead
- **Filament profile tweaks** — adjusted parameters for specific filament types (e.g. PCTG, PCTG-CF)
- **Behavioral documentation** — notes on quirks, workarounds, and undocumented behaviors
- **Upstream issue drafts** — bug reports and feature requests destined for the BambuStudio repo

## Repo Structure

```
machine-gcode/
  start.gcode    # Machine start G-code (based on upstream H2C profile)
  end.gcode      # Machine end G-code
  history.md     # Change log for G-code customizations
```

## Workflow

### Tracking Upstream

The initial commit contains unmodified G-code from Bambu Studio's built-in H2C profile. Customizations are layered on top as separate commits so we can:

1. **Diff against upstream** — see exactly what we changed and why
2. **Rebase onto new versions** — when Bambu updates their machine G-code, create a branch from the new upstream baseline and rebase our changes onto it
3. **Cherry-pick fixes** — apply individual fixes independently

### Versioning Convention

Commit messages reference the upstream BambuStudio version the baseline was taken from (e.g. `v2.5.0.66`). When Bambu ships a new version:

1. Create a branch for the new upstream baseline
2. Replace machine G-code with the new upstream version
3. Rebase customization commits onto the new baseline

## Upstream Reference

- **BambuStudio repo:** https://github.com/bambulab/BambuStudio
- **Profile source:** BambuStudio system profiles (`resources/profiles/BBL/`)
- **Machine G-code location in BambuStudio:** `resources/profiles/BBL/machine/` (embedded in JSON printer profile)
