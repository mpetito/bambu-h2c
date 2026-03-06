# Machine G-code Change History

Baseline: BambuStudio **v2.5.0.66** H2C profile (start: `20251210`, end: `20251111`)

## PCTG / PCTG-CF Support (`start.gcode`)

**Problem:** The stock H2C start G-code applies a `-0.02` Z-offset for Textured PEI plates (`G29.1 Z{-0.02}`), but PCTG needs extra first-layer clearance. Additionally, PCTG and PCTG-CF are missing from the air-printing detection filament list.

**Fix:**

- Skip the Textured PEI plate Z-offset adjustment when printing PCTG or PCTG-CF
- Add PCTG and PCTG-CF to the `M1015.4 S1 K1` air-printing detection filament type list
