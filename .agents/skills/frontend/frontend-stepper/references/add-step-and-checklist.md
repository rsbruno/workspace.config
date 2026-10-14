# Fallback, adicionar step, checklist, encadeamento

## Fallback

Um fallback por step, em `_components/fallbacks/`, usado no `Suspense` do step na rota e no `isLoading` do próprio step. Espelha o step carregado, inclusive o footer (`frontend-fallback`).

## Adicionar step em tela existente

1. Nome em `<entidade>StepNames` (a posição define a ordem).
2. Pasta `_steps/<nome>/index.tsx` (default export, mesmas props dos outros steps).
3. Fallback em `_components/fallbacks/`.
4. `lazy` do step no topo da rota `criar` e novo ramo de renderização com `Suspense` e guard inline.
5. Chaves de locale `steps.<nome>.*` e `footer.<nome>.*`.
6. Ajustar `footer`/navegação do step anterior para apontar para o novo.
7. Se a edição tem abas e o conteúdo vale lá: nome em `<entidade>TabNames`, `lazy` da aba e `TabsTrigger`/`TabsContent` na rota de edição.

## Checklist

1. Nenhum arquivo de registro/lista de steps ou abas, nenhum `resolve…StepIndex`?
2. `lazy` de cada step/aba declarado na própria rota?
3. Nomes dos steps vivem só no schema; a rota deriva dele?
4. Guard de acesso inline e primeiro step sempre acessível?
5. Rodapé usa `StepperFooterSummary`?
6. Locale por `name`, sem literal no JSX?
7. Fallback de step e de aba são arquivos distintos?
8. Sem comentários, sem `any`, `Strings.EMPTY` no lugar de `""`?
9. `data-testid` em stepper, itens e botões?
10. `Pular` abre dialog `info` de confirmação, sem navegar direto?
11. Encadeamento feito (abaixo)?

## Encadeamento

`frontend-stepper` pronto → `frontend-form` (campos do step), `frontend-fallback` (fallback de cada step), `frontend-locale` (chaves de `steps`/`footer`), command palette da tela se criou rota nova. Componente de stepper novo ou alteração em `ui/stepper` segue `frontend-component`.
