# Dates & Time

### DT-1: All date math via date-fns (and date-fns-tz)

**Severity:** should-fix
**Check:** `new Date().setHours(0,0,0,0)`, manual `getTime()` arithmetic, `* 60 * 60 * 1000`, `Date.UTC(...)` ×3, `toISOString().split('T')`, hand-written diffs, manual start/end of day. Use `startOfDay`, `endOfDay`, `differenceInDays/Minutes`, `addDays`, `format`, `isWithinInterval`, `formatInTimeZone`/`toZonedTime`.
**Say:** "use date-fns utils" (×40+) · "For all date related things use date-fns functions" (#106) · "why are we not using startofDay and endofDay here" (#1647) · "why three Date.UTC?" (#827)

### DT-2: Timezone-aware; accept timezone as a param

**Severity:** should-fix
**Check:** Day boundaries computed in server TZ; hardcoded IST math. Utils should take `timezone` (default `Asia/Kolkata` for now).
**Say:** "function should accept timezone as param for now it can default to Asia/Kolkata" (#1742) · "please date-fns tz utilities" (#378)

### DT-3: No epoch / sentinel hacks

**Severity:** blocker
**Check:** Building dates on `1970-01-01` to compare times; `24 * 60` wraparound hacks for night shifts (reuse existing night-shift util); `2099` far-future sentinels.
**Say:** "why 1970?" · "get rid of this 1970 logic" (#1651) · "why 24 \* 60? if it is night shift we already have some better logic to calculate that" (#2368) · "why this night shift logic is rewritten we should already some util right" (#3375)

### DT-4: Keep dates as Date / pass ranges as `{ start, end }`

**Severity:** should-fix
**Check:** Strings passed around and re-parsed; same date passed twice; expanding a range into per-day arrays instead of a between-check.
**Say:** "why we need to do this? can't just pass start & end and while checking just check if is in between" (#1439) · "why same date is passed twice" (#3330) · "why we need to change the type? Can't we send startTime in correct format" (#1651)
