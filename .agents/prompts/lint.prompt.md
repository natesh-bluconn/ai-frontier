---
description: Run ESLint and TypeScript type checker and fix issues
agent: feature-dev-be
---

# Lint and Type Check

Run lint and type checks: **${input:target:Files or 'all' for whole project}**

## Steps

1. If specific files are mentioned, run lint and typecheck on those files only.
2. If no files specified, run on the whole project.

### Lint

```bash
npx eslint "{src,apps,libs,test}/**/*.ts" --fix
```

### Type Check

```bash
tsc -p ./tsconfig.json --noEmit
```

1. For each error found:

   - Show the file, line, and error message
   - Fix the error following codebase conventions
   - Re-run to verify the fix

1. Continue until all errors are resolved or report any that can't be auto-fixed.
