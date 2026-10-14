# Variants and slots

Only applies when the family has its own variant (`size`/`align`/`variant`/etc). **Variant is only a public prop on the Root.** Never redeclared on children — the child reads the already-resolved result from Context (concrete case of "many decoupled consumers", where Context stops being the exception and becomes the default path).

A family with a variant has **one single** `tv({ slots, variants })` (`tailwind-variants`, already used in `button.tsx`/`section-heading/root.tsx`) in `styles.ts` — never one `tv()` per file, never a loose `twMerge` competing with the variant.

## `styles.ts`

```tsx
import { type VariantProps, tv } from "tailwind-variants";

const componentNameVariants = tv({
  slots: {
    root: "base classes for Root here",
    trigger: "base classes for Trigger here",
    content: "base classes for Content here",
  },
  variants: {
    size: {
      sm: { root: "...", trigger: "...", content: "..." },
      lg: { root: "...", trigger: "...", content: "..." },
    },
  },
  defaultVariants: { size: "sm" },
});

type ComponentNameVariantProps = VariantProps<typeof componentNameVariants>;

export { componentNameVariants };
export type { ComponentNameVariantProps };
```

## `context.ts` with slots

```tsx
import { createContext, useContext } from "react";
import { componentNameVariants } from "./styles";

interface ComponentNameContextValue {
  slots: ReturnType<typeof componentNameVariants>;
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
export type { ComponentNameContextValue };
```

## Root resolves, child only consumes

```tsx
// component-name-root.tsx
function ComponentNameRoot({ className, size, children, ref, ...props }: ComponentNameRootProps) {
  const slots = useMemo(() => componentNameVariants({ size }), [size]);
  const contextValue = useMemo(() => ({ slots }), [slots]);

  return (
    <ComponentNameContext.Provider value={contextValue}>
      <div className={slots.root({ className })} ref={ref} {...props}>
        {children}
      </div>
    </ComponentNameContext.Provider>
  );
}

// component-name-trigger.tsx — doesn't receive `size`, grabs the resolved slot from Context
function ComponentNameTrigger({ className, ref, ...props }: ComponentNameTriggerProps) {
  const { slots } = useComponentNameContext("ComponentNameTrigger");
  return <button className={slots.trigger({ className })} ref={ref} {...props} />;
}
```

`className` remains the only way the consumer adjusts local style — `slots.trigger({ className })` already merges it with the base + resolved variant, no `twMerge` needed on top.
