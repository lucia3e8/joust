# Joust — Wearable Jostle-Detection Game

## Overview

A handheld, motion-sensing game device. Each player holds a sensor wand; if
the unit detects acceleration ("jostling") beyond a configured threshold, that
player is out. Units report the trip event to a central base station.

- **Quantity:** 50 player units + base station(s)
- **Environment:** outdoors, minimal occlusion, up to 50 m from base station
- **Form factor:** handheld wand — PCB + battery inside a PVC pipe section
- **Data profile:** event-driven and tiny — a local timestamp of the trip event
  plus a few bits of setup/config. Frame/protocol overhead dominates airtime,
  not payload.

## Design Decisions

### D1 — Motion sensing: accelerometer only (no IMU) — DECIDED

Jostle detection is a transient linear-acceleration threshold problem; no
orientation, heading, or rotation-rate data is needed.

Rationale:

- Rotational jostles still produce tangential/centripetal acceleration, so an
  accelerometer catches them.
- Modern accelerometers (ST LIS2DW12/LIS2DH12, Bosch BMA400, ADI ADXL362) have
  hardware wake-up/threshold interrupt engines: configure threshold + duration
  over I²C once, MCU sleeps until the "you lose" interrupt fires. No sampling
  loop, no filtering firmware, no sensor fusion.
- Power: accel in low-power interrupt mode is ~1–10 µA; a gyro is 0.5–1+ mA
  whenever on — disqualifying for a wearable.
- An IMU is *more* firmware (drift, fusion), not less. BOM delta (~$1–2/unit)
  was not the deciding factor; power and simplicity were.

Candidate parts: **LIS2DW12** (primary), BMA400, ADXL362. Range ±4 g or ±8 g;
threshold adjustable at runtime over I²C.

**As-implemented substitution:** no standalone accelerometer exists in the
registry, so the board uses the **LSM6DSOX** 6-axis IMU in accelerometer-only
mode (gyro powered down, its default state). The accel wake-up interrupt
engine works standalone at ~5 µA, preserving the D1 power/firmware rationale
on IMU silicon; the BOM delta was accepted per "prioritize registry
membership".

### D2 — RF stack: connectionless BLE on pre-certified nRF52 module — DECIDED

Requirements: 50 devices → 1 base station (star), 50 m outdoor near-LOS,
event-driven uplink of a timestamp + small config traffic, downlink command to
the winning unit (LED + haptic), minimal protocol overhead, wearable power
budget.

- **Uplink (event report):** connectionless BLE advertising. On accel
  interrupt, unit transmits its event packet 3–5× with random jitter, then
  sleeps. Base station is a passive scanner — no connection-count limit, no
  connection maintenance. ALOHA-style collisions are negligible at this event
  rate.
- **No BLE connections in normal operation.** Connections cap out around ~20
  per central and buy nothing for this traffic pattern. (Connections remain
  available for DFU / bench config via phone.)
- **Silicon:** nRF52833/nRF52840 on a **pre-certified module** (Raytac
  MDBT50Q, Fanstel BT840, or similar) to inherit FCC/CE intentional-radiator
  certification — chip-down RF cert is not economical at qty 50. Base station
  can be an nRF52840 dongle or a unit variant.
- 50 m outdoors at 2.4 GHz is comfortable at 0–4 dBm; Coded PHY available for
  ~+8 dB margin if body attenuation proves worse than expected.
- Rejected: BLE connections (limit, overhead), ESP-NOW (sleep power),
  Zigbee/Thread (unneeded mesh), sub-GHz/LoRa (range overkill, airtime, cost).

### D3 — Time sync + downlink: BLE periodic advertising beacon — DECIDED

One mechanism serves both needs. The base station runs a **BLE periodic
advertising train** at a fixed interval:

- **Interval: 1 s.** Winner-ping latency of ≤1 s is acceptable (adds
  suspense) and cuts synced-radio average draw to ~12 µA. Crystal drift
  between anchors (±50 ppm → ~50 µs) is negligible.
- **Time base:** beacon carries a sequence number; the periodic-adv anchor
  points are the shared clock. Units sync once at power-on, then the
  controller wakes the radio only at anchors (~2 ms RX per interval). Shared
  game clock = `seq × interval + local offset from last anchor`; sub-ms
  agreement across units. Event timestamps are reported in this clock domain.
- **Downlink:** commands are fields in the beacon payload — `WINNER=<id>`
  (repeated a few intervals; winner fires LED + haptic within one interval),
  game start/stop, threshold config, identify/blink. All connectionless.
- **Multiple base stations:** exactly one base transmits the beacon train;
  additional bases are pure listeners synced to the same train (single clock
  domain). Never run two independent beacon transmitters.
- Standard BLE 5.1+ (periodic advertising); supported by Nordic's controller
  on nRF52833/nRF52840. Same topology as the BLE 5.4 ESL profile.

### D4 — Battery: rechargeable LiPo, 250 mAh — DECIDED

The winner-celebration haptic motor (60–150 mA) exceeds a CR2032's ~15–20 mA
continuous capability, so player units use a **rechargeable LiPo, 250 mAh**
(e.g., 502025/502030 size) + charger IC (MCP73831-class, ~125 mA = 0.5 C).

Budget: in-game average draw ≈ 20–50 µA at the 1 s beacon interval
(beacon-synced radio ~12 µA, MCU sleep ~3 µA, accel ~1 µA, margin) → months of
continuous game mode; winner celebration costs ~0.1 mAh. Capacity is sized for
peak-current headroom (haptic pulse ≈ 0.5 C) and charging convenience, not
runtime. Spec cells with built-in protection PCM.

### D5 — Haptic: ERM motor, discrete drive — DECIDED

Cheapest option is fine: coin-type **ERM vibration motor** driven by an N-FET
+ flyback diode + gate resistor from an MCU GPIO/PWM. No haptic driver IC.

### D6 — Enclosure: PVC pipe, handheld — DECIDED

PCB + LiPo mount inside a PVC pipe section held in the hand.

- PVC is RF-transparent — no metallic enclosure penalty.
- The gripping hand is the dominant attenuator: place the antenna at the far
  end of the pipe from the grip, keep-out per module datasheet, LED visible
  through an end cap or translucent section.
- Long narrow board outline; charging connector (USB-C or contacts) reachable
  through an end cap.

## Implementation (Joust.zen)

All blocks are registry packages; board builds clean (56 components).

| Function | Part / package |
|---|---|
| BLE module (nRF54L15, PCB antenna, pre-certified) | u-blox NORA-B206-00B — `reference/NORAB2x` |
| Motion (accel-only, wake-up INT1 → P0.04) | ST LSM6DSOXTR — `reference/LSM6DSOXx`, I²C |
| Charger + power path (125 mA = 0.5 C, 4.2 V, 500 mA ILIM) | TI BQ25185DLHR — `components/Texas_Instruments/BQ25185DLH` |
| 3.3 V LDO (NORA VCC max 3.5 V → LiPo can't drive it directly) | Richtek RT9013-33GB |
| USB-C charge-only sink (Rd pull-downs, ESD, VBUS TVS) | GCT USB4105 — `modules/UsbCSink16P` |
| Battery / motor connectors | JST PH 2-pos SMD (B2B-PH-SM4-TB) |
| Power switch (gates LDO EN; no load current through switch) | C&K JS202011SCQN DPDT slide |
| Motor low-side switch (100 k gate pulldown) | 2N7002K, 1N4148W flyback |
| Celebration LED | WS2812B addressable RGB (XINGLIGHT XL-1010RGBC), power-gated by TPS22919 load switch (default-off, QOD); 330 Ω data series R from P0.01, enable on P1.10 |
| Programming | Tag-Connect TC2030-NL (SWD, zero BOM cost) |

Design-review outcomes (EE reviewer): all checks passed (power/off-state
leakage, charger straps, FET/flyback sizing, I²C pull-up placement, SWD/reset,
USB CC config).

WS2812B caveats (accepted): pixel VDD spec is 3.5–5.5 V, so below ~3.5 V
battery it runs out of spec (dimmer / color shift); static draw ~0.35 mA is
why it is power-gated rather than always-on. Firmware must keep the data line
low while the pixel is unpowered (DI abs max = VDD + 0.4 V).

Assembly note: the NORA-B2 32.768 kHz crystal (3215, 7 pF) has no house-part
match — specify an MPN at order time, e.g. Epson FC-135R 32.7680KA-A7 or
equivalent 7 pF 3215 part.

