# Gerador Paramétrico de Mãos Protésicas com IA

**🌐 Idiomas: [English](README.md) · Português**

**🔗 Em linha: [handfab.pedrocandeias.net](https://handfab.pedrocandeias.net)**

Plataforma de personalização paramétrica de mãos protésicas assistida por IA. O clínico introduz as medidas antropométricas do paciente; um modelo de IA (Claude ou GPT-4) sugere os parâmetros de desenho ideais; o resultado é renderizado no próprio navegador através de WebAssembly e exportado em STL para impressão 3D.

Construído sobre o [OpenSCAD](https://openscad.org/) e o ambiente de execução WASM do [OpenSCAD Playground](https://github.com/openscad/openscad-playground).

---

## Funcionalidades

- **Renderização 3D no navegador** — o OpenSCAD corre inteiramente em WebAssembly; sem ida e volta ao servidor para renderizar
- **Sugestões de parâmetros por IA** — o Claude ou o GPT-4 analisa os dados antropométricos e recomenda valores de parâmetros
- **Seis parâmetros antropométricos canónicos** — todos os modelos partilham as mesmas definições de medida (`palm_breadth_mm`, `palm_length_mm`, `palm_thickness_mm`, `middle_finger_length_mm`, `thumb_length_mm`, `gauntlet_width_mm`) para que os perfis dos pacientes preencham automaticamente os campos do modelo
- **Configurações guardadas** — conjuntos de parâmetros nomeados, armazenados por paciente; carregáveis entre sessões
- **Multiutilizador com RBAC** — funções Administrador / Técnico / Utilizador; os técnicos gerem os pacientes que lhes estão atribuídos
- **Proxy de API seguro** — as chaves de IA residem apenas no servidor
- **Exportação STL** — descarregue ficheiros prontos a imprimir diretamente do navegador; os modelos com peças definidas oferecem uma janela de seleção para exportar o modelo completo ou peças individuais (várias peças são descarregadas como ZIP). No Flexy Beast, cada dedo divide-se numa peça **base** e numa peça **ponta** separadas, para que cada componente imprimível possa ser exportado e orientado isoladamente
- **Editor de código SCAD para administradores** — os administradores podem editar manualmente o código OpenSCAD e renderizar de imediato
- **Biblioteca de perfis antropométricos** — importe conjuntos de dados de medidas de mãos ao nível populacional; os parâmetros geométricos são derivados automaticamente e mapeados para os campos do modelo
- **Importação CSV em lote** — carregue um conjunto de dados de medidas de mãos de uma população (por exemplo, o conjunto de investigação `multi_population_hand.csv`, com ~96 grupos) através do seletor de ficheiros do navegador, com um só clique. A importação lê o ficheiro localmente e envia o seu conteúdo; repetir é seguro (os grupos duplicados são ignorados)
- **Multilingue (EN/PT)** — um seletor de idioma traduz toda a interface (aplicação, configurador, painel de administração) e o texto dos modelos/parâmetros; o idioma ativo é detetado a partir do navegador e memorizado. Adicionar um idioma resume-se a um único ficheiro de dicionário
- **Rodapé e páginas de conteúdo editáveis (CMS)** — os administradores gerem o rodapé e criam páginas em Markdown (Privacidade, Termos, Ajuda, …) a partir do Painel de Administração; as páginas são apresentadas em URLs limpos `/pages/<slug>` e cada página pode ser traduzida numa versão ligada por idioma

---

## Modelos Disponíveis

| Modelo | ID | Parâmetros | Notas |
|---|---|---|---|
| **Flexy Beast** | `flexy_beast` | Todos os parâmetros antropométricos + ferragens das articulações flexíveis + almofadas de preensão + manga do antebraço | Totalmente paramétrico e autossuficiente — sem importações externas de STL |
| **UnLimbited Phoenix Hand V1.0** | `unlimbed_phoenix_hand` | Escala de impressão uniforme derivada de `palm_breadth_mm` (HandPerc da Team UnLimbited); seletor por peça | Malhas derivadas de STL; 8 peças imprimíveis (palma, dedos, falange, pinos, caixa/pinos de tensão, manga, gabarito) |
| **Paraglider Hand (Flexible Flyer)** | `paraglider_hand` | Todos os parâmetros antropométricos + escala por dedo + vistas montada/disposição de impressão + alternadores de peça `show_*` | Dedos paramétricos; a palma importa uma malha Phoenix v2 reparada como corpo base |
| **Variantes e acessórios Paraglider** | `paraglider_palm_v3`, `paraglider_palm_reborn_tensor`, `paraglider_palm_v3_tensor`, `paraglider_tensioner_box`, `paraglider_thermo_gauntlet`, `paraglider_unlimbited_arm` | Variantes de palma (Phoenix Reborn / UnLimbited v3, com tensor integrado), caixa de tensão, manga termoformável, braço acionado pelo cotovelo | Família remix Paraglider de Marcus Mendenhall; escala de impressão uniforme a partir do `palm_breadth_mm` canónico (o braço mantém o `HandLen` nativo em mm) |

---

## Requisitos

- **Node.js ≥ 22** — a base de dados usa o módulo nativo `node:sqlite`, pelo que não é preciso compilar nenhum módulo nativo
- Uma chave de API da Anthropic ou da OpenAI (para as sugestões de IA; a aplicação funciona sem ela, mas o botão de sugestões fica desativado)

---

## Começar

### 1. Instalar

```bash
git clone <repo>
cd ai-parametric-prosthetic-hand-generator
npm install
```

### 2. Configurar

```bash
cp .env.example .env
```

Edite o `.env`:

```env
JWT_SECRET=<execute: node -e "console.log(require('crypto').randomBytes(32).toString('hex'))">
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
PORT=3000
NODE_ENV=production
```

O `JWT_SECRET` é obrigatório — o servidor não arranca sem ele.

### 3. Arrancar

```bash
npm start          # produção
npm run dev        # desenvolvimento (reinício automático ao alterar ficheiros)
```

### 4. Configuração de primeira execução

Aceda a `http://localhost:3000`. A aplicação mostra um formulário de **Configuração Inicial** — crie a conta de administrador. Depois pode criar contas de técnico e de utilizador a partir do Painel de Administração.

**Alternativa por linha de comandos:**

```bash
node scripts/create-admin.js admin admin@example.com MyPassword123
```

---

## Implantação

A aplicação é um único processo Node.js que serve simultaneamente a API REST e o
frontend estático, pelo que implantar significa enviar a árvore de código-fonte
(sem segredos, sem a base de dados de desenvolvimento e sem `node_modules`) e
executar `npm ci` + `npm start` no servidor.

O `deploy.sh` automatiza isto em dois modos:

```bash
# Reúne todos os ficheiros destinados ao servidor em ./deploy/ (nada sai da máquina).
# Adicione --tar para produzir também deploy.tar.gz.
./deploy.sh collect --tar

# Reúne e, em seguida, sincroniza o pacote (rsync) para um servidor remoto.
# Adicione --delete para espelhar (remover ficheiros remotos obsoletos); --yes para não confirmar.
./deploy.sh deploy user@your-server.com:/opt/prosthetic-hand --delete
```

O pacote reunido **exclui** segredos (`.env`), a base SQLite de desenvolvimento
(`data/`), `node_modules`, `.git`, testes e ferramentas locais — uma verificação
de segurança pós-recolha aborta se algum destes escapar. O `.env.example` *é*
incluído como modelo.

No servidor, depois de os ficheiros chegarem:

```bash
cd /opt/prosthetic-hand
cp .env.example .env        # depois edite: JWT_SECRET + chaves de API
npm ci --omit=dev           # o bcrypt é um binário N-API pré-compilado; o SQLite vem com o Node — nada a compilar
node scripts/create-admin.js admin admin@example.com 'StrongPassword!'   # apenas na primeira execução
npm start                   # ou correr sob pm2 / systemd / Passenger
```

O site em produção corre em **cPanel + Phusion Passenger** (Node 24). O `deploy.sh`
tem um destino predefinido configurável, além de `--port`, `--dry-run` e uma cópia
de segurança remota antes de implantar. Veja [DEPLOY-QUICKSTART.md](DEPLOY-QUICKSTART.md)
para um guia passo a passo com pm2 + Nginx e [DEPLOYMENT.md](DEPLOYMENT.md) para o
guia completo de produção, incluindo o caminho **cPanel/Passenger** (Opção C),
systemd, TLS e cópias de segurança.

---

## Estrutura do Projeto

```
/
├── index.html                  Interface principal
├── auth.js                     Autenticação no frontend (token em memória, cookie de renovação)
├── app.js                      ParameterEditor — renderização, interface, guardar/carregar
├── admin.html / admin.js       Painel de administração (utilizadores, antropometria, rodapé e páginas)
├── anthropometric.js           Janela do importador antropométrico (admin)
├── openscad-worker.js          Worker de renderização WASM
├── page.html                   Visualizador público de páginas de conteúdo Markdown (/pages/<slug>)
├── i18n.js / translations.js   Núcleo de i18n leve + dicionários EN/PT
├── footer.js                   Renderiza o rodapé editável a partir da API
├── markdown.js                 Pequeno renderizador seguro de Markdown → HTML
│
├── models/
│   ├── models-config.json                  Registo de modelos + especificações de parâmetros (com traduções _pt)
│   └── active/
│       ├── flexy_beast/                     Flexy Beast — SCAD paramétrico autossuficiente
│       ├── unlimbed_phoenix_hand/           UnLimbited Phoenix Hand — derivado de STL, exportação por peça
│       ├── paraglider_hand/                 Paraglider Hand — SCAD paramétrico + malha base da palma
│       └── paraglider/                      Variantes e acessórios Paraglider (palmas, tensor, manga, braço)
│
├── docs/                           Notas dos modelos + validação antropométrica
│
├── data/                          (ignorado pelo git — criado/fornecido localmente, não está no repositório)
│   ├── app.db                      Base de dados SQLite (criada automaticamente na primeira execução)
│   └── multi_population_hand.csv   Medidas de mãos populacionais (~96 grupos; fornecer à parte)
│
├── server/
│   ├── index.js                Ponto de entrada do servidor Express
│   ├── db.js                   Ligação node:sqlite (migra automaticamente)
│   ├── schema.sql              Esquema da base de dados
│   ├── middleware/             auth.js, errorHandler.js
│   ├── routes/                 setup, auth, users, configs, ai, anthropometric, content
│   └── services/              authService.js, aiService.js, anthropometricImporter.js
│
├── scripts/
│   ├── create-admin.js         Criação de administrador por linha de comandos
│   └── seed-content.js         Semear/atualizar o rodapé + páginas de conteúdo
│
├── CLAUDE.md                   Guia do programador para o Claude Code
├── CHANGELOG.md                Histórico de versões
├── .env.example                Modelo de ambiente
└── package.json
```

---

## Funções de Utilizador

| Função | Capacidades |
|---|---|
| **admin** | Acesso total: gerir utilizadores, ver todas as configurações, atribuições de técnicos, editor de código SCAD |
| **tech** | Configurações próprias + leitura/escrita das configurações dos pacientes atribuídos |
| **user** | Apenas as suas próprias configurações guardadas |

---

## Parâmetros Antropométricos

Todos os modelos que suportam o preenchimento automático a partir dos perfis dos pacientes usam estes nomes de parâmetros canónicos:

| Parâmetro | Medida | Intervalo típico (adulto) |
|---|---|---|
| `palm_breadth_mm` | Largura metacarpal de nó a nó | 70–100 mm |
| `palm_length_mm` | Base do pulso até à linha dos nós MCP | 90–120 mm |
| `palm_thickness_mm` | Superfície palmar à dorsal | 22–38 mm |
| `middle_finger_length_mm` | Prega MCP à ponta do dedo médio | 60–100 mm |
| `thumb_length_mm` | Prega MCP do polegar à ponta | 45–80 mm |
| `gauntlet_width_mm` | Largura do encaixe do antebraço (≈ perímetro do pulso / π) | 40–90 mm |

Estes nomes têm de coincidir exatamente nos ficheiros `.scad` e em `models-config.json` para que os perfis dos pacientes importados de CSV preencham automaticamente os campos corretos.

### Importar o conjunto de dados populacional

O CSV do conjunto de dados **não vem incluído no repositório** (`data/` é ignorado pelo git). Obtenha
o `multi_population_hand.csv` à parte e coloque-o em qualquer pasta da sua máquina primeiro.

1. Inicie sessão como administrador → abra o **Painel de Administração**
2. Vá ao separador **Perfis Antropométricos**
3. Clique em **⬆ Importar Conjunto de Dados CSV** — o navegador abre um seletor de ficheiros. Navegue até onde
   guardou o `multi_population_hand.csv` (neste projeto está em `data/`) e selecione-o. O
   ficheiro é lido localmente no navegador e o seu conteúdo é enviado; a aplicação não o procura
   por caminho.
4. Uma confirmação indica quantos perfis foram criados (reimportar é seguro — os grupos duplicados
   são ignorados)

> O CSV tem de cumprir o esquema de importação em lote (colunas `measurement_name`, `population`,
> `country`, `sex`, `age_group`, `stat_type`, `value_mm`, …); apenas as linhas `mean` são importadas.
> Veja o Apêndice C de [docs/ai_anthropometric_validation.md](docs/ai_anthropometric_validation.md)
> para o pipeline completo.

---

## Adicionar um Modelo

1. Coloque o ficheiro `.scad` em `models/`
2. Adicione uma entrada em `models/models-config.json`:

```json
{
  "id": "my_model",
  "name": "My Prosthetic Model",
  "description": "...",
  "file": "my_model.scad",
  "parameters": [
    {
      "name": "palm_breadth_mm",
      "type": "number",
      "initial": 83,
      "min": 55,
      "max": 110,
      "step": 1,
      "caption": "Knuckle-to-knuckle palm breadth (mm)",
      "group": "Anthropometric"
    }
  ]
}
```

3. Reinicie o servidor — o modelo aparece imediatamente na lista pendente.

**Tipos de parâmetros:**

| Tipo | Controlo | Notas |
|---|---|---|
| `number` com `min`/`max` | Cursor (slider) | |
| `number` sem `min`/`max` | Campo numérico | |
| `boolean` | Caixa de seleção | |
| `string` | Campo de texto | |

Se o modelo referenciar ficheiros STL externos através de `import()` ou `use<>`, liste-os em `dependencies`:

```json
"dependencies": [
  { "url": "subdir/part.stl", "path": "part.stl" }
]
```

O `url` é relativo a `models/` no servidor; `path` é onde o ficheiro fica no sistema de ficheiros virtual do WASM (tem de ser plano — sem subdiretórios).

---

## Visão Geral da API

| Endpoint | Descrição |
|---|---|
| `GET /api/setup/status` | Verificação de primeira execução |
| `POST /api/setup/admin` | Criar o primeiro administrador |
| `POST /api/auth/login` | Iniciar sessão |
| `POST /api/auth/register` | Auto-registo |
| `POST /api/auth/refresh` | Rotação de tokens via cookie |
| `POST /api/auth/logout` | Revogar o token de renovação |
| `GET /api/users` | Listar utilizadores (admin) |
| `POST /api/users` | Criar utilizador (admin) |
| `GET /api/configurations` | Listar configurações acessíveis |
| `POST /api/configurations` | Guardar configuração |
| `PUT /api/configurations/:id` | Atualizar configuração |
| `DELETE /api/configurations/:id` | Eliminar configuração |
| `POST /api/ai/suggest` | Proxy de sugestão de parâmetros por IA |
| `GET /api/anthropometric` | Listar perfis antropométricos (admin) |
| `POST /api/anthropometric` | Criar perfil a partir de manual/CSV/JSON (admin) |
| `POST /api/anthropometric/import-csv-bulk` | Importar CSV populacional em lote (admin) |
| `GET /api/anthropometric/:id` | Obter perfil com parâmetros geométricos derivados |
| `PUT /api/anthropometric/:id` | Atualizar perfil |
| `DELETE /api/anthropometric/:id` | Eliminar perfil |
| `GET /api/content/footer` · `PUT` | Ler configuração do rodapé (público) / guardar (admin) |
| `GET /api/content/pages/:slug?lang=` | Página de conteúdo pública, sensível ao idioma |
| `POST/PUT/DELETE /api/content/pages` | Gerir páginas de conteúdo (admin) |
| `POST /api/content/pages/:id/translate` | Criar uma tradução ligada de uma página (admin) |

**Limites de taxa:** início de sessão 5/15 min · registo 3/h · sugestões de IA 10/min · todos os outros 500/15 min

---

## Segurança

- Palavras-passe protegidas com bcrypt (custo 12)
- Tokens de acesso JWT: validade de 15 minutos, guardados apenas em memória JS (nunca em localStorage)
- Tokens de renovação: validade de 7 dias, guardados como hashes SHA-256, rodados a cada utilização
- `/.env` e `/config.json` devolvem 404 — bloqueados antes do middleware estático
- Todos os corpos dos pedidos validados com Zod
- Cabeçalhos CSP via Helmet
- As chaves de API de IA nunca saem do servidor

---

## Referência de Configuração

| Variável | Obrigatória | Descrição |
|---|---|---|
| `JWT_SECRET` | Sim | Cadeia hexadecimal de 64 caracteres para assinar JWT |
| `ANTHROPIC_API_KEY` | Para IA | Chave de API do Claude |
| `OPENAI_API_KEY` | Para IA | Chave de API da OpenAI |
| `PORT` | Não | Porta HTTP (predefinição: 3000) |
| `NODE_ENV` | Não | `development` ou `production` |

---

## Redefinir Palavra-passe (linha de comandos)

```bash
node -e "
const db = require('./server/db');
const bcrypt = require('bcrypt');
const hash = bcrypt.hashSync('newpassword', 12);
db.prepare('UPDATE users SET password_hash = ? WHERE username = ?').run(hash, 'admin');
console.log('done');
"
```

---

## Créditos

- [OpenSCAD Playground](https://github.com/openscad/openscad-playground) — ambiente de execução de renderização WASM
- [OpenSCAD](https://openscad.org/) — linguagem de modelação 3D paramétrica
- [Flexy Beast](https://www.thingiverse.com/thing:380665) por daprice — uma mistura do Parametric Cyborg Beast com a Flexy Hand
- [Team UnLimbited](https://www.thingiverse.com/thing:1672381) — desenhos UnLimbited Arm / Phoenix Hand
- [e-NABLE](https://enablingthefuture.org) — desenhos de mãos protésicas de código aberto (linhagem Phoenix / Unlimbited por detrás da Paraglider Hand)
