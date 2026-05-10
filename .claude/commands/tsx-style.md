---
description: Reformat TSX files to match project code style conventions
argument-hint: "[file or directory]"
allowed-tools: Read, Edit, Bash
---

# TSX Style

Refactor a TSX file to conform to strict structural and style conventions.

## When This Skill Applies

Activate when the user asks to clean, refactor, or enforce style on a React component (TSX file). The user will typically reference a file path or have a file open in the editor.

## Steps

1. Read the target TSX file.
2. Apply every rule below — no partial compliance.
3. Write the result back to the file.
4. Report only what was changed and why (no trailing summaries).

## Rules

### File structure
- **One component per file.** Any helper components defined in the same file must be extracted to their own files. Import them where needed.
- **No local components.** Any other components must be extracted in separate TSX files, each component in separate file.
- **Utility functions** (pure logic, no JSX) must be moved to a separate utility file (e.g. `utils/<name>.ts`) and imported.

### Component declaration
- The component **must be declared as a `const` typed `React.FC<Props>`**:
  ```tsx
  const MyComponent: React.FC<Props> = (props) => { … };
  export default MyComponent;
  ```
- **`export default` must be on a separate line** at the bottom of the file — never inline on the declaration.
- Always use `props` as the parameter name in the function signature; **destructure inside the body**:
  ```tsx
  const MyComponent: React.FC<Props> = (props) => {
    const { name, value, onChange } = props;
    …
  };
  ```

### Event handlers
- **One-liners**: keep inline in JSX (e.g. `onClick={() => setValue(x)}`).
- **Multi-line**: extract above the `return`, named with a `handle` prefix (e.g. `handleSubmit`).

### Template cleanliness
- The JSX `return` block must stay **maximum clean**. Allowed expressions: ternary (`? :`), logical (`&&`, `||`), and `.map()`. No other JS expressions in JSX.
- **Array `.map()` callbacks must be inline with an implicit return** — no `return` keyword, no wrapping `{}` block:
  ```tsx
  {items.map((item) => <Item key={item.id} {...item} />)}
  ```
- If the array needs transformation before rendering, derive it with `useMemo` in the component body and map the memoised value in JSX.
- **Inside `.map()`, only JSX is allowed** — no creating constants, no JS expressions beyond prop passing.

### Iteration
- **Never use `for...of` loops.** Replace with the appropriate array method:
    - Transformation → `.map()`
    - Side effects → `.forEach()`
    - Accumulation → `.reduce()`
    - Filtering + mapping → `.filter().map()` or `.reduce()`

### Function length
- **Any function or callback whose body exceeds 30 lines must be extracted** into a separate, meaningfully named function.
    - For component-level logic: extract as a named `const` above the `return`.
    - For pure logic with no component dependencies: move to a utility file and import it.
    - The extracted function name must describe *what* it does, not *how* (e.g. `buildHeatmapScores`, not `processLoop`).

### Early return
- **Use fast-return (guard clauses) wherever possible** to reduce nesting and make the happy path obvious:
  ```ts
  // BAD
  function process(value: string | null) {
    if (value !== null) {
      doSomething(value);
      doMore(value);
    }
  }
  // GOOD
  function process(value: string | null) {
    if (value === null) return;
    doSomething(value);
    doMore(value);
  }
  ```
  Apply this to: event handlers, async effects, utility functions, and any `if` block that wraps the rest of a function body.

### Ternary chains
- **Never chain ternary operators.** Two or more nested/chained ternaries must be replaced with a clearly readable alternative:
    - If the value is **used only in JSX**: extract an inline arrow function that uses `if` / `if-else` and call it immediately, or derive the value with `useMemo`.
    - If the value is **reused or complex**: derive it as a named `const` with `if-else` above the `return`.
  ```tsx
  // BAD
  const label = status === 'done' ? 'Done' : status === 'pending' ? 'Pending' : 'Unknown';

  // GOOD — named const with if-else
  let label = 'Unknown';
  if (status === 'done') label = 'Done';
  else if (status === 'pending') label = 'Pending';

  // GOOD — inline callback in JSX
  {(() => {
    if (status === 'done') return <DoneIcon />;
    if (status === 'pending') return <Spinner />;
    return <ErrorIcon />;
  })()}
  ```
  A single ternary (`a ? b : c`) is fine. The rule applies when ternaries are nested or chained.

### Variable naming
- **No variable names shorter than 3 characters.** Rename to a full descriptive name.
- **Allowed exceptions** (established conventions):
    - `ev` — event
    - `err` — error
    - `e` — exception (catch clause only)
    - `idx` — index
    - `i`, `j` — loop iterators
    - `t` — i18next translation function
    - Other universally recognised single/double-letter conventions (e.g. `x`, `y` for coordinates; `db` for database handle)

### Types
- **Never use the `any` type.** Use `unknown` with type guards, or define a proper interface/type.
- **Never use the `as` operator for type casting.** Use type guards and runtime narrowing instead:
  ```tsx
  // BAD
  const val = input as string;
  // GOOD
  if (typeof input === 'string') { … }
  ```

## Example — before / after

**Before**
```tsx
export default function List({ items, onSelect }: any) {
  const mapped = items.map((i: any) => ({ ...i, label: i.name.toUpperCase() }));
  return (
    <ul>
      {mapped.map((item: any) => {
        const label = item.label;
        return <li key={item.id} onClick={() => { console.log(item.id); onSelect(item.id); }}>{label}</li>;
      })}
    </ul>
  );
}
```

**After**
```tsx
import { useMemo } from 'react';

interface Item {
  id: string;
  name: string;
}

interface Props {
  items: Item[];
  onSelect: (id: string) => void;
}

const List: React.FC<Props> = (props) => {
  const { items, onSelect } = props;

  const displayItems = useMemo(
    () => items.map((i) => ({ ...i, label: i.name.toUpperCase() })),
    [items]
  );

  const handleSelect = (id: string) => {
    console.log(id);
    onSelect(id);
  };

  return (
    <ul>
      {displayItems.map((item) => (
        <li key={item.id} onClick={() => handleSelect(item.id)}>
          {item.label}
        </li>
      ))}
    </ul>
  );
};

export default List;
```
