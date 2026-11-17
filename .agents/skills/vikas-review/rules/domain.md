# Domain-specific Recurring Issues

Add a new `##` section when a module accumulates its own recurring feedback.

## WhatsApp / Messaging

- **DOM-WA-1 (blocker):** WhatsApp/messaging modules stay free of business logic and business-module imports (see ARCH-3). New flows get their own service file (`whatsapp_<flow>.service.ts`), not more code in `whatsapp.service.ts`.
- **DOM-WA-2 (should-fix):** Checks that apply to all message types (user lookup, account checks) happen once, globally — not per handler. "this check should be common for all type of messages right" (#658)
- **DOM-WA-3 (should-fix):** Template text uses named tokens (`{{EMPLOYEE_FIRST_NAME}}`) + a shared replacer, never positional `%s`. Template names/labels/image links are consts. "Changing order of replace will change the meaning" (#269)
- **DOM-WA-4 (should-fix):** When only the message differs between branches, build the message and call `sendMessage` once. "in all of this cases only message is changing" (#698)
- **DOM-WA-5 (should-fix):** One code path to record sent messages; mock-environment config handled consistently. "use one common logic to record sent message" (#2650)
- **DOM-WA-6 (should-fix):** New message "types" must be supported generically first, in their own PR — not via ad-hoc filters. (#3409)
- **DOM-WA-7 (should-fix):** Use `normalizePhoneNumber`; prefer ids over phone numbers once the employee is resolved.

## Attendance / Checkins / Shifts / Reports

- **DOM-ATT-1 (should-fix):** Process clock-in/clock-out _pairs_ directly; don't group by date/employee and nest loops. Distance calc can be done per checkout id in a job. (#1276, #1347)
- **DOM-ATT-2 (should-fix):** Consider edge cases: consecutive CLOCK_OUTs, absent days, multiple shifts per user, night shifts, non-FIXED shift arrangements, `existingAssignments.length === 0`.
- **DOM-ATT-3 (should-fix):** Reuse common cycle/reporting-date/late-calculation utils across all reports; a change to one rule (e.g. grace period) must not alter unrelated calculations. (#608, #3428)
- **DOM-ATT-4 (should-fix):** Shift assignment changes = soft-delete old + create new, not in-place update. (#103)
- **DOM-ATT-5 (should-fix):** Excel import/export helpers live in one shared excel util. (#1598, #3407)

## Audit Logs

- **DOM-AUD-1 (should-fix):** Written in the repository, inside the same transaction as the change, using `createAuditLogs` (bulk). Consistent with how other modules do it. (#2614, #2737)
- **DOM-AUD-2 (should-fix):** Don't fabricate audit context (`performedBy: "SYSTEM"`) when missing — make it required. (#2580, #2673)
- **DOM-AUD-3 (should-fix):** Audit logs are read per resource (`resourceType` + `resourceId` required), never via JSON metadata queries, and never as a substitute for a feature table. (#2580, #3391)

## Support

- **DOM-SUP-1 (should-fix):** `accountId` on support requests is required; scope by it directly instead of joining employees. (#3471, #3476)
- **DOM-SUP-2 (should-fix):** Attachments stored once (S3 keys), conversation entries appended in one write; presigned URLs generated on read. (#3437, #3510, #3563)
- **DOM-SUP-3 (should-fix):** Fetch single records with a dedicated method, not the list version. (#3460)

## LLM / Agents / Workflow generation

- **DOM-AI-1 (blocker):** zod-validate every model output (ZOD-2). Store classifications in DB so the same message isn't re-classified. (#1086)
- **DOM-AI-2 (should-fix):** Use LangGraph/LangChain prompt templates and tooling instead of custom builders/MCP shims. (#3222, #3073)
- **DOM-AI-3 (should-fix):** Provider configuration via per-provider config loaders, not env-var constants. (#3506)
- **DOM-AI-4 (should-fix):** Don't call an LLM for something deterministic code can do. "do we really need to use LLM call for date detection" (#3374)
- **DOM-AI-5 (should-fix):** Workflow versions don't mix — a run started on v1 stays on v1. (#3287)
