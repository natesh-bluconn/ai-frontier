# Background Jobs, File Uploads, External Calls

### JOB-1: Heavy / fan-out / post-response work goes to a PgBoss background job

**Severity:** should-fix (blocker on request path with unbounded work)
**Check:** Request handlers or webhook handlers doing per-employee sends, report generation, distance calc, carry-forward, transfers, lifecycle side effects, email sending. New Temporal workflows → prefer PgBoss.
**Say:** "better you move this logic to a background job" (#1243) · "should happen via background job" (#3313) · "can we use pgboss instead of temporal?" (#2905) · "lets use pg-boss background jobs for these" (#1619)

### JOB-2: Job payloads are small — pass ids, fetch in the job

**Severity:** blocker
**Check:** Buffers, full JSON workflows, whole employee objects, or everything-already-in-DB passed as job data (stored in Postgres).
**Say:** "job data is stored on postgres. Having buffer in postgres is not a good option" (#1894) · "the data we give to enqueue a job should always be small. If you want handle the data fetching inside the job" (#3273) · "you can just push employeeIds to job data and extract required info in the job directly" (#1243) · "let's change it and only pass Id" (#2652)

### JOB-3: Use PgBoss features; don't reimplement them

**Severity:** should-fix
**Check:** Custom retry logic (use enqueue retry options); manual de-dupe (use `singletonKey`/idempotency key — one per schedule/setting); validating `startAfter` in the past; re-starting workers already started in `main.ts`; waiting for job completion in a request; swallowing errors so retries never happen.
**Say:** "jobs are automatically retried no need of custom logic while enqueing you can give retry info" (#1675) · "if you try to create a job with same singletonKey I think it will return existing job" (#1675) · "you are already starting the worker in main.ts why we need it here again" (#1266) · "why we need to wait for job completion?" (#1904) · "workflow will not retried if we won't throw error is it expected?" (#2035)

### JOB-4: Validate before enqueueing

**Severity:** should-fix
**Say:** "this validation should happen before queuing" (#1879)

### JOB-5: Durable state across stages — not local disk/memory

**Severity:** blocker
**Check:** Multi-stage jobs handing off via worker filesystem; in-memory caches expected to persist; cleanup functions never scheduled; job expiry shorter than worst-case runtime.
**Say:** "stage outputs handed off through the worker's local disk … If the next job runs on another worker or after a redeploy" (#3558) · "`sweepExpiredRuns` is never called" (#3558) · "job expires before the handler can finish" (#3558)

### FILE-1: Uploads go client → S3 via presigned URL; backend gets the key

**Severity:** blocker
**Check:** Multer/`FileInterceptor`, base64/data URLs, buffers in request bodies, backend downloading then re-uploading, presigned URLs for server-side uploads (upload directly instead), manually creating S3 "folders".
**Say:** "instead of uploading file through this endpoint. lets directly upload to S3 from client and pass key to this endpoint" (#926) · "why are we uploading from backend? upload should happen on frontend side and you send keys to backend" (#3336) · "we should not support dataurls" (#3336) · "if we are uploading from server side no need of generating pre-signed url you can directly upload" (#658)

### FILE-2: Don't shuttle files between services

**Severity:** should-fix
**Say:** "why we have to send downloaded files to inference service can't we download them there itself if send the ids" (#1111)

### EXT-1: External HTTP via `HttpService` with typed responses; config via `ConfigType`

**Severity:** should-fix
**Check:** `axios`/`fetch` directly; untyped responses then `as`; URLs/keys hardcoded or read from `process.env`; access token fetched on every call; token refresh duplicated instead of an interceptor; bulk APIs ignored in favour of sequential sends.
**Say:** "use HTTPService … if you use httpService no need of this type assertion we can define type of response" (#1619) · "move this url to config" (#978) · "do we have get the access token everytime?" (#1104) · "this we can do in setupInterceptors" (#1779) · "don't we have a bulk send option in whatsapp. This is still sequential and not scalable" (#1649)

### EXT-2: Fire-and-forget side effects

**Severity:** nit
**Check:** Awaiting non-critical logging uploads; duplicated calls in try and catch → `finally` / `void`.
**Say:** "remove await and instead defining in both try & catch move it to finally block" (#474)
