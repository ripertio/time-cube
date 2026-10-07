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
snap_tab_height = 1.2;    // how far the tab protrudes below the lid [mm]
snap_recess_extra = 0.3;  // extra clearance for the matching recess [mm]

battery_length = 25;  // battery pocket length, along X [mm]
battery_width = 6.2;    // battery pocket width, along Y [mm]
battery_depth = 44;   // battery pocket depth, along Z, kept shallow so it sits in the upper cavity [mm]
battery_offset_y = 2; // distance from the pocket to the nearest Y side surface [mm]

mpu_length = 26;          // MPU board height, stands vertically along Z [mm]
mpu_width = 16;           // MPU board width, along X [mm]
mpu_pcb_height = 1.4;     // bare PCB thickness -> width (Y) of the bottom registration shelf [mm]
mpu_pcba_height = 2.5;    // populated PCBA thickness -> width (Y) of the main clearance slot [mm]
mpu_register_height = 2;  // height (Z) of the bottom registration shelf that grips the bare board edge [mm]
mpu_gap_from_battery = 2; // gap between the battery pocket and the MPU pocket, along Y [mm]

esp_length = 23.7;         // ESP32-S3-mini board height, stands vertically along Z [mm]
esp_width = 18.5;          // ESP32-S3-mini board width, along X [mm]
esp_pcb_height = 1.4;      // bare PCB thickness -> width (Y) of the bottom registration shelf [mm]
esp_pcba_height = 5;       // populated PCBA thickness -> width (Y) of the main clearance slot [mm]
esp_register_height = 1;   // height (Z) of the bottom registration shelf that grips the bare board edge [mm]
esp_gap_from_mpu = 15;     // gap between the MPU pocket and the ESP pocket, along Y [mm]

// Controls are mounted on their sides. They drop into top-open body pockets near
// X=size; their actuators point through openings in that outer wall.
switch_length = 9;             // switch body length, along Z when side-mounted [mm]
switch_width = 4;              // switch body width, along Y [mm]
switch_body_depth = 4;       // switch body depth, along X [mm]
switch_fit_clearance = 0.4;    // total clearance around the switch body [mm]
switch_pin_height = 5;         // terminal clearance depth inward from the body [mm]
switch_pin_channel_width = 1.8; // terminal wire channel width, along Y [mm]
switch_access_length = 7;      // side slot length, along Z [mm]
switch_access_width = 2.5;     // actuator channel width, along Y [mm]
switch_side_wall_thickness = 1.4; // remaining outer wall thickness at the switch [mm]
button_side_wall_thickness = 0.8; // flexure tongue thickness at the outer wall [mm]

// 3x6x4.5mm tactile button, laid on its side and top-loaded. The 4.5mm
// dimension faces X; the actuator points toward the X=size wall. A printed
// cantilever in that wall presses the tactile actuator from outside.
button_length = 6;              // body length, along Z when side-mounted [mm]
button_width = 3.5;             // body width, along Y [mm]
button_side_depth = 4.05;        // overall depth including actuator, along X [mm]
button_actuator_length = 3.2;   // actuator length, along Z [mm]
button_actuator_width = 1.8;    // actuator width, along Y [mm]
button_fit_clearance = 0.4;     // total clearance around the button body [mm]
button_pin_size = 1.6;          // 1.2mm terminal diameter plus print clearance [mm]
button_pin_depth = 5.2;         // terminal clearance depth inward from the body [mm]
button_pin_offset_z = 3.25;     // terminal pitch is 6.5mm, along Z when side-mounted [mm]

// Flat side-wall flexure. Parallel through-slots isolate a flush tongue that
// bends inward when pressed, with a relief pocket behind it for travel.
button_flexure_length = 8;           // cantilever length from press zone to root [mm]
button_flexure_slot_width = 0.4;      // width of the through-slots around the tongue [mm]
button_flexure_track_spacing = 4.0;   // distance between slot centerlines [mm]
button_flexure_clearance_depth = 0.8; // inward space behind tongue for flex [mm]
button_flexure_clearance_side = 0.4;  // extra width of the relief behind the tongue [mm]

// Y-axis layout: battery, then switch/button row, then ESP, then MPU.
// Each pocket's Y footprint is bounded by its wider (PCBA) clearance slot.
// The ESP pocket is mirrored 180° around its center so the USB-side of the board
// sits on the opposite edge from the LED-side placement.
row_gap_from_battery = 2;   // gap between the battery pocket and the switch/button row [mm]
esp_gap_from_row = 2;       // gap between the switch/button row and the ESP pocket [mm]
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
cable_channel_depth = 20;     // channel depth (Z) below the mating face [mm]
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
button_y_center = switch_y_center + switch_width / 2 + 1.5 + button_width / 2;
switch_z_center = size - split_h - switch_length / 2;
button_z_center = size - split_h - button_length / 2;
button_flexure_root_z = button_z_center - button_flexure_length;
button_flexure_slot_top_z = size - split_h + 0.5; // extend cutters past the base seam [mm]

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
corridor_width = 7;        // width of the side (Y-bar) corridor, along X [mm]
corridor_x_min = size / 2 + esp_width / 2 + wire_clearance; // just clear of the wider (ESP) board
corridor_y_start = battery_offset_y + battery_width;        // battery's back edge

spur_battery_width = 4;      // channel<->corridor spur width, sized for the battery's 2 cables [mm]
spur_battery_y_center = cable_channel_y_start + cable_channel_length / 2; // feed the gap at its center
spur_battery_x_start = (size + cable_channel_width) / 2 - 0.5; // overlap into the channel slightly

switch_body_x_min = size - switch_side_wall_thickness - switch_body_depth - switch_fit_clearance;
button_body_x_min = size - button_side_wall_thickness - button_side_depth - button_fit_clearance;
switch_terminal_x_min = switch_body_x_min - switch_pin_height - 0.25;
button_terminal_x_min = button_body_x_min - button_pin_depth;
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

// Two through-slots isolate a flat side-wall tongue. They run from its
// lower root to the cover seam; the outer face stays flush with the case.
module button_flexure_slots() {
    x = size - button_side_wall_thickness;
    cut_depth = button_side_wall_thickness + eps2;
    rail_offset = button_flexure_track_spacing / 2;
    root_z = button_flexure_root_z;
    slot_top_z = button_flexure_slot_top_z;
    slot_length = slot_top_z - root_z;
    slot_center_z = (root_z + slot_top_z) / 2;

    for (side = [-1, 1])
        side_stadium_slot(
            x,
            button_y_center + side * rail_offset,
            slot_center_z,
            slot_length,
            button_flexure_slot_width,
            cut_depth
        );
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

module base() {
    difference() {
        intersection() {
            rounded_cube(size, corner_r);
            translate([-1, -1, -1])
                cube([size + 2, size + 2, size - split_h + 1]);
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
        // Keep the switch's original direct side opening. The tactile button
        // now uses a flexible printed tongue instead of a hole through the wall.
        side_stadium_slot(size - switch_side_wall_thickness, switch_y_center, switch_access_cut_z_center, switch_access_cut_length, switch_access_width, switch_side_wall_thickness + eps2);
        button_flexure_slots();
        // Pocket behind the tongue, up to the cover seam, lets it deflect inward;
        // at the button this joins the existing top-loaded body pocket.
        translate([
            size - button_side_wall_thickness - button_flexure_clearance_depth,
            button_y_center - (button_flexure_track_spacing / 2 + button_flexure_clearance_side),
            button_flexure_root_z
        ])
            cube([
                button_flexure_clearance_depth + eps,
                button_flexure_track_spacing + 2 * button_flexure_clearance_side,
                button_flexure_slot_top_z - button_flexure_root_z
            ]);
        // Top-loaded, side-oriented switch body and inward terminal clearance
        translate([switch_body_x_min, switch_y_center - (switch_width + switch_fit_clearance) / 2, size - split_h - switch_length])
            cube([switch_body_depth + switch_fit_clearance, switch_width + switch_fit_clearance, switch_length + eps]);
        translate([switch_terminal_x_min, switch_y_center - switch_pin_channel_width / 2, size - split_h - wire_depth])
            cube([switch_body_x_min - switch_terminal_x_min + eps, switch_pin_channel_width, wire_depth + eps]);
        // Top-loaded 3x6x4.5mm button body and two inward-facing terminal clearances
        translate([button_body_x_min, button_y_center - (button_width + button_fit_clearance) / 2, size - split_h - button_length])
            cube([button_side_depth + button_fit_clearance, button_width + button_fit_clearance, button_length + eps]);
        for (pz = [button_z_center - button_pin_offset_z, button_z_center + button_pin_offset_z])
            let(pin_channel_z_min = pz - button_pin_size / 2)
                translate([button_terminal_x_min, button_y_center - button_pin_size / 2, pin_channel_z_min])
                    cube([button_body_x_min - button_terminal_x_min + eps, button_pin_size, size - split_h - pin_channel_z_min + eps]);
        // wiring: side corridor running past the MPU/ESP boards (clear of both
        // footprints), from the battery's back edge down to the switch/button row
        translate([corridor_x_min, corridor_y_start, size - split_h - wire_depth])
            cube([corridor_width, corridor_y_end - corridor_y_start, wire_depth + eps]);
        // wiring: spur connecting the corridor to the cable_channel (battery's cables)
        translate([spur_battery_x_start, spur_battery_y_center - spur_battery_width / 2, size - split_h - wire_depth])
            cube([corridor_x_min - spur_battery_x_start, spur_battery_width, wire_depth + eps]);
    }
}

module cover() {
    union() {
        difference() {
            intersection() {
                rounded_cube(size, corner_r);
                translate([-1, -1, size - split_h])
                    cube([size + 2, size + 2, split_h + 1]);
            }
            // USB-C charging slot, straight through the cover, above the ESP's socket
            translate([usbc_x_center, usbc_y_center, size - split_h / 2])
                stadium_slot(usbc_slot_length, usbc_slot_width, split_h + 2);
            // Underside reliefs clear the rotated terminals; the cover still bears on
            // each control body's top face and retains it in its pocket.
            translate([switch_terminal_x_min, switch_y_center - switch_pin_channel_width / 2, size - split_h - eps])
                cube([switch_body_x_min - switch_terminal_x_min, switch_pin_channel_width, 1.1]);
            translate([button_terminal_x_min, button_y_center - button_pin_size / 2, button_z_center + button_pin_offset_z - button_pin_size / 2])
                cube([button_body_x_min - button_terminal_x_min, button_pin_size, button_pin_size]);
        }
        // Protruding snap tabs engage the matching clearance recesses in the base.
        for (p = snap_positions)
            translate([p[0], p[1], size - split_h - snap_tab_height])
                cube([snap_tab_width, snap_tab_depth, snap_tab_height]);
    }
}

base();
translate([size +5 , 0, size])
    mirror([0, 0, 1])
        cover();
