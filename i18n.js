/**
 * i18n.js — tiny vanilla i18n for Hand Fab.
 * Translations live in window.TRANSLATIONS (translations.js, loaded first).
 *
 * Usage:
 *   - Static HTML:  <span data-i18n="nav.help">Help</span>
 *                   data-i18n-placeholder / data-i18n-title / data-i18n-aria-label
 *   - JS:           t('dash.title')  or  t('msg.welcome', { name })
 *   - Switch:       I18n.setLang('pt')
 *   - React to it:  window.addEventListener('i18n:change', () => reRender())
 *
 * The active language is remembered in localStorage and otherwise guessed from
 * the browser. apply() runs on DOMContentLoaded and on every language change.
 */
const I18n = (() => {
    const DEFAULT = 'en';
    const SUPPORTED = ['en', 'pt'];
    const NAMES = { en: 'English', pt: 'Português' };

    function detect() {
        const stored = localStorage.getItem('lang');
        if (stored && SUPPORTED.includes(stored)) return stored;
        const nav = (navigator.language || navigator.userLanguage || 'en').slice(0, 2).toLowerCase();
        return SUPPORTED.includes(nav) ? nav : DEFAULT;
    }

    let lang = detect();

    function table(l) { return (window.TRANSLATIONS && window.TRANSLATIONS[l]) || {}; }

    function t(key, vars) {
        let s = table(lang)[key];
        if (s == null) s = table(DEFAULT)[key];   // fall back to source language
        if (s == null) s = key;                    // last resort: show the key
        if (vars) for (const k in vars) s = s.split('{' + k + '}').join(vars[k]);
        return s;
    }

    function apply(root) {
        root = root || document;
        root.querySelectorAll('[data-i18n]').forEach(el => { el.textContent = t(el.getAttribute('data-i18n')); });
        root.querySelectorAll('[data-i18n-html]').forEach(el => { el.innerHTML = t(el.getAttribute('data-i18n-html')); });
        root.querySelectorAll('[data-i18n-placeholder]').forEach(el => { el.setAttribute('placeholder', t(el.getAttribute('data-i18n-placeholder'))); });
        root.querySelectorAll('[data-i18n-title]').forEach(el => { el.setAttribute('title', t(el.getAttribute('data-i18n-title'))); });
        root.querySelectorAll('[data-i18n-aria-label]').forEach(el => { el.setAttribute('aria-label', t(el.getAttribute('data-i18n-aria-label'))); });
        document.documentElement.lang = lang;
    }

    function setLang(l) {
        if (!SUPPORTED.includes(l) || l === lang) return;
        lang = l;
        try { localStorage.setItem('lang', l); } catch (_) { /* ignore */ }
        apply();
        window.dispatchEvent(new CustomEvent('i18n:change', { detail: { lang } }));
    }

    function wireSwitchers() {
        document.querySelectorAll('.lang-switcher').forEach(sel => {
            sel.value = lang;
            sel.addEventListener('change', e => setLang(e.target.value));
        });
    }

    function init() { apply(); wireSwitchers(); }
    if (document.readyState !== 'loading') init();
    else document.addEventListener('DOMContentLoaded', init);

    // Keep every switcher in sync when the language changes anywhere.
    window.addEventListener('i18n:change', () => {
        document.querySelectorAll('.lang-switcher').forEach(sel => { sel.value = lang; });
    });

    return { t, setLang, getLang: () => lang, apply, SUPPORTED, DEFAULT, NAMES };
})();
window.I18n = I18n;
window.t = (key, vars) => I18n.t(key, vars);
