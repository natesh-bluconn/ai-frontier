---
description: Add a new endpoint to an existing NestJS module
agent: feature-dev-be
---

# Add Endpoint

Add a new endpoint: **${input:endpoint:Describe the endpoint (e.g. POST /accounts/:accountId/shifts/:id/approve)}**

## Steps

1. Read the existing module files (controller, service, repository, types) to understand the pattern.
2. Add route handler in the controller with:
   - Correct HTTP method decorator
   - `@ApiOperation`, `@ApiResponse` Swagger decorators
   - Auth decorator (default: `@AllowAnyAuthenticatedUser()`)
   - Multi-tenant URL: `/accounts/:accountId/[resource]s/...`
3. Add service method with TypeDoc, guard clauses, NestJS exceptions.
4. Add repository method if new DB operation is needed.
5. Create DTO(s) if the endpoint accepts a body or new query params.
6. Add new types/interfaces to `types.ts`.
7. After editing, run ESLint and type checker to verify.
