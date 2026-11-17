---
description: Generate a PR description following the team template
agent: ask
---

# Generate PR Description

Generate a pull request description for the current changes.

## Steps

1. Run `git diff --name-only HEAD~1` or `git diff --staged --name-only` to see changed files.
2. Run `git diff HEAD~1` or `git diff --staged` to understand what changed.
3. Determine the change type: feat, fix, refactor, perf, test, docs, build, ci, chore, revert, style.
4. Write a clear description of the changes.
5. Output using this exact format:

```markdown
## Title suggestion

<change type> : <LINEAR ID if known> : <Description>

## Description

- <bullet points describing what changed and why>

## Type of Change

(Select the most appropriate type of change and reflect it in the title, e.g., `fix: <LINEAR ID> : <Description>`. Remove any categories that don't apply.)

- [ ] **feat** (A new feature)
- [ ] **fix** (A bug fix)
- [ ] **docs** (Documentation-only changes)
- [ ] **refactor** (Code changes that neither fix bugs nor add features)
- [ ] **perf** (Code changes that improve performance)
- [ ] **test** (Adding or correcting tests)
- [ ] **build** (Changes affecting the build system or external dependencies, e.g., gulp, broccoli, npm)
- [ ] **ci** (Changes to CI configuration files and scripts, e.g., Travis, CircleCI, BrowserStack, SauceLabs)
- [ ] **chore** (Miscellaneous changes that do not modify source or test files)
- [ ] **revert** (Reverting a previous commit)
- [ ] **style** (Changes that do not affect code functionality, e.g., formatting, whitespace)

## Developer Checklist ✅

(For any checklist items that don't apply, use strikethrough formatting. You must still check the box for acknowledgment. PRs will not be mergeable until all relevant items are checked.)

### Codebase Best Practices:

- [ ] I have ensured that my PR does not include any console logs, and I have used a logger where necessary.
- [ ] I have verified that there are no database calls inside loops.
- [ ] I have ensured business logic is not implemented in the repository layer; it belongs in the service layer. The repository layer is exclusively for database operations.
- [ ] I have avoided placing business logic in common modules (e.g., WhatsApp/AWS). These modules are used only for external services, while business logic remains within our modules.
- [ ] I have performed a `git rebase` or equivalent to avoid merge conflicts in the target branch.

### Documentation and Communication:

- [ ] I have updated the title of this pull request to follow the format `<Change type> : <Description>`.
- [ ] I have included a Loom/Screencast video demonstrating the functionality of the PR, where applicable.

### Screenshots/Video of the Feature in Action (if applicable) 📸

Include a short video explaining complex changes or decisions that may not be immediately obvious.
```

6. Check the box for the matching change type. Use strikethrough (`~~- [ ] item~~`) for items that don't apply.
