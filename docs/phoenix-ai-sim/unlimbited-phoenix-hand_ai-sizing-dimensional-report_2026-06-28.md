# UnLimbited Phoenix Hand — Relatório de Dimensões: Dimensionamento por IA → Exportação STL

**Data:** 2026-06-28 · **Versão do código:** v14.17.0
**Modelo:** UnLimbited Phoenix Hand (`models/active/unlimbed_phoenix_hand/UnLimbitedPhoenix.scad`)

**Método:** idêntico aos testes do Flexy Beast e do Paraglider — simulação ponta-a-ponta
de um utilizador real em `http://localhost:3000/edit` (login → abrir o modelo → escrever
dados antropométricos → sugestão **real** da IA via `POST /api/ai/suggest`,
`claude-sonnet-4-6` → aplicar → **Exportar STL**), browser conduzido com
Playwright/Chromium. Três perfis de paciente + um **baseline** por omissão.

**Especificidades deste modelo (vs os outros dois):**
- **Modelo inteiro, sem peças** → exporta **um único STL**. Por omissão `part = "Palm"`,
  logo o ficheiro exportado é o **palm Phoenix** (`Phoenix_Thermo_Palm_2()`).
- **Um só parâmetro antropométrico:** `palm_breadth_mm`, **com range `[82:131]`**.
  A escala deriva como `HandPerc = palm_breadth_mm / 82 × 100`, **limitada a 100–160 %**.
- Existe um escape manual: `HandPerc_override` (`0` = automático; a caption/ajuda dizem
  **"100–160 define-a diretamente"**), mas o seu range declarado é **`[0:160]`**.

**Referência estática:** o source paramétrico upstream do Team UnLimbited,
`tests/UnLimbited_Arm_V2.2.scad` (`part = 5`, *Palm*), que **embebe a mesma malha**
`Phoenix_Thermo_Palm_2` que o nosso modelo. Renderizado a 100 % dá
**91.96 × 82.17 × 30.55 mm** — coincidente com as funções `Phoenix_Thermo_Palm_2_dim*()`
embebidas no ficheiro.

Dados de apoio: [`run-metadata.json`](run-metadata.json), [`measurements.json`](measurements.json).

> 🔑 **Dois achados:** (1) a integração reproduz a malha Phoenix original **com exatidão**
> (≤ 0.06 mm); (2) o modelo tinha **dois caminhos de escala com floors inconsistentes** — a
> IA contornou o limite de tamanho mínimo via `HandPerc_override`, e fê-lo **só para a
> criança** (não para a mulher). **Corrigido em v14.18.0** (ambos os caminhos agora
> limitados a 100–160%). Ver §5–§6.

---

## 1. O prompt e os dados de paciente

Mesmo template dos outros testes. Inputs escritos (a única variável por perfil):

| Perfil | Texto livre introduzido |
|---|---|
| **criança** | *Criança de 7 anos, mão pequena. Largura da palma (nó a nó) cerca de 62 mm, dedo médio cerca de 56 mm, polegar cerca de 48 mm.* |
| **mulher** | *Mulher adulta, 34 anos, 165 cm, constituição magra. Sem medidas exatas — estima valores plausíveis a partir de normas populacionais.* |
| **homem** | *Homem adulto, 45 anos, 188 cm, mãos grandes. Largura dos nós dos dedos cerca de 96 mm, dedo médio cerca de 86 mm.* |

Grounding: os três pedidos voltaram `grounded: true` (matcher corrigido em v14.16.0,
ver `ai_anthropometric_validation.md` §2.4). Como o modelo só expõe `palm_breadth_mm`,
o bloco de grounding ancora apenas essa medida.

---

## 2. O que a IA devolveu (parâmetros aplicados)

| Perfil | `palm_breadth_mm` (range 82–131) | `HandPerc_override` (0 / 100–160) | → HandPerc efetivo | Resposta crua da IA |
|---|---:|---:|---:|---|
| baseline | 82 | 0 | 100 % | *(defaults)* |
| **criança** | 82 | **76** | **76 %** | `{"palm_breadth_mm": 82, "HandPerc_override": 76}` |
| mulher | 82 | 0 | 100 % | `{"palm_breadth_mm": 82, "HandPerc_override": 0, "LeftRight": "Left"}` |
| homem | 96 | 0 | 117 % | `{"palm_breadth_mm": 96}` |

**Leitura:** a IA percebeu que `palm_breadth_mm` não desce abaixo de 82 (o range mínimo)
e, **só para a criança**, usou `HandPerc_override = 76` para forçar uma impressão mais
pequena — atingindo 76 %, **abaixo** do limite de 100 % que o modelo impõe pela via do
`palm_breadth_mm`. Para a **mulher** (estimada ~78 mm, também < 82) **não** usou o override:
deixou-a no floor de 100 % (= 82 mm). O homem (96 mm) escalou normalmente para 117 %.

---

## 3. Dimensões exportadas vs referência (exatidão da integração)

O nosso modelo aplica `scale([HandPerc/100, …]) Phoenix_Thermo_Palm_2()` — a **mesma**
malha do upstream. Logo o STL exportado deve ser a malha de referência × HandPerc/100.

| Perfil | HandPerc | Comp. (mm) | **Larg. (mm)** | Alt. (mm) | referência × HandPerc | Δ largura |
|---|---:|---:|---:|---:|---:|---:|
| baseline | 100 % | 91.96 | **82.17** | 30.55 | 82.17 | **0.000 mm** |
| criança | 76 % | 69.89 | **62.45** | 23.22 | 62.45 | **0.000 mm** |
| mulher | 100 % | 91.96 | **82.17** | 30.55 | 82.17 | **0.000 mm** |
| homem | 117 % | 107.67 | **96.19** | 35.77 | 96.13 | 0.060 mm |
| *referência upstream (100 %)* | — | 91.96 | 82.17 | 30.55 | — | — |

A integração é **fiel ao milésimo**: o palm exportado coincide com a malha Phoenix
original escalada. Mais: o **baseline** e a **mulher** (ambos 100 %) são **byte-a-byte
idênticos** (mesmo MD5) e iguais à referência upstream — o nosso modelo preserva
exatamente a geometria do Team UnLimbited.

---

## 4. Validação do floor de tamanho

O modelo foi desenhado para **não imprimir abaixo de 100 %** (≈ 82 mm de largura de palma):
a caption do `palm_breadth_mm` di-lo (`clamped to 100–160%`), o range do parâmetro começa
em 82, e a ajuda do modelo recomenda *"para mãos muito pequenas, escolher um modelo mais
pequeno como o Flexy Beast"*. Confirmado pela via `palm_breadth_mm`:

- **mulher** (~78 mm estimado, < 82) → floored a **100 % / 82.17 mm** (igual ao baseline).

Mas há um **segundo caminho de escala que não respeita esse floor** — ver §5.

---

## 5. 🐛→✅ Achado: `HandPerc_override` contornava o floor (corrigido v14.18.0)

`HandPerc_override` é honrado como `HandPerc = override > 0 ? override : auto`. O seu
**range declarado é `[0:160]`**, mas a caption/ajuda dizem que só **`0`** (automático) ou
**`100–160`** (escala direta) fazem sentido — a faixa **1–99 é uma zona-morta** que a
documentação desencoraja.

A IA escolheu **`HandPerc_override = 76`** (dentro de `[0:160]`, mas na zona-morta), e o
modelo escalou o palm a **76 %**, produzindo uma largura de **62.45 mm** — **abaixo do
mínimo de 100 % / 82 mm** que o autor do modelo marcou como o limite imprimível da malha
Phoenix. Ou seja, existem **dois caminhos de dimensionamento com floors inconsistentes**:

| Caminho | Floor | Resultado para a criança |
|---|---|---|
| `palm_breadth_mm` (range 82–131, clamp 100–160 %) | **100 %** (≈ 82 mm) | bloqueado a 82 mm |
| `HandPerc_override` (range 0–160) | **nenhum** (aceita 1–99) | **76 % → 62 mm** |

**Inconsistência da IA:** perante a mesma necessidade (mão < 82 mm), a IA usou o override na
**criança** mas não na **mulher**. Mesmo modelo, dois comportamentos.

**Correção aplicada (v14.18.0).** Em `UnLimbitedPhoenix.scad`, o ramo do override passa a
ter o **mesmo clamp** que a via automática, por isso **nenhum** caminho desce abaixo de
100 %:

```openscad
HandPerc = HandPerc_override > 0
    ? max(100, min(160, HandPerc_override))                       // antes: HandPerc_override (sem floor)
    : max(100, min(160, palm_breadth_mm / REF_PALM_BREADTH * 100));
```

Verificação (render local):

| `HandPerc_override` | HandPerc antes | HandPerc depois | largura palm depois |
|---:|---:|---:|---:|
| 76 (o valor da criança) | 76 % | **100 %** | **82.17 mm** *(era 62.45)* |
| 0 (auto) | 100 % | 100 % | 82.17 mm *(sem alteração)* |
| 130 (override válido) | 130 % | 130 % | 106.81 mm *(sem alteração)* |

A zona-morta 1–99 fica fixada a 100 %; os overrides válidos (100–160) continuam a passar.
Assim, mesmo que a IA volte a sugerir `HandPerc_override = 76` para a criança, a peça sai a
100 % (o mínimo suportado) em vez de 62 mm.

> Nota: nunca foi um bug de geometria (a malha escala perfeitamente) — era uma **lacuna de
> validação/UX** que deixava a IA (ou um utilizador) produzir uma peça fora das tolerâncias
> previstas pelo autor; agora fechada.

---

## 6. Conclusões

1. **Pipeline validado** para o 3.º e último modelo — agora um export de **modelo inteiro
   ficheiro único** (sem modal de peças), conduzido pelo mesmo driver de browser.
2. **Integração exata:** o palm exportado reproduz a malha Phoenix upstream escalada, com
   Δ ≤ 0.06 mm; baseline e mulher (100 %) são idênticos à referência ao byte.
3. **Grounding correto** (matcher v14.16.0) nos três perfis.
4. **Floor de tamanho confirmado pela via `palm_breadth_mm`** (mulher e qualquer valor < 82
   mm ficam a 100 %).
5. **🐛→✅ Lacuna de validação (corrigida v14.18.0):** `HandPerc_override` (range `[0:160]`)
   permitia valores 1–99 que **contornavam** esse floor; a IA usou `76` na criança → palm de
   62 mm, abaixo do mínimo suportado, e de forma **inconsistente** com a mulher. Corrigido:
   ambos os caminhos de escala ficam agora limitados a 100–160% (§5).
6. **Adequação clínica:** este modelo **não serve mãos pequenas** (o próprio autor remete
   para o Flexy Beast). Para os perfis criança/mulher deste estudo, o Flexy Beast ou o
   Paraglider são as escolhas corretas; o Phoenix brilha de 82 mm para cima.

### Ressalvas
- Referência = `tests/UnLimbited_Arm_V2.2.scad` (`part = 5`), que embebe a **mesma** malha
  do nosso modelo — por isso a comparação valida a *integração/escala*, não duas geometrias
  independentes.
- Export = `part = "Palm"` (omissão); o modelo também gera Box/Pins/Fingers/Gauntlet via o
  parâmetro `part`, não cobertos aqui.
- STL exportados no scratchpad da sessão (`…/scratchpad/out_ph/`); só os resumos JSON ficam
  versionados.
