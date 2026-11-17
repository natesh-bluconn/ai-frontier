# Architecture & Module Boundaries

### ARCH-1: Never use `forwardRef` — fix the circular dependency

**Severity:** blocker
**Check:** grep diff for `forwardRef`, `ModuleRef` used to dodge DI. Fix by moving logic to the right module, importing a _Module_ instead of a provider, or passing data in as params.
**Say:** "we should never use forwardref" (#369) · "avoid forwardRefs. If are using it then there something wrong with your code" (#664) · "why this module ref? why can't we inject SupportService" (#3336)

### ARCH-2: Layering — controller → service → repository

**Severity:** blocker
**Check:** `this.prisma` in a service/controller/job; business logic or validation (`throw NotFoundException`, lookups) in controllers; validation inside repositories; repos throwing instead of returning `null`; jobs depending on repositories instead of services.
**Say:** "don't use prisma directly in service" (#664) · "never use prisma directly in controller" (#809) · "this logic should go into service" (#1998) · "validation should always happen outside of respository" (#866) · "why to throw error just return null and the function caller should decide" (#994) · "let's try to depend on services only not repository" (#1675)

### ARCH-3: Common/integration modules contain zero business logic

**Severity:** blocker
**Check:** WhatsApp, AWS/S3/Cognito, OpenAI/LLM, Messaging, Metrics, Jobs modules importing business modules (employee, attendance, leave, overtime…) or containing report/leave/overtime logic. The business module owns the logic and calls the integration service to send/store.
**Say:** "Whatsapp module should never import any of our business logic modules" (#151) · "attendance service should have the report generation logic and it should call whatsapp service to send that message" (#146) · "Open AI service should not have any of our business logic" (#71) · "Aws module shouldn't depend on any of our modules" (#1695) · "don't define workflow related stuff in metrics service" (#1379)

### ARCH-4: Don't create a module for something that belongs in an existing one

**Severity:** should-fix
**Check:** New module/controller for a sub-concept (template edit logs → template module; face encodings → employees; overtime tokens → overtime; account settings → onboarding). Conversely, split a genuinely separate controller into its own file.
**Say:** "no need of separate module for TemplateEditLog. It should be part of template module" (#646) · "actually this is not a generic token so no need of a separate module. Move this to overtime module" (#369)

### ARCH-5: Import Modules, not providers

**Severity:** should-fix
**Check:** Adding another module's Repository/Service to `providers` instead of importing its module; loading many unused services into a module.
**Say:** "no need of adding `AccountRepository` to providers if you are importing `AccountModule`" (#421) · "why are we loading these many services and all of these are not used" (#727) · "instead of importing EmployeesService import EmployeesModule" (#1931)

### ARCH-6: Inject services; don't pass services as params or re-instantiate clients

**Severity:** should-fix
**Check:** Services passed as function args to utils; `new S3Client()` / `new OpenAI()` in a service when a wrapper exists; utils that need DI should become services.
**Say:** "why are we passing the service as params?" (#937) · "create util as service and import required services" (#937) · "why you reinitiate it here? use aws service instead" (#1695)

### ARCH-7: Router modules route; domain modules own logic

**Severity:** should-fix
**Check:** Forms/whatsapp/inbound services that accumulate support/leave/overtime logic. They should dispatch to the owning module's service.
**Say:** "all of this logic should go to supportService, this formservice just routes request to corresponding module" (#3438) · "this should be in overtime module" (#369)

### ARCH-8: Migration/one-off code is isolated

**Severity:** should-fix
**Check:** Regular flows routed through migration services; migration code mixed into regular services.
**Say:** "why this flow is going via migration? separate this logic because we would delete migration code once it's done" (#2127)

### ARCH-9: Generic over feature-specific

**Severity:** should-fix
**Check:** Tokens, metrics, form types, repo update functions hardcoded to one use case when they'll be reused.
**Say:** "please make this token generic if you want to use it everywhere" (#1076) · "this should be generic. should be able update any columns of ReceivedMessage" (#792) · "this should be generic not specific to support" (#3438)
