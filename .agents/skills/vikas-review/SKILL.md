---
name: vikas-review
description: >
  Review a Bluconn backend PR the way Vikas (tech lead) reviews it. Rules are mined
  from ~2,200 of his real review comments across ~460 PRs. Use when asked to review a
  PR / branch / diff "like Vikas", to pre-review your own PR before requesting his
  review, or to decide whether a PR is merge-ready. Complements coding-standards-be
  (the written standard) with what actually gets flagged in review.
---

# Vikas-style PR Review

This skill encodes the review habits of the Bluconn tech lead. The rules are not
theoretical — every rule cites the kind of comment that has been left repeatedly on
real PRs. Treat `coding-standards-be` as the baseline; this skill adds the
**review lens**: what gets questioned, what blocks a merge, and how it is phrased.

## Workflow

1. **Get the diff.** For a PR number: `gh pr view <n> --json title,body,files,additions,deletions,statusCheckRollup` and `gh pr diff <n>`. For a branch: `git diff main...HEAD`.
2. **PR-level gate first** (`rules/pr-hygiene.md`). Size, unrelated changes, failing checks, stray migrations. If the PR fails the gate, say so up front — Vikas won't line-review a PR with failing checks or mixed-in unrelated work.
3. **Load only the rule files the diff touches** (see the index below). Every file in the diff is reviewed against `rules/code-quality.md` + `rules/typescript.md`; add the others by path/content.
4. **For each hunk, ask the Vikas questions**: _Why do we need this? Where is it used? Does this already exist? Will this scale with 1000+ employees / accounts? Who is allowed to call this?_
5. **Verify before commenting.** Grep the codebase before claiming "this already exists" or "this is unused". Cite the existing function/util with `path:line`.
6. **Write the review** in the format below.

## Rule index

| File                                | Load when the diff touches…                                 | Top hits (approx. count in history)                                                         |
| ----------------------------------- | ----------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| `rules/pr-hygiene.md`               | always                                                      | unrelated changes, PR size, checks, merge conflicts                                         |
| `rules/code-quality.md`             | always                                                      | "why we need this?" (160+), duplication/reuse (130+), unnecessary comments                  |
| `rules/typescript.md`               | always (`*.ts`)                                             | type assertions (60+), redefining Prisma types (30+), enums/consts (140+), params-as-object |
| `rules/database-performance.md`     | `*.repository.ts`, services with Prisma calls, loops        | DB calls in loop (70+), fetch-all, transactions, filter in DB                               |
| `rules/prisma-schema-migrations.md` | `prisma/**`                                                 | migrations (65+), `@map`, indexes, relations                                                |
| `rules/architecture.md`             | `*.module.ts`, new modules/services, cross-module imports   | forwardRef (30), layer violations, common modules with business logic                       |
| `rules/auth-security.md`            | controllers, guards, auth, tokens                           | AllowUnauthenticated, admin-only, secrets in logs/cache                                     |
| `rules/api-dtos.md`                 | controllers, `dto/**`                                       | manual validation → DTO, pagination, REST shape, separate endpoints                         |
| `rules/validation-zod.md`           | LLM output, JSON parsing, external payloads, `unknown`      | zod instead of manual checks (35+)                                                          |
| `rules/dates-time.md`               | any date math                                               | date-fns (40+), timezones, `1970` hacks                                                     |
| `rules/async-jobs-files.md`         | jobs, workers, uploads, S3, external HTTP                   | background jobs, client-side S3 upload, HttpService, config                                 |
| `rules/logging.md`                  | any file                                                    | console.log (60+), noisy logs, tokens in logs                                               |
| `rules/testing.md`                  | `test/**`, `test-e2e/**`                                    | Prisma in tests, helpers, invalid-token cases, one endpoint per file                        |
| `rules/domain.md`                   | whatsapp, attendance, audit-log, support, LLM/agent modules | domain-specific recurring issues                                                            |

## Severity

- **blocker** — would get _Changes requested_: bugs, security/auth holes, DB-in-loop on unbounded data, missing/incorrect migrations, layer violations, `forwardRef`, type assertions, failing checks.
- **should-fix** — expected before merge: duplication, missing date-fns, redefined types, magic strings, missing DTO.
- **nit** — prefix with `nit:` (naming, blank lines, `reduce` vs loop, PATCH vs PUT).

## Output format

### Inline comments — in Vikas's voice

Short, direct, lowercase-ish, often a question. One idea per comment. Suggest the
fix, don't lecture. Use ` ```suggestion ` blocks for small concrete fixes. Use
"same here" for repeat occurrences instead of re-explaining. See `references/voice.md`.

```
src/modules/support/support.service.ts:142 [blocker]
no DB calls in a loop. fetch all employees at once with `id: { in: employeeIds }`

src/modules/support/support.service.ts:188 [blocker]
same here

src/modules/support/support.controller.ts:40 [blocker]
why AllowUnauthenticated? this should only be allowed for admins
```

### Longer findings (bugs, subtle logic)

Use a bold label, then the concrete failure scenario, then the fix:
`**Bug: <one-line claim>.** <what input/state triggers it → what goes wrong>. <fix>.`
Labels in use: `**Bug:**`, `**Security/bug:**`, `**Perf:**`, `**Cleanup:**`, `**Convention (CLAUDE.md: …):**`.

### Summary + verdict

End with 2–4 lines: what's blocking, what's PR-level (tests missing, split the PR,
fix checks), and a verdict — **Approve** / **Approve after fixing X** / **Request changes** / **Let's discuss**.
Approve-with-conditions is common: _"logic looks good. merge once the functions are moved to separate files."_

## Extending this skill

The rule files are meant to grow. To add or refine a rule:

1. Pick the matching file in `rules/` (or create `rules/<topic>.md` and add a row to the index above).
2. Append a rule using this template:

   ```markdown
   ### <ID>: <short imperative title>

   **Severity:** blocker | should-fix | nit
   **Check:** what to look for in the diff (be concrete; grep hints welcome).
   **Why:** the reason Vikas gives.
   **Say:** "<a real/representative comment>" (#PR)
   ```

   IDs are `<FILE-PREFIX>-<n>` (e.g. `DB-7`). Never renumber; retire a rule by marking it `**Retired:** <reason>`.

3. To mine new comments since the last refresh, run
   `.agents/skills/vikas-review/scripts/mine-comments.sh [since-date]` and look for themes not yet covered.
   Update the "Last mined" line below.

**Last mined:** 2026-11-02 — PRs #2 → #3586 (2,210 inline comments, 30 review bodies, 133 PR comments).
