---
description: Review backend code against NestJS conventions
agent: code-review-be
---

# Review Backend Code

Review the following: **${input:target:File or module to review}**

Check all of these systematically:

1. **Architecture** — correct layer responsibilities (controller/service/repository)
2. **Auth** — auth decorator on every endpoint
3. **Routes** — multi-tenant URL pattern `/accounts/:accountId/[resource]s`
4. **TypeScript** — no `any`, no enums, interfaces preferred, no magic strings
5. **Pagination** — cursor-based, using `decodeCursor()` / `buildPaginationLinksAndData()`
6. **DTOs** — class-validator, Swagger, definite assignment (`!:`)
7. **JSON:API** — response shape `{ data, links, meta }`
8. **Prisma** — no DB queries in loops, PrismaModule imported
9. **Security** — no secrets, no console.log, logger used
10. **Tests** (if test file) — AAA pattern, TestContext, `tc.tearDown()`

Output findings by severity: 🔴 CRITICAL, 🟠 MAJOR, 🟡 MINOR, 💡 SUGGESTION.
End with verdict: ✅ Approve, 🔁 Request Changes, or ⛔ Reject.
