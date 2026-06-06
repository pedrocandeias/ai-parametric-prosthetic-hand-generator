'use strict';

// eslint-disable-next-line no-unused-vars
function errorHandler(err, req, res, next) {
    const status = err.status || err.statusCode || 500;
    // Show the real message when the error has an explicit status (intentional/classified error).
    // Hide it only for unexpected crashes (no status set → defaults to 500).
    const message = (status < 500 || err.status != null) ? err.message : 'Internal server error';

    if (status >= 500) {
        console.error('[ERROR]', err);
    }

    res.status(status).json({ error: message });
}

module.exports = errorHandler;
