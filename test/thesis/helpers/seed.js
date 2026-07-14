'use strict';

// Seed an isolated, synthetic SQLite database for the local test campaigns.
// Creates a throwaway admin user and a handful of SYNTHETIC anthropometric
// population profiles (no real people, no real datasets). Point the server at
// this DB with HANDFAB_DB_PATH.
//
// Usage: node test/thesis/helpers/seed.js <db_path>
// or programmatically: require(...).seed(dbPath)

const fs = require('fs');
const path = require('path');
const { THESIS_ADMIN } = require('./env');

// Synthetic reference populations. Values are plausible but invented — they are
// NOT drawn from ANSUR or any real survey. Enough shape for profileMapping and
// the grounding path (measurements tree + ai_context) to exercise fully.
const SYNTHETIC_PROFILES = [
    {
        group_name: 'SYNTHETIC Adult Male 50th (test)',
        country: 'Testland', gender: 'male', age_group: 'Adult (18-40)',
        percentile: '50th', sample_size: 100, data_source: 'synthetic',
        measurements: {
            palm: { width_mm: 88, length_mm: 108, thickness_mm: 30 },
            digits: {
                index: { total_length_mm: 74, proximal_length_mm: 32 },
                middle: { total_length_mm: 80, proximal_length_mm: 34 },
                ring: { total_length_mm: 75, proximal_length_mm: 32 },
                pinky: { total_length_mm: 60, proximal_length_mm: 25 },
                thumb: { total_length_mm: 62, proximal_length_mm: 30 },
            },
            wrist: { circumference_mm: 175 },
        },
    },
    {
        group_name: 'SYNTHETIC Adult Female 50th (test)',
        country: 'Testland', gender: 'female', age_group: 'Adult (18-40)',
        percentile: '50th', sample_size: 100, data_source: 'synthetic',
        measurements: {
            palm: { width_mm: 76, length_mm: 96, thickness_mm: 26 },
            digits: {
                index: { total_length_mm: 66, proximal_length_mm: 29 },
                middle: { total_length_mm: 72, proximal_length_mm: 31 },
                ring: { total_length_mm: 67, proximal_length_mm: 29 },
                pinky: { total_length_mm: 53, proximal_length_mm: 22 },
                thumb: { total_length_mm: 56, proximal_length_mm: 27 },
            },
            wrist: { circumference_mm: 152 },
        },
    },
    {
        group_name: 'SYNTHETIC Child Female age 7 (test)',
        country: 'Testland', gender: 'female', age_group: '7',
        percentile: '50th', sample_size: 40, data_source: 'synthetic',
        measurements: {
            palm: { width_mm: 58, length_mm: 70, thickness_mm: 18 },
            digits: {
                index: { total_length_mm: 46, proximal_length_mm: 20 },
                middle: { total_length_mm: 50, proximal_length_mm: 22 },
                ring: { total_length_mm: 47, proximal_length_mm: 20 },
                pinky: { total_length_mm: 38, proximal_length_mm: 16 },
                thumb: { total_length_mm: 40, proximal_length_mm: 19 },
            },
            wrist: { circumference_mm: 120 },
        },
    },
];

async function seed(dbPath) {
    if (!dbPath) throw new Error('seed(dbPath): dbPath required');
    // Ensure a completely fresh DB so campaigns are reproducible.
    for (const suffix of ['', '-wal', '-shm']) {
        const p = dbPath + suffix;
        if (fs.existsSync(p)) fs.unlinkSync(p);
    }
    fs.mkdirSync(path.dirname(dbPath), { recursive: true });

    // Load the real app DB module against the isolated path so the exact schema
    // + migrations are applied. This is why HANDFAB_DB_PATH must be set first.
    process.env.HANDFAB_DB_PATH = dbPath;
    // JWT secret must be valid for authService to load.
    if (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 32) {
        process.env.JWT_SECRET = require('./env').THESIS_JWT_SECRET;
    }
    delete require.cache[require.resolve('../../../server/db')];
    const db = require('../../../server/db');
    const { hashPassword } = require('../../../server/services/authService');

    const hash = await hashPassword(THESIS_ADMIN.password);
    db.prepare(
        `INSERT INTO users (username, email, password_hash, role, email_verified)
         VALUES (?, ?, ?, 'admin', 1)`
    ).run(THESIS_ADMIN.username, THESIS_ADMIN.email, hash);

    const insProfile = db.prepare(
        `INSERT INTO anthropometric_profiles
           (group_name, country, gender, age_group, percentile, sample_size,
            data_source, measurement_source, profile, geometry_parameters, ai_context)
         VALUES (?, ?, ?, ?, ?, ?, ?, 'synthetic', ?, ?, ?)`
    );
    for (const p of SYNTHETIC_PROFILES) {
        const profile = { measurements: p.measurements };
        const aiContext = {
            population: p.group_name,
            uncertainty: 'synthetic reference — not a real dataset',
            completeness: 'complete for mapped fields',
        };
        insProfile.run(
            p.group_name, p.country, p.gender, p.age_group, p.percentile,
            p.sample_size, p.data_source,
            JSON.stringify(profile), JSON.stringify({}), JSON.stringify(aiContext)
        );
    }

    const users = db.prepare('SELECT COUNT(*) AS c FROM users').get().c;
    const profs = db.prepare('SELECT COUNT(*) AS c FROM anthropometric_profiles').get().c;
    return { dbPath, users, profiles: profs, admin: THESIS_ADMIN.username };
}

module.exports = { seed, SYNTHETIC_PROFILES };

if (require.main === module) {
    const dbPath = process.argv[2] || path.join(__dirname, '..', '..', '..', 'data', 'thesis-test.db');
    seed(dbPath)
        .then(r => { console.log('Seeded isolated DB:', JSON.stringify(r)); process.exit(0); })
        .catch(e => { console.error('Seed failed:', e.message); process.exit(1); });
}
