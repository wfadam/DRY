# LI Sweep

## Hardware
- Connect `the optical cable` between 6-inch sphere and spectrometer
- Connect `banana leads` between 6-inch sphere and SMU
- Make sure SMU is under SCPI mode
- Turn on TCU

## Software

### open `Arroyo Control.exe`
- Click [Connect]
- Set `25` as temperature
- Check [on]
### open `6 inch sphere.exe`
- Click [Lot Start]
- Select PN
- Input Lot like `20240725...`
- Input RunID like `T100...`
- Input Total like `200`
- Turn on [Production] if needs continuous DieID
- Click [Confirm]


## Operation
1. Stick the starboard to 6-inch sphere
2. Click [Test Start]
3. Wait for test end
4. repeat 1 to 3 until all tested
5. Check results in `Y:\BNE-UV-Product\Production-Test\Final Test Summary\Engineering-Legacy`
6. Turn of TCU: check [off] then click [Disconnect]

---

# IV Curve

## Hardware
`as LI Sweep excluding TCU`

## Software
`as LI Sweep except PN selection`

## Operation
`as LI Sweep excluding TCU`

---

# Stability Test

## Hardware
`as LI Sweep excluding TCU`

## Software
### open `Stability Test Tool.exe`
1. Click [Open] to select any json file
    * Tune integration time
    * Click [Apply]
    * repeat until signal level is around 60%
2. Click [Save]
3. Input Read Interval `greater than integration time`
4. Click ▷ in top right corner
5. Switch to [Test] Tab
    * Select PN
    * Input Wafer ID
    * Input Part ID
6. Click [Start]
