'use strict';

const path = require('path');
const fs = require('fs');
const { DatabaseSync } = require('node:sqlite');

// DB location. Defaults to data/app.db. `HANDFAB_DB_PATH` overrides it so an
// isolated, synthetic database can be used for automated test campaigns without
// touching production data — a testability seam only; the default is unchanged
// and no runtime behaviour differs when the variable is unset.
const DB_PATH = process.env.HANDFAB_DB_PATH || path.join(__dirname, '..', 'data', 'app.db');
const DATA_DIR = path.dirname(DB_PATH);
const SCHEMA_PATH = path.join(__dirname, 'schema.sql');

// Ensure data directory exists
if (!fs.existsSync(DATA_DIR)) {
    fs.mkdirSync(DATA_DIR, { recursive: true });
}

const db = new DatabaseSync(DB_PATH);

// node:sqlite (Node's built-in SQLite) has no transaction() helper. Provide a
// better-sqlite3-compatible shim: db.transaction(fn) returns a function that runs
// fn inside BEGIN/COMMIT, rolling back on error. Keeps existing call sites
// (e.g. authService.consumeResetToken) unchanged.
db.transaction = (fn) => (...args) => {
    db.exec('BEGIN');
    try {
        const result = fn(...args);
        db.exec('COMMIT');
        return result;
    } catch (err) {
        db.exec('ROLLBACK');
        throw err;
    }
};

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

// Migration: add multilingual columns to `pages` on existing DBs (CREATE IF NOT
// EXISTS above does not alter an existing table). Each translation of a page
// shares a translation_group; a page's language defaults to English.
const pagesSql = (db.prepare(
    `SELECT sql FROM sqlite_master WHERE type='table' AND name='pages'`
).get() || {}).sql || '';
if (pagesSql && !/\blanguage\b/i.test(pagesSql)) {
    db.exec(`ALTER TABLE pages ADD COLUMN language TEXT NOT NULL DEFAULT 'en'`);
}
if (pagesSql && !/translation_group/i.test(pagesSql)) {
    db.exec(`ALTER TABLE pages ADD COLUMN translation_group TEXT`);
}
// Backfill: every existing/un-grouped page is its own translation group (by slug).
db.exec(`UPDATE pages SET translation_group = slug WHERE translation_group IS NULL OR translation_group = ''`);

// Migration: add `email_verified` to `users` on existing DBs. New self-service
// registrations start unverified (0); existing accounts are grandfathered to
// verified (1) so enabling REQUIRE_EMAIL_VERIFICATION never locks out current users.
const usersSql = (db.prepare(
    `SELECT sql FROM sqlite_master WHERE type='table' AND name='users'`
).get() || {}).sql || '';
if (usersSql && !/email_verified/i.test(usersSql)) {
    db.exec(`ALTER TABLE users ADD COLUMN email_verified INTEGER NOT NULL DEFAULT 0`);
    db.exec(`UPDATE users SET email_verified = 1`);
}

module.exports = db;
