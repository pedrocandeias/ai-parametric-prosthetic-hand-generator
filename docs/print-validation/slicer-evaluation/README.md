# slicer-evaluation — Ensaios de preparação para impressão

Dados verificáveis, gerados por CLI de **Bambu Studio** e **PrusaSlicer**, sobre a
preparação para impressão dos modelos paramétricos da HandFab. Serve de base de
evidência ao **Anexo D** da dissertação (Design e Desenvolvimento de Produto).
Os ensaios organizam-se em duas séries: **Série A** (projectos arquivados) e
**Série B** (comparação digital controlada).

> ⚠️ **Estimativas de software, não medições físicas.** Os valores de tempo,
> filamento, massa, volume e custo são calculados pelos fatiadores. Não são
> medições de impressões reais nem indicadores de desempenho estrutural. A
> verificação de malha é geométrica, não mecânica.

## Conteúdo

| Ficheiro | Descrição |
|---|---|
| [`protocolo.md`](protocolo.md) | Metodologia, variáveis, controlos e limites de comparabilidade |
| [`comandos_e_versoes.txt`](comandos_e_versoes.txt) | Comandos exactos, versões e checksums SHA-256 |
| [`resultados_projectos_arquivados.csv`](resultados_projectos_arquivados.csv) | **Série A** — 4 projectos arquivados, fatiados como preparados |
| [`resultados_campanha_controlada.csv`](resultados_campanha_controlada.csv) | **Série B** — 12 casos (3 modelos × 4 perfis) sob condição virtual comum *(o nome do ficheiro conserva a designação técnica original)* |
| [`resultados_geometria.csv`](resultados_geometria.csv) | Geometria: montagem sólida vs palma vs placa disposta; volume, manifold, faces degeneradas |
| [`raw/`](raw/) | Saídas brutas relevantes (result.json, cabeçalhos de G-code, configs, logs) |

## Síntese

**Série A** (perfis embebidos, tal como preparados):

| Projecto | Fatiador | Tempo | Filam. (mm) | Massa (g) | Volume (cm³) | Custo | Placa (mm) |
|---|---|---|---|---|---|---|---|
| Flexy Beast 15, PLA | Bambu 01.10.02.76 | 2h21m50s | 18 645,9 | 56,5 | 44,9 | 2,05 € | 158,2×121,5 |
| Phoenix 15, PLA | Bambu 01.10.02.76 | 5h12m44s | 40 756,7 | 123,5 | 98,0 | 4,48 € | 222,6×214,7 |
| Phoenix 15, PETG | Bambu 01.10.02.76 | 5h51m52s | 39 094,1 | 117,5 | 94,0 | 4,27 € | 222,2×211,5 |
| Paraglider 15, PLA | PrusaSlicer 2.8.1 | 2h32m11s | 12 727,6 | 38,0 | 30,6 | 1,38 € | 98,2×96,9 |

*(Camada: Bambu 0,24 mm; PrusaSlicer 0,20 mm. Custo a 36,29 €/kg para todos os
casos e materiais; no Paraglider coincide com o valor do PrusaSlicer. Aviso no
Paraglider: baixa aderência à base — sugere suportes/aba.)*

**Série B** (condição comum: A1, PLA, 0,20 mm, 2 paredes, 15% grelha, **sem suportes**);
massa / custo / número de placas A1:

| Modelo | child_8 | teen_15 | adult_28 | elderly_70 |
|---|---|---|---|---|
| Flexy Beast | 83,0 g · 3,01 € · 1 placa | 130,9 g · 4,75 € · 1 | 169,2 g · 6,14 € · 2 | 144,3 g · 5,24 € · 2 |
| Paraglider Hand | 50,1 g · 1,82 € · 1 | 83,9 g · 3,05 € · 1 | 116,5 g · 4,23 € · 1 | 89,8 g · 3,26 € · 1 |
| UnLimbited Phoenix | 93,0 g · 3,37 € · 2 | 110,1 g · 4,00 € · 2 | 115,7 g · 4,20 € · 2 | 98,2 g · 3,56 € · 2 |

Todos os 12 casos fatiaram com sucesso. O **número de placas A1** escala com a
antropometria (Flexy passa de 1 para 2 placas; o Phoenix precisa sempre de 2).

**Geometria — o modelo montado não cabe na placa.** O corpo único montado (mão
estendida) excede a placa A1 (256 mm) no Flexy (teen/adult/elderly) e em **todos**
os Paraglider (331–372 mm) → a impressão exige segmentação em peças (que a
plataforma já fornece).

Ver [`protocolo.md`](protocolo.md) para os limites de comparabilidade completos.
