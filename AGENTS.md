# AGENTS.md

> Agent instructions for **bambu-h2c** — Bambu Studio H2C profile customizations

## Project Context

This repo tracks customized Bambu Studio printer/filament profiles for the H2C toolhead. The upstream source is https://github.com/bambulab/BambuStudio. We maintain a rebasing workflow where the initial commit is unmodified upstream G-code and subsequent commits are our patches.

## Key Concepts

- **Machine G-code** — Bambu printers use template G-code with conditional logic (e.g. `{if filament_type[...] == "PLA"}`). These templates use BambuStudio's built-in macro syntax, not standard G-code.
- **Filament types** — BambuStudio recognizes types like `PLA`, `PLA-CF`, `PETG`, `PETG-CF`, `PCTG`, `PCTG-CF`, `TPU`, `ABS`, `ASA`, `PA`, `PA-CF`, `PPA-CF`, `PPS`, `PPS-CF`, etc.
- **Bed types** — `Textured PEI Plate`, `Cool Plate`, `Engineering Plate`, `High Temp Plate`
- **Upstream version** — The current baseline is from BambuStudio **v2.5.0.66** (date `20251210` for start, `20251111` for end).

## File Conventions

| Path                        | Content                              |
| --------------------------- | ------------------------------------ |
| `machine-gcode/start.gcode` | H2C machine start G-code template    |
| `machine-gcode/end.gcode`   | H2C machine end G-code template      |
| `machine-gcode/history.md`  | Change log for G-code customizations |

Future additions may include:

- `filament-profiles/` — JSON filament profile overrides
- `docs/` — Behavioral notes, issue drafts, research

## Editing G-code Templates

- The G-code uses BambuStudio macro syntax: `{if ...}`, `{elsif ...}`, `{endif}`, `{expression}`
- Variables include `filament_type[n]`, `curr_bed_type`, `nozzle_diameter`, `bed_temperature_initial_layer_single`, etc.
- `initial_no_support_extruder` is the index of the first extruder not used exclusively for support
- When adding filament types to conditional blocks, maintain the existing style (same operators, same line-break patterns)
- Always add a comment explaining **why** a change was made

## Git Workflow

- Commit messages should describe the behavioral change, not just "edited file"
- Reference the upstream BambuStudio version when importing new baselines
- Keep customization commits atomic — one logical change per commit
- When documenting a change, note the problem, the fix, and which filament/bed combos are affected

## Do Not

- ❌ Reformat or restructure upstream G-code — keep diffs minimal and rebaseable
- ❌ Remove existing upstream comments or blank lines
- ❌ Combine unrelated fixes in a single commit
- ❌ Use `G29.1 Z` offset values without documenting the reasoning
- ❌ Add filament types to conditional blocks without checking all occurrences in the file

## Safety

- ✅ **Can do**: Edit G-code templates, create documentation, draft issues
- ⚠️ **Ask first**: Rebase operations, force-push, delete branches
- ⚠️ **Ask first**: Changes that affect print behavior for previously-working filaments

## See Also

- [README.md](README.md) — Project overview and workflow
