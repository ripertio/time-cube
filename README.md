# WIP: Time Cube — ESP32-S3 Based Physical Time Tracker

A DIY physical time-tracking cube powered by an ESP32-S3 and an MPU-6050 orientation sensor. Flip the cube to switch between activity categories — no app, no cloud, no phone required. Logs are stored on the device and can be viewed or exported through its local web interface.

## Features

- **Orientation-based tracking** — each face of the cube represents a different activity
- **Long-term local storage** — ring buffer with room for ~88,000 entries (roughly 4 years at a 25-min average session)
- **Power-loss protection** — an unfinished session is recovered after reboot, losing at most ~60 s
- **Built-in analytics** — `/analytics` page served by the cube itself (pie charts, monthly breakdown, daily view)
- **Standalone** — runs on your local network with no cloud dependency or app lock-in
- **Open source** — fully customizable via ESPHome
- **LED status feedback** — onboard WS2812B RGB LED indicates connection and tracking state
- **Battery powered** — LiPo with TP4056 charging circuit

---

## Hardware

| Component    | Specification                              |
| ------------ | ------------------------------------------ |
| MCU          | ESP32-S3 SuperMini (ESP32-S3FH4R2, 4 MB flash) |
| IMU          | MPU-6050 (I2C)                             |
| LED          | Onboard WS2812B                            |
| Battery      | LiPo 400–500 mAh                           |
| Power Switch | Sliding Switch                             |
| Enclosure    | 3D-printed, ~5×5×5 cm, translucent PLA     |

### Wiring (I2C)

| MPU-6050 Pin | ESP32-S3 Pin |
| ------------ | ------------ |
| SDA          | GPIO 8       |
| SCL          | GPIO 9       |
| VCC          | 3.3V         |
| GND          | GND          |
| Button       | GPIO13 ↔ GND |

> Adjust GPIO pins to match your specific wiring if different.

---

## Software

The firmware is built with [ESPHome](https://esphome.io/) (2025.5.2, esp-idf framework). The configuration is in [ESPHome_config/](ESPHome_config/).

### Storage

- Log entries are 32 bytes each in a dedicated flash partition (`tclog`, ~2.7 MB).
- Entries are written to a persistent ring buffer (write head and wrap flag stored in NVS), so the buffer survives reboots and overwrites the oldest data when full.
- Entry format: `timestamp, face, activity, duration_sec`
- OTA is disabled. Firmware updates are done over USB only.
- Files: [timecube_storage.h](ESPHome_config/timecube_storage.h), [partitions_timecube.csv](ESPHome_config/partitions_timecube.csv)

### Power-loss protection

- While a side is active, a checkpoint (side, session start, last-seen time) is saved to NVS every 60 s.
- On the first NTP sync after boot, `recover_checkpoint()` logs any unfinished session up to its last checkpoint.

### Web interface

- `http://timecube.local/` — stock ESPHome config page (loads locally, no internet needed).
- `http://timecube.local/analytics` — self-hosted analytics dashboard. It reads the cube's own CSV export automatically.
- `http://timecube.local/text_sensor/csv_export` — CSV export. Returns the most recent entries (capped at 16 KB per response).
- Files: [timecube_dashboard.h](ESPHome_config/timecube_dashboard.h) (embedded copy of the dashboard), [index.html](index.html) (source; keep in sync with the embedded copy).

### Building and flashing

To flash or inspect logs, use the ESPHome web installer: [web.esphome.io](https://web.esphome.io/?dashboard_install)

Or use the local ESPHome CLI:
```
# one-time install, in a throwaway virtualenv to keep things clean
python3 -m venv ~/.venvs/esphome
source ~/.venvs/esphome/bin/activate
pip install esphome

# fast sanity check — compiles only, no device needed
esphome compile ESPHome_config/timecube.yaml

# compile + flash over USB (prompts you to pick the serial port)
esphome run ESPHome_config/timecube.yaml

# after flashing, tail the device's logs
esphome logs ESPHome_config/timecube.yaml
```

### LED States

| State                  | Color  | Pattern    |
| ---------------------- | ------ | ---------- |
| Boot / WiFi connecting | Yellow | Slow blink |
| Ready / idle           | Off    | —          |
| Debounce in progress   | White  | Dim solid  |
| Face change detected   | Green  | On for 5 s |
| WiFi error             | Red    | Fast blink |

### Side / Face Configuration

Each face (1–6) maps to an activity category. Labels can be set via the web portal at `http://timecube.local` (or the IP address shown in the boot logs).

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
4. NTP time sync runs automatically after connecting

### 3. Track your time

1. Open `http://timecube.local/analytics` (or the cube's IP) to view your data, or `http://timecube.local` for the device page
2. Configure which activity each face represents
3. Flip the cube to start tracking — the active face is logged automatically
4. Export your time logs from `http://timecube.local/text_sensor/csv_export`

---

## Status

### Verified

- Compiles cleanly with ESPHome 2025.5.2 (esp-idf).
- Flipping the cube logs entries correctly (`Logged [n/88064]: Seite X | N s`).
- `/analytics` loads quickly and renders real CSV data.
- `/` (stock config page) loads quickly with `local: true`.

### Not yet verified

- **Power-loss recovery.** Needs a real power cut to confirm. Test: flip to a face, wait more than 60 s, cut power, restore power, wait for WiFi/NTP, and check the logs for `Wiederhergestellt nach Stromverlust`. The recovered entry should appear in `/analytics`.
- **Ring buffer wrap-around.** Untested by construction. It would take a very long time to fill 88,064 entries.

### Known issues

- Occasional `net::ERR_CONNECTION_RESET` on `/events` (the stock page's live-update stream) when several clients connect at once, such as multiple browser tabs plus the VS Code extension. This is likely the ESP32 httpd's small concurrent-socket limit. The browser reconnects automatically, so it is cosmetic for now.

---

## License

MIT
