# API Design & DTOs

### API-1: Validate all input with a DTO — no manual validation

**Severity:** blocker
**Check:** `@Body() body: any/Record`, `@Query('x') x: string` + manual `if (!x) throw`, validation in service ("this validation should be done by dto"), body types without class-validator decorators, `Transform` where `@IsString() @IsNotEmpty()` suffices. DTO should hand the service a `Date`, not a string to parse.
**Say:** "please use DTO for all request data validations" (#519) · "instead of manual valodation use query dto" (#583) · "where are validation tags … check entire dto" (#3524) · "Dto can do this parsing and service should always get a date object" (#3391)

### API-2: DTO correctness

**Severity:** should-fix
**Check:** Update DTOs with all fields optional and only editable fields present (separate Update DTO when allowed fields differ); `@IsEnum` with Prisma enum; `@ValidateNested` for nested; conditional required fields; `@IsNotEmpty` on shared DTOs breaking other endpoints; DTOs used for responses (plain type is enough); create DTOs not exposing fields that are never set at create time; date/time fields using proper validators.
**Say:** "all of these fields should be optional because we might edit different values" (#42) · "only name is allowed to update. So create a separate dto for update" (#11) · "marking this NotEmpty will cause issues with other endpoints where this is used" (#700) · "we don't need DTO for response. Normal type is enough" (#1902)

### API-3: List endpoints are paginated (cursor, JSON:API)

**Severity:** blocker
**Check:** New `GET` list without pagination, or pagination that doesn't return next/prev links; two different pagination styles in one service; account autocomplete returning everything (searchable + page size ~50).
**Say:** "we should have pagination" (#843) · "please follow getEmployees pagination logic … we are not returning next & prev cursors here" (#787) · "why are we using two different versions of pagination?" (#2559)

### API-4: Prefer extending existing endpoints over adding new ones

**Severity:** should-fix
**Check:** A new endpoint per field update, per metric, per filter, per assignee type, "get by params" next to list, "include deleted" variant. Add a query param / reuse the regular update/list endpoint. One endpoint for related metrics.
**Say:** "why we need separate endpoint for each field? why can't we update them why regular update endpoint?" (#1655) · "why we have one endpoint for each metric? why can't we combine them all into one" (#3471) · "getTemplates should cover `getTemplateByParams` no need of separate endpoint" (#548) · "why separate endpoint? can't we extend getLeavePolicy to include deleted ones too" (#1704)

### API-5: REST shape

**Severity:** nit/should-fix
**Check:** `/accounts/:accountId/<resources>`; `/:resourceId` path params (not query); `@Patch` for updates; body (not query) for delete-many payloads; kebab-case paths; never update/delete "by params".
**Say:** "nit: update should be patch" (#106) · "nit: use body instead of query" (#3444) · "we should never update a template by params" (#548)

### API-6: Don't expose endpoints nobody needs

**Severity:** should-fix
**Check:** CRUD scaffolding where only one operation is used (token verify, credentials list/update, provider configs list, "all organisations").
**Say:** "where are we gonna use all these endpoints? Just the verify token one is enough right?" (#369) · "why we need to list credentials? … why do we need to update creds?" (#3006)

### API-7: Errors

**Severity:** should-fix
**Check:** try/catch that only rethrows; converting errors to 500; swallowing errors (`guard()` that hides failures); missing error codes for client comparison.
**Say:** "no need of try catch if you are just throwing error" (#1347) · "why 500 throw the error as is" (#497) · "along with message you can send a error code (ALREADY_EXISTS)" (#1104)

### API-8: Frontend-coordinated changes

**Severity:** nit
**Check:** Renamed fields/contract changes — mention the FE must change too; prefer FE-side mapping when only presentation differs.
**Say:** "FYI we should update the same on frontend too" (#2448) · "I meant mapping in the API query on the frontend itself" (#3551)
