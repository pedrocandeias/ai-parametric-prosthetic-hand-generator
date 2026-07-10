// =====================================================================
//  WRIST BACK WALL  —  e-NABLE Phoenix palm  (-Y gauntlet cuff)
//  Fills the back band between the dome rim and the wrist ears so the
//  dome -> side-walls -> ears read as ONE continuous gauntlet back wall,
//  matching the ghost (which the thin parametric wrist_walls under-filled).
//
//  Method: GHOST-CLIP (the project's accepted idiom, as used by
//  front_assembly / thumb_fill / the floor front): intersect a solid block
//  spanning the back band with import(ghost_stl) -> the EXACT ghost envelope
//  (continuous wall, correct thickness, lug bosses, floor) in that band.
//  Then re-cut the functional voids so they stay OPEN:
//    - the 2 hinge pin bores + inner counterbores (re-cut as clean tunnels)
//    - the 2 hinge windows (covered by the r3 tunnels, same axis)
//    - the cable-channel exits (re-subtract the dome CH sweeps)
//  Union this with the existing wrist()/dorsal_shell(); overlap is welded.
// =====================================================================

// Back-band clip box (measured from ghost occupancy, y -45..-24 / z 0..~21):
//   WB_Y1 sits just behind the dome rim station AY[0]=-30.5 so the fill
//   overlaps the dome legs (continuous, no seam); WB_Z1 stays below the
//   dome roof so the roof/channel mouths are owned by dorsal_shell.
WB_Y0 = -46.5;
WB_Y1 = -27.0;
WB_Z1 = 21.0;

module wrist_back() {
    difference() {
        intersection() {
            import(ghost_stl, convexity = 8);
            translate([-45, WB_Y0, 0]) cube([90, WB_Y1 - WB_Y0, WB_Z1]);
        }
        // --- keep the 2 hinge bores + counterbores + windows OPEN ---
        // one clean r=EAR_BORE_R tunnel per ear along X (EAR_Y,EAR_Z) clears the
        // lug bore AND the wall hinge window (same axis). The tunnel is wider
        // than the r2.5 wall window, but the union with the parametric wall
        // (solid in the r2.5..r3 annulus) restores the measured r2.5 window.
        for (ear = EARS) {
            cx = ear[0]; inner_sign = ear[1];
            translate([cx, EAR_Y, EAR_Z]) rotate([0,90,0])
                cylinder(h = 40, r = EAR_BORE_R, center = true);                  // through bore
            inner_face = cx + inner_sign*EAR_W/2;
            translate([inner_face - inner_sign*EAR_CB_D/2, EAR_Y, EAR_Z]) rotate([0,90,0])
                cylinder(h = EAR_CB_D, r = EAR_CB_R, center = true);              // inner counterbore
        }
        // --- keep the cable-channel exits OPEN ---
        for (channel = CH) path_sweep(circle(r = CH_R), channel);
    }
}
