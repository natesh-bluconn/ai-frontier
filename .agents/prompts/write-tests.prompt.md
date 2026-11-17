---
description: Write unit or E2E tests for a NestJS service or module
agent: test-writer-be
---

# Write Tests

Write tests for: **${input:target:File or module to test (e.g. src/modules/shift/shift.service.ts)}**

## Steps

1. Read the source file to understand inputs, outputs, dependencies, and the layer it belongs to.
2. Determine the test type:
   - If it's a service → unit test at `test/[name]/[name].service.spec.ts`
   - If testing HTTP endpoints → E2E test in `test-e2e/[name]/[name].spec.ts`
3. Follow the AAA pattern (Arrange, Act, Assert) and codebase test conventions.
4. Cover: happy path, validation errors, not-found, auth errors, empty results.
5. After writing, run ESLint and type checker to verify.
