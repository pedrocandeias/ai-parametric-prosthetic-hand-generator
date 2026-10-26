/**
 * footer.js — renders the editable footer from /api/content/footer into every
 * element marked [data-footer]. The static markup already in the page acts as a
 * fallback if the fetch fails. Shared by index.html and page.html.
 *
 * Footer text is admin-edited and stored in one language, so known strings are
 * translated via 'footer.text.<original>' keys in translations.js; anything
 * without a key (custom labels, emails) is shown as stored.
 */
(function () {
    function esc(s) {
        return String(s == null ? '' : s)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
    }

    function tr(s) {
        if (!window.I18n || s == null) return s;
        const key = 'footer.text.' + s;
        const v = I18n.t(key);
        return v === key ? s : v;
    }

    function resolveHref(link) {
        if (link.type === 'page') return '/pages/' + encodeURIComponent(link.target);
        return link.target;
    }

    function buildInner(cfg) {
        const brand = `<div><h3>${esc(tr(cfg.brandTitle))}</h3><p>${esc(tr(cfg.tagline))}</p></div>`;
        const cols = (cfg.columns || []).map(col => {
            const links = (col.links || []).map(l => {
                const href = resolveHref(l);
                const ext = l.type === 'url' && /^https?:/i.test(l.target);
                return `<li><a href="${esc(href)}"${ext ? ' target="_blank" rel="noopener noreferrer"' : ''}>${esc(tr(l.label))}</a></li>`;
            }).join('');
            return `<div><h3>${esc(tr(col.title))}</h3><ul>${links}</ul></div>`;
        }).join('');
        return `<div class="hf-footer-4col-inner">`
            + `<div class="hf-footer-4col-grid">${brand}${cols}</div>`
            + `<div class="hf-footer-copy">${esc(tr(cfg.copyright))}</div>`
            + `</div>`;
    }

    let cfg = null;

    function render() {
        if (!cfg) return;
        const inner = buildInner(cfg);
        document.querySelectorAll('[data-footer]').forEach(t => { t.innerHTML = inner; });
    }

    async function load() {
        if (!document.querySelectorAll('[data-footer]').length) return;
        try {
            const r = await fetch('/api/content/footer');
            if (!r.ok) return;
            cfg = await r.json();
        } catch { return; }
        render();
    }

    window.addEventListener('i18n:change', render);

    if (document.readyState !== 'loading') load();
    else document.addEventListener('DOMContentLoaded', load);
})();
