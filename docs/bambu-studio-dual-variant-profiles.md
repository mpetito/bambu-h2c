# Bambu Studio Dual-Variant Filament Profiles

## How Standard + High Flow nozzle support works in a single filament profile

Bambu Studio supports filament profiles that work with both **Standard** and **High Flow** nozzles using a **variant array indexing system**. This document explains the mechanism for reference when creating or modifying profiles.

---

## The Variant Array System

Many filament parameters (like `filament_max_volumetric_speed`) are stored as **arrays**, where each element corresponds to a different `filament_extruder_variant`. The variant string acts as an index selector.

### Positional alignment

The dual-variant template `fdm_filament_template_direct_dual.json` defines:

```json
"filament_extruder_variant": [
    "Direct Drive Standard",
    "Direct Drive High Flow"
]
```

All variant-aware parameters use the same indexing:

- **Index 0** → `"Direct Drive Standard"` — used when a standard nozzle is selected
- **Index 1** → `"Direct Drive High Flow"` — used when an HF nozzle is selected

### Example

```json
"filament_max_volumetric_speed": [
    "10",
    "16"
]
```

This means: 10 mm³/s with the standard nozzle, 16 mm³/s with the HF nozzle.

---

## How the slicer resolves the correct value

1. **Filament profiles** define per-variant values as arrays and include the template:

   ```json
   "include": ["fdm_filament_template_direct_dual"]
   ```

2. **Printer profiles** declare supported variants via `printer_extruder_variant`. When you select "High Flow" in the slicer UI, the active variant becomes `"Direct Drive High Flow"`.

3. **At slice time**, the function `get_index_for_extruder_parameter()` in [`ParameterUtils.cpp`](https://github.com/bambulab/BambuStudio/blob/6a3e8bb3888b549df716a56266c1f6f3d0259012/src/libslic3r/ParameterUtils.cpp#L51-L79) matches the printer's `NozzleVolumeType` against the `filament_extruder_variant` array to find the positional index, then reads the corresponding element from each variant-aware parameter.

---

## Variant-aware parameters

The following parameters (from `fdm_filament_template_direct_dual.json`) support per-variant values:

| Category          | Parameters                                                                                                                                                                                                                                                                                                               |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Flow**          | `filament_max_volumetric_speed`, `filament_flow_ratio`, `filament_adaptive_volumetric_speed`, `filament_flush_volumetric_speed`                                                                                                                                                                                          |
| **Retraction**    | `filament_retraction_length`, `filament_retraction_speed`, `filament_retraction_minimum_travel`, `filament_retract_before_wipe`, `filament_retract_restart_extra`, `filament_retract_when_changing_layer`, `filament_retraction_distances_when_cut`, `filament_deretraction_speed`, `filament_long_retractions_when_cut` |
| **Wipe/Z-hop**    | `filament_wipe`, `filament_wipe_distance`, `filament_z_hop`, `filament_z_hop_types`                                                                                                                                                                                                                                      |
| **Overhang**      | `filament_overhang_1_4_speed`, `filament_overhang_2_4_speed`, `filament_overhang_3_4_speed`, `filament_overhang_4_4_speed`, `filament_overhang_totally_speed`, `filament_bridge_speed`, `filament_enable_overhang_speed`, `override_process_overhang_speed`                                                              |
| **Cooling**       | `slow_down_min_speed`, `filament_pre_cooling_temperature`, `filament_pre_cooling_temperature_nc`                                                                                                                                                                                                                         |
| **Ramming**       | `filament_ramming_volumetric_speed`, `filament_ramming_volumetric_speed_nc`, `filament_ramming_travel_time_nc`                                                                                                                                                                                                           |
| **NC retraction** | `filament_retract_length_nc`                                                                                                                                                                                                                                                                                             |
| **EC retraction** | `long_retractions_when_ec`, `retraction_distances_when_ec`                                                                                                                                                                                                                                                               |
| **Other**         | `filament_flush_temp`, `volumetric_speed_coefficients`                                                                                                                                                                                                                                                                   |

Additionally, `nozzle_temperature` and `nozzle_temperature_initial_layer` use dual values in Bambu's own profiles (e.g., PETG Basic @BBL H2C).

---

## Creating a dual-variant user profile

To convert an existing single-variant filament profile:

1. **Add the include directive:**

   ```json
   "include": ["fdm_filament_template_direct_dual"]
   ```

2. **Add the second variant to `filament_extruder_variant`:**

   ```json
   "filament_extruder_variant": [
       "Direct Drive Standard",
       "Direct Drive High Flow"
   ]
   ```

3. **Convert all variant-aware parameters** from single-element to dual-element arrays. For each parameter, the first element keeps the existing standard value and the second element is the HF value.

4. **Set differentiated HF values** where the High Flow nozzle warrants different behavior (typically: higher MVS, adjusted retraction, etc.).

5. **Keep non-variant parameters** as single-element arrays — only the parameters listed above need dual values.

---

## Reference: Bambu PETG comparison (H2C 0.4mm nozzle)

Values from Bambu's official profiles showing Standard (index 0) vs HF (index 1):

| Parameter                       | PETG Basic  | PETG HF     |
| ------------------------------- | ----------- | ----------- |
| `filament_max_volumetric_speed` | 18 / 21     | 25 / 35     |
| `filament_flow_ratio`           | 0.97 / 0.97 | 0.97 / 0.97 |
| `filament_retraction_length`    | 0.4 / 0.4   | 0.4 / 0.6   |
| `filament_wipe_distance`        | 1 / 1       | 1 / 1       |
| `slow_down_min_speed`           | (inherited) | 20 / 20     |
| `nozzle_temperature`            | 250 / 250   | 245 / 245   |

---

## Source references

- Template: `BambuStudio/resources/profiles/BBL/filament/fdm_filament_template_direct_dual.json`
- Lookup function: [`ParameterUtils.cpp:get_index_for_extruder_parameter()`](https://github.com/bambulab/BambuStudio/blob/6a3e8bb3888b549df716a56266c1f6f3d0259012/src/libslic3r/ParameterUtils.cpp#L51-L79)
- Calibration usage: [`CalibUtils.cpp`](https://github.com/bambulab/BambuStudio/blob/6a3e8bb3888b549df716a56266c1f6f3d0259012/src/slic3r/Utils/CalibUtils.cpp#L775-L778)
