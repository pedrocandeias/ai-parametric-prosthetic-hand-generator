/**
 * markdown.js — tiny, safe Markdown → HTML renderer.
 * HTML in the source is escaped first, so admin-authored pages can't inject
 * raw markup/scripts. Supports headings, bold, italic, inline code, code
 * fences, links, unordered/ordered lists, blockquotes, hr, and paragraphs.
 * Exposes a global `renderMarkdown(src)`.
 */
(function (global) {
    function escapeHtml(s) {
        return String(s)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
    }

    function inline(s) {
        s = escapeHtml(s);
        s = s.replace(/`([^`]+)`/g, (m, c) => `<code>${c}</code>`);
        s = s.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
        s = s.replace(/(^|[^*])\*([^*\n]+)\*/g, '$1<em>$2</em>');
        // [text](url) — only allow http(s), mailto, or root-relative links
        s = s.replace(/\[([^\]]+)\]\(([^)\s]+)\)/g, (m, text, url) => {
            if (!/^(https?:\/\/|mailto:|\/)/i.test(url)) return m;
            const ext = /^https?:/i.test(url);
            return `<a href="${url}"${ext ? ' target="_blank" rel="noopener noreferrer"' : ''}>${text}</a>`;
        });
        return s;
    }

    const SPECIAL = /^(#{1,4}\s|```|>\s?|\s*[-*+]\s+|\s*\d+\.\s+|(?:---|\*\*\*|___)\s*$)/;

    function render(src) {
        const lines = String(src == null ? '' : src).replace(/\r\n/g, '\n').split('\n');
        let html = '';
        let i = 0;
        while (i < lines.length) {
            const line = lines[i];

            if (/^```/.test(line)) {
                const buf = [];
                i++;
                while (i < lines.length && !/^```/.test(lines[i])) { buf.push(escapeHtml(lines[i])); i++; }
                i++;
                html += `<pre><code>${buf.join('\n')}</code></pre>`;
                continue;
            }
            const h = line.match(/^(#{1,4})\s+(.*)$/);
            if (h) { const lvl = h[1].length; html += `<h${lvl}>${inline(h[2])}</h${lvl}>`; i++; continue; }
            if (/^(?:---|\*\*\*|___)\s*$/.test(line)) { html += '<hr>'; i++; continue; }
            if (/^>\s?/.test(line)) {
                const buf = [];
                while (i < lines.length && /^>\s?/.test(lines[i])) { buf.push(lines[i].replace(/^>\s?/, '')); i++; }
                html += `<blockquote>${render(buf.join('\n'))}</blockquote>`;
                continue;
            }
            if (/^\s*[-*+]\s+/.test(line)) {
                const items = [];
                while (i < lines.length && /^\s*[-*+]\s+/.test(lines[i])) { items.push(inline(lines[i].replace(/^\s*[-*+]\s+/, ''))); i++; }
                html += `<ul>${items.map(x => `<li>${x}</li>`).join('')}</ul>`;
                continue;
            }
            if (/^\s*\d+\.\s+/.test(line)) {
                const items = [];
                while (i < lines.length && /^\s*\d+\.\s+/.test(lines[i])) { items.push(inline(lines[i].replace(/^\s*\d+\.\s+/, ''))); i++; }
                html += `<ol>${items.map(x => `<li>${x}</li>`).join('')}</ol>`;
                continue;
            }
            if (/^\s*$/.test(line)) { i++; continue; }

            const para = [];
            while (i < lines.length && !/^\s*$/.test(lines[i]) && !SPECIAL.test(lines[i])) { para.push(lines[i]); i++; }
            html += `<p>${inline(para.join('\n')).replace(/\n/g, '<br>')}</p>`;
        }
        return html;
    }

    global.renderMarkdown = render;
})(typeof window !== 'undefined' ? window : this);
