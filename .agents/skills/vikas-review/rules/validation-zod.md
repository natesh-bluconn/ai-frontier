# Runtime Validation with zod

Rule of thumb: **"we know what the result would look like" → zod schema, parsed once, types inferred.**

### ZOD-1: Use zod instead of manual shape checks

**Severity:** should-fix
**Check:** Chains of `typeof x === 'string'`, `'key' in obj`, `Array.isArray`, `getString(obj, 'key')` per key, hand-written type guards, custom validation endpoints for JSON payloads.
**Say:** "I don't want any magic string checks in an object always use zod because we know what the result would look like" (#3291) · "why we need to do getString for every key read why can't we do parsing once" (#3336) · "all of this should be handled by zod validation" (#3437)

### ZOD-2: Every LLM / external response is schema-validated and fails loudly

**Severity:** blocker
**Check:** `JSON.parse(llmOutput)` used directly; parse failure silently ignored; stringify-then-parse; looping over candidate schemas instead of `z.union`/`discriminatedUnion`. Throw when the response doesn't match.
**Say:** "throw an error is response doesn't match our schema" (#658) · "what if responseSchema parsing fails? throw an error" (#667) · "you can use z.union to combine multiple schemas … no need of iterating" (#658) · "instead of simple parsing we can use zod schema" (#2824)

### ZOD-3: Types come from schemas (`z.infer`), not duplicated

**Severity:** should-fix
**Check:** An interface next to a zod schema with the same shape; `Pick` it via `schema.pick()`. Schemas that exist only "for types" and are never used to validate → question them.
**Say:** "why we have to create a separate we can infer from zod schema right?" (#2806) · "this also can be derived using pick from zod" (#3437) · "why we need this schema? do we ever validate using this? or is it just for type?" (#2905)

### ZOD-4: Schema hygiene

**Severity:** nit/should-fix
**Check:** camelCase schema variable names (`llmResponseSchema`, not `LLM_RESPONSE_SCHEMA`/`LlmResponseSchema`); schemas in constants/types files, not inline in services; don't re-parse static JSON constants (type them instead); avoid `.optional()` on everything and arbitrary `.min(1)`; don't parse twice; prefer `safeParseAsync` when async refinements exist; `z.record(z.string(), z.unknown())` for open maps.
**Say:** "variables should be camelCase, update all" (#2413) · "move zod schema to constants" (#3518) · "ok this is not schema but an actual JSON, lets remove parsing and return correct type" (#3336) · "why parsing twice?" (#3396) · "why everything is optional" (#3518)

### ZOD-5: Prefer LLMs emit schemas we can execute

**Severity:** should-fix (design)
**Check:** Custom rule engines interpreting LLM-produced validation JSON.
**Say:** "what if llm generates validations as zod schema? then we don't need to maintain this whole logic right" (#3586)
