'use strict';

/**
 * emailService.js — Transactional email via SMTP (nodemailer).
 *
 * Mirrors the AI-key pattern: configuration is read from the environment and is
 * entirely optional. When SMTP is not configured the service degrades to a
 * no-op that logs a warning, so registration / password-reset flows keep
 * working (minus the email) and the server never crashes on a missing mailer.
 *
 * Required env to actually send:
 *   SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, MAIL_FROM
 * Optional:
 *   SMTP_SECURE=true|false   (default: true when port 465, else false)
 *   APP_BASE_URL             (used to build links in emails; falls back to the
 *                             request origin when available)
 */

const nodemailer = require('nodemailer');

const APP_NAME = 'Hand Fab';

let _transport;        // cached nodemailer transport (or null when unconfigured)
let _warnedOnce = false;

function isConfigured() {
    return Boolean(
        process.env.SMTP_HOST &&
        process.env.SMTP_PORT &&
        process.env.MAIL_FROM
    );
}

function getTransport() {
    if (_transport !== undefined) return _transport;

    if (!isConfigured()) {
        _transport = null;
        return _transport;
    }

    const port = parseInt(process.env.SMTP_PORT, 10);
    const secure = process.env.SMTP_SECURE
        ? process.env.SMTP_SECURE === 'true'
        : port === 465;

    _transport = nodemailer.createTransport({
        host: process.env.SMTP_HOST,
        port,
        secure,
        auth: (process.env.SMTP_USER || process.env.SMTP_PASS)
            ? { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS }
            : undefined,
    });
    return _transport;
}

/**
 * Resolve the public base URL for links in emails.
 * Prefers APP_BASE_URL; otherwise derives from the incoming request; finally
 * falls back to localhost for dev.
 */
function baseUrl(req) {
    if (process.env.APP_BASE_URL) {
        return process.env.APP_BASE_URL.replace(/\/+$/, '');
    }
    if (req) {
        const proto = req.headers['x-forwarded-proto'] || req.protocol || 'http';
        const host = req.headers['x-forwarded-host'] || req.get('host');
        if (host) return `${proto}://${host}`;
    }
    return `http://localhost:${process.env.PORT || 3000}`;
}

/**
 * Send an email. Never throws — returns { sent, reason }. When SMTP is not
 * configured this is a logged no-op so callers can fire-and-forget.
 */
async function sendMail({ to, subject, html, text }) {
    const transport = getTransport();
    if (!transport) {
        if (!_warnedOnce) {
            console.warn(
                '[emailService] SMTP not configured (SMTP_HOST/SMTP_PORT/MAIL_FROM) — ' +
                'emails are disabled. Set them in .env to enable delivery.'
            );
            _warnedOnce = true;
        }
        return { sent: false, reason: 'not_configured' };
    }

    try {
        await transport.sendMail({
            from: process.env.MAIL_FROM,
            to,
            subject,
            text,
            html,
        });
        return { sent: true };
    } catch (err) {
        // Delivery failure must not break the auth flow — log and report.
        console.error('[emailService] send failed:', err.message);
        return { sent: false, reason: 'send_error', error: err.message };
    }
}

// ── Minimal branded template (inline; no template engine needed) ────────────

function layout(title, bodyHtml) {
    return `<!DOCTYPE html><html><body style="margin:0;background:#f1f5f9;font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;">
  <div style="max-width:480px;margin:0 auto;padding:32px 16px;">
    <div style="background:#fff;border-radius:12px;padding:32px;box-shadow:0 1px 3px rgba(0,0,0,.08);">
      <h1 style="margin:0 0 4px;font-size:20px;color:#0f172a;">${APP_NAME}</h1>
      <h2 style="margin:0 0 16px;font-size:16px;font-weight:600;color:#334155;">${title}</h2>
      ${bodyHtml}
    </div>
    <p style="text-align:center;color:#94a3b8;font-size:12px;margin-top:16px;">${APP_NAME} — Custom Hand Prosthetic Configuration System</p>
  </div>
</body></html>`;
}

function button(href, label) {
    return `<p style="margin:24px 0;"><a href="${href}" style="display:inline-block;background:#7c3aed;color:#fff;text-decoration:none;padding:12px 24px;border-radius:8px;font-weight:600;">${label}</a></p>
  <p style="font-size:13px;color:#64748b;word-break:break-all;">Or paste this link into your browser:<br>${href}</p>`;
}

// ── Typed helpers ───────────────────────────────────────────────────────────

function sendPasswordReset(to, { username, resetUrl }) {
    const html = layout(
        'Reset your password',
        `<p style="color:#334155;">Hi ${username || 'there'}, we received a request to reset your ${APP_NAME} password. This link expires in 1 hour.</p>
         ${button(resetUrl, 'Reset password')}
         <p style="font-size:13px;color:#64748b;">If you didn't request this, you can safely ignore this email.</p>`
    );
    const text = `Reset your ${APP_NAME} password (expires in 1 hour):\n${resetUrl}\n\nIf you didn't request this, ignore this email.`;
    return sendMail({ to, subject: `Reset your ${APP_NAME} password`, html, text });
}

function sendVerification(to, { username, verifyUrl }) {
    const html = layout(
        'Confirm your email',
        `<p style="color:#334155;">Hi ${username || 'there'}, welcome to ${APP_NAME}. Please confirm your email address to finish setting up your account. This link expires in 24 hours.</p>
         ${button(verifyUrl, 'Confirm email')}`
    );
    const text = `Confirm your ${APP_NAME} email (expires in 24 hours):\n${verifyUrl}`;
    return sendMail({ to, subject: `Confirm your ${APP_NAME} email`, html, text });
}

function sendAccountCreated(to, { username, loginUrl }) {
    const html = layout(
        'Your account is ready',
        `<p style="color:#334155;">Hi ${username || 'there'}, an administrator has created a ${APP_NAME} account for you (username <strong>${username}</strong>). You can sign in with the password you were given.</p>
         ${button(loginUrl, 'Sign in')}`
    );
    const text = `An administrator created a ${APP_NAME} account for you (username ${username}). Sign in: ${loginUrl}`;
    return sendMail({ to, subject: `Your ${APP_NAME} account is ready`, html, text });
}

module.exports = {
    isConfigured,
    baseUrl,
    sendMail,
    sendPasswordReset,
    sendVerification,
    sendAccountCreated,
};
