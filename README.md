# SerialPlotter
A modern and simple serial plotter.

**Designed for macOS 26.** Requires macOS 14.6 or later.

![Screenshot](/Screenshots/Main.png)

## Usage
How to use SerialPlotter
- Start with an Arduino project.
- Initialize the serial:
  ```cpp
  void setup() {
    Serial.begin()
  }
  ```
- Print your logs in this format: `SomeKey: 6969 | AnotherKey: 4242`
  Example:
  ```cpp
  Serial.print("Charging Rate: ");
  Serial.print(currentChargingRate);
  Serial.print(" | New Charge: ");
  Serial.print(newCharge);
  Serial.print(" | Battery: ");
  Serial.print(batteryChargePercentage);
  Serial.print(" | Charging: ");
  Serial.print(charging);
  Serial.print(" | Light: ");
  Serial.print(String(lightOn ? "On" : "Off"));
  Serial.print(" | Dimmer: ");
  Serial.println(String(dimmerPercentage));
  ```
- Connect your Arduino to your computer, upload your code, then run SerialPlotter and click on ▶︎.
