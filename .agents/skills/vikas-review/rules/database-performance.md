# Database & Performance

The guiding question: **"how will this behave with 1000+ employees / all accounts in prod?"**

### DB-1: No DB calls inside loops

**Severity:** blocker
**Check:** `await this.*Repository.*` / `await this.prisma.*` / `await this.*Service.*` (that hits DB) inside `for`, `forEach`, `map` + `Promise.all`, `reduce`. Also `Promise.all(items.map(async …create))` — still N queries.
**Fix:** `findMany({ where: { id: { in: ids } } })` then a `Map`; `createMany` / `createManyAndReturn`; `updateMany`; bulk-create parents first, then children. If too big, batch — but if bulk create fails, throw; don't fall back to one-by-one.
**Say:** "no DB calls in a loop. Use bulk creates" (#1694) · "making DB calls in loop is not scalable try to use bulk updates" (#1619) · "if bulk create fails let's throw error don't go individual route. If data is too big create batches" (#2051) · "we are doing many await calls inside a loop thats something we should avoid" (#2722)

### DB-2: Audit logs use the bulk `createAuditLogs` / createMany version

**Severity:** should-fix
**Check:** Repos writing audit logs one-by-one in a loop; per-module audit logic inconsistent with other repos (audit log written in service in one place, repo in another).
**Say:** "this should use createMany version" (#2881, many) · "this still call multiple DB create calls there should only be one createAuditLogs call" (#2614) · "why log creation is happening in service where as all earlier cases we created in repository" (#2737)

### DB-3: Don't load everything into memory — filter, paginate, count, limit in the query

**Severity:** blocker
**Check:** `findMany` without `where`/`take` on growing tables (employees, users, accounts, checkins, audit logs, messages, support requests); JS `.filter()`/`.slice()` after fetching; fetching rows just to `.length`; fetching 100 when 10 are shown; fetching all tools to get one; fetching all fields to check one exists; date filters done in JS.
**Say:** "this is true. we can't load all users into memory" (#908) · "can't we do this pagination on DB level query instead of getting entire data and then slicing?" (#1936) · "if only count is required why are we fetching entire data" (#2458) · "if we are only showing 10 options in whatsapp why to fetch 100" (#2019) · "all this date filters should be moved to DB while querying" (#1672)

### DB-4: Combine round-trips; fetch what you need in one query

**Severity:** should-fix
**Check:** Two sequential queries that could be one (`include`, join, `findFirst` with `orderBy`); fetching the same record twice ("fetch manager twice"); re-fetching ids you already have; fetching count when you already fetched all rows.
**Say:** "why two DB calls? we can get this in a single call" (#2904) · "we can avoid this for loop with a include" (#2558) · "get latest job directly using DB query" (#977) · "anyway you are fetching all charts then why you need to fetch count too" (#2769)

### DB-5: Multiple writes → one transaction, in the repository

**Severity:** blocker
**Check:** Two+ dependent writes (create + audit log, create + assignment, suspend + log) without `$transaction`, or split across separate transactions; transaction logic living in the service via `this.prisma` (must be in repo). Pass `tx` through when calling other repos.
**Don't:** use transactions for single writes or for reads.
**Say:** "all of this should happen inside a transaction and why prisma is directly used in service it should be in repository" (#2099) · "Use transactions only for writing to DB. No need to use transactions for reading from DB" (#106) · "yes here you need to pass the transaction" (#2226)

### DB-6: Race-safe writes

**Severity:** blocker
**Check:** "read max/count then insert" ID generation, check-then-create without unique constraint, `updateMany` for a single-row update.
**Say:** "this will fail if we get two support requests at same time" (#1577) · "what happens if we have two create requests at once? this will fail" (#1986) · "why we are using updateMany if we are just updating a single token" (#3518)

### DB-7: Update only provided fields — but trust the DTO

**Severity:** should-fix
**Check:** Update repos that spread the whole DTO and could write `undefined` to required columns; conversely, manual `undefined`-stripping when the DTO/Prisma already ignores it.
**Say:** "wouldn't this set fields to undefined if they are not in updateDto" (#843) · "we don't need to do this always usually the DTO ignores/cleansup the undefined values" (#2385) · "don't provide all params just send required data to update" (#2226)

### DB-8: Raw SQL only when Prisma can't; never `$queryRawUnsafe`

**Severity:** blocker for Unsafe, should-fix otherwise
**Check:** `$queryRawUnsafe`; raw queries where a normal Prisma query works; positional index access on raw rows (use named keys); unnecessary joins when the column exists on the table.
**Say:** "why we have to use unsafe queryRaw?" (#1979) · "why this should be a raw query? normal query should work" (#1770) · "instead of index lets use full select key here" (#3471) · "accountId is there on supportrequest right … no need of join" (#3471)

### DB-9: Don't query on JSON columns

**Severity:** should-fix
**Check:** `path:` filters / JSON operators on `metadata`, `data` JSON fields; feature-specific data stuffed into `AuditLog.metadata`.
**Say:** "it's not efficient to query on JSON" (#3438) · "querying on metadata which is a JSON is not a good idea? … we need to see if we have to use some other model instead of logs" (#3375)

### DB-10: Soft delete by default; filter `deletedAt: null`

**Severity:** should-fix
**Check:** Hard `delete` on business entities (employees, expenses, assignments); reads missing `deletedAt: null`; filtering deleted rows in JS instead of the query. Hard delete is acceptable for pure join/flag rows — say why.
**Say:** "you should be doing soft delete here" (#658) · "Instead of filtering deleted shifts here lets filter them out at DB query itself" (#269) · "this can be achieved by deleting the record right? I don't see any harm in hard deleting these" (#2339)

### DB-11: Use ids, not names, as identifiers

**Severity:** should-fix
**Check:** Lookups/mappings by `name`, phone number, or email when an id is available; maps keyed by names from LLM output.
**Say:** "it's better to always deal with ids instead of names" (#926) · "name is never a primary identifier" (#2055) · "is it guaranteed that name will unique?" (#2409)

### DB-12: Caching must be justified and safe

**Severity:** should-fix (blocker if secrets)
**Check:** In-memory caches for data that must survive redeploys (classifications → store in DB); caches of decrypted secrets; caches around a cheap query.
**Say:** "cache will not work here. It will go away when we redeploy. Better to store in DB" (#1086) · "we are storing un encrypted data in cache thats a security risk" (#1901) · "why you need this cache if are just querying my email" (#2099)
