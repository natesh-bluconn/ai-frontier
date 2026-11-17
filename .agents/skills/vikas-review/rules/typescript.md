# TypeScript & Typing

### TS-1: No type assertions (`as`, `!`, `satisfies` used as a workaround)

**Severity:** blocker
**Check:** grep the diff for `as`, `!.`, `!;`, `as unknown as`, `satisfies`. Each one needs the _root_ type fixed: typed `httpService.post<T>()`, correct repository return type, zod parse, discriminated union, generic on a helper. Flag `satisfies` on plain constants ("why we need satisfies?").
**Why:** Assertions hide real type mismatches; the most frequent single-line comment in history.
**Say:** "no type assertion" · "why you have to do this type assertion after defining the type on `this.httpService.post<…>`" (#2650) · "why you need type assertion here if we are checking Array.isArray in below line" (#1530) · "don't use typeassertion, validated entities should return correct type" (#2409)

### TS-2: Derive types — don't redefine Prisma / DTO / zod types

**Severity:** should-fix
**Check:** New interfaces in `*.types.ts` that mirror a Prisma model, a DTO, or a zod schema. Use `Pick<>`, `Omit<>`, `Prisma.XGetPayload<>`, `Prisma.XWhereInput`, `z.infer<>`, `extends XBodyDto`. Prisma enums over hand-written string unions/consts.
**Say:** "why you have to define this again? we already have EmployeeCheckin type from prisma" (#1347) · "no need of defining this type complete you can use Pick<EmployeeCheckin, 'id' | 'employeeId'>" (#1347) · "FormField should be inferred from FormFieldSchema" (#3182) · "why can't use prisma enum" (#3312)

### TS-3: No magic strings — enums / `as const` maps everywhere

**Severity:** should-fix
**Check:** String literals compared or assigned for statuses, types, template names, labels, platform names, login methods, job names, feature flags. Prisma enum if it's a DB value; otherwise a `const X = {...} as const` map (no TS `enum`). Feature flags: one central place.
**Say:** "use enum" (×100+) · "this is why I always to define these as enum constants" (#2651) · "I don't want any magic string checks in an object always use zod because we know what the result would look like" (#3291) · "add all feature flags at one place" (#3314)

### TS-4: More than 2 params → one object param

**Severity:** should-fix
**Check:** Function signatures with 3+ positional params (threshold has varied 2–3; flag at 3+, mention at 2+ when the types are the same and easy to swap).
**Say:** "any function should not take more than 2 params. If it's more than 2 pass it as a object" (#151) · "pass params as object when they are more than 3" (#2650)

### TS-5: Use discriminated unions instead of runtime type sniffing

**Severity:** should-fix
**Check:** `if ('x' in obj)`, `typeof obj.y === 'string'` chains, optional fields that are required for some variants (`trueBranch`/`falseBranch` for if-else nodes), return types that depend on node type.
**Say:** "why can't we use union types to narrow down to specific message type?" (#2651) · "we can create a union type so we expect `trueBranch` & `falseBranch` to be defined for `if-else` type" (#1895)

### TS-6: Accept the correct type, not `string | X` or optional-everything

**Severity:** should-fix
**Check:** Params typed `string` that should be `Date`/enum; `string[] | string` filters (always array); fields optional when they're always present (`auditContext?`, `accountId?`); supporting two input shapes; `| undefined` where caller always passes a value; optional chaining on always-present `tx`.
**Say:** "why are we accepting string just accept Date" (#1675) · "filter status should always be a array, even if we want to filter by one value pass as array" (#3409) · "why this will optional we will always have auditContext right?" (#2671) · "always accept one type why you have to support two" (#3437)

### TS-7: No `any` / `unknown` where the shape is known

**Severity:** should-fix
**Check:** `unknown` for data whose schema we own (form attachments, entity data, LLM responses). Parse once with zod into a typed value.
**Say:** "we always know support form attachments schema why is this unknown" (#3336) · "Convention (CLAUDE.md: no `unknown`): `spec!: Record<string, unknown>`" (#3558)

### TS-8: Explicit return types; don't drop them

**Severity:** should-fix
**Say:** "include return type" (#3) · "why return type is removed?" (#1358)

### TS-9: Don't define types inside functions; keep types in `*.types.ts`

**Severity:** nit
**Say:** "don't define types inside a function" (#1535) · "move all types to types file" (#1770)
