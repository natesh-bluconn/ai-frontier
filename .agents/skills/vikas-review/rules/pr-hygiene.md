# PR Hygiene (PR-level gate)

Check these before reading any code. Most "Request changes" with no line comments come from here.

### PR-1: All checks must pass before review

**Severity:** blocker
**Check:** `gh pr view <n> --json statusCheckRollup`. Lint, prettier, typecheck, tests. Also flag if _no_ checks ran.
**Why:** Reviewer time is wasted on PRs that don't build. Approving a PR with failing checks is itself called out.
**Say:** "fix prettier errors. I won't be reviewing any PR if all checks are not passing" (#2654) · "why was this PR approved? even though checks are failing" (#3417) · "why no checks ran on this PR?" (#3410)

### PR-2: No changes unrelated to the task

**Severity:** blocker
**Check:** Files/hunks that don't serve the PR title: `package.json`/`package-lock.json` churn, `tsconfig.json`, `docker-compose.yml`, `app.module.ts`, `main.ts`, test support files, other modules' logic, reformatting. Lint-fix PRs must contain no logic changes.
**Why:** Mixed PRs are hard to review and hide regressions.
**Say:** "how are these changes related to this PR? don't include unrelated changes" (#1649) · "don't include any logical changes in this lint fix PR" (#2881) · "why is this removed?" (on tsconfig, #2327) · "revert all changes not related to your PR" (#1577)

### PR-3: Keep PRs small but functionally meaningful

**Severity:** should-fix (blocker if > ~1000 lines)
**Check:** additions+deletions. Target ≲ 200–400 changed lines. But don't split by file type (schema PR, then repo PR, then service PR) — each PR should deliver a working slice.
**Say:** "keep your PR short no more than 200 changes" (#493) · "why is this approved? it has 1000+ line changes?" (#2677) · "make sure that each PR you raise delivers a meaningful piece of functionality toward the final feature. Don't split PRs based solely on files." (#3375) · "I am not sure how we gonna use these const so better raise a PR which completes some functionality" (#3506)

### PR-4: Rebased, no merge conflicts, not mixing other PRs' commits

**Severity:** blocker
**Check:** `mergeable` state; commits from other branches; changes that already exist on main.
**Say:** "this PR is mixing up other PRs stuff too and fix merge conflicts" (#2662) · "this is already implemented with pagination. Please rebase your branch with main" (#1059) · "if merging main is problem, please create a separate PR with only your changes" (#713)

### PR-5: Bot comments (Copilot / Claude / CodeRabbit) addressed

**Severity:** should-fix
**Check:** Unresolved bot review threads.
**Say:** "fix Claude comments" · "please fix copilot comments" · "Yes please. And also fix all copilot comments too" (#772)

### PR-6: Previous review comments actually fixed

**Severity:** blocker
**Check:** On re-review, re-open each earlier thread and verify the code changed. Don't accept "resolved" without the change.
**Say:** "this is not fixed" · "most of my last comment is not fixed" (#2099) · "all comments are not fixed" (#3222)

### PR-7: Title, description, and proof of testing

**Severity:** should-fix
**Check:** PR title/description per `pr-review` skill template; a loom/screenshot for user-facing changes; tests for new endpoints (a 12k-line PR with no tests was flagged).
**Say:** "make sure that you include details about the changes in PR description and PR title" (#2428) · "going forward include a loom or screenshot for every PR" (#169) · "the PR adds ~12k lines with no unit, HTTP or E2E tests" (#3558)

### PR-8: No debug / test-only leftovers

**Severity:** blocker
**Check:** Test-only modules wired into `app.module.ts`, hardcoded test passwords outside test env, analysis `.md` files committed (e.g. `performance-optimization-suggestions.md`), commented-out code.
**Say:** "you have added this for testing? Can you please remove it" (#425) · "remove this file" (#1076) · "we should only use this constant password for testing purpose only" (#1087)
