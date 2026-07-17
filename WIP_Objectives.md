# Project Objectives

## Stage 0 — Hardware & Enclosure

### Procurement & Assembly
- [x] Order all hardware components
- [x] Wire up components 
    - [x] ESP32-S3
    - [x] MPU-6050, 
    - [ ] battery
    - [ ] on/off switch
    - [ ] reset button

### 3D Design & Printing
- [x] Create initial sketch / concept drawing
- [x] Ask for help with CAD design
- [ ] Finalize CAD model
  - Cube body: ~50×50×50 mm outer dimensions
  - Wall thickness: 1.5–2 mm for semi-transparency
  - Internal standoffs / snap-fits to hold PCB and battery in place
  - Cutouts: USB-C port, sliding power switch, diffuser window for LED
  - Lid or bottom panel that clips or screws shut for easy access
- [ ] Buy transparent / translucent PLA (natural or white for LED glow)
- [ ] Slice and print prototype
  - Infill: 10–15% (gyroid) to keep walls thin and light diffusion even
- [ ] Test fit: verify all components fit, check LED glow through walls
- [ ] Iterate: refine tolerances, adjust wall thickness if needed

---

## Stage 1 — Orientation Detection
- [x] Read MPU-6050 via I2C
- [x] Determine active face (1–6) using gravity threshold on each axis
- [x] Serial monitor output for debugging

---

## Stage 2 — LED Feedback
- [x] Implement NeoPixel LED states
- [x] 2-second debounce logic to avoid spurious face changes
- [ ] 25-minute Pomodoro timer with LED indicator

---

## Stage 3 — WiFi & Time
- [x] WiFiManager hotspot onboarding (captive portal on first boot)
- [x] NTP time sync

---

## Stage 4 — Data Storage
- [x] Local storage on device
- [x] Write CSV log entries: `timestamp, face, activity, duration_sec`

---

## Stage 5 — Web Interface
- [ ] Activity dashboard with live status
- [ ] Per-face activity label configuration
- [ ] CSV export / download
- [x] Analytics page (`analytics.html`) — pie charts, monthly breakdown, daily view
