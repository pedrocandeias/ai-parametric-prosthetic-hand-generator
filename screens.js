/**
 * screens.js — Screen navigation, selection page, and profile page.
 * Depends on: Auth (auth.js), loaded before app.js.
 */

const Screens = (() => {
    let _prevScreen = 'selection';

    function esc(str) {
        return String(str)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
    }

    function show(name) {
        document.querySelectorAll('.app-screen').forEach(s => s.classList.remove('active'));
        const screen = document.getElementById(`screen-${name}`);
        if (screen) screen.classList.add('active');
    }

    // ── Selection page ────────────────────────────────────────────────────────

    async function loadSelectionData() {
        await Promise.all([loadModels(), loadSavedConfigs()]);
        _renderRoleBanner();
    }

    function _renderRoleBanner() {
        const container = document.getElementById('selection-role-banner');
        if (!container) return;
        const user = Auth.getUser();
        if (!user || user.role === 'user') { container.innerHTML = ''; return; }

        const isAdmin = user.role === 'admin';
        const isTech  = user.role === 'tech';

        const fileEditIcon = `<svg width="20" height="20" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>`;
        const settingsIcon = `<svg width="20" height="20" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 010 2.83 2 2 0 01-2.83 0l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 01-4 0v-.09A1.65 1.65 0 009 19.4a1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 01-2.83-2.83l.06-.06A1.65 1.65 0 004.68 15a1.65 1.65 0 00-1.51-1H3a2 2 0 010-4h.09A1.65 1.65 0 004.6 9a1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 012.83-2.83l.06.06A1.65 1.65 0 009 4.68a1.65 1.65 0 001-1.51V3a2 2 0 014 0v.09a1.65 1.65 0 001 1.51 1.65 1.65 0 001.82-.33l.06-.06a2 2 0 012.83 2.83l-.06.06A1.65 1.65 0 0019.4 9a1.65 1.65 0 001.51 1H21a2 2 0 010 4h-.09a1.65 1.65 0 00-1.51 1z"/></svg>`;

        if (isAdmin) {
            container.innerHTML = `
                <div class="role-card purple">
                    <div class="role-card-content">
                        <div class="role-card-left">
                            <div class="role-card-icon purple">${settingsIcon}</div>
                            <div>
                                <div class="role-card-title">Admin Dashboard</div>
                                <div class="role-card-sub">Manage users, models and configurations</div>
                            </div>
                        </div>
                        <a href="admin.html" class="btn-primary btn-sm">Open Dashboard</a>
                    </div>
                </div>`;
        } else if (isTech) {
            container.innerHTML = `
                <div class="role-card green">
                    <div class="role-card-content">
                        <div class="role-card-left">
                            <div class="role-card-icon green">${fileEditIcon}</div>
                            <div>
                                <div class="role-card-title">Editor Dashboard</div>
                                <div class="role-card-sub">Review and edit user prosthetic profiles</div>
                            </div>
                        </div>
                        <a href="admin.html" class="btn-primary btn-sm">Open Dashboard</a>
                    </div>
                </div>`;
        }
    }

    async function loadModels() {
        const grid = document.getElementById('selection-models-grid');
        if (!grid) return;
        try {
            const res = await fetch('/models/models-config.json');
            const data = await res.json();
            const models = data.models || [];
            if (!models.length) {
                grid.innerHTML = '<p class="sel-empty">No models available.</p>';
                return;
            }
            grid.innerHTML = models.map((m, i) => {
                const stops = [
                    ['#94a3b8','#cbd5e1','#e2e8f0'],
                    ['#a1a1aa','#d4d4d8','#e4e4e7'],
                    ['#9ca3af','#d1d5db','#e5e7eb'],
                    ['#a8a29e','#d6d3d1','#e7e5e4'],
                ][i % 4];
                const bg = [
                    'linear-gradient(160deg,#f1f5f9 0%,#e2e8f0 100%)',
                    'linear-gradient(160deg,#f4f4f5 0%,#e4e4e7 100%)',
                    'linear-gradient(160deg,#f3f4f6 0%,#e5e7eb 100%)',
                    'linear-gradient(160deg,#f5f5f4 0%,#e7e5e4 100%)',
                ][i % 4];
                const gid = `mg${i}`;
                return `
                <div class="sel-model-card" data-model-id="${esc(m.id)}" role="button" tabindex="0" aria-label="Configure ${esc(m.name)}">
                    <div class="sel-model-thumb" style="background:${bg}">
                        <svg viewBox="0 0 200 200" fill="none" xmlns="http://www.w3.org/2000/svg">
                            <defs>
                                <linearGradient id="${gid}" x1="0%" y1="0%" x2="100%" y2="100%">
                                    <stop offset="0%" stop-color="${stops[0]}"/>
                                    <stop offset="50%" stop-color="${stops[1]}"/>
                                    <stop offset="100%" stop-color="${stops[2]}"/>
                                </linearGradient>
                            </defs>
                            <path d="M75 130 L75 168 C75 173 78 176 83 176 L117 176 C122 176 125 173 125 168 L125 130 Z" fill="url(#${gid})" opacity="0.9"/>
                            <path d="M65 138 L54 149 C50 153 50 159 54 163 L59 168 C63 172 69 172 73 168 L80 158 Z" fill="url(#${gid})"/>
                            <rect x="78" y="36" width="16" height="98" rx="8" fill="url(#${gid})"/>
                            <rect x="96" y="26" width="16" height="108" rx="8" fill="url(#${gid})"/>
                            <rect x="114" y="36" width="16" height="98" rx="8" fill="url(#${gid})"/>
                            <rect x="132" y="56" width="14" height="78" rx="7" fill="url(#${gid})"/>
                            <line x1="82" y1="140" x2="118" y2="140" stroke="white" stroke-width="2.5" opacity="0.5"/>
                            <line x1="82" y1="152" x2="118" y2="152" stroke="white" stroke-width="2.5" opacity="0.5"/>
                            <line x1="82" y1="164" x2="118" y2="164" stroke="white" stroke-width="2.5" opacity="0.5"/>
                        </svg>
                    </div>
                    <div class="sel-model-body">
                        <h3>
                            <svg width="13" height="13" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5" style="display:inline;vertical-align:middle;margin-right:5px;opacity:0.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>${esc(m.name)}
                        </h3>
                        <p>${esc((m.description || '').slice(0, 130))}${(m.description || '').length > 130 ? '…' : ''}</p>
                    </div>
                    <div class="sel-model-action">
                        <button class="btn-primary btn-block" tabindex="-1">Start New</button>
                    </div>
                </div>`;
            }).join('');
        } catch {
            grid.innerHTML = '<p class="sel-empty">Failed to load models.</p>';
        }
    }

    async function loadSavedConfigs() {
        const list = document.getElementById('selection-saved-list');
        if (!list) return;
        if (!Auth.isAuthenticated()) {
            list.innerHTML = '<p class="sel-empty">Sign in to see saved configurations.</p>';
            return;
        }
        try {
            const res = await Auth.fetchWithAuth('/api/configurations');
            if (!res.ok) throw new Error();
            const configs = await res.json();
            if (!configs.length) {
                list.innerHTML = '<p class="sel-empty">No saved configurations yet. Configure a model and save it to see it here.</p>';
                return;
            }
            list.innerHTML = configs.map(c => {
                const date = c.created_at
                    ? new Date(c.created_at).toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' })
                    : '';
                return `
                <div class="sel-config-card" data-config-id="${esc(c.id)}" role="button" tabindex="0" aria-label="Load ${esc(c.name)}">
                    <div class="sel-config-name">
                        <svg width="14" height="14" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2" style="flex-shrink:0;opacity:0.5">
                            <path d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3 3m0 0l-3-3m3 3V4"/>
                        </svg>
                        ${esc(c.name)}
                    </div>
                    <div class="sel-config-meta">
                        <span class="sel-badge">${esc(c.model_id || '')}</span>
                        ${date ? `<span>${esc(date)}</span>` : ''}
                    </div>
                    ${c.notes ? `<p style="font-size:0.8125rem;color:var(--text-muted)">${esc(c.notes.slice(0, 100))}</p>` : ''}
                    <div style="margin-top:4px">
                        <button class="btn-secondary btn-block btn-sm" tabindex="-1" style="font-size:0.8125rem">Load Profile</button>
                    </div>
                </div>`;
            }).join('');
        } catch {
            list.innerHTML = '<p class="sel-empty">Failed to load saved configurations.</p>';
        }
    }

    // ── Open customization for a model ───────────────────────────────────────

    async function openModel(modelId) {
        _prevScreen = 'selection';
        show('customization');
        const modelSelect = document.getElementById('model-select');
        if (modelSelect) modelSelect.value = modelId;
        const pe = window.parameterEditor;
        if (!pe) return;
        await pe.loadModel(modelId);
        _setCustomizationTitle(pe.currentModel?.name || modelId);
        pe.renderPreview();
    }

    function _setCustomizationTitle(name) {
        const title = document.getElementById('customization-title');
        if (title) title.textContent = name ? `Customize Your Prosthetic — Type: ${name}` : 'Customize Your Prosthetic';
    }

    async function openConfig(configId) {
        _prevScreen = 'selection';
        show('customization');
        const pe = window.parameterEditor;
        if (!pe) return;
        try {
            const res = await Auth.fetchWithAuth(`/api/configurations/${configId}`);
            const config = await res.json();
            if (!res.ok) throw new Error(config.error || 'Load failed');

            if (!pe.currentModel || pe.currentModel.id !== config.model_id) {
                const modelSelect = document.getElementById('model-select');
                if (modelSelect) modelSelect.value = config.model_id;
                await pe.loadModel(config.model_id);
            }

            pe.applySuggestions(config.parameters);
            _setCustomizationTitle(pe.currentModel?.name || config.model_id);

            const nameEl = document.getElementById('config-name');
            const notesEl = document.getElementById('config-notes');
            if (nameEl) nameEl.value = config.name;
            if (notesEl) notesEl.value = config.notes || '';
            pe._currentConfigId = config.id;
            pe.updateStatus(`Loaded: ${config.name}`, 'success');

            // Switch to saved tab then auto-render
            const savedTabBtn = document.querySelector('[data-tab="saved"]');
            if (savedTabBtn) savedTabBtn.click();
            pe.renderPreview();
        } catch (err) {
            if (window.parameterEditor) {
                window.parameterEditor.updateStatus('Error loading config: ' + err.message, 'error');
            }
        }
    }

    // ── Profile page ─────────────────────────────────────────────────────────

    function openProfile() {
        const user = Auth.getUser();
        if (user) {
            const usernameEl = document.getElementById('profile-username');
            const emailEl = document.getElementById('profile-email');
            const roleEl = document.getElementById('profile-role');
            if (usernameEl) usernameEl.value = user.username || '';
            if (emailEl) emailEl.value = user.email || '';
            if (roleEl) roleEl.value = user.role || '';
        }
        // Clear password fields and messages
        ['profile-current-pw','profile-new-pw','profile-confirm-pw'].forEach(id => {
            const el = document.getElementById(id);
            if (el) el.value = '';
        });
        const errEl = document.getElementById('profile-pw-error');
        const okEl = document.getElementById('profile-pw-success');
        if (errEl) { errEl.textContent = ''; errEl.classList.remove('active'); }
        if (okEl) { okEl.textContent = ''; okEl.classList.remove('active'); }

        _prevScreen = document.querySelector('.app-screen.active')?.id?.replace('screen-', '') || 'selection';
        show('profile');
    }

    function initProfileEvents() {
        document.getElementById('profile-save-pw-btn')?.addEventListener('click', async () => {
            const user = Auth.getUser();
            if (!user) return;
            const errEl = document.getElementById('profile-pw-error');
            const okEl = document.getElementById('profile-pw-success');
            if (errEl) { errEl.textContent = ''; errEl.classList.remove('active'); }
            if (okEl) { okEl.textContent = ''; okEl.classList.remove('active'); }

            const currentPw = document.getElementById('profile-current-pw')?.value || '';
            const newPw = document.getElementById('profile-new-pw')?.value || '';
            const confirmPw = document.getElementById('profile-confirm-pw')?.value || '';

            function showErr(msg) {
                if (errEl) { errEl.textContent = msg; errEl.classList.add('active'); }
            }

            if (!currentPw || !newPw || !confirmPw) return showErr('All fields are required.');
            if (newPw !== confirmPw) return showErr('New passwords do not match.');
            if (newPw.length < 8) return showErr('New password must be at least 8 characters.');

            const btn = document.getElementById('profile-save-pw-btn');
            if (btn) btn.disabled = true;
            try {
                const res = await Auth.fetchWithAuth(`/api/users/${user.id}/password`, {
                    method: 'PATCH',
                    body: JSON.stringify({ current_password: currentPw, new_password: newPw }),
                });
                const data = await res.json();
                if (!res.ok) throw new Error(data.error || 'Failed to update password');
                if (okEl) { okEl.textContent = 'Password updated successfully!'; okEl.classList.add('active'); }
                document.getElementById('profile-current-pw').value = '';
                document.getElementById('profile-new-pw').value = '';
                document.getElementById('profile-confirm-pw').value = '';
            } catch (err) {
                showErr(err.message);
            } finally {
                if (btn) btn.disabled = false;
            }
        });
    }

    // ── Initialise ────────────────────────────────────────────────────────────

    function init() {
        // Auth events → show/hide app shell
        window.addEventListener('auth:login', async () => {
            document.getElementById('app-shell')?.classList.add('active');
            show('selection');
            await loadSelectionData();
        });

        window.addEventListener('auth:logout', () => {
            document.getElementById('app-shell')?.classList.remove('active');
        });

        // ── Selection page: model cards
        document.getElementById('selection-models-grid')?.addEventListener('click', e => {
            const card = e.target.closest('[data-model-id]');
            if (card) openModel(card.dataset.modelId);
        });
        document.getElementById('selection-models-grid')?.addEventListener('keydown', e => {
            if (e.key === 'Enter') {
                const card = e.target.closest('[data-model-id]');
                if (card) openModel(card.dataset.modelId);
            }
        });

        // ── Selection page: saved config cards
        document.getElementById('selection-saved-list')?.addEventListener('click', e => {
            const card = e.target.closest('[data-config-id]');
            if (card) openConfig(card.dataset.configId);
        });
        document.getElementById('selection-saved-list')?.addEventListener('keydown', e => {
            if (e.key === 'Enter') {
                const card = e.target.closest('[data-config-id]');
                if (card) openConfig(card.dataset.configId);
            }
        });

        // ── Customization: back to selection
        document.getElementById('btn-back-to-selection')?.addEventListener('click', async () => {
            show('selection');
            await loadSelectionData();
        });

        // ── User menu: edit profile
        document.getElementById('user-menu-profile')?.addEventListener('click', e => {
            e.preventDefault();
            document.getElementById('user-menu-dropdown')?.classList.remove('active');
            openProfile();
        });

        // ── Profile: back button
        document.getElementById('btn-back-from-profile')?.addEventListener('click', () => {
            show(_prevScreen || 'selection');
        });

        initProfileEvents();
    }

    return { show, init, loadSelectionData };
})();

document.addEventListener('DOMContentLoaded', () => {
    Screens.init();
});
