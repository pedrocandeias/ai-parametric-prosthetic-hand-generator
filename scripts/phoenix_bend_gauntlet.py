#!/usr/bin/env python3
"""Generate the PREVIEW-ONLY thermoformed (tube) Phoenix gauntlet mesh.

The Team UnLimbited Phoenix gauntlet (`Gauntlet_V4`) is distributed as a FLAT
plate: that is how it prints, and that is what the print-bed layout / STL export
must keep. In real use it is heat-formed over the `Jig` — the tapered arch-
section former that ships in the same .scad — so the assembled hand actually
wears it as a tube around the forearm.

This script wraps the flat plate onto a forearm section and writes the result as
a static polyhedron (`Gauntlet_V4_curved()`), used ONLY by the assembled preview
in phoenix_assembly.scad.

Why precomputed instead of a live OpenSCAD transform: the flat plate is a coarse
mesh (large triangles spanning the full 95 mm width), so any bend has to
subdivide it first. Doing that per render — either with N boolean slices or a
dense in-language remap — costs seconds in the browser WASM build on every
parameter change. The plate itself is a fixed mesh (only uniformly scaled by
HandPerc), so baking the bend once is both cheaper and exact.

Section
    The jig confirms the shape family — a half-ellipse: flat base, arched top,
    growing from wrist to elbow — but not the size. Its own arch (43 mm wide at
    the small end) is far narrower than the wrist the gauntlet has to meet, so
    the section is set by the hinge instead (see EAR_ARC/A_EAR below): the ears
    must come out vertical and flat to meet the palm's, and that alone fixes the
    arch at the wrist. From there it rounds out into a tube up the forearm.

Method
    1. Read the `Gauntlet_V4` mesh (and the palm, for reference) out of
       UnLimbitedPhoenix.scad.
    2. Cut the flat plate with planes x = const (and z = const across the ear
       ramp) so the bend has vertices to follow. Plane cuts are edge-
       deterministic, so the mesh stays watertight (the manifold backend
       silently DROPS meshes it cannot convert).
    3. Map every vertex: |x| is arc length from the crown of the arch, and the
       plate's own y (0..4.89 thickness) becomes an outward normal offset.
       Past the base of the arch the section continues straight down; at the
       wrist the hinge boss leaves the arch earlier and stays flat (FLAT_ARC).
    Output frame matches the flat plate: crown line on y = 0, centred on x = 0,
    z unchanged — so the assembly seats both versions with one GAUNT_POS (only
    its z rises to the palm's crown, see phoenix_assembly.scad).

Usage:  python3 scripts/phoenix_bend_gauntlet.py
"""

import math
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.path.join(HERE, "..", "models", "active", "unlimbed_phoenix_hand")
SRC = os.path.join(MODEL_DIR, "UnLimbitedPhoenix.scad")
OUT = os.path.join(MODEL_DIR, "phoenix_gauntlet_curved.scad")

CUT_STEP = 3.0   # mm between the x cutting planes (bend resolution across the width)
Z_CUT_STEP = 3.0   # mm between the z cutting planes (the fold migrates along the guard)
ROUND = 3        # decimals kept in the emitted point list

# ── the hinge ears set the wrist section ────────────────────────────────────
# Measured on the flat plate: the square hinge-tab holes sit at x = +-EAR_ARC,
# z = Z_EAR. EAR_ARC is therefore the arc length from the crown to the ear, so
# solving the arch height from A_EAR such that the quarter perimeter equals it
# puts the base of the arch — where the wall stands vertical — right at the
# hinge. The ear itself is held vertical by FLAT_ARC below, but this keeps the
# shell almost vertical there too, so the fold into the ear stays shallow.
EAR_ARC = 30.0   # |x| of the hinge-tab hole on the flat plate
Z_EAR = -81.75   # z  of the hinge-tab hole on the flat plate
A_EAR = 28.0     # half-width of the section at the ear
# The ear is a stiff boss, so it does not roll with the shell: it stays FLAT and
# hangs vertically off a bend line just inboard of it. FLAT_ARC is that bend
# line. It must clear the WHOLE boss or the disc comes out distorted — the plate
# widens into it between z -84 and -74, spanning arc 22.15..38.14 — so the bend
# sits at 22, and every point of the boss is then a rigid drop from one bend
# line at one z: the disc stays exactly round and its face planar, square to the
# hinge axis.
# Only the wrist end bends this way. Along Z_FLAT_* the bend line MIGRATES
# outward until it reaches the base of the arch, where a vertical drop is what
# the section does anyway — so the fold fades out with no pleating, leaving the
# rest of the guard rolled into its tube. (Blending the two positions instead
# crumples the shell: the free edge is pulled several mm out of place.) Because
# the fold's position varies along the guard, the z cuts have to span its whole
# length — the plate's own triangles are far too long in z to follow it.
FLAT_ARC = 22.0
R_FOLD = 2.0     # bend radius of that fold (mm) — a sharp crease would make the
                 # plate's own thickness overlap itself on the inside of the bend
Z_FLAT_FULL = -73.0   # bend line fully in at/below this z (clear of the boss)
Z_FLAT_NONE = -25.0   # bend line out at the base of the arch at/above this z

# The ear has to end up OUTBOARD of the palm's wrist wall (palm boss | ear |
# washer | pin head), and no amount of bending gets it there: nothing at 30 mm of
# arc can sit more than 30 mm from the guard's axis, the palm's wall is already
# 30.92 mm out, and turning the ear 90 deg spends several mm more of that. The
# material has to give — so the whole guard is stretched sideways by one uniform
# factor, solved to land the ear's inner face exactly on the palm's wall. One
# global scale, not a local flare: the ear planes are normal to X, so stretching
# X moves them without touching the disc's shape, and the shell just widens.
PALM_WALL_HALF = 30.92  # palm ear boss outer face, out from the guard axis (world x 24.08/85.92)

# Height of the guard's crown line in the assembly (GAUNT_POS.z there); only
# used to report where the ear boss lands against the palm's hinge. The ear hole
# is a fixed drop below the crown (the bend depth plus EAR_ARC - FLAT_ARC of
# vertical wall), so this is what puts it on the palm's wrist-pin axis at z 8.5.
GAUNT_CROWN_Z = 20.33
Z_ELBOW = 0.0    # plate z at the open (elbow) end
A_ELBOW = 24.0   # elbow half-width / arch height (BEFORE the lateral stretch):
B_ELBOW = 26.0   # the guard rounds out into a tube as it runs up the forearm


# ── mesh extraction ─────────────────────────────────────────────────────────
def read_mesh(src, name):
    i = src.index(name + "_points()")
    pts = [tuple(map(float, p)) for p in
           re.findall(r"\[(-?[\d.]+),(-?[\d.]+),(-?[\d.]+)\]", src[i:src.index("];", i)])]
    i = src.index(name + "_faces()")
    faces = [tuple(int(k) for k in f.split(","))
             for f in re.findall(r"\[([\d,]+)\]", src[i:src.index("];", i)])]
    return pts, faces


# ── seam section: the palm's own thermoformed wrist arch ────────────────────
def palm_wrist_arch(pts, band=(-150.0, -144.0)):
    """Half-width and arch height of the palm shell where the gauntlet meets it.
    Returns (a, b, crown_z): the wrist end of the guard is wrapped onto exactly
    this half-ellipse, so the two shells line up at the seam."""
    s = [p for p in pts if band[0] <= p[1] <= band[1]]
    a = (max(p[0] for p in s) - min(p[0] for p in s)) / 2
    zlo, zhi = min(p[2] for p in s), max(p[2] for p in s)
    return a, zhi - zlo, zhi


# ── watertight subdivision: cut the triangle soup with axis = const planes ──
def cut_by(tris, axis, planes):
    for c in planes:
        nxt = []
        for tri in tris:
            d = [v[axis] - c for v in tri]
            if max(d) <= 0 or min(d) >= 0:
                nxt.append(tri)
                continue
            # lone vertex on one side of the plane, the other two opposite
            lone = next(i for i in range(3) if (d[i] > 0) != (d[(i + 1) % 3] > 0)
                        and (d[i] > 0) != (d[(i + 2) % 3] > 0))
            a, b, cc = tri[lone], tri[(lone + 1) % 3], tri[(lone + 2) % 3]
            p, q = split_edge(a, b, axis, c), split_edge(a, cc, axis, c)
            nxt += [(a, p, q), (p, b, cc), (p, cc, q)]
        tris = nxt
    return tris


def split_edge(u, v, axis, c):
    """Point where edge u-v crosses axis = c. Endpoint order is canonicalised so
    both triangles sharing the edge get bit-identical coordinates."""
    a, b = (u, v) if u <= v else (v, u)
    t = (c - a[axis]) / (b[axis] - a[axis])
    p = tuple(a[k] + t * (b[k] - a[k]) for k in range(3))
    return p[:axis] + (c,) + p[axis + 1:]


# ── the wrap itself ─────────────────────────────────────────────────────────
def smoothstep(u):
    u = min(1.0, max(0.0, u))
    return u * u * (3 - 2 * u)


def solve_b(a, arc):
    """Arch height whose quarter perimeter is `arc` — i.e. the section that puts
    the base of the arch (where the wall stands vertical) exactly `arc` of plate
    away from the crown."""
    lo, hi = 0.01, 3 * a
    for _ in range(80):
        mid = (lo + hi) / 2
        if quarter_arc(a, mid) < arc:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2


def make_wrap(b_ear):
    span = Z_ELBOW - Z_EAR

    def section(z):
        t = (z - Z_EAR) / span
        return (A_EAR + (A_ELBOW - A_EAR) * t,   # half-width of the arch at this z
                b_ear + (B_ELBOW - b_ear) * t)   # height of the arch at this z

    def rolled(a, b, s, y):
        """Point at arc length s, offset y along the outward normal — the shell
        following the section, continuing straight down past the base."""
        t, smax = arc_to_t(a, b, s)
        if t is None:
            return (a + y, -b - (s - smax))      # past the base: vertical wall
        ct, st = math.cos(t), math.sin(t)
        nx, ny = b * st, a * ct                  # outward normal (unnormalised)
        n = math.hypot(nx, ny)
        return (a * st + y * nx / n, b * ct - b + y * ny / n)

    def tilt(a, b, s):
        """Angle the shell has turned away from the crown at arc s, in radians:
        0 flat, pi/2 standing vertical (the outward normal is (sin, cos) of it)."""
        t, _ = arc_to_t(a, b, s)
        return math.pi / 2 if t is None else math.atan2(b * math.sin(t), a * math.cos(t))

    def folded(a, b, s_end, s, y):
        """The shell rolled to arc `s`, but turned upright early: it leaves the
        section, sweeps R_FOLD radius round to vertical by arc s_end, and runs
        straight down after that. The fillet matters — folding on a zero radius
        makes the plate's own thickness overlap itself in the crease."""
        a0 = tilt(a, b, s_end)                   # how far it has turned already
        turn = math.pi / 2 - a0
        s0 = s_end - R_FOLD * turn               # where the fillet starts
        if s <= s0:
            return rolled(a, b, s, y)
        # centre of the fillet, on the inside of the bend
        px, py = rolled(a, b, s0, 0)
        cx, cy = px - R_FOLD * math.sin(a0), py - R_FOLD * math.cos(a0)
        if s <= s_end:                           # on the fillet
            ang = a0 + (s - s0) / R_FOLD
            return (cx + (R_FOLD + y) * math.sin(ang),
                    cy + (R_FOLD + y) * math.cos(ang))
        return (cx + R_FOLD + y, cy - (s - s_end))  # vertical below it

    def bend_arc(a, b, z):
        """Arc by which the shell has finished standing upright. At the ear that
        is FLAT_ARC — the fold completes just before the boss, so the boss is
        flat — and it migrates out to the base of the arch, where the section
        goes vertical by itself, over Z_FLAT_FULL..NONE."""
        base = quarter_arc(a, b)
        k = smoothstep((z - Z_FLAT_NONE) / (Z_FLAT_FULL - Z_FLAT_NONE))
        return base + (FLAT_ARC - base) * k

    # lateral stretch that carries the ears clear of the palm's wrist wall
    stretch = PALM_WALL_HALF / folded(*section(Z_EAR), FLAT_ARC, FLAT_ARC, 0)[0]

    def wrap(v):
        x, y, z = v
        a, b = section(z)
        s = abs(x)
        px, py = folded(a, b, bend_arc(a, b, z), s, y)
        return ((1.0 if x >= 0 else -1.0) * stretch * px, py, z)

    return wrap


def arc_to_t(a, b, s):
    """Invert arc length -> ellipse parameter t, measured from the crown.
    Returns (t, quarter_arc); t is None when s runs past the base."""
    smax = quarter_arc(a, b)
    if s >= smax:
        return None, smax
    lo, hi = 0.0, math.pi / 2
    for _ in range(60):
        mid = (lo + hi) / 2
        if arc_len(a, b, mid) < s:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2, smax


def arc_len(a, b, t, n=64):
    h = t / n
    return h * sum(_ds(a, b, (i + 0.5) * h) for i in range(n))


def quarter_arc(a, b):
    return arc_len(a, b, math.pi / 2, 256)


def _ds(a, b, t):
    return math.hypot(a * math.cos(t), b * math.sin(t))


# ── emit ────────────────────────────────────────────────────────────────────
def main():
    src = open(SRC).read()
    gp, gf = read_mesh(src, "Gauntlet_V4")
    pp, _ = read_mesh(src, "Phoenix_Thermo_Palm_2")
    b_ear = solve_b(A_EAR, EAR_ARC)
    print(f"palm wrist arch (reference): half-width {palm_wrist_arch(pp)[0]:.2f} mm, "
          f"height {palm_wrist_arch(pp)[1]:.2f} mm, crown at z {palm_wrist_arch(pp)[2]:.2f}")
    print(f"ear section: {2*A_EAR:.1f} x {b_ear:.2f} mm (quarter arc "
          f"{quarter_arc(A_EAR, b_ear):.2f} = ear arc {EAR_ARC})")
    # where the hinge boss actually lands, straight out of the map
    ix = make_wrap(b_ear)((EAR_ARC, 0.0, Z_EAR))[0]
    ox, ey, _ = make_wrap(b_ear)((EAR_ARC, 3.8, Z_EAR))
    print(f"  ear plate -> world x {55 - ix:.2f}..{55 - ox:.2f} / "
          f"{55 + ix:.2f}..{55 + ox:.2f} (outboard of the palm wall at 24.08 / 85.92)")
    print(f"  ear hole  -> world z {GAUNT_CROWN_Z + ey:.2f} (palm ear holes 8.5); "
          f"guard crown at z {GAUNT_CROWN_Z} (GAUNT_LIFT in phoenix_assembly.scad)")
    for z, a, b in ((Z_EAR, A_EAR, b_ear), (Z_ELBOW, A_ELBOW, B_ELBOW)):
        half = max(abs(p[0]) for p in gp if abs(p[2] - z) < 3)
        print(f"  z={z:6.1f}: section {2*a:.1f} x {b:.1f} mm, quarter arc "
              f"{quarter_arc(a, b):.1f} mm vs plate half-width {half:.1f} mm")

    tris = [tuple(gp[i] for i in f) for f in gf]
    xlo = min(p[0] for p in gp)
    xhi = max(p[0] for p in gp)
    n = int((xhi - xlo) / CUT_STEP)
    xplanes = [xlo + (xhi - xlo) * (i + 1) / (n + 1) for i in range(n)]
    # z planes over the whole guard: the fold's position varies along it, and the
    # plate's own triangles are far too long in z to follow that
    zlo = min(p[2] for p in gp)
    m = int((0 - zlo) / Z_CUT_STEP)
    zplanes = [zlo + (0 - zlo) * (i + 1) / (m + 1) for i in range(m)]
    tris = cut_by(cut_by(tris, 0, xplanes), 2, zplanes)
    print(f"triangles {len(gf)} -> {len(tris)} "
          f"({len(xplanes)} x planes, {len(zplanes)} z planes)")

    wrap = make_wrap(b_ear)
    cache, points, faces = {}, [], []
    for tri in tris:
        idx = []
        for v in tri:
            k = tuple(round(c, 6) for c in v)
            if k not in cache:
                cache[k] = len(points)
                points.append(wrap(v))
            idx.append(cache[k])
        if len(set(idx)) == 3:
            faces.append(idx)
    print(f"vertices {len(points)}  faces {len(faces)}")

    fmt = lambda p: "[%s]" % ",".join(f"{c:.{ROUND}f}".rstrip("0").rstrip(".") or "0" for c in p)
    with open(OUT, "w") as fh:
        fh.write(
            "// ==========================================================================\n"
            "//  phoenix_gauntlet_curved.scad — GENERATED, do not edit by hand\n"
            "//    scripts/phoenix_bend_gauntlet.py\n"
            "//\n"
            "//  Preview-only thermoformed Phoenix gauntlet: the flat Gauntlet_V4 plate\n"
            "//  wrapped onto the forearm, so the assembled view shows the arm guard as\n"
            "//  the tube it becomes on the arm (heat-formed over the Jig former in real\n"
            "//  life). The printed part stays FLAT — the print-bed layout still uses\n"
            "//  Gauntlet_V4().\n"
            "//\n"
            "//  Half-elliptical section (flat base, arched top), linear along the guard:\n"
            f"//    ear   (z={Z_EAR:.1f}): {2*A_EAR:.1f} x {b_ear:.2f} mm — height solved so the base of\n"
            "//                    the arch falls on the hinge tabs, i.e. the ears come out\n"
            "//                    VERTICAL, parallel to (and flush inboard of) the palm's\n"
            f"//    elbow (z={Z_ELBOW:.0f}):   {2*A_ELBOW:.1f} x {B_ELBOW:.1f} mm — rounds out into a tube\n"
            "//  Same frame as the flat plate: crown line on y = 0, centred on x = 0, z\n"
            "//  unchanged — so GAUNT_POS/GAUNT_ROT seat both versions identically.\n"
            "// ==========================================================================\n"
            "function Gauntlet_V4_curved_faces() = [\n")
        fh.write(",".join("[%d,%d,%d]" % tuple(f) for f in faces))
        fh.write("];\nfunction Gauntlet_V4_curved_points() = [\n")
        fh.write(",".join(fmt(p) for p in points))
        fh.write("];\nmodule Gauntlet_V4_curved() {\n"
                 "\tpolyhedron(faces = Gauntlet_V4_curved_faces(), "
                 "points = Gauntlet_V4_curved_points(), convexity = 10);\n}\n")
    print(f"wrote {OUT} ({os.path.getsize(OUT)/1024:.0f} KB)")


if __name__ == "__main__":
    main()
