# Rodapé, pular step, mutation, locale

## Rodapé do step

Todo step usa `PageFormFooter` + `StepperFooterSummary`:

```tsx
<PageFormFooter data-testid="site-create-footer">
  <StepperFooterSummary hint={t("footer.general.hint")} />
  <Can permissions={[Policies.Agribusiness.Sites.Create]}>
    <Button ... />
  </Can>
</PageFormFooter>
```

Props de `StepperFooterSummary`: `hint` (obrigatória), `hintSize` (`"xs"`), `hintColor` (`"500"`), mais as de `PageFormFooterSummary` sem `children`. Contador e tipografia não são montados à mão.

Ações do rodapé seguem as regras globais: nunca botão Cancelar, ícone semântico por ação, `<Can>` em tudo que muta, `data-testid` por botão.

## Pular step opcional

Botão `Pular` nunca navega direto. Abre um dialog de confirmação dedicado que explica a consequência de pular; só o `onConfirm` do dialog conclui a saída.

- Arquivo: `_components/dialogs/skip-<entidade>-<step>-confirmation.tsx`, seguindo `frontend-page` → `references/dialogs-layout.md` (sem estado, sem mutation, sem `index.ts`).
- Variante sempre `info`, ícone `SkipForwardIcon`, botão cancelar com `XIcon`.
- Props: `open`, `onOpenChange`, `onConfirm`, `data-testid` opcional.
- Estado de abertura no step via `useDisclosure` (`onOpen` no botão, `setOpen` no `onOpenChange`).
- Locale em `<entidade>.confirm.skip-<step>` com `title`, `description`, `confirm`, `cancel`. A consequência vem do requisito na documentação, nunca inventada; sem requisito, perguntar.

## Mutation e navegação entre steps

- Step que cria a entidade: no `onSuccess`, toast, invalidate das queries e `navigate({ to, search: { step: "<próximo>", <id>: id }, replace: true })`.
- Mutation com `toast.dispatch` custom exige `meta: { ignoreError: true }`; sem `onError` custom o toast de erro é automático.
- Step final navega para a listagem (`Concluir`) e pode ter `Pular` com `appearance="ghost"`.

## Locale

Chaves por step, na árvore da tela (`frontend-locale` manda no formato):

```
<entidade>.create.steps.<step>.label
<entidade>.create.steps.<step>.description
<entidade>.create.footer.<step>.<chave>
```

A rota usa `t(\`steps.${name}.label\`)`; nunca string visível no JSX.
