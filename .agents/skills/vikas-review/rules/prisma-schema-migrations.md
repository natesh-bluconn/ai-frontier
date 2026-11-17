# Prisma Schema & Migrations

### MIG-1: Schema change ⇔ exactly one matching migration

**Severity:** blocker
**Check:** For every `prisma/schema/*.prisma` change there's a migration; for every migration there's a schema change. Migration SQL contains _only_ this PR's changes (no drift from someone else's branch, no dropped tables/enums you didn't touch). Multiple migrations in one PR → regenerate as one.
**Say:** "migration file is missing. Please include it" (#336) · "why is this migration created without schema changes?" (#309) · "this migration has more changes then schema please correct it" (#407) · "please combine all migration files. Regenerate one" (#646) · "why migration has other schema changes?" (#843)

### MIG-2: Never edit an already-applied migration

**Severity:** blocker
**Check:** Diffs to existing `migrations/*/migration.sql` files.
**Say:** "why are you editing an existing migration? changes made in already applied migration never apply on DB" (#3480) · "updating existing migration won't reapply make sure the previous migration is not yet deployed anywhere" (#2644)

### MIG-3: Shared enum additions go in one PR

**Severity:** should-fix
**Check:** Several PRs each adding a value to the same enum (e.g. `AuditLogResourceType`) → migrations collide.
**Say:** "These migrations are getting mixed up instead raise a PR with all AuditLogResourceTypes in one go" (#2654)

### MIG-4: Data migrations — ask about prod size and load

**Severity:** should-fix
**Check:** `UPDATE`/`INSERT … SELECT`/backfills in SQL migrations. Ask how many rows in prod and how long it takes. Large or logic-heavy backfills → run via an admin endpoint/job instead.
**Say:** "can you please get the number of employees with extra space in prod DB? just to verify how much load this would cause on DB" (#923) · "how many accounts do we have in prod now? and how much time will this migration take" (#2367) · "do this migration via an endpoint" (#2527)

### MIG-5: snake_case columns via `@map`, tables via `@@map` (plural)

**Severity:** should-fix
**Check:** Every camelCase field has `@map("snake_case")`; model has `@@map("plural_snake")`; `createdAt`/`updatedAt` mapped; model names PascalCase singular; enum values ALL_CAPS.
**Say:** "postgres is not case sensitive. Lets convert all these to snake case using @map" (#106) · "add @map for all these fields" (#84) · "@@map(\"overtime_request_tokens\")" (#809) · "use all caps" (#1987)

### MIG-6: Indexes only when a query uses them

**Severity:** should-fix
**Check:** New `@@index` — ask which query uses it. `@@unique([a, b])` already indexes `a`; don't add `@@index([a])`. Duplicated/overlapping indexes; index on `createdAt` alone; index on `deletedAt`-only. Reorder composite id to avoid an extra index.
**Say:** "create indexes only if they are used" (#3335) · "no need of this index @@unique([bundleId, moduleSlug]) will also act as a index" (#2339) · "these two indexes look similar" (#3459) · "why we need a separate index on createdAt we will never by just createdAt" (#2580)

### MIG-7: Model the relation correctly; no redundant columns

**Severity:** should-fix
**Check:** Proper `@relation` + FK (`approvedBy` → User, `userId` → User); `accountId` on a child that's derivable from its parent (entity → account, transfer → employees); duplicated fields across two models (`providerType` on both config & credential, `costUsd` on both); both `isActive` and `deletedAt`; `enabled` flags where delete works; `Json` where `String[]` suffices; one-to-one vs one-to-many correctness (one expense setting per account; one role per employee; user in a single org).
**Say:** "why it should be linked to account? we already have account linking on entity" (#1835) · "why `isActive` & `deletedAt`? one of them can serve both right" (#3006) · "why is this Json? It can be list of strings right?" (#882) · "each account should only have one expense setting right?" (#727)

### MIG-8: Don't store derivable / ephemeral data

**Severity:** should-fix
**Check:** Storing presigned URLs (store S3 key), full old+new message in edit logs, buffers in job data, every intermediate prompt when only latest is needed.
**Say:** "storing the s3 key would be enough right" (#3335) · "why you have to store the public presigned url in conversation it has to be generated everytime somone fetches right" (#3437)

### MIG-9: Nullable → required after backfill

**Severity:** nit
**Say:** "we might have to remove the optional setting after migration" (#3476)
