# Quick Start

## Prerequisites

- **Node.js 18+** — [nodejs.org](https://nodejs.org/)
- An Anthropic or OpenAI API key (optional — required for AI suggestions)

---

## Step 1 — Install & Configure

```bash
cd ai-parametric-prosthetic-hand-generator

# Install dependencies
npm install

# Create your environment file
cp .env.example .env
```

Edit `.env` and set at minimum:

```bash
# Generate a secure secret:
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

JWT_SECRET=<paste the output here>
ANTHROPIC_API_KEY=sk-ant-...     # optional
OPENAI_API_KEY=sk-...            # optional
```

---

## Step 2 — Start the Server

```bash
npm start
```

Or use the shell script:

```bash
./start-server.sh
```

Server starts at **http://localhost:3000**

---

## Step 3 — Create the First Admin

On first run the app shows a **First-Run Setup** screen in the browser.

Fill in a username, email, and password to create the administrator account.

**Alternative (CLI):**
```bash
node scripts/create-admin.js admin admin@example.com MyPassword123
```

---

## Step 4 — Use the App

1. Log in with the admin account
2. Select **Fingerator - Prosthetic Finger** from the model dropdown
3. Adjust parameter sliders — the 3D preview re-renders automatically
4. To get AI parameter suggestions:
   - Select AI provider (Claude or GPT-4)
   - Type anthropometric data, e.g.: `woman, 42 years old, 75kg, 172cm height, arm length 65cm`
   - Click **Get AI Suggestions**
5. Give the config a name and click **Save** to store it
6. Click **Export STL** to download the model for printing

---

## Step 5 — Create More Users (optional)

Open the **Admin Panel** from the user menu (top-right).

- Create a **Tech** user for each prosthetist
- Create **User** accounts for patients
- On the **Tech Assignments** tab, assign patients to techs

Techs can then log in and see the saved configurations of their assigned patients.

---

## Interface Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│ Prosthetic Hand AI Parameter Generator          [username ▼] [Sign In]│
└─────────────────────────────────────────────────────────────────────┘
┌─────────────────────┬───────────────────────────────────────────────┐
│ Select Model:       │  3D Preview                                    │
│ [Fingerator ▼]      │              [Reset] [Render] [Export STL]     │
├─────────────────────┤                                                │
│ Fingerator -        ├────────────────────────────────────────────────│
│ Prosthetic Finger   │                                                │
├─────────────────────┤                                                │
│ Saved Configs       │         (interactive 3D model)                 │
│ [Select config ▼]   │                                                │
│ Name: [__________]  │                                                │
│ Notes:[__________]  │                                                │
│ [Load][Save][Delete]│                                                │
├─────────────────────┤                                                │
│ AI Parameter        │                                                │
│ Assistant           │                                                │
│ Provider:[Claude ▼] │                                                │
│ [patient data...]   │                                                │
│ [Get AI Suggestions]│                                                │
├─────────────────────┤                                                │
│ === Scale ===       │                                                │
│ global_scale: 1.25  │                                                │
│ [━━━━━●━━━━━━━━]    │                                                │
│                     │                                                │
│ === Items to Print  │                                                │
│ [✓] long fingers    │                                                │
│ [ ] short fingers   │                                                │
└─────────────────────┴────────────────────────────────────────────────│
│ Ready                                                                │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Adding Your Own Models

### 1. Create an OpenSCAD file

Place it in `models/mymodel.scad`:

```openscad
/* [Dimensions] */
scale = 1.0;
wall = 2;

/* [Features] */
hollow = false;
```

### 2. Register it in `models/models-config.json`

```json
{
  "models": [
    {
      "id": "mymodel",
      "name": "My Model",
      "description": "A custom parametric model",
      "file": "mymodel.scad",
      "parameters": [
        {
          "name": "scale",
          "type": "number",
          "initial": 1.0,
          "min": 0.5,
          "max": 3.0,
          "step": 0.01,
          "caption": "Overall scale factor",
          "group": "Dimensions"
        },
        {
          "name": "hollow",
          "type": "boolean",
          "initial": false,
          "caption": "Make hollow",
          "group": "Features"
        }
      ]
    }
  ]
}
```

### 3. Restart the server

Your model appears in the dropdown immediately.

---

## Quick Reference

| Task | Command |
|------|---------|
| Start server | `npm start` |
| Dev (auto-restart) | `npm run dev` |
| Create first admin (CLI) | `node scripts/create-admin.js <user> <email> <pass>` |
| Generate JWT secret | `node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"` |

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Server won't start | Check `.env` has `JWT_SECRET` set |
| First-run setup not showing | Clear cookies and reload |
| AI suggestions fail | Check `ANTHROPIC_API_KEY` or `OPENAI_API_KEY` in `.env` |
| 3D viewer blank | Check browser console; try Chrome if using Firefox |
| Login loop | Clear `refresh_token` cookie; regenerate `JWT_SECRET` |

Full details: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
