# Relatório — Adaptação paramétrica dos modelos aos dados antropométricos

**Projeto:** AI Parametric Prosthetic Hand Generator
**Âmbito:** análise técnica detalhada do que foi **adicionado e modificado** em cada modelo ativo da plataforma para que (a) fiquem paramétricos e (b) os dados antropométricos do paciente lhes possam ser aplicados.
**Exclusão:** este relatório não cobre o modelo **pec Phoenix** (por indicação; tem relatório próprio em `docs/pec-phoenix-hand/`).

> As afirmações citam ficheiros reais e versões do `CHANGELOG.md`. A história git está compactada em poucos commits, pelo que a atribuição de versões usa os blocos datados do CHANGELOG (a fonte fiável), cruzados com o conteúdo atual dos ficheiros.

---

## 1. Contexto e problema

Os modelos herdados são reconstruções de designs da comunidade e-NABLE (Flexy Beast, Cyborg Beast, UnLimbited Phoenix, Paraglider/Flexible Flyer). No estado original **não** consumiam medições antropométricas: apresentavam escala fixa ou hardcoded, nomes de parâmetro incompatíveis com o pipeline de importação, e acoplamentos escondidos (partes com escala congelada dentro de sub-ficheiros, percursos de dimensionamento com limites inconsistentes).

O trabalho tornou cada modelo **paramétrico e ancorado na anatomia do paciente**, mantendo os **nomes de campo canónicos** de `CLAUDE.md` (secção *Anthropometric Parameter Alignment*), de forma a que um perfil importado (CSV → base de dados) auto-preencha os parâmetros corretos.

Duas estratégias de parametrização emergiram, consoante a natureza da geometria herdada:
- **Geometria própria escalável** (Flexy Beast, Cyborg Beast) — reconstruída em SCAD paramétrico; a escala aplica-se diretamente às primitivas.
- **Meshes fixas importadas** (UnLimbited Phoenix; a palma do Paraglider) — a camada paramétrica é construída *à volta* das meshes sem distorcer as zonas funcionais (furos de pino), esticando só bandas sem furos.

---

## 2. A ponte de dados — `server/services/profileMapping.js`

O elo entre o **perfil antropométrico armazenado** e o **modelo paramétrico vivo** é `profileMapping.js` — a **única fonte de verdade** desta tradução, usada tanto pelo seletor "Population baseline" da configuração como pelo grounding da IA (`aiRoutes.js`).

**Decisão de arquitetura chave:** o mapeamento parte da árvore anatómica normalizada `profile.measurements` (ex.: `palm.width_mm`, `digits.middle.total_length_mm`) e **não** dos `geometry_parameters` do importador. Estes foram construídos para o design socket-and-phalanx Kwawu/cyborgbeast (chaves como `finger_length_index`, bloco `pekwawu`) e **nenhum** coincide com os nomes canónicos dos modelos. A `profile.measurements` alinha 1:1 com a coluna "Platform source" de `CLAUDE.md`.

Mapa canónico (`PARAM_TO_MEASUREMENT_PATH`):

| Parâmetro do modelo | Caminho em `profile.measurements` |
|---|---|
| `palm_breadth_mm` | `palm.width_mm` |
| `palm_length_mm` / `palm_thickness_mm` | `palm.length_mm` / `palm.thickness_mm` |
| `index/middle/ring/pinky_finger_length_mm` | `digits.<dedo>.total_length_mm` |
| `thumb_length_mm` | `digits.thumb.total_length_mm` |
| `*_base_length_mm` (proximal) | `digits.<dedo>.proximal_length_mm` |
| `wrist_circumference_mm` | `wrist.circumference_mm` |

`mapProfileToModelParameters(profile, modelDef)` percorre os parâmetros do modelo e só aplica um valor quando este (a) existe no modelo, (b) é numérico, (c) está no mapa canónico e (d) tem uma medição finita — fazendo **clamp aos min/max** declarados. Parâmetros não anatómicos (hardware, visibilidade, lateralidade, cores) nunca são tocados.

---

## 3. Análise detalhada por modelo

### 3.1 Flexy Beast

**Origem e estado herdado.** Adaptado de `daprice/Flexy-Beast` (CC BY-SA 4.0), ele próprio um mashup do Parametric Cyborg Beast (MakerBlock) e do Flexy Hand (Steve Wood / Gyrobot) — juntas flexíveis impressas substituem os parafusos Chicago e elásticos. O design upstream tinha escala fixa e não expunha inputs anatómicos; a charneira dos dedos era uma placa STL medida (`Finger_Hinge_Plate.scad` traçado de `Finger_Hinge_Plate.stl`) e o gauntlet era uma mesh importada opaca. Entrou na plataforma **já paramétrico** em **v9.1.0** (self-contained, sem imports STL, geometria conduzida por parâmetros canónicos).

**Ficheiros.** `models/active/flexy_beast/flexy_beast.scad` (auto-contido: palma, dedos, polegar, liner termoformável, juntas flexíveis); `gauntlet.scad` (cópia do Cyborg desde v14.70 — ver §5); fontes de reconstrução dev-only em `models/reconstruction/flexy_beast/` (excluídas do deploy).

**Mecanismo de escala** (`flexy_beast.scad`):
- **Escala uniforme da mão** — guia de tamanhos Cyborg Beast:
  ```
  xScaleFactor = (palm_breadth_mm + 5) / 55;   // isotrópico (y=z=x)
  ```
  Palma (`cyborgbeastpalm`), polegar, cutouts de hardware e abas de pulso são todos envolvidos em `scale([xScaleFactor,…])`.
- **Comprimento dos dedos** — âncora anatómica: a scale=1 o alcance é `fingerbase(20)+fingertip_curved(17)=37 mm`, codificado como `REF_FINGER_MM=37` e invertido:
  ```
  fingerLength = middle_finger_length_mm / (REF_FINGER_MM * xScaleFactor);
  ```
  (é o multiplicador *residual* de comprimento sobre a escala uniforme, para o dedo médio alcançar `middle_finger_length_mm` a qualquer escala de palma.)
- **Proporções por dedo** relativas ao médio: `indexProp = index_finger_length_mm / middle_finger_length_mm` (idem ring/pinky/thumb). Cada dedo é emitido como `fingerlayout(<prop>·fingerLength)`, que escala os dois segmentos (base 20 mm, tip 17 mm) pelo mesmo multiplicador.
- **Colocação derivada** (não hardcoded): os quatro dedos numa pitch `sp=14` × `xScaleFactor`, na linha dos nós; o polegar reutiliza a geometria dos dedos via `thumbProp`.

**Parâmetros antropométricos** (6 canónicos, grupo `Anthropometric`): `palm_breadth_mm` (→ `xScaleFactor`), `middle_finger_length_mm` (→ `fingerLength` e denominador dos `*Prop`), `index/ring/pinky_finger_length_mm` (→ `*Prop`), `thumb_length_mm` (→ `thumbProp`). **Não** usa o split proximal/distal (base/tip derivam como frações fixas 20/17 de um multiplicador). `mirrored` (`role:"laterality"`).

**Juntas flexíveis (v14.34).** A placa STL medida foi substituída por um `flexy_joint()` paramétrico (dogbone de duas lobas + membrana flexível), com todas as dimensões derivadas do hardware (`joint_dia`, `joint_thick`) e da escala.

**Versões-chave:** v9.1.0 (add paramétrico); v11.0.0 (correção da ponte perfil→modelo, remoção do `applyGeometryParameters` morto); v13.1–13.2 (gauntlet + charneira de pulso); v14.34 (`flexy_joint()`); **v14.70 (gauntlet partilhado com o Cyborg — §5)**.

### 3.2 Cyborg Beast

**Estado herdado.** Cyborg Beast MakerBlock / e-NABLE (parafusos Chicago + cordão elástico). Três módulos originais foram `include`d praticamente intactos: `cyborgpalm001.scad` (palma; `hardwarecutouts()` já define os eixos de charneira do nó em `y=27` e do pulso em `y=-27, z=5.5`), `cyborgfingermid002.scad` (falange proximal `fingermid`, com alavanca nativa `len` e furos em `±(11.5+len/3)`), `cyborgfingertip002.scad` (falange distal). Toda a camada paramétrica vive no wrapper **`cyborg_beast.scad`** (novo, v14.32.0).

**Escala:**
```
overall_scale = (palm_breadth_mm + 5) / 55;   // aplicado no topo: scale(overall_scale)
```
Curva de alcance medida (por-dedo, via `len`):
```
R(len) = 60.85 + 1.584·len   (len ≥ 0)
R(len) = 60.85 + 1.328·len   (len < 0)
```

**Divisão proximal/distal (v14.37 — a funcionalidade antropométrica de topo).** Cada segmento impresso ganhou a sua própria alavanca: base → `lp` (`fingermid`), tip → `ld` (`fingertip`). O vão proximal é **analítico**:
```
vão proximal (MCP→PIP) = 23 + (2/3)·lp
```
O alcance distal é resolvido **por diferença** para o comprimento total se manter (`DREACH0 = 60.85 − 23 = 37.85`), com funções de inversão `base_lp(base_mm)` / `tip_ld(total_mm, base_mm)`. `place_finger()` assenta o dedo na linha dos nós com `yoff = 9.5 + lp/3` (v14.35), mantendo o pino coaxial para qualquer split. Com `lp==ld` reduz-se exatamente ao dedo nativo (render retrocompatível).

O **polegar** é calibrado por render (escala uniforme do sub-conjunto): `reach_local = 55.84 + 0.6185·lp + 0.77·ld` (ajuste em grelha 5×4, resíduo máx. 0.74 mm); `thumb_scale()` preserva o comprimento total.

**Parâmetros antropométricos:** `palm_breadth_mm` (→ `overall_scale`), comprimentos totais dos dedos, `thumb_length_mm`, e **`*_base_length_mm` → `digits.<f>.proximal_length_mm`** (o split), e `wrist_circumference_mm` (gauntlet). **Descoberta:** o schema do importador (`anthropometricImporter.js`) já definia `digits.<f>.proximal/middle/distal_length_mm` (rácios `PHALANX_RATIOS` 0.45/0.31/0.24; polegar 0.54/0.46) mas **nunca fora ligado a nenhum SCAD** — o split plumbou-o pela primeira vez.

**Gauntlet (v14.40).** `gauntlet.scad` reconstrói o *Normal Gauntlet with Tensioner* como **polyhedron orgânico embebido** (~8000 faces, ~99% do volume; sem import STL), com os furos re-cortados parametricamente (argumentos de módulo, não globais). Dimensionamento anisotrópico `[g_hinge, g_len, g_depth]`:
```
g_hinge = (G_FIN_X − 2.6) / G_PRONG_X          // X fixo à palma (prongs 2.6 mm dentro das abas)
g_depth = (wrist_circumference_mm/π + 6) / (G_NATIVE_W · overall_scale)   // girth ao pulso
g_len   = gauntlet_length_scale
```
Auto-assenta no eixo do pino do pulso (`G_PIN_Y=-27, G_PIN_Z=5.5`) resolvendo `g_seat` após a rotação/escala, para qualquer girth/comprimento/tilt. Registado como dependência para o loader WASM. Parâmetros: `show_gauntlet`, `wrist_circumference_mm`, `gauntlet_tilt`, `gauntlet_length_scale`, `wrist_pin_dia`/`wrist_pin_clearance`, `gauntlet_rim_hole_d`.

**Calibração do polegar (v14.44).** Medição vs. STLs de referência (`Thumb_Phal.stl`=31.2 mm, `Thumb_Finger_w_Bumps.stl`=36.5 mm) mostrou a base ~6 mm curta; correção: `THUMB_BASE_REACH` 44.93→51.3 mm e default `thumb_base_length_mm` 22→27 → base e tip a <0.1 mm dos originais.

**Versões-chave:** v14.32 (wrapper antropométrico), v14.35 (assentamento), v14.37 (split), v14.40/14.41 (gauntlet), v14.44 (polegar).

### 3.3 Paraglider · Hand Reborn

**Estado herdado.** Base "Flexible Flyer"/Paraglider de Marcus Mendenhall (2020, CC BY-SA 4.0). A palma **não** é geometria procedural pura — assenta numa mesh importada (`palm_left_v2_nobox.stl`, mesh Phoenix v2) mais furação/canais processados. Upstream usava `overall_scale=1.25` hardcoded por ficheiro, e construções `each`/`[[..],,[..]]` incompatíveis com o WASM (corrigidas).

**Ficheiros:** `paraglider_hand.scad` (wrapper autorado), `paraglider_palm_left.scad` (palma Reborn, `scaled_palm()`), `fingerator.scad`, `pipe.scad`, `pg_v3palm.scad` (palma UnlimbitedV3), `pg_box/gauntlet/arm.scad` (componentes namespaced via `scripts/namespace_scad.py`). Distinção crítica: o wrapper puxa a palma Reborn com **`use`** (âmbito lexical) e a V3 com **`include`**.

**Escala:**
```
overall_scale = palm_breadth_mm / 66.4;                  // REF_PALM=66.4 (default 83 → 1.25)
global_scale  = middle_finger_length_mm / 57.6;          // REF_FINGER=57.6 (72 → 1.25)
index_scale   = index_finger_length_mm  / 57.6;          // idem ring/pinky
```
Cada dedo escala pelo seu próprio comprimento (recebe `fscale` como argumento de módulo → `_sf = fscale/global_scale`); os furos de pino são divididos de volta (`d/scale_size`) para manterem tamanho físico constante.

**Bug corrigido (v14.17).** A palma Reborn **não** escalava com `palm_breadth_mm` — congelada em 113.70×100.80×38.19 mm (o tamanho 83 mm à escala 1.25) para qualquer largura. **Causa:** `scaled_palm()` vive em `paraglider_palm_left.scad` (que assa `overall_scale=1.25`) e era puxada com `use` (lexical), ignorando o `overall_scale` do wrapper; os dedos escapavam por receberem a escala como argumento. **Correção:** `scale(overall_scale / 1.25) scaled_palm()` no call site. Verificado: 62→84.9, 83→113.7 (inalterado), 96→131.5 mm. A palma UnlimbitedV3 já estava correta (`include`).

**Parâmetros antropométricos.** `palm_breadth_mm` (deforma a palma), `index/middle/ring/pinky_finger_length_mm` (deformam os dedos). **Nota honesta:** só **5 dos 8** campos canónicos deformam geometria — `palm_length_mm`, `palm_thickness_mm` e `thumb_length_mm` são armazenados para alinhamento perfil/IA mas não reesculpem a mesh (a palma é escalada uniformemente pela largura; o polegar segue o `global_scale`). `mirrored` (`role:"laterality"`).

**Componentes (v14.11).** Consolidado de 7 modelos separados num só com seletores `component` (Hand/Box/Gauntlet/Arm) e `palm_style` (Reborn/UnlimbitedV3). Os acessórios `ARM_*`/`GAU_*` usam dimensões nativas próprias, não o conjunto canónico (não são conduzidos pelas medidas do paciente).

**Versões-chave:** v7.0/7.1 (ativação paramétrica + alinhamento canónico), v7.7 (comprimento por dedo), v14.11 (consolidação), v14.17 (correção da escala da palma).

### 3.4 UnLimbited Phoenix

**Estado herdado.** Team UnLimbited Phoenix Hand V1.0 (Davies & Murray; Phoenix original de Jason Bryant; CC BY-NC-SA). O ficheiro pristino está preservado em `UnLimbitedPhoenix_original.scad`. Superfície paramétrica mínima: seletor `part`, uma escala global `HandPerc` (100–160%), e `LeftRight`. As **meshes são fixas** (STL/polyhedron embebidos), por isso a estratégia foi construir a camada paramétrica *à volta* delas sem distorcer os furos de pino.

**Ficheiros (dependências registadas para o loader WASM):** `UnLimbitedPhoenix.scad` (servido), `phoenix_assembly.scad` (receita partilhada), `phoenix_preview_meshes.scad` (meshes manifold para a preview), `phoenix_snap_pins.scad`, `phoenix_tensioner_block.scad`, `phoenix_tensioner_pins.scad` (reconstruções B-rep medidas do STEP via step2scad).

**Escala da palma:**
```
HandPerc = HandPerc_override > 0
    ? max(100, min(160, HandPerc_override))
    : max(100, min(160, palm_breadth_mm / 82 * 100));   // REF_PALM_BREADTH = 82
```
O render final aplica `scale([HandPerc/100,…])`. A **correção v14.18** clampou **ambos** os percursos a 100–160% (a banda `1–99` do override era uma zona morta sem piso — na simulação de IA uma criança saía a 76%/62 mm).

**Comprimento paramétrico por dedo (v14.48) — o núcleo antropométrico.** Como as meshes são fixas e têm furos, um dedo é alongado esticando **só a banda de haste sem furos**, mantendo as zonas de dobradiça intactas e empurrando a extremidade. Parâmetros `index/middle/ring/pinky/thumb_finger_length_mm` (total) + `*_base_length_mm` (proximal), com os nomes canónicos → auto-preenchidos por `profileMapping.js`. Referência nativa 72/31 (defaults renderizam idênticos ao dedo de série). Mecanismo em `phoenix_assembly.scad`:
```
REF_PROX = 31;  REF_DIST = 41;                 // 31 + 41 = 72
bd_of(i) = FBASE[i] − REF_PROX;                // extra proximal
td_of(i) = (FLEN[i] − FBASE[i]) − REF_DIST;    // extra distal

module stretch_shaft(ylo, yhi, d){             // 3 bandas em Y:
  intersection(){ children(); …acima de yhi… }               // extremidade de dobradiça: fixa
  translate([0,yhi,0]) scale([1,(yhi-ylo+d)/(yhi-ylo),1])…    // banda de haste: esticada
  translate([0,-d,0]) intersection(){ children(); …abaixo… }  // extremidade oposta: transladada
}
ph_col_s(i,bd) = stretch_shaft(20, 42, bd) …    // proximal: MCP fixo, PIP empurrado
fn_col_s(i,td) = stretch_shaft(-48,-14, td) …    // distal: PIP fixo, ponta empurrada
```
Como as zonas de furo nunca são escaladas (só fatiadas e mantidas/transladadas rigidamente), **os furos de pino ficam redondos**. O pino PIP e a ponta acompanham o proximal alongado (`translate([0,PIP_HOLE_Y+bd_of(f),…]) pin(…)`), mantendo a junta coaxial. Efeito 1:1 (médio 72→100 → alcance +27.6 mm).

**Componentização.** Preview de mão montada + `phoenix_assembly.scad` partilhado (v14.36); correções de manifold da preview (v14.41–14.45); toggles por peça `show_palm/fingers/thumb/pins/gauntlet/tensioner` + `print_layout` (v14.45); cores por peça `color_*` (v14.46).

**Parâmetros antropométricos:** `palm_breadth_mm`, comprimentos totais + `*_base_length_mm`. `mirrored` (`role:"laterality"` — ver §6). `HandPerc_override` (override manual de escala).

**Versões-chave:** v14.3 (integração + HandPerc), v14.18 (clamp), v14.36 (montagem + hardware STEP), v14.41–45 (preview manifold), v14.46 (cores), v14.48 (comprimento por dedo).

---

## 4. Correções transversais no pipeline IA/grounding

Não alteram geometria, mas garantem que os dados antropométricos certos chegam aos modelos.

- **Matcher de perfis (v14.16).** `findBestProfileMatch` ancorava quase todos os pacientes no *ANSUR I Male* (o token `'m,'` era substring de `"mm,"`/`"cm,"`; parsing só em inglês). Agora tokens em fronteiras `\b` Unicode e **multilingues (EN/PT/ES)**, idade entende "anos"/"años", `age_group` numérico bucketizado; mais extração LLM opcional de `{gender,age}` (`extractPatientAttributes`, `claude-haiku-4-5`) quando o parser determinístico falha.
- **Lateralidade UI-only (v14.19).** Uma avaliação UCD encontrou um defeito de segurança: a IA emitia `mirrored=true` independentemente do lado pedido. Agora os parâmetros de lado têm `role:"laterality"`; o `app.js` exclui-os da lista sugerível, injeta o lado escolhido como facto fixo, e descarta defensivamente qualquer chave de lateralidade em `applySuggestions`.

---

## 5. Unificação do gauntlet Flexy ↔ Cyborg (v14.70.0)

O Flexy Beast e o Cyborg Beast **partilham a palma do Cyborg Beast** — mesmo eixo do pino de pulso (`Y=-27, Z=5.5`), mesmas abas (`|X|=26.6`) e mesma fórmula de escala `(palm_breadth+5)/55`. Logo, **uma peça encaixa em ambos**. O gauntlet primitivo inline do Flexy (~120 linhas de módulos `g_*`) foi **removido** e substituído por uma cópia do `gauntlet.scad` orgânico do Cyborg (§3.2), com a matemática de assentamento portada verbatim, envolvida na escala uniforme do Flexy (`scale([xScaleFactor,…])`, equivalente ao `scale(overall_scale)` do Cyborg).

**Ganho antropométrico:** o gauntlet do Flexy trocou o antigo `gauntlet_width_mm` (não-canónico, derivado à mão pelo clínico) por **`wrist_circumference_mm`** (canónico) — passa assim a **auto-dimensionar-se do perfil do paciente** via `profileMapping.js`, tal como o Cyborg. Parâmetros unificados: `wrist_circumference_mm`, `gauntlet_tilt`, `gauntlet_length_scale`, `gauntlet_rim_hole_d`, `wrist_pin_dia`, `wrist_pin_clearance`.

Por decisão de projeto, o `gauntlet.scad` é **copiado** para o diretório de cada modelo (não partilhado por referência) para manter os modelos independentes. Verificado com renders OpenSCAD locais (montado, print layout, junta de pulso com furo redondo/coaxial, escala de criança).

---

## 6. Coerência de interface e normalização de parâmetros (v14.72.0)

Diagnóstico: os **nomes antropométricos já estavam alinhados** (é o propósito do §2); o que estava incoerente era a **organização da UI** — cada modelo ordenava os grupos de forma diferente e havia nomes divergentes para o mesmo conceito.

**Ordem canónica de grupos** (aplicada aos quatro modelos; grupos ausentes são saltados):
```
Component → Anthropometric → Segment split → Hardware → Gauntlet → Options → Visibility → Colors → Arm
```
O singleton "Palm liner" do Cyborg foi fundido em "Options". É uma reordenação **só de configuração** — nomes, valores e comportamento inalterados.

**Dois renames de normalização:**
- **Lateralidade:** Phoenix `LeftRight` (enum "Left"/"Right") → **`mirrored`** (boolean), igual aos outros três. `UnLimbitedPhoenix.scad` ramifica em `!mirrored`; a config usa o enum partilhado (Left=false/Right=true, `role:"laterality"`). **Sem migração necessária:** a lateralidade nunca é restaurada de configs guardadas (é saltada no `applySuggestions`), pelo que o rename não pode trocar silenciosamente uma mão guardada.
- **Toggle de vista:** Paraglider `show_assembled` (true=montado) → **`print_layout`** (true=plano), igual a Cyborg/Phoenix. `paraglider_hand.scad` ramifica em `print_layout`; o `exportLayout` do modelo passou a `{print_layout:true}`. É um toggle de pré-visualização, sobreposto no export — sem impacto geométrico em configs guardadas.

Ficam por normalizar apenas divergências **semânticas** legítimas (esquemas de cor/visibilidade por-segmento vs. por-dedo, conforme a geometria tenha 1 ou 2 segmentos; hardware específico como as juntas flexíveis) — forçar nomes idênticos aí pioraria a clareza.

---

## 7. Como foi validado

- **Simulação de sizing por IA → export STL** (Flexy, Paraglider, UnLimbited Phoenix) — revelou os bugs de escala/clamp/lateralidade. Relatórios em `tests/flexy-beast-ai-sim/`, `tests/paraglider-ai-sim/`, `docs/phoenix-ai-sim/`, `docs/ucd-ai-sim/`.
- **Provas dimensionais/MD5** dos STLs exportados (palma congelada do Paraglider; Phoenix mesh × HandPerc/100 a ≤0.06 mm; polegar do Cyborg a <0.1 mm dos STLs de referência).
- **Testes unitários herméticos** do matcher (`test/profileMapping.test.js`).
- **Testes E2E de export** (`tests/cyborg_export.spec.js`).
- **Renders OpenSCAD locais** para a unificação do gauntlet e os renames (Phoenix esquerda/direita/print; Paraglider montado/plano).
- **Suite de avaliação da tese** `test/thesis/` (REP/ROB/ACC), com as fixtures sincronizadas aos parâmetros atuais.

---

## 8. Síntese

| Modelo | Estado herdado | O que foi feito | Versões |
|---|---|---|---|
| **Flexy Beast** | escala fixa; charneira e gauntlet como meshes/STL | escala `(palm_breadth+5)/55`; dedos antropométricos (`REF_FINGER=37`); `flexy_joint()` paramétrico; gauntlet **partilhado com o Cyborg** por `wrist_circumference_mm` | v9.1, v13.1–13.2, v14.34, v14.70 |
| **Cyborg Beast** | Chicago-screw; dedos de 1 alavanca; sem gauntlet paramétrico | wrapper antropométrico; split proximal/distal analítico (`*_base_length_mm`); gauntlet orgânico auto-assente por `wrist_circumference_mm`; polegar calibrado vs STLs | v14.32, v14.37, v14.40, v14.44 |
| **Paraglider Reborn** | palma congelada a 1.25 (`use`+hardcoded) | palma volta a escalar (`scale(overall_scale/1.25)`); dedos paramétricos por dedo (`REF_FINGER=57.6`); consolidação multi-componente | v7.x, v14.11, v14.17 |
| **UnLimbited Phoenix** | meshes fixas; só escala global; override furava o piso | comprimento por dedo via `stretch_shaft` (haste sem furos); clamp 100–160%; hardware STEP; montagem/toggles/cores | v14.3, v14.18, v14.36, v14.45–48 |
| **(transversal)** | matcher ancorava tudo em ANSUR I Male; IA forçava mão direita | matcher multilingue + fallback LLM; lateralidade UI-only role-based | v14.16, v14.19 |
| **(coerência)** | grupos e nomes divergentes entre modelos | ordem canónica de grupos; `LeftRight→mirrored`; `show_assembled→print_layout` | v14.72 |

**Conclusão.** Cada prótese ativa teve de ser reconstruída ou corrigida para responder à antropometria: umas em SCAD paramétrico próprio (Flexy, Cyborg), outras com uma camada paramétrica à volta de meshes fixas (Phoenix, palma do Paraglider). A ligação perfil→modelo é centralizada em `profileMapping.js` sobre nomes canónicos; o gauntlet foi unificado entre os dois modelos que partilham a palma; e a interface foi normalizada para uma experiência coerente entre modelos. Todo o percurso foi validado por simulações de sizing, provas dimensionais e renders.
