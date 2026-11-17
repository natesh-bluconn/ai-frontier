# Code Quality — necessity, reuse, simplicity

The single most common review comment is some form of **"why do we need this?"**. Every new function, field, endpoint, type, param, check, or dependency must justify itself.

### CQ-1: Question every addition — "why we need this?" / "where is this used?"

**Severity:** should-fix (blocker for new endpoints/tables/packages)
**Check:** For each new export/function/field/package, grep for usages. Flag unused functions, params set but never read (`executionContext is only set and not used`), defensive checks that can't trigger, new npm packages.
**Say:** "where is this used?" · "why we need this?" · "if not used remove them" · "executionContext is only set and not used. why we really need this?" (#1895) · "why we need this on backend?" (on a package, #1100)

### CQ-2: Don't rebuild what exists — find and reuse

**Severity:** should-fix
**Check:** Before accepting a new helper/repo method/endpoint/service, grep for an existing one: `getAllEmployees`, `getUser`, `updateEmployee`, `normalizePhoneNumber`, existing excel utils, existing sendEmail job, `OpenAiService`, S3 endpoints, vendor repository, `AllowUnauthenticated`-style decorators, night-shift utils, audit-log `createAuditLogs`. Prefer extending an existing endpoint with a query param over a new endpoint.
**Say:** "we already have something called `getAllEmployees`" (#124) · "don't we have an existing sendEmail job?" (#3336) · "why are we rebuilding these utils? we already have implemented these right?" (#2649) · "use existing endpoints only just add AllowOnetimeUser to those endpoints" (#1104)

### CQ-3: Don't create wrapper functions with no extra logic

**Severity:** should-fix
**Check:** Functions that only forward to another function; repo methods specialized for one field when a generic `update` exists; separate "by-email" variants.
**Say:** "why we need this separate function if it is just calling countEntitiesByTypeIdsFiltered" (#2559) · "don't create specific function unless it requires some extra logic. Use the general update function" (#700) · "no need of a separate function if it doesn't have any custom logic" (#3558)

### CQ-4: Extract repeated logic into a util (once, in a common place)

**Severity:** should-fix
**Check:** The same block appearing 2+ times in a diff or across services (cycle logic, normalized shift time, round-off, cache-key building, excel parsing, bulk-upload validation). Utils go in `src/utils` / `src/common/utils`, not inside a service or a `*.types.ts` file.
**Say:** "this logic is repeated can we create a util" · "why we keep writing excel utils for each service" · "keep all excel utils at one place" (#3407) · "these are common utils can we move there and reuse across code base" (#3182)

### CQ-5: Simplify — fewer loops, fewer conversions, fewer branches

**Severity:** should-fix
**Check:** Iterating the same array twice; loop-in-loop; grouping data that's already scoped (group by date when fetching one date); converting hours→minutes→hours; building a Map then iterating it; `sort` then index instead of scanning. Use `reduce` to build multiple structures in one pass.
**Say:** "why are we iterating over employeeCheckins twice? We can simplify logic here" (#569) · "why we have to group checkins by date if we are only getting checkins for a given date?" (#421) · "we can construct these in one loop" (#1931) · "nit: use reduce. you can also build employeeById in same reduce" (#3442) · "if you sort checkins first & last you can directly get by index" (#493)

### CQ-6: No arbitrary/magic conditions — fix the input instead

**Severity:** blocker
**Check:** `length === 5`, `1970` epoch hacks, `24 * 60` hacks, hardcoded `3` (languages), `2099`, hardcoded emails/phone numbers/IDs, `split('-')` parsing.
**Say:** "what is this length == 5 check? please avoid those arbitary condition checks. If input is incorrect fix that" (#3487) · "get rid of this 1970 logic" (#1651) · "instead 2099 can we do something like 50 years from now" (#3556) · "email hard coded?" (#678)

### CQ-7: Guard clauses and early returns

**Severity:** should-fix
**Check:** Nested if/else, happy path not last, empty `if` blocks.
**Say:** "always follow early return coding style `if (!existing || existing.accountId === accountId) { throw ... }`" (#3314) · "always prefer early returns style" (#1649) · "avoid nested if else" (#1895) · "why we need empty if block" (#2734)

### CQ-8: Remove unnecessary comments and dead code

**Severity:** should-fix
**Check:** Comments restating code, commented-out code, AI-generated narration. _Do_ keep comments where logic is non-obvious, or where a branch exists only for type narrowing ("add a comment mentioning the same").
**Say:** "remove unnecessary comments every where" (#1054) · "remove commented code" (#493) · "add necessary comments where logic is little complex" (#1649)

### CQ-9: Naming

**Severity:** nit (should-fix for misleading names)
**Check:** camelCase variables/keys (no snake_case, no `Id` → `id`, no UPPERCASE vars); snake_case file & folder names; function names that describe what they actually check; function-valued variables named like functions; `CONGRATS`-style unclear names; "OTP" for things that aren't OTPs.
**Say:** "always use camelCase naming for variables" (#269) · "lets follow snake case name convention for all the files & folders" (#416) · "this name looks confusing … let function name reflect the same" (#3498) · "rename the variable it's a function not a value" (#3467)

### CQ-10: One class per file; split growing services by flow

**Severity:** should-fix
**Check:** Multiple classes in one file; `whatsapp.service.ts`-style god files gaining new flows; functions defined inside `*.types.ts`.
**Say:** "One file should only have one class" (#269) · "this file becoming complex lets move this logic to separate file. like we will have separate service file for each flow" (#658) · "don't define functions in types" / "move functions out of types file" (#2580, #2651)

### CQ-11: Don't reassign function params / don't mutate inputs

**Severity:** should-fix
**Say:** "never reassign to a function param" (#548)

### CQ-12: Prefer well-known libraries over custom logic — but don't add deps casually

**Severity:** should-fix
**Check:** Hand-rolled template replacement (use token replacer / mustache-style), hand-rolled metrics (use OpenTelemetry), custom prompt builders (use LangGraph/LangChain prompt templates), custom JWT decode (use `aws-jwt-verify`). Conversely, reject React-only packages on backend and packages duplicating existing deps (zod).
**Say:** "why are we building these metrics ourselves there are preexisting packages … @opentelemetry/instrumentation-express" (#2381) · "use langGraph prompt template" (#3222) · "the package is for react please use something specific for backend" (#1100) · "why we need this? can't we use zod?" (#1154)
