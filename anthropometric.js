/**
 * anthropometric.js — Anthropometric Reference Data Importer.
 * Admin backoffice only. Loaded by admin.html.
 *
 * Anthropometric profiles are population-level reference datasets
 * (e.g. "Northern European adult female, 50th percentile") — not
 * individual patient records.
 *
 * Public API (used by admin.js):
 *   AnthropometricImporter.openNew()          — open blank import modal
 *   AnthropometricImporter.loadProfiles(q)    — fetch filtered profile list
 *   AnthropometricImporter.deleteProfile(id)  — delete a profile
 */

const AnthropometricImporter = (() => {

    // ── Open / close ──────────────────────────────────────────────────────────

    function openNew() {
        resetModal();
        const modal = document.getElementById('anthro-modal');
        if (modal) modal.style.display = 'flex';
    }

    function close() {
        const modal = document.getElementById('anthro-modal');
        if (modal) modal.style.display = 'none';
    }

    function resetModal() {
        document.querySelectorAll('#anthro-modal input[type=number], #anthro-modal input[type=text]')
            .forEach(el => { el.value = ''; });
        const ta = document.getElementById('anthro-import-text');
        if (ta) ta.value = '';
        const res = document.getElementById('anthro-results');
        if (res) { res.style.display = 'none'; res.innerHTML = ''; }
        setStatus('', '');
        const saveBtn = document.getElementById('anthro-save-btn');
        if (saveBtn) saveBtn.disabled = false;
        switchTab('manual');
    }

    // ── Tab switching ─────────────────────────────────────────────────────────

    function switchTab(name) {
        document.querySelectorAll('.anthro-tab-btn').forEach(b =>
            b.classList.toggle('active', b.dataset.tab === name));
        document.querySelectorAll('.anthro-tab-panel').forEach(p =>
            p.style.display = p.dataset.panel === name ? 'block' : 'none');
    }

    // ── Collect data ──────────────────────────────────────────────────────────

    function v(id)  { const el = document.getElementById(id); return el ? el.value.trim() : ''; }
    function nv(id) { const val = parseFloat(v(id)); return isNaN(val) ? undefined : val; }

    function collectDemographicMeta(prefix = '') {
        const groupName = v(`anthro-${prefix}group-name`);
        if (!groupName) throw new Error('Group Name is required');

        const gender = v(`anthro-${prefix}gender`) || undefined;

        return {
            group_name:   groupName,
            country:      v(`anthro-${prefix}country`)     || undefined,
            gender,
            age_group:    v(`anthro-${prefix}age-group`)   || undefined,
            percentile:   v(`anthro-${prefix}percentile`)  || undefined,
            sample_size:  prefix === '' ? (nv('anthro-sample-size') || undefined) : undefined,
            data_source:  v(`anthro-${prefix}data-source`) || undefined,
            notes:        prefix === '' ? (v('anthro-notes') || undefined) : undefined,
        };
    }

    function collectManualData() {
        const meta = collectDemographicMeta('');
        const unit = v('anthro-unit') || 'mm';

        const data = {};
        const fields = {
            // ── Hand measurements (primary) ──────────────────────────────────
            palm_length:               'anthro-palm-length',
            palm_breadth:              'anthro-palm-width',       // breadth = width alias
            palm_thickness:            'anthro-palm-thickness',   // new primary
            average_finger_width:      'anthro-avg-finger-width', // new primary
            wrist_circumference:       'anthro-wrist-circ',
            // ── Finger total lengths (new primary inputs) ────────────────────
            thumb_length_total:        'anthro-thumb-total',
            index_length_total:        'anthro-idx-total',
            middle_length_total:       'anthro-mid-total',
            ring_length_total:         'anthro-ring-total',
            little_length_total:       'anthro-pinky-total',
            // ── Finger segment breakdown (optional detail) ───────────────────
            finger_index_proximal:     'anthro-idx-prox',
            finger_index_middle:       'anthro-idx-mid',
            finger_index_distal:       'anthro-idx-dist',
            finger_index_circumference: 'anthro-idx-circ',
            finger_middle_proximal:    'anthro-mid-prox',
            finger_middle_middle:      'anthro-mid-mid',
            finger_middle_distal:      'anthro-mid-dist',
            finger_middle_circumference: 'anthro-mid-circ',
            finger_ring_proximal:      'anthro-ring-prox',
            finger_ring_middle:        'anthro-ring-mid',
            finger_ring_distal:        'anthro-ring-dist',
            finger_ring_circumference: 'anthro-ring-circ',
            finger_pinky_proximal:     'anthro-pinky-prox',
            finger_pinky_middle:       'anthro-pinky-mid',
            finger_pinky_distal:       'anthro-pinky-dist',
            finger_pinky_circumference: 'anthro-pinky-circ',
            // ── Residual limb (primary) ──────────────────────────────────────
            residual_length:                 'anthro-stump-length',
            residual_circumference_proximal: 'anthro-stump-circ-prox',  // new primary
            residual_circumference_distal:   'anthro-stump-circ-dist',  // new primary
        };

        for (const [key, elId] of Object.entries(fields)) {
            const val = nv(elId);
            if (val !== undefined) data[key] = { value: val, unit };
        }

        return {
            format: 'form',
            data,
            meta: {
                ...meta,
                tolerance_preference: v('anthro-tolerance') || 'standard',
                hardware_standard:    v('anthro-hardware')  || 'm3',
                measurement_source:   'manual',
            },
            default_unit: unit,
        };
    }

    function collectImportData() {
        const meta = collectDemographicMeta('import-');
        const fmt  = v('anthro-import-format') || 'csv';
        const text = v('anthro-import-text');
        const unit = v('anthro-import-unit') || 'mm';

        if (!text) throw new Error('Paste or type your data above');

        let data;
        if (fmt === 'json') {
            try { data = JSON.parse(text); } catch { throw new Error('Invalid JSON'); }
        } else {
            data = text;
        }

        return {
            format: fmt,
            ...(fmt === 'csv' ? { csv_text: data } : { data }),
            default_unit: unit,
            meta: {
                ...meta,
                tolerance_preference: v('anthro-import-tol') || 'standard',
                hardware_standard:    v('anthro-import-hw')  || 'm3',
                measurement_source:   fmt,
            },
        };
    }

    // ── Process ───────────────────────────────────────────────────────────────

    async function processData(save = false) {
        setStatus('Processing…', '');
        document.getElementById('anthro-process-btn').disabled = true;
        document.getElementById('anthro-save-btn').disabled    = true;

        try {
            const activeTab = document.querySelector('.anthro-tab-btn.active')?.dataset.tab || 'manual';
            const payload   = activeTab === 'import' ? collectImportData() : collectManualData();

            const url = save ? '/api/anthropometric' : '/api/anthropometric/preview';
            const res = await Auth.fetchWithAuth(url, { method: 'POST', body: JSON.stringify(payload) });
            const result = await res.json();
            if (!res.ok) throw new Error(result.error || 'Processing failed');

            renderResults(result);

            if (save) {
                setStatus(`Saved — profile #${result.id}`, 'success');
                document.getElementById('anthro-save-btn').disabled = true;
                if (typeof window.loadAnthroProfiles === 'function') window.loadAnthroProfiles();
            } else {
                setStatus('Preview ready — click "Save Profile" to persist', 'success');
                document.getElementById('anthro-save-btn').disabled = false;
            }
        } catch (err) {
            setStatus(err.message, 'error');
            document.getElementById('anthro-save-btn').disabled = false;
        } finally {
            document.getElementById('anthro-process-btn').disabled = false;
        }
    }

    // ── Render results ────────────────────────────────────────────────────────

    function renderResults(result) {
        const panel = document.getElementById('anthro-results');
        if (!panel) return;

        const geom = result.geometry_parameters;
        const ctx  = result.ai_context;

        const geomRows = Object.entries(geom)
            .map(([k, val]) => `<tr><td>${k}</td><td>${typeof val === 'number' ? val.toFixed(3) : val}</td></tr>`)
            .join('');

        const missingHtml = ctx.missing_measurements.length
            ? ctx.missing_measurements.map(m => `<li>${m}</li>`).join('')
            : '<li style="color:#27ae60">None — full dataset</li>';

        const notesHtml = ctx.notes.map(n => `<li>${escHtml(n)}</li>`).join('');
        const uColor = { low: '#27ae60', medium: '#f39c12', high: '#e74c3c' }[ctx.uncertainty] || '#888';

        panel.innerHTML = `
            <div class="anthro-results-grid">
                <div class="anthro-result-card">
                    <h4>Reference Geometry Parameters</h4>
                    <p style="font-size:0.8rem;color:#888;margin-bottom:0.5rem">
                        Computed from population averages. Use as a starting point for patient configuration.
                    </p>
                    <table class="anthro-param-table">
                        <thead><tr><th>Parameter</th><th>Value</th></tr></thead>
                        <tbody>${geomRows}</tbody>
                    </table>
                </div>
                <div class="anthro-result-card">
                    <h4>Dataset Quality</h4>
                    <p style="margin-bottom:0.5rem;font-size:0.85rem">
                        <strong>Completeness:</strong>
                        <span style="color:${uColor};font-weight:600;text-transform:capitalize">${ctx.uncertainty}</span>
                        &nbsp;|&nbsp; <strong>Source:</strong> ${escHtml(ctx.measurement_source)}
                        &nbsp;|&nbsp; <strong>Hardware:</strong> ${escHtml(ctx.hardware_standard).toUpperCase()}
                    </p>
                    <p style="font-size:0.82rem;font-weight:600;margin-bottom:0.2rem">Missing measurements:</p>
                    <ul style="font-size:0.8rem;padding-left:1.25rem;margin-bottom:0.6rem">${missingHtml}</ul>
                    <p style="font-size:0.82rem;font-weight:600;margin-bottom:0.2rem">Notes:</p>
                    <ul style="font-size:0.8rem;padding-left:1.25rem">${notesHtml}</ul>
                </div>
            </div>`;
        panel.style.display = 'block';
    }

    // ── Load / delete ─────────────────────────────────────────────────────────

    async function loadProfiles({ country, gender, age_group } = {}) {
        const params = new URLSearchParams();
        if (country)   params.set('country',   country);
        if (gender)    params.set('gender',    gender);
        if (age_group) params.set('age_group', age_group);

        const url = '/api/anthropometric' + (params.toString() ? '?' + params : '');
        const res = await Auth.fetchWithAuth(url);
        if (!res.ok) return [];
        return await res.json();
    }

    async function deleteProfile(id) {
        const res = await Auth.fetchWithAuth(`/api/anthropometric/${id}`, { method: 'DELETE' });
        const data = await res.json();
        if (!res.ok) throw new Error(data.error || 'Delete failed');
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    function setStatus(msg, type) {
        const el = document.getElementById('anthro-status');
        if (!el) return;
        el.textContent = msg;
        el.className   = 'anthro-status' + (type ? ' ' + type : '');
    }

    function escHtml(s) {
        return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
    }

    // ── Boot ──────────────────────────────────────────────────────────────────

    document.addEventListener('DOMContentLoaded', () => {
        document.getElementById('anthro-modal')
            ?.addEventListener('click', e => { if (e.target === e.currentTarget) close(); });
        document.getElementById('anthro-close-btn')
            ?.addEventListener('click', close);

        document.querySelectorAll('.anthro-tab-btn').forEach(btn =>
            btn.addEventListener('click', () => switchTab(btn.dataset.tab)));

        document.getElementById('anthro-process-btn')
            ?.addEventListener('click', () => processData(false));
        document.getElementById('anthro-save-btn')
            ?.addEventListener('click', () => processData(true));

        document.querySelectorAll('.anthro-section-toggle').forEach(btn => {
            btn.addEventListener('click', () => {
                const body = btn.closest('.anthro-section').querySelector('.anthro-section-body');
                if (!body) return;
                const isOpen = body.style.display !== 'none';
                body.style.display = isOpen ? 'none' : 'block';
                btn.textContent    = isOpen ? '▶' : '▼';
            });
        });
    });

    return { openNew, close, loadProfiles, deleteProfile };
})();
