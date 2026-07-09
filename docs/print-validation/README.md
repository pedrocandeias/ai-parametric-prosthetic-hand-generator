# Validação de Impressão — Modelos 3MF Dimensionados por IA (variações de idade)

Este diretório é a **etapa de validação de impressão** que dá seguimento à
[`ai_anthropometric_validation.md`](../ai_anthropometric_validation.md). Onde esse
documento validou os **números** produzidos pelo pipeline de dimensionamento por IA,
aqui fechamos o ciclo até **ficheiros 3MF prontos a imprimir**, gerados pelo caminho
de produção da plataforma, para os **três modelos ativos** em **quatro grupos etários**.

O objetivo é ter, em mãos, peças físicas que atravessem toda a gama de tamanhos
imprimíveis, para inspeção de encaixe, tolerâncias das juntas e comportamento do piso
de escala do Phoenix.

## Método

Cada configuração passou pelo **pipeline vivo real** da plataforma, não por valores
copiados à mão:

1. **Prompt** — reconstruído exatamente como o frontend (`app.js · getAISuggestions`),
   injetando o schema de parâmetros vivo de cada modelo a partir de
   `models/models-config.json` (a lateralidade e a cor são excluídas da lista da IA; a
   lateralidade é fixada em **esquerda** como escolha de UI).
2. **Dimensionamento por IA** — `POST /api/ai/suggest` autenticado
   (`anthropic · claude-sonnet-4-6`) com `patient_text` + `model_id`, pelo que o
   **grounding por dataset** (§2.4 do documento principal) foi ativado. **As 12 execuções
   devolveram `grounded: true`.**
3. **Render** — os parâmetros sugeridos são aplicados como *overrides* OpenSCAD (`-D`),
   com o *layout* de impressão de cada modelo, e exportados para **3MF** (unidades em mm,
   cores por peça preservadas como materiais) via OpenSCAD 2026 — o mesmo motor que a UI
   corre em WASM. Cada pasta guarda também um `.png` de pré-visualização, o `params.json`
   (sugestões da IA + `grounded`) e o `prompt.txt` (prompt exato + texto do paciente).

> **Nota de reprodutibilidade.** A amostragem do LLM é estocástica (§3.4 do documento
> principal): estes ficheiros são **uma extração representativa** por perfil. Os
> invariantes (ordenação dos dedos, intervalos, proporções) mantêm-se entre execuções;
> os milímetros exatos variam ±2–3 mm.

## Perfis (arquétipo homem brasileiro, variado por idade)

Mesmo arquétipo do "Homem 28 🇧🇷" do documento principal, declinado em quatro idades:

| Pasta | Etiqueta | Texto do paciente |
|---|---|---|
| `child_8` | Rapaz 8 | `boy, 8 years old, 26kg, 128cm height, Brazil, small hands` |
| `teen_15` | Adolescente 15 | `teenage boy, 15 years old, 60kg, 170cm height, Brazil, slim build, arm length 62cm` |
| `adult_28` | Homem 28 | `man, 28 years old, 82kg, 180cm height, Brazil, arm length 70cm` |
| `elderly_70` | Homem 70 | `man, 70 years old, 78kg, 172cm height, Brazil, arm length 68cm` |

## Parâmetros aplicados (execução representativa, mm)

Largura da palma + comprimentos dos dedos que a IA devolveu por perfil. Todos
respeitam a ordenação anatómica (médio mais longo, mindinho mais curto, polegar <
médio) e caem nos intervalos por idade.

### Flexy Beast

| Perfil | palm_breadth | índic | médio | anelar | mindinho | polegar |
|---|--:|--:|--:|--:|--:|--:|
| child_8 | 64 | 57 | 60 | 58 | 46 | 50 |
| teen_15 | 78 | 70 | 74 | 72 | 57 | 62 |
| adult_28 | 90 | 76 | 84 | 80 | 65 | 71 |
| elderly_70 | 84 | 65 | 69 | 66 | 52 | 62 |

### Paraglider · Hand

| Perfil | palm_breadth | índic | médio | anelar | mindinho | polegar |
|---|--:|--:|--:|--:|--:|--:|
| child_8 | 63 | 55 | 60 | 55 | 43 | 48 |
| teen_15 | 78 | 69 | 74 | 68 | 56 | 67 |
| adult_28 | 90 | 76 | 84 | 76 | 65 | 71 |
| elderly_70 | 84 | 66 | 69 | 66 | 52 | 62 |

### UnLimbited Phoenix (só largura da palma)

| Perfil | palm_breadth pedido | HandPerc efetivo | nota |
|---|--:|--:|---|
| child_8 | **82** | 100 % | **limitado ao piso** — a IA estimou ~62 mm mas o Phoenix não imprime abaixo de 82 mm; devolveu 82 sem `HandPerc_override` (correção v14.18.0 a funcionar) |
| teen_15 | 88 | ~107 % | |
| adult_28 | 90 | ~110 % | |
| elderly_70 | 84 | ~102 % | |

**Verificação de escala do Phoenix (bbox da palma exportada):** 82 mm → 82.2 × 92.0 ×
30.6 mm; 90 mm → 90.2 × 100.9 × 33.5 mm; rácio 1.098 = exatamente 90/82. A largura pedida
chega à malha ao milímetro e a escala é uniforme.

## Notas de impressão por modelo

- **Flexy Beast** — `print_layout = true`: **um único ficheiro 3MF** com todas as 12
  peças dispostas planas na base de impressão (palma, gauntlet, e as 12 secções de dedo
  coloridas). Escala para o mais pequeno — a escolha certa para o perfil `child_8`.
- **Paraglider · Hand** — `show_assembled = false`: **um único 3MF** com palma, 5 dedos
  e os pinos de pivô em disposição plana.
- **UnLimbited Phoenix** — impresso **uma peça de cada vez**: cada pasta contém **8
  ficheiros 3MF** (`palm`, `fingers`, `phalanx`, `pins`, `box`, `tpins`, `gauntlet`,
  `jig`). É de malha fixa, **só 82 mm e acima** — inadequado para mãos pequenas; para o
  `child_8` fica no piso de 100 %.

### Peças separadas (`parts/`)

Além da placa combinada, o Flexy e o Paraglider trazem cada peça como **ficheiro 3MF
individual** dentro de uma subpasta `parts/` — igual à seleção por peça do modal de
exportação da plataforma. Cada peça é isolada pelos seus *toggles*, **centrada na base
e assente em Z=0** (o mesmo *drop-to-bed* que o frontend faz), e exportada com a **cor
por peça** embebida como material 3MF. Assim pode imprimir-se peça a peça, por cor/material
ou consoante o tamanho da base:

- **Flexy Beast** — 12 peças: `palm`, `gauntlet`, e `<dedo>_base`/`<dedo>_tip` para
  índice, médio, anelar, mindinho e polegar.
- **Paraglider · Hand** — 7 peças: `palm`, `index`, `middle`, `ring`, `pinky`, `thumb`,
  `pins`.
- **UnLimbited Phoenix** — já é per-peça por natureza (os 8 ficheiros ficam diretamente
  na pasta da idade, sem subpasta `parts/`).

## Manifesto de pastas

```
docs/print-validation/
├── README.md                      (este ficheiro)
├── flexy_beast/<idade>/
│   ├── flexy_beast_<idade>.3mf + .png    (placa combinada)
│   ├── params.json + prompt.txt
│   └── parts/<peça>.3mf                  (12 peças individuais, coloridas, assentes)
├── paraglider_hand/<idade>/
│   ├── paraglider_hand_<idade>.3mf + .png
│   ├── params.json + prompt.txt
│   └── parts/<peça>.3mf                  (7 peças individuais)
└── unlimbed_phoenix_hand/<idade>/
    ├── unlimbed_phoenix_hand_<idade>_<parte>.3mf (×8) + .png
    └── params.json + prompt.txt
```

**116 ficheiros 3MF** no total: 8 placas combinadas (4 Flexy + 4 Paraglider) + 76 peças
individuais (48 Flexy + 28 Paraglider) + 32 Phoenix. PNG de pré-visualização a par de
cada placa combinada e de cada peça Phoenix. Idades: `child_8`, `teen_15`, `adult_28`,
`elderly_70`.

_Data de execução: 2026-07-08 · provider `anthropic · claude-sonnet-4-6` · grounding
ativo · OpenSCAD 2026.04.26._
