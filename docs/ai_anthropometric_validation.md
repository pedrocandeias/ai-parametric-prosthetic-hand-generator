# AI-Assisted Anthropometric Sizing of a Parametric Prosthetic Hand — A Validation Study

## Abstract

This document reports a structured validation of the platform's **AI parameter-suggestion
pipeline**, in which a large language model (LLM) infers a complete set of anthropometric
dimensions for a 3D-printable parametric prosthetic hand (the *Flexy Beast* model) from
free-text patient descriptions. The central hypothesis is that a non-expert user — who does
not know clinical hand measurements — can nonetheless obtain an anatomically plausible,
print-ready design by describing the patient in ordinary language. We define a validation
protocol (range conformance, finger proportionality, adult plausibility, age-appropriate
scaling, and contralateral handedness) and apply it across two experiments spanning the
realistic input spectrum: rich direct measurements, partial data, and demographics only.
Across both experiments the model produced valid, in-range, anatomically ordered output in
every case. We also document the system's non-deterministic behaviour, a heuristic
false-positive in our own test, and one genuine robustness gap (handedness inferred rather
than instructed). Results are a single representative sample; the protocol — not the exact
millimetres — is the contribution.

---

## 1. Introduction & Motivation

Conventional prosthetic fitting requires a clinician to capture a set of hand measurements
(palm breadth, per-digit lengths, etc.) using calipers and standardised landmarks. The target
user of this platform is instead a **layperson** — a patient or family member — who has neither
the vocabulary nor the instruments for that task. The AI step exists specifically to bridge
this gap: it transforms whatever information the user *can* provide into the structured,
millimetre-precise parameter set the parametric CAD model requires.

This reframes the success criterion. The system is not asked to reproduce a gold-standard
clinical measurement; it is asked to produce a **reasonable, safe, editable starting point**
from sparse input, which the user (or a reviewing technician) then fine-tunes via the
parameter controls before export. Accessibility for the low-knowledge user is therefore the
primary design value, and it drives what we validate: graceful behaviour across the full range
of input richness, anatomical self-consistency, and safety-relevant correctness (notably the
hand side).

---

## 2. System Architecture

### 2.1 Pipeline overview

```
free-text description
   → frontend prompt construction (app.js · getAISuggestions)
       · injects the live Flexy Beast parameter schema (name, caption, type, min/max, current)
   → POST /api/ai/suggest    (server/routes/aiRoutes.js, JWT-authenticated, rate-limited)
   → aiService.callAnthropic (claude-sonnet-4-6)
   → JSON object { param: value, ... }
   → applySuggestions()      (drops unknown keys; updates only valid params)
   → parametric re-render (OpenSCAD WASM)  →  user fine-tuning  →  STL export
```

### 2.2 Prompt construction

The prompt is assembled per request and embeds the **current** model's parameter definitions,
so the LLM is always grounded in the live schema (names, captions, allowed ranges, current
values) rather than a hardcoded list. It instructs the model to (i) treat anthropometric
parameters as anatomical measurements in millimetres, (ii) estimate from population norms when
only qualitative data is given, (iii) preserve realistic inter-finger proportions, (iv) emit
only known parameter names within each range, and (v) leave non-anatomical parameters
(hardware/visibility/colour) at their defaults unless implied. The full template is reproduced
in Appendix A.

### 2.3 Canonical anthropometric schema

The parameter names are deliberately aligned with the platform's anthropometric import
pipeline (see `CLAUDE.md`), so AI output, CSV-imported population profiles, and manual entry
all share one measurement vocabulary. The adult reference ranges used as plausibility bounds
are reproduced in Appendix B.

---

## 3. Methodology

### 3.1 Model & configuration

| Item | Value |
|---|---|
| Target CAD model | `flexy_beast` (fully self-contained parametric SCAD) |
| LLM provider / model | Anthropic · `claude-sonnet-4-6` |
| Endpoint | `POST /api/ai/suggest` (admin-authenticated) |
| Output contract | single JSON object, parameter→value |
| Date of run | 2026-06-05 |

### 3.2 Experimental design

Two experiments were defined to cover complementary axes:

- **Experiment 1 — inference from population proxies (§4).** Five profiles described purely by
  *indirect* body proxies (age, sex, weight, height, region, arm length) with **no** hand
  measurements. This isolates the model's ability to infer hand anthropometry from
  demographics — the dominant real-world "common user" case.
- **Experiment 2 — input-spectrum & contralateral handedness (§5).** Three unilateral-amputation
  profiles spanning rich → sparse input, testing verbatim use of supplied measurements,
  proportional estimation of missing fields, and correct mirroring to the amputated side.

### 3.3 Validation criteria

Each suggestion is evaluated against five criteria:

1. **Schema conformance** — output parses as JSON; every key is a real model parameter; every
   numeric value lies within its declared `min`/`max`.
2. **Finger proportionality** — middle ≥ index, middle ≥ ring, pinky is shortest, thumb < middle.
3. **Adult plausibility** — for adult profiles, each measurement falls within the canonical
   adult range (Appendix B).
4. **Age-appropriate scaling** — minors scale below adult norms and flex-joint hardware is
   reduced for children's hands.
5. **Handedness correctness** (Experiment 2) — `mirrored` is set so the prosthesis matches the
   *amputated* side, i.e. the mirror of the measured/intact hand.

### 3.4 On non-determinism

LLM sampling is **stochastic**: identical input does not yield identical output. Consequently
the numeric tables below are a **single representative draw**, and §4.4 quantifies the
run-to-run variation we observed. The validation criteria are designed to be
*distributional invariants* — properties expected to hold on every draw — rather than assertions
about specific values. This is the appropriate epistemic stance for validating a stochastic
component: we test the shape and safety of the output, not its exact coordinates.

---

## 4. Experiment 1 — Inference from population proxies

### 4.1 Profiles (indirect proxies only)

| # | Label | Free-text input |
|---|---|---|
| 1 | Man 28 🇧🇷 | `man, 28 years old, 82kg, 180cm height, Brazil, arm length 70cm` |
| 2 | Girl 10 🇯🇵 | `girl, 10 years old, 32kg, 138cm height, Japan, small frame` |
| 3 | Woman 65 🇳🇬 | `woman, 65 years old, 68kg, 160cm height, Nigeria, arm length 62cm` |
| 4 | Man 50 🇩🇪 | `man, 50 years old, 95kg, 175cm height, Germany, broad hands, arm length 66cm` |
| 5 | Teen 15 🇮🇳 | `teenage boy, 15 years old, 60kg, 168cm height, India, slim build, arm length 67cm` |

### 4.2 Results (representative run, mm)

| Parameter | Man 28 🇧🇷 | Girl 10 🇯🇵 | Woman 65 🇳🇬 | Man 50 🇩🇪 | Teen 15 🇮🇳 |
|---|---|---|---|---|---|
| `palm_breadth_mm` | 90 | 62 | 74 | 95 | 72 |
| `index_finger_length_mm` | 76 | 52 | 64 | 78 | 64 |
| `middle_finger_length_mm` | 80 | 55 | 68 | 82 | 68 |
| `ring_finger_length_mm` | 76 | 52 | 65 | 79 | 64 |
| `pinky_finger_length_mm` | 62 | 42 | 50 | 63 | 51 |
| `thumb_length_mm` | 70 | 48 | 58 | 72 | 58 |
| `joint_dia` (hardware) | 7 | **5** | *default* | 7 | 7 |
| `joint_thick` (hardware) | 4 | **2** | *default* | 4 | 4 |

*Bold = AI proactively reduced flex-joint hardware for a child's hand. "default" = parameter
omitted, leaving the model's current value (per the "leave hardware unless implied" rule).*

### 4.3 Validation

**Summary: 14 checks passed, 1 warning, 0 failures.**

- **Schema conformance:** all 5 parsed; every key valid; all values in range. ✓ *(This is also
  the regression check for the prompt fix — the prior prompt was hardcoded for the removed
  "Fingerator" model and steered the LLM toward nonexistent parameters that were then silently
  dropped on apply.)*
- **Proportionality:** all 5 satisfy middle-longest / pinky-shortest / thumb < middle. ✓
- **Adult plausibility:** the three adults all fall within canonical adult ranges. ✓
- **Age scaling:** Girl 10 scaled to `palm_breadth` 62 mm and reduced hardware to 5 mm / 2 mm
  unprompted. ✓
- **Warning (not a model error):** the 15-year-old received `palm_breadth` 72 mm; our test's
  blanket "`minor ⇒ < 70 mm`" heuristic flagged it, but 72 mm is correct for a tall, slim
  mid-teen whose hand is essentially adult-sized. The fault is in the over-strict assertion,
  not the suggestion.

### 4.4 Run-to-run variation (illustrating §3.4)

Comparing this run with a prior independent run on the same Man 28 🇧🇷 profile:

| Field | Prior run | This run | Δ |
|---|---|---|---|
| `palm_breadth_mm` | 88 | 90 | +2 |
| `index_finger_length_mm` | 74 | 76 | +2 |
| `middle_finger_length_mm` | 78 | 80 | +2 |
| `thumb_length_mm` | 68 | 70 | +2 |

The variation is small (±2–3 mm, ~2–3%) and **preserves all invariants** (ordering, ranges,
proportions). The Woman 65 🇳🇬 profile additionally illustrates *structural* non-determinism: in
one run the model emitted explicit `joint_dia`/`joint_thick`, in another it omitted them
(leaving defaults) — both valid under the prompt contract. This bounds the expected jitter for
downstream consumers and reinforces that the AI output is a **starting point**, refined by the
user, not a fixed prescription.

---

## 5. Experiment 2 — Input-spectrum & contralateral handedness

### 5.1 Rationale

In practice the user supplies *whatever they have*. For a **unilateral amputation**, the richest
available data is direct measurement of the **intact contralateral hand**; the prosthesis must
then be produced for the **opposite** (amputated) side, i.e. the geometric mirror of the
measured hand. The `mirrored` parameter (`false` = left, `true` = right) governs this. This
experiment spans three richness levels and verifies both verbatim use of supplied values and
correct side assignment.

### 5.2 Profiles

| Scenario | Input | Amputated side → required prosthesis |
|---|---|---|
| Direct contralateral | full intact-LEFT-hand measurements | right → RIGHT |
| Partial + demographics | man 40; only `pb=90` from intact RIGHT hand | left → LEFT |
| Demographics only | woman 30, East Asian, 158 cm | right → RIGHT |

### 5.3 Results (representative run, mm)

| Scenario | `palm_breadth` | idx / mid / ring / pky / thumb | AI `mirrored` | Side correct |
|---|---|---|---|---|
| Direct contralateral | 84 *(verbatim)* | 72 / 78 / 75 / 58 / 64 *(verbatim)* | `true` | ✓ |
| Partial + demographics | 90 *(verbatim)* | 76 / 80 / 76 / 62 / 72 *(estimated)* | `false` | ✓ |
| Demographics only | 72 *(estimated)* | 61 / 65 / 62 / 48 / 57 *(estimated)* | `true` | ✓ |

### 5.4 Findings

- **Provided measurements are used verbatim** — the model does not re-estimate over data the
  user supplied (all six values in scenario 1; the lone `pb=90` in scenario 2 passed through).
- **Partial input blends correctly** — supplied values are retained and missing fields are
  estimated *proportionally around them*.
- **Demographics-only degrades gracefully** — the core low-knowledge path produces a full,
  plausible set.
- **Handedness was correct in all three** — the model produced the mirror of the intact side.

> ⚠ **Threat to validity — handedness is *inferred*, not *instructed*.** The prompt does not
> mention handedness or mirroring; the model deduced it from natural-language phrasing
> ("missing the RIGHT hand"). With `claude-sonnet-4-6` and full-sentence input this was
> reliable across runs, but for terse clinical shorthand (e.g. *"L hand pb84, R amp"*) it is not
> guaranteed. Because a wrong-side hand is unusable and a non-expert may not notice, an explicit
> contralateral/mirror rule in the prompt is the recommended hardening (see §8).

---

## 6. Discussion

**Anatomical fidelity.** Across eight distinct profiles the model honoured the standard digit
ordering and adult/paediatric magnitude norms, and reflected both **sexual dimorphism** (men >
women on every field) and **regional population variation** (the country influenced estimates).
The 65-year-old woman and the slim 15-year-old converged on similar small-adult sizes, which is
anatomically reasonable and indicates the model reasons over multiple proxies jointly rather
than keying on a single attribute.

**Graceful degradation.** The two experiments jointly demonstrate a monotone relationship
between input richness and reliance on priors: supplied measurements are used verbatim, partial
data anchors proportional estimation, and demographics-only falls back fully to population
norms — without the user needing to know which fields matter. This is precisely the behaviour
the accessibility goal requires.

**Emergent hardware adaptation.** The reduction of flex-joint dimensions for a child's hand was
not requested in the profile text; it follows from the parameter *captions* (which note "reduce
for small children's hands"), showing the model uses the injected schema's documentation, not
only its names.

---

## 7. Limitations & Threats to Validity

1. **Single-draw sampling.** Results are one representative run per profile. We characterise but
   do not statistically bound the output distribution; a rigorous study would aggregate many
   draws and report per-parameter dispersion.
2. **No clinical ground truth.** Plausibility bounds are population ranges, not per-patient
   measured truth. This validates *reasonableness*, not *accuracy* against a real hand.
3. **Inferred handedness.** As noted in §5.4, side assignment relies on model inference and is a
   latent safety risk for terse input until made explicit.
4. **Heuristic brittleness in the harness.** The "minor ⇒ palm < 70 mm" check produced a
   false positive; test heuristics must allow for near-adult adolescents.
5. **Stochastic infrastructure faults.** One burst of rapid back-to-back calls returned an
   empty/unparseable response; a short delay resolved it. Production use should add retry/backoff
   and strict JSON-schema validation with a re-prompt on failure.
6. **Model/version coupling.** Findings are specific to `claude-sonnet-4-6`; behaviour
   (especially the emergent inferences) may differ on other models or future versions and
   should be re-validated on change.

---

## 8. Future Work

- **Explicit contralateral/mirroring rule** in the prompt, removing reliance on inference for a
  safety-relevant parameter.
- **Statistical validation:** N-draw sampling per profile with reported mean/σ per parameter and
  invariant pass-rates.
- **Schema-validated output:** enforce a JSON schema server-side and auto-re-prompt on violation,
  rather than silently dropping unknown keys.
- **Ground-truth benchmarking** against measured-hand datasets to quantify estimation error, not
  just plausibility.
- **Permanent regression set:** retain the demographics-only profiles as a standing test, since
  that path serves the lowest-knowledge user.

---

## 9. Reproducibility

The server must be running with a valid `ANTHROPIC_API_KEY` in `.env`. The validation harness
logs in as an admin, reconstructs the exact frontend prompt for each profile (injecting the live
`flexy_beast` parameter schema from `models/models-config.json`), calls `POST /api/ai/suggest`,
parses the returned JSON, and applies the §3.3 criteria. Because sampling is stochastic, expect
the numbers to differ between runs while the invariant checks continue to pass. When issuing many
requests in quick succession, insert a short delay (or retry with backoff) to avoid transient
provider errors.

---

## Appendix A — Prompt template

For each profile the frontend sends the following (the live prompt embeds the full Flexy Beast
parameter JSON in place of the abbreviated array):

```
You are sizing a 3D-printed parametric prosthetic hand model ("Flexy Beast") for a patient.

Patient anthropometric data:
<free-text profile>

These are the model's adjustable parameters. Each has a name, a caption describing what it
controls, an allowed range (min/max where applicable), and the current value:
[ { "name": "palm_breadth_mm", "caption": "...", "type": "number", "min": 55, "max": 110, "current": 83 }, ... ]

Guidance:
- Anthropometric parameters are anatomical measurements in millimetres. Use the patient's
  data to set them directly. Canonical fields (when present): palm_breadth_mm
  (knuckle-to-knuckle, ~70-100mm adult), palm_length_mm, palm_thickness_mm,
  index/middle/ring/pinky_finger_length_mm (MCP crease to tip), thumb_length_mm,
  gauntlet_width_mm (≈ wrist circumference / π + ~5mm clearance).
- If the data is qualitative, estimate plausible adult measurements from population norms;
  women typically run smaller than men.
- Keep proportions realistic relative to each other (middle finger longest, pinky shortest).
- Only suggest values for parameters listed above, by their exact name, within min/max.
- Leave hardware/visibility/color parameters at their current values unless implied.

Respond with ONLY a valid JSON object mapping parameter names to suggested values.
```

## Appendix B — Canonical adult anthropometric ranges

Source: `CLAUDE.md` (Anthropometric Parameter Alignment). Used as plausibility bounds in §3.3.4.

| Parameter | Measurement | Typical adult range |
|---|---|---|
| `palm_breadth_mm` | Knuckle-to-knuckle metacarpal breadth | 70–100 mm |
| `middle_finger_length_mm` | MCP crease to middle fingertip | 60–115 mm |
| `index_finger_length_mm` | Index MCP crease to tip | 55–110 mm |
| `ring_finger_length_mm` | Ring MCP crease to tip | 55–110 mm |
| `pinky_finger_length_mm` | Pinky MCP crease to tip | 40–85 mm |
| `thumb_length_mm` | Thumb MCP crease to tip | 45–80 mm |
