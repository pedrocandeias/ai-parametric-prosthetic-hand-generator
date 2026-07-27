# Protocolo — Ensaios de preparação para impressão (HandFab)

**Data de execução:** 2026-07-14
**Âmbito:** gerar dados verificáveis, por linha de comando de dois fatiadores
(Bambu Studio e PrusaSlicer), sobre a **preparação para impressão** dos modelos
paramétricos da HandFab. Os valores aqui produzidos são **estimativas de
software de fatiamento**, não medições físicas.

> **Distinção fundamental.** Um fatiador estima tempo, comprimento de filamento,
> massa e volume a partir das trajectórias que planeia. Não são medições reais de
> uma impressão física, nem indicadores de desempenho estrutural. A verificação
> de malha (estanquidade, faces degeneradas) é uma propriedade **geométrica** do
> ficheiro e **não** um indicador de resistência mecânica da peça impressa.

Os ensaios organizam-se em duas **séries** complementares: **Série A** (projectos
arquivados, fatiados como preparados) e **Série B** (comparação digital
controlada). Os nomes dos ficheiros CSV conservam a designação técnica original.

---

## 1. Programas, versões e ambiente

| Item | Valor |
|---|---|
| Bambu Studio | `BambuStudio-01.10.02.76` (AppImage PR-6008) |
| PrusaSlicer | `2.8.1+linux-x64-GTK3-202409181416` |
| Python / NumPy | 3.12.3 / 2.4.4 (só na análise geométrica) |

Os *checksums* SHA-256 dos AppImage e os comandos exactos estão em
[`comandos_e_versoes.txt`](comandos_e_versoes.txt).

**Isolamento.** O AppImageLauncher do sistema interceptava os AppImage e
provocava *segfault* em modo headless; por isso os AppImage foram **extraídos** e
executou-se o binário interno (`AppRun`), como o protocolo previa. O `HOME` foi
redirigido para um directório de trabalho dedicado e o PrusaSlicer usou um
`--datadir` próprio, de modo a **não alterar os perfis globais do utilizador**.

---

## 2. Série A — projectos arquivados (fatiados como preparados)

Quatro *project files* preservados em `docs/print-validation/`:

| # | Projecto | Ficheiro | Fatiador / impressora | Material |
|---|---|---|---|---|
| 1 | Flexy Beast, 15 anos | `flexy_beast_teen_15_print.3mf` | Bambu Studio / Bambu Lab A1 | PLA |
| 2 | UnLimbited Phoenix, 15 anos | `unlimbed_phoenix_hand_teen_15_print_project.3mf` | Bambu Studio / A1 | PLA |
| 3 | UnLimbited Phoenix, 15 anos | `unlimbed_phoenix_hand_teen_15_print_project_PETG.3mf` | Bambu Studio / A1 | PETG |
| 4 | Paraglider Hand, 15 anos | `paraglider_15_teen_prusa_print_profile.3mf` | PrusaSlicer / Prusa MINI | PLA |

**Duplicado localizado:** existe uma cópia distinta (checksum diferente) do
projecto Phoenix PLA em
`unlimbed_phoenix_hand/teen_15/unlimbed_phoenix_hand_teen_15_print_project.3mf`.
A Série A usou a versão de topo (`docs/print-validation/…`).

**Descoberta metodológica.** Os quatro ficheiros contêm geometria, definições de
processo/filamento e o *layout* de placa — mas **não** os resultados de
fatiamento: no Bambu, o `slice_info.config` só tinha o cabeçalho; no PrusaSlicer,
não havia G-code embebido. Por isso cada projecto foi **re-fatiado com o seu
próprio perfil embebido** (tal como preparado) para obter tempo, filamento e
massa. O layout e a orientação foram mantidos.

**Parâmetros efectivos** (extraídos das configurações embebidas — ver
[`raw/extract_params.txt`](raw/extract_params.txt)):

- Bambu (3 casos): A1, bico 0,4 mm, perfil base "0.20mm Standard @BBL A1" mas com
  **altura de camada real = 0,24 mm** (o campo `layer_height` foi alterado; o nome
  do perfil não reflecte o valor efectivo), 2 paredes, 4 topo / 3 base, 15% grelha,
  **suportes em árvore orgânica** (só na base, regiões críticas, limiar 35°),
  `auto_brim` 5 mm. Caso 3 usa PETG (slot de filamento `GFG00`).
- PrusaSlicer (Paraglider): Prusa MINI (MINIIS), bico 0,4 mm, perfil
  "0.20mm SPEED @MINIIS 0.4", **camada 0,20 mm**, 2 perímetros, 5 topo / 4 base,
  15% grelha, **sem suportes**, sem aba.

Resultados em [`resultados_projectos_arquivados.csv`](resultados_projectos_arquivados.csv).

---

## 3. Série B — comparação digital controlada (12 casos)

Três modelos (**Flexy Beast**, **Paraglider Hand**, **UnLimbited Phoenix**) × quatro
perfis (**child_8, teen_15, adult_28, elderly_70**), fatiados sob **uma única
condição virtual comum**:

| Variável (controlo) | Valor fixo |
|---|---|
| Impressora | Bambu Lab A1, bico 0,4 mm |
| Filamento | Bambu PLA Basic @BBL A1 |
| Altura de camada | 0,20 mm |
| Paredes/perímetros | 2 |
| Enchimento | 15%, padrão grelha |
| **Suportes (política única)** | **desligados** (`enable_support = 0`) |
| Aba | `auto_brim` |
| Orientação/layout | orientação das peças mantida (`--orient 0`); o fatiador apenas coloca (`--arrange 1 --ensure-on-bed`); a 2.ª placa A1 é criada automaticamente quando não cabe numa |

> Esta série de ensaios **não** é uma impressão física nem uma recomendação de
> imprimibilidade. É uma **comparação digital controlada** da exigência de
> preparação dos três modelos à mesma escala de definições.

**Input de cada caso = conjunto de peças imprimíveis já exportadas pela
plataforma** (não o modelo montado; ver §4): Flexy 12 peças, Paraglider 7 peças,
Phoenix 8 peças.

**Nota de resolução de herança (Bambu CLI).** Ao carregar o preset de filamento de
sistema via `--load-filaments`, o CLI **não** resolvia a cadeia de herança:
`filament_density` e `filament_max_volumetric_speed` ficavam a 0, produzindo
**massa = 0 g** e tempos irreais (≈11 h). Corrigiu-se **aplanando a herança** do
preset (densidade 1,26; caudal 21 mm³/s) — ficheiro
[`raw/configs/pla_basic_a1_resolved.json`](raw/configs/pla_basic_a1_resolved.json).
Todos os 12 casos foram fatiados com o filamento resolvido.

Resultados em [`resultados_campanha_controlada.csv`](resultados_campanha_controlada.csv).

---

## 4. Análise geométrica

Parser de 3MF próprio (NumPy; extensão *production* do Bambu) — sem fatiamento.
Para cada modelo/perfil distinguem-se **três noções de tamanho** (a não confundir):

1. **Montagem sólida (mão estendida)** — a bounding box do corpo único do 3MF de
   montagem (dedos e punho estendidos). É o *vão anatómico*, **não** um layout de
   placa. Nos modelos Flexy/Paraglider este corpo excede a placa (ver §5).
2. **Palma (peça)** — bounding box da peça `palm` isolada.
3. **Placa disposta (Série B)** — footprint das peças efectivamente dispostas na
   placa A1 pelo fatiador.

Também se reporta: volume de malha, nº de corpos, estanquidade/manifold e faces
degeneradas. Para o Phoenix usou-se ainda o `render-report.json` da série de
crescimento e os 3MF individuais da palma.

Resultados em [`resultados_geometria.csv`](resultados_geometria.csv).

**Assimetria de exportação (achado).** A plataforma exporta Flexy e Paraglider
como **um corpo único montado** (além das peças), mas o Phoenix **apenas em peças
soltas** — não existe um 3MF de montagem por perfil (só o `print_project` do
teen_15). Esta diferença é registada, não contornada.

---

## 5. Custo estimado

O custo é calculado a **36,29 €/kg** — o preço de filamento do perfil Prusament
PLA emitido pelo PrusaSlicer — **assumido igual para ambos os fatiadores e para
todos os materiais** (indicação do autor). Fórmula: `custo = massa_g / 1000 ×
36,29 €`. Para o Paraglider, o valor calculado (1,38 €) **coincide** com o custo
emitido pelo próprio PrusaSlicer, o que valida a taxa. Os valores por caso estão
na coluna `custo_eur_a_36.29_por_kg` de cada CSV.

---

## 6. Limites de comparabilidade (ler antes de citar valores)

- **Estimativa ≠ medição.** Todos os tempos/filamentos/massas/custos são
  estimativas de software; variam com versão, perfil e firmware; não medem
  resistência.
- **Fatiadores diferentes na Série A.** O Paraglider foi fatiado noutro programa
  (PrusaSlicer) e noutra impressora (Prusa MINI) — os seus números **não são
  directamente comparáveis** com os três casos Bambu/A1. **Excepção legítima:** os
  dois projectos Phoenix (PLA e PETG) partilham modelo, impressora, geometria,
  camada e processo, diferindo só no material — são um contraste de material válido.
- **Altura de camada diferente na Série A.** Bambu 0,24 mm vs PrusaSlicer 0,20 mm —
  mais uma razão para não comparar linhas da Série A entre si como se fossem a
  mesma condição.
- **Série A ≠ Série B.** A Série A usa suportes (Bambu) e camada 0,24 mm; a Série B
  é sem suportes e 0,20 mm. São desenhos experimentais distintos.
- **Modelo montado não cabe na placa.** O corpo único montado de Flexy (teen 259,
  adult 296, elderly 273 mm) e **todos** os Paraglider (331–372 mm) excedem a
  placa A1 (256 mm) e a MINI (180 mm). Por isso a Série B fatia **peças
  segmentadas**, e a impressão real exige segmentação — o que a plataforma já
  fornece nas pastas `parts/`.
- **Custo com taxa única.** O custo assume 36,29 €/kg para todos os casos e
  materiais — **o PETG usa a mesma taxa do PLA**; só um preço real distinto (por
  fornecedor ou no tempo) alteraria proporcionalmente os valores.
- **Leitura estrutural.** As estimativas do fatiador não medem resistência e a
  integridade de malha é geométrica; contudo, os parâmetros (paredes, enchimento,
  material) permitem uma leitura **qualitativa e relativa** do comportamento
  mecânico esperado. Valores absolutos de resistência/durabilidade exigem ensaio
  físico. Detalhe no Anexo D (D.4.3, D.8).
- **Rótulo de volume do Bambu.** O comentário do G-code do Bambu diz
  `total filament volume [cm^3]` com um valor que está de facto em **mm³**; o
  volume aqui foi calculado de forma consistente por massa/densidade.

---

## 7. Reprodutibilidade

Todos os *scripts* de extracção, geometria, fatiamento e agregação, os ficheiros
de configuração e as saídas brutas relevantes estão em [`raw/`](raw/). Os comandos
exactos estão em [`comandos_e_versoes.txt`](comandos_e_versoes.txt).
