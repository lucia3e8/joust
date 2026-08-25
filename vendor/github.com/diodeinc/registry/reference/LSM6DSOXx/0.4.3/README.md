# LSM6DSOXx Reference Design

Reference design for the STMicroelectronics LSM6DSOXTR, a 6-axis IMU with embedded AI
(Machine Learning Core + Finite State Machine). Implements Mode 1 configuration with
selectable I²C or SPI primary interface.

## Features
- **IC**: LSM6DSOXTR (LGA-14L, 2.5 × 3.0 × 0.83 mm)
  - 3-axis accelerometer: ±2/±4/±8/±16 g
  - 3-axis gyroscope: ±125/±250/±500/±1000/±2000 dps
  - 0.55 mA combo high-performance mode, 3 µA power-down
  - Embedded finite state machine (16 programs) and machine learning core (8 decision trees)
  - 9 KB smart FIFO with compression
- **Interfaces**: I²C (up to 400 kHz) or SPI (up to 10 MHz), selectable via config
- **Interrupts**: Two programmable interrupt outputs (INT1, INT2)
## Usage

### I²C mode (default)

```python
LSM6DSOXx = Module("github.com/diodeinc/registry/reference/LSM6DSOXx/LSM6DSOXx.zen")

LSM6DSOXx(
    name="IMU",
    VDD=vdd_1v8,
    VDDIO=vddio_1v8,
    GND=gnd,
    I2C=i2c_bus,
    i2c_address="0x6A",
    INT1=imu_int1,
)
```

### SPI mode

```python
LSM6DSOXx = Module("github.com/diodeinc/registry/reference/LSM6DSOXx/LSM6DSOXx.zen")

LSM6DSOXx(
    name="IMU",
    communication="SPI",
    VDD=vdd_1v8,
    VDDIO=vddio_1v8,
    GND=gnd,
    SPI=spi_bus,
    INT1=imu_int1,
    INT2=imu_int2,
)
```

## Design Notes

- **Mode 1 only**: SDX and SCX pins are tied to GND via 0 Ω resistors (per datasheet
  Section 7.1). Modes 2–4 (sensor hub, auxiliary SPI / OIS) are not supported.
- **OCS_AUX / SDO_AUX**: Left unconnected per Mode 1 requirements. Internal pull-ups
  are enabled by default in Mode 1 (Table 20).
- **Decoupling**: 100 nF ceramic on each supply pin, placed close to the IC per
  datasheet recommendation (Section 7.1).
- **CS pull-up**: 10 kΩ to VDDIO. In I²C mode, holds CS high to select the I²C
  interface. In SPI mode, keeps CS deasserted at reset until the master drives it.
- **I²C pull-ups**: 4.7 kΩ to VDDIO. The I²C interface requires external pull-ups on
  SCL and SDA (Section 5.1.1). Set `i2c_pullup=False` if pull-ups are provided
  elsewhere on the bus.
- **I²C address**: Configured via `i2c_address`. A 10 kΩ resistor straps SDO/SA0
  to GND (0x6A) or VDDIO (0x6B). Both resistors DNP in SPI mode.

## References
- [LSM6DSOX Datasheet](https://www.st.com/resource/en/datasheet/lsm6dsox.pdf)
- [AN5272 — LSM6DSOX Application Note](https://www.st.com/resource/en/application_note/an5272.pdf)
