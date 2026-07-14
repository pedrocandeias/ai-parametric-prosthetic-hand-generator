'use strict';

// Explicit list of WCAG 2.2 AA checks that automated tooling CANNOT decide and
// that require human verification (protocol §6.5). Automated axe-core coverage
// is necessary but not sufficient — an audit with zero violations does NOT
// authorise a global conformance claim. This checklist is emitted verbatim into
// every accessibility campaign so the manual work is traceable.

const CHECKLIST = {
    title: 'Verificações manuais de acessibilidade (WCAG 2.2 AA) — não resolúveis por automação',
    generated_note: 'Uma auditoria automática sem violações NÃO autoriza declaração de conformidade global.',
    items: [
        { id: 'MAN-KEYBOARD', criterion: '2.1.1 Keyboard / 2.1.2 No Keyboard Trap', check: 'Percorrer autenticação, dashboard, selecção/configuração de modelo, sugestão de IA, render e exportação usando APENAS teclado. Todas as operações essenciais alcançáveis, accionáveis e reversíveis; sem armadilhas de foco.', result: 'inconclusivo (manual)' },
        { id: 'MAN-FOCUS-VISIBLE', criterion: '2.4.7 Focus Visible / 2.4.11 Focus Not Obscured', check: 'O indicador de foco é sempre visível e não fica escondido por cabeçalhos fixos, modais ou o visualizador 3D.', result: 'inconclusivo (manual)' },
        { id: 'MAN-FOCUS-ORDER', criterion: '2.4.3 Focus Order', check: 'A ordem de tabulação segue uma sequência lógica em cada ecrã e dentro dos modais (login, exportação).', result: 'inconclusivo (manual)' },
        { id: 'MAN-NAMES', criterion: '4.1.2 Name, Role, Value / 1.3.1 Info and Relationships', check: 'Cada controlo paramétrico (slider, select, cor) e cada campo de formulário tem um nome acessível programático e rótulo associado; o leitor de ecrã anuncia função e valor.', result: 'inconclusivo (manual)' },
        { id: 'MAN-ERRORS', criterion: '3.3.1 Error Identification / 3.3.3 Error Suggestion', check: 'Erros de autenticação, perfil e exportação são identificados por texto (não só por cor) e associados ao campo; instruções de correcção presentes.', result: 'inconclusivo (manual)' },
        { id: 'MAN-STATUS', criterion: '4.1.3 Status Messages', check: 'Mensagens dinâmicas — "A renderizar…", "Sugestões aplicadas", "Erro de renderização", estado da exportação — são anunciadas por tecnologia assistiva (role=status/aria-live) sem mover o foco.', result: 'inconclusivo (manual)' },
        { id: 'MAN-CONTRAST', criterion: '1.4.3 Contrast (Minimum) / 1.4.1 Use of Color', check: 'Contraste ≥ 4.5:1 (texto) e 3:1 (componentes/estados de foco); nenhuma informação depende exclusivamente da cor (ex.: estado de sucesso/erro do status).', result: 'inconclusivo (manual)' },
        { id: 'MAN-REFLOW', criterion: '1.4.10 Reflow / 1.4.4 Resize Text', check: 'A 400% de ampliação e a 320 CSS px de largura não há perda de conteúdo ou funcionalidade essencial; sem scroll bidireccional para conteúdo linear.', result: 'inconclusivo (manual)' },
        { id: 'MAN-TARGET', criterion: '2.5.8 Target Size (Minimum)', check: 'Alvos interactivos ≥ 24×24 CSS px (ou com espaçamento equivalente): swatches de cor, ícones de ajuda, checkboxes de exportação.', result: 'inconclusivo (manual)' },
        { id: 'MAN-AUTH', criterion: '3.3.8 Accessible Authentication (Minimum)', check: 'A autenticação não exige um teste cognitivo sem alternativa; permite colar a palavra-passe e o uso de gestores de palavras-passe.', result: 'inconclusivo (manual)' },
        { id: 'MAN-3D-ALT', criterion: '1.1.1 Non-text Content / 1.3.1', check: 'O visualizador 3D e os estados exclusivamente visuais têm alternativa: os parâmetros, o estado e as operações essenciais são obtíveis sem depender da imagem renderizada (valores nos controlos, texto de estado).', result: 'inconclusivo (manual)' },
        { id: 'MAN-SR', criterion: 'Exploratory screen-reader pass', check: 'Percurso exploratório com leitor de ecrã (NVDA/VoiceOver/Orca): nomes, funções, estados e alterações compreensíveis ponta-a-ponta.', result: 'inconclusivo (manual)' },
    ],
};

module.exports = { CHECKLIST };
