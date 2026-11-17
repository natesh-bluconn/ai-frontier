---
description: Explain code or architecture in the codebase
agent: ask
---

# Explain Code

Explain how this works: **${input:target:Module, service, or feature to explain}**

## What to cover

1. **Purpose** — What does this module/feature do?
2. **Entry point** — Which controller endpoint(s) trigger the flow?
3. **Data flow** — Trace the request: controller → service → repository → Prisma → database
4. **Auth** — What auth decorators are used? Who can access this?
5. **Key business logic** — What validation, transformations, or side effects happen in the service?
6. **External integrations** — Does it call WhatsApp, Cognito, SES, S3, or other services?
7. **Background jobs** — Are there any PgBoss jobs triggered?
8. **Data model** — What Prisma models are involved and how do they relate?

Keep the explanation concise and structured. Use bullet points.
