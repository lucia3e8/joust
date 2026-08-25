# 2N7002 / 2N7002K — logic-level N-channel MOSFET, SOT-23

Commodity 60 V small-signal switching FET in SOT-23 (TO-236AB), pin 1 = gate,
pin 2 = source, pin 3 = drain. One `.zen`, one `.kicad_sym` with a symbol per
tier, one shared footprint with an embedded STEP model.

Use it for low-side switching of small loads directly from 1.8–5 V logic. Both
tiers are true logic-level parts: V_GS(th) is 2.5 V max and R_DS(on) is
specified at 4.5 V or 5 V, never 10 V only.

## Tiers

| `variant` | V_DS | I_D (T_A = 25 °C) | R_DS(on) max | V_GS(th) | Gate ESD clamp |
|---|---|---|---|---|---|
| `"2N7002K"` (default) | 60 V | ≥ 300 mA | 4 Ω @ V_GS = 4.5 V | 1.0–2.5 V | yes, 2 kV HBM |
| `"2N7002"` | 60 V | ≥ 170 mA | 7.5 Ω @ V_GS = 5 V | 1.0–2.5 V | no |

Each tier ships every in-stock second source: the primary part is the
strongest-specified/widest-stocked MPN and the others are BOM alternates, so the
envelope above is what a design may rely on. The R_DS(on) bound is quoted at the
lowest gate voltage every source of the tier specifies — Diodes' bins are given
at 5 V (3 Ω for 2N7002K, 7.5 Ω for 2N7002), Vishay's 4 Ω at 4.5 V sets the
`"2N7002K"` bound.

| `variant` | Primary | Alternates |
|---|---|---|
| `"2N7002K"` | onsemi `2N7002KT1G` (1.6 Ω @ 10 V, 2.5 Ω @ 4.5 V) | Diodes `2N7002K-7`, Vishay `2N7002K-T1-GE3` |
| `"2N7002"` | Diodes `2N7002-7-F` (5 Ω @ 10 V, 7.5 Ω @ 5 V) | Nexperia `2N7002,215` |

## Usage

```zen
Fet = Module("github.com/diodeinc/registry/components/2N7002/2N7002.zen")

# Default 2N7002K tier: low-side PWM switch driven from a 3.3 V MCU timer output
Fet(
    name = "Q_LED_R",
    GATE = LED_R_PWM,
    DRAIN = LED_R_CATHODE,
    SOURCE = GND,
)

# Original 2N7002 bin, when the higher R_DS(on) does not matter
Fet(
    name = "Q_EN",
    variant = "2N7002",
    GATE = EN_GPIO,
    DRAIN = SHUTDOWN_PIN,
    SOURCE = GND,
)
```

## Integration notes

- **3.3 V drive.** No datasheet in the family guarantees R_DS(on) below 4.5 V.
  onsemi's Figure 5 gives ~1.7 Ω typical at V_GS = 3.3 V / I_D = 200 mA versus
  1.33 Ω typical at 4.5 V, so budget about 1.3× the 4.5 V number at 25 °C and
  ~1.4× more at T_j = 85 °C. At 120 mA the `"2N7002K"` tier drop is ~0.3 V using
  onsemi's 2.5 Ω bound and ~0.5 V at the 4 Ω tier envelope; the `"2N7002"` tier
  is ~0.9 V.
- **Gate network.** Q_g is 0.7 nC at 4.5 V and C_iss is 45 pF max, so a 25 kHz
  PWM pin sources ~18 µA average and needs no buffer. Add a 47–220 Ω series gate
  resistor to damp the gate loop and a 10–100 kΩ pulldown so the FET stays off
  while the driving pin is high-impedance. This package is the primitive only;
  those parts belong to the consuming design.
- **Low-side only.** The source-drain body diode conducts whenever V_S > V_D.
- **Thermals.** onsemi P_D is 300 mW on a minimum land (R_thJA 417 °C/W) and
  420 mW on a 1 in² pad (R_thJA 300 °C/W); copper area, not the 60 V / 5 A
  pulsed ratings, sets the practical limit.
- **Not covered.** 2N7002W (SC-70) and 2N7002DW (dual, SOT-363) share the die
  but not the footprint. Nexperia's 2N7002K is excluded as an alternate: it is
  the weakest bin of that tier (5.3 Ω at 4.5 V, V_GS limited to ±15 V) and shows
  no distributor stock.
- **Footprint.** `SOT95P260X110-3N`, an IPC-7351 nominal-density SOT-23 land:
  pads 1.05 mm along the lead × 0.6 mm across it, 1.9 mm row pitch, 2.4 mm
  pad-centre span, with an embedded STEP model (2.9 × 1.3 mm body, 2.6 mm lead
  span, 1.1 mm high). Unchanged from earlier revisions of this package so
  existing consumer layouts stay valid.
