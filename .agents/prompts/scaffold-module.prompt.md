---
description: Scaffold a complete NestJS module with controller, service, repository, DTOs
agent: feature-dev-be
---

# Scaffold NestJS Module

Scaffold a complete new NestJS module for the resource: **${input:resourceName:Resource name (e.g. project, invoice)}**

## Steps

1. **Read 2-3 existing modules** in `src/modules/` to match the codebase style.
2. Create all files under `src/modules/<resourceName>/`:
   - `<resourceName>.module.ts` — imports `PrismaModule`, registers controller, service, repository
   - `<resourceName>.controller.ts` — multi-tenant routes `/accounts/:accountId/<resourceName>s`, Swagger decorators, auth decorators
   - `<resourceName>.service.ts` — business logic operating on DOs only, TypeDoc on public methods
   - `<resourceName>.repository.ts` — Prisma operations via `PrismaService`, returns DOs or null
   - `<resourceName>.types.ts` — interfaces for DOs, params, cursor types
   - `dto/create-<resourceName>-body.dto.ts` — class-validator + Swagger, definite assignment (`!:`)
   - `dto/update-<resourceName>-body.dto.ts`
   - `dto/get-<resourceName>-query.dto.ts` — cursor pagination params
3. Include CRUD endpoints: list (GET), get by ID (GET), create (POST), update (PATCH), delete (DELETE).
4. Use cursor-based pagination from `src/utils/pagination` for the list endpoint.
5. Add `@AllowAnyAuthenticatedUser()` decorator on the controller class (this is the default — review and replace with `@AllowAdminUser()` for admin-only resources).
6. Register the module in `app.module.ts`.
7. If a Prisma model doesn't exist yet, create a schema file at `prisma/schema/<resourceName>.prisma`.
8. Run ESLint and type checker on all created files to verify.
