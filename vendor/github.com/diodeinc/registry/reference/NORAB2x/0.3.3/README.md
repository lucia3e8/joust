# NORAB2x Reference Design

u-blox NORA-B2 Bluetooth LE and IEEE 802.15.4 module reference circuit for the
NORA-B206-00B (integrated PCB trace antenna variant). Based on the Nordic
Semiconductor nRF54L15 SoC.

## Features

- **IC**: u-blox NORA-B206-00B (LGA, 14.3 × 10.4 × 1.9 mm)
  - Bluetooth 6.0 LE, IEEE 802.15.4 (Thread, Matter, Zigbee)
  - Arm Cortex-M33 (128 MHz) + RISC-V coprocessor (128 MHz)
  - 256 kB RAM, 1.5 MB flash
  - Integrated PCB trace antenna (+3 dBi)
  - Channel Sounding support
- **Supply**: 1.7V to 3.5V single rail with VCC decoupling
- **Interfaces**: UART, SPI (32 MHz), QSPI, I2C, SWD, NFC, 8× GPIO
- **Clock**: Optional 32.768 kHz crystal for lowest-power LFCLK
- **Reset**: Internal ~14 kΩ pull-up; 100 nF input cap for noise filtering; 0 Ω series resistor for external reset access
- **I2C**: Optional 10 kΩ pull-up resistors to VCC

## Interfaces

| Name | Type | Description |
|------|------|-------------|
| VCC | Power | Module supply (1.7V to 3.5V) |
| GND | Ground | Common ground |
| UART | Uart | UART data (TX/RX, module perspective) |
| UART_RTS | Gpio | UART request-to-send (optional) |
| UART_CTS | Gpio | UART clear-to-send (optional) |
| SPI | Spi | SPI main node, up to 32 MHz (optional) |
| SPI_DCX | Gpio | SPI Data/Command for displays (optional) |
| QSPI | Qspi | Quad SPI for external flash (optional) |
| I2C | I2c | I2C bus (optional) |
| SWD | Swd | Serial Wire Debug |
| RESET_N | Net | Active-low reset input (optional) |
| NFC1, NFC2 | Net | NFC antenna pads (optional) |
| GPIO_P0_00–GPIO_P1_13 | Gpio | 8 general-purpose IOs (optional) |
| WAKE_HOST | Gpio | Module-to-host wake (optional) |
| WAKE_UP | Gpio | Host-to-module wake (optional) |

## Configuration

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| populate_crystal | bool | True | Populate 32.768 kHz crystal (Y_LFXO). False DNPs the crystal and uses internal RC (~500 ppm). |
| i2c_pullup | bool | True | Populate I2C pull-up resistors (10 kΩ to VCC). |

## Usage

```python
NORAB2x = Module("github.com/diodeinc/registry/reference/NORAB2x/NORAB2x.zen")

NORAB2x(
    name="U1",
    VCC=vcc_3v3,
    GND=gnd,
    UART=uart_bus,
    SWD=swd_bus,
    I2C=i2c_bus,
)
```

### Minimal BLE beacon (UART + SWD only)

```python
NORAB2x(
    name="U1",
    VCC=vcc_3v3,
    GND=gnd,
    SWD=swd_bus,
    populate_crystal=True,
)
```

### With external QSPI flash and no crystal

```python
NORAB2x(
    name="U1",
    VCC=vcc_1v8,
    GND=gnd,
    UART=uart_bus,
    SWD=swd_bus,
    QSPI=qspi_flash_bus,
    populate_crystal=False,
)
```

## Design Notes

### Pin Sharing
Two GPIO pins are internally connected to RF control pins on the module:
- `GPIO_P0_02` ↔ `RF_CTRL2` (pads C8 and G7, both nRF P0.02)
- `GPIO_P1_13` ↔ `RF_CTRL1` (pads J8 and G5, both nRF P1.13)

The reference design connects each pair to the same net so the integrator
gets a single IO per physical nRF pin.

### Antenna
NORA-B206 has an integrated PCB trace antenna. The host PCB must:
- Place the module centered on a board edge
- Provide ≥10 mm ground plane on three non-edge sides
- Include a ground-plane cutout under the antenna area
- Maintain ≥10 mm clearance from tall components and enclosure walls
- Connect all EAGP pads to ground with stitching vias

### Low-Frequency Clock
- **populate_crystal=True** (default): 32.768 kHz crystal provides ±20 ppm accuracy and lowest
  sleep current. Configure in firmware via device tree `&hfxo` and `&lfxo` nodes.
- **populate_crystal=False**: Crystal is DNP. Internal RC oscillator (LFRC, ~500 ppm). Pins XL1/XL2 become
  available as GPIOs (P1.00, P1.01). Slightly higher sleep current but simpler BOM.

### Reset Circuit
The module has an internal ~14 kΩ pull-up on RESET_N (typ 14 kΩ, range 12–16 kΩ per
datasheet Table 18). No external pull-up is needed. A 100 nF cap to ground filters
noise and provides a power-on delay (RC ≈ 1.4 ms with the internal 14 kΩ). A 0 Ω
series resistor (`R_RESET_EXT`) connects the `RESET_N` IO for external reset control
via open-drain driver or push button.

### HFXO Internal Load Capacitance
The internal 32 MHz crystal requires software configuration of internal load caps.
Add this to your Zephyr device tree board definition:
```dts
&hfxo {
    load-capacitors = "internal";
    load-capacitance-femtofarad = <14250>;
};
```

### NFC
To use NFC, connect NFC1 and NFC2 to an inductive NFC antenna with tuning capacitors
for 13.56 MHz resonance. When not using NFC, NFC1/NFC2 can be configured as GPIOs
(P1.02, P1.03) in firmware — but do not apply an NFC field when in GPIO mode.

## References

- [NORA-B2 Data Sheet](https://content.u-blox.com/sites/default/files/NORA-B2_DataSheet_UBX-23013817.pdf) (UBX-23013817)
- [NORA-B2 System Integration Manual](https://content.u-blox.com/sites/default/files/documents/NORA-B2_SIM_UBXDOC-465451970-3345.pdf) (UBXDOC-465451970-3345)
- [nRF54L15 Datasheet](https://docs.nordicsemi.com/bundle/ps_nrf54L15/page/keyfeatures_html5.html) (Nordic Semiconductor)
- [nRF Connect SDK](https://developer.nordicsemi.com/nRF_Connect_SDK/doc/latest/nrf/index.html)
