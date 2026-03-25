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
    return `<span class="badge badge-${role}">${role}</span>`;
}

function statusBadge(isActive) {
    return isActive
        ? '<span class="badge badge-active">Active</span>'
        : '<span class="badge badge-inactive">Inactive</span>';
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
                    <button class="btn-primary btn-edit" data-id="${u.id}">Edit</button>
                    <button class="btn-warning btn-change-role" data-id="${u.id}" data-role="${u.role}">Role</button>
                    <button class="btn-secondary btn-reset-token" data-id="${u.id}">Reset Token</button>
                    ${u.is_active
                        ? `<button class="btn-secondary btn-suspend" data-id="${u.id}">Suspend</button>`
                        : `<button class="btn-success btn-activate" data-id="${u.id}">Activate</button>`}
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
        tbody.innerHTML = '<tr><td colspan="3" style="color:#888;padding:1.5rem">No tech users found. Create a user with role=tech first.</td></tr>';
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
                        <option value="">— select user —</option>
                        ${regularUsers.map(u => `<option value="${u.id}">${escHtml(u.username)}</option>`).join('')}
                    </select>
                    <button class="btn-primary btn-add-patient" data-tech="${tech.id}" style="white-space:nowrap">Assign</button>
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
            cell.textContent = 'None assigned';
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
                    <button class="btn-danger btn-anthro-delete" data-id="${p.id}">Delete</button>
                </div>
            </td>
        </tr>`;
    }).join('');

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

// ── Boot ──────────────────────────────────────────────────────────────────

document.addEventListener('DOMContentLoaded', async () => {
    // Logout button in header
    document.getElementById('admin-logout')?.addEventListener('click', async (e) => {
        e.preventDefault();
        await Auth.logout();
        window.location.href = 'index.html';
    });

    // Override the default showLoginModal to redirect to main page for login
    window.showLoginModal = () => { window.location.href = 'index.html'; };

    // Restore session
    const ok = await Auth.tryRestoreSession();
    if (!ok) {
        window.location.href = 'index.html';
        return;
    }

    const user = Auth.getUser();
    if (user?.role !== 'admin') {
        document.getElementById('admin-loading').textContent = 'Access denied. Admin role required.';
        return;
    }

    document.getElementById('admin-loading').style.display = 'none';
    document.getElementById('admin-content').style.display = 'block';

    setupTabs();
    setupEditModal();
    setupResetTokenModal();
    setupCreateUserForm();
    setupAnthroTab();
    loadUsers();
});
