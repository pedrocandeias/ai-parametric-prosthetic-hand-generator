'use strict';

const crypto = require('crypto');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const db = require('../db');

const BCRYPT_ROUNDS = 12;
const ACCESS_TOKEN_TTL = '15m';
const REFRESH_TOKEN_TTL_DAYS = 7;

function getJwtSecret() {
    const secret = process.env.JWT_SECRET;
    if (!secret || secret.length < 32) {
        throw new Error('JWT_SECRET env var must be set to at least 32 characters');
    }
    return secret;
}

function hashToken(token) {
    return crypto.createHash('sha256').update(token).digest('hex');
}

// ── Passwords ──────────────────────────────────────────────────────────────

async function hashPassword(plaintext) {
    return bcrypt.hash(plaintext, BCRYPT_ROUNDS);
}

async function verifyPassword(plaintext, hash) {
    return bcrypt.compare(plaintext, hash);
}

// ── Access tokens (JWT, in-memory only) ───────────────────────────────────

function signAccessToken(user) {
    return jwt.sign(
        { sub: user.id, username: user.username, role: user.role },
        getJwtSecret(),
        { algorithm: 'HS256', expiresIn: ACCESS_TOKEN_TTL }
    );
}

function verifyAccessToken(token) {
    return jwt.verify(token, getJwtSecret(), { algorithms: ['HS256'] });
}

// ── Refresh tokens (opaque, stored as SHA-256 hash in DB) ─────────────────

function issueRefreshToken(userId) {
    const token = uuidv4();
    const tokenHash = hashToken(token);
    const expiresAt = new Date(Date.now() + REFRESH_TOKEN_TTL_DAYS * 86400 * 1000)
        .toISOString()
        .replace('T', ' ')
        .substring(0, 19);

    db.prepare(
        `INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
         VALUES (?, ?, ?)`
    ).run(userId, tokenHash, expiresAt);

    return token;
}

function consumeRefreshToken(token) {
    // Returns user row or null; rotates (revokes old, caller issues new)
    const tokenHash = hashToken(token);
    const row = db.prepare(
        `SELECT rt.id, rt.user_id, rt.expires_at, rt.revoked,
                u.id AS uid, u.username, u.email, u.role, u.is_active
         FROM refresh_tokens rt
         JOIN users u ON u.id = rt.user_id
         WHERE rt.token_hash = ?`
    ).get(tokenHash);

    if (!row) return null;
    if (row.revoked) return null;
    if (new Date(row.expires_at) < new Date()) return null;
    if (!row.is_active) return null;

    // Revoke used token (rotation)
    db.prepare(`UPDATE refresh_tokens SET revoked = 1 WHERE id = ?`).run(row.id);

    return {
        id: row.uid,
        username: row.username,
        email: row.email,
        role: row.role,
    };
}

function revokeRefreshToken(token) {
    const tokenHash = hashToken(token);
    db.prepare(`UPDATE refresh_tokens SET revoked = 1 WHERE token_hash = ?`).run(tokenHash);
}

function pruneExpiredTokens() {
    db.prepare(
        `DELETE FROM refresh_tokens WHERE expires_at < datetime('now') OR revoked = 1`
    ).run();
    db.prepare(
        `DELETE FROM password_reset_tokens WHERE expires_at < datetime('now') OR used = 1`
    ).run();
}

// ── Password reset tokens ─────────────────────────────────────────────────

const RESET_TOKEN_TTL_HOURS = 1;

function issueResetToken(userId) {
    // Invalidate any existing unused tokens for this user
    db.prepare(
        `UPDATE password_reset_tokens SET used = 1 WHERE user_id = ? AND used = 0`
    ).run(userId);

    const token = uuidv4();
    const tokenHash = hashToken(token);
    const expiresAt = new Date(Date.now() + RESET_TOKEN_TTL_HOURS * 3600 * 1000)
        .toISOString()
        .replace('T', ' ')
        .substring(0, 19);

    db.prepare(
        `INSERT INTO password_reset_tokens (user_id, token_hash, expires_at) VALUES (?, ?, ?)`
    ).run(userId, tokenHash, expiresAt);

    return token;
}

function consumeResetToken(plainToken, newPasswordHash) {
    const tokenHash = hashToken(plainToken);
    const row = db.prepare(
        `SELECT prt.id, prt.user_id, prt.expires_at, prt.used,
                u.id AS uid, u.username, u.email, u.role, u.is_active
         FROM password_reset_tokens prt
         JOIN users u ON u.id = prt.user_id
         WHERE prt.token_hash = ?`
    ).get(tokenHash);

    if (!row) return null;
    if (row.used) return null;
    if (new Date(row.expires_at) < new Date()) return null;
    if (!row.is_active) return null;

    db.transaction(() => {
        db.prepare(`UPDATE password_reset_tokens SET used = 1 WHERE id = ?`).run(row.id);
        db.prepare(
            `UPDATE users SET password_hash = ?, updated_at = datetime('now') WHERE id = ?`
        ).run(newPasswordHash, row.user_id);
        db.prepare(`UPDATE refresh_tokens SET revoked = 1 WHERE user_id = ?`).run(row.user_id);
    })();

    return { id: row.uid, username: row.username, email: row.email, role: row.role };
}

module.exports = {
    hashPassword,
    verifyPassword,
    signAccessToken,
    verifyAccessToken,
    issueRefreshToken,
    consumeRefreshToken,
    revokeRefreshToken,
    pruneExpiredTokens,
    issueResetToken,
    consumeResetToken,
};
