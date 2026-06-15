'use strict';
// Content seed for Hand Fab — footer pages + footer config. Idempotent (upsert
// by slug / settings key), so it is safe to re-run. From the app root:
//   node scripts/seed-content.js [dbPath]   (defaults to ./data/app.db)
const { DatabaseSync } = require('node:sqlite');
const path = require('path');
const DB_PATH = process.argv[2] || path.join(__dirname, '..', 'data', 'app.db');

const GH = 'https://github.com/pedrocandeias/ai-parametric-prosthetic-hand-generator';
const EMAIL = 'hello@handfab.pedrocandeias.net';

const footer = {
  brandTitle: 'Hand Fab',
  tagline: 'Custom hand prosthetic configuration system',
  copyright: '© 2026 Hand Fab. All rights reserved.',
  columns: [
    { title: 'Support', links: [
      { label: 'Help Center', type: 'page', target: 'help-center' },
      { label: 'Documentation', type: 'page', target: 'documentation' },
      { label: 'Tutorials', type: 'page', target: 'tutorials' },
    ] },
    { title: 'Contact', links: [
      { label: EMAIL, type: 'url', target: 'mailto:' + EMAIL },
      { label: 'GitHub', type: 'url', target: GH },
    ] },
    { title: 'Legal', links: [
      { label: 'Privacy Policy', type: 'page', target: 'privacy-policy' },
      { label: 'Terms of Service', type: 'page', target: 'terms-of-service' },
      { label: 'Accessibility', type: 'page', target: 'accessibility' },
    ] },
  ],
};

const pages = [
  {
    slug: 'help-center',
    title: 'Help Center',
    body: `Welcome to Hand Fab. This page gets you from sign-in to a printable prosthetic hand in a few steps.

## Getting started

1. **Sign in** with the account your administrator created for you.
2. On the dashboard, choose a model (currently **Flexy Beast**, a wrist-powered hand) and select **Start New**.
3. In the configurator, open the **Parameters** tab and set the anthropometric measurements (palm breadth, finger lengths, thumb length). Hover the **ⓘ** icon next to any field to learn what it does.
4. Use the **3D Preview** to check the shape, then **Render** for a refined view.
5. When you are happy, choose **Export STL** to download the printable parts.

## Not sure of the measurements?

Open the **AI Assistant** tab and describe the person (for example: "woman, 42, 172 cm, hand length about 18 cm"). Claude suggests a starting set of dimensions you can then fine-tune. You can also seed values from an imported **population baseline**.

## Saving your work

Use the **Saved** tab to store a configuration with a name and notes, and reload it later.

## Still stuck?

- Read the [Documentation](/pages/documentation) for a full reference.
- Follow a [Tutorial](/pages/tutorials) end to end.
- Email us at **${EMAIL}** or open an issue on [GitHub](${GH}).`,
  },
  {
    slug: 'documentation',
    title: 'Documentation',
    body: `Hand Fab is a parametric design tool for 3D-printable prosthetic hands. It runs the OpenSCAD geometry engine directly in your browser (via WebAssembly), so models are generated and exported on your own machine.

## Models

The active model is **Flexy Beast** — a wrist-powered hand adapted from open-source designs (a mashup of the Parametric Cyborg Beast and the Flexy Hand). Flexible printed joints replace screws and elastics for a lighter, easier-to-assemble build.

## Parameters

All sizing is **anthropometric** — driven by real hand measurements in millimetres:

- **Palm breadth** — knuckle-to-knuckle width; drives the overall hand scale.
- **Finger lengths** — index, middle, ring, pinky, measured MCP crease to tip.
- **Thumb length** — controls thumb opposition.
- **Hardware / joints** — flex-joint hole diameter and slot thickness.
- **Gauntlet** — optional forearm cuff that pins to the wrist.

Every parameter has an **ⓘ** tooltip explaining its objective and the effect of changing it.

## AI assistant & baselines

Describe a person in plain language and the AI assistant proposes a starting set of dimensions. Imported **population datasets** let you seed the sliders from a demographic group, then refine. AI suggestions are a starting point — always review them.

## Exporting & printing

**Export STL** produces the printable parts (palm, fingers split into base/tip, thumb, and optional gauntlet). Print in PLA or PETG; the flexible joints are designed to print flat and assemble afterwards.

## Source & licensing

Hand Fab is open source. The code, model sources, and the designs it builds on are available on [GitHub](${GH}). The underlying hand designs carry their own open-source licences — see the repository.`,
  },
  {
    slug: 'tutorials',
    title: 'Tutorials',
    body: `Step-by-step walkthroughs for common tasks.

## Your first hand in 10 minutes

1. Sign in and select **Flexy Beast → Start New**.
2. Open **Parameters** and set **Palm breadth** to the wearer's measured knuckle-to-knuckle width.
3. Set each **finger length** and the **thumb length**.
4. Watch the **3D Preview** update, then press **Render**.
5. Press **Export STL** and save the files.
6. Slice and print (see below).

## Measuring a hand

- **Palm breadth:** measure straight across the back of the hand, index knuckle to pinky knuckle, fingers together.
- **Finger length:** from the knuckle crease (MCP) to the fingertip, finger straight.
- **Thumb length:** from the thumb's base crease to the tip.

Record everything in **millimetres**. When in doubt, measure twice.

## Using the AI assistant

If you only know rough details, open **AI Assistant**, describe the person, and press **Get AI Suggestions**. Apply the result, then adjust individual sliders. Treat the suggestion as a starting point, not a final fit.

## Printing & assembly

- Material: **PLA** or **PETG**.
- Print the fingers and palm flat; the living-hinge joints flex after printing.
- Optionally print the **gauntlet** and pin it to the wrist with the printed wrist pin.
- Test the range of motion before final tensioning.

## Going further

The full design is open source — fork it, study the geometry, or contribute on [GitHub](${GH}).`,
  },
  {
    slug: 'privacy-policy',
    title: 'Privacy Policy',
    body: `Hand Fab is a free, **open-source** tool for designing 3D-printable prosthetic hands ([source on GitHub](${GH})). This page describes, in plain terms, how the hosted instance handles data. It is offered openly and you use it at your own discretion and responsibility.

## What we collect

- **Account:** your username and email. Passwords are stored only as a salted **bcrypt hash** — never in plain text.
- **Your designs:** the model parameters and notes you choose to save.
- **Measurements you enter:** anthropometric numbers and any free-text description you type for sizing. Please keep this to measurements — do not enter names or identifying patient details.
- **Basic technical logs:** e.g. IP address and timestamps, kept briefly for security and reliability.

## AI suggestions

If you use the AI assistant, the text you type is sent to the AI provider (**Anthropic**) to generate sizing suggestions. Don't include identifying information in it.

## How it's used

Only to run your account, store your designs, provide suggestions, keep the service secure, and answer support requests. We do **not** sell your data or use it for advertising.

## Security & honesty

Passwords are hashed, access is role-based, and traffic uses HTTPS. That said, this is a small open-source project provided **as is**, with no guarantees — use it at your own risk and don't store anything you can't afford to lose.

## Removing your data

Want your account or data deleted? Email **${EMAIL}** and we'll remove it.

## Self-hosting

Because Hand Fab is open source, anyone can run their own copy. If you use an instance hosted by someone else, that operator — not us — controls the data on it.

## Contact

Questions? **${EMAIL}**, or open an issue on [GitHub](${GH}).`,
  },
  {
    slug: 'terms-of-service',
    title: 'Terms of Service',
    body: `Hand Fab is a free, **open-source** project ([source on GitHub](${GH})), shared in the hope that it's useful. Please read this before relying on it.

## Use at your own risk

Hand Fab is provided **"as is", with no warranty of any kind** — express or implied — and **no guarantee of fitness for any purpose**. You use it, and anything you make with it, **entirely at your own risk and responsibility**. To the maximum extent allowed by law, the authors and contributors accept **no liability** for any loss, injury, or damage arising from its use.

## Not a medical device

> Hand Fab is a **design and prototyping tool — not a medical device and not clinical advice**. Its output is design files only, not approved or certified by any regulator. Anyone who prints, fits, or uses a device based on these files does so at their own risk and should have it evaluated by a qualified prosthetist or clinician. You are solely responsible for the safety and suitability of anything you produce.

## Open source & licensing

The software and the hand designs it builds on are open source under their respective licences — see [GitHub](${GH}). You are free to use, study, modify, and self-host it under those terms. Designs you create from your own measurements are yours.

## Your responsibilities

Use Hand Fab lawfully, don't attempt to break or abuse the service, and keep your account credentials secure. You are responsible for activity under your account.

## Availability & changes

This is a community/hobby project. It may change, break, or go offline at any time, with no guarantee of availability. These terms may be updated; continued use means you accept the current version.

## Contact

**${EMAIL}**, or open an issue on [GitHub](${GH}).`,
  },
  {
    slug: 'accessibility',
    title: 'Accessibility',
    body: `We want Hand Fab to be usable by as many people as possible, including people who use assistive technologies.

## Our commitment

We aim to follow the **Web Content Accessibility Guidelines (WCAG) 2.1, Level AA** as a target standard, and we treat accessibility as an ongoing effort rather than a one-time task.

## What we do

- Interactive controls are reachable and operable by **keyboard**.
- Buttons and icons carry **text labels / ARIA labels** for screen readers.
- We aim for readable text sizes and sufficient colour contrast.
- Parameter fields include descriptive help text.

## Known limitations

- The **interactive 3D preview** is inherently visual and is not fully describable to screen readers. The numeric parameters remain fully accessible, and exported files do not depend on the preview.
- Some advanced areas are still being improved.

## Feedback

If you hit an accessibility barrier, please tell us — your feedback directly shapes our fixes. Email **${EMAIL}** with the page, what you were trying to do, and the assistive technology you use. You can also open an issue on [GitHub](${GH}).

We will do our best to respond and to provide the information or function you need in an accessible way.`,
  },
];

const db = new DatabaseSync(DB_PATH);
const up = db.prepare(
  `INSERT INTO pages (slug, title, body, is_published) VALUES (?, ?, ?, 1)
   ON CONFLICT(slug) DO UPDATE SET title = excluded.title, body = excluded.body, is_published = 1, updated_at = datetime('now')`
);
for (const p of pages) up.run(p.slug, p.title, p.body);

db.prepare(
  `INSERT INTO site_settings (key, value, updated_at) VALUES ('footer', ?, datetime('now'))
   ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = datetime('now')`
).run(JSON.stringify(footer));

console.log('seeded pages:', pages.map(p => p.slug).join(', '));
console.log('total pages now:', db.prepare('SELECT count(*) c FROM pages').get().c);
console.log('footer columns:', JSON.parse(db.prepare("SELECT value FROM site_settings WHERE key='footer'").get().value).columns.map(c => c.title).join(', '));
