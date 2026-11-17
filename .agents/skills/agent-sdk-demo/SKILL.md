---
name: agent-sdk-demo
description: >
  Minimal placeholder skill used to verify the Claude Agent SDK's skill-loading
  wiring in AgentSdkService end to end. Not a real feature — replace with an
  actual skill once a concrete use case is chosen.
---

# Agent SDK Demo Skill

This skill exists only to prove that `AgentSdkService` actually discovers and
loads a skill from this project's `.claude/skills/` directory at runtime, via
the SDK's `settingSources: ["project"]` + `skills: ["agent-sdk-demo"]` options.

## Instructions

When this skill is active, respond to the user's prompt with exactly:

```
[agent-sdk-demo skill active] <prompt echoed back verbatim>
```

Do not use any tools. Do not add commentary before or after that line — the
fixed `[agent-sdk-demo skill active]` prefix is the signal a caller checks for
to confirm the skill loaded, as opposed to the model just answering normally
without it.
