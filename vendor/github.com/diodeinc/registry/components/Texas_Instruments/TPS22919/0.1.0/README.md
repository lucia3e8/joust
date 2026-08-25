# TPS22919 — TI 5.5 V, 1.5 A load switch with controlled slew rate (SC-70-6)

Single gated power rail: TPS22919 plus input/output bypass, the QOD strap
that sets off-state discharge, and an external ON pull-down that makes the
rail default-off when nothing drives the enable.

## Parts

| `automotive` | MPN | Grade | Sourcing alternates |
|---|---|---|---|
| `False` (default) | TPS22919DCKR | catalog, −40 to 105 °C | TPS22919DCKT (250-pc reel) |
| `True` | TPS22919QDCKRQ1 | AEC-Q100 grade 1, −40 to 125 °C | — |

Both are SC-70-6 (DCK) with identical pinout and specifications. Slew rate
is fixed silicon; TI has no pin-compatible SC-70-6 sibling with a different
rise time. TPS22917 / TPS22918 add a CT pin for adjustable rise time but are
SOT-23-6 with a different pinout, so they need a separate package.

## Configuration

| Config | Type | Default | Effect |
|---|---|---|---|
| `automotive` | bool | `False` | Selects the AEC-Q100 orderable |
| `discharge` | `Internal` / `External` / `Off` | `Internal` | QOD strap: 0 Ω to VOUT, `r_qod` in series, or depopulated |
| `r_qod` | Resistance | `1kohm` | Series QOD resistance when `discharge="External"` |
| `c_in` | Capacitance | `1uF` | Input bypass (0402, 10 V) |
| `c_out` | Capacitance | `1uF` | Local output bypass (0402, 10 V); sets inrush = C × slew rate |
| `on_pulldown` | bool | `True` | Populate R_ON_PD |
| `on_pulldown_resistance` | Resistance | `100kohm` | R_ON_PD value |

## Examples

```zen
TPS22919 = Module("github.com/diodeinc/registry/components/Texas_Instruments/TPS22919/TPS22919.zen")

# microSD slot VDD, gated by an MCU GPIO. Default-off, fast discharge.
TPS22919(
    name="U_SD_PWR",
    VIN = V3V3,
    VOUT = V3V3_SD,
    GND = GND,
    ON = SD_PWR_EN,
)

# 5 V LED domain: extra local bulk, still discharged on gate-off.
TPS22919(
    name="U_LED_PWR",
    c_out = "10uF",
    VIN = V5,
    VOUT = V5_LED,
    GND = GND,
    ON = LED_PWR_EN,
)

# Slow the fall for power-down sequencing (R_DIS = 24 Ohm + r_qod).
TPS22919(
    name="U_SAT_PWR",
    discharge = "External",
    r_qod = "1kohm",
    VIN = V3V3,
    VOUT = V3V3_SAT,
    GND = GND,
    ON = SAT_PWR_EN,
)
```

## Integration notes

- `ON` thresholds (V_IH ≥ 1 V, V_IL ≤ 0.35 V) are referenced to GND, not
  VIN, so a 3.3 V GPIO can gate a 5 V rail. Keep V_ON ≤ 6 V.
- Default-off comes from the populated 100 kΩ R_ON_PD, not from the IC's
  Smart Pull Down, which disconnects permanently once ON is first driven
  high. Expect 33 µA at 3.3 V (55 µA at 5.5 V) of extra GPIO drive current
  while the rail is enabled.
- Turn-on takes 1.75–1.95 ms with a 2.7–3.2 mV/µs ramp. Inrush is
  C_LOAD × slew rate, so size total downstream bulk against what the
  upstream rail tolerates (47 µF ≈ 150 mA at 5 V).
- Off-state input current is 2 nA typ (800 nA max over temperature). There
  is no reverse blocking: the pass FET body diode conducts OUT → IN, so do
  not back-drive VOUT above VIN.
- 1.5 A continuous is a thermal limit, not an R_ON limit: R_θJA is
  210.7 °C/W in SC-70-6. Give the VIN/VOUT copper area at 1 A and above.
- The bundled `layout/TPS22919` fragment routes VIN, VOUT, QOD, and ON
  locally with 0.4 mm power copper and ties C_IN and R_ON_PD grounds
  together. C_OUT's ground pad is left for the parent board's ground plane.

## Package

**DCK / SC-70-6** (JEDEC MO-203 AB), 2.0 × 2.1 mm body, 0.65 mm pitch.
Footprint is KiCad's stock `SOT-363_SC-70-6` with an embedded STEP model —
1.025 × 0.35 mm pads on a 1.675 mm span, IPC-7351 nominal density. TI's
DCK0006A land pattern uses 0.9 × 0.4 mm pads on a 2.2 mm span; both reach a
3.1 mm outer envelope, with the KiCad pattern trading toe extension for
heel coverage.
