---
description: Commit, push, and deploy the current changes (with safety checks)
argument-hint: [optional commit message]
---

You are running the **CPD** (Commit → Push → Deploy) workflow for this repo. Follow
these steps in order. STOP and ask the user if any safety check fails.

If `$ARGUMENTS` is non-empty, use it as the commit subject; otherwise write a clear
Conventional-Commits subject yourself from the diff.

## 1. Review the change
- `git status --short` and `git diff --stat` to see what changed.
- Identify which files are **yours/intended** vs **untracked data you should NOT commit**
  (reference STL/mesh sets, scratch output, large binaries the user dropped in `tests/`,
  e.g. `tests/flexible-flyer-master/`, `tests/flexy-beast-original/`, `tests/*.stl`,
  `tests/UnLimbited_Arm_*`, `*_assembly.scad`). When unsure whether a file is intended,
  ask — do not blindly `git add -A`.

## 2. Safety checks (abort on failure)
- **No stray scratch in the source tree:** `find . -path ./deploy -prune -o -path ./node_modules -prune -o -path ./.git -prune -o \( -type d \( -name 'out_*' -o -name 'stl_*' \) \) -print`. If anything shows up under a model/source dir, it must be deleted before deploying (the deployer copies everything except its hard-excludes, so scratch would ship to prod). The 2026-06-28 deploy nearly shipped `models/active/paraglider_hand/out_pg2/` — always check.
- **CHANGELOG + version:** per `CLAUDE.md`, every code change needs a `CHANGELOG.md` entry and a matching `package.json` `version`. If a code file changed but CHANGELOG/version weren't bumped, stop and add them (or confirm with the user).
- **Asset cache-buster:** if any front-end JS changed (`app.js`, `translations.js`, `i18n.js`, `auth.js`, `footer.js`, `screens.js`), the `?v=<version>` query on the `<script>` tags in `index.html` must match the new `package.json` version — otherwise returning browsers serve stale cached JS and new strings/i18n keys render raw (e.g. `cfg.tabColors`). Bump them together.

## 3. Commit
- If on the default branch (`main`), create a feature branch first; otherwise commit on the current branch.
- `git add` only the intended files (explicit paths — never the untracked data from step 1).
- Commit. End the message body with:
  `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`

## 4. Push
- `git push -u origin <current-branch>`.

## 5. Deploy (production cPanel — `pedrocandeias.net`)
- **Dry-run first:** `./deploy.sh deploy --dry-run`. Print the transferred-file list and
  confirm it contains ONLY intended files (no scratch, no secrets, no `data/`). Abort if not.
- **Deploy:** `./deploy.sh deploy --yes` (it takes a remote DB+code backup first and runs a
  secret/`data/` safety check).

## 6. Restart if server code changed
- If any `server/**` file changed, the Passenger app must reload (client-only changes —
  `app.js`, `index.html`, `models/`, `.scad`, `docs/` — go live on refetch, no restart):
  `ssh -o BatchMode=yes pedrocan@pedrocandeias.net "mkdir -p /home/pedrocan/public_html/sites/handfab/tmp && touch /home/pedrocan/public_html/sites/handfab/tmp/restart.txt"`
  then hit the site once to trigger the reload.

## 7. Health check
- `curl -s -o /dev/null -w "%{http_code}\n" https://pedrocandeias.net/sites/handfab/api/setup/status` — expect `200`. A clean 200 after a server-code change also confirms the new code loaded without a boot error.

## 8. Report
Summarise: branch, commit hash/subject, files deployed, whether a restart was needed/done,
and the health-check result.
