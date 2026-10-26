'use strict';

// admin-models.js — "Models" tab: add/edit parametric models without a deploy.
// Depends on admin.js (toast, escHtml, fmtDate) and auth.js / i18n.js.
//
// Form mode reads the Customizer parameters out of the main .scad
// (POST /api/models/parse-scad); Advanced mode edits the raw definition JSON
// (same shape as a models-config.json entry) for fields the form doesn't cover.

const MDL_TEXT_FIELDS = ['label', 'label_pt', 'caption', 'caption_pt', 'help', 'help_pt'];
const MDL_TYPES = ['number', 'boolean', 'enum', 'color', 'string'];
const MDL_MAX_PAYLOAD = 7.5 * 1024 * 1024;   // server JSON limit is 8 MB

let mdlList = { repo: [], custom: [] };
let mdl = null;   // editor state

// ── List ────────────────────────────────────────────────────────────────────

async function loadModelsTab() {
    const tbody = document.getElementById('mdl-tbody');
    try {
        const res = await Auth.fetchWithAuth('/api/models/admin');
        const data = await res.json();
        if (!res.ok) throw new Error(data.error);
        mdlList = data;
        const name = (m) => (I18n.getLang() === 'pt' && m.name_pt) ? m.name_pt : m.name;
        const repoRows = data.repo.map(m => `
            <tr>
                <td>${escHtml(name(m))}</td>
                <td><code>${escHtml(m.id)}</code></td>
                <td><span class="mdl-source">${t('mdl.sourceRepo')}</span></td>
                <td><span class="page-status-pill published">${t('mdl.statusActive')}</span></td>
                <td>${m.paramCount}</td>
                <td>${m.configCount}</td>
                <td style="color:var(--text-muted);font-size:0.8125rem">${t('mdl.readOnly')}</td>
            </tr>`);
        const customRows = data.custom.map(m => `
            <tr data-id="${escHtml(m.id)}">
                <td>${escHtml(name(m))}</td>
                <td><code>${escHtml(m.id)}</code></td>
                <td><span class="mdl-source" style="background:#ecfdf5;color:#047857">${t('mdl.sourceCustom')}</span></td>
                <td><span class="page-status-pill ${m.enabled ? 'published' : 'draft'}">${m.enabled ? t('mdl.statusActive') : t('mdl.statusDraft')}</span></td>
                <td>${m.paramCount}</td>
                <td>${m.configCount}</td>
                <td class="action-cell">
                    <button class="btn-secondary btn-sm mdl-edit" type="button">${t('admin.edit')}</button>
                    <button class="btn-secondary btn-sm mdl-toggle" type="button">${m.enabled ? t('mdl.toDraft') : t('mdl.publish')}</button>
                    <button class="btn-danger btn-sm mdl-delete" type="button">${t('admin.delete')}</button>
                </td>
            </tr>`);
        tbody.innerHTML = repoRows.concat(customRows).join('');
    } catch {
        tbody.innerHTML = `<tr><td colspan="7">${t('mdl.loadFail')}</td></tr>`;
    }
}

async function toggleModel(id) {
    const m = mdlList.custom.find(x => x.id === id);
    if (!m) return;
    const res = await Auth.fetchWithAuth(`/api/models/admin/${encodeURIComponent(id)}`, {
        method: 'PUT', body: JSON.stringify({ enabled: !m.enabled }),
    });
    const d = await res.json().catch(() => ({}));
    if (!res.ok) { toast(d.error || t('admin.tFailed'), 'error'); return; }
    toast(d.enabled ? t('mdl.tPublished') : t('mdl.tDrafted'));
    loadModelsTab();
}

async function deleteModel(id) {
    if (!confirm(t('mdl.confirmDelete', { id }))) return;
    const res = await Auth.fetchWithAuth(`/api/models/admin/${encodeURIComponent(id)}`, { method: 'DELETE' });
    const d = await res.json().catch(() => ({}));
    if (!res.ok) { toast(d.error || t('admin.tFailed'), 'error'); return; }
    toast(t('mdl.tDeleted'));
    if (mdl && mdl.id === id) closeModelEditor();
    loadModelsTab();
}

// ── Editor state ────────────────────────────────────────────────────────────

function mdlShowError(msg) {
    const el = document.getElementById('mdl-error');
    el.textContent = msg || '';
    el.style.display = msg ? 'block' : 'none';
    if (msg) el.scrollIntoView({ behavior: 'smooth', block: 'center' });
}

async function openModelEditor(id) {
    mdlShowError('');
    if (id) {
        const res = await Auth.fetchWithAuth(`/api/models/admin/${encodeURIComponent(id)}`);
        const data = await res.json();
        if (!res.ok) { toast(data.error || t('admin.tFailed'), 'error'); return; }
        mdl = {
            isNew: false, id: data.id, enabled: data.enabled,
            def: data.definition,
            files: data.files.map(f => ({ name: f.name, size: f.size, existing: true })),
            removeFiles: new Set(), warnings: {}, mode: 'form',
        };
    } else {
        mdl = {
            isNew: true, id: '', enabled: false,
            def: { name: '', limb: 'hand', renderBackend: 'manifold', parameters: [] },
            files: [], removeFiles: new Set(), warnings: {}, mode: 'form',
        };
    }
    document.getElementById('mdl-editor-title').textContent = mdl.isNew ? t('mdl.titleNew') : t('mdl.titleEdit', { id: mdl.id });
    document.getElementById('mdl-parse-report').textContent = '';
    setMode('form', true);
    renderModelForm();
    const ed = document.getElementById('mdl-editor');
    ed.classList.add('open');
    ed.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

function closeModelEditor() {
    document.getElementById('mdl-editor').classList.remove('open');
    mdl = null;
}

function renderModelForm() {
    const d = mdl.def;
    const idEl = document.getElementById('mdl-id');
    idEl.value = mdl.id;
    idEl.disabled = !mdl.isNew;
    document.getElementById('mdl-name').value = d.name || '';
    document.getElementById('mdl-name-pt').value = d.name_pt || '';
    document.getElementById('mdl-desc').value = d.description || '';
    document.getElementById('mdl-desc-pt').value = d.description_pt || '';
    document.getElementById('mdl-limb').value = ['hand', 'arm', 'other'].includes(d.limb) ? d.limb : 'hand';
    document.getElementById('mdl-backend').value = d.renderBackend === 'cgal' ? 'cgal' : 'manifold';
    document.getElementById('mdl-enabled').checked = !!mdl.enabled;
    document.getElementById('mdl-ai').value = d.aiGuidance || '';
    renderFiles();
    renderParams();
}

function fmtSize(n) {
    if (n == null) return '';
    return n < 1024 ? `${n} B` : n < 1048576 ? `${(n / 1024).toFixed(1)} KB` : `${(n / 1048576).toFixed(1)} MB`;
}

function renderFiles() {
    const tbody = document.getElementById('mdl-files-tbody');
    if (!mdl.files.length) {
        tbody.innerHTML = `<tr><td colspan="4" style="color:var(--text-muted)">${t('mdl.noFiles')}</td></tr>`;
        return;
    }
    tbody.innerHTML = mdl.files.map((f, i) => {
        const isScad = /\.scad$/i.test(f.name);
        return `<tr data-i="${i}">
            <td>${isScad ? `<input type="radio" name="mdl-main" value="${escHtml(f.name)}" ${mdl.def.file === f.name ? 'checked' : ''}>` : ''}</td>
            <td><code>${escHtml(f.name)}</code>${f.existing ? '' : ` <span class="mdl-warn" style="background:#ecfdf5;color:#047857">${t('mdl.fileNew')}</span>`}</td>
            <td>${fmtSize(f.size)}</td>
            <td><button type="button" class="icon-btn-x mdl-file-remove" title="${escHtml(t('admin.delete'))}">×</button></td>
        </tr>`;
    }).join('');
}

const MDL_WARN_TEXT = {
    inferred_range: 'mdl.wInferred',
    laterality_candidate: 'mdl.wLaterality',
    non_canonical: 'mdl.wCanonical',
    not_in_scad: 'mdl.wNotInScad',
};

function renderParams() {
    const wrap = document.getElementById('mdl-params');
    const params = mdl.def.parameters || [];
    if (!params.length) {
        wrap.innerHTML = `<p class="mdl-note">${t('mdl.noParams')}</p>`;
        return;
    }
    wrap.innerHTML = params.map((p, i) => {
        const v = (x) => x === undefined || x === null ? '' : escHtml(String(x));
        const typeOpts = MDL_TYPES.map(ty => `<option value="${ty}" ${p.type === ty ? 'selected' : ''}>${t('mdl.type.' + ty)}</option>`).join('');
        const initial = p.type === 'boolean'
            ? `<select data-f="initial"><option value="true" ${p.initial === true ? 'selected' : ''}>true</option><option value="false" ${p.initial !== true ? 'selected' : ''}>false</option></select>`
            : `<input type="text" data-f="initial" value="${v(p.initial)}">`;
        const isNum = p.type === 'number';
        const warns = (mdl.warnings[p.name] || []).map(c => `<span class="mdl-warn">${escHtml(t(MDL_WARN_TEXT[c] || c))}</span>`).join('');
        const options = (p.options || []).map(o => `${o.value}: ${o.label}`).join('\n');
        return `<div class="mdl-param" data-i="${i}">
            <div class="mdl-param-row">
                <div><label>${t('mdl.pName')}</label><input type="text" data-f="name" value="${v(p.name)}"></div>
                <div><label>${t('mdl.pType')}</label><select data-f="type">${typeOpts}</select></div>
                <div><label>${t('mdl.pInitial')}</label>${initial}</div>
                <div><label>Min</label><input type="number" step="any" data-f="min" value="${v(p.min)}" ${isNum ? '' : 'disabled'}></div>
                <div><label>${t('mdl.pStep')}</label><input type="number" step="any" data-f="step" value="${v(p.step)}" ${isNum ? '' : 'disabled'}></div>
                <div><label>Max</label><input type="number" step="any" data-f="max" value="${v(p.max)}" ${isNum ? '' : 'disabled'}></div>
                <div><label>${t('mdl.pGroup')}</label><input type="text" data-f="group" value="${v(p.group)}"></div>
                <div><button type="button" class="icon-btn-x mdl-param-remove" title="${escHtml(t('admin.delete'))}">×</button></div>
            </div>
            ${warns}
            <details>
                <summary>${t('mdl.pMore')}</summary>
                <div class="mdl-grid">
                    <div><label>${t('mdl.pLabelEn')}</label><input type="text" data-f="label" value="${v(p.label)}"></div>
                    <div><label>${t('mdl.pLabelPt')}</label><input type="text" data-f="label_pt" value="${v(p.label_pt)}"></div>
                    <div><label>${t('mdl.pCaptionEn')}</label><input type="text" data-f="caption" value="${v(p.caption)}"></div>
                    <div><label>${t('mdl.pCaptionPt')}</label><input type="text" data-f="caption_pt" value="${v(p.caption_pt)}"></div>
                    <div><label>${t('mdl.pHelpEn')}</label><textarea data-f="help" rows="2">${v(p.help)}</textarea></div>
                    <div><label>${t('mdl.pHelpPt')}</label><textarea data-f="help_pt" rows="2">${v(p.help_pt)}</textarea></div>
                    ${p.type === 'enum' ? `<div class="full"><label>${t('mdl.pOptions')}</label><textarea data-f="options" rows="3" placeholder="false: Left hand&#10;true: Right hand">${escHtml(options)}</textarea></div>` : ''}
                    <div class="full"><label class="mdl-check"><input type="checkbox" data-f="laterality" ${p.role === 'laterality' ? 'checked' : ''}> ${t('mdl.pLaterality')}</label></div>
                </div>
            </details>
        </div>`;
    }).join('');
}

// ── Form ⇄ definition ───────────────────────────────────────────────────────

function scalarFrom(str) {
    const s = String(str).trim();
    if (s === 'true' || s === 'false') return s === 'true';
    if (s !== '' && !isNaN(Number(s))) return Number(s);
    return s.replace(/^"(.*)"$/, '$1');
}

// Read the parameter cards back into mdl.def.parameters, keeping any extra
// keys (dependsOn, …) that only the JSON mode can set.
function syncParamsFromDom() {
    const params = mdl.def.parameters || [];
    document.querySelectorAll('#mdl-params .mdl-param').forEach(card => {
        const p = params[Number(card.dataset.i)];
        if (!p) return;
        const get = (f) => card.querySelector(`[data-f="${f}"]`);
        p.name = get('name').value.trim();
        p.type = get('type').value;
        const init = get('initial').value;
        if (p.type === 'number') p.initial = init.trim() === '' ? init : Number(init);
        else if (p.type === 'boolean') p.initial = init === 'true';
        else if (p.type === 'enum') p.initial = scalarFrom(init);
        else p.initial = init;
        for (const f of ['min', 'step', 'max']) {
            const val = get(f).value;
            if (p.type === 'number' && val !== '') p[f] = Number(val); else delete p[f];
        }
        const group = get('group').value.trim();
        if (group) p.group = group; else delete p.group;
        for (const f of MDL_TEXT_FIELDS) {
            const val = get(f).value.trim();
            if (val) p[f] = val; else delete p[f];
        }
        const opts = get('options');
        if (opts) {
            p.options = opts.value.split('\n').map(l => l.trim()).filter(Boolean).map(l => {
                const ci = l.indexOf(':');
                const value = scalarFrom(ci >= 0 ? l.slice(0, ci) : l);
                return { label: (ci >= 0 ? l.slice(ci + 1) : l).trim(), value };
            });
            // Initial value typed as text: match it to an option of the same spelling.
            const match = p.options.find(o => String(o.value) === String(p.initial));
            if (match) p.initial = match.value;
        } else if (p.type !== 'enum') {
            delete p.options;
        }
        if (get('laterality').checked) p.role = 'laterality'; else if (p.role === 'laterality') delete p.role;
    });
}

function syncFormToState() {
    if (mdl.mode !== 'form') return;
    const d = mdl.def;
    if (mdl.isNew) mdl.id = document.getElementById('mdl-id').value.trim();
    const set = (k, val) => { if (val) d[k] = val; else delete d[k]; };
    set('name', document.getElementById('mdl-name').value.trim());
    set('name_pt', document.getElementById('mdl-name-pt').value.trim());
    set('description', document.getElementById('mdl-desc').value.trim());
    set('description_pt', document.getElementById('mdl-desc-pt').value.trim());
    set('limb', document.getElementById('mdl-limb').value);
    set('renderBackend', document.getElementById('mdl-backend').value);
    set('aiGuidance', document.getElementById('mdl-ai').value.trim());
    mdl.enabled = document.getElementById('mdl-enabled').checked;
    const main = document.querySelector('input[name="mdl-main"]:checked');
    if (main) d.file = main.value;
    syncParamsFromDom();
}

function setMode(mode, silent) {
    if (!mdl) return;
    if (!silent && mode === mdl.mode) return;
    if (!silent && mode === 'json') {
        syncFormToState();
        document.getElementById('mdl-json').value = JSON.stringify(mdl.def, null, 2);
    }
    if (!silent && mode === 'form') {
        let parsed;
        try { parsed = JSON.parse(document.getElementById('mdl-json').value); }
        catch (e) { mdlShowError(t('mdl.jsonInvalid', { msg: e.message })); return; }
        if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) { mdlShowError(t('mdl.jsonNotObject')); return; }
        if (!Array.isArray(parsed.parameters)) parsed.parameters = [];
        mdl.def = parsed;
        renderModelForm();
    }
    mdlShowError('');
    mdl.mode = mode;
    document.getElementById('mdl-form-view').style.display = mode === 'form' ? '' : 'none';
    document.getElementById('mdl-json-view').style.display = mode === 'json' ? '' : 'none';
    document.getElementById('mdl-mode-form').classList.toggle('active', mode === 'form');
    document.getElementById('mdl-mode-json').classList.toggle('active', mode === 'json');
}

// ── Files ───────────────────────────────────────────────────────────────────

function readAsBase64(file) {
    return new Promise((resolve, reject) => {
        const r = new FileReader();
        r.onload = () => resolve(String(r.result).split(',')[1] || '');
        r.onerror = () => reject(r.error);
        r.readAsDataURL(file);
    });
}

async function addFiles(fileList) {
    syncFormToState();
    let newMain = null;
    for (const file of fileList) {
        if (!/^[A-Za-z0-9][A-Za-z0-9_.-]{0,99}$/.test(file.name) || !/\.(scad|stl|dxf|svg)$/i.test(file.name)) {
            toast(t('mdl.badFileName', { name: file.name }), 'error');
            continue;
        }
        if (file.size > 5 * 1024 * 1024) { toast(t('mdl.fileTooBig', { name: file.name }), 'error'); continue; }
        const content_base64 = await readAsBase64(file);
        const entry = { name: file.name, size: file.size, content_base64 };
        const i = mdl.files.findIndex(f => f.name === file.name);
        if (i >= 0) mdl.files[i] = entry; else mdl.files.push(entry);
        mdl.removeFiles.delete(file.name);
        if (!mdl.def.file && /\.scad$/i.test(file.name)) { mdl.def.file = file.name; newMain = file.name; }
    }
    renderFiles();
    // First main .scad on an empty model: read its parameters straight away.
    if (newMain && !(mdl.def.parameters || []).length) parseMainScad();
}

function removeFile(i) {
    syncFormToState();
    const f = mdl.files[i];
    if (!f) return;
    if (f.existing) mdl.removeFiles.add(f.name);
    mdl.files.splice(i, 1);
    if (mdl.def.file === f.name) {
        const next = mdl.files.find(x => /\.scad$/i.test(x.name));
        if (next) mdl.def.file = next.name; else delete mdl.def.file;
    }
    renderFiles();
}

async function mainScadSource() {
    const f = mdl.files.find(x => x.name === mdl.def.file);
    if (!f) return null;
    if (f.content_base64) {
        const bytes = Uint8Array.from(atob(f.content_base64), c => c.charCodeAt(0));
        return new TextDecoder().decode(bytes);
    }
    const res = await fetch(`/api/models/files/${encodeURIComponent(mdl.id)}/${encodeURIComponent(f.name)}`, { cache: 'no-cache' });
    return res.ok ? res.text() : null;
}

// Parse the main .scad and merge: parameters already defined keep everything the
// admin wrote; new ones are added; ones no longer in the file are flagged.
async function parseMainScad() {
    syncFormToState();
    const report = document.getElementById('mdl-parse-report');
    if (!mdl.def.file) { report.textContent = t('mdl.needMain'); return; }
    const source = await mainScadSource();
    if (source == null) { report.textContent = t('mdl.readFail'); return; }
    const res = await Auth.fetchWithAuth('/api/models/parse-scad', { method: 'POST', body: JSON.stringify({ source }) });
    const data = await res.json();
    if (!res.ok) { report.textContent = data.error || t('admin.tFailed'); return; }

    const existing = new Map((mdl.def.parameters || []).map(p => [p.name, p]));
    const parsedNames = new Set(data.parameters.map(p => p.name));
    const merged = [];
    let added = 0;
    for (const p of data.parameters) {
        if (existing.has(p.name)) merged.push(existing.get(p.name));
        else { merged.push(p); added++; }
    }
    const missing = [...existing.values()].filter(p => !parsedNames.has(p.name));
    mdl.def.parameters = merged.concat(missing);

    mdl.warnings = {};
    for (const w of data.warnings) (mdl.warnings[w.name] = mdl.warnings[w.name] || []).push(w.code);
    for (const p of missing) mdl.warnings[p.name] = ['not_in_scad'];
    // Auto-tick laterality for an obvious mirrored/left-right switch on a fresh parse.
    for (const p of mdl.def.parameters) {
        if (!existing.has(p.name) && (mdl.warnings[p.name] || []).includes('laterality_candidate')) p.role = 'laterality';
    }

    const skipped = data.skipped.length
        ? ' ' + t('mdl.parseSkipped', { n: data.skipped.length, names: data.skipped.slice(0, 8).map(s => s.name).join(', ') + (data.skipped.length > 8 ? '…' : '') })
        : '';
    report.textContent = t('mdl.parseReport', { found: data.parameters.length, added, kept: data.parameters.length - added, missing: missing.length }) + skipped;
    renderParams();
}

// ── Save ────────────────────────────────────────────────────────────────────

async function saveModel() {
    mdlShowError('');
    if (mdl.mode === 'json') {
        try {
            const parsed = JSON.parse(document.getElementById('mdl-json').value);
            if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) throw new Error(t('mdl.jsonNotObject'));
            mdl.def = parsed;
        } catch (e) { mdlShowError(t('mdl.jsonInvalid', { msg: e.message })); return; }
    } else {
        syncFormToState();
    }
    if (mdl.isNew && !mdl.id) { mdlShowError(t('mdl.needId')); return; }
    if (!mdl.def.file) { mdlShowError(t('mdl.needMain')); return; }

    const files = mdl.files.filter(f => f.content_base64).map(f => ({ name: f.name, content_base64: f.content_base64 }));
    const body = mdl.isNew
        ? { id: mdl.id, enabled: mdl.enabled, definition: mdl.def, files }
        : { enabled: mdl.enabled, definition: mdl.def, files, removeFiles: [...mdl.removeFiles] };
    const json = JSON.stringify(body);
    if (json.length > MDL_MAX_PAYLOAD) { mdlShowError(t('mdl.tooLarge')); return; }

    const btn = document.getElementById('mdl-save-btn');
    btn.disabled = true;
    try {
        const res = await Auth.fetchWithAuth(mdl.isNew ? '/api/models/admin' : `/api/models/admin/${encodeURIComponent(mdl.id)}`, {
            method: mdl.isNew ? 'POST' : 'PUT', body: json,
        });
        const data = await res.json().catch(() => ({}));
        if (!res.ok) { mdlShowError(data.error || t('admin.tFailed')); return; }
        toast(mdl.isNew ? t('mdl.tCreated') : t('mdl.tSaved'));
        closeModelEditor();
        loadModelsTab();
    } catch {
        mdlShowError(t('admin.tNetworkError'));
    } finally {
        btn.disabled = false;
    }
}

// ── Wiring ──────────────────────────────────────────────────────────────────

function setupModelsTab() {
    document.getElementById('mdl-new-btn').addEventListener('click', () => openModelEditor());
    document.getElementById('mdl-cancel-btn').addEventListener('click', closeModelEditor);
    document.getElementById('mdl-save-btn').addEventListener('click', saveModel);
    document.getElementById('mdl-mode-form').addEventListener('click', () => setMode('form'));
    document.getElementById('mdl-mode-json').addEventListener('click', () => setMode('json'));
    document.getElementById('mdl-add-files').addEventListener('click', () => document.getElementById('mdl-file-input').click());
    document.getElementById('mdl-file-input').addEventListener('change', async (e) => {
        await addFiles([...e.target.files]);
        e.target.value = '';
    });
    document.getElementById('mdl-parse-btn').addEventListener('click', parseMainScad);
    document.getElementById('mdl-files-tbody').addEventListener('click', (e) => {
        if (e.target.classList.contains('mdl-file-remove')) removeFile(Number(e.target.closest('tr').dataset.i));
    });
    document.getElementById('mdl-add-param').addEventListener('click', () => {
        syncFormToState();
        mdl.def.parameters = mdl.def.parameters || [];
        mdl.def.parameters.push({ name: '', type: 'number', initial: 0, min: 0, max: 100, step: 1 });
        renderParams();
    });
    const params = document.getElementById('mdl-params');
    params.addEventListener('click', (e) => {
        if (!e.target.classList.contains('mdl-param-remove')) return;
        syncFormToState();
        mdl.def.parameters.splice(Number(e.target.closest('.mdl-param').dataset.i), 1);
        renderParams();
    });
    // Changing the type swaps the control set (checkbox vs min/max vs options).
    params.addEventListener('change', (e) => {
        if (e.target.dataset.f !== 'type') return;
        syncFormToState();
        const p = mdl.def.parameters[Number(e.target.closest('.mdl-param').dataset.i)];
        if (p.type === 'boolean') p.initial = !!p.initial && p.initial !== 'false';
        if (p.type === 'enum' && !p.options) p.options = [{ label: String(p.initial), value: p.initial }];
        renderParams();
        const card = document.querySelector(`#mdl-params .mdl-param[data-i="${mdl.def.parameters.indexOf(p)}"] details`);
        if (card && p.type === 'enum') card.open = true;
    });
    document.getElementById('mdl-tbody').addEventListener('click', (e) => {
        const tr = e.target.closest('tr[data-id]');
        if (!tr) return;
        const id = tr.dataset.id;
        if (e.target.classList.contains('mdl-edit')) openModelEditor(id);
        else if (e.target.classList.contains('mdl-toggle')) toggleModel(id);
        else if (e.target.classList.contains('mdl-delete')) deleteModel(id);
    });
    window.addEventListener('i18n:change', () => {
        if (document.getElementById('tab-models').classList.contains('active')) loadModelsTab();
        if (mdl && mdl.mode === 'form') { syncFormToState(); renderParams(); renderFiles(); }
    });
}
