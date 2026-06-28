# Flexy Beast — Relatório de Dimensões: Dimensionamento por IA → Exportação STL

**Data:** 2026-06-28 · **Versão do código:** v14.16.0 (re-corrido **após** a correção do grounding)
**Modelo:** Flexy Beast (`models/active/flexy_beast/flexy_beast.scad`)

**Método:** Simulação ponta-a-ponta de um utilizador real na app em
`http://localhost:3000/edit` — login → abrir o Flexy Beast → escrever os dados
antropométricos do paciente → sugestão **real** da IA (`POST /api/ai/suggest`,
provider `anthropic`, `claude-sonnet-4-6`) → aplicar → **Exportar STL**. O browser
foi conduzido com Playwright/Chromium, por isso cada render passa pelo caminho de
exportação de produção OpenSCAD-WASM (`print_layout=true`, toggles por peça,
assentamento na base) — não houve atalho por CLI.

Três perfis de paciente mais um **baseline** com os parâmetros por omissão. Para
cada configuração exportaram-se 7 peças imprimíveis, medidas com `trimesh` (caixa
envolvente, extensões ordenadas `Comp. ≥ Larg. ≥ Alt.`, em mm), comparadas
(a) baseline-vs-IA e (b) contra os STL estáticos do daprice em
`tests/flexy-beast-original/stl/` (fixos a **160 % da escala base do Cyborg
Beast**).

Dados de apoio: [`run-metadata.json`](run-metadata.json) (prompts + respostas cruas
da IA + parâmetros aplicados) e [`measurements.json`](measurements.json) (geometria
de cada peça).

> **Nota:** esta é a 2.ª corrida, depois de corrigir o matcher de grounding
> (v14.16.0). A 1.ª corrida revelou que o grounding ancorava os três casos no mesmo
> grupo **masculino** — ver §2 para o antes→depois.

---

## 1. O prompt e os dados de paciente

O cliente envia um único prompt em template por pedido (idêntico entre perfis,
exceto a linha de dados do paciente e os valores `current`). Texto completo em
`run-metadata.json → profiles[].full_prompt_sent` (8 020 caracteres); estrutura:

```
You are sizing a 3D-printed parametric prosthetic hand model ("Flexy Beast") for a patient.

Patient anthropometric data:
<<< texto livre do utilizador — ver tabela abaixo >>>

These are the model's adjustable parameters … [37 parâmetros: name/caption/min/max/current] …

Guidance:
- Anthropometric parameters are anatomical measurements in millimetres … palm_breadth_mm (~70-100mm),
  index/middle/ring/pinky_finger_length_mm (MCP crease to tip), thumb_length_mm, gauntlet_width_mm …
- If the data is qualitative … estimate plausible adult measurements from population norms;
  women typically run smaller than men.
- Keep proportions realistic … Only suggest values for parameters listed above … stay within min/max.
- Leave hardware/visibility/color parameters at their current values unless the patient data implies a change.

Respond with ONLY a valid JSON object mapping parameter names to suggested values. No prose, no markdown.
```

Ao prompt é anexado, do lado do servidor, um **bloco de grounding** populacional
(ver §2). Dados de paciente escritos (a única variável por perfil):

| Perfil | Texto livre introduzido |
|---|---|
| **criança** | *Criança de 7 anos, mão pequena. Largura da palma (nó a nó) cerca de 62 mm, dedo médio cerca de 56 mm, polegar cerca de 48 mm.* |
| **mulher** | *Mulher adulta, 34 anos, 165 cm, constituição magra. Sem medidas exatas — estima valores plausíveis a partir de normas populacionais.* |
| **homem** | *Homem adulto, 45 anos, 188 cm, mãos grandes. Largura dos nós dos dedos cerca de 96 mm, dedo médio cerca de 86 mm.* |

---

## 2. Grounding antropométrico — antes → depois da correção

O servidor procura na tabela `anthropometric_profiles` (100 perfis populacionais)
o grupo mais próximo do paciente e anexa as suas médias medidas ao prompt como
âncora (precedência: medidas explícitas do paciente > médias populacionais).

**Antes (v14.15.0):** o matcher ancorava os **três** casos no mesmo grupo
masculino. Causa: o token de género masculino `'m,'` estava contido nas unidades
`"mm,"`/`"cm,"`, logo qualquer texto com medidas era lido como **masculino**; e o
parsing de género/idade era só em inglês (ignorava "Mulher", "Criança", "7 anos").

**Depois (v14.16.0):** match correto por género + escalão etário + proximidade de
idade. Reproduzido com os mesmos textos:

| Perfil | Grupo escolhido **antes** | Grupo escolhido **depois** | Como |
|---|---|---|---|
| criança | ANSUR I **Male** 50th (palma 90.3 mm) | **Dutch children KIMA, age 7** | idade 7 (det.) → escalão *child* + proximidade |
| mulher | ANSUR I **Male** 50th | **ANSUR I Female 50th + Hand Survey** | "Mulher"→female, "34 anos"→adult |
| homem | ANSUR I Male 50th | **ANSUR I Male 50th + Hand Survey** | "Homem"→male, "45 anos"→adult |

A DB tinha sempre os perfis certos (39 femininos, 37 masculinos, idades 2→80+,
incluindo `ANSUR I Female 50th` e `Dutch children … age 7`); o problema era o
matcher, agora resolvido. Detalhe técnico da correção em §7.

---

## 3. O que a IA devolveu (parâmetros aplicados)

| Parâmetro | omissão | criança | mulher | homem |
|---|---:|---:|---:|---:|
| palm_breadth_mm | 83 | **62** | **77** | **96** |
| middle_finger_length_mm | 72 | 56 | 77 | 86 |
| index_finger_length_mm | 68 | 52 | 70 | 78 |
| ring_finger_length_mm | 68 | 52 | 73 | 82 |
| pinky_finger_length_mm | 55 | 40 | 59 | 67 |
| thumb_length_mm | 65 | 48 | 63 | 73 |
| gauntlet_width_mm | 60 | 47 | 57 | 60 |
| gauntlet_length_mm | 108 | 80 | 100 | 108 |
| joint_dia | 7 | **5** | 6 | 7 |
| joint_thick | 4 | **2** | 3 | 4 |
| wrist_pin_dia | 7 | **5** | 7 | 7 |

**Observações**
- Medidas quantitativas (criança, homem) respeitadas quase à letra (palma 62/96).
- A **mulher** está agora ancorada no dataset **feminino** ANSUR I (antes era
  masculino): a IA produziu uma mão de adulta franzina coerente (palma 77, médio
  77, polegar 63) e reduziu o gauntlet (57×100) — algo que na 1.ª corrida, com
  âncora masculina, não acontecia.
- Hardware segue as captions: criança com `joint_dia 5`, `joint_thick 2`,
  `wrist_pin_dia 5` (as captions dizem *"reduce to 5/2 mm for children's hands"*);
  intermédio na mulher; defaults no homem.

---

## 4. Dimensões dos STL exportados — baseline vs IA (extensão mais longa, mm)

Cada valor medido a partir do STL realmente exportado. `Δ` vs o baseline por omissão.

| Peça | baseline | criança (Δ / %) | mulher (Δ / %) | homem (Δ / %) |
|---|---:|---:|---:|---:|
| palm | 124.20 | 94.56 (−29.6 / −23.9 %) | 115.73 (−8.5 / −6.8 %) | 142.55 (+18.4 / +14.8 %) |
| index_base | 43.16 | 32.98 (−10.2 / −23.6 %) | 43.80 (+0.6 / +1.5 %) | 49.51 (+6.4 / +14.7 %) |
| index_tip | 62.77 | 47.78 (−15.0 / −23.9 %) | 61.51 (−1.3 / −2.0 %) | 72.10 (+9.3 / +14.9 %) |
| middle_base | 45.32 | 35.14 (−10.2 / −22.5 %) | 47.59 (+2.3 / +5.0 %) | 53.83 (+8.5 / +18.8 %) |
| middle_tip | 64.61 | 49.62 (−15.0 / −23.2 %) | 64.73 (+0.1 / +0.2 %) | 75.78 (+11.2 / +17.3 %) |
| thumb_base | 41.54 | 30.82 (−10.7 / −25.8 %) | 40.02 (−1.5 / −3.7 %) | 46.80 (+5.3 / +12.7 %) |
| thumb_tip | 35.20 | 26.80 (−8.4 / −23.9 %) | 32.80 (−2.4 / −6.8 %) | 39.46 (+4.3 / +12.1 %) |

**A geometria acompanha linearmente os parâmetros.** Comprimento da palma vs
`palm_breadth_mm`:

| config | palm_breadth_mm | comp. palma (mm) | comp. / breadth |
|---|---:|---:|---:|
| criança | 62 | 94.56 | 1.525 |
| mulher | 77 | 115.73 | 1.503 |
| baseline | 83 | 124.20 | 1.496 |
| homem | 96 | 142.55 | 1.485 |

Nota: as **pontas** dos dedos exportam como cascas abertas (`watertight: false`, sem
volume fechado) porque `finger_pads=true` esvazia-as para moldar as almofadas de
silicone — esperado.

---

## 5. Comparação dimensional peça-a-peça (completa)

Um bloco por peça: caixa envolvente completa de cada config (Comp.×Larg.×Alt. +
volume), variação vs baseline, e a linha da **referência estática daprice (160 %)**
em linha.

> Mapeamento estático: `palm → palm.stl`; peças `*_base` → `finger_base.stl`;
> `index_tip`/`middle_tip` → `finger_tip.stl`; `thumb_tip → thumb_tip.stl`.

**palm**

| Config | Comp. (mm) | Larg. (mm) | Alt. (mm) | vol (cm³) | ΔComp. vs baseline |
|---|---:|---:|---:|---:|---:|
| baseline | 124.20 | 102.16 | 47.35 | 104.39 | — |
| criança | 94.56 | 77.78 | 36.05 | 47.11 | -29.64 (-23.9%) |
| mulher | 115.73 | 95.19 | 44.12 | 85.27 | -8.47 (-6.8%) |
| homem | 142.55 | 117.25 | 54.34 | 158.53 | +18.35 (+14.8%) |
| *estático palm (160%)* | 116.44 | 95.78 | 47.35 | — | — |

**index_base**

| Config | Comp. (mm) | Larg. (mm) | Alt. (mm) | vol (cm³) | ΔComp. vs baseline |
|---|---:|---:|---:|---:|---:|
| baseline | 43.16 | 19.02 | 18.84 | 9.03 | — |
| criança | 32.98 | 14.48 | 14.35 | 4.13 | -10.18 (-23.6%) |
| mulher | 43.80 | 17.72 | 17.56 | 8.49 | +0.64 (+1.5%) |
| homem | 49.51 | 21.83 | 21.63 | 14.51 | +6.35 (+14.7%) |
| *estático finger_base (160%)* | 40.50 | 18.84 | 17.83 | — | — |

**index_tip**

| Config | Comp. (mm) | Larg. (mm) | Alt. (mm) | vol (cm³) | ΔComp. vs baseline |
|---|---:|---:|---:|---:|---:|
| baseline | 62.77 | 24.76 | 19.02 | — | — |
| criança | 47.78 | 22.04 | 14.48 | — | -14.99 (-23.9%) |
| mulher | 61.51 | 25.46 | 17.72 | — | -1.26 (-2.0%) |
| homem | 72.10 | 23.25 | 21.83 | — | +9.33 (+14.9%) |
| *estático finger_tip (160%)* | 58.56 | 22.12 | 17.83 | 11.27 | — |

**middle_base**

| Config | Comp. (mm) | Larg. (mm) | Alt. (mm) | vol (cm³) | ΔComp. vs baseline |
|---|---:|---:|---:|---:|---:|
| baseline | 45.32 | 19.02 | 18.84 | 9.74 | — |
| criança | 35.14 | 14.48 | 14.35 | 4.53 | -10.18 (-22.5%) |
| mulher | 47.59 | 17.72 | 17.56 | 9.56 | +2.27 (+5.0%) |
| homem | 53.83 | 21.83 | 21.63 | 16.38 | +8.51 (+18.8%) |
| *estático finger_base (160%)* | 40.50 | 18.84 | 17.83 | — | — |

**middle_tip**

| Config | Comp. (mm) | Larg. (mm) | Alt. (mm) | vol (cm³) | ΔComp. vs baseline |
|---|---:|---:|---:|---:|---:|
| baseline | 64.61 | 24.76 | 19.02 | — | — |
| criança | 49.62 | 22.04 | 14.48 | — | -14.99 (-23.2%) |
| mulher | 64.73 | 25.46 | 17.72 | — | +0.12 (+0.2%) |
| homem | 75.78 | 23.25 | 21.83 | — | +11.17 (+17.3%) |
| *estático finger_tip (160%)* | 58.56 | 22.12 | 17.83 | 11.27 | — |

**thumb_base**

| Config | Comp. (mm) | Larg. (mm) | Alt. (mm) | vol (cm³) | ΔComp. vs baseline |
|---|---:|---:|---:|---:|---:|
| baseline | 41.54 | 19.02 | 18.84 | 8.50 | — |
| criança | 30.82 | 14.48 | 14.35 | 3.72 | -10.72 (-25.8%) |
| mulher | 40.02 | 17.72 | 17.56 | 7.41 | -1.52 (-3.7%) |
| homem | 46.80 | 21.83 | 21.63 | 13.34 | +5.26 (+12.7%) |
| *estático finger_base (160%)* | 40.50 | 18.84 | 17.83 | — | — |

**thumb_tip**

| Config | Comp. (mm) | Larg. (mm) | Alt. (mm) | vol (cm³) | ΔComp. vs baseline |
|---|---:|---:|---:|---:|---:|
| baseline | 35.20 | 19.02 | 18.63 | — | — |
| criança | 26.80 | 14.48 | 14.35 | — | -8.40 (-23.9%) |
| mulher | 32.80 | 17.72 | 17.56 | — | -2.40 (-6.8%) |
| homem | 39.46 | 21.83 | 16.24 | — | +4.26 (+12.1%) |
| *estático thumb_tip (160%)* | 33.95 | 18.43 | 17.20 | 3.91 | — |

---

## 6. Comparação com a referência estática daprice

Os STL de demo estão fixos a **160 % da escala base do Cyborg Beast** (malha mais
antiga; é uma verificação de *envelope/tamanho*, não um diff ao nível do vértice).

| Peça estática | estático Comp.×Larg.×Alt. (mm) | config mais próxima | a nossa Comp.×Larg.×Alt. (mm) |
|---|---|---|---|
| palm.stl | 116.44 × 95.78 × 47.35 | **mulher** | 115.73 × 95.19 × 44.12 |
| finger_base.stl | 40.50 × 18.84 × 17.83 | mulher (index_base) | 43.80 × 17.72 × 17.56 |
| finger_tip.stl | 58.56 × 22.12 × 17.83 | mulher (index_tip) | 61.51 × 25.46 × 17.72 |
| thumb_tip.stl | 33.95 × 18.43 × 17.20 | mulher (thumb_tip) | 32.80 × 17.72 × 17.56 |

**Conclusão:** a demo daprice 160 % corresponde quase exatamente ao
dimensionamento de **mulher adulta franzina** deste modelo (palma 116.4 vs 115.7
mm, < 1 % no eixo mais longo). O default do repo (83 mm → 124 mm) é ~6–7 % maior, e
o homem ~22 % maior. O rebuild paramétrico reproduz o envelope da referência a
poucos mm quando dimensionado para a mesma mão.

---

## 7. A correção (o que mudou no código)

**Opção 1 — matcher determinístico** (`server/services/profileMapping.js`):
- Tokens de género com **fronteira de palavra Unicode** (já não substring) → as
  unidades `"mm,"`/`"cm,"` deixam de ser lidas como masculino.
- Dicionário **multilingue** (EN/PT/ES) de género e de escalão etário.
- `extractAge` entende "anos"/"años"; e as alturas/larguras ("188 cm") não são lidas
  como idade.
- `age_group` numérico da DB ("7", "18-30", "80+", "Adult (Military, 17–40)") é
  reduzido a um escalão (child/adult/elderly) **com proximidade numérica de idade**
  → um 7 anos cai no dataset de crianças de 7 anos.

**Opção 2 — extração estruturada via LLM** (`aiService.extractPatientAttributes`,
`claude-haiku-4-5`): para texto livre/qualitativo, extrai `{gender, age}` em JSON e
alimenta o matcher. Corre **só quando** o parser determinístico fica incompleto
(eficiente) e degrada graciosamente para o parser em caso de erro/sem chave. Ex.
verificado: *"retired schoolteacher, mid-seventies"* → o parser falha → o LLM infere
`age 75`. (Subsome a ideia de "traduzir para inglês", sem chamada extra na maioria
dos casos.)

**Testes:** `test/profileMapping.test.js` (`npm run test:unit`, 10/10 a passar) —
cobre a regressão das unidades-como-masculino, o parsing multilingue, o bucketing de
idade e o override por hints.

Nesta corrida, os 3 perfis tinham género+idade explícitos, por isso o match correto
veio do parser determinístico (Opção 1); a Opção 2 é o reforço para descrições
ambíguas.

---

## 8. Conclusões

1. **Pipeline de produção validado ponta-a-ponta** pela UI real (login, IA
   autenticada, exportação STL por peça via OpenSCAD-WASM).
2. **Grounding corrigido:** a mulher passou a ancorar num dataset **feminino** e a
   criança num dataset de **crianças de 7 anos** (antes ambas em ANSUR I Male). A
   geometria exportada reflete-o (mulher agora ~6.8 % abaixo do baseline na palma,
   com dedos coerentes com a âncora feminina).
3. **Geometria fiel aos parâmetros:** comprimentos escalam linearmente com as
   entradas (comp. palma / breadth ≈ 1.49–1.52 numa gama 62→96 mm).
4. **Fidelidade ao original:** dimensionado para a mesma mão, o Flexy Beast
   paramétrico reproduz o envelope da demo daprice 160 % a < 1 % na palma; a única
   diferença estrutural são as pontas dos dedos intencionalmente ocas.
5. **Melhoria dos dados antropométricos entregue (v14.16.0):** Opção 1 (matcher
   determinístico) + Opção 2 (extração LLM), com testes unitários. Os 39 perfis
   femininos e os de criança da DB deixaram de ficar por usar.

### Ressalvas
- Referência estática = escala fixa de 160 % e malha antiga → §6 é envelope/tamanho.
- Extensões ordenadas (`Comp.≥Larg.≥Alt.`); secções das pontas refletem a orientação
  de impressão.
- Os pacotes STL (4 ZIP, 7 peças) estão no scratchpad da sessão (`…/scratchpad/out_v2/`);
  aqui só ficam versionados os resumos JSON. Diz se queres os STL no repositório.
