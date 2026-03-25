'use strict';

const express = require('express');
const rateLimit = require('express-rate-limit');
const { z } = require('zod');
const db = require('../db');
const {
    hashPassword,
    verifyPassword,
    signAccessToken,
    issueRefreshToken,
    consumeRefreshToken,
    revokeRefreshToken,
    issueResetToken,
    consumeResetToken,
} = require('../services/authService');
const { requireAuth, requireRole } = require('../middleware/auth');

const router = express.Router();

const REFRESH_COOKIE = 'refresh_token';
const COOKIE_OPTIONS = {
    httpOnly: true,
    sameSite: 'strict',
    secure: process.env.NODE_ENV === 'production',
    maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days in ms
    path: '/api/auth',
};

// --- Rate limiters ---
const loginLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 5,
    message: { error: 'Too many login attempts, try again in 15 minutes' },
    standardHeaders: true,
    legacyHeaders: false,
});

const registerLimiter = rateLimit({
    windowMs: 60 * 60 * 1000,
    max: 3,
    message: { error: 'Too many registrations from this IP' },
    standardHeaders: true,
    legacyHeaders: false,
});

const resetLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 10,
    message: { error: 'Too many reset attempts, try again later' },
    standardHeaders: true,
    legacyHeaders: false,
});

// --- Validation schemas ---
const LoginSchema = z.object({
    login: z.string().min(1), // username or email
    password: z.string().min(1),
});

const RegisterSchema = z.object({
    username: z.string().min(2).max(50).regex(/^\w+$/, 'Username may only contain letters, digits, and underscores'),
    email: z.string().email(),
    password: z.string().min(8).max(128),
});

const ResetRequestSchema = z.object({
    user_id: z.number().int().positive(),
});

const ResetRedeemSchema = z.object({
    token: z.string().min(1),
    new_password: z.string().min(8).max(128),
});

// --- Helpers ---
function setRefreshCookie(res, token) {
    res.cookie(REFRESH_COOKIE, token, COOKIE_OPTIONS);
}

function clearRefreshCookie(res) {
    res.clearCookie(REFRESH_COOKIE, { ...COOKIE_OPTIONS, maxAge: 0 });
}

// POST /api/auth/login
router.post('/login', loginLimiter, async (req, res, next) => {
    try {
        const result = LoginSchema.safeParse(req.body);
        if (!result.success) {
            return res.status(400).json({ error: result.error.errors[0].message });
        }

        const { login, password } = result.data;

        const user = db.prepare(
            `SELECT * FROM users WHERE (username = ? OR email = ?) AND is_active = 1`
        ).get(login, login);

        if (!user) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        const valid = await verifyPassword(password, user.password_hash);
        if (!valid) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        const accessToken = signAccessToken(user);
        const refreshToken = issueRefreshToken(user.id);

        setRefreshCookie(res, refreshToken);
        res.json({
            accessToken,
            user: { id: user.id, username: user.username, email: user.email, role: user.role },
        });
    } catch (err) {
        next(err);
    }
});

// POST /api/auth/register — self-service, creates 'user' role
router.post('/register', registerLimiter, async (req, res, next) => {
    try {
        const result = RegisterSchema.safeParse(req.body);
        if (!result.success) {
            return res.status(400).json({ error: result.error.errors[0].message });
        }

        const { username, email, password } = result.data;

        // Check uniqueness
        const existing = db.prepare(
            `SELECT id FROM users WHERE username = ? OR email = ?`
        ).get(username, email);
        if (existing) {
            return res.status(409).json({ error: 'Username or email already taken' });
        }

        const passwordHash = await hashPassword(password);
        const stmt = db.prepare(
            `INSERT INTO users (username, email, password_hash, role) VALUES (?, ?, ?, 'user')`
        );
        const info = stmt.run(username, email, passwordHash);

        const user = { id: info.lastInsertRowid, username, email, role: 'user' };
        const accessToken = signAccessToken(user);
        const refreshToken = issueRefreshToken(user.id);

        setRefreshCookie(res, refreshToken);
        res.status(201).json({ accessToken, user });
    } catch (err) {
        next(err);
    }
});

// POST /api/auth/logout
router.post('/logout', requireAuth, (req, res) => {
    const token = req.cookies?.[REFRESH_COOKIE];
    if (token) revokeRefreshToken(token);
    clearRefreshCookie(res);
    res.json({ ok: true });
});

// POST /api/auth/refresh — uses HttpOnly cookie
router.post('/refresh', (req, res, next) => {
    try {
        const token = req.cookies?.[REFRESH_COOKIE];
        if (!token) {
            return res.status(401).json({ error: 'No refresh token' });
        }

        const user = consumeRefreshToken(token);
        if (!user) {
            clearRefreshCookie(res);
            return res.status(401).json({ error: 'Invalid or expired refresh token' });
        }

        const accessToken = signAccessToken(user);
        const newRefreshToken = issueRefreshToken(user.id);

        setRefreshCookie(res, newRefreshToken);
        res.json({ accessToken, user });
    } catch (err) {
        next(err);
    }
});

// POST /api/auth/reset-request — admin only, generates a reset token for a user
router.post('/reset-request', requireAuth, requireRole('admin'), async (req, res, next) => {
    try {
        const result = ResetRequestSchema.safeParse(req.body);
        if (!result.success) {
            return res.status(400).json({ error: result.error.errors[0].message });
        }

        const { user_id } = result.data;
        const user = db.prepare(
            `SELECT id FROM users WHERE id = ? AND is_active = 1`
        ).get(user_id);
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        const token = issueResetToken(user_id);
        res.json({ token, expires_in: '1 hour' });
    } catch (err) {
        next(err);
    }
});

// POST /api/auth/reset — public, redeems a reset token and sets a new password
router.post('/reset', resetLimiter, async (req, res, next) => {
    try {
        const result = ResetRedeemSchema.safeParse(req.body);
        if (!result.success) {
            return res.status(400).json({ error: result.error.errors[0].message });
        }

        const { token, new_password } = result.data;
        const newPasswordHash = await hashPassword(new_password);
        const user = consumeResetToken(token, newPasswordHash);

        if (!user) {
            return res.status(400).json({ error: 'Invalid or expired reset token' });
        }

        const accessToken = signAccessToken(user);
        const refreshToken = issueRefreshToken(user.id);

        setRefreshCookie(res, refreshToken);
        res.json({ accessToken, user });
    } catch (err) {
        next(err);
    }
});

// GET /api/auth/me
router.get('/me', requireAuth, (req, res) => {
    const user = db.prepare(
        `SELECT id, username, email, role FROM users WHERE id = ? AND is_active = 1`
    ).get(req.user.sub);

    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json(user);
});

module.exports = router;
