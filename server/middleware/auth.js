'use strict';

const { verifyAccessToken } = require('../services/authService');

/**
 * requireAuth — verifies Bearer access token and attaches req.user.
 * Responds 401 if missing or invalid.
 */
function requireAuth(req, res, next) {
    const authHeader = req.headers['authorization'];
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Authentication required' });
    }

    const token = authHeader.slice(7);
    try {
        req.user = verifyAccessToken(token);
        next();
    } catch (err) {
        res.status(401).json({ error: 'Invalid or expired token' });
    }
}

/**
 * requireRole(role) — middleware factory.
 * Must be used after requireAuth.
 * Accepts a string role or an array of acceptable roles.
 */
function requireRole(role) {
    const allowed = Array.isArray(role) ? role : [role];
    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({ error: 'Authentication required' });
        }
        if (!allowed.includes(req.user.role)) {
            return res.status(403).json({ error: 'Insufficient permissions' });
        }
        next();
    };
}

module.exports = { requireAuth, requireRole };
