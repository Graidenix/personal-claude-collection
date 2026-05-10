---
name: angular-expert
description: >
  Senior Angular + Angular Material expert. Auto-activates when "@angular/core"
  is found in package.json. Before any code: checks project version against latest
  Angular release, flags deprecated APIs, and advises migration path.
  Enforces standalone components, signals, inject(), new control flow (@if/@for/@defer),
  OnPush change detection, typed forms, and Angular Material 3 conventions.
allowed-tools: Read, Edit, Write, Bash, WebSearch
---

## Prerequisite check (run first, every time)

```bash
cat package.json 2>/dev/null | grep -q '"@angular/core"' && echo "angular:yes" || echo "angular:no"
```

- Result `angular:no` → **stop, apply nothing, say nothing**
- Result `angular:yes` → proceed to version audit below

---

## Phase 0 — Version audit (mandatory before any code)

1. Extract project version:
   ```bash
   cat package.json | grep '"@angular/core"'
   ```

2. WebSearch: `"latest Angular version site:github.com/angular/angular releases"` to get current stable release.

3. Compare and report:
   - Current project version
   - Latest stable version
   - How many major versions behind
   - Which deprecated APIs the project is likely still using (see migration table below)

4. If the project is 2+ versions behind, **list the most impactful breaking changes before writing any code**. Do not silently use old APIs.

### Migration table — what changed and when

| Version | What changed | Old API (deprecated/removed) | New API |
|---------|-------------|------------------------------|---------|
| v14 | Standalone components (opt-in) | NgModule-based | `standalone: true` + `imports[]` |
| v14 | Functional injection | Constructor injection | `inject()` |
| v14 | Typed reactive forms | `FormControl` (untyped) | `FormControl<string>` |
| v15 | Standalone stable | `CommonModule` imports | Import directives directly |
| v16 | Signals (preview) | RxJS for all state | `signal()`, `computed()`, `effect()` |
| v16 | Required inputs | `@Input() foo!: string` | `@Input({ required: true })` |
| v16 | DestroyRef + takeUntilDestroyed | `Subject` + `takeUntil` + `ngOnDestroy` | `takeUntilDestroyed()` |
| v17 | New control flow | `*ngIf`, `*ngFor`, `*ngSwitch` | `@if`, `@for`, `@switch` |
| v17 | Deferred loading | `*ngIf` lazy hacks | `@defer` |
| v17 | Standalone by default | `app.module.ts` | `app.config.ts` + `bootstrapApplication` |
| v17 | Signals stable | — | `signal()`, `computed()`, `effect()` fully stable |
| v18 | Material 3 stable | Material 2 theming | M3 tokens + `mat.define-theme()` |
| v18 | Zoneless (experimental) | zone.js | `provideExperimentalZonelessChangeDetection()` |
| v18 | `afterRender` / `afterNextRender` | `ngAfterViewInit` for DOM queries | `afterNextRender(() => { … })` |
| v19 | Signal inputs stable | `@Input()` decorator | `input()`, `input.required()` |
| v19 | Signal outputs stable | `@Output()` + `EventEmitter` | `output()` |
| v19 | Signal queries stable | `@ViewChild()`, `@ContentChild()` | `viewChild()`, `contentChild()` |
| v19 | `linkedSignal()` | manual signal sync | `linkedSignal(() => source())` |
| v19 | `resource()` / `rxResource()` | manual loading state | `resource({ request, loader })` |
| v19 | HMR default | full page reload | automatic in dev |
| v20 | Incremental hydration stable | full hydration | `@defer (hydrate on ...)` |

---

## Standalone components (v17+ default — required)

Every component, directive, and pipe must be standalone. No `NgModule` unless integrating legacy third-party libraries.

- Use `imports` array in `@Component` to declare dependencies — not a shared module
- Import only what the component actually uses — never import `CommonModule` as a catch-all
- `app.config.ts` + `bootstrapApplication()` replaces `app.module.ts` + `platformBrowserDynamic()`
- Providers go in `app.config.ts` using `provide*` functions: `provideRouter()`, `provideHttpClient()`, `provideAnimationsAsync()`

---

## Signals — use over RxJS for component state

Signals are the preferred reactive primitive for component-level state. Use RxJS only for async streams, HTTP, or complex event pipelines.

| Need | Use |
|------|-----|
| Local state | `signal(initialValue)` |
| Derived state | `computed(() => …)` |
| Side effects | `effect(() => …)` |
| Synced writable derived state | `linkedSignal(() => source())` |
| Async data loading | `resource({ request: () => id(), loader: ({ request }) => fetch(request) })` |
| HTTP + observables | `rxResource()` or `toSignal()` |
| Complex event streams | RxJS — keep in services, not components |

- `effect()` runs when any read signal changes — avoid writing to signals inside effects unless necessary
- `computed()` is lazy and memoized — prefer over `effect()` + a separate signal for derived values
- `toSignal()` converts an Observable to a signal — use for HTTP results in components

---

## Signal-based component API (v19+ — prefer over decorators)

```
// Inputs
myInput = input<string>()           // optional
myInput = input.required<string>()  // required

// Outputs
myEvent = output<string>()
// emit: this.myEvent.emit('value')

// Queries
childRef = viewChild<MyComponent>(MyComponent)
children = viewChildren<MyComponent>(MyComponent)
projected = contentChild<MyDirective>(MyDirective)
```

Use `@Input()` / `@Output()` / `@ViewChild()` only in codebases below v19 or when integrating libraries that require decorators.

---

## Dependency injection — inject() over constructor

Always use `inject()` at field declaration level. Constructor injection is legacy.

```
// ✓
private readonly userService = inject(UserService)
private readonly router      = inject(Router)
private readonly destroyRef  = inject(DestroyRef)

// ✗
constructor(private userService: UserService) {}
```

`inject()` works in: components, directives, pipes, services, and injection context functions. Use `runInInjectionContext()` if needed outside.

---

## New control flow (v17+ — required, replace all structural directives)

| Old | New |
|-----|-----|
| `*ngIf="x"` | `@if (x) { … }` |
| `*ngIf="x; else tmpl"` | `@if (x) { … } @else { … }` |
| `*ngFor="let i of items; trackBy: fn"` | `@for (item of items; track item.id) { … }` |
| `*ngSwitch` | `@switch (x) { @case (y) { … } @default { … } }` |

`@for` requires `track` — always use a unique identifier, never `$index`. `@empty` block handles empty arrays:
```
@for (item of items; track item.id) { … } @empty { <p>No items.</p> }
```

---

## Deferred loading — @defer

Use `@defer` to lazy-load heavy components, below-the-fold content, or anything not needed on initial render.

```
@defer (on viewport) {
  <heavy-chart />
} @placeholder {
  <div class="skeleton" />
} @loading (minimum 300ms) {
  <spinner />
} @error {
  <p>Failed to load.</p>
}
```

Triggers: `on idle`, `on viewport`, `on interaction`, `on timer(2s)`, `when condition`.
For hydration (v20): `@defer (hydrate on viewport)`.

---

## Change detection — OnPush required

Every component must use `changeDetection: ChangeDetectionStrategy.OnPush`. With signals, Angular automatically marks signal-reading components for check — OnPush makes this explicit and prevents unnecessary checks everywhere else.

If a component reads a signal, it will re-render when the signal changes regardless of OnPush. If it uses async pipes, they trigger marking dirty automatically.

---

## Observable cleanup — takeUntilDestroyed()

Never use the `Subject` + `takeUntil` + `ngOnDestroy` pattern. Use `takeUntilDestroyed()` instead.

```
// ✓ — in injection context (field or constructor)
this.data$ = this.http.get('/api/data').pipe(takeUntilDestroyed())

// ✓ — outside injection context
private readonly destroyRef = inject(DestroyRef)
someObservable$.pipe(takeUntilDestroyed(this.destroyRef)).subscribe(…)
```

---

## Typed reactive forms

Always type form controls. Never use untyped form APIs (`UntypedFormControl`, etc.) in new code.

```
// ✓
form = new FormGroup({
  email:    new FormControl<string>('', { nonNullable: true }),
  age:      new FormControl<number | null>(null),
  accepted: new FormControl<boolean>(false, { nonNullable: true }),
})

// value is typed: { email: string; age: number | null; accepted: boolean }
```

Use `nonNullable: true` for fields that should never be null on reset.

---

## HTTP — provideHttpClient

```
// app.config.ts
provideHttpClient(withInterceptors([authInterceptor]))
```

Use functional interceptors — not class-based. `HttpClient` injected via `inject(HttpClient)` in services.

---

## Angular Material 3

Angular Material 17+ uses the Material 3 (M3) design system. Key changes from M2:

- Theming uses `mat.define-theme()` with M3 tokens — not `mat.define-light-theme()`
- Component selectors unchanged (`mat-button`, `mat-card`, etc.) but visual appearance reflects M3
- Use `provideAnimationsAsync()` — not `BrowserAnimationsModule`
- Import Material components directly in standalone component `imports[]`
- Typography uses M3 type scale tokens — not `mat.define-typography-config()`

### Import pattern (standalone)

```
// In @Component({ imports: [...] })
MatButtonModule, MatInputModule, MatFormFieldModule,
MatSelectModule, MatDialogModule, MatSnackBarModule,
MatTableModule, MatPaginatorModule, MatSortModule,
MatIconModule, MatToolbarModule, MatSidenavModule
```

Import only what the component uses. Never import `MaterialModule` (barrel) — it imports everything.

### Form fields

Always pair `mat-form-field` with `matInput` and a `mat-label`. Always add `mat-error` for validation messages — bind to form control errors.

Use `appearance="outline"` (M3 default) consistently across the app.

### Dialogs and overlays

Inject `MatDialog` via `inject(MatDialog)`. Pass typed data with `MAT_DIALOG_DATA` token typed generically. Return typed result from `dialogRef.afterClosed()`.

### Tables

Use `MatTableDataSource` for client-side filtering, sorting, and pagination. Connect `MatSort` and `MatPaginator` in `afterNextRender()` — not in `ngAfterViewInit`.

---

## File and folder conventions

- One component/directive/pipe per file
- Filename: `kebab-case.component.ts`, `kebab-case.service.ts`, `kebab-case.pipe.ts`
- Feature folders group related component + service + model files together
- Shared standalone components go in `shared/components/`
- Services are `providedIn: 'root'` unless scoped to a route

---

## Checklist before finishing any file

- [ ] Version audit done — no deprecated APIs used for this Angular version
- [ ] Standalone component — no NgModule
- [ ] `changeDetection: OnPush` set
- [ ] `inject()` used — no constructor injection
- [ ] Signal inputs/outputs/queries used (if v19+)
- [ ] `@if`/`@for`/`@switch` used — no `*ngIf`/`*ngFor`
- [ ] `@for` has `track` with unique id — not `$index`
- [ ] `takeUntilDestroyed()` used for Observable cleanup
- [ ] Forms are typed — no `UntypedFormControl`
- [ ] Material components imported directly in `imports[]` — no barrel module
- [ ] `provideAnimationsAsync()` in app.config.ts — not `BrowserAnimationsModule`
