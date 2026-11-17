---
description: Create a reusable E2E test helper for the test suite
agent: feature-dev-be
---

# Create E2E Test Helper

Create an E2E test helper for: **${input:module:Module name (e.g. shift, leave, expense)}**

## Steps

1. Read the module's controller and DTOs to understand endpoints and required fields.
2. Check existing helpers in `test/support/helper/` for the naming and style pattern.
3. Create the helper at `test/support/helper/<module>_helpers.ts` with:
   - Constructor taking `server` (from TestContext)
   - Methods for each CRUD operation: `create`, `list`, `getById`, `update`, `delete`
   - All methods use multi-tenant URL: `/accounts/${accountId}/<resource>s`
   - All methods accept `token` and `accountId` parameters
   - Sensible defaults for required fields in `create`
4. Register the helper in `test/support/test-context.ts`:
   - Import the helper class
   - Add property to `TestContext` interface
   - Initialize with `new Helper(server)` in `createTestContext()`
5. Run ESLint on the new and modified files.
