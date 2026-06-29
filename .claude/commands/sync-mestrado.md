---
description: Sync the AI-sizing reports into the mestrado (thesis) docs repo and commit
argument-hint: [optional commit message]
---

You are running **sync-mestrado**: copy this project's AI-sizing report docs into the
thesis repo at `/home/pec/dev/mestrado/docs/` and commit them there. Use this after
updating any of the reports so the thesis copy stays current.

If `$ARGUMENTS` is non-empty, use it as the mestrado commit subject; otherwise use the
default below.

## Paths
- Source: `/home/pec/dev/ai-parametric-prosthetic-hand-generator/docs/`
- Target: `/home/pec/dev/mestrado/docs/`

## Report set to sync (the validation study + everything it links to)
Copy these from source → target, **additively** (never delete other thesis files in the
target; no `rsync --delete`, no wiping the dir):

- `ai_anthropometric_validation.md`  ← the master validation study
- `flexy_beast.md`, `paraglider.md`, `unlimbited_phoenix.md`  ← per-model integration notes
- `flexy-beast-ai-sim/`, `paraglider-ai-sim/`, `phoenix-ai-sim/`, `ucd-ai-sim/`  ← report bundles (md + JSON)

## Steps
1. Verify the source files exist; copy each into the target (`cp` for files, `cp -r` for
   the bundle dirs, overwriting). Do NOT touch any other file under the target.
2. Sanity-check: confirm the validation study's relative links to the `*-ai-sim/` reports
   resolve in the target (each linked `.md` exists under `/home/pec/dev/mestrado/docs/`).
3. In the mestrado repo (`/home/pec/dev/mestrado`), `git add` the synced paths only, then
   commit. If on the default branch, that is fine (this is the thesis repo, not handfab).
   End the commit body with:
   `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`
   Default subject: `docs: sync AI-sizing reports from handfab (validation study + sim reports + integration notes)`
   Do NOT push unless the user asks.
4. Report: which files were copied, link-resolution result, and the mestrado commit hash/subject.
