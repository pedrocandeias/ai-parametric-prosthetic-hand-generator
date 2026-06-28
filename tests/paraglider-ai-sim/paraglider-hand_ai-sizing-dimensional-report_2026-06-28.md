# Paraglider · Hand — Relatório de Dimensões: Dimensionamento por IA → Exportação STL

**Data:** 2026-06-28 · **Versão do código:** v14.16.0
**Modelo:** Paraglider · Hand (`models/active/paraglider_hand/paraglider_hand.scad`),
defaults `component = Hand`, `palm_style = Reborn`.

**Método:** idêntico ao teste do Flexy Beast — simulação ponta-a-ponta de um
utilizador real em `http://localhost:3000/edit` (login → abrir Paraglider → escrever
dados antropométricos → sugestão **real** da IA via `POST /api/ai/suggest`,
`claude-sonnet-4-6` → aplicar → **Exportar STL**), browser conduzido com
Playwright/Chromium. Cada render passa pelo caminho de produção OpenSCAD-WASM, com as
9 dependências do modelo (`.scad` + 2 `.stl`) montadas automaticamente pelo
`loadModel`. Três perfis de paciente + um **baseline** por omissão; 6 peças
exportadas por config (palm, index, middle, ring, pinky, thumb), medidas com
`trimesh`.

**Referência estática:** os meshes-fonte do **Flexible Flyer** em
`tests/flexible-flyer-master/.../files/` (`palm_left_v2_nobox.stl` — o palm Reborn —
e `Unlimbited_v3_palm_left_f360.stl`).

Dados de apoio: [`run-metadata.json`](run-metadata.json) e
[`measurements.json`](measurements.json).

> ⚠️ **Principal achado (CORRIGIDO em v14.17.0):** o **palm não escalava** com os
> dados antropométricos — ficava congelado no tamanho médio (breadth 83) para
> qualquer paciente (os dedos escalavam bem). Era um bug do modelo, não do pipeline.
> Foi corrigido e re-testado: o palm passa a escalar (criança 84.9 / homem 131.5 mm).
> Ver §6 para a causa-raiz, a correção e a verificação antes→depois.

---

## 1. O prompt e os dados de paciente

Mesmo template do teste do Flexy (texto completo em
`run-metadata.json → profiles[].full_prompt_sent`). O Paraglider expõe um conjunto
antropométrico **mais rico** que o Flexy — inclui `palm_length_mm` e
`palm_thickness_mm`. Inputs escritos (a única variável por perfil):

| Perfil | Texto livre introduzido |
|---|---|
| **criança** | *Criança de 7 anos, mão pequena. Largura da palma (nó a nó) cerca de 62 mm, dedo médio cerca de 56 mm, polegar cerca de 48 mm.* |
| **mulher** | *Mulher adulta, 34 anos, 165 cm, constituição magra. Sem medidas exatas — estima valores plausíveis a partir de normas populacionais.* |
| **homem** | *Homem adulto, 45 anos, 188 cm, mãos grandes. Largura dos nós dos dedos cerca de 96 mm, dedo médio cerca de 86 mm.* |

---

## 2. Grounding antropométrico (já com a correção v14.16.0)

O matcher corrigido escolheu o grupo populacional certo em cada caso (precedência:
medidas do paciente > médias populacionais):

| Perfil | género/idade detetados | grupo escolhido | médias mapeadas (palma breadth / length, mm) |
|---|---|---|---|
| criança | —/7 | **Dutch children KIMA, age 7** | 64 / 138* |
| mulher | female/34 | **ANSUR I Female 50th + Hand Survey** | 79.3 / 104 |
| homem | male/45 | **ANSUR I Male 50th + Hand Survey** | 90.3 / 113.8 |

\* O dataset de crianças trazia um `palm_length` de 138 mm (claramente errado para
7 anos). A IA **ignorou-o** corretamente (produziu `palm_length 60`), porque o
contexto "criança, mão pequena" + as medidas explícitas pequenas têm precedência —
bom exemplo de robustez. Para a **mulher**, a média feminina mapeada `palm_length
104` explica diretamente o valor sugerido (103 mm).

---

## 3. O que a IA devolveu (parâmetros aplicados)

| Parâmetro | omissão | criança | mulher | homem |
|---|---:|---:|---:|---:|
| palm_breadth_mm | 83 | **62** | **78** | **96** |
| palm_length_mm | 95 | 60 | 103 | 120 |
| palm_thickness_mm | 32 | 20 | 26 | 32 |
| middle_finger_length_mm | 72 | 56 | 78 | 86 |
| index_finger_length_mm | 68 | 51 | 71 | 79 |
| ring_finger_length_mm | 68 | 51 | 73 | 82 |
| pinky_finger_length_mm | 55 | 40 | 60 | 67 |
| thumb_length_mm | 65 | 48 | 64 | 74 |

A IA produziu valores antropometricamente coerentes para os **8** campos. Pós-correção
(§6), `palm_breadth_mm` passa a escalar o palm (e os `*_finger_length_mm` escalam os
dedos). Nota: `palm_length_mm` e `palm_thickness_mm` continuam a ser **só para
alinhamento com perfis/IA** — o palm escala uniformemente a partir de `palm_breadth_mm`
(é assim por design: os furos dos pinos têm de ficar circulares, logo o palm não pode
ser escalado não-uniformemente), tal como documentado nas captions do modelo.

---

## 4. Dimensões dos STL exportados (extensão mais longa, mm) — após a correção

| Peça | baseline | criança (Δ%) | mulher (Δ%) | homem (Δ%) |
|---|---:|---:|---:|---:|
| **palm** | 113.70 | **84.94 (−25.3 %)** | **105.49 (−7.2 %)** | **131.51 (+15.7 %)** |
| index | 93.08 | 82.31 (−11.6 %) | 94.98 (+2.0 %) | 100.05 (+7.5 %) |
| middle | 95.62 | 85.48 (−10.6 %) | 99.42 (+4.0 %) | 104.49 (+9.3 %) |
| ring | 90.72 | 80.54 (−11.2 %) | 93.72 (+3.3 %) | 99.11 (+9.2 %) |
| pinky | 82.94 | 73.95 (−10.8 %) | 85.93 (+3.6 %) | 90.12 (+8.7 %) |
| thumb | 89.87 | 81.01 (−9.9 %) | 93.19 (+3.7 %) | 97.62 (+8.6 %) |

Pós-correção, o palm escala uniformemente: comp./breadth = **1.370 constante** nas 4
configs (113.70/83 = 84.94/62 = 105.49/77 = 131.51/96). Antes da correção, o palm
era byte-a-byte idêntico (mesmo MD5) nas 4 — ver §6. Os valores das peças de dedo são
os mesmos de antes (a correção só toca no palm).

> **Nota de método (dedos):** no print-layout do Paraglider, cada peça de dedo
> exportada agrupa a **falange + a ponta** com um espaçamento fixo de 50 mm, por isso
> a *Comp.* da bbox mistura geometria que escala com um gap que não escala — varia
> menos do que o parâmetro. O indicador limpo é a **secção transversal** (largura),
> que escala **exatamente** com o parâmetro do dedo (ver §5).

---

## 5. Os dedos escalam corretamente (verificação pela secção)

A largura da bbox de cada dedo segue o respetivo `*_finger_length_mm` ao milésimo.
Exemplo do indicador (param `index_finger_length_mm`, escala = length / 57.6):

| config | index_finger_length_mm | escala param (vs base) | Larg. index (mm) | escala Larg. (vs base) |
|---|---:|---:|---:|---:|
| baseline | 68 | 1.000 | 19.69 | 1.000 |
| criança | 51 | 0.750 | 14.77 | 0.750 |
| mulher | 71 | 1.044 | 20.56 | 1.044 |
| homem | 79 | 1.162 | 22.87 | 1.162 |

As duas últimas colunas são idênticas → os dedos escalam uniformemente e
proporcionalmente. O mesmo se verifica para middle/ring/pinky/thumb (tabela completa
em §7 e em `measurements.json`).

---

## 6. 🐛→✅ Bug do palm: encontrado e corrigido (v14.17.0)

**Sintoma (antes):** o palm exportado media **113.70 × 100.80 × 38.19 mm em todas as
configurações** (criança breadth 62, mulher 78, homem 96 — todos iguais; STL
byte-a-byte idêntico). Confirmado também por render local com OpenSCAD CLI (não era
artefacto do export do browser): o palm a `palm_breadth_mm=62` era idêntico ao de `=96`.

**Causa-raiz:** em `paraglider_palm_left.scad`, **linha 4: `overall_scale = 1.25;`**
(default hardcoded). O ficheiro principal calcula
`overall_scale = palm_breadth_mm / 66.4` (linha 107) mas puxa o palm Reborn com
**`use <paraglider_palm_left.scad>`** (linha 205). `use` é de escopo **léxico**, por
isso o módulo `scaled_palm()` resolve `overall_scale` no escopo do **seu próprio
ficheiro** (1.25) e ignora o valor antropométrico do principal. Os **dedos** escapam
porque recebem a escala como **argumento** (`_finger_phalanx(index_scale)`); o palm
não recebia nada. (O `palm_style="UnlimbitedV3"` **já estava correto**: `pg_v3palm.scad`
entra por **`include`**, logo o seu `V3_overall_scale` resolve para o valor do
principal — verificado: V3 escala 62→85.9, 96→133.0 mm.)

**Prova numérica (antes):** palm 113.70 mm = palm Reborn de origem (90.96 mm) × 1.25
— exatamente o tamanho de breadth 83, congelado.

**Impacto clínico:** uma criança configurada a 62 mm recebia dedos de criança montados
num **palm de adulto** (breadth 83) — proporções partidas, peça impossível de montar.

**Correção aplicada** (`paraglider_hand.scad`): como `scaled_palm()` já cozinha a
escala 1.25 (= 83/66.4), reaplica-se a escala antropométrica em falta no ponto de
chamada do Reborn:
```
else scale(overall_scale / 1.25) scaled_palm();   // 1.25 × overall_scale/1.25 = palm_breadth_mm/66.4
```
Isolado a uma linha do ficheiro principal (não toca na biblioteca `use`d, sem risco de
colisão de variáveis); o caminho V3 fica intacto.

**Verificação (depois):** o palm Reborn passa a escalar, com **comp./breadth = 1.370
constante** e **sem regressão** no tamanho de referência (breadth 83 inalterado):

| breadth (config) | palm comp. antes | palm comp. depois |
|---|---:|---:|
| 62 (criança) | 113.70 | **84.94** |
| 77 (mulher) | 113.70 | **105.49** |
| 83 (baseline) | 113.70 | 113.70 *(igual — sem regressão)* |
| 96 (homem) | 113.70 | **131.51** |

Confirmado tanto por render local OpenSCAD como pela re-corrida completa do fluxo no
browser (login → IA → export). Ressalva: a correção escala o palm uniformemente
(incluindo os canais de cordel/elástico), em linha com o comportamento dos dedos — se
se quiser manter os canais a tamanho absoluto fixo, é um refinamento separado.

---

## 7. Comparação dimensional peça-a-peça (completa)

Caixa envolvente de cada config + referência estática (apenas o palm tem mesh-fonte;
os dedos do Flexible Flyer são gerados por `fingerator.scad`, sem STL estático).

**palm**

| Config | Comp. (mm) | Larg. (mm) | Alt. (mm) | ΔComp. vs baseline |
|---|---:|---:|---:|---:|
| baseline | 113.70 | 100.80 | 38.19 | — |
| criança | 84.94 | 75.30 | 28.53 | −28.76 (−25.3%) |
| mulher | 105.49 | 93.52 | 35.43 | −8.21 (−7.2%) |
| homem | 131.51 | 116.59 | 44.17 | +17.81 (+15.7%) |
| *estático Reborn palm (fonte)* | 90.96 | 80.64 | 30.55 | — |
| *estático Unlimbited v3 palm (fonte)* | 92.00 | 82.86 | 30.64 | — |

**index**

| Config | Comp. (mm) | Larg. (mm) | Alt. (mm) | ΔLarg. vs baseline |
|---|---:|---:|---:|---:|
| baseline | 93.08 | 19.69 | 14.49 | — |
| criança | 82.31 | 14.77 | 10.87 | −25.0% |
| mulher | 94.98 | 20.56 | 15.13 | +4.4% |
| homem | 100.05 | 22.87 | 16.83 | +16.2% |

**middle**

| Config | Comp. (mm) | Larg. (mm) | Alt. (mm) | ΔLarg. vs baseline |
|---|---:|---:|---:|---:|
| baseline | 95.62 | 20.85 | 15.34 | — |
| criança | 85.48 | 16.21 | 11.93 | −22.3% |
| mulher | 99.42 | 22.58 | 16.62 | +8.3% |
| homem | 104.49 | 24.90 | 18.33 | +19.4% |

**ring**

| Config | Comp. (mm) | Larg. (mm) | Alt. (mm) | ΔLarg. vs baseline |
|---|---:|---:|---:|---:|
| baseline | 90.72 | 19.69 | 14.49 | — |
| criança | 80.54 | 14.77 | 10.87 | −25.0% |
| mulher | 93.72 | 21.14 | 15.56 | +7.4% |
| homem | 99.11 | 23.74 | 17.47 | +20.6% |

**pinky**

| Config | Comp. (mm) | Larg. (mm) | Alt. (mm) | ΔLarg. vs baseline |
|---|---:|---:|---:|---:|
| baseline | 82.94 | 15.92 | 11.72 | — |
| criança | 73.95 | 11.58 | 8.52 | −27.3% |
| mulher | 85.93 | 17.37 | 12.78 | +9.1% |
| homem | 90.12 | 19.40 | 14.28 | +21.9% |

**thumb**

| Config | Comp. (mm) | Larg. (mm) | Alt. (mm) | vol (cm³) | ΔLarg. vs baseline |
|---|---:|---:|---:|---:|---:|
| baseline | 89.87 | 20.85 | 16.74 | 9.93 | — |
| criança | 81.01 | 16.21 | 13.02 | 4.61 | −22.3% |
| mulher | 93.19 | 22.58 | 18.13 | 12.67 | +8.3% |
| homem | 97.62 | 24.90 | 19.99 | 17.05 | +19.4% |

---

## 8. Comparação com a referência estática (Flexible Flyer)

O mesh Reborn de origem (`palm_left_v2_nobox.stl`) está à escala 1.0 (breadth ≈ 66.4
mm, comp. 90.96 mm). Pós-correção, o nosso palm escala em torno dela, em vez do
tamanho único congelado de antes:

| config (breadth) | o nosso palm comp. (mm) | vs Reborn-fonte (90.96) |
|---|---:|---:|
| criança (62) | 84.94 | −6.6 % |
| baseline (83) | 113.70 | +25.0 % |
| mulher (77) | 105.49 | +16.0 % |
| homem (96) | 131.51 | +44.6 % |

A referência confirma a correção: o palm da criança (breadth 62) aproxima-se do mesh
Reborn de origem (que é ~breadth 66), e cada paciente recebe um palm proporcional à
sua mão — uma família de tamanhos, não um valor fixo. (Antes da correção, todas as
linhas seriam 113.70 / +25.0 %.)

---

## 9. Conclusões

1. **Pipeline de produção validado** para um 2.º modelo, mais complexo (import de
   STL + 9 dependências montadas pela app, manifold).
2. **Grounding corrigido a funcionar** também aqui: género/idade certos, datasets
   femininos/criança usados, dataset com `palm_length` errado ignorado pela IA.
3. **Sugestão de parâmetros da IA correta** nos 8 campos antropométricos.
4. **Dedos escalam fielmente** com os parâmetros (secção transversal = razão do
   parâmetro, ao milésimo).
5. **🐛→✅ Bug encontrado e corrigido (v14.17.0):** o **palm Reborn não escalava** com
   `palm_breadth_mm` — congelado em scale 1.25 — por `use <paraglider_palm_left.scad>`
   + `overall_scale=1.25` hardcoded no módulo (§6). Crítico clinicamente (criança
   recebia palm de adulto). Corrigido com uma linha (`scale(overall_scale/1.25)`) e
   re-testado: o palm passa a escalar (criança 84.9 / homem 131.5 mm), sem regressão
   no tamanho de referência. O caminho UnlimbitedV3 já estava correto.

### Ressalvas
- Referência estática = mesh-fonte do Flexible Flyer; só o palm tem STL de origem
  (dedos são paramétricos via `fingerator.scad`).
- Para os dedos, a *Comp.* da bbox inclui o gap fixo de 50 mm do print-layout
  (falange+ponta na mesma peça); usar a **largura** como indicador de escala (§5).
- Pacotes STL (4 ZIP × 6 peças) no scratchpad da sessão (`…/scratchpad/out_pg/`); só
  os resumos JSON ficam versionados.
