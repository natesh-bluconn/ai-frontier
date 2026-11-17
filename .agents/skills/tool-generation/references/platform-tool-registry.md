# Platform Tool Registry — the complete internal tool surface

This is the list of every platform tool a custom tool's `tool` node can call by `toolName`. It
is extracted from `ToolExecutionService` and the 19 provider files it wires in. If a name is not
on this list, the sandbox returns
`{ success: false, error: "Structured tool '<name>' not found in any category" }` and your tool
node dies. Copy names character for character — `generate-form-link` is hyphenated, everything
else is snake_case.

## Ground truth is the source code — you can and should read it

You are running with access to this repository. This file is a distilled snapshot; **the zod
schemas in the provider files are the ground truth.** Whenever you are about to write a tool
node's `toolParameters` and anything is uncertain — a param name, optionality, a default, an
enum value, the exact return shape — open the provider file and read the tool's `schema:` block
and its handler's return statements. The registry's hub is:

```
src/modules/agent/services/toolExecution.service.ts   ← category map + envelope wrap + __eventActor injection
```

Category → provider source file:

| Category                   | Tools                                                                                                                                                                                                                                                             | Source file                                                          |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| whatsapp                   | send_whatsapp_message, send_button_whatsapp_message, send_list_whatsapp_message, send_template_message, send_bulk_template_message, send_manager_approval_template, send_media_message, get_whatsapp_media, handle_location_message, handle_bulk_employee_checkin | `src/modules/whatsapp/tools/whatsapp.tools.ts`                       |
| entity                     | create_entity, get_entity, update_entity, delete_entity, list_entities, list_entities_filtered, search_entities, get_entity_hierarchy                                                                                                                             | `src/modules/entity-management/tools/entity-management.tool.ts`      |
| dbOperations               | db_read_records, db_create_record, db_update_records                                                                                                                                                                                                              | `src/modules/agent/tools/db-operations.tool.ts`                      |
| openai                     | openai_chat_completion, openai_audio_transcription                                                                                                                                                                                                                | `src/modules/agent/tools/openai.tool.ts`                             |
| awsS3                      | upload_mediaBuffer_to_s3                                                                                                                                                                                                                                          | `src/modules/agent/tools/awsS3.tool.ts`                              |
| faceAttendance             | mark_face_attendance, mark_face_attendance_skip_phone_check                                                                                                                                                                                                       | `src/modules/employee/tools/face-attendance.tools.ts`                |
| email                      | send_email                                                                                                                                                                                                                                                        | `src/modules/agent/tools/email.tool.ts`                              |
| forms                      | generate-form-link                                                                                                                                                                                                                                                | `src/modules/agent/tools/forms.tool.ts`                              |
| resumeFlow                 | resume_child_workflow                                                                                                                                                                                                                                             | `src/modules/parent-workflow/tools/parent-workflow.tool.ts`          |
| regularization             | process_regularization_approval                                                                                                                                                                                                                                   | `src/modules/agent/tools/regularization.tool.ts`                     |
| supervisorflow             | validate_employee_ids, send_geofence_selection_message, validate_geofence                                                                                                                                                                                         | `src/modules/agent/tools/supervisorFlow.tool.ts`                     |
| job                        | list_jobs, get_employee_jobs, get_jobs_for_scheduling, get_assigned_jobs, update_job_completion_status, add_job_proof_of_work, search_jobs_by_name, get_employee_manager_info, get_task_hierarchy, get_job_details, update_job, get_active_flow_tracking_id       | `src/modules/project_management/job/tools/job.tools.ts`              |
| scheduler                  | schedule_task_progress_reminder                                                                                                                                                                                                                                   | `src/modules/scheduler-settings/tools/scheduler.tools.ts`            |
| knowledgeBase              | get_rag_response                                                                                                                                                                                                                                                  | `src/modules/knowledge-base/tools/knowledge-base.tools.ts`           |
| distance                   | calculate_distance_between_points                                                                                                                                                                                                                                 | `src/modules/agent/tools/distance.tool.ts`                           |
| verification               | store_onboarding_details                                                                                                                                                                                                                                          | `src/modules/verification/tools/verification.tools.ts`               |
| view                       | refresh_view, query_view                                                                                                                                                                                                                                          | `src/modules/agent/tools/view.tool.ts`                               |
| dprView                    | refresh/query × zone_view, road_view, zone_abstract, road_abstract                                                                                                                                                                                                | `src/modules/agent/tools/dpr-view.tool.ts`                           |
| erp                        | erp_get, erp_post, erp_update                                                                                                                                                                                                                                     | `src/modules/agent/tools/erp.tool.ts`                                |
| externalOperations (gated) | external_list_resources, external_read_records, external_get_record, external_create_record, external_update_record, external_delete_record                                                                                                                       | `src/modules/external-integration/tools/external-operations.tool.ts` |

How to read a provider file fast: each tool is a `tool(handler, { name, description, schema })`
call — `grep -n 'name: "'` lists every tool with its line number; the `schema: z.object({...})`
right below it is the exact parameter contract (`.optional()`, `.default(x)`, `.enum([...])`,
`.min()/.max()` are all binding), and the handler's `return` statements are the exact output
shapes. A `try/catch` that returns an error object/string means error-payload style; no catch
(or a rethrow) means the tool throws. If this snapshot and the source ever disagree, **the
source wins** — follow the source and note the drift.

Worked example tool definitions built on these tools live in the repo's `workflows/` directory
(`workflows/odometer/tools/`, `workflows/materialRequest/NewTools/`, `workflows/TripWorkflow/Tools/`)
— real production graphs you can read for how params are actually bound. Ignore their legacy
fields (`category: "n8n"`, `endpoint`, embedded `accountId`).

## How every call behaves — read this before the tables

Every `tool` node call goes through `executeToolByName`, which wraps the tool's own return
value:

- Tool ran without throwing → the node result is `{ success: true, data: <whatever the tool returned> }`.
- Tool **threw** → `{ success: false, error: "Tool execution failed: <message>" }` → **your
  tool node THROWS and the graph dies** (only `get_whatsapp_media` is auto-retried by the
  engine before dying).

This creates the single most important distinction in this file, marked on every tool below:

- **Failure: throws** — any error kills your graph at that node. If the outcome is optional,
  guard the node behind an `if-else`; if it is essential, let it die only after your own sends
  are done (irreversible/critical actions last).
- **Failure: error payload** — the tool catches internally and _returns_ its error
  (`{ success: false, error }`, an `"Error: ..."` string, or a message field). The node
  SUCCEEDS. **You must envelope-check in a code node** before using any field, or you will
  read `undefined` off a failure object and ship garbage downstream:

```js
const r = $("my_tool_node");
const envelope = (r && r.data) || r || {}; // wrapper may or may not be unwrapped
if (envelope.success === false) {
  /* handle */
}
```

"Sends message" below means the tool itself delivers user-facing WhatsApp/app messages as a
side effect. When it does, do NOT send a duplicate confirmation from the graph; when it does
NOT (it only returns text), the graph must send the text itself if the user should see it.

Parameter injection you get for free (do not fight it):

- `applyMessageSource` stamps `source`, `__flowTrackingId`, `__receivedMessageId` onto every
  call from the message context. You may pass `__flowTrackingId` explicitly when threading a
  different flow's id (production tools do this for template sends).
- For `create_entity` / `update_entity` / `delete_entity`, the service builds and injects
  `__eventActor` from source/phoneNumber/employeeId/flowTrackingId — never construct it
  yourself.
- Inside a **custom tool's graph**, `$input.body` always carries `accountId`, `phoneNumber`,
  `flowTrackingId` and the inbound message — read platform params from there. This does **not**
  extend to a platform tool a workflow step calls directly: that call receives only the step's
  own `tool.params` (plus `source` and `__flowTrackingId` / `__receivedMessageId`), so every `!`
  param below has to be bound in the step itself.

Param notation: `!` required, `?` optional, `=x` default.

---

## whatsapp — messaging (the tools your flows live on)

### send_whatsapp_message

- Params: `phoneNumber!` string · `message!` string · `messageType!` string (`"text"` normal, `"location"` sends a location-request prompt)
- Returns: string `"Message sent to <phoneNumber>"`
- Failure: **throws**. Sends message: **yes** (that IS its job).
- Routes to BluConn app / mock server automatically when `source` says so.

### send_button_whatsapp_message

- Params: `phoneNumber!` · `message!` (body text above buttons) · `buttons!` array 1–3 of `{ id!, title! }` (title ≤ 20 chars)
- Returns: string `"Interactive button message sent successfully with result: ..."`
- Failure: **throws**. Sends message: **yes**.
- The `id` you set is exactly what comes back as the reply's buttonId — this is where your
  contract's reply ids are minted.

### send_list_whatsapp_message

- Params: `phoneNumber!` · `message!` · `buttonText?="Select an option"` (≤ 20 chars) · `listItems!` array 1–10 of `{ id!, title! (≤24), description? (≤72) }`
- Returns: string `"Interactive list message sent successfully with result: ..."`
- Failure: **throws**. Sends message: **yes**. Single section titled "Options".
- List-row selections arrive as kind `button` in the engine.

### send_template_message

- Params: `phoneNumber!` (`+91...` or `91...`) · `templateName!` (DB template key) · `languageCode?` Prisma `Language` (EN, HI, KN, TA, …; defaults to the employee's profile language) · `parameters?` Record<string,string> (Mustache `{{VAR}}`) · `buttonIds?` string[] (REQUIRED if template has buttons; count+order must match) · `listRowIds?` string[] (REQUIRED if template has list rows; count+order across all sections)
- Returns: string. Success: `"Template \"<name>\" ... sent to <phone> (Result: ...)"`. **Failure is a string too**: `"Error: Employee not found with phone number ..."` or `"Error sending template: <msg>"`.
- Failure: **error payload (string)** — the node never throws. Check `typeof data === 'string' && data.startsWith('Error')` in a code node if delivery matters.
- Sends message: **yes**. Recipient must be a registered employee.

### send_bulk_template_message

- Params: `accountId!` · `recipients!` array of `{ phoneNumber!, languageCode?, parameters? }` · `templateName!` · `buttonIds?` / `listRowIds?` (same ids for ALL recipients)
- Returns: string `"✅ N messages queued for delivery using template ..."` (or `"No recipients provided"`)
- Failure: fire-and-forget — per-recipient failures are **silently dropped**; the returned string only proves queuing. Non-employees and missing templates are skipped without a trace.
- Sends message: **yes** (async). Never use it when you must know delivery happened.

### send_manager_approval_template

- Params: `phoneNumber!` (manager) · `requestType!` (e.g. "Regularization") · `employeeName!` · `employeeId!` · `details!` · `approvePayload!` · `rejectPayload!` (these two strings come back as the buttonIds of the taps) · `languageCode?="en"`
- Returns: string `"Manager approval template sent to ..."`
- Failure: **throws**. Sends message: **yes**.
- Meta-approved template `manager_approval_request` — works OUTSIDE the 24-hour window. Use for
  cold notifies to approvers.

### send_media_message

- Params: `phoneNumber!` · `mediaUrl?` XOR `mediaBuffer?` (base64; uploaded to S3 for you) · `mediaType!` enum `image|video|audio|document` · `caption?` · `fileName?` (document display name / S3 name)
- Returns: string. Success: `"Media message (<type>) sent successfully ..."`. **Failures are strings**: `"Error: Either mediaUrl or mediaBuffer must be provided"`, `"Error uploading media to S3: ..."`.
- Failure: mostly **error payload (string)**; the final remote send can still **throw**. Sends message: **yes**.

### get_whatsapp_media

- Params: `mediaId!` (WhatsApp media id, or a direct URL for BLUCONN_APP media)
- Returns: `{ mediaId, mediaBuffer (base64), mimeType }`
- Failure: **throws** — but this is the ONE tool the step engine auto-retries before failing the turn. Sends message: **no**.
- First node of every media flow: `messageBody` from `$input.body` is the mediaId when the
  inbound message was media.

### handle_location_message

- Params: `senderPhone!` · `timestamp!` · `messageBody!` (the location payload) · `logType!` `CLOCK_IN|CLOCK_OUT` · `workflowId!` (flowTrackingId) · `shiftId!` · `shiftName!` · `persistEmployeeCheckin?=true` (false = validate + confirm only, no DB write)
- Returns: attendance object `{ shiftId, shiftName, clockIn, clockOut, dayOfWeek, timestamp, logType, lat, lng, address, allowCheckinBeforeShift, allowCheckoutAfterShift }` **or a string** (validation refusal, e.g. outside geofence).
- Failure: **throws** on hard errors; refusals come back as strings. Sends message: **yes** (its own confirmation) — a step calling it can be terminal with nothing after.

### handle_bulk_employee_checkin

- Params: `phoneNumber!` (supervisor, receives summary) · `timestamp!` · `employeeIds!` string[] · `logType!` · `geofenceId!` · `accountId!`
- Returns: the formatted summary string (`✅ *Bulk Check-in Summary* ...` with per-employee failures)
- Failure: **throws**. Sends message: **yes** — the summary to the supervisor AND per-employee confirmations.

---

## entity — records (your data layer; ALL return error envelopes, none throw)

Every entity tool catches internally → node always succeeds → **always envelope-check**.
`create_entity`/`update_entity`/`delete_entity` get `__eventActor` injected automatically.

### create_entity

- Params: `accountId!` · `entityTypeSlug!` · `data!` object · `parentId?` (hierarchy) · `createdBy?` · `triggerWorkflows?=true` · `flowTrackingId?` (ALWAYS pass `$input.body.flowTrackingId` so the event links to this run)
- Returns: `{ success: true, entityId, message }` | `{ success: false, error }`
- Sends message: no.

### get_entity

- Params: `accountId!` · `entityId!`
- Returns: `{ success: true, entity: { id, entityTypeId, data, parentId, createdAt, updatedAt } }` | `{ success: false, error }`
- The record's fields live in `entity.data` — two levels deep after the wrapper:
  `((r.data)||r).entity.data`.

### update_entity

- Params: `accountId!` · `entityId!` · `data!` (partial merge) · `updatedBy?` · `version?` (optimistic concurrency) · `triggerWorkflows?=true` · `flowTrackingId?`
- Returns: `{ success: true, entityId, message }` | `{ success: false, error }`

### delete_entity

- Params: `accountId!` · `entityId!` · `deletedBy?` · `triggerWorkflows?=true`
- Returns: `{ success: true, message }` | `{ success: false, error }`. Soft delete.

### list_entities

- Params: `accountId!` · `entityTypeSlug!` · `parentId?` · `ancestryPath?` (prefix) · `page?` (1-indexed) · `limit?`
- Returns: `{ success: true, entities: [{ id, entityTypeId, data, parentId, createdAt, updatedAt }], total }` | `{ success: false, error }`

### list_entities_filtered

- Params: `list_entities` params **plus** `jsonbField?` (e.g. `'status'`) · `jsonbValue?` · `includeEntityEvents?` (adds `events` per entity)
- Returns: same shape as list_entities (+ `events` when asked). Use when you need
  `entityTypeSlug + parentId + a data field` together.

### search_entities

- Params: `accountId!` · `entityTypeSlug!` · `fieldPath!` (JSONB path, e.g. `'requestNumber'`) · `value!` · `page?` · `limit?=50`
- Returns: `{ success: true, entities: [...] }` | `{ success: false, error }` (no total)

### get_entity_hierarchy

- Params: `accountId!` · `entityTypeSlug!` (root) · `filters?` object on root data · `includeChildren?=true` · `childrenTypes?` string[] (empty = all)
- Returns: `{ success: true, entities: [nested children structure], total }` | `{ success: false, error }`
- One call replaces N list_entities calls for tree reads.

---

## dbOperations — raw Prisma table access (all THROW on DB errors)

Auto-injects `accountId` filtering and recursive `deletedAt: null` (soft-delete) filtering into
every query — you cannot leak other tenants' or deleted rows. Prefer entity tools for
entity-typed data; use these for platform tables (employees, checkins, …).

### db_read_records

- Params: `tableName!` · `filters?` object (Prisma where) · `select?` XOR `include?` (mutually exclusive) · `orderBy?` · `take?=10` (max 100) · `skip?=0` · `accountId!` · `includeDeleted?=false`
- Returns: `{ data: rows[], total, page }`
- Failure: **throws** (bad table/field names, Prisma errors).

### db_create_record

- Params: `tableName!` · `data!` · `select?` · `include?` · `accountId!`
- Returns: `{ success: true, data: createdRow }`
- Failure: **throws**.

### db_update_records

- Params: `tableName!` · `filters!` · `data!` · `select?`/`include?` (presence ⇒ single `update`, else `updateMany`)
- Returns: `{ success: true, data: row }` (single) or `{ success: true, count }` (many)
- Failure: **throws**.

---

## openai — model calls

### openai_chat_completion

- Params: `prompt!` = a COMPLETE OpenAI ChatCompletionCreateParams object (`{ model, messages, response_format?, ... }`) — the whole request goes under the single `prompt` key.
- Returns: the raw ChatCompletion — your text is at `choices[0].message.content`. When you asked
  for JSON, `JSON.parse` it inside a try/catch in a code node; the model is not a schema
  guarantee.
- Failure: **throws** (API/auth/rate errors). Sends message: no.

### openai_audio_transcription

- Params: `audio!` base64 · `model?="whisper-1"` · `language?` (e.g. `'en'`) · `response_format?="json"` enum `json|text|srt|verbose_json|vtt`
- Returns: `{ text }` on success, `{ text: "", error: "Audio transcription failed: ..." }` on failure.
- Failure: **error payload** — node succeeds; check `error`/empty `text`. Sends message: no.

---

## awsS3 — storage

### upload_mediaBuffer_to_s3

- Params: `bufferString!` base64 · `FileName!` (capital F — copy exactly) · `folderName!` · `fireAndForget?`
- Returns: `{ message, mediaUrl }`. With `fireAndForget: true` it returns the _expected_ URL
  immediately — the upload may still fail silently afterwards; only use it when a lost file is
  acceptable.
- Failure: **throws** (synchronous mode). Sends message: no.

---

## faceAttendance — face recognition check-in

Both tools return formatted, user-facing result STRINGS (✅/❌ …) for EVERY outcome — match,
no-match, no-face, errors — and never throw. They do **NOT** send the message; your graph must
send the returned string with send_whatsapp_message (or the engine shows it via the step tool's
message).

### mark_face_attendance

- Params: `mediaBuffer!` base64 image · `phoneNumber!` (must match the enrolled employee) · `accountId!` · `logType?="CLOCK_IN"`
- Returns: result string.

### mark_face_attendance_skip_phone_check

- Params: `mediaBuffer!` · `accountId!` · `logType?` — identifies the employee by face alone (kiosk/supervisor mode).
- Returns: result string.

---

## email

### send_email

- Params: `employeeId!` · `accountId?` · `mediaId!` · `messageType!` · `emailSubject!` · `emailBody!`
- Returns: `{ message: "Email sent successfully", mediaUrl }`
- Failure: **throws**. Sends: an EMAIL to the support-team address (media is downloaded,
  stored to S3, and attached/linked). Not a user-WhatsApp tool.

---

## forms — web form links

### generate-form-link ← HYPHENATED name

- Params: `toolName!` (form definition) · `accountId!` · `employeeId!` · `flowTrackingId!` (required so submission resumes the flow) · `workflowId?` · `expiresInMinutes?=30` · `phoneNumber?` + `templateName?` (both together = also send the link via that template) · `languageCode?`
- Returns: link payload; on failure `{ error }` — **error payload**, node succeeds; check it.
- Sends message: only when `phoneNumber`+`templateName` given.

---

## resumeFlow — parent/child workflow control

### resume_child_workflow

- Params: `entityId!` · `employeeId!` · `accountId!`
- Returns: `{ success, flowTrackingId|null, status|null, message }`
- Failure: **error payload**. Sends message: no.

---

## regularization

### process_regularization_approval

- Params: `flowTrackingId!` (of the employee's regularization flow) · `managerDecision!` `'approve'|'reject'` · `employeePhoneNumber!`
- Returns: a JSON **string** — `JSON.parse` it in a code node → `{ success, message, ... }`.
- Failure: **error payload** (inside the JSON string). Sends message: **yes** — it notifies the
  employee of the decision, writes the checkin on approve, and completes the flow itself. Your
  graph only needs to acknowledge the manager.

---

## supervisorflow — crew check-in helpers (all SEND their own messages)

### validate_employee_ids

- Params: `phoneNumber!` (supervisor) · `companyEmployeeIds!` string[] (≤ 15) · `accountId!`
- Returns: JSON **string** `{ message, employeeIds }` (parse it).
- Sends message: **yes** — the validation summary WITH Confirm/Cancel buttons whose ids are
  HARDCODED `confirm_employees` / `cancel_employees`. Your workflow contract MUST route exactly
  those two ids.

### send_geofence_selection_message

- Params: `phoneNumber!` · `accountId!`
- Returns: confirmation string. Sends message: **yes** — a list of the account's geofences whose
  row id is the geofence NAME (dynamic ids → empty `onButton` + unrelated-route idiom).

### validate_geofence

- Params: `phoneNumber!` · `accountId!` · `geofenceName!` (the tapped row id)
- Returns: `{ isValid, geofenceId?, geofenceName?, message }`
- Sends message: **yes** — its own follow-up prompt. Failure: **error payload** (`isValid: false`).

---

## job — project-management jobs (ALL return `{success:false, message|error}` envelopes, none throw)

Phone numbers are normalized to last-10-digits + `+91` internally. All list/read tools return
`success: false` with a message when the employee or jobs are missing — envelope-check always.

### list_jobs

- Params: `phoneNumber!` · `status?="PENDING"` enum `PENDING|IN_PROGRESS|COMPLETED` · `offset?=0`
- Returns: `{ success, jobs: [{ id, title (≤24 chars), description (trimmed + "| Due: dd-MM-yyyy") }], hasMore, totalJobs, currentOffset, nextOffset, message }`
- Page size 9; when more exist appends a pseudo-row `{ id: "SHOW_MORE_<nextOffset>", title: "Show More" }` — shaped for send*list_whatsapp_message; route the `SHOW_MORE*` prefix.

### get_employee_jobs

- Params: `phoneNumber!`
- Returns: `{ success, jobsList: [{ jobId, jobName, jobDescription, currentStatus, totalScope, completionStatus, employeeName, employeeId, unitOfMeasurement, estimatedStart, estimatedEnd, actualStart?, actualEnd? }], totalJobs, message }` (dates dd-MM-yyyy, numbers as strings)

### get_jobs_for_scheduling

- Params: `dateFrom?` YYYY-MM-DD · `dateTo?` · `includeUnassigned?=false`
- Returns: `{ success, total, jobs: [{ jobId, jobName, startDate (ISO), endDate (ISO), status, employee: { id, name, employeeId, phoneNumber }|null }], message }`

### get_assigned_jobs

- Params: `accountId!`
- Returns: same job shape as above + `subTaskName, taskName, projectName`.

### update_job_completion_status

- Params: `completionStatus!` number (units done TODAY — it ADDS to existing progress) · `jobId?` · `phoneNumber?` (one of the two required; phone path picks the latest relevant job)
- Returns: `{ success, message, jobDetails: { jobId, jobName, previousCompletionStatus, newCompletionStatus, todaysProgress, totalScope, percentageComplete, status } }`
- Auto-sets actualStart on first progress, flips to COMPLETED at full scope. Rejects negative,
  over-scope, and already-completed — all as `success: false` messages.

### add_job_proof_of_work

- Params: `phoneNumber!` · `proofOfWorkUrl!` (S3 URL) · `jobId?` (default: latest relevant job)
- Returns: `{ success, message, jobDetails: { jobId, jobName, totalMediaUrls, latestProofUrl } }`

### search_jobs_by_name

- Params: `phoneNumber!` · `taskName?` · `subTaskName?` · `jobNames?` string[] — exact-then-fuzzy matching (handles typos)
- Returns: `{ success, jobs: [ get_employee_jobs shape + taskName, subTaskName, projectName, matchScore, isExactMatch ], totalJobs, message }` sorted by score.

### get_employee_manager_info

- Params: `phoneNumber!`
- Returns: `{ success, employeeDetails: { employeeId, employeeName, employeeCode, phoneNumber }, managerDetails: { managerId, managerName, managerPhoneNumber, managerEmail }, message }` — `success:false` when no manager assigned.

### get_task_hierarchy

- Params: `taskName!` (partial, case-insensitive) · `accountId!`
- Returns: `{ success, data: { task fields + subTasks: [{ subtask fields + jobs: [...] }] }, message }`

### get_job_details

- Params: `jobId!` · `phoneNumber!` · `workflowName!` (label echoed back)
- Returns: `{ success, jobName, subTaskName, taskName, projectName, workflowName, expectedStartDate, expectedEndDate, durationDays, message }` (despite its description it does NOT send buttons — it only returns data).

### update_job

- Params: `jobId!` · `phoneNumber!` · `updateType!` enum `ACTUAL_START_DATE|NOT_STARTED_REASON|PROGRESS|PROGRESS_WITH_REASON|ACTUAL_END_DATE|NOT_ENDED_REASON` · conditionally required: `actualStartDate?` / `actualEndDate?` (ISO or dd/MM/yyyy) · `progressPercentage?` 0–100 (converted to units of totalScope) · `reason?` (appended to reasonForDelay)
- Returns: `{ success, status: "updated", jobId, jobName, jobTotalScope, jobUnitOfMeasurement, updateType, updatedFields, timestamp, message: <ready-to-send formatted WhatsApp text> }` | `{ success: false, error, errorCode }`
- Sends message: **no** — but `message` is pre-formatted for you to send.

### get_active_flow_tracking_id

- Params: `phoneNumber!`
- Returns: `{ success, flowTrackingId?, message }` — also cleans up stale flows as a side effect.

---

## scheduler

### schedule_task_progress_reminder

- Params: `accountId!` · `toolId!` (tool to run on schedule) · `type?="agenticjobs"` · `startDateTime!` ISO 8601 · `recurrence!` `{ type! enum NONE|DAILY|WEEKLY|MONTHLY, interval! ≥1, daysOfWeek? [0-6, 0=Sun] (WEEKLY), dayOfMonth? 1–31 (MONTHLY), weekOfMonth? (MONTHLY), dayOfWeekInMonth? 0–6 (MONTHLY), endType! enum NEVER|AFTER|ON, occurrences? (AFTER), endDate? ISO (ON) }` · `parameters?` object passed to the tool at fire time
- Returns: `{ success, jobId?, settingId?, cronExpression?, endDate?, error? }`
- Failure: **error payload**. Sends message: no.

---

## knowledgeBase

### get_rag_response

- Params: `question!` · `accountId!` · `language?` · `employeeId?`
- Returns: the answer **string**. Failure: **throws**. Sends message: **no** — send the answer
  yourself.

---

## distance

### calculate_distance_between_points

- Params: `points!` array ≥ 2 of `{ lat, lng }` OR `{ address }` (geocoded) · `name?`
- Returns: `{ total_distance_km, segments: [...], number_of_stops, route_summary }`
- Failure: **throws** (invalid input, geocoding failure). Sends message: no.

---

## verification — onboarding KYC

### store_onboarding_details

- Params: `employeeId!` · `accountId!` · all optional: `aadharNumber?` · `nameAsPerAadhar?` · `dateOfBirth?` · `address?` · `panNumber?` · `bankAccountNumber?` · `ifscCode?` · `status?` enum `PENDING|IN_PROGRESS|COMPLETED|REJECTED`
- Returns: plain outcome **strings** for every case; never throws. Sends message: no.

---

## view — generic materialized-view reports (all error-envelope, none throw)

### refresh_view

- Params: `viewName!` (view must already exist)
- Returns: `{ success: true, viewName }` | `{ success: false, error }`. Call ONCE before query_view.

### query_view — two modes on one tool

- QUERY mode: `executionId!` (injected by the worker) · `viewName!` · `filters?` structured object (`{col: v}` =, `{col:{gte,lte,gt,lt}}`, `{col:{in:[...]}}`, `{col:{like|ilike:'x%'}}` — parameterized, injection-safe) · `orderBy?` `[{column, direction: asc|desc}]`
  - Returns `{ success, scratchKey, total }` — rows go to a worker-side scratch file, NOT into the result (keep huge rowsets out of node results). 1M-row hard ceiling.
- READ mode: `executionId!` · `scratchKey!` (from query mode)
  - Returns `{ success, data: rows[], total }` — call ONCE from the consuming code node.

---

## dprView — DPR reporting views (all return `{success:false, error, data:[], total:0}` on failure, none throw)

Four refresh/query pairs. Every `refresh_*` takes `{}` and returns
`{ success, message, refreshedAt }` — call it ONCE before its `query_*`. Queries batch-fetch ALL
rows (no limit) — result sets can be huge; aggregate in code nodes, don't echo to WhatsApp.

- **refresh_zone_view / query_zone_view** — `accountId!` · `ancestryPath?` prefix · `startDate?`/`endDate?` YYYY-MM-DD · `entityTypeSlug?` → `{ success, data: rows, total }`; rows carry pre-joined BOQ fields (boq_short_description, boq_uom, boq_sub_work, boq_rate).
- **refresh_road_view / query_road_view** — `accountId!` · `projectId?` (road entity id) · `ancestryPath?` · `startDate?`/`endDate?` → rows with BOQ + side fields (side_name, side_direction, chainage_min/max).
- **refresh_zone_abstract / query_zone_abstract** — `accountId!` · `dprZoneId?` · `zoneName?` → ONE pre-aggregated row per zone: cumulative/prev-month/curr-month/prev-day/today amounts in ₹ and `_cr` (crore) variants.
- **refresh_road_abstract / query_road_abstract** — `accountId!` · `roadId?` · `ancestryPath?` → one row per road, same amount columns.

---

## erp — Frappe/ERPNext bridge (all error-envelope, none throw)

Credentials are resolved per account by `credentialName` — the spec must name which stored
credential to use; you cannot invent one.

### erp_get

- Params: `doctype?` XOR `url?` (custom endpoint) · `filters?` Frappe tuple filters (e.g. `[["status","=","Open"]]`) · `fields?=["name"]` · `limit?=20` · `orderBy?` · `queryParams?` · `accountId!` · `credentialName!`
- Returns: `{ success, data, count? }` | `{ success: false, error }`

### erp_post

- Params: `doctype?` XOR `url?` · `data!` · `accountId!` · `credentialName!`
- Returns: `{ success, data }` | `{ success: false, error }`

### erp_update

- Params: (`doctype!` + `name!`) XOR `url?` · `data!` · `accountId!` · `credentialName!`
- Returns: `{ success, data }` | `{ success: false, error }`

---

## externalOperations — unified external-provider CRUD (GATED)

Only registered when the account's `externalIntegrationConfig.opsEnabled` is on — if the spec
does not say external ops are enabled, treat these as unavailable and put dependent steps in
`unbuildable`. All return an `ExternalToolResponse` envelope from the executor (error-envelope
style). Common params: `accountId!` · `providerType!` (slug, e.g. `erpnext`, `hubspot`).

- **external_list_resources** — + nothing. Lists resources/fields/filters/operations for the provider.
- **external_read_records** — + `resourceName!` · `filters?` (unified, keys must match the resource's filter definitions; NO pagination params — handled internally) · `maxRecords?` ≤ 10000.
- **external_get_record** — + `resourceName!` · `recordId!`.
- **external_create_record** — + `resourceName!` · `data!` (provider field names).
- **external_update_record** — + `resourceName!` · `recordId!` · `data!`.
- **external_delete_record** — + `resourceName!` · `recordId!`.

---

## Quick failure-mode index

| Kills the node on failure (throws)                                                                                                                                                                                                                                                                                                                                                               | Returns its failure in the payload (node succeeds — envelope-check)                                                                                                                                                                                                                                                                                                                                                                                                 |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| send_whatsapp_message, send_button_whatsapp_message, send_list_whatsapp_message, send_manager_approval_template, get_whatsapp_media (auto-retried), handle_location_message (hard errors), handle_bulk_employee_checkin, send_email, db_read_records, db_create_record, db_update_records, openai_chat_completion, upload_mediaBuffer_to_s3, get_rag_response, calculate_distance_between_points | all 8 entity tools, all 12 job tools, send*template_message ("Error: …" strings), send_media_message (mostly), send_bulk_template_message (silent), openai_audio_transcription, generate-form-link, resume_child_workflow, process_regularization_approval, validate_employee_ids, validate_geofence, store_onboarding_details, refresh_view/query_view, all 8 dprView tools, schedule_task_progress_reminder, erp_get/erp_post/erp_update, all 6 external*\* tools |

## Tools that send user-facing messages themselves

send_whatsapp_message · send_button_whatsapp_message · send_list_whatsapp_message ·
send_template_message · send_bulk_template_message · send_manager_approval_template ·
send_media_message · handle_location_message · handle_bulk_employee_checkin ·
process_regularization_approval · validate_employee_ids · send_geofence_selection_message ·
validate_geofence · generate-form-link (only with phoneNumber+templateName)

Everything else only returns data or text — if the user should see it, your graph sends it.
