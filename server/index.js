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
const errorHandler = require('./middleware/errorHandler');

const app = express();
const PORT = process.env.PORT || 3000;
const ROOT = path.join(__dirname, '..');

// --- Security headers ---
app.use(helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            scriptSrc: ["'self'", "'unsafe-inline'", "'wasm-unsafe-eval'", "unpkg.com", "cdn.jsdelivr.net"],
            scriptSrcAttr: ["'unsafe-inline'"],
            styleSrc: ["'self'", "'unsafe-inline'"],
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
app.use(express.json({ limit: '1mb' }));
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

// --- API 404 (unknown API routes should return JSON, not the SPA) ---
app.use('/api', (req, res) => res.status(404).json({ error: 'API endpoint not found' }));

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
});

module.exports = app;
