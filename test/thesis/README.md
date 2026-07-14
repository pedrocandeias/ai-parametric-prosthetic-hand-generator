# HandFab — Thesis Evaluation Test Suite

Reproducible test infrastructure that produces evidence for the master's
dissertation evaluation of the HandFab platform, implementing the authoritative
protocol in
`mestrado/.../annexes/testes_plataforma/protocolo_geral_avaliacao_plataforma.md`
and the case matrix `matriz_casos_teste.csv`.

It evaluates three families:

1. **Repetibilidade & reprodutibilidade** (`REP-*`) — deterministic pathway repeated ≥10×, cross-browser, plus AI schema/limits (mocked) and optional live dispersion.
2. **Robustez** (`ROB-*`) — limits, invalid input, contradictions, uncovered populations, model floor, service failure, render/export failure — each classified `passa` / `falha controlada` / `falha não controlada` / `inconclusivo`.
3. **Acessibilidade** (`ACC-*`) — automated WCAG 2.2 A/AA (`@axe-core/playwright`) across states, plus an explicit manual-verification checklist.

## Commands

```bash
npm run test:thesis:repetition     # REP-DET (10×/model), REP-XBR (chromium/firefox/webkit), REP-AI (mocked)
npm run test:thesis:robustness     # ROB-* (UI + API + grounding logic)
npm run test:thesis:a11y:local     # ACC-* on the isolated local HTTP server
npm run test:thesis:a11y:public    # ACC public audit — NON-DESTRUCTIVE, unauthenticated only
npm run test:thesis                # aggregate: the four above, EXCLUDING paid AI & prod-destructive runs
npm run test:thesis:ai:live        # OPT-IN paid AI dispersion — requires RUN_LIVE_AI_TESTS=1
```

Every campaign writes a fresh, non-overwriting evidence directory:

```
test-results/thesis-evaluation/AAAA-MM-DD_HH-MM-SS_<campaign>/
  metadados.json              # reproducibility metadata (commit, node, playwright, axe, URL, commands…) — NO secrets
  frozen-configs.json         # the frozen deterministic configurations
  results/                    # machine-readable JSON/CSV per case
  artifacts/                  # STL geometries, screenshots, per-browser metrics, pw traces/videos
  logs/run.ndjson             # append-only run log
  playwright-report/          # Playwright HTML report
  manifesto_evidencias.csv    # SHA-256 of every artefact (schema of manifesto_evidencias.csv)
```

## Isolation & safety

- **Isolated synthetic DB.** Local campaigns run a dedicated server on `:3100`
  (`THESIS_PORT`) against `data/thesis-test.db` (`HANDFAB_DB_PATH`), seeded with a
  synthetic admin and synthetic anthropometric profiles — never production data.
  It is a testability seam only; with the variable unset the app uses `data/app.db`.
- **No paid calls by default.** The isolated server runs key-less, so any
  `/api/ai/suggest` returns a controlled `503`. Provider keys are forwarded to the
  server only when `RUN_LIVE_AI_TESTS=1`.
- **Mock vs real AI are separate.** Mocked responses (`rep-ai-mock`) are labelled
  `mocked:true` and can never be presented as a real AI repetition.
- **No secrets in evidence.** `metadados.json` records only presence booleans for
  API keys; the one-time login session cookie is kept in a temp file outside the
  evidence directory and deleted afterwards.
- **Public = read-only.** The public campaign audits only the unauthenticated
  surface; no login, no data creation/modification, no fault injection.

## Key knobs (environment)

| Variable | Default | Meaning |
|---|---|---|
| `THESIS_REP_RUNS` | 10 | deterministic repetitions per REP-DET case |
| `THESIS_GEOMETRY_TOL_MM` | 0.05 | pre-declared bbox tolerance for equivalence (§6.1) |
| `THESIS_PORT` | 3100 | isolated local server port |
| `THESIS_PUBLIC_URL` | https://handfab.pedrocandeias.net | public target |
| `RUN_LIVE_AI_TESTS` | (unset) | `1` enables paid AI dispersion suite |
| `THESIS_AI_LIVE_RUNS` | 10 | live AI repetitions |

## Layout

```
test/thesis/
  helpers/        env, campaign (metadata+manifest), stlMetrics, aiSchema, seed, pageObjects, testBase
  fixtures/       frozen-configs.json
  repetition/     rep-det, rep-xbr, rep-ai-mock, rep-ai-live
  robustness/     rob-ui, rob-api
  a11y/           a11y-local, a11y-public, manual-checklist
  playwright.thesis.config.js
  run-campaign.js run-thesis.js
```

## Scope caveats

This suite evaluates the technical artefact only. It does **not** assess user
testing, clinical adequacy, or prosthetic efficacy. An automated audit with zero
violations does **not** establish global WCAG conformance — see the manual
checklist emitted with every accessibility campaign.
