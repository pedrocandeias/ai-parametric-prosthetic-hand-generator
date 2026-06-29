# Avaliação User-Centered Design do Dimensionamento por IA

**Data:** 2026-06-29 · **Versão do código:** v14.18.0
**Modelos:** Flexy Beast · Paraglider · Hand · UnLimbited Phoenix Hand

Este relatório avalia o sistema pela lente do **user-centered design (UCD)**. O valor
de desenho primário declarado pelo estudo de validação
([`ai_anthropometric_validation.md`](../ai_anthropometric_validation.md)) é a
**acessibilidade para o utilizador sem conhecimento clínico**: um leigo (paciente,
familiar) deve conseguir uma peça plausível, segura e imprimível descrevendo o paciente
em linguagem corrente. A pergunta central é, portanto:

> Quando a entrada é como um leigo *realmente* escreve — vaga, sem milímetros,
> multilingue — o sistema continua a produzir um resultado **seguro** e **utilizável**?

**Método.** Um harness em Node conduz o pipeline **real** de IA — reconstrói o prompt do
`app.js`, aplica o grounding por dataset (`findBestProfileMatch` + extração LLM) e chama
`claude-sonnet-4-6`, exatamente como a app — sem browser, para correr muitas entradas.
A manufaturabilidade é auditada com `trimesh` sobre as peças re-renderizadas localmente
em OpenSCAD. Dados em bruto: [`test1-2_inputs.json`](test1-2_inputs.json),
[`test1-2_ai-results.json`](test1-2_ai-results.json),
[`test2_handedness-reproducibility.json`](test2_handedness-reproducibility.json).

---

## 1. Teste 1 — Input realista de leigo (robustez da entrada)

Oito descrições como um leigo escreveria — vagas, comparativas, com gíria, sem números,
em quatro línguas — no Flexy Beast. Validação: conformidade de intervalo, ordenação
anatómica (médio mais longo, mindinho mais curto), plausibilidade e grounding.

| Input (resumo) | Língua | `palm_breadth` | grounded → grupo | range | ordem |
|---|---|---:|---|:--:|:--:|
| "filho de 7 anos, mão como uma bola de ténis" | PT | 64 | Dutch children, male, 7 | ✓ | ✓ |
| "senhora, magrinha e baixa" | PT | 74 | ANSUR I Female 50th | ✓ | ✓ |
| "mão mais pequena que a minha, luvas M" | PT | 80 | ANSUR I Male 50th | ✓ | ✓ |
| "gajo grande, mãos de pedreiro" | PT | 97 | ANSUR I Male 50th | ✓ | ✓ |
| "my daughter is 9, quite petite" | EN | 64 | Dutch children, female, 9 | ✓ | ✓ |
| "hombre mayor, manos grandes" | ES | 91 | Dutch elderly, male, 65–69 | ✓ | ✓ |
| "une femme adulte, taille moyenne, mince" | FR | 77 | ANSUR I Female 50th | ✓ | ✓ |
| "criança" (uma palavra) | PT | 55 | Dutch children, female, 2 | ✓ | ✓ |

**Resultado: PASSA (8/8).** Toda a entrada — incluindo **francês** (fora do dicionário
determinístico EN/PT/ES) e gíria — produziu parâmetros válidos, dentro de intervalo e
anatomicamente ordenados, com grounding na população correta. A **extração LLM** de
`{gender, age}` faz o trabalho cross-língua (correu em todos os casos). A "ponte de
acessibilidade" aguenta input pobre — o resultado central de UCD positivo.

*Nuance menor:* "criança" sem idade ancorou na criança mais nova (2 anos) — sem idade
explícita, um valor mediano de criança seria preferível.

---

## 2. Teste 2 — Segurança (o utilizador confia e não deteta erros)

### 2a. Falha-segura — entradas absurdas → **PASSA**

| Input | `palm_breadth` resultante | Esperado |
|---|---:|---|
| "mãos gigantes, palma com 200 mm" | **110** | clampado ao máximo (110) ✓ |
| "palma de 0 mm" | **55** | clampado ao mínimo (55) ✓ |

A IA respeita os limites min/max mesmo perante valores absurdos — não produz uma peça
fora de escala.

### 2b. Steering de modelo — **GAP de UX**

Mesma criança (palma ~62 mm) em dois modelos:

| Modelo | `palm_breadth` produzido | grounding |
|---|---:|---|
| Flexy Beast | **62** (escala para baixo) | Dutch children, age 7 |
| UnLimbited Phoenix | **82** (floor — 33 % grande demais) | Dutch children, age 7 |

O grounding **sabe** que é uma criança, mas o Phoenix não imprime abaixo de 82 mm e
devolve 82 — **sem qualquer aviso ao utilizador** de que o modelo é inadequado para a mão
descrita. A ajuda do modelo recomenda o Flexy Beast para mãos pequenas, mas essa
orientação não é trazida ao contexto. Um leigo recebe uma mão um terço grande demais e
não tem como saber.

### 2c. Lateralidade — ⚠️→✅ **FALHA de segurança (corrigida v14.19.0)**

A mão pretendida foi pedida explicitamente; verificou-se o parâmetro `mirrored`
(`true` = mão direita; `false`/ausente = esquerda, o default do modelo):

| Pedido | `mirrored` (4 repetições) | Corretos |
|---|---|:--:|
| **mão esquerda (PT)** | `[true, true, true, true]` | **0/4** ❌ |
| mão direita (PT) | `[true, true, true, true]` | 4/4 ✓ |
| **left hand (EN)** | `[true, true, (falha parse), true]` | **1/4** ❌ |

A IA emitia `mirrored = true` **sempre**, ignorando a lateralidade pedida: quem pedia a mão
**esquerda recebia sistematicamente uma mão direita**. Como o leigo confia no resultado, só
descobriria o erro depois de imprimir e montar — desperdício de material e, sobretudo, de
confiança. É a confirmação (mais grave) da lacuna de lateralidade já antecipada no estudo
de validação (§9 "Trabalho Futuro").

> **Corrigido (v14.19.0).** A lateralidade passa a ser **exclusivamente** uma escolha da UI.
> Os parâmetros de lateralidade são marcados com `role: "laterality"` no `models-config.json`;
> o `app.js` (i) exclui-os da lista que a IA pode sugerir, (ii) injeta no prompt o lado já
> escolhido pelo utilizador como facto fixo, e (iii) descarta defensivamente qualquer chave de
> lateralidade vinda da IA. Verificação: a IA passa a **omitir `mirrored` em 9/9** execuções,
> incluindo o conflito UI-esquerda / texto-direita. Implementado de forma **genérica
> (laterality, não "handedness")**, pelo que já serve qualquer membro par futuro (braço, pé,
> perna).

---

## 3. Teste D — Manufaturabilidade (a peça é imprimível?)

### Ao nível dos parâmetros — **a IA é consciente da manufaturabilidade**

Para a criança no Flexy Beast, a IA reduziu o hardware: `joint_dia` 7 → **5 mm** e
`joint_thick` 4 → **2 mm** — exatamente o que a *caption* recomenda para mãos de criança
(evita que a junta rasgue o plástico fino). Não foi instruída a fazê-lo nos números; leu
a intenção das captions.

### Ao nível da malha — auditoria `trimesh` (config criança, features mais pequenas)

| Peça | Watertight | Manifold | Corpos | Faces degeneradas |
|---|:--:|:--:|:--:|---:|
| Flexy — palma | ✓ | ✓ | 1 | 0 |
| Flexy — dedo médio | ✓ | ✓ | 3 | 0 |
| Paraglider — palma | ✓ | ✓ | 1 | **142** |
| Paraglider — dedo médio | **✗** | ✓ | 4 | 26 |
| Phoenix — palma | **✗** | **✗** | 5 | 6 |

- **Flexy Beast: limpo** — sólido fechado, manifold, sem faces degeneradas mesmo à escala
  criança. Pronto a fatiar.
- **Paraglider: avisos** — a palma tem 142 faces de área-zero e o dedo sai não-watertight,
  artefactos do CSG dos canais (`pipe.scad`/fingerator). Os fatiadores costumam reparar
  isto automaticamente, mas é um sinal a verificar num slicer real.
- **Phoenix: malha-fonte não-manifold** — a palma Phoenix é não-watertight/não-manifold.
  Isto é **herdado da malha original** convertida (poliedro embebido), **não** introduzido
  pelo nosso escalonamento (que é exato — ver o relatório do Phoenix). Imprime na prática,
  mas não é um sólido pristino.

*Limitação:* a estimativa de **espessura mínima de parede** por ray-casting não produziu
um valor fiável — o método requer malhas watertight, e três das cinco peças não o são.
Uma verificação rigorosa de espessura mínima exige um slicer (ou reparação prévia).

---

## 4. Recomendações UCD (priorizadas)

1. **[Segurança — crítico] ✅ Lateralidade determinística (feito, v14.19.0).** A mão
   (esquerda/direita) deixou de ser inferida pela IA: é a escolha da UI, injetada no prompt
   e nunca sobreposta (`role: "laterality"`). Resta o reforço de **UX**: tornar esse controlo
   prominente (não apenas mais um parâmetro entre dezenas), idealmente um seletor
   esquerda/direita dedicado e obrigatório.
2. **[UX] Aviso de adequação de modelo.** Quando a mão estimada cai fora da gama imprimível
   de um modelo (ex.: criança no Phoenix < 82 mm), avisar e **encaminhar** para um modelo
   adequado (Flexy Beast), em vez de devolver silenciosamente o tamanho do floor.
3. **[Confiança] Mostrar proveniência e incerteza.** Expor ao utilizador o grupo
   populacional em que ancorou (`grounded`, grupo, completude do dataset) para calibrar
   confiança e saber quando pedir ajuda a um técnico.
4. **[Manufaturabilidade] Reparar/avisar malha no export.** Para o Paraglider e o Phoenix,
   passar um passo de reparação (ou um aviso de "verificar no slicer") antes de entregar o
   STL ao leigo.

---

## 5. Conclusão

No **dimensionamento**, o sistema serve bem o utilizador-alvo sem conhecimento clínico:
absorve input vago, comparativo, com gíria e multilingue (PT/EN/ES/FR) e devolve sempre
parâmetros válidos, plausíveis e ancorados; falha de forma segura perante valores
absurdos; e até ajusta o hardware à manufaturabilidade da criança. **Mas** restam, antes de
uso real com leigos: **uma falha de segurança** (lateralidade sistematicamente errada para
a mão esquerda) e **dois gaps de UX** (sem aviso de adequação de modelo; sem proveniência
visível). A primeira é a prioridade — um utilizador que confia no resultado não a deteta.

Relacionados: [estudo de validação](../ai_anthropometric_validation.md) ·
relatórios por-modelo
([Flexy](../flexy-beast-ai-sim/flexy-beast_ai-sizing-dimensional-report_2026-06-28.md) ·
[Paraglider](../paraglider-ai-sim/paraglider-hand_ai-sizing-dimensional-report_2026-06-28.md) ·
[Phoenix](../phoenix-ai-sim/unlimbited-phoenix-hand_ai-sizing-dimensional-report_2026-06-28.md)).
