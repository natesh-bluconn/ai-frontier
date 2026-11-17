---
name: tracing-decorator-pattern
description: >
  Guidance for adding OpenTelemetry tracing to NestJS methods in the Bluconn
  codebase with minimal diff noise. Use this skill when instrumenting an
  existing method with a span — prefer the `@Trace` method decorator over the
  `runInSpan` callback wrapper so the method body is not re-indented and the
  PR diff stays small.
---

# Tracing Decorator Pattern — Minimal-Diff Instrumentation

## Why this skill exists

Two equivalent helpers in `src/common/tracing/trace.decorator.ts` produce a
span around a piece of code:

- `runInSpan({ name, tracer, attributes?, rootContext? }, async () => { ... })`
  — a callback wrapper.
- `@Trace({ name, tracer, attributes?, swallowErrors?, rootContext? })`
  — a method decorator.

Both create the span, set status `OK`, record exceptions, and end the span.
They differ only in **how they wrap the code**:

- `runInSpan` requires you to take the entire method body, indent it one level
  deeper inside an `async () => { ... }` callback, and re-format the surrounding
  `try`/`finally`. This adds 1 leading space to **every** line in the method
  and shows up in `git diff` as a near-total rewrite (e.g. `-130 / +187`).
- `@Trace` is a single block placed **above** the method signature. The body
  stays exactly as it was. The diff is limited to: the import line, the
  decorator block, and any attribute statements that need `this`.

**Rule:** when adding a span around an existing method, use `@Trace`. Reserve
`runInSpan` for fragments **inside** a method (e.g. a sub-block of an
already-traced method) where a decorator cannot be applied.

## When this skill applies

Use this skill if any of these are true:

- You are wrapping an existing class method with a span and the diff would
  re-indent the whole body.
- You see `runInSpan({...}, async () => { /* entire method body */ })` as the
  only statement in a method's `try` — that is the anti-pattern this skill
  fixes.
- A reviewer flags a tracing PR for excessive line churn driven by indentation
  changes.

## Decorator signature recap

```ts
@Trace({
  name: "span.name" | (args) => `span.${(args[0] as Foo).type}`,
  tracer: "bluconn.<module>",
  attributes?: (args: readonly unknown[]) => Attributes,
  swallowErrors?: boolean, // default false — re-throw after recording
  rootContext?: boolean,   // default false — start under current active span
})
```

- `name` may be a constant string or a function of the call args.
- `attributes` runs **outside** the instance, so it has **no `this` binding**.
  Anything that needs an instance method (`this.foo(...)`) cannot live in the
  static `attributes` config — push it inside the body via
  `setActiveSpanAttributes({...})` instead.
- `args` is the readonly tuple of the method's runtime arguments. Cast each
  position to its declared parameter type when you reach for it
  (`args[0] as MyDto`); avoid `any`/`unknown` leaks.
- Spread-with-condition is the safest way to emit only present attributes:

  ```ts
  ...(name && { "workflow.name": name }),
  ...(count !== undefined && { "workflow.node_count": count }),
  ```

  Always coerce to an object first if the source field is loosely typed
  (e.g. `Workflow | Record<string, unknown>` → check `typeof` / `Array.isArray`
  before reading), otherwise TS errors with `Spread types may only be created
from object types.`

## Conversion recipe

Given an existing method:

```ts
async perform(data: JobData): Promise<string> {
  const { foo, bar } = data;
  // …setup…
  try {
    return await runInSpan(
      {
        name: "job.do-thing",
        tracer: "bluconn.jobs",
        attributes: { "foo.id": foo.id, "bar.kind": bar.kind },
      },
      async () => {
        // 80 lines of body, all indented one level extra
      },
    );
  } finally {
    await cleanup();
  }
}
```

Convert to:

```ts
@Trace({
  name: "job.do-thing",
  tracer: "bluconn.jobs",
  attributes: (args) => {
    const data = args[0] as JobData;
    return {
      "foo.id": data.foo.id,
      "bar.kind": data.bar.kind,
    };
  },
})
async perform(data: JobData): Promise<string> {
  const { foo, bar } = data;
  // …setup…
  try {
    // 80 lines of body, ORIGINAL indentation preserved
  } finally {
    await cleanup();
  }
}
```

### Step-by-step

1. **Replace the import.**
   `runInSpan` → `Trace` (keep `addActiveSpanEvent`, `setActiveSpanAttributes`
   if used).
2. **Add a tracer name constant** if the file does not already have one:
   ```ts
   private static readonly TRACER_NAME = "bluconn.<module>";
   ```
   Use it via `tracer: ClassName.TRACER_NAME` so the literal lives in one
   place.
3. **Move the static attributes object into a function** of `args` and cast
   each positional arg to its declared type. Drop any attributes that need
   `this`.
4. **Insert `setActiveSpanAttributes({...})` once at the top of the body** for
   any attributes you had to drop (the ones that need `this.` calls).
5. **Unwrap the body**: delete the `runInSpan(...)` call and the surrounding
   `async () => { ... }`. Keep the original `try`/`catch`/`finally`.
6. **Verify.** Run, in order:
   - `get_errors` on the file (TS check).
   - `npx eslint --fix <file>`.
   - `npm run typecheck`.
   - `git diff <base> -- <file> --shortstat` — expect a large reduction
     (e.g. 187/130 → ~40/8 on a single method).

### Dynamic span names

If the span name depends on runtime data, pass a function:

```ts
@Trace({
  name: (args) => `workflow.node.${(args[0] as WorkflowNode).type}`,
  tracer: ClassName.TRACER_NAME,
  attributes: (args) => { /* … */ },
})
```

### Mid-method spans

For sub-spans **inside** an already-decorated method, `runInSpan` is the right
tool — you cannot apply a decorator to an inline block. Place it around the
specific operation only:

```ts
const result = await runInSpan({ name: "db.findUsers", tracer: ClassName.TRACER_NAME }, () =>
  this.prisma.user.findMany({ where }),
);
```

## Existing references in the codebase

- `src/common/tracing/trace.decorator.ts` — `Trace`, `runInSpan`,
  `setActiveSpanAttributes`, `addActiveSpanEvent` source.
- `src/modules/agent/services/flowTracking.service.ts` (`@Trace` on
  `update(...)`) — example of a typed `attributes` function.
- `src/modules/agent/jobs/custom-workflow-execution.job.ts` — both `@Trace`
  patterns: constant span name (`perform`) and dynamic span name
  (`executeNodeWithLogging`), plus in-body `setActiveSpanAttributes` for
  attributes that need `this`.

## Anti-patterns to flag in review

- A method whose entire body is wrapped in `runInSpan(..., async () => { ... })`
  with nothing else in the outer `try` — convert to `@Trace`.
- Passing `args` to the `attributes` function without typing each position
  (relying on `any` / implicit narrowing).
- Calling `this.something(...)` inside the `attributes` function (it will be
  undefined; the function runs without an instance binding).
- Adding tracing in a way that re-indents > 50 lines that have no other
  semantic change. The diff should reflect _what changed_, not _where the
  braces moved_.

## Quick checklist before opening a tracing PR

- [ ] Imports updated; `runInSpan` removed where a decorator replaces it.
- [ ] `TRACER_NAME` constant present per file/module.
- [ ] No `this.` calls inside `attributes`.
- [ ] Each `args[i]` cast to its declared parameter type.
- [ ] Attributes that need instance methods moved to
      `setActiveSpanAttributes(...)` at the top of the body.
- [ ] Original method body retains its original indentation.
- [ ] `npm run typecheck` clean.
- [ ] Diff shortstat is dominated by additions; deletions are limited to the
      original `runInSpan` block and the import swap.
