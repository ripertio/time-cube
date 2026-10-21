# Project Objectives

## Done
- [x] Hardware wired up: ESP32-S3, MPU-6050, battery, on/off switch, reset button
- [x] Enclosure: CAD model, translucent PLA prototype printed, test fit OK
- [x] Orientation detection: MPU-6050 over I2C, active face (1–6) via gravity threshold, serial debug output
- [x] NeoPixel LED states with 2 s debounce
- [x] WiFiManager captive-portal onboarding + NTP time sync
- [x] Local CSV log: `timestamp, face, activity, duration_sec`
- [x] Analytics page integratiet into the ESP itself(`index.html` exact copy of timecube_dashboard.h): pie charts, monthly breakdown, daily view
- [x] Live activity dashboard
- [x] Per-face activity label configuration
- [x] CSV export / download
- [x] Enclosure: refine tolerances / wall thickness

## Remaining

- [x] 25-minute Pomodoro timer with LED indicator, ofter  25min - switch to break
- [ ] Verify power-loss recovery (test procedure in README.md, Status section)
- [x] Extra button: implement input handling and LED feedback
  - [ ] Hold: toggle WiFi on/off (LED indicates state)
  - [ ] Single press: skip / reactivate current side (LED indicates state)
  - [ ] Double press: break (LED indicates break)
