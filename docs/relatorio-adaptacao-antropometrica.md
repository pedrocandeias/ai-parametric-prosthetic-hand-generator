# Relatório — Adaptação dos modelos de prótese aos dados antropométricos

**Projeto:** AI Parametric Prosthetic Hand Generator
**Âmbito:** o que teve de ser alterado nos modelos ativos da plataforma para que respondessem aos dados antropométricos, e como foi feito.
**Nota:** este relatório **exclui o modelo pec Phoenix** por indicação expressa.

---

## 1. Contexto e problema

Os modelos que a plataforma herdou (STL/SCAD de projetos de terceiros da comunidade e-NABLE) **não** estavam preparados para consumir medições antropométricas. Na prática apresentavam três padrões problemáticos:

- **escala fixa/hardcoded** (o modelo imprimia sempre no mesmo tamanho, independentemente do paciente);
- **parâmetros com nomes incompatíveis** com o pipeline de importação antropométrica;
- **acoplamentos escondidos** (partes com escala congelada dentro de sub-ficheiros SCAD, ou percursos de dimensionamento com limites inconsistentes).

O objetivo do trabalho foi tornar cada prótese ativa **paramétrica e ancorada na anatomia do paciente**, mantendo os nomes de campo canónicos definidos em `CLAUDE.md` (secção *Anthropometric Parameter Alignment*), de forma a que um perfil importado (CSV → base de dados) possa auto-preencher os parâmetros corretos do modelo.

---

## 2. A ponte de dados — `profileMapping.js`

O elo central entre o **perfil antropométrico armazenado** e o **modelo paramétrico vivo** é `server/services/profileMapping.js`. É a **única fonte de verdade** desta tradução, usada tanto pelo seletor "Population baseline" da configuração como pelo grounding da IA.

**Decisão de arquitetura chave:** o mapeamento parte da árvore anatómica normalizada `profile.measurements` (ex.: `palm.width_mm`, `digits.middle.total_length_mm`) e **não** dos `geometry_parameters` do importador. Os `geometry_parameters` foram construídos para o design socket-and-phalanx Kwawu/cyborgbeast (chaves como `finger_length_index`, bloco `pekwawu`) e **nenhum** coincide com os nomes canónicos dos modelos. A `profile.measurements` alinha 1:1 com a coluna "Platform source" da tabela em `CLAUDE.md`.

Mapa canónico (`PARAM_TO_MEASUREMENT_PATH`):

| Parâmetro do modelo (SCAD/config) | Caminho em `profile.measurements` |
|---|---|
| `palm_breadth_mm` | `palm.width_mm` |
| `palm_length_mm` | `palm.length_mm` |
| `palm_thickness_mm` | `palm.thickness_mm` |
| `index/middle/ring/pinky_finger_length_mm` | `digits.<dedo>.total_length_mm` |
| `thumb_length_mm` | `digits.thumb.total_length_mm` |
| `*_base_length_mm` (proximal) | `digits.<dedo>.proximal_length_mm` |
| `wrist_circumference_mm` | `wrist.circumference_mm` |

`mapProfileToModelParameters(profile, modelDef)` percorre os parâmetros do modelo e só aplica um valor quando este (a) existe no modelo, (b) é numérico, (c) está no mapa canónico e (d) tem uma medição finita no perfil — **fazendo clamp aos min/max declarados** de cada parâmetro. Parâmetros não anatómicos (hardware, visibilidade, lateralidade) nunca são tocados.

Usado por:
- `GET /api/anthropometric/:id/model-parameters` (seletor de baseline populacional na configuração);
- grounding da IA em `aiRoutes.js` (`patient_text` + `model_id` → `findBestProfileMatch` → `buildGroundingBlock` anexado ao prompt).

---

## 3. Alterações por modelo

### 3.1 Flexy Beast

**Dimensionamento antropométrico.** A escala global da mão passou a derivar da fórmula do guia de tamanhos do Cyborg Beast: `xScaleFactor = (palm_breadth_mm + 5) / 55`. Todos os comprimentos de dedos são conduzidos anatomicamente (`middle_finger_length_mm` como comprimento-mestre, com o alcance de referência `REF_FINGER × xScaleFactor`); as proporções por dedo são inferidas dos comprimentos individuais relativamente ao dedo médio. Os campos expostos seguem os nomes canónicos: `palm_breadth_mm`, `index/middle/ring/pinky_finger_length_mm`, `thumb_length_mm`.

**Reconstrução paramétrica do gauntlet (v13.1.0, 2026-06-14).** O `Normal_Gauntlet_w_Tensioner.stl` foi feito reverse-engineering para um gauntlet totalmente paramétrico, construído **só com primitivas** (meio-tubo oval cónico = `hull` de discos elípticos, shelled, abertura palmar cortada por uma caixa; boss do tensor; ranhuras de crenelação triangulares; furos dorsais; dois straps distais). Módulos com prefixo `g_` e `$fn`-scoped → **compatível com OpenSCAD-WASM** (sem BOSL2) e isolado da geometria da mão. Novos parâmetros no grupo `[Gauntlet]`: `show_gauntlet`, `gauntlet_width_mm`, `gauntlet_length_mm`, `gauntlet_wall_mm`, `gauntlet_pos_adjust`. É uma peça impressa à parte, posicionada no pulso e escalada pelas suas próprias dimensões de antebraço (independente da largura dos nós dos dedos).

**Pulso articulado (v13.2.0).** Adicionado um `wrist_pin()` impresso (haste com cabeça) que encaixa por pressão nas abas do pulso da palma; os straps auto-abrem (`g_splay`) para assentar por dentro das abas e rodar no pino. O furo do pino é perfurado **redondo em espaço de assembly** (a escala `g_sx≠g_sy` do cuff tornaria elíptico um furo perfurado nativamente). Novos parâmetros `[Wrist Hinge]`: `show_wrist_pin`, `wrist_pin_dia`, `wrist_pin_clearance`, `strap_splay_adjust`.

**Organização (v13.4.0).** As fontes de reconstrução (mesh de origem, variantes orgânica + primitiva, dados de perfis/straps, STLs) foram movidas para `models/reconstruction/flexy_beast/` (só desenvolvimento, excluídas do deploy); `models/active/flexy_beast/` mantém apenas o ficheiro de plataforma `flexy_beast.scad` (que já inlinea o gauntlet acabado).

### 3.2 Cyborg Beast

**Gauntlet paramétrico próprio (v14.40.0, 2026-07-10).** O mesmo gauntlet reconstruído foi integrado como dependência própria `models/active/cyborg-beast/gauntlet.scad` (incluída pelo `cyborg_beast.scad` e registada em `models-config.json` `dependencies` para o carregador WASM a montar). O cuff **auto-assenta** no eixo do pino do pulso da palma (as prongas encaixam dentro das abas e acompanham o pino para qualquer girth/comprimento/tilt) e é dimensionado ao utilizador por `wrist_circumference_mm` (largura do cuff = `circunferência/π + folga`), **independentemente da escala da mão**. Parâmetros: `show_gauntlet`, `wrist_circumference_mm`, `gauntlet_tilt`, `gauntlet_length_scale`, `wrist_pin_dia` + `wrist_pin_clearance`, `gauntlet_rim_hole_d`, e a 12.ª cor por-peça `color_gauntlet` (gravada no 3MF). Verificado E2E em `tests/cyborg_export.spec.js`.

**Divisão de falanges proximal/distal (v14.37.0, 2026-07-10).** Dedos e polegar ganharam controlo independente do segmento **base (proximal)** e **tip (distal)**. Novos parâmetros `index/middle/ring/pinky/thumb_base_length_mm` = comprimento da falange proximal (MCP→PIP; polegar MCP→IP); o distal preenche o restante para o comprimento total do dedo se manter fixo. Os defaults (22/24/22/16/22) reproduzem exatamente a proporção nativa de `len` partilhado (render retrocompatível).

- **Dedos — analítico:** vão proximal = `23 + 2·lp/3`; alavanca distal resolvida a partir da curva de alcance `R = 60.85 + slope·len`; assento `place_finger = 9.5 + lp/3`; tip empurrado `23 + lp/3 + ld/3` para manter o pino PIP coaxial.
- **Polegar — calibrado por render:** `reach_local = 55.84 + 0.6185·lp + 0.77·ld` (ajuste em grelha 5×4, resíduo máx. 0.74 mm); offset de junção PIP `−(23.667 + lp/3 + ld/3)`.

**Descoberta importante:** o schema do importador antropométrico (`anthropometricImporter.js`) **já definia** `digits.<dedo>.proximal_length_mm` / `middle_length_mm` / `distal_length_mm` (dedos) e `digits.thumb.proximal/distal_length_mm`, com `PHALANX_RATIOS` (proximal 0.45 / middle 0.31 / distal 0.24; polegar 0.54/0.46) — mas **nunca tinham sido ligados a nenhum parâmetro SCAD**. Agora `profileMapping.js` mapeia `*_base_length_mm → digits.<dedo>.proximal_length_mm`. O dedo impresso de 2 segmentos mapeia anatomicamente proximal→base e middle+distal→tip.

### 3.3 Paraglider · Hand Reborn — correção de escala da palma (v14.17.0, 2026-06-28)

**Bug:** a palma Reborn (o `palm_style` por defeito) **não escalava** com `palm_breadth_mm` — a palma exportada era byte-idêntica (MD5) para larguras 62/78/83/96 mm, congelada em 113.70×100.80×38.19 mm (o tamanho "médio" de 83 mm à escala 1.25). Os dedos escalavam bem.

**Causa-raiz:** `scaled_palm()` vive em `paraglider_palm_left.scad`, que é puxado com `use` (âmbito lexical), por isso lia o `overall_scale = 1.25` hardcoded **nesse ficheiro** e ignorava o `overall_scale = palm_breadth_mm / 66.4` calculado no ficheiro principal. Os dedos escapavam porque recebem a escala como argumento de módulo.

**Impacto clínico:** uma criança (largura 62 mm) obtinha dedos de criança numa palma de adulto — proporções quebradas, mão inutilizável.

**Correção:** re-aplicar a escala pretendida no call site do Reborn — `scale(overall_scale / 1.25) scaled_palm();` (o módulo assa 1.25, logo o efeito líquido é `palm_breadth_mm/66.4`). Verificado: palma escala (62→84.9 mm, 83→113.7 mm inalterado, 96→131.5 mm), rácio L/largura constante, sem regressão a 83 mm. O percurso UnlimbitedV3 já estava correto (usa `include`).

### 3.4 UnLimbited Phoenix

O Phoenix foi o modelo que recebeu a parametrização mais extensa. Ao contrário do Flexy Beast (geometria própria escalável), as meshes do Phoenix são **fixas** (STL/polyhedron importados), pelo que a estratégia foi diferente: manter as meshes e adicionar à volta delas uma camada paramétrica (comprimento por dedo, montagem, visibilidade, cor) sem distorcer as zonas funcionais (furos de pino). Componentes adicionados:

**(a) Comprimento paramétrico por dedo — os cinco dígitos (v14.48.0).** Esta é a adição antropométrica central. Cada dedo e o polegar passam a ser dimensionáveis ao paciente com novos parâmetros `index/middle/ring/pinky/thumb_finger_length_mm` (total MCP→ponta, grupo *Anthropometric*) + `*_base_length_mm` (proximal MCP→PIP, grupo *Segment split*), que **correspondem exatamente aos nomes canónicos de `CLAUDE.md`** — logo os perfis importados populam-nos automaticamente via `profileMapping.js` (secção 2). Como as meshes são fixas, um dedo é alongado **dividindo a coluna na zona de haste sem furos**, mantendo as zonas de dobradiça (furos) por escalar, esticando só a haste e empurrando a extremidade — os furos de pino ficam perfeitamente redondos e imprimíveis. Referência nativa 72/31, por isso os defaults renderizam idênticos ao dedo de série; o pino PIP e a ponta acompanham o proximal alongado, e o layout de impressão plano exporta cada dígito ao seu comprimento. Verificado: alteração 1:1 (médio 72→100 → alcance da ponta +27.6 mm), o split base redistribui proximal/distal com o total constante, os furos ficam redondos e a mão renderiza manifold sem regressão nos defaults.

**(b) Componentes de hardware reconstruídos (medidos do STEP).** O tensor e os pinos deixaram de ser reconstruções ajustadas à mão e passaram a peças B-rep medidas face-a-face do ficheiro STEP (step2scad): `phoenix_tensioner_block.scad`, `phoenix_tensioner_pins.scad`, `phoenix_snap_pins.scad`. Registados como `dependencies` do modelo para o carregador WASM os montar.

**(c) Pré-visualização de mão montada + receita partilhada (v14.36.0).** O modelo passou a abrir numa **pré-visualização da mão montada** (palma, quatro dedos, polegar, pinos, gauntlet, tensor e anilhas todos assentes), conduzida pelo mesmo `palm_breadth_mm`/`HandPerc` e envolvida num `scale()` uniforme (mantém-se assente a qualquer tamanho e espelha para a mão direita). A receita foi extraída para um módulo partilhado `phoenix_assembly.scad` (fonte única, `include`d tanto pelo modelo servido como pelo harness de dev). Seguiram-se correções de manifold da preview (`phoenix_preview_meshes.scad`, v14.41–14.45) para o backend manifold do browser não descartar as meshes não-manifold da palma/pontas.

**(d) Controlos de visibilidade por peça (v14.45.0).** O antigo dropdown `part` foi substituído por toggles sempre visíveis — `show_palm`, `show_fingers`, `show_thumb`, `show_pins`, `show_gauntlet`, `show_tensioner` — mais um `print_layout` (preview montado ↔ layout plano para export STL), alinhando com o padrão do Cyborg Beast/Flexy Beast.

**(e) Cores por peça (v14.46.0).** Toda a mão montada ficou recolorável a partir da UI: `color_palm`, `color_index/middle/ring/pinky`, `color_thumb`, `color_pins`, `color_gauntlet`, `color_washers`, `color_tensioner_block`, `color_tensioner_pins` (injetadas no `phoenix_assembly.scad`, gravadas no 3MF).

**(f) Correção do piso de escala inconsistente (v14.18.0, 2026-06-28).** O modelo dimensionava a palma por dois percursos com **pisos inconsistentes**:
- `palm_breadth_mm` → `HandPerc = max(100, min(160, palm_breadth_mm/82*100))` — com piso a 100% (o autor recomenda o Flexy Beast para mãos mais pequenas);
- `HandPerc_override` (range declarado `[0:160]`) → `override>0 ? override : auto`, mas a banda **1–99 era uma zona morta sem piso**.

Na simulação de sizing por IA, para uma criança o modelo devolveu `HandPerc_override = 76` → palma a **76% (62 mm)**, abaixo do mínimo suportado; para a mulher (também <82 mm) deixou `override=0` e fez piso a 100%/82 mm — ou seja, a IA contornava o piso **de forma inconsistente**.

**Correção:** ambos os percursos passam a fazer clamp a 100–160% — `HandPerc = HandPerc_override > 0 ? max(100, min(160, HandPerc_override)) : max(100, min(160, palm_breadth_mm/82*100))`. Verificado: override 76→100% (82.17 mm), 0→82.17 mm, 130→106.8 mm. Nenhum percurso desce abaixo de 100%.

---

## 4. Correções transversais no pipeline IA/grounding

Estas não alteram a geometria, mas garantem que os dados antropométricos certos chegam aos modelos.

### 4.1 Matcher de perfis populacionais (v14.16.0, 2026-06-28)

`findBestProfileMatch` ancorava quase todos os pacientes no *ANSUR I Male 50th Percentile*. Causas: o token de género masculino `'m,'` é substring das unidades `"mm,"`/`"cm,"` (qualquer texto com uma medição era lido como masculino) e o parsing de género/idade era **só em inglês**.

**Correção:** tokens agora casados em fronteiras de palavra Unicode e **multilingues (EN/PT/ES)**; idade entende "anos"/"años"; valores numéricos de `age_group` ("7", "18-30", "80+", "Adult (Military, 17–40)") são bucketizados em criança/adulto/idoso por proximidade numérica. Adicionalmente, extração LLM opcional de `{gender, age}` (`extractPatientAttributes` em `aiService.js`, via `claude-haiku-4-5`) que corre só quando o parser determinístico deixa lacunas e degrada com elegância. Testes unitários herméticos em `test/profileMapping.test.js` (`npm run test:unit`). Após a correção: mulher→ANSUR I Female, criança 7→Dutch children age 7, homem→ANSUR I Male.

### 4.2 Lateralidade controlada só pela UI (v14.19.0, 2026-06-29)

Uma avaliação UCD encontrou um **defeito de segurança**: a IA emitia `mirrored=true` (mão direita) independentemente do lado pedido — pedidos explícitos de mão esquerda produziam silenciosamente uma mão direita (reproduzível 4/4), que um leigo só deteta depois de imprimir.

**Correção:** os parâmetros de lado passam a estar tagueados `role:"laterality"` em `models-config.json` (`mirrored` no Flexy Beast e Paraglider, `LeftRight` no Phoenix); o `app.js` exclui-os da lista sugerível pela IA, injeta o lado escolhido pelo utilizador como facto fixo no prompt, e descarta defensivamente qualquer chave de lateralidade em `applySuggestions`. Verificado: a IA omite `mirrored` em 9/9 execuções (incl. conflito UI-esquerda / texto-direita). Desenhado de forma genérica como **lateralidade** (não "handedness"), pronto para qualquer membro par futuro (braço, pé, perna).

---

## 5. Como foi validado

- **Simulação de sizing por IA → export STL** para Flexy Beast, Paraglider e UnLimbited Phoenix (foi este harness que revelou os bugs das secções 3.3, 3.4, 4.1 e 4.2). Relatórios em `tests/flexy-beast-ai-sim/`, `tests/paraglider-ai-sim/`, `docs/phoenix-ai-sim/`, `docs/ucd-ai-sim/`.
- **Prova numérica por MD5/dimensões** dos STLs exportados (ex.: Paraglider palma congelada; Phoenix mesh × HandPerc/100 a ≤0.06 mm).
- **Testes unitários herméticos** do matcher (`test/profileMapping.test.js`).
- **Testes E2E de export** (`tests/cyborg_export.spec.js`, incl. o conjunto de 12 cores com o gauntlet).

---

## 6. Síntese

| Modelo | Estado herdado | O que foi feito | Versão |
|---|---|---|---|
| Flexy Beast | escala fixa; sem gauntlet paramétrico | escala `(palm_breadth+5)/55`, dedos antropométricos, gauntlet reconstruído + pulso articulado | v13.1–13.2 |
| Cyborg Beast | sem gauntlet paramétrico; dedos de segmento único | nova gauntlet **paramétrica em OpenSCAD** (`gauntlet.scad`) dimensionada por `wrist_circumference_mm`; split proximal/distal por `*_base_length_mm` | v14.37, v14.40 |
| Paraglider Reborn | palma congelada a 1.25 | palma volta a escalar com `palm_breadth_mm` | v14.17 |
| UnLimbited Phoenix | meshes fixas; só escala global de palma; override furava o piso de 100% | comprimento paramétrico por dedo + split proximal (`*_finger_length_mm`/`*_base_length_mm`, canónicos) via split de haste sem furos; hardware medido do STEP (tensor/pinos); preview montada + `phoenix_assembly.scad`; toggles por peça; cores por peça; clamp de ambos os percursos a 100–160% | v14.18, v14.36, v14.45–14.48 |
| (transversal) matcher | ancorava tudo em ANSUR I Male | tokens multilingues + fallback LLM | v14.16 |
| (transversal) lateralidade | IA forçava mão direita | lado é escolha de UI, excluída da IA | v14.19 |

**Conclusão:** sim, cada prótese ativa teve de ser tocada. Umas foram reconstruídas de raiz em SCAD paramétrico (gauntlets, split de falanges), outras corrigidas em bugs de escala/clamp que impediam a resposta à antropometria. A ligação perfil→modelo é centralizada em `profileMapping.js`, sobre os nomes de campo canónicos de `CLAUDE.md`, e todo o percurso foi validado por simulações de sizing e provas dimensionais dos STLs exportados.
