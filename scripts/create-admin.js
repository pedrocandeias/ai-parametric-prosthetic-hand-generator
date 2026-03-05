#!/usr/bin/env node
/**
 * CLI fallback for creating the first admin user.
 * Usage: node scripts/create-admin.js <username> <email> <password>
 */

require('dotenv').config();

const db = require('../server/db');
const { hashPassword } = require('../server/services/authService');

async function main() {
    const [username, email, password] = process.argv.slice(2);

    if (!username || !email || !password) {
        console.error('Usage: node scripts/create-admin.js <username> <email> <password>');
        process.exit(1);
    }

    const existing = db.prepare('SELECT COUNT(*) AS cnt FROM users').get();
    if (existing.cnt > 0) {
        console.error('Users already exist. Use the admin panel to manage users.');
        process.exit(1);
    }

    const passwordHash = await hashPassword(password);
    const info = db.prepare(
        `INSERT INTO users (username, email, password_hash, role) VALUES (?, ?, ?, 'admin')`
    ).run(username, email, passwordHash);

    console.log(`Admin user created: ${username} (id=${info.lastInsertRowid})`);
    process.exit(0);
}

main().catch(err => {
    console.error('Error:', err.message);
    process.exit(1);
});
