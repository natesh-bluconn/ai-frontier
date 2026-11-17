# Logging

### LOG-1: No `console.*` — use the Winston/Nest logger

**Severity:** blocker
**Check:** grep diff for `console.log|console.error|console.warn|console.info|console.debug`. Use `@Inject(WINSTON_MODULE_NEST_PROVIDER)` or Nest `Logger` the same way existing code in the module does.
**Say:** "remove console logs" (×60+) · "remove console. Use logger if required" (#124) · "please check how logger is used in existing code" (#1266)

### LOG-2: Log minimally and meaningfully

**Severity:** should-fix
**Check:** A log per step; logs copied from other code; several consecutive logs that should be one; per-node logs in an orchestrator that belong in each node's `execute`; timestamps added to messages (logger already has them).
**Say:** "don't log everything only do logging if usefull" (#1928) · "looks like you just copied existing code. do we need all of these logs?" (#3028) · "combine these logs into 1" (#1895) · "logs will always have time associated why we need to push it again?" (#2567)

### LOG-3: Do log errors and genuinely useful metrics

**Severity:** should-fix
**Check:** Caught errors not logged; removing `processingTimeMs`-style perf logs.
**Say:** "log the error" (#421) · "for these kind of things where we value processingTimeMs please keep it" (#2567)

### LOG-4: Never log secrets / PII

**Severity:** blocker
**Say:** "don't print tokens" (#1104)
