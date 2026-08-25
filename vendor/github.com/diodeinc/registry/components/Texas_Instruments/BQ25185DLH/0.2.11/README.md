# BQ25185DLH

Texas Instruments BQ25185 1-cell, 1 A standalone **linear** Li-ion /
Li-poly / LiFePO₄ battery charger with integrated power path, pushbutton
input, and battery-tracking VINDPM. WSON-10 (DLH, 2.2 × 2.0 mm, exposed
pad). Orderable MPN: `BQ25185DLHR`.

- **VIN**: 2.7 V – 5.5 V recommended (25 V tolerant abs max)
- **ICHG**: 10 mA – 1000 mA, resistor programmed (R_ISET)
- **VBATREG**: 3.6 / 3.65 / 4.05 / 4.1 / 4.2 / 4.35 / 4.4 V (strap programmed)
- **ILIM**: 100 / 500 / 1100 mA (strap programmed, paired with VBATREG)
- **IDISCHG**: up to 3.125 A (BAT → SYS)

[Datasheet](https://www.ti.com/lit/ds/symlink/bq25185.pdf)

## Usage

```python
Bq25185 = Module("github.com/diodeinc/registry/components/Texas_Instruments/BQ25185DLH/BQ25185DLH.zen")

Bq25185(
    name="CHARGER",
    charge_current="500mA",
    battery_regulation="4.2V",
    input_current_limit="500mA",

    VIN=VBUS_5V,
    SYS=VSYS,
    BAT=VBAT_1S,
    GND=GND,

    CE=GND,          # tie low to always enable, or drive from a host GPIO
    STAT1=STAT1,     # optional open-drain status
    STAT2=STAT2,     # optional open-drain status
                     # TS omitted: bypass_thermistor=True handles it
)
```

### Dual-rate charging (XIAO HICHG-style) + no indicator LEDs

```python
Bq25185(
    name="CHARGER",
    charge_current="50mA",         # base rate (HICHG low / undriven)
    fast_charge_current="100mA",   # rate while HICHG is high
    populate_status_leds=False,    # drive your own charge LED from STAT

    VIN=VBUS_5V, SYS=VSYS, BAT=VBAT_1S, GND=GND,
    CE=GND,
    HICHG=HICHG,   # host GPIO ≥3 V: high = fast charge; undriven = base rate
    STAT1=STAT1,   # clean high-Z open-drain when LEDs depopulated
)
```

### Area-critical: omit unused optional footprints entirely

```python
Bq25185(
    name="CHARGER",
    charge_current="500mA",
    populate_status_leds=False,      # feature off
    disabled_circuitry="OMIT",       # drop the DNP footprints from the board

    VIN=VBUS_5V, SYS=VSYS, BAT=VBAT_1S, GND=GND,
    CE=GND,
    STAT1=STAT1,
)
```

With `disabled_circuitry="OMIT"` the disabled indicator-LED block
(D_STAT1/D_STAT2 + R_STAT1/R_STAT2) and, when `fast_charge_current` is
unset, the fast-charge block (R_ISET_FAST + Q_HICHG + R_HICHG_PD) are not
instantiated at all, so those footprints leave the board — useful when
every mm² of courtyard counts. The default (`"DNP"`) keeps them as
unpopulated footprints, unchanged from prior releases. When the
fast-charge branch is omitted, the `HICHG` gate io is not declared (it
gates the 2N7002, not a charger pin), so no dangling optional io and no
"`HICHG` not connected" warning results.

Setting `fast_charge_current` switches a second ISET resistor in parallel
through a 2N7002 N-FET (gate = `HICHG`, 100 kΩ pulldown parks the base
rate). It must be greater than `charge_current` and ≤ 1000 mA. Leaving it
unset keeps a single fixed rate. Drive `HICHG` at ≥ 3 V (2N7002
V_GS(th) up to 2.5 V) — a 1.8 V GPIO is not guaranteed to enable fast
charge. `populate_status_leds=False` DNPs the D_STAT1/D_STAT2 LEDs and
their 1.2 kΩ resistors (topology preserved).

Invalid (`battery_regulation`, `input_current_limit`) combinations fail
the build — only the pairs in datasheet Table 7-1 are valid (100 mA ILIM
exists only with V_BATREG = 4.2 V).

## Integration notes

- `CE` must not float; there is intentionally no internal strap.
- With an external NTC on `TS`, set `bypass_thermistor=False` or the
  populated 10 kΩ bypass shifts the hot/cold trip points.
- By default STAT1/STAT2 drive a status LED (red/orange) through a
  1.2 kΩ current-limit resistor from SYS (~1.9 mA). This is an
  indication path, not a clean GPIO pull-up: for host readback add a
  pull-up to the host logic rail and use a SYS-tolerant / high-Z input.
  Set `populate_status_leds=False` to DNP the LEDs and resistors, which
  also leaves STAT as an unloaded high-Z open-drain node.
- `disabled_circuitry` (`"DNP"` default / `"OMIT"`) chooses whether a
  switched-off optional block (indicator LEDs, or the fast-charge branch
  when `fast_charge_current` is unset) is DNP-placed or dropped from the
  board entirely. Use `"OMIT"` only on area-critical designs where the
  feature is permanently unused.
- ESD/TVS on VIN, cell-level battery protection, and USB BC1.2 detection
  are integrator-owned (see the `.zen` docstring).
- Footprint follows the TI DLH0010A datasheet land pattern (pads
  0.5 × 0.2 mm at ±0.8 mm, 0.9 × 1.5 mm exposed pad, ~88 % paste
  coverage on the EP) with the vendor STEP model embedded.

## Migration notes

Both additions in v0.3 are backward compatible — with `fast_charge_current`
unset and `populate_status_leds` at its `True` default, the netlist,
BOM population, and behavior are identical to prior versions.

- **`fast_charge_current` (optional `Current`)** + **`HICHG` (optional
  `Net`)**: adds a DNP-by-default dual-rate ISET branch (R_ISET_FAST +
  2N7002 + 100 kΩ gate pulldown). Populated only when
  `fast_charge_current` is set; requires `charge_current` <
  `fast_charge_current` ≤ 1000 mA. Drive `HICHG` at ≥ 3 V; it may be left
  unconnected (held low = base rate). Adds a dependency on
  `components/2N7002` (DNP unless the feature is enabled).
- **`populate_status_leds` (`bool`, default `True`)**: set `False` to
  DNP the indicator LEDs and their series resistors. No action needed to
  retain the previous always-populated behavior.

The following add one config and shrink one passive:

- **`disabled_circuitry` (enum `"DNP"` | `"OMIT"`, default `"DNP"`)**:
  when set to `"OMIT"`, a *disabled* optional block (indicator LEDs when
  `populate_status_leds=False`; fast-charge branch when
  `fast_charge_current` is unset) is not instantiated, removing its
  footprints from the board for area-critical consumers. The `"DNP"`
  default preserves the prior DNP-placed behavior, topology, netlist and
  BOM population unchanged from prior versions. When the fast-charge
  branch is omitted (`disabled_circuitry="OMIT"` with `fast_charge_current`
  unset), the `HICHG` gate io is now declared only when that branch
  exists, so it no longer emits a "`HICHG` not connected to any ports"
  warning. This is a diagnostic-only fix: consumers that set
  `fast_charge_current` and/or connect `HICHG` are unaffected (the io is
  still exposed whenever the branch is populated or DNP-placed).
- **C_BAT downsized 0603 → 0402** (intentional passive change — the
  C_BAT MPN and footprint differ from prior versions): now a
  2.2 µF / 25 V / X5R 0402 (Murata GRM155R61E225KE11D). Datasheet
  §8.2.2.3 requires only 1 µF on BAT with no 25 V callout (the 25 V
  recommendation is scoped to IN/SYS). BAT tops at V_BATREG (≤ 4.4 V),
  where the 25 V-rated 0402 holds ≈ 1.35–1.39 µF on Murata typical
  DC-bias data — above the 1 µF floor and above the 1 µF TI uses in its
  own characterization, though with less headroom than the 0603.
  C_VIN (0603) and C_SYS (0805) were reviewed and deliberately left
  unchanged. Re-sync your layout so the C_BAT footprint updates to 0402.
- **Strap/signal resistors downsized 0402 → 0201** (footprint/BOM change,
  no API change): R_ISET, R_VSET, R_TS_BYPASS, R_ISET_FAST, R_HICHG_PD,
  R_STAT1, R_STAT2 now use house Panasonic ERJ-1GNF/ERJ-1GJF 0201
  (25 V / 0.05 W / 1 %). Node voltages (≤ 5 V) and dissipation (≤ ~5 mW)
  sit well inside the 0201 ratings, and R_ISET/R_VSET keep their 1 %
  tolerance so charge-current / regulation accuracy is unchanged.
  **C_ISET stays 0402**: the house cap catalog has no 0201 C0G part
  (0201 tops out at 2.2 nF X7R), so a C0G 47 pF is only sourceable at
  0402. C_VIN/C_SYS/C_BAT are unchanged (§8.2.2.3 voltage-rating /
  derating). Re-sync your layout for the 0201 resistor footprints.

## Supersedes

This package replaces `components/Texas_Instruments/BQ25185DLHR` and
`reference/BQ25185x` (deprecated: non-datasheet pin names, thermal pad
modeled as a second GND pin, and perimeter pads shifted 0.25 mm outboard
of the TI land pattern).
