// time-cube.scad
// 50mm cube with 3mm-radius rounded corners/edges,
// split into a base and a cover exactly 3mm from the top face.

size = 48;          // overall cube edge length [mm]
corner_r = 3;        // corner/edge rounding radius [mm]
split_h = 3;         // height of the cover slice, measured parallel to the top edge [mm]
gap = 90;            // visual separation between base and cover when previewing

// Manifold repair epsilon: prevents z-fighting artifacts in OpenSCAD rendering
eps = 0.01;          // small overlap/clearance to avoid floating-point precision issues
eps2 = 0.02;         // double epsilon for larger relief cuts

inner_cavity_depth = 28; // height of the upper internal cavity where the parts sit [mm]
inner_cavity_wall = 2;   // wall thickness around the internal cavity [mm]

snap_tab_inset = 4;       // distance of the snap tabs from the cover edge [mm]
snap_tab_width = 3.2;     // width of each snap tab [mm]
snap_tab_depth = 2.0;     // depth of each snap tab measured along the edge [mm]
snap_tab_height = 2.2;   // how far the tab protrudes below the lid [mm]
snap_recess_extra = 0.15; // total extra clearance for the matching recess, split across both sides [mm]
snap_tab_chamfer = 0.4;   // lead-in taper at the tab tip [mm]
snap_rib_width = 0.6;     // width (X) of each crush rib on the tab's Y faces [mm]
snap_rib_crush = 0.15;    // how far each rib protrudes from the tab face; exceeds the per-side clearance, so it grips [mm]

rabbet_width = 1;         // width of the stepped lip around the seam [mm]
rabbet_height = 1;        // height of the stepped lip [mm]
rabbet_clearance = 0.15;  // gap between the cover lip and the base step, horizontally and vertically [mm]

battery_length = 25;  // battery pocket length, along X [mm]
battery_width = 6.2;    // battery pocket width, along Y [mm]
battery_depth = 44;   // battery pocket depth, along Z, kept shallow so it sits in the upper cavity [mm]
battery_offset_y = 2; // distance from the pocket to the nearest Y side surface [mm]

mpu_length = 26;          // MPU board height, stands vertically along Z [mm]
mpu_width = 16;           // MPU board width, along X [mm]
mpu_pcb_height = 1.4;     // bare PCB thickness -> width (Y) of the bottom registration shelf [mm]
mpu_pcba_height = 2.5;    // populated PCBA thickness -> width (Y) of the main clearance slot [mm]
mpu_register_height = 2;  // height (Z) of the bottom registration shelf that grips the bare board edge [mm]

esp_length = 23.7;         // ESP32-S3-mini board height, stands vertically along Z [mm]
esp_width = 18.5;          // ESP32-S3-mini board width, along X [mm]
esp_pcb_height = 1.4;      // bare PCB thickness -> width (Y) of the bottom registration shelf [mm]
esp_pcba_height = 5.5;       // populated PCBA thickness -> width (Y) of the main clearance slot [mm]
esp_register_height = 1;   // height (Z) of the bottom registration shelf that grips the bare board edge [mm]
esp_gap_from_mpu = 20;     // gap between the MPU pocket and the ESP pocket, along Y [mm]

// The side switch remains in the X=size wall. The extra tactile switch is now
// mounted actuator-up beneath a flexure in the snap-fit cover.
switch_length = 8.7;             // switch body length, along Z when side-mounted [mm]
switch_width = 4;              // switch body width, along Y [mm]
switch_body_depth = 4;       // switch body depth, along X [mm]
switch_fit_clearance = 0.4;    // total clearance around the switch body [mm]
switch_pin_height = 5;         // terminal clearance depth inward from the body [mm]
switch_pin_channel_width = 1.8; // terminal wire channel width, along Y [mm]
switch_access_length = 7;      // side slot length, along Z [mm]
switch_access_width = 2.5;     // actuator channel width, along Y [mm]
switch_side_wall_thickness = 1.2; // remaining outer wall thickness at the switch [mm]

// 3x6x4.5mm tactile button, rotated actuator-up beneath the cover tongue.
// In this orientation its 6mm body dimension and terminal pitch run along Y.
// The two pin wells connect to the existing side wire corridor.
button_length = 3.5;              // switch body length along X [mm]
button_width = 6;             // switch body width along Y [mm]
button_side_depth = 3.9;        // body/actuator stack height along Z [mm]
button_actuator_width = 1.8;    // actuator width [mm]
button_fit_clearance = 0.4;     // total clearance around the switch body [mm]
button_pin_size = 1.6;          // terminal clearance square, along X and Y [mm]
button_pin_depth = 6.0;         // pin clearance down to the wire trench [mm]
button_pin_offset_y = 3.5;     // half the terminal spacing, centered along Y [mm]

// Flush top-cover flexure. A U-shaped through-slot isolates the tongue; an
// underside relief leaves a thin top skin and room for the switch body.
button_flexure_length = 13.5;         // tongue length, along X [mm]
button_flexure_slot_width = 0.8;      // rounded through-slot width [mm]
button_flexure_track_spacing = 4.6;   // distance between parallel slot centers [mm]
button_flexure_skin_thickness = 1.0;  // remaining top skin at the tongue [mm]
button_flexure_switch_gap = 0.2;      // clearance above the unpressed actuator [mm]

// Y-axis layout: battery, then switch/button row, then ESP, then MPU.
// Each pocket's Y footprint is bounded by its wider (PCBA) clearance slot.
// The ESP pocket is mirrored 180° around its center so the USB-side of the board
// sits on the opposite edge from the LED-side placement.
row_gap_from_battery = 2;   // gap between the battery pocket and the switch/button row [mm]
esp_gap_from_row = -3;       // gap between the switch/button row and the ESP pocket [mm]
row_y_start = battery_offset_y + battery_width + row_gap_from_battery;
row_y_center = row_y_start + max(switch_width, button_length) / 2;
row_y_end = row_y_start + max(switch_width, button_length);
esp_y_start = row_y_end + esp_gap_from_row;
esp_y_center = esp_y_start + esp_pcba_height / 2;
mpu_y_start = esp_y_start + esp_pcba_height + esp_gap_from_mpu;
mpu_y_center = mpu_y_start + mpu_pcba_height / 2;

// Cable channel between the ESP and MPU pockets: a trench cut into the top of the
// base, open at the mating face, that fills the whole gap between the two boards'
// clearance slots. Leaves each board's registration shelf/pcb-width slot mostly
// untouched, while giving the 4 interconnect wires a path that isn't pinched
// when the cover is fitted.
cable_channel_width = 14;       // channel size along X, room for the 4 wires [mm]
cable_channel_depth = 18;     // channel depth (Z) below the mating face [mm]
cable_channel_y_start = esp_y_start + esp_pcba_height - 0.5; // overlap into the ESP slot slightly
cable_channel_y_end = mpu_y_start + 0.5;                   // overlap into the MPU slot slightly
cable_channel_length = cable_channel_y_end - cable_channel_y_start; // spans the ESP/MPU gap with grip overlap
cable_channel_relief_length = mpu_y_start - cable_channel_y_start - 2; // stop side relief at the MPU pocket edge

// USB-C charging slot in the cover, above the ESP32-S3-mini's top edge, where its
// USB-C socket is soldered face-up on the PCB -- long axis runs along X (board width).
usbc_slot_length = 10;    // long-axis (X) size of the USB-C cutout [mm]
usbc_slot_width = 4.2;   // short-axis (Y) size of the USB-C cutout [mm]
usbc_x_center = size / 2;      // aligned with the ESP pocket's X center
usbc_y_center = esp_y_center + esp_pcba_height / 2 - usbc_slot_width / 2 - 0.5; // toward the ESP's outer edge

// Controls are side by side along Y on the X=size wall, away from the ESP pocket.
switch_y_center = row_y_center + 1;
button_gap_switch = 7;
button_y_center = switch_y_center + switch_width / 2 + button_gap_switch + button_width / 2;
switch_z_center = size - split_h - switch_length / 2;
button_top_x_center = 43;       // same side location as before, just inside the +X rim [mm]
button_top_y_center = button_y_center; // preserve the original button row [mm]
button_switch_top_z = size - button_flexure_skin_thickness - button_flexure_switch_gap;
button_body_bottom_z = button_switch_top_z - button_side_depth;
button_flexure_root_x = 30.5;   // root is inward of the actuator, clear of USB-C and snap features [mm]
button_flexure_tip_x = button_flexure_root_x + button_flexure_length;
button_flexure_slot_z = size - split_h / 2;
button_flexure_relief_x = button_flexure_root_x + 1.2;
button_flexure_relief_width = button_flexure_tip_x + 0.2 - button_flexure_relief_x;
button_wire_channel_width = 1; // width of each open-top pin-to-corridor route [mm]

// Switch slot extends upward to the cover seam, keeping its original lower edge.
// The slot bottom sits at (switch_z_center - switch_access_length/2).
// We extend it upward to the mating face, creating an overrun that makes
// the slot full-width (access_width → full width via half-width chamfer).
switch_slot_bottom_z = switch_z_center - switch_access_length / 2;
switch_slot_top_z = size - split_h;  // mating face (cover seam)
switch_access_cut_length = switch_slot_top_z - switch_slot_bottom_z + switch_access_width / 2;
switch_access_cut_z_center = switch_slot_bottom_z + switch_access_cut_length / 2;

// Wiring connectors (base only): shallow trenches connect top-loaded control
// terminals to the side corridor and then the existing interconnect cable channel.
wire_depth = 8;              // depth (Z) of all wiring connectors, from the mating face [mm]
wire_clearance = 0;        // clearance of the side corridor from the ESP pocket's edge [mm]
corridor_width = 5;        // width of the side (Y-bar) corridor, along X [mm]
corridor_x_min = size / 2 + esp_width / 2 + wire_clearance; // just clear of the wider (ESP) board
corridor_y_start = battery_offset_y + battery_width;        // battery's back edge

barrier_notch_width = 8;     // X width of the cut through the battery/ESP wall, for the ESP's +/- solder joints [mm]
barrier_notch_x_start = size / 2 + esp_width / 2 - barrier_notch_width; // flush with the ESP's high-X edge, where the corridor begins [mm]

spur_battery_width = 4;     // channel<->corridor spur width, sized for the battery's 2 cables [mm]
spur_battery_y_center = cable_channel_y_start + cable_channel_length / 2; // feed the gap at its center
spur_battery_x_start = (size + cable_channel_width) / 2 - 0.5; // overlap into the channel slightly

switch_body_x_min = size - switch_side_wall_thickness - switch_body_depth - switch_fit_clearance;
switch_terminal_x_min = switch_body_x_min - switch_pin_height - 0.25;
button_body_x_min = button_top_x_center - (button_length + button_fit_clearance) / 2;
button_body_y_min = button_top_y_center - (button_width + button_fit_clearance) / 2;
button_terminal_y1 = button_top_y_center - button_pin_offset_y;
button_terminal_y2 = button_top_y_center + button_pin_offset_y;
button_wire_x_end = button_top_x_center + (button_length + button_fit_clearance) / 2;
control_wire_y = cable_channel_y_start + cable_channel_length / 2;

// Prolong the battery's Y-bar corridor past the battery spur so the two connect.
corridor_y_end = spur_battery_x_start + 0.5;

$fn = 64;

snap_positions = [
    [snap_tab_inset, snap_tab_inset],
    [size - snap_tab_inset - snap_tab_width, snap_tab_inset],
    [snap_tab_inset, size - snap_tab_inset - snap_tab_depth],
    [size - snap_tab_inset - snap_tab_width, size - snap_tab_inset - snap_tab_depth],
];

// stadium-shaped (rounded-end) slot, extruded along Z, long axis along X
module stadium_slot(length, width, height) {
    r = width / 2;
    translate([0, 0, -height / 2])
        hull() {
            translate([-(length - width) / 2, 0, 0])
                cylinder(r = r, h = height, $fn = 32);
            translate([(length - width) / 2, 0, 0])
                cylinder(r = r, h = height, $fn = 32);
        }
}

module side_stadium_slot(x, y, z, length, width, depth) {
    translate([x + depth / 2, y, z])
        rotate([0, -90, 0])
            stadium_slot(length, width, depth);
}

// U-shaped through-slots make a flush top-cover tongue. The open end is toward
// the center of the lid; the root stays connected to the supported -X rim.
module button_flexure_slots() {
    cut_h = split_h + eps2;
    rail_offset = button_flexure_track_spacing / 2;
    for (side = [-1, 1])
        translate([(button_flexure_tip_x + button_flexure_root_x) / 2, button_top_y_center + side * rail_offset, button_flexure_slot_z])
            stadium_slot(button_flexure_length, button_flexure_slot_width, cut_h);
    // Cross-cut the two side slots at the free end, leaving the root intact.
    translate([button_flexure_tip_x, button_top_y_center, button_flexure_slot_z])
        rotate([0, 0, 90])
            stadium_slot(button_flexure_track_spacing, button_flexure_slot_width, cut_h);
}

module button_flexure_relief() {
    translate([
        button_flexure_relief_x,
        button_top_y_center - (button_flexure_track_spacing - button_flexure_slot_width) / 2,
        size - split_h - eps
    ])
        cube([
            button_flexure_relief_width,
            button_flexure_track_spacing - button_flexure_slot_width,
            split_h - button_flexure_skin_thickness + eps2
        ]);
    // Wider local pocket clears the rotated switch body under the free end.
    translate([
        button_body_x_min - 0.1,
        button_body_y_min - 0.1,
        size - split_h - eps
    ])
        cube([
            button_length + button_fit_clearance + 0.2,
            button_width + button_fit_clearance + 0.2,
            split_h - button_flexure_skin_thickness + eps2
        ]);
}
module button_terminal_channels() {
    for (py = [button_terminal_y1, button_terminal_y2])
        translate([
            button_top_x_center - button_pin_size / 2,
            py - button_pin_size / 2,
            button_body_bottom_z - button_pin_depth
        ])
            cube([button_pin_size, button_pin_size, button_pin_depth + eps]);
}

// Two separate top-open routes connect the Y-spaced pins to the existing
// side wire corridor. Each cut runs from the mating face down to wire_depth.
module button_pin_wire_channels() {
    for (py = [button_terminal_y1, button_terminal_y2])
        translate([
            corridor_x_min,
            py - button_wire_channel_width / 2,
            size - split_h - wire_depth
        ])
            cube([
                button_wire_x_end - corridor_x_min,
                button_wire_channel_width,
                wire_depth + eps
            ]);
}

module rounded_cube(s, r) {
    hull() {
        for (x = [r, s - r])
            for (y = [r, s - r])
                for (z = [r, s - r])
                    translate([x, y, z])
                        sphere(r = r);
    }
}

// rounded_cube shrunk by inset on every side, following the outer rounding
module inset_rounded_cube(inset) {
    translate([inset, inset, inset])
        rounded_cube(size - 2 * inset, corner_r - inset);
}

// Snap tab hanging from the cover (z=0 is the tab tip). The tip is tapered for
// lead-in; crush ribs on the Y faces take up the recess clearance.
module snap_tab() {
    c = snap_tab_chamfer;
    hull() {
        translate([c, c, 0])
            cube([snap_tab_width - 2 * c, snap_tab_depth - 2 * c, eps]);
        translate([0, 0, c])
            cube([snap_tab_width, snap_tab_depth, snap_tab_height - c + eps]); // eps: overlap into the cover
    }
    for (y = [-snap_rib_crush, snap_tab_depth - eps])
        translate([(snap_tab_width - snap_rib_width) / 2, y, c])
            cube([snap_rib_width, snap_rib_crush + eps, snap_tab_height - c]);
}

module base() {
    difference() {
        intersection() {
            rounded_cube(size, corner_r);
            translate([-1, -1, -1])
                cube([size + 2, size + 2, size - split_h + 1]);
        }
        // rabbet: step the outer rim down so the cover lip can seat over it
        difference() {
            translate([-1, -1, size - split_h - rabbet_height])
                cube([size + 2, size + 2, rabbet_height + 1]);
            inset_rounded_cube(rabbet_width);
        }
        // matching recesses for the lid snap tabs
        for (p = snap_positions)
            translate([p[0] - snap_recess_extra / 2, p[1] - snap_recess_extra / 2, size - split_h - snap_tab_height - 0.2])
                cube([snap_tab_width + snap_recess_extra, snap_tab_depth + snap_recess_extra, snap_tab_height + 0.4]);
        // battery pocket, open at the mating face, centered in X, offset toward one Y side
        translate([(size - battery_length) / 2, battery_offset_y, size - split_h - battery_depth])
            cube([battery_length, battery_width, battery_depth + eps]);
        // MPU sensor board pocket: a vertical slot, open only at the mating (top) face,
        // closed at the bottom. A narrow registration shelf at the very bottom grips
        // the bare PCB edge; the wider clearance slot above it (reaching all the way
        // to the top) gives the populated board room, so the header/socket at the
        // top of the board can be plugged in from above.
        translate([(size - mpu_width) / 2, mpu_y_center - mpu_pcb_height / 2, size - split_h - mpu_length])
            cube([mpu_width, mpu_pcb_height, mpu_register_height + eps]);
        translate([(size - mpu_width) / 2, mpu_y_center - mpu_pcba_height / 2, size - split_h - mpu_length + mpu_register_height - eps])
            cube([mpu_width, mpu_pcba_height, mpu_length - mpu_register_height + eps2]);
        // ESP32-S3-mini pocket: same vertical-slot style as the MPU pocket,
        // but mirrored 180° around its center so the USB-side of the board faces the
        // opposite side of the cube from the LED-side placement.
        translate([size / 2, esp_y_center, size - split_h - esp_length])
            rotate([0, 0, 180])
                translate([-esp_width / 2, -esp_pcb_height / 2, 0])
                    cube([esp_width, esp_pcb_height, esp_register_height + eps]);
        translate([size / 2, esp_y_center, size - split_h - esp_length + esp_register_height - eps])
            rotate([0, 0, 180])
                translate([-esp_width / 2, -esp_pcba_height / 2, 0])
                    cube([esp_width, esp_pcba_height, esp_length - esp_register_height + eps2]);
        // cable channel connecting the MPU and ESP pockets, for the interconnect wires
        translate([(size - cable_channel_width) / 2, cable_channel_y_start, size - split_h - cable_channel_depth])
            cube([cable_channel_width, cable_channel_length, cable_channel_depth + eps]);
        // Widen only the high-X side to wiring-trench depth. Stop at the MPU
        // pocket edge to preserve its holder; length follows the board spacing.
        translate([size / 2, cable_channel_y_start, size - split_h - wire_depth])
            cube([esp_width / 2, cable_channel_relief_length, wire_depth + eps]);
        // Keep the switch's original direct side opening.
        side_stadium_slot(size - switch_side_wall_thickness, switch_y_center, switch_access_cut_z_center, switch_access_cut_length, switch_access_width, switch_side_wall_thickness + eps2);
        // Top-loaded, side-oriented switch body and inward terminal clearance
        translate([switch_body_x_min, switch_y_center - (switch_width + switch_fit_clearance) / 2, size - split_h - switch_length])
            cube([switch_body_depth + switch_fit_clearance, switch_width + switch_fit_clearance, switch_length + eps]);
        translate([switch_terminal_x_min, switch_y_center - switch_pin_channel_width / 2, size - split_h - wire_depth])
            cube([switch_body_x_min - switch_terminal_x_min + eps, switch_pin_channel_width, wire_depth + eps]);
        // Actuator-up tactile switch pocket. The case body stops at its floor;
        // the switch's upper part sits in the cover's underside relief.
        translate([button_body_x_min, button_body_y_min, button_body_bottom_z])
            cube([
                button_length + button_fit_clearance,
                button_width + button_fit_clearance,
                size - split_h - button_body_bottom_z + eps
            ]);
        // wiring: side corridor running past the MPU/ESP boards (clear of both
        // footprints), from the battery's back edge down to the switch/button row
        translate([corridor_x_min, corridor_y_start, size - split_h - wire_depth])
            cube([corridor_width, corridor_y_end - corridor_y_start, wire_depth + eps]);
        // wiring: spur connecting the corridor to the cable_channel (battery's cables)
        translate([spur_battery_x_start, spur_battery_y_center - spur_battery_width / 2, size - split_h - wire_depth])
            cube([corridor_x_min - spur_battery_x_start, spur_battery_width, wire_depth + eps]);
        // wiring: notch through the battery/ESP wall, wire_depth deep like the other channels
        translate([barrier_notch_x_start, corridor_y_start - eps, size - split_h - wire_depth])
            cube([barrier_notch_width, esp_y_start - corridor_y_start + 2 * eps, wire_depth + eps]);
        // Separate open-top routes connect each Y-spaced button pin directly
        // to the existing wire corridor, so attached leads can be loaded from above.
        button_pin_wire_channels();
        button_terminal_channels();
    }
}

module cover() {
    union() {
        difference() {
            intersection() {
                rounded_cube(size, corner_r);
                translate([-1, -1, size - split_h - rabbet_height + rabbet_clearance])
                    cube([size + 2, size + 2, split_h + rabbet_height - rabbet_clearance + 1]);
            }
            // hollow the lip so only a rim ring hangs below the mating face
            intersection() {
                inset_rounded_cube(rabbet_width + rabbet_clearance);
                translate([-1, -1, size - split_h - rabbet_height])
                    cube([size + 2, size + 2, rabbet_height]);
            }
            // USB-C charging slot, straight through the cover, above the ESP's socket
            translate([usbc_x_center, usbc_y_center, size - split_h / 2])
                stadium_slot(usbc_slot_length, usbc_slot_width, split_h + 2);
            // Top-facing flexure tongue and its underside travel/switch relief.
            button_flexure_slots();
            button_flexure_relief();
            // Underside reliefs clear the rotated terminals; the cover still bears on
            // each control body's top face and retains it in its pocket.
            translate([switch_terminal_x_min, switch_y_center - switch_pin_channel_width / 2, size - split_h - eps])
                cube([switch_body_x_min - switch_terminal_x_min, switch_pin_channel_width, 1.1]);
        }
        // Protruding snap tabs engage the matching clearance recesses in the base.
        for (p = snap_positions)
            translate([p[0], p[1], size - split_h - snap_tab_height])
                snap_tab();
    }
}

// Print the base bottom-down. The cover is mirrored with its flat outer top face
// on the build plate; its underside flexure relief opens upward during printing.
base();

translate([0, 0, size])
        cover();