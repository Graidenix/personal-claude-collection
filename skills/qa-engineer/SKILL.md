---
name: qa-engineer
description: >
  QA Engineer persona. When editing React (JSX/TSX) or Angular (HTML) component
  templates, checks .claude/test-id.state in the current project — if "on",
  automatically adds data-test-id attributes to meaningful elements (buttons,
  inputs, links, data displays). Toggle with /test-id on|off.
allowed-tools: Bash, Read, Edit
---

## State check (run first, every time)

Before touching any template file, run:
```bash
cat .claude/test-id.state 2>/dev/null || echo "off"
```

- Result is `on`  → apply all rules below
- Result is `off` or file missing → **stop, do nothing, say nothing about test-id**

Acknowledge state changes with a single line: `test-id: ON` or `test-id: OFF`.

---

## When to add data-test-id

Add to elements that are **interactive** or **display meaningful data**:

| Category | Elements |
|----------|----------|
| Actions | `<button>`, `<Button>`, icon buttons, submit/reset inputs |
| Form fields | `<input>`, `<textarea>`, `<select>`, `<Checkbox>`, `<Radio>`, `<Switch>`, `<DatePicker>` |
| Navigation | `<a>`, `<Link>`, `<NavItem>`, tab items, breadcrumb links |
| Data display | elements showing: price, name, status, count, date, ID, score, label — any user-facing value |
| Forms | `<form>`, `<Form>` |
| Dialogs | modal triggers, `<Dialog>`, `<Modal>`, drawer triggers |
| Feedback | `<Alert>`, `<Toast>`, `<Badge>`, error messages, validation messages |

**Do NOT add** to: layout wrappers (`<div>`, `<section>`, `<header>` used for structure only), decorative icons, static text that has no test value, elements that already have `data-test-id`.

---

## Naming convention

Format: `kebab-case`, descriptive, no generic names.

Pattern: `[context]-[description]-[type]`

- `[context]` — component or feature scope (omit if obvious from file name)
- `[description]` — what the element represents
- `[type]` — `btn`, `input`, `select`, `link`, `label`, `value`, `form`, `modal`, `alert`

Examples:
```
login-submit-btn
email-input
user-status-value
product-price-value
confirm-delete-btn
search-input
pagination-next-btn
role-select
error-message-alert
profile-avatar-link
```

Rules:
- Never: `button1`, `input2`, `div-test`, `component-btn` (too generic)
- Never reuse the same ID twice in one template
- If the element maps to a prop or variable name, use that as the description: `{user.name}` → `user-name-value`
- For lists/repeated elements, use the item identifier in the ID: `product-{product.id}-price-value` (React) or `product-{{product.id}}-price-value` (Angular)

---

## React / JSX / TSX

Add as a JSX attribute:
```tsx
<button data-test-id="submit-btn" onClick={handleSubmit}>Submit</button>
<input data-test-id="email-input" type="email" value={email} />
<span data-test-id="user-name-value">{user.name}</span>
```

For dynamic lists:
```tsx
{products.map((product) => (
  <div key={product.id}>
    <span data-test-id={`product-${product.id}-price-value`}>{product.price}</span>
  </div>
))}
```

---

## Angular / HTML templates

Add as an HTML attribute:
```html
<button data-test-id="submit-btn" (click)="onSubmit()">Submit</button>
<input data-test-id="email-input" type="email" [(ngModel)]="email" />
<span data-test-id="user-name-value">{{ user.name }}</span>
```

For dynamic lists:
```html
<div *ngFor="let product of products">
  <span [attr.data-test-id]="'product-' + product.id + '-price-value'">{{ product.price }}</span>
</div>
```

---

## What to report

After editing, append a one-line summary:
`test-id: added N attribute(s) — [comma-separated list of IDs added]`

If a file was skipped (no meaningful elements found): `test-id: no targets found in [filename]`
