---
name: pr-review
description: >
  PR review skill for the Bluconn codebase. Use this skill when writing PR
  descriptions, reviewing pull requests, generating changelogs, or evaluating
  whether code is merge-ready. Includes the team's PR template, review checklist,
  and merge criteria.
---

# PR Review Skill — GitHub Workflow

Templates and checklists for pull requests, code reviews, and merge decisions.

## PR Title Format

```
<change type> : <LINEAR ID> : <Description>
```

Examples:

- `feat: ENG-123 : add user authentication`
- `fix: ENG-456 : resolve null pointer in UserService`

Valid change types: `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`, `style`

## PR Description Template

```markdown
## Description

- What changes were made in this pull request?

## Type of Change

- [ ] **feat** (A new feature)
- [ ] **fix** (A bug fix)
- [ ] **docs** (Documentation-only changes)
- [ ] **refactor** (Code changes that neither fix bugs nor add features)
- [ ] **perf** (Code changes that improve performance)
- [ ] **test** (Adding or correcting tests)
- [ ] **build** (Changes affecting the build system or external dependencies)
- [ ] **ci** (Changes to CI configuration files and scripts)
- [ ] **chore** (Miscellaneous changes)
- [ ] **revert** (Reverting a previous commit)
- [ ] **style** (Formatting changes only)

## Developer Checklist ✅

### Codebase Best Practices:

- [ ] No console logs; logger used where necessary
- [ ] No database calls inside loops
- [ ] Business logic in service layer, not repository
- [ ] No business logic in common modules
- [ ] Multi-tenant URL pattern followed
- [ ] Auth decorators on all endpoints
- [ ] Git rebased to avoid merge conflicts
- [ ] Guard clauses used — errors handled at beginning of functions
- [ ] Early returns for error conditions — no deeply nested ifs
- [ ] Happy path last in functions
- [ ] No unnecessary else statements after return

### Documentation and Communication:

- [ ] PR title follows format
- [ ] Loom/Screencast video included (if applicable)
```

## Merge Criteria

### Automated (CI)

- [ ] `lint` passing
- [ ] `type-check` passing
- [ ] `test` passing with coverage thresholds
- [ ] `build` succeeds

### Human Review

- [ ] At least 1 approval
- [ ] No unresolved comments
- [ ] PR title follows format
- [ ] Branch rebased on target
- [ ] No `console.log` in code
- [ ] Developer checklist completed

## Reviewer Checklist

### Architecture

- [ ] Controllers are thin — no business logic
- [ ] Services contain all business logic, operate on DOs only
- [ ] Repositories do DB operations only
- [ ] No database queries inside loops

### TypeScript

- [ ] No `any` or `unknown` without justification
- [ ] No type assertions (`as`, `!`)
- [ ] No enums — `const` maps used
- [ ] Multiple params passed as object
- [ ] Descriptive variable names with auxiliary verbs (`isLoading`, `hasError`)
- [ ] `function` keyword used for standalone functions, not `const`

### Error Handling

- [ ] Guard clauses at beginning of functions
- [ ] Early returns for error conditions — no deeply nested if statements
- [ ] Happy path last in functions
- [ ] No unnecessary else statements after return
- [ ] User input sanitized and validated
- [ ] Proper error logging with clear messages
- [ ] NestJS exceptions used (not raw `Error`)

### NestJS

- [ ] DTOs validated with `class-validator`
- [ ] Swagger decorators on new endpoints
- [ ] JSON:API response shape followed
- [ ] Pagination on list endpoints
- [ ] Auth guards on protected endpoints
- [ ] NestJS exceptions used (not raw `Error`)

### Testing

- [ ] Tests added for new functionality
- [ ] AAA pattern followed
- [ ] Happy path + error paths covered
- [ ] `afterEach(() => jest.clearAllMocks())` present

### Security

- [ ] No secrets hardcoded
- [ ] User input validated
- [ ] No `console.log` — logger used

## Review Comment Conventions

- **`[blocking]`** — Must fix before merge
- **`[non-blocking]`** — Good to fix, won't hold PR
- **`[question]`** — Asking for clarification
- **`[nit]`** — Tiny style thing, author's discretion
- **`[arch]`** — Architecture concern, discuss first

```
[blocking] No NotFoundException thrown when user not found — service returns undefined.
[blocking] Database query inside a loop on line 47 — use findByIds instead.
[non-blocking] Could use Promise.all for parallel fetches.
[nit] Prefer const map over enum per conventions.
```
