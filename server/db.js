'use strict';

const path = require('path');
const fs = require('fs');
const Database = require('better-sqlite3');

const DATA_DIR = path.join(__dirname, '..', 'data');
const DB_PATH = path.join(DATA_DIR, 'app.db');
const SCHEMA_PATH = path.join(__dirname, 'schema.sql');

// Ensure data directory exists
if (!fs.existsSync(DATA_DIR)) {
    fs.mkdirSync(DATA_DIR, { recursive: true });
}

const db = new Database(DB_PATH);

// Migration: drop anthropometric_profiles if it has the old patient-linked schema
// (identified by presence of user_id column)
const oldAnthro = db.prepare(
    `SELECT sql FROM sqlite_master WHERE type='table' AND name='anthropometric_profiles'`
).get();
if (oldAnthro?.sql?.includes('user_id')) {
    db.exec('DROP TABLE IF EXISTS anthropometric_profiles');
}

// Apply schema (idempotent — uses CREATE IF NOT EXISTS)
const schema = fs.readFileSync(SCHEMA_PATH, 'utf8');
db.exec(schema);

module.exports = db;
