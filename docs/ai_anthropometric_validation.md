# Dimensionamento Antropométrico Assistido por IA de uma Mão Protésica Paramétrica — Um Estudo de Validação

## Resumo

Este documento relata uma validação estruturada do **pipeline de sugestão de parâmetros por
IA** da plataforma, no qual um modelo de linguagem de grande dimensão (LLM) infere um conjunto
completo de dimensões antropométricas para uma mão protésica paramétrica imprimível em 3D (o
modelo *Flexy Beast*) a partir de descrições de pacientes em texto livre. A hipótese central é
que um utilizador não especialista — que desconhece as medições clínicas da mão — pode ainda
assim obter um desenho anatomicamente plausível e pronto a imprimir descrevendo o paciente em
linguagem corrente. Definimos um protocolo de validação (conformidade com os intervalos,
proporcionalidade dos dedos, plausibilidade no adulto, escalonamento adequado à idade e
lateralidade contralateral) e aplicamo-lo em dois experimentos que abrangem todo o espectro
realista de entradas: medições diretas ricas, dados parciais e apenas dados demográficos. Em
ambos os experimentos o modelo produziu, em todos os casos, resultados válidos, dentro dos
intervalos e anatomicamente ordenados. Documentamos também o comportamento não determinístico
do sistema, um falso positivo heurístico no nosso próprio teste e uma lacuna genuína de
robustez (lateralidade inferida em vez de instruída). Os resultados são uma única amostra
representativa; o protocolo — e não os milímetros exatos — é o contributo.

---

## 1. Introdução e Motivação

A adaptação protésica convencional exige que um clínico capture um conjunto de medições da mão
(largura da palma, comprimentos por dedo, etc.) usando paquímetros e pontos de referência
normalizados. O utilizador-alvo desta plataforma é, pelo contrário, um **leigo** — um paciente
ou familiar — que não tem nem o vocabulário nem os instrumentos para essa tarefa. O passo de IA
existe especificamente para colmatar esta lacuna: transforma a informação que o utilizador
*consegue* fornecer no conjunto de parâmetros estruturado e com precisão milimétrica que o
modelo CAD paramétrico requer.

Isto reformula o critério de sucesso. Não se pede ao sistema que reproduza uma medição clínica
de referência; pede-se-lhe que produza um **ponto de partida razoável, seguro e editável** a
partir de entradas escassas, que o utilizador (ou um técnico revisor) afina depois através dos
controlos de parâmetros antes da exportação. A acessibilidade para o utilizador com pouco
conhecimento é, portanto, o valor primário de desenho, e é ela que determina o que validamos:
comportamento gracioso em todo o espectro de riqueza das entradas, autoconsistência anatómica e
correção relevante para a segurança (nomeadamente o lado da mão).

---

## 2. Arquitetura do Sistema

### 2.1 Visão geral do pipeline

```
free-text description
   → frontend prompt construction (app.js · getAISuggestions)
       · injects the live Flexy Beast parameter schema (name, caption, type, min/max, current)
       · also sends patient_text + model_id for server-side grounding
   → POST /api/ai/suggest    (server/routes/aiRoutes.js, JWT-authenticated, rate-limited)
       · dataset grounding (§2.4): findBestProfileMatch → buildGroundingBlock
         appends the closest population group's measured means to the prompt
   → aiService.callAnthropic (claude-sonnet-4-6)
   → JSON object { param: value, ... }
   → applySuggestions()      (drops unknown keys; updates only valid params)
   → parametric re-render (OpenSCAD WASM)  →  user fine-tuning  →  STL export
```

### 2.2 Construção do prompt

O prompt é montado por pedido e incorpora as definições de parâmetros do modelo **atual**, de
forma a que o LLM esteja sempre fundamentado no schema vivo (nomes, legendas, intervalos
permitidos, valores atuais) em vez de numa lista fixa. Instrui o modelo a (i) tratar os
parâmetros antropométricos como medições anatómicas em milímetros, (ii) estimar a partir de
normas populacionais quando apenas são dados dados qualitativos, (iii) preservar proporções
inter-dedos realistas, (iv) emitir apenas nomes de parâmetros conhecidos dentro de cada
intervalo e (v) deixar os parâmetros não anatómicos (hardware/visibilidade/cor) nos seus
valores por omissão, salvo se implicados. O template completo é reproduzido no Apêndice A.

### 2.3 Schema antropométrico canónico

Os nomes dos parâmetros estão deliberadamente alinhados com o pipeline de importação
antropométrica da plataforma (ver `CLAUDE.md`), de modo a que a saída da IA, os perfis
populacionais importados de CSV e a introdução manual partilhem todos um único vocabulário de
medição. Os intervalos de referência do adulto usados como limites de plausibilidade são
reproduzidos no Apêndice B.

### 2.4 Grounding por dataset (a partir da v11.0.0)

Originalmente o LLM estimava os casos qualitativos a partir das **suas próprias** normas
populacionais derivadas do treino; os datasets populacionais importados pela plataforma
(Apêndice C) eram uma biblioteca de referência passiva que não entrava no prompt. As sugestões
são agora opcionalmente **grounded** sobre esse dataset:

1. O frontend envia `patient_text` e `model_id` juntamente com o prompt.
2. `server/services/profileMapping.js · findBestProfileMatch` pontua cada perfil populacional
   armazenado em função do texto livre por **género**, **categoria etária + proximidade
   numérica de idade** e **país**, com um critério de desempate a favor de datasets
   representativos de percentil/média e de levantamentos de mãos, e seleciona a melhor
   correspondência (acima de uma pontuação mínima; caso contrário, nenhuma).
3. `mapProfileToModelParameters` projeta as `measurements` desse perfil nos parâmetros do
   modelo vivo — limitadas aos limites de cada parâmetro — e `buildGroundingBlock` anexa as
   médias medidas ao prompt como uma âncora explícita (ver Apêndice A).
4. O prompt instrui que **as medições fornecidas do paciente têm precedência** sobre estas
   médias populacionais, pelo que o grounding enviesa os *priors*, não os dados do utilizador.

O grounding é best-effort e retrocompatível: se nenhum perfil corresponder (ou o dataset estiver
vazio) o pedido prossegue sem grounding, e a resposta indica `grounded: true|false`. O mesmo
módulo `profileMapping` alimenta o seletor "Population baseline" do configurador, pelo que o
caminho de seed-from-dataset e o caminho de grounding por IA partilham uma única tradução.

> **Robustez do matcher (v14.16.0).** O parser de género/idade era originalmente apenas em
> inglês e usava tokens de substring, pelo que o token masculino `'m,'` correspondia às unidades
> `"mm,"`/`"cm,"` — **qualquer** texto de paciente que contivesse uma medição era lido como
> *masculino*, e os termos em português/espanhol eram ignorados. Na prática isto ancorava quase
> todas as descrições (incluindo crianças e mulheres) em *ANSUR I Male 50th Percentile*. Foi
> detetado pelas simulações end-to-end abaixo e corrigido: os tokens correspondem agora em
> fronteiras de palavra Unicode e são multilingues (EN/PT/ES), a análise de idade compreende
> `anos`/`años`, e os valores numéricos de `age_group` (`"7"`, `"18-30"`, `"80+"`) são
> classificados em criança/adulto/idoso com proximidade numérica. Os testes unitários herméticos
> estão em `test/profileMapping.test.js` (`npm run test:unit`).
>
> **Extração opcional por LLM (v14.16.0).** Para descrições em texto livre ou multilingues onde
> o parser determinístico deixa uma lacuna, `aiService.extractPatientAttributes` (uma chamada
> rápida `claude-haiku-4-5`) extrai `{gender, age}` para ancorar a correspondência. Corre
> **apenas** quando a análise determinística está incompleta e degrada-se graciosamente (recorre
> à análise de texto) em qualquer erro ou chave em falta — pelo que as entradas estruturadas não
> incorrem em nenhuma chamada adicional.

Isto desloca a questão de validação relevante para as entradas qualitativas: onde a §4 mediu os
*priors* não auxiliados do modelo, as execuções com grounding testam adicionalmente se o sistema
**se ancora no grupo correspondente** sem sobrepor as medições declaradas. Os invariantes da
§3.3 (schema, ordenação, intervalo, escalonamento) continuam a aplicar-se inalterados.

---

## 3. Metodologia

### 3.1 Modelo e configuração

| Item | Valor |
|---|---|
| Modelo CAD alvo | `flexy_beast` (SCAD paramétrico totalmente autocontido) |
| Fornecedor / modelo de LLM | Anthropic · `claude-sonnet-4-6` |
| Endpoint | `POST /api/ai/suggest` (autenticado como admin) |
| Contrato de saída | objeto JSON único, parâmetro→valor |
| Data da execução | 2026-06-05 |

### 3.2 Desenho experimental

Foram definidos dois experimentos para cobrir eixos complementares:

- **Experimento 1 — inferência a partir de proxies populacionais (§4).** Cinco perfis descritos
  puramente por proxies corporais *indiretos* (idade, sexo, peso, altura, região, comprimento do
  braço) **sem** quaisquer medições da mão. Isto isola a capacidade do modelo de inferir a
  antropometria da mão a partir de dados demográficos — o caso dominante do "utilizador comum" no
  mundo real.
- **Experimento 2 — espectro de entradas e lateralidade contralateral (§5).** Três perfis de
  amputação unilateral abrangendo entradas ricas → escassas, testando o uso literal das medições
  fornecidas, a estimativa proporcional dos campos em falta e o espelhamento correto para o lado
  amputado.

### 3.3 Critérios de validação

Cada sugestão é avaliada segundo cinco critérios:

1. **Conformidade com o schema** — a saída é parseável como JSON; cada chave é um parâmetro real
   do modelo; cada valor numérico situa-se dentro do seu `min`/`max` declarado.
2. **Proporcionalidade dos dedos** — médio ≥ indicador, médio ≥ anelar, o mindinho é o mais
   curto, polegar < médio.
3. **Plausibilidade no adulto** — para perfis adultos, cada medição cai dentro do intervalo
   canónico do adulto (Apêndice B).
4. **Escalonamento adequado à idade** — os menores escalam abaixo das normas do adulto e o
   hardware das articulações flexíveis é reduzido para mãos de criança.
5. **Correção da lateralidade** (Experimento 2) — `mirrored` é definido de modo a que a prótese
   corresponda ao lado *amputado*, isto é, o espelho da mão medida/intacta.

### 3.4 Sobre o não determinismo

A amostragem do LLM é **estocástica**: entradas idênticas não produzem saídas idênticas. Por
conseguinte, as tabelas numéricas abaixo são uma **única extração representativa**, e a §4.4
quantifica a variação entre execuções que observámos. Os critérios de validação foram concebidos
para serem *invariantes distribucionais* — propriedades que se espera que se verifiquem em cada
extração — em vez de afirmações sobre valores específicos. Esta é a postura epistémica adequada
para validar um componente estocástico: testamos a forma e a segurança da saída, não as suas
coordenadas exatas.

---

## 4. Experimento 1 — Inferência a partir de proxies populacionais

### 4.1 Perfis (apenas proxies indiretos)

| # | Etiqueta | Entrada em texto livre |
|---|---|---|
| 1 | Homem 28 🇧🇷 | `man, 28 years old, 82kg, 180cm height, Brazil, arm length 70cm` |
| 2 | Menina 10 🇯🇵 | `girl, 10 years old, 32kg, 138cm height, Japan, small frame` |
| 3 | Mulher 65 🇳🇬 | `woman, 65 years old, 68kg, 160cm height, Nigeria, arm length 62cm` |
| 4 | Homem 50 🇩🇪 | `man, 50 years old, 95kg, 175cm height, Germany, broad hands, arm length 66cm` |
| 5 | Adolescente 15 🇮🇳 | `teenage boy, 15 years old, 60kg, 168cm height, India, slim build, arm length 67cm` |

### 4.2 Resultados (execução representativa, mm)

| Parâmetro | Homem 28 🇧🇷 | Menina 10 🇯🇵 | Mulher 65 🇳🇬 | Homem 50 🇩🇪 | Adolescente 15 🇮🇳 |
|---|---|---|---|---|---|
| `palm_breadth_mm` | 90 | 62 | 74 | 95 | 72 |
| `index_finger_length_mm` | 76 | 52 | 64 | 78 | 64 |
| `middle_finger_length_mm` | 80 | 55 | 68 | 82 | 68 |
| `ring_finger_length_mm` | 76 | 52 | 65 | 79 | 64 |
| `pinky_finger_length_mm` | 62 | 42 | 50 | 63 | 51 |
| `thumb_length_mm` | 70 | 48 | 58 | 72 | 58 |
| `joint_dia` (hardware) | 7 | **5** | *default* | 7 | 7 |
| `joint_thick` (hardware) | 4 | **2** | *default* | 4 | 4 |

*Negrito = a IA reduziu proativamente o hardware das articulações flexíveis para uma mão de
criança. "default" = parâmetro omitido, deixando o valor atual do modelo (segundo a regra
"deixar o hardware salvo se implicado").*

### 4.3 Validação

**Resumo: 14 verificações passadas, 1 aviso, 0 falhas.**

- **Conformidade com o schema:** os 5 foram parseados; cada chave válida; todos os valores
  dentro do intervalo. ✓ *(Esta é também a verificação de regressão para a correção do prompt —
  o prompt anterior estava codificado para o modelo "Fingerator" removido e direcionava o LLM
  para parâmetros inexistentes que eram depois silenciosamente descartados na aplicação.)*
- **Proporcionalidade:** os 5 satisfazem médio-mais-longo / mindinho-mais-curto / polegar <
  médio. ✓
- **Plausibilidade no adulto:** os três adultos caem todos dentro dos intervalos canónicos do
  adulto. ✓
- **Escalonamento por idade:** a Menina 10 escalou para `palm_breadth` 62 mm e reduziu o
  hardware para 5 mm / 2 mm sem instrução. ✓
- **Aviso (não é erro do modelo):** o adolescente de 15 anos recebeu `palm_breadth` 72 mm; a
  heurística genérica do nosso teste "`menor ⇒ < 70 mm`" assinalou-o, mas 72 mm está correto
  para um adolescente alto e magro de meia-adolescência cuja mão tem essencialmente tamanho
  adulto. A falha está na asserção demasiado estrita, não na sugestão.

### 4.4 Variação entre execuções (ilustrando a §3.4)

Comparando esta execução com uma execução independente anterior sobre o mesmo perfil Homem 28
🇧🇷:

| Campo | Execução anterior | Esta execução | Δ |
|---|---|---|---|
| `palm_breadth_mm` | 88 | 90 | +2 |
| `index_finger_length_mm` | 74 | 76 | +2 |
| `middle_finger_length_mm` | 78 | 80 | +2 |
| `thumb_length_mm` | 68 | 70 | +2 |

A variação é pequena (±2–3 mm, ~2–3%) e **preserva todos os invariantes** (ordenação,
intervalos, proporções). O perfil Mulher 65 🇳🇬 ilustra adicionalmente o não determinismo
*estrutural*: numa execução o modelo emitiu explicitamente `joint_dia`/`joint_thick`, noutra
omitiu-os (deixando os valores por omissão) — ambos válidos sob o contrato do prompt. Isto
limita o jitter esperado para os consumidores a jusante e reforça que a saída da IA é um **ponto
de partida**, refinado pelo utilizador, não uma prescrição fixa.

---

## 5. Experimento 2 — Espectro de entradas e lateralidade contralateral

### 5.1 Fundamentação

Na prática, o utilizador fornece *aquilo que tem*. Para uma **amputação unilateral**, os dados
mais ricos disponíveis são a medição direta da **mão contralateral intacta**; a prótese deve
então ser produzida para o lado **oposto** (amputado), isto é, o espelho geométrico da mão
medida. O parâmetro `mirrored` (`false` = esquerda, `true` = direita) governa isto. Este
experimento abrange três níveis de riqueza e verifica tanto o uso literal dos valores fornecidos
como a atribuição correta do lado.

### 5.2 Perfis

| Cenário | Entrada | Lado amputado → prótese necessária |
|---|---|---|
| Contralateral direto | medições completas da mão ESQUERDA intacta | direita → DIREITA |
| Parcial + demográficos | homem 40; apenas `pb=90` da mão DIREITA intacta | esquerda → ESQUERDA |
| Apenas demográficos | mulher 30, asiática oriental, 158 cm | direita → DIREITA |

### 5.3 Resultados (execução representativa, mm)

| Cenário | `palm_breadth` | ind / méd / anel / mind / polegar | `mirrored` da IA | Lado correto |
|---|---|---|---|---|
| Contralateral direto | 84 *(literal)* | 72 / 78 / 75 / 58 / 64 *(literal)* | `true` | ✓ |
| Parcial + demográficos | 90 *(literal)* | 76 / 80 / 76 / 62 / 72 *(estimado)* | `false` | ✓ |
| Apenas demográficos | 72 *(estimado)* | 61 / 65 / 62 / 48 / 57 *(estimado)* | `true` | ✓ |

### 5.4 Conclusões

- **As medições fornecidas são usadas literalmente** — o modelo não reestima sobre os dados que
  o utilizador forneceu (todos os seis valores no cenário 1; o único `pb=90` no cenário 2 passou
  diretamente).
- **A entrada parcial combina-se corretamente** — os valores fornecidos são retidos e os campos
  em falta são estimados *proporcionalmente em torno deles*.
- **Apenas-demográficos degrada-se graciosamente** — o caminho central de baixo conhecimento
  produz um conjunto completo e plausível.
- **A lateralidade esteve correta nos três** — o modelo produziu o espelho do lado intacto.

> ⚠ **Ameaça à validade — a lateralidade é *inferida*, não *instruída*.** O prompt não menciona
> lateralidade nem espelhamento; o modelo deduziu-a a partir do fraseado em linguagem natural
> ("missing the RIGHT hand"). Com `claude-sonnet-4-6` e entrada em frase completa isto foi
> fiável ao longo das execuções, mas para abreviaturas clínicas concisas (por ex. *"L hand
> pb84, R amp"*) não está garantido. Como uma mão do lado errado é inutilizável e um não
> especialista pode não reparar, uma regra explícita de contralateral/espelho no prompt é o
> reforço recomendado (ver §9).

---

## 6. Experimento 3 — Validação Geométrica Inter-Modelos (IA → exportação STL)

Onde os Experimentos 1–2 mediram as estimativas **numéricas** do LLM, o Experimento 3 fecha o
ciclo até à **geometria impressa**, em **todos os três** modelos ativos. Cada execução conduz a
interface `/edit` real de ponta a ponta com Playwright/Chromium — login → escrever uma descrição
de paciente → `POST /api/ai/suggest` real (`claude-sonnet-4-6`, grounding ativo) → aplicar →
**Exportar STL** pelo caminho de produção OpenSCAD-WASM — e depois mede cada malha exportada com
`trimesh`. *(Execuções: 2026-06-28, matcher de grounding corrigido na v14.16.0.)* Quatro
configurações por modelo: um **baseline** por omissão mais três perfis de paciente (criança /
mulher adulta / homem adulto).

Detalhe por modelo, prompts e tabelas por peça:
[Flexy Beast](flexy-beast-ai-sim/flexy-beast_ai-sizing-dimensional-report_2026-06-28.md) ·
[Paraglider](paraglider-ai-sim/paraglider-hand_ai-sizing-dimensional-report_2026-06-28.md) ·
[UnLimbited Phoenix](phoenix-ai-sim/unlimbited-phoenix-hand_ai-sizing-dimensional-report_2026-06-28.md).

### 6.1 Modelos em teste

| Modelo | Entradas antropométricas | Exportação | Mecanismo de escala | Mão mínima imprimível |
|---|---|---|---|---|
| Flexy Beast | largura da palma + 5 comprimentos de dedos | 12 peças de impressão | `xScaleFactor=(breadth+5)/55`, escalas de comprimento por dedo | pequena (capaz para criança) |
| Paraglider · Hand | largura/comprimento/espessura da palma + 5 dedos | 7 peças | `overall_scale=breadth/66.4` (palma) + por dedo | tendencialmente adulto |
| UnLimbited Phoenix | apenas largura da palma | modelo inteiro, 1 ficheiro | `HandPerc=breadth/82×100` uniforme, **limitado a 100–160 %** | **≈82 mm (100 %)** |

### 6.2 Dimensionamento por IA entre modelos (parâmetros aplicados)

Todas as doze execuções devolveram `grounded: true` e valores dentro do intervalo e
anatomicamente ordenados.

| Perfil | Flexy `palm_breadth` / `middle` | Paraglider `palm_breadth` / `middle` | Phoenix `palm_breadth` |
|---|---|---|---|
| baseline | 83 / 72 | 83 / 72 | 82 |
| criança | 62 / 56 | 62 / 56 | **82** *(no piso; +`HandPerc_override=76`)* |
| mulher | 77 / 77 | 77 / 76 | **82** *(no piso)* |
| homem | 96 / 86 | 96 / 86 | 96 |

Os dois modelos multi-parâmetro dimensionam-se de forma **quase idêntica** (independentemente de
qual modelo está carregado — a estimativa segue o paciente, não a malha). O Phoenix expõe o piso
da sua única entrada: perfis abaixo de 82 mm não podem ser expressos, pelo que a IA devolveu 82 —
exceto para a criança, onde recorreu à saída de emergência `HandPerc_override` (ver §6.5, defeito
3).

### 6.3 Palma exportada — rácio de escala vs baseline (maior dimensão)

| Perfil | Flexy Beast | Paraglider | Phoenix |
|---|---:|---:|---:|
| baseline | 1.000 (124.2 mm) | 1.000 (113.7 mm) | 1.000 (92.0 mm) |
| criança | 0.761 | 0.747 | 0.760 † |
| mulher | 0.932 | 0.928 | **1.000** ‡ |
| homem | 1.148 | 1.157 | 1.171 |

† A criança do Phoenix só encolheu porque a IA usou `HandPerc_override = 76` (76 %), o que
**contornou** o piso de 100 % do modelo — um defeito, agora corrigido (§6.5); após a correção é
1.000.
‡ A mulher do Phoenix (estimada em ~77 mm < 82) é **limitada ao piso de 100 %** — o modelo não a
consegue imprimir mais pequena, por desenho. O Flexy e o Paraglider escalam-na para baixo
suavemente (~0.93).

A geometria segue as entradas **linearmente** nos dois modelos escaláveis (comprimento/largura da
palma do Flexy ≈ 1.49–1.52 constante; Paraglider ≈ 1.37 constante), confirmando que o mapeamento
de parâmetros chega à malha.

### 6.4 Fidelidade à geometria de origem

| Modelo | Referência estática | Concordância |
|---|---|---|
| Flexy Beast | STLs de demonstração daprice (160 %) | palma dentro de ~1 % quando dimensionada para a mesma mão |
| Paraglider | malha da palma Flexible Flyer Reborn | corresponde após a correção de escala da palma (§6.5, defeito 2) |
| UnLimbited Phoenix | `UnLimbited_Arm_V2.2.scad` a montante (mesma malha embebida) | **exato** — ≤ 0.06 mm; idêntico byte a byte a 100 % |

### 6.5 Defeitos encontrados e corrigidos

Fechar o ciclo dos números até à **geometria** foi o que fez emergir estes — nenhum era visível
nas verificações numéricas dos Experimentos 1–2. Os três foram corrigidos e re-verificados de
ponta a ponta.

| # | Âmbito | Defeito | Correção |
|---|---|---|---|
| 1 | Grounding (todos os modelos) | `findBestProfileMatch` ancorava **todos** os pacientes em *ANSUR I Male 50th* — o token masculino `'m,'` correspondia às unidades `"mm,"`/`"cm,"`, e a análise era apenas em inglês (§2.4) | **v14.16.0** — tokens multilingues em fronteira de palavra Unicode, classificação por idade, extração opcional por LLM |
| 2 | Palma do Paraglider | A palma Reborn estava **congelada** no tamanho de 83 mm — `scaled_palm()` é importada com `use` (com escopo léxico) e lia o `overall_scale=1.25` codificado da biblioteca, ignorando `palm_breadth_mm` | **v14.17.0** — reaplicar a escala no local de chamada |
| 3 | Override do Phoenix | `HandPerc_override` (intervalo `[0:160]`) tinha uma zona morta `1–99` **sem piso**; a IA usou `76` para imprimir uma palma de criança a 62 mm, abaixo do mínimo suportado de 100 % | **v14.18.0** — limitar também o ramo do override a 100–160 % |

### 6.6 Orientação para seleção de modelo

Os três modelos são **complementares**, não intermutáveis, por tamanho imprimível:

- **Flexy Beast** — escala para o mais pequeno; a escolha certa para **crianças** e mãos
  estreitas.
- **Paraglider · Hand** — entradas antropométricas mais ricas (acrescenta
  comprimento/espessura da palma); bom para adultos num intervalo amplo.
- **UnLimbited Phoenix** — malha fixa, **apenas 82 mm e acima**; excelente fidelidade ao
  original mas inadequado para mãos pequenas (o seu próprio texto de ajuda redireciona para o
  Flexy Beast).

Para os perfis de criança e mulher aqui, o Flexy Beast ou o Paraglider são corretos; o Phoenix
limita-os ao piso. Isto é agora consistente na geometria após a correção do defeito 3.

---

## 7. Discussão

**Fidelidade anatómica.** Em oito perfis distintos o modelo respeitou a ordenação padrão dos
dedos e as normas de magnitude do adulto/pediátricas, e refletiu tanto o **dimorfismo sexual**
(homens > mulheres em todos os campos) como a **variação populacional regional** (o país
influenciou as estimativas). A mulher de 65 anos e o jovem magro de 15 anos convergiram para
tamanhos semelhantes de adulto pequeno, o que é anatomicamente razoável e indica que o modelo
raciocina conjuntamente sobre múltiplos proxies em vez de se fixar num único atributo.

**Degradação graciosa.** Os dois experimentos demonstram em conjunto uma relação monótona entre
a riqueza das entradas e a dependência dos priors: as medições fornecidas são usadas
literalmente, os dados parciais ancoram a estimativa proporcional e apenas-demográficos recorre
totalmente às normas populacionais — sem o utilizador precisar de saber quais os campos
relevantes. Este é precisamente o comportamento que o objetivo de acessibilidade exige.

**Adaptação emergente de hardware.** A redução das dimensões das articulações flexíveis para uma
mão de criança não foi pedida no texto do perfil; decorre das *legendas* dos parâmetros (que
indicam "reduzir para mãos de crianças pequenas"), mostrando que o modelo usa a documentação do
schema injetado, e não apenas os seus nomes.

---

## 8. Limitações e Ameaças à Validade

1. **Amostragem de extração única.** Os resultados são uma execução representativa por perfil.
   Caracterizamos mas não limitamos estatisticamente a distribuição de saída; um estudo rigoroso
   agregaria muitas extrações e reportaria a dispersão por parâmetro.
2. **Sem verdade de terreno clínica.** Os limites de plausibilidade são intervalos populacionais,
   não a verdade medida por paciente. Isto valida a *razoabilidade*, não a *exatidão* face a uma
   mão real.
3. **Lateralidade inferida.** Como referido na §5.4, a atribuição do lado depende da inferência
   do modelo e é um risco latente de segurança para entradas concisas até ser tornada explícita.
4. **Fragilidade heurística no harness.** A verificação "menor ⇒ palma < 70 mm" produziu um
   falso positivo; as heurísticas de teste têm de contemplar adolescentes quase-adultos.
5. **Falhas estocásticas de infraestrutura.** Uma rajada de chamadas rápidas consecutivas
   devolveu uma resposta vazia/não parseável; um pequeno atraso resolveu-a. O uso em produção
   deveria acrescentar retry/backoff e validação estrita de JSON-schema com um novo prompt em
   caso de falha.
6. **Acoplamento a modelo/versão.** As conclusões são específicas de `claude-sonnet-4-6`; o
   comportamento (em especial as inferências emergentes) pode diferir noutros modelos ou versões
   futuras e deve ser re-validado em caso de mudança.
7. **Os experimentos antecedem o grounding por dataset.** As execuções da §4–§5 (2026-06-05)
   mediram os priors *não auxiliados* do modelo; o grounding do lado do servidor (§2.4) foi
   lançado depois (v11.0.0, 2026-06-06) e está agora ativo por omissão. Os números reportados
   caracterizam, portanto, o comportamento sem grounding; o comportamento com grounding ainda
   não foi re-medido sob este protocolo.

---

## 9. Trabalho Futuro

- **Regra explícita de contralateral/espelhamento** no prompt, removendo a dependência da
  inferência para um parâmetro relevante para a segurança.
- **Validação estatística:** amostragem de N extrações por perfil com média/σ reportadas por
  parâmetro e taxas de aprovação dos invariantes.
- **Saída validada por schema:** impor um JSON schema do lado do servidor e fazer auto-re-prompt
  em caso de violação, em vez de descartar silenciosamente chaves desconhecidas.
- **Benchmarking face à verdade de terreno** contra datasets de mãos medidas para quantificar o
  erro de estimativa, não apenas a plausibilidade.
- **Re-validação com grounding:** re-executar a §4–§5 com o grounding por dataset (§2.4) ativado
  e comparar com o baseline sem grounding — será que a ancoragem no grupo populacional
  correspondente reduz a variância entre execuções (§4.4) e aperta as estimativas de entradas
  qualitativas sem sobrepor as medições fornecidas? _(Ainda em aberto como estudo estatístico.)_
  - ✅ **`findBestProfileMatch` validado (2026-06-28).** As simulações de browser end-to-end
    (login → sugestão por IA → exportação STL) no Flexy Beast e no Paraglider mostraram que o
    matcher ancorava uma criança, uma mulher e um homem **todos** em *ANSUR I Male 50th
    Percentile*, expondo o bug de unidades-como-masculino / apenas-inglês. Corrigido na v14.16.0
    (§2.4); após a correção as mesmas entradas correspondem a *Dutch children age 7*, *ANSUR I
    Female* e *ANSUR I Male* respetivamente. Execuções completas, prompts e dimensões por peça em
    [`docs/flexy-beast-ai-sim/`](flexy-beast-ai-sim/flexy-beast_ai-sizing-dimensional-report_2026-06-28.md)
    e [`docs/paraglider-ai-sim/`](paraglider-ai-sim/paraglider-hand_ai-sizing-dimensional-report_2026-06-28.md).
- **Conjunto permanente de regressão:** reter os perfis de apenas-demográficos como teste
  permanente, dado que esse caminho serve o utilizador de menor conhecimento.

---

## 10. Reprodutibilidade

O servidor deve estar em execução com uma `ANTHROPIC_API_KEY` válida no `.env`. O harness de
validação inicia sessão como admin, reconstrói o prompt exato do frontend para cada perfil
(injetando o schema de parâmetros vivo de `flexy_beast` a partir de `models/models-config.json`),
chama `POST /api/ai/suggest`, parseia o JSON devolvido e aplica os critérios da §3.3. Como a
amostragem é estocástica, espere que os números difiram entre execuções enquanto as verificações
de invariantes continuam a passar. Ao emitir muitos pedidos em sucessão rápida, insira um pequeno
atraso (ou retry com backoff) para evitar erros transitórios do fornecedor.

**Controlo do grounding.** Para reproduzir os números *sem grounding* da §4–§5, omita
`patient_text`/`model_id` do corpo do pedido (ou execute contra uma base de dados sem perfis
importados) para que nenhum bloco de grounding seja anexado; o campo de resposta `grounded`
confirma qual o caminho executado. Para exercitar o comportamento com grounding, envie ambos os
campos exatamente como o frontend vivo faz e importe primeiro um dataset populacional (Apêndice
C).

---

## Apêndice A — Template do prompt

Para cada perfil o frontend envia o seguinte (o prompt vivo incorpora o JSON completo dos
parâmetros do Flexy Beast em vez do array abreviado):

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

Quando o grounding por dataset (§2.4) encontra um grupo populacional correspondente, o servidor
anexa o seguinte bloco ao prompt acima antes de chamar o fornecedor:

```
Reference population data — the closest matching group in our anthropometric
dataset is "<group_name>", n=<sample_size> (dataset completeness: <uncertainty>).
Its measured mean values are:
  palm_breadth_mm: 79.3 mm
  middle_finger_length_mm: 78.6 mm
  index_finger_length_mm: 71.3 mm
  ring_finger_length_mm: 74 mm
  pinky_finger_length_mm: 60.4 mm
  thumb_length_mm: 64.8 mm
Anchor your estimate on these measured means, adjusting for the patient's specific
description (build, height, stated measurements). Supplied patient measurements always
take precedence over these population means.
```

Os valores acima são as médias reais do grupo *ANSUR I Female 50th Percentile* tal como
devolvidas por `GET /api/anthropometric/1/model-parameters?model_id=flexy_beast` — isto é, a
projeção idêntica que o seletor "Population baseline" do configurador aplica.

## Apêndice B — Intervalos antropométricos canónicos do adulto

Fonte: `CLAUDE.md` (Anthropometric Parameter Alignment). Usados como limites de plausibilidade na
§3.3.4.

| Parâmetro | Medição | Intervalo típico do adulto |
|---|---|---|
| `palm_breadth_mm` | Largura metacarpal nó-a-nó | 70–100 mm |
| `middle_finger_length_mm` | Prega MCP à ponta do dedo médio | 60–115 mm |
| `index_finger_length_mm` | Prega MCP do indicador à ponta | 55–110 mm |
| `ring_finger_length_mm` | Prega MCP do anelar à ponta | 55–110 mm |
| `pinky_finger_length_mm` | Prega MCP do mindinho à ponta | 40–85 mm |
| `thumb_length_mm` | Prega MCP do polegar à ponta | 45–80 mm |

## Apêndice C — Importação em massa de dataset populacional

A §2.3 nota que a saída da IA, a introdução manual e os **perfis populacionais importados de
CSV** partilham um único vocabulário de medição. Este apêndice documenta como essa biblioteca
populacional é construída a partir do dataset de investigação incluído, dado que o caminho de
importação é fácil de interpretar mal.

### C.1 O que é o dataset

`data/multi_population_hand.csv` é um **dataset de literatura de investigação**, não uma lista de
pacientes individuais. Cada linha é uma única medição publicada (por ex. *"Finger length (right
hand) - Thumb"*) para uma população, etiquetada com o seu estudo de origem, página/citação,
país, sexo, faixa etária, dimensão da amostra e um `stat_type` (`mean`, `std_dev`, `min`, `max`
ou um percentil). Uma população abrange, portanto, muitas linhas — uma por medição × estatística.

### C.2 Como funciona "Import CSV Dataset"

O controlo é um **seletor de ficheiro local**, não um fetch do servidor. O botão do painel de
admin (`admin.js`) aciona um `<input type="file">` oculto; o browser lê o texto do ficheiro
escolhido no lado do cliente (`file.text()`) e fá-lo POST como `csv_text` para
`POST /api/anthropometric/import-csv-bulk` (`server/routes/anthropometricRoutes.js`). O servidor
nunca carrega o caminho por HTTP — a referência `data/...` nos docs é apenas onde o ficheiro
reside no disco do operador. (Por conseguinte, o bloqueio estático `/data/* → 404` é irrelevante
para a importação; apenas protege pedidos de URL.)

Processamento do lado do servidor:

1. **Parse** do CSV, voltando a juntar linhas divididas por quebras de linha dentro de campos de
   citação entre aspas (verificação de aspas balanceadas).
2. **Filtrar** para linhas utilizáveis: manter apenas `stat_type === 'mean'`, apenas medições
   presentes em `MEASUREMENT_MAP`, e apenas `value_mm` numérico positivo. As linhas de *valor*
   de std-dev / min / max / percentil são descartadas.
3. **Agrupar** as linhas pela chave composta `population | country | sex | age_group |
   percentile`. Todas as médias por dedo e da palma de uma população colapsam num **único
   perfil**; a primeira média vence por campo.
4. **Derivar e inserir** — para cada grupo o `anthropometricImporter` deriva os parâmetros de
   geometria (`palm_breadth_mm`, comprimentos de dedos, …) e um blob de contexto de IA, e uma
   linha é inserida em `anthropometric_profiles`.

A resposta é `{ created, skipped, total_groups }`, exibida na UI como um toast.

### C.3 Idempotência

A cada grupo é atribuído um `group_name` determinístico
(por ex. `Young adults (age 18-30) female (Turkey) — 50th`). Antes de inserir:

```js
const existing = db.prepare(
  'SELECT id FROM anthropometric_profiles WHERE group_name = ?'
).get(group_name);
if (existing) { skipped++; continue; }
```

Por isso re-executar a importação é seguro: a segunda execução reporta `created: 0, skipped: N`
sem duplicados. **Ressalva:** a chave de deduplicação é `group_name`, que omite `data_source` —
dois estudos diferentes que produzam a mesma etiqueta de população/sexo/país/percentil
colidiriam, e a primeira importação vence em vez de as duas serem fundidas.

### C.4 Nota sobre disponibilidade

`data/` está em gitignore, pelo que `data/multi_population_hand.csv` **não está versionado no
repositório** e é excluído pelo `deploy.sh`. Deve ser fornecido à máquina do operador por outra
via antes de o passo de importação nos guias README/QUICK-START poder ser seguido.
