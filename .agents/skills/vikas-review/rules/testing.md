# Tests

See `test-writing-be` for structure. These are what gets flagged in review.

### TEST-1: Never touch Prisma/repositories directly in HTTP/E2E tests — use the API

**Severity:** blocker
**Check:** `prisma.*` or `*Repository` calls in `test/**/*.spec.ts` / `test-e2e/**` for arrange or assert. Create data via endpoints / helpers that call endpoints.
**Say:** "let's not directly use the repository. Always use an endpoint to do any action in e2e tests" (#80) · "we should never use prisma directly. Always get desired data through APIs" (#442) · "Please remove all DB calls" (#1049)

### TEST-2: Repeated setup → shared helpers in `test/support`

**Severity:** should-fix
**Check:** Copy-pasted account/token/employee creation; a second helper for the same thing ("why two shift helpers?"); helpers for things that have no endpoint; mock services inline in `test-context.ts` (split per file); global setup/teardown not using the clear-database util.
**Say:** "if you see something repeating a lot, let's create a util function for the same" (#81) · "you can use createTestLeaveApplication helper" (#513) · "lets move this mock services to separate files for each" (#1166)

### TEST-3: One endpoint per spec file; `beforeEach` for per-endpoint tests

**Severity:** should-fix
**Check:** `get.spec.ts` covering two endpoints; `beforeAll` in per-endpoint tests (E2E module tests may use `beforeAll`).
**Say:** "looks like this file is dealing with two endpoints. Move them into separate files" (#676) · "why is this changed to `beforeAll`?" (#425)

### TEST-4: Cover auth failures and edge cases

**Severity:** should-fix
**Check:** Each endpoint has a no-token / invalid-token case; 404 cases with accurate titles; assertions on returned payloads, not only status.
**Say:** "write a test case for invalid token … please add it for all endpoints" (#519) · "assert messages too" (#561)

### TEST-5: Mock paid/external services

**Severity:** blocker
**Check:** Tests hitting OpenAI/LLMs, WhatsApp, Cognito, S3.
**Say:** "Running these tests every time might add up to our openAi billing" (#80) · "this might hit openAi to fetch holidays. If so let's mock that" (#81)

### TEST-6: Don't paper over slow/failing tests

**Severity:** blocker
**Check:** Raised Jest timeouts; deleted test cases; duplicated tests between unit and e2e; tests that "pass" but assert the wrong thing.
**Say:** "why we need high timeouts? Instead of increasing timeouts can you please check why it's taking more time?" (#1044) · "why are these test cases deleted?" (#2183) · "whats the point in testing same thing at two different places?" (#2367) · "are these test cases passing? I think they are not correct" (#490)
