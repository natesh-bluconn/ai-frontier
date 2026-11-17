---
name: code-review-be
description: >
  Review backend code against NestJS codebase conventions. Checks architecture,
  TypeScript, auth, DTOs, pagination, Prisma patterns, and tests.
tools: Read, Glob, Grep, Bash
disallowedTools: Write, Edit
model: sonnet
memory: project
skills:
  - coding-standards-be
---

{{file:../../.agents/agents/code-review-be.md}}
