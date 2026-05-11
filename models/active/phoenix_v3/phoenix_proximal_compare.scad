// Comparison: FreeCAD mesh reference (blue) vs parametric reconstruction (red)
// Both rendered to STL first, then imported here for side-by-side visual check.
// Run from project root:
//   openscad models/active/phoenix_v3/phoenix_proximal_compare.scad

GAP = 20;

// Blue = FreeCAD mesh reference (ground truth, translated to origin)
color("skyblue", 0.7)
translate([-(12.4 + GAP/2), 0, 0])
    import("freecad_proximal_origin.stl");

// Red = parametric CSG reconstruction
color("tomato", 0.7)
translate([GAP/2, 0, 0])
    import("phoenix_proximal_output.stl");
