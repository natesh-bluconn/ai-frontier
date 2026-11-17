---
description: Fix TypeScript and ESLint errors in the codebase
agent: feature-dev-be
---

# Fix Errors

Fix all errors in: **${input:target:File path or 'all' for whole project}**

## Steps

1. Run type checker first:

```bash
npm run typecheck 2>&1
```

1. Run ESLint:

```bash
npx eslint "{src,apps,libs,test}/**/*.ts" 2>&1
```

1. For each error:

   - Understand the root cause — don't just suppress it
   - Apply the minimal fix that resolves it correctly
   - Follow codebase conventions:
     - No `any` or type assertions unless absolutely necessary
     - Use proper Prisma types from `@prisma/client`
     - Use interfaces from the module's `types.ts`
     - DTOs use definite assignment (`!:`)

1. After fixing, re-run both commands to verify no new errors.
