# Estrutura, schema, rota de criação e edição com abas

## Estrutura

```
<entidades>/
  criar/index.tsx                       → rota do wizard, com os lazy dos steps
  _schemas/create-search.schema.ts      → <entidade>StepNames + search schema
  _steps/
    <step>/index.tsx                    → um step, default export
  _components/fallbacks/<entidade>-<step>-step-fallback.tsx
```

Edição com abas (opcional, só se a rota de edição tem abas):

```
  editar/$id/index.tsx                  → rota com os lazy das abas
  _schemas/edit-tab.schema.ts           → <entidade>TabNames
  _tabs/
    <aba>/index.tsx
  _components/fallbacks/<entidade>-<aba>-tab-fallback.tsx
```

`_steps` e `_tabs` ficam separados: step cria/avança e navega, aba só edita. Fallback de step e de aba são arquivos distintos (o step tem o footer do stepper, a aba tem o footer de salvar). Não unificar.

## Schema (nomes são a fonte única)

```ts
import * as z from "zod";

export const siteStepNames = ["general", "products"] as const;

export type SiteStepName = (typeof siteStepNames)[number];

export const createSearchSchema = z.object({
  step: z.enum(siteStepNames).optional(),
  siteId: z.string().optional()
});
```

O id da entidade criada no step 1 trafega na search (`siteId`), nunca em estado local.

## Rota de criação

```tsx
const SiteGeneralStep = lazy(() => import("../_steps/general"));
const SiteProductsStep = lazy(() => import("../_steps/products"));

const activeIndex = stepName === "products" && siteId ? 1 : 0;

const steps = useMemo<StepperRootStep[]>(
  () =>
    siteStepNames.map((name) => ({
      description: t(`steps.${name}.description`),
      "data-testid": `site-create-step-${name}`,
      label: t(`steps.${name}.label`)
    })),
  [t]
);

function handleStepChange(index: number) {
  navigate({ search: (previous) => ({ ...previous, step: siteStepNames[index] }), replace: true });
}

<StepperRoot
  className="mx-auto max-w-2xl px-3 py-8"
  onValueChange={handleStepChange}
  data-testid="site-create-stepper"
  value={activeIndex}
  steps={steps}
>
  <PageFormRoot>
    <PageFormContent>
      <If condition={activeIndex === 0}>
        <Then>
          <Suspense fallback={<SiteGeneralStepFallback />}>
            <SiteGeneralStep siteId={siteId} />
          </Suspense>
        </Then>
        <Else>
          <Suspense fallback={<SiteProductsStepFallback />}>
            <SiteProductsStep siteId={siteId} />
          </Suspense>
        </Else>
      </If>
    </PageFormContent>
  </PageFormRoot>
</StepperRoot>
```

- Os nomes vêm de `<entidade>StepNames` (schema); a ordem do array é a ordem do stepper e o índice dos steps.
- Guard de acesso é inline na rota: step que depende do id criado só abre com o id na search (`stepName === "products" && siteId`); sem o id volta para o primeiro.
- Todo step recebe as mesmas props; prop que só alguns usam é opcional e o step trata o default com `Strings.EMPTY`.
- Ordem de hooks: `useMemo` antes do `if (!isHydrated) return <Fallback />`.
- `StepperRoot` aceita `steps: StepperRootStep[]` (`label`, `description`, `data-testid`); `children` é só o conteúdo extra.
- Step só é clicável quando já concluído; `navigate` sempre com `replace: true`.
- Rota segue `frontend-page`: `beforeLoad: require(...)`, `validateSearch: createSearchSchema`, `pendingComponent`, `errorComponent: ErrorBoundary`, `usePageTitle`, guard de hidratação.

## Rota de edição com abas

Cada aba tem seu `lazy` no topo, seu `TabsTrigger` e seu `TabsContent` com `Suspense` e fallback próprio, escritos um a um na rota. Sem `ForEach` sobre lista de abas.
