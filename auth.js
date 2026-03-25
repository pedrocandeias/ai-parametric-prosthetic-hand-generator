/**
 * auth.js — Frontend authentication module.
 * Access token is kept in JS memory only (never localStorage/sessionStorage).
 * Refresh token lives in an HttpOnly cookie managed server-side.
 */

const Auth = (() => {
    let _accessToken = null;
    let _user = null;
    let _refreshTimer = null;

    // ── Token management ──────────────────────────────────────────────────

    function setSession(accessToken, user) {
        _accessToken = accessToken;
        _user = user;
        scheduleRefresh(accessToken);
        window.dispatchEvent(new CustomEvent('auth:login', { detail: user }));
    }

    function clearSession() {
        _accessToken = null;
        _user = null;
        if (_refreshTimer) clearTimeout(_refreshTimer);
        _refreshTimer = null;
        window.dispatchEvent(new CustomEvent('auth:logout'));
    }

    function scheduleRefresh(token) {
        if (_refreshTimer) clearTimeout(_refreshTimer);
        try {
            // Decode expiry from JWT payload (no verification needed client-side)
            const payload = JSON.parse(atob(token.split('.')[1]));
            const expiresInMs = (payload.exp * 1000) - Date.now();
            // Refresh 60 seconds before expiry, minimum 5s
            const delay = Math.max(expiresInMs - 60_000, 5_000);
            _refreshTimer = setTimeout(refresh, delay);
        } catch {
            // Fallback: refresh every 14 minutes
            _refreshTimer = setTimeout(refresh, 14 * 60 * 1000);
        }
    }

    // Parse JSON response; surface a clean error if the body is not JSON
    async function safeJson(res) {
        try {
            return await res.json();
        } catch {
            throw new Error('Server returned an unexpected response. Is the server running?');
        }
    }

    // ── Public API ─────────────────────────────────────────────────────────

    async function fetchWithAuth(url, options = {}) {
        if (!_accessToken) {
            throw Object.assign(new Error('Not authenticated'), { status: 401 });
        }

        const headers = { ...(options.headers || {}), Authorization: `Bearer ${_accessToken}` };
        if (options.body) headers['Content-Type'] = 'application/json';

        const res = await fetch(url, {
            ...options,
            headers,
            credentials: 'same-origin',
        });

        // If 401, attempt one silent refresh then retry
        if (res.status === 401) {
            const refreshed = await refresh();
            if (!refreshed) {
                clearSession();
                showLoginModal();
                throw Object.assign(new Error('Session expired'), { status: 401 });
            }
            return fetchWithAuth(url, options);
        }

        return res;
    }

    async function login(login, password) {
        const res = await fetch('/api/auth/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            credentials: 'same-origin',
            body: JSON.stringify({ login, password }),
        });

        const data = await safeJson(res);
        if (!res.ok) throw new Error(data.error || 'Login failed');

        setSession(data.accessToken, data.user);
        return data.user;
    }

    async function register(username, email, password) {
        const res = await fetch('/api/auth/register', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            credentials: 'same-origin',
            body: JSON.stringify({ username, email, password }),
        });

        const data = await safeJson(res);
        if (!res.ok) throw new Error(data.error || 'Registration failed');

        setSession(data.accessToken, data.user);
        return data.user;
    }

    async function resetPassword(token, newPassword) {
        const res = await fetch('/api/auth/reset', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            credentials: 'same-origin',
            body: JSON.stringify({ token, new_password: newPassword }),
        });
        const data = await safeJson(res);
        if (!res.ok) throw new Error(data.error || 'Reset failed');
        setSession(data.accessToken, data.user);
        return data.user;
    }

    async function setupAdmin(username, email, password) {
        const res = await fetch('/api/setup/admin', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, email, password }),
        });

        const data = await safeJson(res);
        if (!res.ok) throw new Error(data.error || 'Setup failed');

        // Auto-login after setup
        return login(username, password);
    }

    async function logout() {
        try {
            if (_accessToken) {
                await fetch('/api/auth/logout', {
                    method: 'POST',
                    headers: { Authorization: `Bearer ${_accessToken}` },
                    credentials: 'same-origin',
                });
            }
        } catch { /* ignore network errors on logout */ }
        clearSession();
        showLoginModal();
    }

    async function refresh() {
        try {
            const res = await fetch('/api/auth/refresh', {
                method: 'POST',
                credentials: 'same-origin',
            });
            if (!res.ok) return false;
            const data = await res.json();
            setSession(data.accessToken, data.user);
            return true;
        } catch {
            return false;
        }
    }

    // Try to restore session silently on page load via cookie
    async function tryRestoreSession() {
        const ok = await refresh();
        return ok;
    }

    function getUser() { return _user; }
    function getToken() { return _accessToken; }
    function isAuthenticated() { return !!_accessToken; }

    return {
        login,
        register,
        logout,
        refresh,
        tryRestoreSession,
        fetchWithAuth,
        setupAdmin,
        resetPassword,
        getUser,
        getToken,
        isAuthenticated,
    };
})();

// ── Login Modal UI ──────────────────────────────────────────────────────────

function showLoginModal(view = 'login') {
    const modal = document.getElementById('login-modal');
    if (!modal) return;
    modal.style.display = 'flex';
    switchLoginView(view);
}

function hideLoginModal() {
    const modal = document.getElementById('login-modal');
    if (modal) modal.style.display = 'none';
}

function switchLoginView(view) {
    document.querySelectorAll('.login-view').forEach(el => el.style.display = 'none');
    const target = document.getElementById(`login-view-${view}`);
    if (target) target.style.display = 'block';
}

function showAuthError(viewId, msg) {
    const el = document.getElementById(`${viewId}-error`);
    if (el) { el.textContent = msg; el.style.display = 'block'; }
}

function clearAuthErrors() {
    document.querySelectorAll('.auth-error').forEach(el => {
        el.textContent = '';
        el.style.display = 'none';
    });
}

function updateUserMenu(user) {
    const menu = document.getElementById('user-menu');
    const loginBtn = document.getElementById('login-btn');
    if (!menu) return;

    if (user) {
        menu.style.display = 'flex';
        if (loginBtn) loginBtn.style.display = 'none';
        const name = document.getElementById('user-menu-name');
        if (name) name.textContent = user.username;

        const adminLink = document.getElementById('user-menu-admin');
        if (adminLink) adminLink.style.display = user.role === 'admin' ? 'block' : 'none';
    } else {
        menu.style.display = 'none';
        if (loginBtn) loginBtn.style.display = 'inline-block';
    }
}

// ── Boot ────────────────────────────────────────────────────────────────────

document.addEventListener('DOMContentLoaded', async () => {
    // Wire up login modal form events
    setupLoginModalEvents();

    // Listen for auth events to update header UI
    window.addEventListener('auth:login', (e) => updateUserMenu(e.detail));
    window.addEventListener('auth:logout', () => updateUserMenu(null));

    // Check if first-run setup is needed
    try {
        const res = await fetch('/api/setup/status');
        const { needsSetup } = await res.json();
        if (needsSetup) {
            showLoginModal('setup');
            return;
        }
    } catch { /* ignore */ }

    // Try silent session restore (via refresh cookie)
    const restored = await Auth.tryRestoreSession();
    if (!restored) {
        showLoginModal('login');
    }
});

function setupLoginModalEvents() {
    // ── Login form ──
    const loginForm = document.getElementById('login-form');
    if (loginForm) {
        loginForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            clearAuthErrors();
            const login = document.getElementById('login-username').value.trim();
            const password = document.getElementById('login-password').value;
            const btn = loginForm.querySelector('button[type=submit]');
            btn.disabled = true;
            try {
                await Auth.login(login, password);
                hideLoginModal();
            } catch (err) {
                showAuthError('login', err.message);
            } finally {
                btn.disabled = false;
            }
        });
    }

    // ── Register form ──
    const registerForm = document.getElementById('register-form');
    if (registerForm) {
        registerForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            clearAuthErrors();
            const username = document.getElementById('register-username').value.trim();
            const email = document.getElementById('register-email').value.trim();
            const password = document.getElementById('register-password').value;
            const btn = registerForm.querySelector('button[type=submit]');
            btn.disabled = true;
            try {
                await Auth.register(username, email, password);
                hideLoginModal();
            } catch (err) {
                showAuthError('register', err.message);
            } finally {
                btn.disabled = false;
            }
        });
    }

    // ── Setup form ──
    const setupForm = document.getElementById('setup-form');
    if (setupForm) {
        setupForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            clearAuthErrors();
            const username = document.getElementById('setup-username').value.trim();
            const email = document.getElementById('setup-email').value.trim();
            const password = document.getElementById('setup-password').value;
            const btn = setupForm.querySelector('button[type=submit]');
            btn.disabled = true;
            try {
                await Auth.setupAdmin(username, email, password);
                hideLoginModal();
            } catch (err) {
                showAuthError('setup', err.message);
            } finally {
                btn.disabled = false;
            }
        });
    }

    // ── Reset form ──
    const resetForm = document.getElementById('reset-form');
    if (resetForm) {
        resetForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            clearAuthErrors();
            const token = document.getElementById('reset-token-input').value.trim();
            const newPassword = document.getElementById('reset-new-password').value;
            const btn = resetForm.querySelector('button[type=submit]');
            btn.disabled = true;
            try {
                await Auth.resetPassword(token, newPassword);
                hideLoginModal();
            } catch (err) {
                showAuthError('reset', err.message);
            } finally {
                btn.disabled = false;
            }
        });
    }

    // ── View switchers ──
    document.getElementById('go-register')?.addEventListener('click', (e) => {
        e.preventDefault(); clearAuthErrors(); switchLoginView('register');
    });
    document.getElementById('go-login')?.addEventListener('click', (e) => {
        e.preventDefault(); clearAuthErrors(); switchLoginView('login');
    });
    document.getElementById('go-login-from-setup')?.addEventListener('click', (e) => {
        e.preventDefault(); clearAuthErrors(); switchLoginView('login');
    });
    document.getElementById('go-reset')?.addEventListener('click', (e) => {
        e.preventDefault(); clearAuthErrors(); switchLoginView('reset');
    });
    document.getElementById('go-login-from-reset')?.addEventListener('click', (e) => {
        e.preventDefault(); clearAuthErrors(); switchLoginView('login');
    });

    // ── Logout ──
    document.getElementById('logout-btn')?.addEventListener('click', async (e) => {
        e.preventDefault();
        await Auth.logout();
    });

    // ── Login button in header ──
    document.getElementById('login-btn')?.addEventListener('click', () => {
        showLoginModal('login');
    });

    // ── Close modal backdrop click ──
    document.getElementById('login-modal')?.addEventListener('click', (e) => {
        // Only close if clicking the backdrop, not modal content
        if (e.target === e.currentTarget) {
            // Don't close — require explicit login
        }
    });

    // ── Dropdown toggle ──
    document.getElementById('user-menu-toggle')?.addEventListener('click', () => {
        const dropdown = document.getElementById('user-menu-dropdown');
        if (dropdown) dropdown.style.display = dropdown.style.display === 'block' ? 'none' : 'block';
    });

    // Close dropdown on outside click
    document.addEventListener('click', (e) => {
        const menu = document.getElementById('user-menu');
        if (menu && !menu.contains(e.target)) {
            const dd = document.getElementById('user-menu-dropdown');
            if (dd) dd.style.display = 'none';
        }
    });
}
