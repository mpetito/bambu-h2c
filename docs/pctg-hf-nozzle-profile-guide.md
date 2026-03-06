# 3D Fuel PCTG Pro — High Flow Nozzle Profile Optimization Guide
## For the Bambu Lab H2C with Tungsten Carbide HF 0.4mm Nozzle

---

## Executive Summary

This report provides a complete set of recommendations for optimizing the existing 3D-Fuel PCTG Pro filament profile (currently at 10 mm³/s max volumetric speed, 275°C) for use with the Bambu H2C's High Flow (HF) tungsten carbide 0.4mm nozzle. The current profile is already significantly tuned beyond 3D Fuel's published defaults and has a strong thermal foundation. Five specific JSON-level changes are recommended, along with a companion process profile checklist and calibration workflow. The estimated daily-driver max volumetric speed target for the HF nozzle is **16 mm³/s**, with a tested ceiling likely in the 20–24 mm³/s range.

---

## 1. Current Profile Assessment

The profile (`3D-Fuel PCTG Pro @Bambu Lab H2C 0.4 nozzle`, updated 1/6/26) has already been substantially modified from 3D Fuel's published 2.0 profile. The table below compares the current values against 3D Fuel's official defaults and identifies the status of each setting.

### 1.1 Comparison to 3D Fuel Published Defaults

| Setting | 3D Fuel 2.0 Default | Current Profile | Status |
|---------|---------------------|-----------------|--------|
| Max Volumetric Speed | 6 mm³/s | 10 mm³/s | ✅ Already increased +67% |
| Nozzle Temperature | 255°C | 275°C | ✅ Already in high-speed band |
| First Layer Temperature | 270°C | 275°C | ✅ Matched to print temp |
| Temp Range High | 280°C | 300°C | ✅ Extended headroom |
| Bed Temperature | 80°C | 80°C | ✅ Matches latest guidance |
| Flow Ratio | 1.0 | 0.97 | ⚠️ Below recommended |
| Fan Min Speed | — | 10% | ✅ Conservative cooling |
| Fan Max Speed | 40% | 50% | ⚠️ Slightly high |
| Overhang Fan | 90% | 90% | ✅ Correct |
| Z-Hop | 0.6mm | 0.6mm | ✅ Matches updated guidance |
| Wipe Enabled | Yes | Yes (1mm distance) | ✅ Correct |
| Retraction Length | — | 0.4mm | ⚠️ May be insufficient for HF |
| Pressure Advance | 0.02 (disabled) | 0.02 (disabled) | ✅ Correct — see Section 2 |
| Extruder Variant | — | Direct Drive Standard | ❌ Must change for HF |
| Infill Pattern | Cubic (process) | (process profile) | Verify Cubic, not Grid |

### 1.2 Settings Already Well-Tuned

The following settings require no changes for HF optimization:

- **Nozzle temperature (275°C)**: Already in the optimal 270–280°C band for high-speed PCTG printing. 3D Fuel recommends "hotter for faster speeds" and the H2C supports up to 350°C.
- **Bed temperature (80°C)**: Matches 3D Fuel's updated Bambu guidance.
- **Z-hop (0.6mm)**: 3D Fuel specifically updated their profiles from 0.4mm to 0.6mm to reduce nozzle buildup.
- **Wipe enabled with 1mm distance**: 3D Fuel explicitly recommends wipe for PCTG, "especially on 3D printers equipped with a High Flow nozzle."
- **Close fan first 3 layers**: Reasonable for bed adhesion.
- **Slow down layer time (12s)**: Matches 3D Fuel's updated minimum.
- **Filament density (1.23 g/cm³)**: Correct for PCTG.
- **Required nozzle HRC (3)**: The tungsten carbide nozzle (HRA 90) far exceeds this.

---

## 2. Pressure Advance: Keep Disabled in Filament Profile

### 2.1 Why `enable_pressure_advance = 0` Is Correct

The current setting of `enable_pressure_advance = 0` with a stored `pressure_advance = 0.02` is **the standard and correct configuration for all Bambu Studio filament profiles**. This is not a bug or oversight.

Bambu's architecture separates PA management from the filament profile:

- **In the filament JSON**: `enable_pressure_advance = 0` means "do not embed a PA override in the g-code." The g-code will contain `; enable_pressure_advance = 0` as a comment, and the printer will ignore the profile's K value.
- **On the printer hardware**: PA/K values are stored per-filament on the printer itself, managed via the Device tab in Bambu Studio or through the Flow Dynamics Calibration system.
- **Bambu's reasoning**: Bambu intentionally keeps PA at the printer level because K values can vary between individual machines, nozzles, and hotend conditions. They pushed back on requests to add PA to filament profiles for this reason.

### 2.2 How PA Actually Works on the H2C

The H2C (like the H2D and A1 series) uses an **eddy current sensor** in the toolhead to perform real-time Flow Dynamics Calibration. This is superior to a static K value in a profile because it measures actual filament behavior at the nozzle.

There are three pre-print calibration modes:

| Mode | Behavior | When to Use |
|------|----------|-------------|
| **Automatic** | Checks if filament+nozzle combo was recently calibrated. Reuses last value if unchanged; recalibrates if nozzle or filament changed. | Recommended default for daily use |
| **Open** | Calibrates before every print. Result applies only to that print. | Use when switching filaments frequently or testing new MVS |
| **Off** | Uses the manually-saved K value from the printer's stored PA profile. If no profile exists, uses system defaults. | Use after manual calibration with known-good K value |

**Important H2C/H2D-specific behavior**: These printers use a "more sophisticated flow calibration algorithm" that dynamically adjusts compensation based on printer model, nozzle type, and filament type. Even with the "Default" PA profile (no manual calibration), the system provides intelligent compensation.

### 2.3 Recommended PA Workflow

1. **Do NOT change `enable_pressure_advance` to `1`** — this would bypass the H2C's hardware calibration system and force a static K value from the profile.
2. **Run Flow Dynamics Calibration** (auto mode) on the H2C specifically for this filament with the HF nozzle installed. The HF nozzle's larger melt zone will produce a different optimal K value than the standard nozzle.
3. **Save the result** to the printer via Bambu Studio's "Manage Result" page.
4. **Set pre-print calibration to "Automatic"** for daily use, or "Open" during the initial tuning phase.
5. **Re-run calibration** after changing the MVS significantly (e.g., moving from 10 to 16 mm³/s), as higher flow rates affect optimal PA.

### 2.4 OrcaSlicer Exception

If the team uses OrcaSlicer instead of Bambu Studio, OrcaSlicer *does* support `enable_pressure_advance = 1` in the filament profile, which injects an `M900 K<value>` command into the g-code. This overrides both stored calibrations and automatic pre-print calibration. Only use this approach if:
- The slicer is OrcaSlicer (not Bambu Studio)
- A precise K value has been determined through manual testing
- Consistency across multiple printers is not required

For Bambu Studio workflows, leave `enable_pressure_advance = 0`.

---

## 3. Recommended Profile Changes

### 3.1 Required Changes (JSON Fields)

These five changes should be applied to create the HF variant:

#### Change 1: Extruder Variant
```json
"filament_extruder_variant": ["Direct Drive High Flow"]
```
**Rationale**: Bambu Studio uses this field to apply HF-specific speed calculations and nozzle parameters. With "Direct Drive Standard" selected, the slicer may throttle speeds below the HF nozzle's capability. Bambu's own filament profiles carry separate settings per extruder variant, and selecting "Direct Drive High Flow" unlocks the correct speed logic.

**Impact**: This is the single most important change. Without it, increasing MVS may have limited or no effect on actual print speeds.

#### Change 2: Max Volumetric Speed
```json
"filament_max_volumetric_speed": ["16"]
```
**Rationale**: 16 mm³/s is the recommended starting point for balanced HF printing with a 0.4mm nozzle at 275°C. This represents a 60% increase over the current 10 mm³/s. See Section 4 for the full estimation methodology and alternative targets.

**Impact**: Primary speed improvement. At 0.2mm layer height with 0.45mm line width, this allows speeds up to ~178 mm/s before the MVS governor kicks in (vs. ~111 mm/s at 10 mm³/s).

#### Change 3: Flow Ratio
```json
"filament_flow_ratio": ["1.0"]
```
**Rationale**: 3D Fuel explicitly recommends 1.0 for Pro PCTG and warns that the generic Bambu PCTG value of 0.95 "causes visible holes and weaker parts." The current 0.97 is better than 0.95 but still below 3D Fuel's recommendation. After switching to the HF nozzle, this should be verified via flow rate calibration.

**Impact**: Eliminates potential under-extrusion that can manifest as micro-gaps in walls and reduced part strength.

#### Change 4: Retraction Length
```json
"filament_retraction_length": ["0.8"]
```
**Rationale**: The current 0.4mm is below the typical Bambu direct-drive default of 0.8mm. The HF nozzle's larger melt zone creates a bigger pool of molten filament under pressure. PCTG is already a notoriously oozy material. With higher flow rates, 0.4mm of retraction is unlikely to relieve enough pressure during travel moves.

**Impact**: Reduces stringing and ooze during non-print travel moves. May need further increase to 1.0–1.2mm if stringing persists at higher MVS values.

#### Change 5: Wipe Distance
```json
"filament_wipe_distance": ["2"]
```
**Rationale**: 3D Fuel specifically recommends increased wipe behavior for PCTG on HF nozzles. The current 1mm wipe distance may be insufficient at higher flow rates where more residual pressure exists at retraction points.

**Impact**: Cleaner travel moves, reduced blob formation at seam points.

### 3.2 Optional / Conditional Changes

| Setting | Current | Suggested | Condition |
|---------|---------|-----------|-----------|
| `fan_max_speed` | 50 | 35–40 | If surface finish issues appear; 3D Fuel's profile uses 40% |
| `nozzle_temperature` | 275 | 280 | Only if pushing MVS above 18 mm³/s |
| `during_print_exhaust_fan_speed` | 70 | 40–50 | If printing enclosed; 3D Fuel recommends warm chamber (~45°C) |
| `complete_print_exhaust_fan_speed` | 70 | 70 | Keep — post-print ventilation is fine |
| `filament_bridge_speed` | 25 | 20 | If bridge quality degrades at higher flow |
| `filament_adaptive_volumetric_speed` | 0 | 1 | Consider enabling for dynamic flow adjustment by geometry |

### 3.3 Settings to NOT Change

| Setting | Current Value | Why Keep It |
|---------|--------------|-------------|
| `enable_pressure_advance` | 0 | Correct for Bambu ecosystem (see Section 2) |
| `pressure_advance` | 0.02 | Dormant placeholder — PA managed by printer hardware |
| `filament_z_hop` | 0.6 | Matches 3D Fuel's anti-buildup guidance |
| `filament_wipe` | 1 | Already enabled |
| `overhang_fan_speed` | 90 | Correct for overhangs |
| `close_fan_the_first_x_layers` | 3 | Good for adhesion |
| `slow_down_layer_time` | 12 | Appropriate minimum |
| `hot_plate_temp` / `eng_plate_temp` | 80 | Correct for PCTG |
| `filament_cost` | 29.95 | Informational only |
| `filament_density` | 1.23 | Correct for PCTG |

---

## 4. Max Volumetric Speed Estimation

### 4.1 Methodology

The MVS estimates are derived from three data sources:

1. **Bambu official HF nozzle data**: The 0.4mm HF tungsten carbide nozzle increases PETG HF throughput from 24 to 32 mm³/s — a 33% increase over the standard hardened steel nozzle. For the 0.6mm HF nozzle, PETG HF reaches 40 mm³/s.

2. **PCTG vs. PETG flow equivalence**: Independent volumetric flow testing shows PCTG reaching 24–26 mm³/s at 260°C on high-flow-capable hardware, closely matching PETG results of ~25 mm³/s on the same equipment. At 275°C (this profile's temperature), PCTG should flow at least as well.

3. **3D Fuel's own testing history**: 3D Fuel originally set their profile to 20 mm³/s but reduced it to 6 mm³/s because longer layers developed inconsistent matte/gloss appearance on standard nozzles. The HF nozzle's improved melt capability should push this threshold higher.

### 4.2 Recommended Targets by Use Case

| Use Case | MVS Target | Temperature | Expected Print Quality |
|----------|-----------|-------------|----------------------|
| **Quality / Glossy** | 12–14 mm³/s | 275°C | Consistent glossy finish equivalent to current 10 mm³/s on standard nozzle |
| **Balanced / Functional** | 16–18 mm³/s | 275°C | Good surface quality; may see minor gloss variation on very long layers |
| **Speed / Structural** | 20–22 mm³/s | 275–280°C | Acceptable for functional parts; some finish inconsistency likely |
| **Experimental Max** | 24+ mm³/s | 280°C | Hardware limit zone; requires favorable geometry and careful tuning |

### 4.3 Speed Translation

For reference, at 0.2mm layer height and 0.45mm line width:

| MVS (mm³/s) | Max Print Speed (mm/s) | Improvement vs. Current |
|-------------|----------------------|------------------------|
| 10 (current) | ~111 mm/s | Baseline |
| 14 | ~156 mm/s | +40% |
| 16 | ~178 mm/s | +60% |
| 18 | ~200 mm/s | +80% |
| 22 | ~244 mm/s | +120% |

**Note**: These are the maximum speeds the MVS governor will allow. Actual print speeds also depend on the process profile's speed settings, acceleration limits, and geometry. Increasing MVS without raising process profile speeds will yield zero time savings.

---

## 5. Companion Process Profile Requirements

The filament profile changes above will only take effect if the process profile's speed and acceleration settings allow the printer to reach the new MVS-derived speeds. The following process profile settings should be reviewed:

### 5.1 Speed Settings

| Feature | Current Typical | Recommended for HF |
|---------|----------------|-------------------|
| Outer Wall | 50–100 mm/s | 80–120 mm/s (quality dependent) |
| Inner Wall | 100–150 mm/s | 150–250 mm/s (MVS will govern) |
| Infill | 150–200 mm/s | 200–300 mm/s (biggest HF benefit) |
| Top Surface | 100 mm/s | 100 mm/s (keep conservative) |
| Bridge | 25 mm/s | 20–25 mm/s (keep conservative) |

### 5.2 Acceleration Settings

**Critical**: PCTG's nozzle buildup problem is primarily acceleration-driven, not flow-driven. The viscous material stays where deposited, and aggressive direction changes cause the toolhead to scrape previously deposited material.

| Feature | Bambu Default | Recommended for PCTG |
|---------|--------------|---------------------|
| General / Outer Wall | 10,000 mm/s² | 2,000 mm/s² |
| Top Surface | 10,000 mm/s² | 1,000 mm/s² |
| Travel | 10,000 mm/s² | 5,000 mm/s² |

### 5.3 Infill Pattern

Use **Cubic** infill, NOT Grid. Grid infill is specifically identified by 3D Fuel as problematic for PCTG nozzle buildup due to its crossing toolpath pattern.

---

## 6. Calibration Workflow

After applying the JSON changes, perform the following calibrations in order:

### Step 1: Flow Dynamics Calibration (Pressure Advance)
- Run the H2C's automatic Flow Dynamics Calibration with the HF nozzle installed
- Save the result to the printer
- Set pre-print mode to "Automatic" for ongoing use
- **Must be re-run** after significant MVS changes

### Step 2: Flow Ratio Verification
- Run a flow ratio calibration print
- Verify that 1.0 is correct with the HF nozzle geometry
- Adjust only if clear over-extrusion is observed (unlikely given 3D Fuel's guidance)

### Step 3: Max Volumetric Flow Tower
- Use Bambu Studio's built-in flow rate test OR Orca Slicer's calibration tower
- Temporarily set MVS very high (~100 mm³/s) so it doesn't bottleneck the test
- Start at 10 mm³/s, step by 1–2 mm³/s up to ~30 mm³/s
- Identify where under-extrusion begins
- Set final MVS **2–3 steps below** the failure point
- Reduce a further 10–20% from that number for a reliability margin

### Step 4: Retraction Test
- Print a multi-object stringing test (multiple small towers with travel moves between them)
- Start with 0.8mm retraction
- Increase to 1.0–1.2mm if stringing persists
- Test with wipe distance at 2mm

### Step 5: Real-World Validation Print
- Print a functional test part with mixed features (walls, overhangs, bridges, infill)
- Check for: matte/gloss consistency on long layers, corner quality, nozzle buildup
- If matte striping appears on long layers, reduce MVS by 2 mm³/s

---

## 7. Summary of JSON Changes

### Minimum Viable Changes (apply immediately)

```json
{
    "filament_extruder_variant": ["Direct Drive High Flow"],
    "filament_max_volumetric_speed": ["16"],
    "filament_flow_ratio": ["1.0"],
    "filament_retraction_length": ["0.8"],
    "filament_wipe_distance": ["2"]
}
```

### Profile Naming Convention

Rename the profile to clearly indicate HF nozzle use:
```json
{
    "name": "3D-Fuel PCTG Pro @Bambu Lab H2C 0.4 HF nozzle",
    "filament_settings_id": ["3D-Fuel PCTG Pro @Bambu Lab H2C 0.4 HF nozzle"]
}
```

### Optional: Create Tiered Variants

For teams needing both quality and speed options:

| Variant | MVS | Temp | Use |
|---------|-----|------|-----|
| `...0.4 HF nozzle - Quality` | 12 | 275 | Display/aesthetic parts |
| `...0.4 HF nozzle` | 16 | 275 | General functional (default) |
| `...0.4 HF nozzle - Speed` | 20 | 280 | Rapid prototyping, structural |

---

## 8. Known Risks and Watch Items

- **Nozzle buildup**: PCTG's viscous nature makes it prone to material accumulating on the nozzle tip. Higher flow rates and acceleration exacerbate this. Primary mitigations are reduced acceleration, Cubic infill, and wipe-on-retract.
- **Matte/gloss striping**: At flow rates above ~18 mm³/s, longer layers may not maintain consistent surface gloss. This is the specific issue that caused 3D Fuel to reduce their original 20 mm³/s profile to 6 mm³/s on standard nozzles.
- **CHT-style nozzle caution**: Community reports indicate that CHT split-flow nozzles cause bubbling/burning with PCTG. The Bambu HF tungsten carbide nozzle uses a different geometry (optimized melt zone, not filament-splitting), so this should not apply — but monitor initial prints.
- **No official 3D Fuel HF profile exists yet**: These recommendations are derived from hardware specifications, community testing, and 3D Fuel's published guidance. An official profile may eventually be released.
- **Exhaust fan vs. chamber warmth**: The current 70% exhaust fan during printing actively removes warm air from the enclosure. 3D Fuel recommends warm enclosures for PCTG (~45°C chamber temp). Consider reducing exhaust during printing if odor permits.

---

## Appendix A: Reference Data

### Bambu HF 0.4mm Nozzle — Official Max Volumetric Speeds

| Material | Standard HS 0.4mm | HF TC 0.4mm | Increase |
|----------|-------------------|-------------|----------|
| PLA Basic | 24 mm³/s | 40 mm³/s | +67% |
| PLA Matte | 28 mm³/s | 48 mm³/s | +71% |
| PETG HF | 24 mm³/s | 32 mm³/s | +33% |

PCTG is more viscous than PETG, so the 33% PETG HF number is the most relevant comparator (not the 67% PLA number).

### 3D Fuel PCTG Pro — Manufacturer Specifications

- Recommended nozzle temp: 260–280°C
- Recommended bed temp: 75–80°C
- Glass transition temp: 76°C (TDS) / 84°C (profile `temperature_vitrification`)
- Density: 1.23 g/cm³
- Hardened nozzle required for matte colors

### H2C Platform Capabilities

- Max hotend temperature: 350°C
- Standard flow hotend max: 40 mm³/s (ABS, 280°C)
- HF hotend max: 65 mm³/s (ABS, 280°C)
- Active chamber heating: up to 65°C
- Flow Dynamics Calibration: eddy current sensor (automatic)
- Nozzle system: Vortek magnetic quick-swap
