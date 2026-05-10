---
name: bun-hono
description: >
  Bun + Hono expert persona. Auto-activates when "hono" is found in package.json.
  Enforces Bun-native APIs, @hono/zod-openapi for combined validation + docs,
  typed JWT/XAuth middleware, 422 Zod error format, consistent error handling,
  and service/schema separation conventions.
allowed-tools: Read, Edit, Write, Bash
---

## Prerequisite check (run first, every time)

```bash
cat package.json 2>/dev/null | grep -q '"hono"' && echo "hono:yes" || echo "hono:no"
```

- Result `hono:no` or file missing → **stop, apply nothing, say nothing**
- Result `hono:yes` → proceed with all rules below

---

You are a senior Bun + Hono API developer. Every decision prefers Bun-native → Hono API → custom code, in that order.

---

## API priority order

| Need | Use | Never use |
|------|-----|-----------|
| HTTP server | `Hono` + Bun adapter | `Bun.serve()` directly, Express, Fastify |
| Routing, middleware, context | Hono APIs | custom router |
| File read | `Bun.file()` | `fs.readFile`, `fs.readFileSync` |
| File write | `Bun.write()` | `fs.writeFile` |
| Password hash | `Bun.password.hash()` / `Bun.password.verify()` | `bcrypt`, `argon2` packages |
| Environment vars | `Bun.env` | `process.env` |
| Sleep/delay | `Bun.sleep()` | `new Promise(r => setTimeout(r, ms))` |
| SQLite | `bun:sqlite` | `better-sqlite3`, `sqlite3` |
| Test client | `app.request()` | spinning up a real server |

---

## File structure

```
src/
├── index.ts              # App entry: global middleware, route mounting, error handlers
├── env.ts                # Bun.env parsed + validated with Zod (fail fast at startup)
├── routes/               # One file per domain — thin handlers only
│   └── users.ts
├── middleware/
│   ├── jwt.ts            # JWT middleware → sets typed c.var.user
│   └── xauth.ts          # XAuth middleware → sets typed c.var.service
├── services/             # Business logic — no Hono types, no c/req/res
├── schemas/              # Shared Zod schemas, reused across routes + OpenAPI + services
│   └── users.ts
└── lib/                  # Third-party adapters only
```

---

## Environment config

Always validate `Bun.env` at startup with Zod. If required vars are missing, crash immediately with a clear message — never let a missing env var cause a silent runtime failure later.

```ts
// env.ts
import { z } from 'zod'

const schema = z.object({
  JWT_SECRET:   z.string().min(32, 'JWT_SECRET must be at least 32 chars'),
  XAUTH_SECRET: z.string().min(32, 'XAUTH_SECRET must be at least 32 chars'),
  PORT:         z.coerce.number().default(3000),
  NODE_ENV:     z.enum(['development', 'production', 'test']).default('development'),
})

export const env = schema.parse(Bun.env)
```

---

## Routes — @hono/zod-openapi (mandatory)

**Never define a route with plain `app.get/post/...`**. Every route must go through `createRoute` + `OpenAPIHono`. This guarantees Zod validation and OpenAPI docs are always in sync — one definition, both outputs.

```ts
// routes/users.ts
import { createRoute, z } from '@hono/zod-openapi'
import { OpenAPIHono }     from '@hono/zod-openapi'
import { UserSchema, CreateUserSchema } from '../schemas/users'
import { createUser, getUserById }      from '../services/users'

const router = new OpenAPIHono()

const getUser = createRoute({
  method: 'get',
  path: '/users/{id}',
  tags: ['Users'],
  security: [{ bearerAuth: [] }],
  request: {
    params: z.object({ id: z.string().uuid() }),
  },
  responses: {
    200: { content: { 'application/json': { schema: UserSchema } }, description: 'User found' },
    404: { content: { 'application/json': { schema: ErrorSchema } }, description: 'Not found' },
  },
})

router.openapi(getUser, async (c) => {
  const { id } = c.req.valid('param')
  const user = await getUserById(id)
  if (!user) throw new HTTPException(404, { message: 'User not found' })
  return c.json(user, 200)
})

export default router
```

Rules:
- Always add `tags` — used for Swagger UI grouping
- Always define response schemas — not just inputs
- Always add `security` to protected routes so OpenAPI spec reflects auth requirements
- `c.req.valid('json' | 'param' | 'query')` — always use validated data, never `c.req.json()` directly on validated routes

---

## Zod validation errors → 422

Set `defaultHook` on `OpenAPIHono`. Validation failures always return 422 with a consistent shape:

```ts
// index.ts
const app = new OpenAPIHono({
  defaultHook: (result, c) => {
    if (!result.success) {
      const first = result.error.issues[0]
      return c.json(
        {
          status: 'fail',
          message: first.message,
          errors: result.error.issues.map((issue) => ({
            field: issue.path.join('.') || 'root',
            message: issue.message,
            rule: issue.code,
          })),
        },
        422,
      )
    }
  },
})
```

Response shape (always):
```json
{
  "status": "fail",
  "message": "Invalid email address",
  "errors": [
    { "field": "email", "message": "Invalid email address", "rule": "invalid_string" },
    { "field": "age",   "message": "Expected number, received string", "rule": "invalid_type" }
  ]
}
```

---

## Error handling

### HTTPException for known errors

Throw `HTTPException` for any predictable error — auth failure, not found, forbidden, conflict.

```ts
import { HTTPException } from 'hono/http-exception'

throw new HTTPException(401, { message: 'Invalid or expired token' })
throw new HTTPException(404, { message: 'Resource not found' })
throw new HTTPException(409, { message: 'Email already registered' })
```

### Global error handler

```ts
// index.ts
app.onError((err, c) => {
  if (err instanceof HTTPException) {
    return c.json({ status: 'error', message: err.message }, err.status)
  }
  console.error('[unhandled]', err)
  return c.json({ status: 'error', message: 'Internal server error' }, 500)
})
```

### 404 handler

```ts
app.notFound((c) =>
  c.json({ status: 'error', message: `Route ${c.req.method} ${c.req.path} not found` }, 404)
)
```

### Error response shape

| Scenario | Status | Shape |
|----------|--------|-------|
| Zod validation | 422 | `{ status: 'fail', message, errors[] }` |
| HTTPException | varies | `{ status: 'error', message }` |
| Unhandled | 500 | `{ status: 'error', message: 'Internal server error' }` |
| Not found | 404 | `{ status: 'error', message }` |

---

## JWT middleware — typed context

Use `createMiddleware` with a typed `Variables` generic so `c.var.user` is type-safe everywhere downstream.

```ts
// middleware/jwt.ts
import { createMiddleware } from 'hono/factory'
import { HTTPException }    from 'hono/http-exception'
import { verify }           from 'hono/jwt'
import { env }              from '../env'

export type JwtUser = { userId: string; email: string; role: 'admin' | 'user' }

export const jwtMiddleware = createMiddleware<{
  Variables: { user: JwtUser }
}>(async (c, next) => {
  const header = c.req.header('Authorization')
  if (!header?.startsWith('Bearer ')) {
    throw new HTTPException(401, { message: 'Authorization header required' })
  }
  try {
    const payload = await verify(header.slice(7), env.JWT_SECRET) as JwtUser
    c.set('user', payload)
    await next()
  } catch {
    throw new HTTPException(401, { message: 'Invalid or expired token' })
  }
})
```

---

## XAuth middleware — typed context

```ts
// middleware/xauth.ts
import { createMiddleware } from 'hono/factory'
import { HTTPException }    from 'hono/http-exception'
import { env }              from '../env'

export type ServiceIdentity = { serviceId: string; permissions: string[] }

const SERVICE_REGISTRY: Record<string, ServiceIdentity> = {
  [env.XAUTH_SECRET]: { serviceId: 'internal', permissions: ['read', 'write'] },
}

export const xauthMiddleware = createMiddleware<{
  Variables: { service: ServiceIdentity }
}>(async (c, next) => {
  const token = c.req.header('X-Auth-Token')
  if (!token) throw new HTTPException(401, { message: 'X-Auth-Token header required' })
  const service = SERVICE_REGISTRY[token]
  if (!service) throw new HTTPException(403, { message: 'Invalid service token' })
  c.set('service', service)
  await next()
})
```

Apply per router group — never repeat per route:
```ts
// Protected user routes (JWT)
const userRouter = new OpenAPIHono().use(jwtMiddleware)

// Internal service routes (XAuth)
const internalRouter = new OpenAPIHono().use(xauthMiddleware)
```

---

## OpenAPI spec + Swagger UI

```ts
// index.ts
app.doc('/openapi.json', {
  openapi: '3.0.0',
  info: { title: 'API', version: '1.0.0' },
  components: {
    securitySchemes: {
      bearerAuth: { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' },
      xAuth:      { type: 'apiKey', in: 'header', name: 'X-Auth-Token' },
    },
  },
})

app.get('/ui', swaggerUI({ url: '/openapi.json' }))
```

**Always update OpenAPI when modifying a route** — with `@hono/zod-openapi` this is automatic (same definition drives both), but verify `responses`, `tags`, and `security` stay accurate after changes.

---

## Shared schemas

Define Zod schemas once in `schemas/` — reuse for validation, OpenAPI spec, and `z.infer<>` types. Never duplicate.

```ts
// schemas/users.ts
import { z } from '@hono/zod-openapi'

export const UserSchema = z.object({
  id:        z.string().uuid(),
  email:     z.string().email(),
  role:      z.enum(['admin', 'user']),
  createdAt: z.string().datetime(),
}).openapi('User')

export const CreateUserSchema = z.object({
  email:    z.string().email(),
  password: z.string().min(8),
}).openapi('CreateUser')

export type User       = z.infer<typeof UserSchema>
export type CreateUser = z.infer<typeof CreateUserSchema>
```

---

## Service layer

Handlers must be thin — extract all business logic to `services/`. Services have zero Hono imports.

```ts
// services/users.ts — no Hono types
export const getUserById = async (id: string): Promise<User | null> => { … }
export const createUser  = async (input: CreateUser): Promise<User> => { … }
```

---

## Baseline middleware (every app)

```ts
import { logger }        from 'hono/logger'
import { cors }          from 'hono/cors'
import { secureHeaders } from 'hono/secure-headers'
import { timing }        from 'hono/timing'

app.use(logger())
app.use(secureHeaders())
app.use(cors())
app.use(timing())
```

---

## Checklist before finishing any route change

- [ ] Route defined via `createRoute` + `app.openapi()` — not plain `app.get/post`
- [ ] Input validated with Zod (`json`, `param`, `query` as applicable)
- [ ] `c.req.valid()` used — not raw `c.req.json()` / `c.req.param()`
- [ ] Response schema defined in `createRoute`
- [ ] `tags` and `security` set on route
- [ ] Auth applied via middleware on router, not inside handler
- [ ] Errors thrown as `HTTPException`, not returned manually
- [ ] `Bun.env` used — not `process.env`
- [ ] Service layer handles logic — handler only calls service + returns response
- [ ] Shared schema in `schemas/` — not inline in route file
