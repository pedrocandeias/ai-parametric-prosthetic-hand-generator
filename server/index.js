'use strict';

require('dotenv').config();

const express = require('express');
const path = require('path');
const morgan = require('morgan');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const cookieParser = require('cookie-parser');

const setupRoutes = require('./routes/setupRoutes');
const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const configRoutes = require('./routes/configRoutes');
const aiRoutes = require('./routes/aiRoutes');
const anthropometricRoutes = require('./routes/anthropometricRoutes');
const contentRoutes = require('./routes/contentRoutes');
const emailService = require('./services/emailService');
const errorHandler = require('./middleware/errorHandler');

const app = express();
const PORT = process.env.PORT || 3000;
const ROOT = path.join(__dirname, '..');

// Behind a reverse proxy (cPanel/Passenger → Apache). Trust the first proxy so
// req.ip / X-Forwarded-For are correct and express-rate-limit doesn't error
// (ERR_ERL_UNEXPECTED_X_FORWARDED_FOR).
app.set('trust proxy', 1);

// --- Cross-Origin Isolation (required for SharedArrayBuffer / OpenSCAD WASM) ---
app.use((req, res, next) => {
    res.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
    res.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');
    next();
});

// --- Security headers ---
app.use(helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            scriptSrc: ["'self'", "'unsafe-inline'", "'wasm-unsafe-eval'", "unpkg.com", "cdn.jsdelivr.net"],
            scriptSrcAttr: ["'unsafe-inline'"],
            styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com"],
            fontSrc: ["'self'", "https://fonts.gstatic.com"],
            workerSrc: ["'self'", "blob:"],
            connectSrc: ["'self'", "blob:"],
            imgSrc: ["'self'", "data:", "blob:"],
            objectSrc: ["'none'"],
        }
    }
}));

// --- Logging ---
app.use(morgan('dev'));

// --- Body parsing + cookies ---
app.use(express.json({ limit: '8mb' })); // headroom for admin CSV bulk import (multi_population_hand.csv ~1.1 MB)
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());

// --- Block sensitive files before static serving ---
app.get('/.env', (req, res) => res.status(404).end());
app.get('/config.json', (req, res) => res.status(404).end());
app.get('/data/*', (req, res) => res.status(404).end());

// --- Global rate limiter (generous baseline) ---
app.use(rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 500,
    message: { error: 'Too many requests, please try again later' },
    standardHeaders: true,
    legacyHeaders: false,
}));

// --- API routes ---
app.use('/api/setup', setupRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/configurations', configRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/anthropometric', anthropometricRoutes);
app.use('/api/content', contentRoutes);

// --- API 404 (unknown API routes should return JSON, not the SPA) ---
app.use('/api', (req, res) => res.status(404).json({ error: 'API endpoint not found' }));

// --- Clean URLs for static pages (drop the .html, matching the SPA URL style) ---
app.get('/admin', (req, res) => res.sendFile(path.join(ROOT, 'admin.html')));
// Public content-page viewer: /pages/<slug> → a viewer template that fetches the page
app.get('/pages/:slug', (req, res) => res.sendFile(path.join(ROOT, 'page.html')));

// --- Static files (public-facing app) ---
app.use(express.static(ROOT, {
    // Don't serve sensitive files
    index: 'index.html',
}));

// --- SPA fallback (only for non-API, non-file paths) ---
app.get('*', (req, res, next) => {
    if (req.path.startsWith('/api/')) return next();
    res.sendFile(path.join(ROOT, 'index.html'));
});

// --- Central error handler ---
app.use(errorHandler);

app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`Email (SMTP): ${emailService.isConfigured() ? 'enabled' : 'disabled (no SMTP_* configured)'}`);
});

module.exports = app;
