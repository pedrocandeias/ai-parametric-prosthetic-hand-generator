# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: cms-i18n.spec.js >> CMS i18n admin UI + viewer switcher
- Location: tests/cms-i18n.spec.js:3:1

# Error details

```
Error: locator.click: Target page, context or browser has been closed
Call log:
  - waiting for locator('.tab-btn[data-tab="content"]')
    - locator resolved to <button class="tab-btn" data-tab="content" data-i18n="admin.tabContent">Footer & Pages</button>
  - attempting click action
    - waiting for element to be visible, enabled and stable
    - element is visible, enabled and stable
    - scrolling into view if needed
    - done scrolling
  - element was detached from the DOM, retrying
    - waiting for" https://handfab.pedrocandeias.net/" navigation to finish...
    - navigated to "https://handfab.pedrocandeias.net/"

```

```
Error: write EPIPE
```