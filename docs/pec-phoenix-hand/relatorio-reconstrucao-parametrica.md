# Reconstrução paramétrica da mão protésica e-NABLE Phoenix (modelo *pec Phoenix hand*)

**Relatório técnico de desenvolvimento** — 12 de julho de 2026 (desenvolvimento decorrido a 11–12 de julho de 2026)
Repositório: `ai-parametric-prosthetic-hand-generator` · modelo `models/active/pec_phoenix_hand/` · versões v14.51.0–v14.56.0 do registo de alterações (`CHANGELOG.md`)

---

## 1. Introdução e objetivos

As próteses de mão de fabrico aditivo distribuídas pela comunidade e-NABLE — em particular a família Phoenix/UnLimbited — circulam maioritariamente sob a forma de malhas triangulares (STL), resultado de processos de modelação escultórica. Este formato, adequado à impressão direta, é inadequado à personalização antropométrica: uma malha não expõe dimensões com significado clínico (largura da palma, comprimento das falanges, diâmetros de furação), pelo que qualquer ajuste ao paciente se reduz a uma escala global uniforme, com as distorções funcionais conhecidas (folgas de pinos e canais que escalam juntamente com a anatomia).

O presente trabalho documenta a reconstrução da palma esquerda e das falanges da mão Phoenix como **modelos paramétricos legíveis em OpenSCAD**, integráveis na plataforma de geração de próteses desenvolvida no âmbito desta dissertação. Os objetivos específicos foram:

1. **Fidelidade dimensional** às peças originais, com as interfaces funcionais (furos de pinos, ranhuras, canais de cabo) dimensionalmente exatas;
2. **Parametrização com significado** — cada número editável deve corresponder a uma característica física identificável, com os valores medidos no original como *defaults*;
3. **Eliminação progressiva das dependências de malha** (recortes por interseção com o STL original), condição necessária à portabilidade para o renderizador OpenSCAD WebAssembly da plataforma, que não dispõe dos ficheiros STL locais;
4. **Verificabilidade** — instrumentação de verificação incorporada no próprio modelo e métricas quantitativas de semelhança geométrica.

## 2. Metodologia

Adotou-se o método de reconstrução por fidelidade de características documentado internamente em `openscad-parametric-reconstructor/RECONSTRUCTION_METHOD.md`, cujo princípio nuclear se resume na máxima *measure, never guess*: nenhuma dimensão entra no código sem provir de uma medição sobre a malha original. Os elementos essenciais do método são:

- **Malha-fantasma alinhada (*ghost*).** O STL original é realinhado ao referencial do modelo (centrado em X/Y, base em Z = 0) e importado de forma translúcida sobre a reconstrução, permitindo verificação visual contínua da coincidência de envelopes. No modelo da palma, o original apresenta uma caixa envolvente de X ±41,43 mm, Y ±46 mm e Z 0–30,6 mm.
- **Medição instrumentada.** Extração de perfis por secção (`stl-to-openscad.py`), mapas de ocupação (`mesh.contains`), varrimentos de secções e extração de faces originais por zona, com tabelas comparativas *alvo | obtido* a preceder qualquer alteração de código.
- **Construção por primitivas simples**, fundidas por `union()` e escavadas por `difference()`, privilegiando a legibilidade sobre a mimetização cega da malha.
- **Instrumentação de verificação no Customizer** do próprio ficheiro: sobreposição do *ghost* (`show_ghost`), planos de corte (`section` longitudinal/transversal/horizontal com `section_at`) que seccionam simultaneamente modelo e *ghost*, e vista colorida por peça (`debug_colors`).
- **Métrica quantitativa.** A semelhança volumétrica é avaliada por *Intersection over Union* (IoU) voxelizada (passo 0,4–0,5 mm; `verify_recon.py`), reportada de forma honesta e nunca usada como critério binário de aceitação — para cascas orgânicas finas, primitivas legíveis limitam estruturalmente o IoU atingível.
- **Verificação topológica.** Exportação STL com confirmação de variedade fechada (*manifold*, estado `NoError` no relatório do OpenSCAD).

A este método acrescentou-se, na fase aqui descrita, uma **análise comparativa de modelos abertos da comunidade e-NABLE** (Cyborg Beast, família *flexible flyer*/paraglider, gerador *fingerator*), com o propósito de identificar idiomas de construção paramétrica transferíveis. Sublinha-se que a transferência incide sobre **técnicas**, nunca sobre dimensões: copiar formas de uma família de mãos distinta degradaria a fidelidade ao original Phoenix.

## 3. Arquitetura do modelo

### 3.1 Ficheiro único com peças comutáveis

O modelo da palma foi consolidado num único ficheiro, `Palm_left_V2.scad` (v14.51.0), absorvendo os cinco ficheiros parciais anteriormente incluídos por `include`. O ficheiro organiza-se em sete secções (*PARTES*), cada uma com uma caixa de verificação própria no grupo `[Features]` do Customizer, permitindo isolar qualquer peça para inspeção, depuração ou impressão parcial:

| Parte | Conteúdo | Comutador |
|---|---|---|
| 1 | Casca dorsal (arco + canais de cabo) | `show_shell` |
| 2 | Montagem de pivô do polegar | `show_thumb` |
| 3 | Clevises de pivô dos dedos (nós) | `show_knuckles` |
| 4 | Aletas dorsais e coroas | `show_fins` |
| 5 | Orelhas de charneira e paredes do punho | `show_wrist` |
| 6 | Parede posterior do punho | `show_wrist_back` |
| 7 | Chão palmar perfurado | `show_grid` |

O módulo `model()` funde as peças ativas; os furos globais são recortados por peça, garantindo que cada comutador produz um sólido coerente (Figura 4).

### 3.2 Montagem

O ficheiro `_assembly.scad` compõe a mão completa: palma, falanges proximais e distais, guarda de antebraço e ferragens. Os pinos de encaixe e o bloco tensor provêm de reconstruções B-rep exatas a partir de ficheiros STEP (`phoenix_snap_pins.scad`, `phoenix_tensioner_block.scad`, `phoenix_tensioner_pins.scad`, v14.50.0), assentes nas interfaces medidas da palma (pinos dos nós, furo do polegar, orelhas do punho). Toda a alteração às peças propaga-se automaticamente à montagem, uma vez que esta inclui o ficheiro da palma e chama os módulos por nome (Figura 7).

## 4. Técnicas paramétricas adotadas

O núcleo do trabalho consistiu em substituir geometria de origem orgânica — tabelas de pontos medidos e recortes pela malha original — por construções paramétricas suaves, adotando idiomas identificados em modelos abertos da comunidade.

### 4.1 Casca dorsal: técnica *hull-of-primitives* (proveniência: Cyborg Beast)

A casca dorsal encontrava-se implementada como um *loft* (`skin()` da biblioteca BOSL2) de 30 estações transversais com 34 pontos cada — cerca de mil coordenadas medidas, regeneradas por um passo de ajuste automático e, por isso, não editáveis manualmente. Tratava-se de geometria *data-driven*: paramétrica na construção, mas orgânica na forma.

A análise do modelo Cyborg Beast (`cyborgpalm001.scad`, módulo `cyborgbeast07palm`) revelou o idioma alternativo: o sólido exterior é **um único `hull()` estendido sobre meia dúzia de primitivas de controlo com nome** (esferas achatadas por `scale`, cilindros, prismas finos), a cavidade interior é um segundo `hull()` de primitivas próprias, subtraído, e os cortes funcionais são aplicados no fim. O invólucro convexo estica uma "pele" G1-contínua sobre as primitivas, produzindo superfícies suaves sem tabelas de pontos.

A casca foi reconstruída segundo este idioma (v14.53.0): três **estações de controlo** (rebordo do punho, secção média, rebordo dos dedos), cada uma composta por um elipsoide de coroa achatado e dois postes de parede; o exterior é o `hull()` das três estações, cortado por planos verticais nos dois rebordos; a cavidade é o mesmo `hull()` com as estações encolhidas pela espessura de parede, prolongado para além dos rebordos e abaixo da placa, de modo a deixar o fundo e os topos abertos; os cinco canais de cabo são subtraídos no fim. O grupo `[Shell]` do Customizer expõe 18 parâmetros — espessura de parede (`SHELL_WALL` = 5,0 mm), raio dos canais (`CH_R` = 1,23 mm), altura do "joelho" parede/coroa (`SHELL_KNEE_Z` = 20 mm), três parâmetros de forma da coroa (`CROWN_FLAT/RZ/RY`) e doze escalares de estação (`Y`, `X` esquerdo, `X` direito e altura de ápice por estação) — todos com os valores medidos como *defaults*, pelo que a renderização por omissão continua a acompanhar o envelope original (Figuras 1–3).

A verificação incluiu sobreposição com o *ghost*, secções transversal, longitudinal e horizontal (parede uniforme de ~5 mm; canais embebidos no teto) e exportação STL da casca isolada com estado *manifold* `NoError`.

Numa iteração posterior (v14.56.0, 12 de julho de 2026) eliminou-se o vinco de ~90° na transição parede→coroa com a introdução do parâmetro `KNEE_R` (3,5 mm por omissão) no grupo `[Shell]`: um par de cilindros de concordância por estação, tangentes aos planos exteriores das paredes à altura do "joelho" (z = 20 mm), com cópia concêntrica na cavidade de raio `KNEE_R` menos a espessura de parede, o que preserva a espessura uniforme da casca ao longo da concordância (Figura 12). Após a alteração, o modelo completo manteve o estado *manifold* `NoError` e a montagem renderiza sem avisos.

### 4.2 Chão palmar: contorno por primitivas ancoradas (proveniência: `Palm_left_floor.scad`)

O chão perfurado assentava num polígono de 45 pontos medidos e, na banda frontal, num recorte por interseção com o STL original (*ghost-clip*), que conformava a placa à face inferior côncava sob os nós dos dedos.

Do ficheiro de referência `Palm_left_floor.scad` transferiu-se o idioma da **placa extrudida a partir de um contorno 2D suavizado por cadeias de `offset`**, levado mais longe: o contorno passou a ser a **união de primitivas de pegada com nome, cada uma ancorada à peça vizinha com que solda** — corpo principal sob os pés da casca, aventais e abas frontais por clevis de dedo (parando a `cy − folga` para preservar o curso de flexão do dedo), abas posteriores derivadas das estações das orelhas do punho e apoios do polegar alinhados com o eixo de 50° do respetivo pivô. A suavização aplica um fecho morfológico (filete côncavo) seguido de abertura (arredondamento convexo), com raios paramétricos de 1,2 mm. A grelha de ventilação em *basket-weave* manteve os seus nove parâmetros. O grupo `[Floor]` expõe dez parâmetros de contorno (espessura, sobreposição de soldadura, raios, alcances das abas, folgas), com as coordenadas antigas a sobreviver apenas como *defaults*.

O resultado eliminou por completo a dependência do *ghost* nesta peça, mantendo a cobertura das zonas de acoplamento (Figura 5). A verificação do modelo completo com o novo chão reportou *manifold* `NoError` (género topológico 124, ~83 000 facetas) e nenhum aviso novo de renderização.

### 4.3 Canais de cabo: perfil autoportante e escala inversa (proveniência: *flexible flyer*/paraglider)

A análise dos ficheiros `paraglider_palm_unlimbited_v3.scad`, `paraglider_palm_unlimbited_v3_tensor.scad` e `paraglider_palm_left_tensor.scad` (Marcus Mendenhall, família *flexible flyer*) concluiu que estes **não constroem a palma parametricamente** — importam uma malha base da própria família Phoenix e re-parametrizam apenas as interfaces (idioma *plug-then-drill*: tapar a característica cozida na malha com um sólido sobredimensionado e refurá-la parametricamente). O seu valor para o presente trabalho reside em três idiomas de interface:

1. **Secção em "D" autoportante para os canais de tendão** — fundo plano com cantos chanfrados e arco superior, varrida ao longo de percursos com curvas suavizadas, dispensando suportes de impressão no interior dos furos.
2. **Suavização dos percursos** por interpolação das dobras (equivalente BOSL2: `round_corners` sobre as polilinhas medidas dos cinco canais).
3. ***Inverse-scaling* das interfaces.** Quando o modelo é escalado globalmente para o tamanho do paciente, as dimensões do *hardware* físico (parafusos, pinos, cordel) não escalam. O idioma consiste em dividir cada dimensão de interface pelo fator de escala global antes da aplicação do `scale()` — por exemplo, `cylinder(d = 3.5/overall_scale)` para um furo de parafuso M3 —, de modo que a peça impressa apresente sempre a dimensão nominal do componente, independentemente da escala anatómica. Este princípio será adotado quando a palma receber o gancho de escala global da plataforma; previne a classe de defeitos de dimensionamento já observada noutros modelos do repositório.

Os dois primeiros idiomas foram implementados em `Palm_left_V2.scad`. O perfil "D" foi **invertido** relativamente ao paraglider — chão semicircular e teto quase plano com chanfros a 45° — dado que a palma Phoenix se imprime com o chão na plataforma, colocando o vão em consola no **teto** do furo. A suavização das dobras é feita por `round_corners` (método *smooth*), com raio paramétrico `CH_BEND_R` = 1,2 mm. Os pontos de passagem dos cinco canais, medidos sobre o teto orgânico antigo, foram re-ajustados para acompanhar a coroa paramétrica: os percursos permanecem embebidos na banda de teto de 5 mm até y ≈ 16–22 mm e mergulham depois a 30–45° para as saídas medidas junto aos clevises. Onde um canal abandona o material do teto, é envolvido por uma **bainha tubular impressa** (parede `CH_SHEATH_WALL` = 1,4 mm), ao estilo dos condutos exteriores do *flexible flyer*, de modo que o furo nunca fica exposto. Os cortes passaram a ser gerados por um único módulo, `cable_channels()`, partilhado pelos três locais que os subtraem (`dorsal_shell()`, `front_assembly()`, `wrist_back()`), o que garante o alinhamento exato entre re-cortes. A verificação por secções confirmou os cinco furos embebidos com o teto em "D"; o modelo completo renderiza sem erros e a casca isolada exporta *manifold* `NoError`.

### 4.4 Falanges: idiomas do *fingerator* e melhoria do IoU

Os modelos das falanges (`Proximals.scad`, `Distals_v2.scad`) foram avaliados quantitativamente contra as malhas originais alinhadas, estabelecendo o primeiro *baseline* medido:

| Peça | IoU | Volume excedente | Volume em falta | Observações |
|---|---|---|---|---|
| Falange proximal | 0,947–0,949 | 76 mm³ | 59 mm³ | erro concentrado nos flancos frontais e no rebaixo inferior |
| Falange distal (std) | 0,906–0,914 | 245 mm³ | 85 mm³ | rácio de volume 1,058; erro dominante nos "ombros" das secções |

A análise do gerador *fingerator* (mesma autoria da família *flexible flyer*; cópia local `fingerator.scad`) identificou a razão da suavidade das suas superfícies: **nenhum paralelepípedo aparece em superfície visível** — as secções do corpo são `hull()` de círculos escalados (ovais contínuos), a ponta é um único `hull()` de esferas achatadas e meio toro, as extremidades das forquilhas resultam de interseção com um cilindro concêntrico com o pino, e os relevos côncavos são cilindros elípticos inclinados subtraídos. Em contrapartida, a falange distal reconstruída usa retângulos arredondados nas secções do *loft*, que mantêm os cantos cheios onde o original apresenta secções ovais/ovoides — a origem dos ~118 mm³ excedentes na zona de flexão.

Foi definido e executado um plano de adaptação em seis pontos (P1–P6), aplicado sobre cópias de trabalho (`Distals_v3.scad`, `Proximals_v2.scad`; os ficheiros originais foram preservados como referência), com verificação IoU após cada alteração e preservação estrita das interfaces funcionais — furos e ranhuras de pinos, carris e, em particular, as **aletas dorsais**, características do desenho Phoenix e ausentes no *fingerator*. Alterações que degradaram a métrica foram revertidas (caso do *loft* do corpo cilíndrico da proximal, que regrediu para 0,963).

**Falange proximal** — IoU 0,949 → **0,965** (voxel de 0,4 mm; 0,962 a 0,5 mm), rácio de volume 1,002. Progressão por alteração: P5, afunilamento frontal em três estações (0,950); P6a, rebaixos inferiores elípticos, inclinados e assimétricos (0,958); P6b, barriga em *loft* de dois círculos medidos (0,961); P6c, pés inferiores quase planos por interseção elipse ∩ plano (0,964) — etapa que produziu um achado de medição: as paredes inferiores do original assentam em faces quase planares, com inclinações de 5,3° e 1,1°; P6d, reajuste analítico final (0,965). A invariância das interfaces foi confirmada por soma de verificação (*md5*) módulo a módulo: `pin_hole`, carris, discos dos nós e aletas com coroas permaneceram byte a byte idênticos.

**Falange distal** — IoU por variante: std 0,906 → **0,964**; short 0,908 → **0,962**; thumb 0,879 → **0,972**; rácios de volume 0,992, 0,989 e 0,997, respetivamente. Em P1, as secções do *loft* passaram de retângulos arredondados a perfis superelípticos com afunilamento ("ovo"), ajustados por mínimos quadrados estação a estação contra a malha original (resíduo RMS de 0,02–0,14 mm), mantendo fixa a contagem de vértices (96) para preservar a correspondência do `skin()`. P2 produziu o segundo achado de medição: a face de fundo da ranhura do pino do original **é um cilindro concêntrico com o furo do pino, de raio 7,39 mm, idêntico nos três tamanhos** — precisamente o idioma do *fingerator*, confirmado assim no próprio desenho Phoenix — complementado por dois rebaixos de entrada do furo, medidos. P3 densificou a cúpula da ponta com cinco a seis estações medidas (caixa envolvente Y = 43,52 mm contra 43,60 mm no original); P4 deu à goteira do tendão um fundo com inclinação medida por tamanho e uma rampa de saída do cordel. Os invariantes (ranhura de 5,90 mm, pino, vetores `feat_*`, aleta e coroa) mantiveram-se byte a byte idênticos e foram confirmados na geometria renderizada.

As Figuras 8–10 documentam a comparação visual de partida que motivou o plano.

### 4.5 Clevises dos dedos: eliminação do *ghost-clip* e costura paramétrica com a casca

Na iteração de 12 de julho de 2026 (v14.56.0), a Parte 3 — os quatro clevises de pivô dos dedos e a respetiva junção com a casca dorsal — tornou-se **totalmente paramétrica**, eliminando o operador `clip_ghost` que até aí aparava toda a peça pela malha original. A reconstrução seguiu o princípio de medição por característica: os olhos de pivô passaram a invólucros (`hull`) medidos **por prong físico**, mantendo exatos os discos-pé de raio 5,9 mm tangentes à placa e substituindo o anterior disco de sobre-enchimento aparado pela malha por topos de "capuz" medidos; as caixas de fusão posteriores (*backboxes*) deram lugar a pescoços e cortinas com dimensões medidas; e a banda de junção que era recortada pela malha foi substituída por lajes de flanco e de vão complementadas por bolsas de janela arredondadas, cujos postes de rebordo **seguem o perfil do rebordo da casca paramétrica**, produzindo uma costura C0 sem degrau — o efeito de "escada" anteriormente visível no canto do mindinho foi eliminado por interpolação entre os níveis dos dedos (Figuras 11 e 13). Os *keyholes* funcionais (furo redondo e ranhura retangular do pino) continuam a ser cortados no fim, com as dimensões byte-exatas; os canais de cabo são re-cortados pelo módulo partilhado `cable_channels()`, com enclausuramento melhorado (canal 1 a 96 %, canal 2 a 100 %) e as bocas verificadas abertas por *flood-fill* voxelizado.

Regista-se, por transparência metodológica, o custo desta escolha na métrica volumétrica: o IoU voxelizado da banda dos nós (Y 18–46 mm) desceu de 0,909 para 0,730. O volume excedente corresponde à **junção contínua com a casca, escolhida deliberadamente** segundo o critério de projeto definido pelo utilizador — suavidade da ligação à casca acima da fidelidade à malha bruta, que naquela zona exibia rebordos expostos com degraus até 5 mm. Trata-se, portanto, de um desvio documentado e parametrizado (a geometria de junção é afinável pelos parâmetros da costura), e não de uma regressão acidental — um exemplo concreto do enquadramento metodológico que reporta o IoU honestamente sem o erigir em critério binário de aceitação (secção 2).

## 5. Resultados e verificação

À data de 12 de julho de 2026, encontram-se concluídos e verificados:

- **Consolidação e comutadores por peça** (v14.51.0) — as sete peças isolam-se individualmente; a montagem completa renderiza sem erros.
- **Casca dorsal paramétrica** (v14.53.0) — sobreposição *ghost* com acompanhamento próximo do envelope (Figura 1); secções com parede uniforme de ~5 mm e canais embebidos (Figuras 2–3); STL isolado *manifold* `NoError`; soldadura preservada com clevises, polegar, punho e chão no modelo completo (Figura 6).
- **Chão palmar paramétrico** (v14.53.0) — contorno suave sem malha original; abas alinhadas sob os prongs dos clevises e apoios do polegar confirmados contra o *ghost* (Figura 5); modelo completo *manifold* `NoError`; montagem íntegra em vista inferior (Figura 7).
- **Canais de cabo em perfil "D"** — os cinco canais re-encaminhados e embebidos na coroa paramétrica, com teto autoportante, dobras suavizadas e bainhas tubulares onde saem do material; módulo de corte único partilhado pelas três peças; secções de verificação e casca *manifold* `NoError` (secção 4.3).
- **Melhoria de IoU das falanges (P1–P6)** — a partir do *baseline* medido (tabela da secção 4.4): proximal 0,949 → 0,965 (rácio de volume 1,002); distal std 0,906 → 0,964, short 0,908 → 0,962, thumb 0,879 → 0,972 (rácios 0,992/0,989/0,997), com todas as interfaces funcionais confirmadas byte a byte idênticas (secção 4.4). Os valores finais passam a constituir a referência de regressão.
- **Clevises dos dedos totalmente paramétricos** (v14.56.0) — *ghost-clip* eliminado na Parte 3; costura C0 com o rebordo da casca paramétrica, sem degraus (Figuras 11 e 13); *keyholes* byte-exatos; bocas dos canais verificadas abertas por *flood-fill* voxelizado; trade-off de IoU na banda dos nós documentado na secção 4.5.
- **Concordância parede→coroa da casca** (`KNEE_R`, v14.56.0) — vinco de ~90° substituído por filete cilíndrico com espessura de parede preservada (Figura 12); modelo completo *manifold* `NoError` e montagem sem avisos.

### Figuras

- **Figura 1** — Sobreposição da casca dorsal paramétrica (opaca) com a malha original alinhada (translúcida). `img/fig01-shell-sobreposicao-ghost.png`
- **Figura 2** — Secção transversal da casca com o *ghost*: parede uniforme e furos dos canais de cabo no teto. `img/fig02-shell-seccao-transversal.png`
- **Figura 3** — Secção horizontal a Z = 10 mm: paredes laterais a acompanhar o original. `img/fig03-shell-seccao-horizontal.png`
- **Figura 4** — Vista colorida por peça (`debug_colors`) com casca e parede posterior desativadas, ilustrando os comutadores por peça. `img/fig04-partes-por-cores.png`
- **Figura 5** — Chão palmar paramétrico em vista de topo sobre o *ghost*: abas frontais sob os clevises e apoios do polegar. `img/fig05-chao-topo-ghost.png`
- **Figura 6** — Modelo completo da palma (renderização isométrica, geometria integralmente avaliada). `img/fig06-modelo-completo-iso.png`
- **Figura 7** — Montagem completa em vista inferior: chão paramétrico soldado a paredes, orelhas e clevises, com os dedos montados. `img/fig07-assembly-vista-inferior.png`
- **Figura 8** — Falange do *fingerator*: superfície contínua obtida por `hull()` de primitivas curvas. `img/fig08-fingerator-falange.png`
- **Figura 9** — Falange proximal reconstruída (vista lateral, baseline IoU 0,947–0,949). `img/fig09-proximal-reconstruida.png`
- **Figura 10** — Falange distal reconstruída (vista lateral, baseline IoU 0,906–0,914). `img/fig10-distal-reconstruida.png`
- **Figura 11** — Clevises paramétricos e junção com a casca, com sobreposição da malha original: costura contínua sem recorte pela malha. `img/fig11-clevises-juncao-ghost.png`
- **Figura 12** — Secção transversal da casca com a concordância parede→coroa (`KNEE_R`): eliminação do vinco com espessura de parede preservada. `img/fig12-shell-joelho-boleado.png`
- **Figura 13** — Canto frontal esquerdo (mindinho) após a interpolação entre níveis dos dedos: costura C0 sem o efeito de "escada". `img/fig13-canto-frontal-esquerdo.png`

## 6. Discussão e limitações

**Dependências de malha remanescentes.** Após a parametrização dos clevises (secção 4.5), apenas duas zonas da palma continuam a recorrer a interseções com o STL original: o polegar (Parte 2, três usos — enchimento, junção com a casca e cúpula dorsal) e a parede posterior do punho (Parte 6, um uso — integralmente *ghost-clip*). Até à sua substituição, o ficheiro não é portátil para o renderizador WASM da plataforma. As vias de substituição estão identificadas: uma quarta estação de controlo ("cuff", Y ≈ −45 mm) na técnica da casca para a parede posterior, e o idioma de "capota" (*hull* de discos achatados menos cópia encolhida, observado nas coberturas de nós do paraglider) para a cúpula do polegar, reutilizando o próprio `shell_station()` rodado para o eixo do polegar.

**Fidelidade orgânica vs. parametrização.** A substituição de geometria medida ponto-a-ponto por primitivas suaves implica um desvio deliberado face ao original — aceite como *trade-off* pela editabilidade e portabilidade, de acordo com a decisão de projeto de abdicar por completo da componente orgânica desde que a superfície resultante seja suave. A sobreposição *ghost* mantém o desvio visível e quantificável.

**Convexidade do invólucro.** O `hull()` é intrinsecamente convexo: concavidades de silhueta (o estreitamento frontal da planta da palma, por exemplo) só são reproduzíveis por interseção com planos/sólidos adicionais ou por composição de múltiplos invólucros. As protuberâncias convexas medidas (o bojo lateral médio) são, pelo contrário, capturadas naturalmente pelas estações de controlo.

**IoU como métrica.** Reitera-se o enquadramento metodológico: o IoU é reportado, não otimizado como fim em si. Nas falanges, a margem entre o *baseline* (0,879–0,949) e os valores finais (0,962–0,972) proveio de erro sistemático de forma de secção, corrigido sem tocar nas interfaces — e a correção produziu conhecimento sobre o original (a face de fundo da ranhura cilíndrica e concêntrica com o pino; os pés inferiores quase planares da proximal). Os ~3,5 % residuais correspondem a efeitos de "pele" abaixo de 0,2 mm, com retornos fortemente decrescentes, pelo que não se justifica prosseguir a otimização. Para a casca fina da palma, o teto prático do IoU é estruturalmente mais baixo e a verificação por secções e sobreposição é mais informativa. O caso complementar é a banda dos nós (secção 4.5): aí o IoU desceu deliberadamente (0,909 → 0,730) porque o critério de projeto — a suavidade da junção com a casca — prevaleceu sobre a fidelidade a uma zona da malha bruta com defeitos próprios; a métrica cumpre o seu papel ao tornar o custo do critério explícito e rastreável.

**Trabalho futuro imediato.** Quarta estação da casca para a parede posterior do punho; capota paramétrica do polegar; gravação de série/escala (*labels* com proveniência clínica, idioma `do_labels()` do paraglider); gancho de escala global com *inverse-scaling* das interfaces, em articulação com o dimensionamento antropométrico da plataforma; promoção das cópias de trabalho das falanges (`Proximals_v2.scad`, `Distals_v3.scad`) a ficheiros ativos da montagem após validação de impressão.

## 7. Referências

Fontes internas do repositório (consultadas a 11–12 de julho de 2026):

1. **Método de reconstrução** — `openscad-parametric-reconstructor/RECONSTRUCTION_METHOD.md`; ferramenta de verificação `openscad-parametric-reconstructor/scripts/verify_recon.py`.
2. **Modelo reconstruído** — `models/active/pec_phoenix_hand/Palm_left_V2.scad` (v14.51.0–v14.56.0); montagem `_assembly.scad`; falanges `Proximals.scad`, `Distals_v2.scad` e cópias de trabalho `Proximals_v2.scad`, `Distals_v3.scad`; ferragens STEP `phoenix_snap_pins.scad`, `phoenix_tensioner_block.scad`, `phoenix_tensioner_pins.scad` (v14.50.0).
3. **Cyborg Beast** (comunidade e-NABLE) — `models/active/pec_phoenix_hand/cyborgpalm001.scad`: técnica *hull-of-primitives* da palma (módulos `cyborgbeast07palm`, `cyborgbeast07palminsidespace`, `hardwarecutouts`).
4. **Chão de referência** — `models/active/pec_phoenix_hand/Palm_left_floor.scad` (cópia de `openscad-parametric-reconstructor/templates/`).
5. **Família *flexible flyer*/paraglider** (Marcus Mendenhall, 2020–2022) — `models/active/pec_phoenix_hand/paraglider_palm_unlimbited_v3.scad`, `paraglider_palm_unlimbited_v3_tensor.scad`, `paraglider_palm_left_tensor.scad`; originais com dependências em `archive/tests/flexible-flyer-master/flexible_flyer-master/files/`.
6. **Fingerator** (gerador de dedos da mesma família) — cópia local `models/active/pec_phoenix_hand/fingerator.scad`; fonte de referência `~/dev/anatofab/prostfab/converters/fingerator.scad`.
7. **Registo de alterações** — `CHANGELOG.md`, entradas v14.50.0–v14.56.0 (11–12 de julho de 2026).

---

*Documento gerado no âmbito do desenvolvimento da plataforma de geração assistida de próteses; os caminhos citados referem-se ao repositório do projeto. As afirmações quantitativas (IoU, volumes, contagens de parâmetros) correspondem a medições efetuadas nas sessões de trabalho de 11 e 12 de julho de 2026.*
