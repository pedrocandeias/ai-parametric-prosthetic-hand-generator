/**
 * footer.js — renders the editable footer from /api/content/footer into every
 * element marked [data-footer]. The static markup already in the page acts as a
 * fallback if the fetch fails. Shared by index.html and page.html.
 */
(function () {
    function esc(s) {
        return String(s == null ? '' : s)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
    }

    function resolveHref(link) {
        if (link.type === 'page') return '/pages/' + encodeURIComponent(link.target);
        return link.target;
    }

    function buildInner(cfg) {
        const brand = `<div><h3>${esc(cfg.brandTitle)}</h3><p>${esc(cfg.tagline)}</p></div>`;
        const cols = (cfg.columns || []).map(col => {
            const links = (col.links || []).map(l => {
                const href = resolveHref(l);
                const ext = l.type === 'url' && /^https?:/i.test(l.target);
                return `<li><a href="${esc(href)}"${ext ? ' target="_blank" rel="noopener noreferrer"' : ''}>${esc(l.label)}</a></li>`;
            }).join('');
            return `<div><h3>${esc(col.title)}</h3><ul>${links}</ul></div>`;
        }).join('');
        return `<div class="hf-footer-4col-inner">`
            + `<div class="hf-footer-4col-grid">${brand}${cols}</div>`
            + `<div class="hf-footer-copy">${esc(cfg.copyright)}</div>`
            + `</div>`;
    }

    async function load() {
        const targets = document.querySelectorAll('[data-footer]');
        if (!targets.length) return;
        let cfg;
        try {
            const r = await fetch('/api/content/footer');
            if (!r.ok) return;
            cfg = await r.json();
        } catch { return; }
        const inner = buildInner(cfg);
        targets.forEach(t => { t.innerHTML = inner; });
    }

    if (document.readyState !== 'loading') load();
    else document.addEventListener('DOMContentLoaded', load);
})();
