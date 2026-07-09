// ============================================
// Finger_Hinge_Plate — parametric reconstruction
// Method: top-view 2D profile + linear_extrude (both part
// types are constant-section vertical prisms).
// All dims measured from models/Finger_Hinge_Plate.stl.
// ============================================

$fn = 96;

// --- Dogbone link (11 copies): two lobes + narrow bar, 12mm tall ---
dog_lobe_r   = 2.491;   // end-circle radius (Y extent 4.98 -> r 2.49)
dog_lobe_x   = 5.00;    // lobe center offset from part center (X15 -> +-5.0)
dog_bar_hw   = 0.99;    // half-width of connecting bar (bar width 1.98)
dog_h        = 12.0;    // extrude height

// --- Eyelet link (4 copies): drilled ring at one end, blob at the other,
//     joined by an asymmetric neck. Outer outline traced from the mesh
//     top-section (constant along Z); hole is a clean bore. 16mm tall ---
eye_ring_c   = [ 6.79, -1.19];  // ring (eyelet) center
eye_hole_r   = 1.99;            // through-hole radius
eye_h        = 16.0;            // extrude height
eye_outline  = [
        [6.895,-4.692],
        [6.311,-4.656], [5.742,-4.525], [5.202,-4.302], [4.707,-3.994],
        [4.269,-3.607], [3.901,-3.155], [3.612,-2.647], [3.411,-2.098],
        [2.866,-1.893], [2.366,-1.606], [1.918,-1.230], [1.469,-0.854],
        [1.021,-0.477], [0.573,-0.101], [0.104,0.161], [-0.446,-0.039],
        [-0.996,-0.240], [-1.546,-0.440], [-2.096,-0.640], [-2.653,-0.800],
        [-3.238,-0.800], [-3.823,-0.800], [-4.226,-1.183], [-4.659,-1.575],
        [-5.153,-1.888], [-5.691,-2.115], [-6.259,-2.250], [-6.841,-2.290],
        [-7.422,-2.233], [-7.986,-2.081], [-8.517,-1.839], [-9.000,-1.509],
        [-9.417,-1.100], [-9.761,-0.628], [-10.023,-0.106], [-10.196,0.451],
        [-10.274,1.030], [-10.256,1.613], [-10.142,2.186], [-9.932,2.732],
        [-9.630,3.232], [-9.250,3.676], [-8.802,4.050], [-8.299,4.346],
        [-7.754,4.555], [-7.182,4.671], [-6.598,4.692], [-6.019,4.614],
        [-5.462,4.435], [-4.944,4.167], [-4.476,3.817], [-4.073,3.395],
        [-3.580,3.200], [-2.995,3.200], [-2.417,3.158], [-1.867,2.958],
        [-1.317,2.758], [-0.767,2.557], [-0.217,2.357], [0.340,2.200],
        [0.925,2.200], [1.511,2.200], [2.096,2.200], [2.681,2.200],
        [3.266,2.200], [3.819,2.016], [4.369,1.816], [4.907,1.746],
        [5.423,2.018], [5.978,2.200], [6.554,2.290], [7.138,2.282],
        [7.713,2.179], [8.263,1.981], [8.769,1.688], [9.219,1.316],
        [9.602,0.876], [9.908,0.378], [10.127,-0.163], [10.254,-0.733],
        [10.285,-1.316], [10.219,-1.897], [10.051,-2.456], [9.792,-2.980],
        [9.451,-3.454], [9.037,-3.865], [8.561,-4.203], [8.035,-4.457],
        [7.475,-4.622]
];

// --- Measured plate layout (part-center X,Y for each body) ---
dog_positions = [
    [-18.21,-14.34], [-18.12,-8.67], [-18.07,-2.99],
    [-17.88,  2.66], [-17.81, 8.27], [-17.82,13.86],   // left column (6)
    [ 20.33,-12.66], [ 20.35,-7.09], [ 20.01,-1.48],
    [ 20.32,  4.09], [ 20.60, 9.60]                     // right column (5)
];
eye_positions = [
    [1.20,-13.68], [1.09,-5.15], [1.03,3.72], [0.97,12.33]
];

// ---------- 2D profiles ----------
module dogbone_profile() {
    union() {
        translate([-dog_lobe_x, 0]) circle(r = dog_lobe_r);
        translate([ dog_lobe_x, 0]) circle(r = dog_lobe_r);
        hull() {
            translate([-dog_lobe_x, 0]) circle(r = dog_bar_hw);
            translate([ dog_lobe_x, 0]) circle(r = dog_bar_hw);
        }
    }
}

module eyelet_profile() {
    difference() {
        polygon(eye_outline);
        translate(eye_ring_c) circle(r = eye_hole_r);
    }
}

// ---------- 3D parts ----------
module dogbone() linear_extrude(height = dog_h) dogbone_profile();
module eyelet()  linear_extrude(height = eye_h)  eyelet_profile();

// ---------- Assembly ----------
module plate() {
    for (p = dog_positions) translate([p[0], p[1], 0]) dogbone();
    for (p = eye_positions) translate([p[0], p[1], 0]) eyelet();
}

plate();
