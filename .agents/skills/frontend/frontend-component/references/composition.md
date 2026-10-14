# How to share state between parts

Context is the **last resort**, not the default — any change to the Provider's `value` re-renders every consumer, even one that only reads one field. Order of preference:

1. **`Children` + `cloneElement`** — when the parts are direct children of the Root. Preferred pattern for most cases (simple Tabs, single-item Accordion, Radio Group).
2. **Local state + callback props** — when only two parts talk to each other (Trigger and Content) and the Root can pass `onOpenChange`/`open` straight to the children it renders.
3. **Context** — only when (1) and (2) aren't technically viable (parts at any nesting level, many decoupled consumers) or when the user explicitly asks for Context.

## `cloneElement` template (preferred)

```tsx
// component-name-root.tsx
import { useState, useMemo, Children, isValidElement, cloneElement, type ComponentProps } from "react";
import { Slot } from "@radix-ui/react-slot";

interface ComponentNameChildProps {
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
}

interface ComponentNameRootProps extends ComponentProps<"div"> {
  asChild?: boolean;
}

function ComponentNameRoot({ asChild, children, ref, ...props }: ComponentNameRootProps) {
  const [open, setOpen] = useState(false);

  const childrenWithProps = useMemo(
    () =>
      Children.map(children, (child) => {
        if (!isValidElement<ComponentNameChildProps>(child)) return child;
        return cloneElement(child, { open, onOpenChange: setOpen });
      }),
    [children, open]
  );

  const Comp = asChild ? Slot : "div";

  return (
    <Comp ref={ref} {...props}>
      {childrenWithProps}
    </Comp>
  );
}
ComponentNameRoot.displayName = "ComponentNameRoot";

export { ComponentNameRoot };
export type { ComponentNameRootProps };
```

`isValidElement<ComponentNameChildProps>(child)` types `child` without a cast — never `as Partial<unknown>`/`as never`.

## Context template (only when justified)

`context.ts`:

```tsx
import { createContext, useContext } from "react";

interface ComponentNameState {
  open: boolean;
}

interface ComponentNameContextValue {
  state: ComponentNameState;
  onChange: (next: ComponentNameState) => void;
}

const ComponentNameContext = createContext<ComponentNameContextValue | null>(null);

function useComponentNameContext(consumerName: string): ComponentNameContextValue {
  const context = useContext(ComponentNameContext);
  if (!context) {
    throw new Error(`\`${consumerName}\` must be used within \`ComponentNameRoot\``);
  }
  return context;
}

export { ComponentNameContext, useComponentNameContext };
export type { ComponentNameContextValue, ComponentNameState };
```

The hook takes `consumerName` (name of the caller) to point the error at the exact wrong subcomponent.

`component-name-root.tsx` with Context:

```tsx
import { useState, useCallback, useMemo, type ComponentProps } from "react";
import { Slot } from "@radix-ui/react-slot";
import { ComponentNameContext } from "./context";
import type { ComponentNameContextValue, ComponentNameState } from "./context";

interface ComponentNameRootProps extends ComponentProps<"div"> {
  defaultState?: ComponentNameState;
  asChild?: boolean;
}

function ComponentNameRoot({ asChild, defaultState, children, ref, ...props }: ComponentNameRootProps) {
  const [state, setState] = useState<ComponentNameState>(() => defaultState ?? { open: false });

  const handleChange = useCallback((next: ComponentNameState) => {
    setState(next);
  }, []);

  const contextValue: ComponentNameContextValue = useMemo(
    () => ({ state, onChange: handleChange }),
    [state, handleChange]
  );

  const Comp = asChild ? Slot : "div";

  return (
    <ComponentNameContext.Provider value={contextValue}>
      <Comp ref={ref} {...props}>
        {children}
      </Comp>
    </ComponentNameContext.Provider>
  );
}
ComponentNameRoot.displayName = "ComponentNameRoot";

export { ComponentNameRoot };
export type { ComponentNameRootProps };
```

`component-name-trigger.tsx` (with `asChild` + `Slot`):

```tsx
import { memo, type ComponentProps } from "react";
import { Slot } from "@radix-ui/react-slot";
import { useComponentNameContext } from "./context";

interface ComponentNameTriggerProps extends ComponentProps<"button"> {
  asChild?: boolean;
}

const ComponentNameTrigger = memo(({ asChild, ref, ...props }: ComponentNameTriggerProps) => {
  const context = useComponentNameContext("ComponentNameTrigger");
  const Comp = asChild ? Slot : "button";

  return <Comp ref={ref} type="button" data-state={context.open ? "open" : "closed"} {...props} />;
});
ComponentNameTrigger.displayName = "ComponentNameTrigger";

export { ComponentNameTrigger };
export type { ComponentNameTriggerProps };
```

`data-state` (not conditional className) is the pattern to expose visual state to CSS.

## TanStack Query data never travels through Context

If any part fetches async data via `useApiQuery`/`useQuery`, that data (response, `isLoading`, `isFetching`) **never** enters the Context's `value` nor gets redrilled through props from the Root. TanStack Query's cache is already the sharing mechanism — each part that needs the data calls the **same** `queryOptions` directly (same `queryKey` = cache hit, no extra request).

```tsx
// WRONG — Root fetches and pushes through Context
function ComponentNameRoot({ children }: ComponentNameRootProps) {
  const query = useApiQuery(someQueryOptions);
  const contextValue = useMemo(() => ({ data: query.data, isLoading: query.isLoading }), [query.data, query.isLoading]);
  return <ComponentNameContext.Provider value={contextValue}>{children}</ComponentNameContext.Provider>;
}

// RIGHT — each part fetches on its own
function ComponentNameList() {
  const { data, isLoading } = useApiQuery(someQueryOptions);
}
```

Consequence: if the only thing the parts would "share" is server data, and each can already fetch it on its own, there's no reason for Context to exist. Before creating `context.ts`, ask: what's left to share once query data is out of the equation? If the answer is "nothing", skip Context.

## Minimal prop drilling

Every component receives only the minimum props — what it can't decide/fetch on its own (callback, `open`/`onOpenChange`, id coming from the URL). Server data (or something derived from it, already cached) is fetched by the part itself, never received pre-computed from whoever assembles the tree.

```tsx
// WRONG
function DeliveryPage() {
  const { data: order } = useApiQuery(findOrderByIdQueryOptions(orderId));
  const { data: addresses } = useApiQuery(findAllAddressesQueryOptions);
  const selectedAddress = addresses?.find((item) => item.id === order?.shipping?.addressId);
  return <SelectedAddressCard address={selectedAddress} onChangeAddress={openPicker} />;
}

// RIGHT — the part fetches on its own (cache hit, zero extra cost)
function DeliveryPage() {
  return <SelectedAddressCard onChangeAddress={openPicker} />;
}
function SelectedAddressCard({ onChangeAddress }: SelectedAddressCardProps) {
  const { id: orderId } = useParams({ from: "/(publicas)/pedido/$id" });
  const { data: order } = useApiQuery(findOrderByIdQueryOptions(orderId));
  const { data: addresses } = useApiQuery(findAllAddressesQueryOptions);
  const address = addresses?.find((item) => item.id === order?.shipping?.addressId);
}
```

## Multiple modals: one `useDisclosure()` per modal

When a screen/component coordinates 2+ modals, each modal has its own `useDisclosure()` instance (`@/hooks/use-disclosure`) — never a single instance with `data` like `useDisclosure<"picker" | "form">()` comparing a string. Props are destructured and renamed with the modal's name:

```tsx
// WRONG
const modal = useDisclosure<"picker" | "form">();
<AddressPickerModal open={modal.open && modal.data === "picker"} onOpenChange={modal.onOpenChange} />

// RIGHT
const { onOpen: onOpenPicker, onOpenChange: onOpenChangePicker, open: openPicker } = useDisclosure();
const { onOpen: onOpenForm, onOpenChange: onOpenChangeForm, open: openForm } = useDisclosure();
<AddressPickerModal open={openPicker} onOpenChange={onOpenChangePicker} />
<AddressFormModal open={openForm} onOpenChange={onOpenChangeForm} />
```

Transitioning between modals (e.g. picker → form) is an explicit call of both instances: `onClosePicker(); onOpenForm();` — never a `data` change.
