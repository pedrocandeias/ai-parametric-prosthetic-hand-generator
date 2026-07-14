'use strict';

// Dependency-free STL mesh analyser for the thesis repetition campaigns.
//
// Parses binary or ASCII STL and derives the geometric metrics the protocol
// (protocolo_geral_avaliacao_plataforma.md §6.1) asks for so that two runs can
// be compared even when their SHA-256 differs:
//   - triangle (face) count and unique-vertex count
//   - axis-aligned bounding box + its dimensions
//   - signed volume (sum of tetra signed volumes, |value| in mm^3)
//   - watertightness / manifold condition (every edge shared by exactly 2 faces)
//   - degenerate (zero-area) face count
//
// It intentionally has no third-party dependencies so the analysis is auditable
// and reproducible. Coordinates are quantised (default 1e-4 mm) before hashing
// vertices/edges so that binary float noise does not masquerade as topology.

const crypto = require('crypto');

const QUANT = 1e-4; // mm — quantisation grid for vertex/edge identity

function isBinarySTL(buf) {
    // An ASCII STL starts with "solid". Some binary files also begin with the
    // bytes "solid", so confirm by checking whether the declared triangle count
    // matches the file length for the binary layout (84 + 50*n bytes).
    if (buf.length < 84) return false;
    const looksAscii = buf.slice(0, 5).toString('ascii').toLowerCase() === 'solid';
    if (!looksAscii) return true;
    const triCount = buf.readUInt32LE(80);
    return buf.length === 84 + triCount * 50;
}

function q(v) {
    // Quantise a coordinate to the identity grid, normalising -0 to 0.
    const r = Math.round(v / QUANT) * QUANT;
    return Object.is(r, -0) ? 0 : r;
}

function vkey(x, y, z) {
    return `${q(x)},${q(y)},${q(z)}`;
}

function parseBinary(buf) {
    const triCount = buf.readUInt32LE(80);
    const tris = [];
    let off = 84;
    for (let i = 0; i < triCount; i++) {
        // Skip 3 normal floats (12 bytes), read 3 vertices (9 floats).
        const base = off + 12;
        const v = [];
        for (let k = 0; k < 3; k++) {
            const p = base + k * 12;
            v.push([buf.readFloatLE(p), buf.readFloatLE(p + 4), buf.readFloatLE(p + 8)]);
        }
        tris.push(v);
        off += 50;
    }
    return tris;
}

function parseAscii(text) {
    const nums = [];
    const re = /vertex\s+(-?[\d.eE+]+)\s+(-?[\d.eE+]+)\s+(-?[\d.eE+]+)/g;
    let m;
    while ((m = re.exec(text)) !== null) {
        nums.push([parseFloat(m[1]), parseFloat(m[2]), parseFloat(m[3])]);
    }
    const tris = [];
    for (let i = 0; i + 2 < nums.length; i += 3) {
        tris.push([nums[i], nums[i + 1], nums[i + 2]]);
    }
    return tris;
}

function triArea(a, b, c) {
    const ux = b[0] - a[0], uy = b[1] - a[1], uz = b[2] - a[2];
    const vx = c[0] - a[0], vy = c[1] - a[1], vz = c[2] - a[2];
    const cx = uy * vz - uz * vy;
    const cy = uz * vx - ux * vz;
    const cz = ux * vy - uy * vx;
    return 0.5 * Math.sqrt(cx * cx + cy * cy + cz * cz);
}

function signedVolumeOfTri(a, b, c) {
    // Signed volume of the tetrahedron (origin, a, b, c); summed over a closed
    // mesh this yields the enclosed volume.
    return (
        a[0] * (b[1] * c[2] - b[2] * c[1]) -
        a[1] * (b[0] * c[2] - b[2] * c[0]) +
        a[2] * (b[0] * c[1] - b[1] * c[0])
    ) / 6;
}

/**
 * Analyse an STL buffer and return protocol geometry metrics.
 * @param {Buffer} buf
 * @returns {object}
 */
function analyzeSTL(buf) {
    const binary = isBinarySTL(buf);
    const tris = binary ? parseBinary(buf) : parseAscii(buf.toString('ascii'));

    const bbox = {
        min: [Infinity, Infinity, Infinity],
        max: [-Infinity, -Infinity, -Infinity],
    };
    const verts = new Set();
    const edges = new Map(); // quantised edge key -> incidence count
    let degenerate = 0;
    let volume = 0;
    let surfaceArea = 0;

    const edgeKey = (p, qk) => (p < qk ? `${p}|${qk}` : `${qk}|${p}`);

    for (const [a, b, c] of tris) {
        for (const p of [a, b, c]) {
            for (let d = 0; d < 3; d++) {
                if (p[d] < bbox.min[d]) bbox.min[d] = p[d];
                if (p[d] > bbox.max[d]) bbox.max[d] = p[d];
            }
        }
        const ka = vkey(...a), kb = vkey(...b), kc = vkey(...c);
        verts.add(ka); verts.add(kb); verts.add(kc);

        const area = triArea(a, b, c);
        surfaceArea += area;
        if (area <= 1e-9 || ka === kb || kb === kc || ka === kc) {
            degenerate++;
            continue; // do not count degenerate edges toward manifold check
        }
        volume += signedVolumeOfTri(a, b, c);

        for (const [p, qk] of [[ka, kb], [kb, kc], [kc, ka]]) {
            const ek = edgeKey(p, qk);
            edges.set(ek, (edges.get(ek) || 0) + 1);
        }
    }

    let boundaryEdges = 0; // shared by exactly 1 face
    let nonManifoldEdges = 0; // shared by >2 faces
    for (const count of edges.values()) {
        if (count === 1) boundaryEdges++;
        else if (count > 2) nonManifoldEdges++;
    }

    const dims = tris.length
        ? [bbox.max[0] - bbox.min[0], bbox.max[1] - bbox.min[1], bbox.max[2] - bbox.min[2]]
        : [0, 0, 0];

    return {
        format: binary ? 'binary' : 'ascii',
        bytes: buf.length,
        sha256: crypto.createHash('sha256').update(buf).digest('hex'),
        faces: tris.length,
        unique_vertices: verts.size,
        bbox: {
            min: bbox.min.map(r6),
            max: bbox.max.map(r6),
            dims_mm: dims.map(r6),
        },
        volume_mm3: r6(Math.abs(volume)),
        surface_area_mm2: r6(surfaceArea),
        degenerate_faces: degenerate,
        boundary_edges: boundaryEdges,
        non_manifold_edges: nonManifoldEdges,
        // Watertight: closed surface with no boundary edges. Manifold: no edge
        // shared by more than two faces. A print-ready mesh should be both.
        watertight: tris.length > 0 && boundaryEdges === 0,
        manifold: tris.length > 0 && nonManifoldEdges === 0,
    };
}

function r6(v) {
    return Number.isFinite(v) ? Math.round(v * 1e6) / 1e6 : v;
}

/**
 * Compare two analyses and classify their geometric relationship per §6.2.
 * `tolMm` is the pre-declared bounding-box tolerance in millimetres.
 * @returns {{binary_identical:boolean, geometry_class:string, deltas:object}}
 */
function compareAnalyses(ref, other, tolMm) {
    const binary_identical = ref.sha256 === other.sha256;
    const dimDeltas = ref.bbox.dims_mm.map((d, i) => r6(Math.abs(d - other.bbox.dims_mm[i])));
    const maxDimDelta = Math.max(...dimDeltas, 0);
    const volDelta = r6(Math.abs(ref.volume_mm3 - other.volume_mm3));
    const facesEqual = ref.faces === other.faces;
    const vertsEqual = ref.unique_vertices === other.unique_vertices;

    let geometry_class;
    if (binary_identical) {
        geometry_class = 'identical'; // same bytes → same geometry
    } else if (facesEqual && vertsEqual && maxDimDelta <= tolMm) {
        // Same topology and bbox within tolerance: a serialisation-only
        // difference (float ordering / attribute bytes), not a geometry change.
        geometry_class = 'serialization_only';
    } else if (maxDimDelta <= tolMm) {
        geometry_class = 'within_tolerance';
    } else {
        geometry_class = 'out_of_tolerance';
    }

    return {
        binary_identical,
        geometry_class,
        deltas: {
            max_bbox_dim_delta_mm: maxDimDelta,
            bbox_dim_deltas_mm: dimDeltas,
            volume_delta_mm3: volDelta,
            faces_equal: facesEqual,
            unique_vertices_equal: vertsEqual,
        },
    };
}

module.exports = { analyzeSTL, compareAnalyses, isBinarySTL, QUANT };
