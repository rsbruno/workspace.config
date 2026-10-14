# E2E com Playwright e integração de rotas e componentes

## 6. E2E com Playwright

E2E deve provar jornadas que atravessam navegador, router, sessão, guards, API e atualização da tela:

- criação válida e payload persistido;
- edição válida e valores existentes carregados;
- listagem com busca, filtro e paginação relevantes;
- arquivamento, restauração e exclusão, incluindo a mudança de estado exibida na listagem;
- navegação da linha, command palette e ações da toolbar quando existirem;
- fallback de erro ou not-found quando houver uma jornada reproduzível;
- bloqueio de feature ou permissão quando houver uma sessão/fixture que permita provar a tela negada.

Não dependa de dados fixos compartilhados entre testes. Crie entidades identificáveis, use nomes únicos, espere a hidratação pela UI e limpe tudo em `afterEach` ou `afterAll`. A limpeza deve tolerar recurso já removido e registrar falha de cleanup sem esconder o resultado principal.

Use as respostas HTTP reais como evidência quando a ação for relevante, mas também verifique o resultado visível após a resposta. Uma resposta `200` sozinha não prova que a tela atualizou corretamente.

## 7. Integração de rotas e componentes

Para cada tela CRUD, crie somente os arquivos que correspondem aos cenários existentes, mas cubra todos os branches implementados.

### Listagem

Cubra:

- feature e permission guard da rota;
- `Can` do botão de criar;
- `TableRowLink` com e sem a permissão exigida;
- coluna de ações com `can` ou `canAny`;
- cada lado de um `canAny` isoladamente, além do caso sem nenhuma policy;
- cada `<Can>` interno de cada item do popover;
- busca, cada filtro, combinação de filtros, limpar filtros e parâmetros enviados;
- dados de linha, status, empty state e paginação nos dois limites;
- `pendingComponent`, `isPending`, `isFetching` e fallback sem desmontar a tabela durante refetch;
- command palette e ações de navegação relacionadas à tela.

### Criar e editar

Cubra:

- feature e permission guard da rota;
- hidratação e fallback antes de montar o formulário;
- renderização dos valores iniciais na edição;
- `Can` do submit;
- preenchimento válido e payload final enviado ao serviço;
- cada regra de validação relevante;
- campos assíncronos mostrando `pending` durante consulta, sem transformar uma espera localizada em skeleton de tela;
- sucesso, toast, invalidação e navegação;
- erro customizado quando existir no código;
- 404/not-found e error boundary quando houver uma forma prática de montá-los.

### Componentes

Cada componente com comportamento próprio tem testes de integração isolados:

- row-actions: trigger, clique que não navega pela linha, estado ativo/arquivado, todas as policies, variantes `warning`/`info`/`danger`, diálogos, pending e mutations;
- dialogs: abertura, conteúdo, cancelamento, confirmação e pending;
- filters: todos os campos e valores enviados;
- badges: cada estado, label e variante;
- command palette: ações, busca, permissões e destino;
- fallbacks: presença e estrutura essencial quando o carregamento inicial exigir.
