# WIP: Time Cube — ESP32-S3 Based Physical Time Tracker

A DIY physical time-tracking cube powered by an ESP32-S3 and an MPU-6050 orientation sensor. Flip the cube to switch between activity categories — no app, no cloud, no phone required. Logs are exported via a local web interface and stored on the ESP, or exported to your device

## Features

- **Orientation-based tracking** — each face of the cube represents a different activity
- **Standalone** — runs on your local network with no cloud dependency or app lock-in
- **Open source** — fully customizable via ESPHome
- **LED status feedback** — onboard WS2812B RGB LED indicates connection and tracking state
- **Battery powered** — LiPo with TP4056 charging circuit

## Current State


---

## Hardware

| Component    | Specification                  |
| ------------ | ------------------------------ |
| MCU          | ESP32-S3 SuperMini             |
| IMU          | MPU-6050 (I2C)                 |
| LED          | Onboard WS2812B                |
| Battery      | LiPo 400–500 mAh               |
| Power Switch | Sliding Switch                 |
| Enclosure    | 3D-printed, ~5×5×5 cm          |

### Wiring (I2C)

| MPU-6050 Pin | ESP32-S3 Pin |
| ------------ | ------------ |
| SDA          | GPIO 8       |
| SCL          | GPIO 9       |
| VCC          | 3.3V         |
| GND          | GND          |
| Reset Button | GPIO         |

> Adjust GPIO pins to match your specific wiring if different.

---

## Software

The firmware is built with [ESPHome](https://esphome.io/). The configuration file is located in [](ESPHome_config/).

To flash or inspect logs, use the ESPHome web installer: [web.esphome.io](https://web.esphome.io/?dashboard_install)

### LED States

| State                  | Color  | Pattern    |
| ---------------------- | ------ | ---------- |
| Boot / WiFi connecting | Yellow | Slow blink |
| Ready / idle           | Off    | —          |
| Debounce in progress   | White  | Dim solid  |
| Face change detected   | Green  | On for 5 s |
| WiFi error             | Red    | Fast blink |

### Side / Face Configuration

Each face (1–6) maps to an activity category. You can configure the labels via the ESPHome web portal at `http://timecube.local` (or the IP address shown in the boot logs).

To find your cube's hostname or IP:
1. Connect the cube via USB to your computer
2. Open [web.esphome.io](https://web.esphome.io/?dashboard_install) and view the device logs
3. After boot and WiFi connection, the assigned IP address is printed in the log

---

## Getting Started

### 1. Flash the firmware

1. Connect the cube via USB
2. Go to [web.esphome.io](https://web.esphome.io/?dashboard_install)
3. Select the device and flash the config from `ESPHome_config/`

### 2. First boot & WiFi setup

1. Power on the cube
2. Connect your phone or laptop to the cube's WiFi hotspot (no password)
3. Follow the captive portal to connect the cube to your local WiFi

### 3. Track your time

1. Open `http://timecube.local` (or the cube's IP) in a browser
2. Configure which activity each face represents
3. Flip the cube to start tracking — the active face is logged automatically
4. Export your time logs from the web interface (e.g. http://timecube.local/text_sensor/csv_export)

---

## License

MIT
