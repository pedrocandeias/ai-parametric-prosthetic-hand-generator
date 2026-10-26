'use strict';

// Unit tests for the OpenSCAD Customizer parser behind the admin "Models" tab
// and for model-definition validation. Run with:  npm run test:unit
// The registry opens the SQLite DB on require, so point it at a throwaway file.

const os = require('os');
const path = require('path');
const fs = require('fs');
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'handfab-models-'));
process.env.HANDFAB_DB_PATH = path.join(tmp, 'test.db');

const { test, after } = require('node:test');
const assert = require('node:assert/strict');
const { parseScadParameters } = require('../server/services/scadParser');
const { validateDefinition, isValidFileName } = require('../server/services/modelRegistry');

after(() => fs.rmSync(tmp, { recursive: true, force: true }));

const SRC = `
// Header comment that is not a caption

/* [Anthropometric] */
// Knuckle-to-knuckle breadth
palm_breadth_mm = 83; // [55:1:110]
wrist_circumference_mm = 160; // [120:200]
mirrored = false; // [false:Left hand, true:Right hand]

/* [Style] */
finish = "matte"; // [matte, gloss]
color_palm = "#cbd5e1";
show_palm = true;
joint_gap = 0.4;
palm_width_mm = 80;
scale = palm_breadth_mm / 55;
offsets = [1, 2, 3];
$fn = 48;

/* [Hidden] */
secret = 3;

/* [Global] */
module hand() {
    inner = 5;
}
after_module = 1;
`;

test('reads Customizer parameters with groups, ranges and captions', () => {
    const { parameters } = parseScadParameters(SRC);
    const byName = Object.fromEntries(parameters.map(p => [p.name, p]));
    assert.deepEqual(byName.palm_breadth_mm, {
        name: 'palm_breadth_mm', type: 'number', initial: 83, min: 55, step: 1, max: 110,
        group: 'Anthropometric', caption: 'Knuckle-to-knuckle breadth',
    });
    assert.equal(byName.wrist_circumference_mm.min, 120);
    assert.equal(byName.wrist_circumference_mm.max, 200);
    assert.equal(byName.wrist_circumference_mm.step, 1);
    assert.equal(byName.show_palm.type, 'boolean');
    assert.equal(byName.color_palm.type, 'color');
    assert.equal(byName.finish.type, 'enum');
    assert.deepEqual(byName.finish.options.map(o => o.value), ['matte', 'gloss']);
    assert.equal(byName.finish.group, 'Style');
});

test('labelled dropdown keeps value types', () => {
    const { parameters } = parseScadParameters(SRC);
    const m = parameters.find(p => p.name === 'mirrored');
    assert.equal(m.type, 'enum');
    assert.equal(m.initial, false);
    assert.deepEqual(m.options, [{ label: 'Left hand', value: false }, { label: 'Right hand', value: true }]);
});

test('skips expressions, vectors, $ variables, [Hidden] and anything after a module', () => {
    const { parameters, skipped } = parseScadParameters(SRC);
    const names = parameters.map(p => p.name);
    for (const n of ['scale', 'offsets', '$fn', 'secret', 'inner', 'after_module']) assert.ok(!names.includes(n), n);
    assert.deepEqual(skipped, [{ name: 'scale', reason: 'expression' }, { name: 'offsets', reason: 'vector' }]);
});

test('flags inferred ranges, laterality candidates and non-canonical anatomy names', () => {
    const { warnings } = parseScadParameters(SRC);
    const has = (name, code) => warnings.some(w => w.name === name && w.code === code);
    assert.ok(has('joint_gap', 'inferred_range'));
    assert.ok(has('mirrored', 'laterality_candidate'));
    assert.ok(has('palm_width_mm', 'non_canonical'));
    assert.ok(!has('palm_breadth_mm', 'non_canonical'));
    assert.ok(!has('wrist_circumference_mm', 'non_canonical'));
});

test('header comments separated by a blank line are not captions', () => {
    const { parameters } = parseScadParameters('// Licence text\n\nx = 1; // [0:10]\n');
    assert.equal(parameters[0].caption, undefined);
});

test('parses every repository model without losing a configured parameter', () => {
    const cfg = require('../models/models-config.json');
    const flexy = cfg.models.find(m => m.id === 'flexy_beast');
    const src = fs.readFileSync(path.join(__dirname, '..', 'models', flexy.file), 'utf8');
    const got = new Set(parseScadParameters(src).parameters.map(p => p.name));
    assert.deepEqual(flexy.parameters.map(p => p.name).filter(n => !got.has(n)), []);
});

const baseDef = () => ({
    name: 'Test hand', file: 'test_hand.scad',
    parameters: [{ name: 'palm_breadth_mm', type: 'number', initial: 80, min: 55, max: 110, step: 1 }],
});

test('accepts a minimal definition and strips server-owned fields', () => {
    const r = validateDefinition({ ...baseDef(), id: 'x', dependencies: [{ url: '../../etc' }], parts: [] });
    assert.ok(r.success);
    assert.equal(r.data.id, undefined);
    assert.equal(r.data.dependencies, undefined);
    assert.deepEqual(r.data.parts, []);
});

test('rejects invalid definitions', () => {
    const bad = [
        { ...baseDef(), file: '../evil.scad' },
        { ...baseDef(), file: 'model.stl' },
        { ...baseDef(), parameters: [] },
        { ...baseDef(), name: '<img src=x onerror=alert(1)>' },
        { ...baseDef(), parameters: [{ name: 'a b', type: 'number', initial: 1 }] },
        { ...baseDef(), parameters: [{ name: 'x', type: 'number', initial: 200, min: 0, max: 100 }] },
        { ...baseDef(), parameters: [{ name: 'x', type: 'enum', initial: 'c', options: [{ label: 'A', value: 'a' }] }] },
        { ...baseDef(), parameters: [{ name: 'x', type: 'boolean', initial: 1 }, { name: 'x', type: 'boolean', initial: true }] },
    ];
    for (const d of bad) assert.equal(validateDefinition(d).success, false, JSON.stringify(d).slice(0, 80));
});

test('file-name whitelist blocks traversal and unknown types', () => {
    for (const ok of ['hand.scad', 'gauntlet_v2.scad', 'Proximals.stl', 'logo.svg']) assert.ok(isValidFileName(ok), ok);
    for (const no of ['../hand.scad', '.hidden.scad', 'a/b.scad', 'x.html', 'x.js', 'x.scad.html', '']) assert.ok(!isValidFileName(no), no);
});
