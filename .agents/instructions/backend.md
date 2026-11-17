# Bluconn Backend — Copilot Instructions

This is a NestJS + TypeScript + Prisma (PostgreSQL) backend with strict coding standards.

## Stack

- **NestJS** with TypeScript strict mode
- **Prisma** ORM (PostgreSQL) — `PrismaService` via `PrismaModule`
- **class-validator** + **class-transformer** for DTOs
- **Swagger** (`@nestjs/swagger`) for API docs
- **JSON:API** response format with cursor-based pagination
- **Winston** logger via `@Inject(WINSTON_MODULE_NEST_PROVIDER)`
- **PgBoss** for background jobs
- **Jest** + **Supertest** for testing

## Architecture

Layered architecture — strict separation of concerns:

| Layer          | Does                                                   | Must NOT               |
| -------------- | ------------------------------------------------------ | ---------------------- |
| Controller     | HTTP in/out, auth decorators, DTO↔DO mapping, Swagger | Contain business logic |
| Service        | Business logic, validation, orchestration              | Touch Prisma directly  |
| Repository     | Prisma DB queries, DAO→DO mapping                      | Contain business logic |
| Common modules | External service wrappers (WhatsApp, AWS, etc.)        | Contain business logic |

## Key Conventions

### Core Principles

- Provide accurate, factual, thoughtful answers — reason carefully
- Write correct, up-to-date, bug-free, fully functional, working, secure, easy-to-read, and efficient code
- If there might not be a correct answer, say so. If you do not know the answer, say so instead of guessing
- Prefer iteration and modularization over code duplication

### TypeScript

- No `any`, no `unknown`, no type assertions (`as`, `!`)
- No enums — use `const` maps with `as const`. Prisma enums OK.
- Prefer `interface` over `type` for object shapes
- Explicit return types on exported functions
- Multiple params → pass as object; multiple returns → return as object
- No `console.log` — use NestJS `Logger` or Winston
- Use descriptive variable names with auxiliary verbs (e.g., `isLoading`, `hasError`)
- Use the `function` keyword for standalone functions, not `const`

### Error Handling and Validation

- **Sanitize user input** — validate all inputs via DTOs with class-validator
- **Handle errors and edge cases at the beginning of functions** — use guard clauses
- **Use early returns** for error conditions to avoid deeply nested if statements
- **Place the happy path last** in the function for improved readability
- **Avoid unnecessary else statements** — use the if-return pattern instead
- **Use guard clauses** to handle preconditions and invalid states early
- **Implement proper error logging** and user-friendly error messages
- **Consider custom error types or error factories** for consistent error handling

### Routes & Auth

- Multi-tenant URLs: `/accounts/:accountId/[resource]s`
- Global `AuthGuard` via `APP_GUARD` — no manual `@UseGuards()`
- Auth decorators: `@AllowAnyAuthenticatedUser()`, `@AllowAdminUser()`, `@AllowUnauthenticated()`

### DTOs

- class-validator decorators on all fields
- `@ApiProperty` / `@ApiPropertyOptional` Swagger decorators
- Definite assignment: `name!: string`
- Suffixes: `CreateXBodyDto`, `UpdateXBodyDto`, `GetXsQueryDto`

### Pagination

- Cursor-based via `decodeCursor()` and `buildPaginationLinksAndData()` from `src/utils/pagination`
- JSON:API response: `{ data, links, totalCount }`

### Prisma

- Import `PrismaModule`, not `PrismaService` directly
- No DB queries inside loops — use `findMany`, `createMany` with `IN` clauses
- Repository returns `null` when not found; service throws `NotFoundException`
- DAO→DO mapping via `toDO()` method in repository

### File Structure

```text
src/modules/[name]/
├── [name].module.ts
├── [name].controller.ts
├── [name].service.ts
├── [name].repository.ts
├── [name].types.ts
└── dto/
```

### Testing

- Service unit tests: `test/[name]/[name].service.spec.ts` (mock deps, `@nestjs/testing`)
- Per-endpoint HTTP tests: `test/[name]/get.spec.ts`, `post.spec.ts`, etc. (`createTestContext()`, `beforeEach`)
- Module E2E tests: `test-e2e/[name]/[name].spec.ts` (`createTestContext()`, `beforeAll`)
- AAA pattern (Arrange, Act, Assert), variable naming: `inputX`, `mockX`, `actualX`, `expectedX`
- Mock only at boundaries (WhatsApp, Cognito, SES, LLM, FaceRecognition)
- `tc.tearDown()` in `afterAll` with 30s timeout

### Commands

- Lint: `npm run lint` → `eslint "{src,apps,libs,test}/**/*.ts" --fix`
- Type check: `npm run typecheck` → `tsc -p ./tsconfig.json --noEmit`
- Test: `npm run test` (unit), `npm run test:e2e` (E2E)
