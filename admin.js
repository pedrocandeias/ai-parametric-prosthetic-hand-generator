'use strict';

// admin.js — Admin panel logic
// Depends on auth.js (Auth global + login modal helpers)

let allUsers = [];

// ── Utilities ─────────────────────────────────────────────────────────────

function toast(msg, type = 'success') {
    const el = document.getElementById('toast');
    el.textContent = msg;
    el.className = type;
    el.style.display = 'block';
    clearTimeout(el._timer);
    el._timer = setTimeout(() => { el.style.display = 'none'; }, 3000);
}

function roleBadge(role) {
    const label = t('admin.role' + role.charAt(0).toUpperCase() + role.slice(1));
    return `<span class="badge badge-${role}">${label}</span>`;
}

function statusBadge(isActive) {
    return isActive
        ? `<span class="badge badge-active">${t('admin.active')}</span>`
        : `<span class="badge badge-inactive">${t('admin.inactive')}</span>`;
}

function fmtDate(s) {
    if (!s) return '—';
    return s.replace('T', ' ').substring(0, 10);
}

// ── Data loaders ──────────────────────────────────────────────────────────

async function loadUsers() {
    const res = await Auth.fetchWithAuth('/api/users');
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || 'Failed to load users');
    allUsers = data;
    renderUsersTable(data);
    renderAssignmentsTab(data);
}

function renderUsersTable(users) {
    const tbody = document.getElementById('users-tbody');
    if (!tbody) return;
    tbody.innerHTML = '';

    users.forEach(u => {
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td>${u.id}</td>
            <td>${escHtml(u.username)}</td>
            <td>${escHtml(u.email)}</td>
            <td>${roleBadge(u.role)}</td>
            <td>${statusBadge(u.is_active)}</td>
            <td>${fmtDate(u.created_at)}</td>
            <td>
                <div class="action-cell">
                    <button class="btn-primary btn-edit" data-id="${u.id}">${t('admin.edit')}</button>
                    <button class="btn-warning btn-change-role" data-id="${u.id}" data-role="${u.role}">${t('admin.changeRole')}</button>
                    <button class="btn-secondary btn-reset-token" data-id="${u.id}">${t('admin.resetToken')}</button>
                    ${u.is_active
                        ? `<button class="btn-secondary btn-suspend" data-id="${u.id}">${t('admin.suspend')}</button>`
                        : `<button class="btn-success btn-activate" data-id="${u.id}">${t('admin.activate')}</button>`}
                </div>
            </td>
        `;
        tbody.appendChild(tr);
    });

    // Wire action buttons
    tbody.querySelectorAll('.btn-edit').forEach(btn => {
        btn.addEventListener('click', () => openEditModal(Number(btn.dataset.id)));
    });
    tbody.querySelectorAll('.btn-change-role').forEach(btn => {
        btn.addEventListener('click', () => changeRole(Number(btn.dataset.id), btn.dataset.role));
    });
    tbody.querySelectorAll('.btn-reset-token').forEach(btn => {
        btn.addEventListener('click', () => generateResetToken(Number(btn.dataset.id)));
    });
    tbody.querySelectorAll('.btn-suspend').forEach(btn => {
        btn.addEventListener('click', () => setActive(Number(btn.dataset.id), false));
    });
    tbody.querySelectorAll('.btn-activate').forEach(btn => {
        btn.addEventListener('click', () => setActive(Number(btn.dataset.id), true));
    });
}

// ── Reset token modal ──────────────────────────────────────────────────────

async function generateResetToken(userId) {
    const modal = document.getElementById('reset-token-modal');
    const display = document.getElementById('reset-token-display');
    const errEl = document.getElementById('reset-token-error');
    errEl.style.display = 'none';
    display.textContent = 'Generating…';
    modal.style.display = 'flex';

    try {
        const res = await Auth.fetchWithAuth('/api/auth/reset-request', {
            method: 'POST',
            body: JSON.stringify({ user_id: userId }),
        });
        const data = await res.json();
        if (!res.ok) throw new Error(data.error || 'Failed to generate token');
        display.textContent = data.token;
    } catch (err) {
        display.textContent = '';
        errEl.textContent = err.message;
        errEl.style.display = 'block';
    }
}

function setupResetTokenModal() {
    document.getElementById('close-reset-token-btn')?.addEventListener('click', () => {
        document.getElementById('reset-token-modal').style.display = 'none';
        document.getElementById('reset-token-display').textContent = '';
    });
    document.getElementById('copy-reset-token-btn')?.addEventListener('click', () => {
        const text = document.getElementById('reset-token-display').textContent;
        if (text) navigator.clipboard.writeText(text).then(() => toast('Token copied'));
    });
    document.getElementById('reset-token-modal')?.addEventListener('click', (e) => {
        if (e.target === e.currentTarget) {
            document.getElementById('reset-token-modal').style.display = 'none';
            document.getElementById('reset-token-display').textContent = '';
        }
    });
}

// ── Tech Assignments ──────────────────────────────────────────────────────

function renderAssignmentsTab(users) {
    const tbody = document.getElementById('assignments-tbody');
    if (!tbody) return;

    const techs = users.filter(u => u.role === 'tech' && u.is_active);
    const regularUsers = users.filter(u => u.role === 'user' && u.is_active);

    tbody.innerHTML = '';

    if (techs.length === 0) {
        tbody.innerHTML = `<tr><td colspan="3" style="color:#888;padding:1.5rem">${t('admin.noTechs')}</td></tr>`;
        return;
    }

    techs.forEach(tech => {
        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td style="font-weight:600">${escHtml(tech.username)}</td>
            <td id="patients-${tech.id}">Loading…</td>
            <td>
                <div style="display:flex;gap:0.5rem;align-items:center">
                    <select id="add-patient-select-${tech.id}" style="padding:0.3rem;border:1px solid #ddd;border-radius:4px;font-size:0.85rem">
                        <option value="">${t('admin.selectUser')}</option>
                        ${regularUsers.map(u => `<option value="${u.id}">${escHtml(u.username)}</option>`).join('')}
                    </select>
                    <button class="btn-primary btn-add-patient" data-tech="${tech.id}" style="white-space:nowrap">${t('admin.assign')}</button>
                </div>
            </td>
        `;
        tbody.appendChild(tr);
        loadPatients(tech.id);
    });

    tbody.querySelectorAll('.btn-add-patient').forEach(btn => {
        btn.addEventListener('click', () => addPatient(Number(btn.dataset.tech)));
    });
}

async function loadPatients(techId) {
    const cell = document.getElementById(`patients-${techId}`);
    if (!cell) return;
    try {
        const res = await Auth.fetchWithAuth(`/api/users/${techId}/patients`);
        const patients = await res.json();
        if (!res.ok) { cell.textContent = 'Error'; return; }

        if (patients.length === 0) {
            cell.textContent = t('admin.noneAssigned');
            return;
        }

        const ul = document.createElement('ul');
        ul.className = 'patient-list';
        patients.forEach(p => {
            const li = document.createElement('li');
            li.innerHTML = `
                <span>${escHtml(p.username)}</span>
                <button class="btn-danger" style="padding:0.2rem 0.5rem;font-size:0.75rem"
                    data-tech="${techId}" data-user="${p.id}">Remove</button>
            `;
            li.querySelector('button').addEventListener('click', () => removePatient(techId, p.id));
            ul.appendChild(li);
        });
        cell.innerHTML = '';
        cell.appendChild(ul);
    } catch {
        cell.textContent = 'Error';
    }
}

async function addPatient(techId) {
    const select = document.getElementById(`add-patient-select-${techId}`);
    const userId = Number(select?.value);
    if (!userId) { toast('Select a user to assign', 'error'); return; }

    const res = await Auth.fetchWithAuth(`/api/users/${techId}/patients`, {
        method: 'POST',
        body: JSON.stringify({ user_id: userId }),
    });
    const data = await res.json();
    if (!res.ok) { toast(data.error || 'Failed', 'error'); return; }
    toast('Patient assigned');
    loadPatients(techId);
}

async function removePatient(techId, userId) {
    if (!confirm('Remove this patient assignment?')) return;
    const res = await Auth.fetchWithAuth(`/api/users/${techId}/patients/${userId}`, { method: 'DELETE' });
    const data = await res.json();
    if (!res.ok) { toast(data.error || 'Failed', 'error'); return; }
    toast('Assignment removed');
    loadPatients(techId);
}

// ── User actions ──────────────────────────────────────────────────────────

async function changeRole(userId, currentRole) {
    const roles = ['user', 'tech', 'admin'];
    const next = roles[(roles.indexOf(currentRole) + 1) % roles.length];
    if (!confirm(`Change role to "${next}"?`)) return;

    const res = await Auth.fetchWithAuth(`/api/users/${userId}`, {
        method: 'PATCH',
        body: JSON.stringify({ role: next }),
    });
    const data = await res.json();
    if (!res.ok) { toast(data.error || 'Failed', 'error'); return; }
    toast(`Role updated to ${next}`);
    loadUsers();
}

async function setActive(userId, active) {
    const action = active ? 'activate' : 'suspend';
    if (!confirm(`${action.charAt(0).toUpperCase() + action.slice(1)} this user?`)) return;

    const res = await Auth.fetchWithAuth(`/api/users/${userId}`, {
        method: 'PATCH',
        body: JSON.stringify({ is_active: active }),
    });
    const data = await res.json();
    if (!res.ok) { toast(data.error || 'Failed', 'error'); return; }
    toast(`User ${action}d`);
    loadUsers();
}

// ── Edit user modal ───────────────────────────────────────────────────────

function openEditModal(userId) {
    const user = allUsers.find(u => u.id === userId);
    if (!user) return;

    document.getElementById('edit-user-id').value = userId;
    document.getElementById('edit-username').value = user.username;
    document.getElementById('edit-email').value = user.email;
    document.getElementById('edit-password').value = '';
    document.getElementById('edit-error').style.display = 'none';

    const modal = document.getElementById('edit-modal');
    modal.style.display = 'flex';
    document.getElementById('edit-username').focus();
}

function closeEditModal() {
    document.getElementById('edit-modal').style.display = 'none';
}

async function saveEditUser() {
    const userId = Number(document.getElementById('edit-user-id').value);
    const username = document.getElementById('edit-username').value.trim();
    const email = document.getElementById('edit-email').value.trim();
    const password = document.getElementById('edit-password').value;
    const errEl = document.getElementById('edit-error');
    errEl.style.display = 'none';

    const saveBtn = document.getElementById('edit-save-btn');
    saveBtn.disabled = true;

    try {
        // Update username/email
        const patch = {};
        const user = allUsers.find(u => u.id === userId);
        if (username !== user.username) patch.username = username;
        if (email !== user.email) patch.email = email;

        if (Object.keys(patch).length > 0) {
            const res = await Auth.fetchWithAuth(`/api/users/${userId}`, {
                method: 'PATCH',
                body: JSON.stringify(patch),
            });
            const data = await res.json();
            if (!res.ok) {
                errEl.textContent = data.error || 'Update failed';
                errEl.style.display = 'block';
                return;
            }
        }

        // Update password if provided
        if (password) {
            const res = await Auth.fetchWithAuth(`/api/users/${userId}/password`, {
                method: 'PATCH',
                body: JSON.stringify({ password }),
            });
            const data = await res.json();
            if (!res.ok) {
                errEl.textContent = data.error || 'Password update failed';
                errEl.style.display = 'block';
                return;
            }
        }

        closeEditModal();
        toast('User updated');
        loadUsers();
    } finally {
        saveBtn.disabled = false;
    }
}

function setupEditModal() {
    document.getElementById('edit-cancel-btn')?.addEventListener('click', closeEditModal);
    document.getElementById('edit-save-btn')?.addEventListener('click', saveEditUser);
    document.getElementById('edit-modal')?.addEventListener('click', (e) => {
        if (e.target === e.currentTarget) closeEditModal();
    });
}

// ── Create user form ──────────────────────────────────────────────────────

function setupCreateUserForm() {
    const createBtn = document.getElementById('create-user-btn');
    const cancelBtn = document.getElementById('cancel-create-btn');
    const saveBtn   = document.getElementById('save-new-user-btn');
    const form      = document.getElementById('create-user-form');

    createBtn?.addEventListener('click', () => {
        form.classList.toggle('open');
        document.getElementById('create-user-error').style.display = 'none';
    });

    cancelBtn?.addEventListener('click', () => form.classList.remove('open'));

    saveBtn?.addEventListener('click', async () => {
        const errEl = document.getElementById('create-user-error');
        errEl.style.display = 'none';
        const username = document.getElementById('new-username').value.trim();
        const email    = document.getElementById('new-email').value.trim();
        const password = document.getElementById('new-password').value;
        const role     = document.getElementById('new-role').value;

        saveBtn.disabled = true;
        try {
            const res = await Auth.fetchWithAuth('/api/users', {
                method: 'POST',
                body: JSON.stringify({ username, email, password, role }),
            });
            const data = await res.json();
            if (!res.ok) {
                errEl.textContent = data.error || 'Create failed';
                errEl.style.display = 'block';
                return;
            }
            form.classList.remove('open');
            document.getElementById('new-username').value = '';
            document.getElementById('new-email').value = '';
            document.getElementById('new-password').value = '';
            toast(`User ${username} created`);
            loadUsers();
        } finally {
            saveBtn.disabled = false;
        }
    });
}

// ── Anthropometric profiles tab ────────────────────────────────────────────

async function loadAnthroProfiles() {
    const country   = document.getElementById('anthro-filter-country')?.value.trim()   || undefined;
    const gender    = document.getElementById('anthro-filter-gender')?.value           || undefined;
    const age_group = document.getElementById('anthro-filter-age-group')?.value.trim() || undefined;

    try {
        const profiles = await AnthropometricImporter.loadProfiles({ country, gender, age_group });
        renderAnthroProfiles(profiles);
    } catch (err) {
        toast('Failed to load profiles: ' + err.message, 'error');
    }
}

// Exposed globally so anthropometric.js can call it after saving
window.loadAnthroProfiles = loadAnthroProfiles;

function renderAnthroProfiles(profiles) {
    const tbody = document.getElementById('anthro-profiles-tbody');
    if (!tbody) return;

    if (!profiles.length) {
        tbody.innerHTML = `<tr><td colspan="10" style="text-align:center;color:#888;padding:1.5rem">
            No profiles yet. Click "+ New Profile" to import one.
        </td></tr>`;
        return;
    }

    tbody.innerHTML = profiles.map(p => {
        const uncertainty = p.uncertainty || '—';
        const uColor = { low: '#27ae60', medium: '#e67e22', high: '#e74c3c' }[uncertainty] || '#888';
        return `<tr>
            <td>${p.id}</td>
            <td>${escHtml(p.group_name)}</td>
            <td>${escHtml(p.country  || '—')}</td>
            <td>${escHtml(p.gender   || '—')}</td>
            <td>${escHtml(p.age_group || '—')}</td>
            <td>${escHtml(p.percentile || '—')}</td>
            <td>${p.sample_size != null ? p.sample_size : '—'}</td>
            <td><span style="color:${uColor};font-weight:600;text-transform:capitalize">${uncertainty}</span></td>
            <td>${fmtDate(p.created_at)}</td>
            <td>
                <div class="action-cell">
                    <button class="btn-secondary btn-anthro-edit" data-id="${p.id}">Edit</button>
                    <button class="btn-danger btn-anthro-delete" data-id="${p.id}">Delete</button>
                </div>
            </td>
        </tr>`;
    }).join('');

    tbody.querySelectorAll('.btn-anthro-edit').forEach(btn => {
        btn.addEventListener('click', () => {
            AnthropometricImporter.openEdit(Number(btn.dataset.id));
        });
    });

    tbody.querySelectorAll('.btn-anthro-delete').forEach(btn => {
        btn.addEventListener('click', async () => {
            if (!confirm('Delete this anthropometric profile?')) return;
            try {
                await AnthropometricImporter.deleteProfile(Number(btn.dataset.id));
                toast('Profile deleted');
                loadAnthroProfiles();
            } catch (err) {
                toast(err.message, 'error');
            }
        });
    });
}

function setupAnthroTab() {
    document.getElementById('anthro-filter-btn')
        ?.addEventListener('click', loadAnthroProfiles);

    document.getElementById('anthro-new-btn')
        ?.addEventListener('click', () => {
            AnthropometricImporter.openNew();
        });

    document.getElementById('anthro-bulk-import-btn')
        ?.addEventListener('click', () => {
            document.getElementById('anthro-bulk-file').click();
        });

    document.getElementById('anthro-bulk-file')
        ?.addEventListener('change', async (e) => {
            const file = e.target.files[0];
            if (!file) return;
            e.target.value = '';

            const btn = document.getElementById('anthro-bulk-import-btn');
            const orig = btn.textContent;
            btn.textContent = 'Importing…';
            btn.disabled = true;

            try {
                const csv_text = await file.text();
                const res = await Auth.fetchWithAuth('/api/anthropometric/import-csv-bulk', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ csv_text }),
                });
                const json = await res.json();
                if (!res.ok) throw new Error(json.error || 'Import failed');
                toast(`Imported ${json.created} profile(s) — ${json.skipped} skipped (already exist)`);
                loadAnthroProfiles();
            } catch (err) {
                toast('Import error: ' + err.message, 'error');
            } finally {
                btn.textContent = orig;
                btn.disabled = false;
            }
        });
}

// ── Tab switching ──────────────────────────────────────────────────────────

function setupTabs() {
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
            document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
            btn.classList.add('active');
            const panel = document.getElementById(`tab-${btn.dataset.tab}`);
            panel?.classList.add('active');
            // Load profiles when switching to anthropometric tab
            if (btn.dataset.tab === 'anthropometric') loadAnthroProfiles();
            if (btn.dataset.tab === 'content') { loadFooter(); loadPages(); }
        });
    });
}

// ── XSS helper ────────────────────────────────────────────────────────────

function escHtml(str) {
    return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}

// ── Footer & Pages (content) ─────────────────────────────────────────────────

let footerColumns = []; // [{ title, links: [{ label, type, target }] }]

async function loadFooter() {
    try {
        const res = await fetch('/api/content/footer');
        const cfg = await res.json();
        document.getElementById('footer-brand').value = cfg.brandTitle || '';
        document.getElementById('footer-tagline').value = cfg.tagline || '';
        document.getElementById('footer-copyright').value = cfg.copyright || '';
        footerColumns = (Array.isArray(cfg.columns) ? cfg.columns : []).map(c => ({
            title: c.title || '',
            links: (c.links || []).map(l => ({
                label: l.label || '',
                type: l.type === 'page' ? 'page' : 'url',
                target: l.target || '',
            })),
        }));
        renderFooterColumns();
    } catch {
        toast('Failed to load footer', 'error');
    }
}

function renderFooterColumns() {
    const wrap = document.getElementById('footer-columns');
    wrap.innerHTML = footerColumns.map((col, ci) => `
        <div class="footer-col" data-col="${ci}">
            <div class="footer-col-head">
                <input type="text" class="col-title" placeholder="${t('admin.columnTitle')}" value="${escHtml(col.title)}">
                <button class="icon-btn-x col-remove" title="${t('admin.removeColumn')}" type="button">&times;</button>
            </div>
            <div class="footer-col-links">
                ${col.links.map((l, li) => `
                    <div class="footer-link-row" data-link="${li}">
                        <input type="text" class="link-label" placeholder="${t('admin.linkLabel')}" value="${escHtml(l.label)}">
                        <select class="link-type">
                            <option value="page" ${l.type === 'page' ? 'selected' : ''}>${t('admin.linkPage')}</option>
                            <option value="url" ${l.type === 'url' ? 'selected' : ''}>${t('admin.linkUrl')}</option>
                        </select>
                        <input type="text" class="link-target" placeholder="${l.type === 'page' ? 'page-slug' : 'https://…'}" value="${escHtml(l.target)}">
                        <button class="icon-btn-x link-remove" title="${t('admin.removeLink')}" type="button">&times;</button>
                    </div>
                `).join('')}
            </div>
            <div class="footer-col-actions">
                <button class="btn-secondary btn-sm link-add" type="button">${t('admin.addLink')}</button>
            </div>
        </div>
    `).join('');
}

// Read the current DOM inputs back into footerColumns before any re-render/save.
function syncFooterFromDom() {
    footerColumns = Array.from(document.querySelectorAll('#footer-columns .footer-col')).map(colEl => ({
        title: colEl.querySelector('.col-title').value,
        links: Array.from(colEl.querySelectorAll('.footer-link-row')).map(row => ({
            label: row.querySelector('.link-label').value,
            type: row.querySelector('.link-type').value,
            target: row.querySelector('.link-target').value,
        })),
    }));
}

async function saveFooter() {
    syncFooterFromDom();
    const payload = {
        brandTitle: document.getElementById('footer-brand').value,
        tagline: document.getElementById('footer-tagline').value,
        copyright: document.getElementById('footer-copyright').value,
        columns: footerColumns,
    };
    const errEl = document.getElementById('footer-error');
    errEl.textContent = '';
    try {
        const res = await Auth.fetchWithAuth('/api/content/footer', {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload),
        });
        const data = await res.json();
        if (!res.ok) { errEl.textContent = data.error || 'Failed to save footer'; return; }
        toast('Footer saved');
    } catch {
        errEl.textContent = 'Network error';
    }
}

function slugify(s) {
    return String(s).toLowerCase().trim().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '').slice(0, 80);
}

let _pagesById = {};

async function loadPages() {
    const tbody = document.getElementById('pages-tbody');
    try {
        const res = await Auth.fetchWithAuth('/api/content/pages');
        const pages = await res.json();
        if (!res.ok) { tbody.innerHTML = `<tr><td colspan="5">Failed to load pages</td></tr>`; return; }
        _pagesById = {};
        pages.forEach(p => { _pagesById[p.id] = p; });
        if (!pages.length) { tbody.innerHTML = `<tr><td colspan="5" style="color:#999">${t('admin.noPages')}</td></tr>`; return; }
        tbody.innerHTML = pages.map(p => `
            <tr data-id="${p.id}">
                <td>${escHtml(p.title)}</td>
                <td><a href="/pages/${encodeURIComponent(p.slug)}" target="_blank" rel="noopener">/pages/${escHtml(p.slug)}</a></td>
                <td><span class="page-status-pill ${p.is_published ? 'published' : 'draft'}">${p.is_published ? t('admin.statusPublished') : t('admin.pillDraft')}</span></td>
                <td>${fmtDate(p.updated_at)}</td>
                <td>
                    <button class="btn-secondary btn-sm page-edit" type="button">${t('admin.edit')}</button>
                    <button class="btn-danger btn-sm page-delete" type="button">${t('admin.delete')}</button>
                </td>
            </tr>
        `).join('');
        tbody.querySelectorAll('.page-edit').forEach(b => b.addEventListener('click', e => openPageForm(_pagesById[e.target.closest('tr').dataset.id])));
        tbody.querySelectorAll('.page-delete').forEach(b => b.addEventListener('click', e => {
            const id = Number(e.target.closest('tr').dataset.id);
            deletePage(id, _pagesById[id]);
        }));
    } catch {
        tbody.innerHTML = `<tr><td colspan="5">Failed to load pages</td></tr>`;
    }
}

function openPageForm(page) {
    document.getElementById('page-error').textContent = '';
    document.getElementById('page-id').value = page ? page.id : '';
    document.getElementById('page-title').value = page ? page.title : '';
    const slugEl = document.getElementById('page-slug');
    slugEl.value = page ? page.slug : '';
    slugEl.dataset.touched = page ? '1' : '';
    document.getElementById('page-body').value = page ? page.body : '';
    document.getElementById('page-published').value = page && !page.is_published ? '0' : '1';
    const openLink = document.getElementById('page-open-link');
    if (page) { openLink.style.display = ''; openLink.href = '/pages/' + encodeURIComponent(page.slug); }
    else { openLink.style.display = 'none'; }
    document.getElementById('page-form').classList.add('open');
    document.getElementById('page-title').focus();
}

function closePageForm() {
    document.getElementById('page-form').classList.remove('open');
}

async function savePage() {
    const id = document.getElementById('page-id').value;
    const payload = {
        title: document.getElementById('page-title').value.trim(),
        slug: document.getElementById('page-slug').value.trim(),
        body: document.getElementById('page-body').value,
        is_published: document.getElementById('page-published').value === '1',
    };
    const errEl = document.getElementById('page-error');
    errEl.textContent = '';
    try {
        const res = await Auth.fetchWithAuth(id ? `/api/content/pages/${id}` : '/api/content/pages', {
            method: id ? 'PUT' : 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload),
        });
        const data = await res.json();
        if (!res.ok) { errEl.textContent = data.error || 'Failed to save page'; return; }
        toast(id ? 'Page updated' : 'Page created');
        closePageForm();
        loadPages();
    } catch {
        errEl.textContent = 'Network error';
    }
}

async function deletePage(id, page) {
    if (!confirm(`Delete page "${page ? page.title : id}"? This cannot be undone.`)) return;
    try {
        const res = await Auth.fetchWithAuth(`/api/content/pages/${id}`, { method: 'DELETE' });
        if (!res.ok) { const d = await res.json().catch(() => ({})); toast(d.error || 'Failed to delete', 'error'); return; }
        toast('Page deleted');
        loadPages();
    } catch {
        toast('Network error', 'error');
    }
}

function setupContentTab() {
    const colsWrap = document.getElementById('footer-columns');
    colsWrap.addEventListener('click', (e) => {
        const colEl = e.target.closest('.footer-col');
        if (!colEl) return;
        const ci = Number(colEl.dataset.col);
        if (e.target.classList.contains('col-remove')) {
            syncFooterFromDom(); footerColumns.splice(ci, 1); renderFooterColumns();
        } else if (e.target.classList.contains('link-add')) {
            syncFooterFromDom(); footerColumns[ci].links.push({ label: '', type: 'page', target: '' }); renderFooterColumns();
        } else if (e.target.classList.contains('link-remove')) {
            syncFooterFromDom();
            const li = Number(e.target.closest('.footer-link-row').dataset.link);
            footerColumns[ci].links.splice(li, 1); renderFooterColumns();
        }
    });
    colsWrap.addEventListener('change', (e) => {
        if (e.target.classList.contains('link-type')) {
            const target = e.target.closest('.footer-link-row').querySelector('.link-target');
            target.placeholder = e.target.value === 'page' ? 'page-slug' : 'https://…';
        }
    });
    document.getElementById('footer-add-column').addEventListener('click', () => {
        syncFooterFromDom(); footerColumns.push({ title: 'New column', links: [] }); renderFooterColumns();
    });
    document.getElementById('footer-save-btn').addEventListener('click', saveFooter);

    document.getElementById('page-new-btn').addEventListener('click', () => openPageForm());
    document.getElementById('page-cancel-btn').addEventListener('click', closePageForm);
    document.getElementById('page-save-btn').addEventListener('click', savePage);
    document.getElementById('page-title').addEventListener('input', (e) => {
        const slugEl = document.getElementById('page-slug');
        if (!document.getElementById('page-id').value && !slugEl.dataset.touched) slugEl.value = slugify(e.target.value);
    });
    document.getElementById('page-slug').addEventListener('input', (e) => { e.target.dataset.touched = '1'; });
}

// ── Boot ──────────────────────────────────────────────────────────────────

document.addEventListener('DOMContentLoaded', async () => {
    // Logout button in header
    document.getElementById('admin-logout')?.addEventListener('click', async (e) => {
        e.preventDefault();
        await Auth.logout();
        window.location.href = '/';
    });

    // Override the default showLoginModal to redirect to main page for login
    window.showLoginModal = () => { window.location.href = '/'; };

    // Restore session
    const ok = await Auth.tryRestoreSession();
    if (!ok) {
        window.location.href = '/';
        return;
    }

    const user = Auth.getUser();
    if (user?.role !== 'admin') {
        document.getElementById('admin-loading').textContent = t('admin.accessDenied');
        return;
    }

    document.getElementById('admin-loading').style.display = 'none';
    document.getElementById('admin-content').style.display = 'block';

    // Populate greeting + avatar initial
    if (user) {
        const name = user.username || 'Admin';
        const greetEl = document.getElementById('admin-user-greeting');
        const avatarEl = document.getElementById('admin-user-avatar');
        if (greetEl) greetEl.textContent = t('menu.greeting', { name });
        if (avatarEl) avatarEl.textContent = name.charAt(0).toUpperCase();
    }

    // User menu dropdown toggle
    const menuEl = document.getElementById('admin-user-menu');
    const menuBtn = document.getElementById('admin-user-btn');
    if (menuBtn && menuEl) {
        menuBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            const open = menuEl.classList.toggle('open');
            menuBtn.setAttribute('aria-expanded', open);
        });
        document.addEventListener('click', () => {
            menuEl.classList.remove('open');
            menuBtn.setAttribute('aria-expanded', 'false');
        });
    }

    setupTabs();
    setupEditModal();
    setupResetTokenModal();
    setupCreateUserForm();
    setupAnthroTab();
    setupContentTab();
    loadUsers();

    // Re-render the JS-built tables/editors in the new language.
    window.addEventListener('i18n:change', () => {
        const u = Auth.getUser && Auth.getUser();
        const greetEl = document.getElementById('admin-user-greeting');
        if (u && greetEl) greetEl.textContent = t('menu.greeting', { name: u.username || 'Admin' });
        if (allUsers && allUsers.length) { renderUsersTable(allUsers); renderAssignmentsTab(allUsers); }
        const contentTab = document.getElementById('tab-content');
        if (contentTab && contentTab.classList.contains('active')) { renderFooterColumns(); loadPages(); }
    });
});
