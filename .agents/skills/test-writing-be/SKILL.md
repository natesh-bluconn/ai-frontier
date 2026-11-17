---
name: test-writing-be
description: >
  Backend test writing skill for the Bluconn NestJS + Prisma codebase.
  Use this skill when writing, reviewing, or improving Jest tests —
  service unit tests, per-endpoint HTTP tests (both in test/), and
  module-level E2E tests (in test-e2e/).
---

# Backend Test Writing — Jest + NestJS (Bluconn Codebase)

## Core Philosophy

- Test **behavior**, not implementation. Tests must survive internal refactors.
- Follow **Arrange-Act-Assert (AAA)** — three clearly separated phases.
- Name variables: `inputX`, `mockX`, `actualX`, `expectedX`.
- Mock only at boundaries: DB, external services (WhatsApp, Cognito, SES, LLM, OpenAI, FaceRecognition). Never mock own modules.
- **E2E tests are the primary test type** — most tests use `TestContext`.

## Test Directory Structure

```
test/                           ← Service tests + per-endpoint HTTP tests + support
  [name]/
    [name].service.spec.ts      ← Service unit test (mock deps, @nestjs/testing)
    get.spec.ts                 ← HTTP test for GET /[resource]
    post.spec.ts                ← HTTP test for POST /[resource]
    patch.spec.ts               ← HTTP test for PATCH /[resource]/:id
    delete.spec.ts              ← HTTP test for DELETE /[resource]/:id
    [sub-endpoint]/             ← Nested route tests
      get.spec.ts
      post.spec.ts
  support/
    test-context.ts             ← TestContext factory (core infrastructure)
    prisma-transactional-client.ts  ← Transaction rollback isolation
    test-data-generator.ts      ← Reusable test data factories
    mocks/                      ← Mock external services
    helper/                     ← 30+ module-specific HTTP helpers
test-e2e/                       ← Module-level E2E tests (broader scope)
  [module]/
    [module].spec.ts            ← Full module E2E test (beforeAll, shared context)
```

## Running Tests

```bash
npm test            # Only src/**/*.spec.ts (rarely used — co-located unit tests)
npm run test:e2e    # All tests in test/ + test-e2e/
npm run test:cov    # Unit tests with coverage
```

## TestContext — The Core E2E Pattern

Every E2E test uses `createTestContext()` which:

1. Creates a **transactional Prisma client** (all DB writes roll back at teardown)
2. Boots a full NestJS app with `AppModule`
3. Overrides external service providers with mocks
4. Initializes 30+ module helper classes
5. Returns a `TestContext` with `app`, `server`, `prisma`, helpers, and `tearDown()`

### Mocked External Services (always overridden)

| Provider                 | Mock class                   | Behavior                                    |
| ------------------------ | ---------------------------- | ------------------------------------------- |
| `PrismaService`          | Transaction proxy            | Rollback-based isolation                    |
| `WhatsappService`        | `MockWhatsappService`        | No-op messaging                             |
| `CognitoService`         | `MockCognitoService`         | Returns `{ UserSub: 'dummy-user-sub-...' }` |
| `WhatsAppRemoteService`  | `MockWhatsAppRemoteService`  | Returns mock URLs, 200 status               |
| `SESService`             | `MockSESService`             | No-op email                                 |
| `LLMService`             | `MockLLMService`             | Configurable: `setReturnNull()`             |
| `OpenAiService`          | `MockOpenAiService`          | Returns mock embeddings                     |
| `FaceRecognitionService` | `MockFaceRecognitionService` | Mock encodings                              |

## Non-Negotiable Rules

1. **AAA pattern** — Arrange, Act, Assert. Blank line between phases.
2. Variable naming: `inputX`, `mockX`, `actualX`, `expectedX`.
3. `afterEach(() => jest.clearAllMocks())` in unit tests.
4. `jest.clearAllMocks()` + `jest.clearAllTimers()` + `tc.tearDown()` in E2E `afterAll`.
5. Mock only at boundaries. **Never mock own services.**
6. Cover: happy path (201/200), validation errors (400), not-found (404), auth errors (403), empty results.
7. No DB queries inside loops in test helpers.
8. **E2E:** Always use `createTestContext()`.
9. **E2E:** Always call `tc.tearDown()` in `afterAll` with 30s timeout.
10. No `console.log` in test files.
11. Test names: `it('should return 400 status code if request body is empty')`.
12. **Auth:** Use `tc.authHelper.getToken(email)` or `tc.authHelper.getAdminToken(email)`.
13. **URLs:** Multi-tenant: `/accounts/:accountId/[resource]`.
14. **Timeouts:** `}, 30000);` on `beforeAll` and `afterAll`.

## Template 1 — Service Unit Test

```typescript
// test/[name]/[name].service.spec.ts
import { Test, type TestingModule } from "@nestjs/testing";
import { NotFoundException } from "@nestjs/common";
import { [Name]Service } from "./[name].service";
import { [Name]Repository } from "./[name].repository";

describe("[Name]Service", () => {
  let service: [Name]Service;
  const mock[Name]Repository = {
    findAll: jest.fn(),
    findById: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        [Name]Service,
        { provide: [Name]Repository, useValue: mock[Name]Repository },
      ],
    }).compile();
    service = module.get<[Name]Service>([Name]Service);
  });

  afterEach(() => jest.clearAllMocks());

  describe("findOne", () => {
    it("returns domain object when record exists", async () => {
      // Arrange
      const inputId = "record-123";
      const expected[Name] = { id: inputId, name: "Test" };
      mock[Name]Repository.findById.mockResolvedValue(expected[Name]);

      // Act
      const actualResult = await service.findOne(inputId);

      // Assert
      expect(actualResult).toEqual(expected[Name]);
    });

    it("throws NotFoundException when record does not exist", async () => {
      // Arrange
      const inputId = "nonexistent-id";
      mock[Name]Repository.findById.mockResolvedValue(null);

      // Act + Assert
      await expect(service.findOne(inputId)).rejects.toThrow(NotFoundException);
    });
  });
});
```

## Template 2 — Per-Endpoint HTTP Test

```typescript
// test/[name]/get.spec.ts  (or post.spec.ts, patch.spec.ts, delete.spec.ts)
import { HttpStatus } from "@nestjs/common";
import supertest from "supertest";
import { createTestContext, type TestContext } from "test/support/test-context";

describe("GET /accounts/:accountId/[resources]", () => {
  let tc: TestContext;
  let accountId: string;
  let token: string;

  beforeEach(async () => {
    tc = await createTestContext();
    const account = await tc.accountHelper.createAccount({});
    accountId = account.id;
    token = tc.authHelper.getToken(account.userEmail);
  });

  afterEach(async () => {
    jest.clearAllMocks();
    jest.clearAllTimers();
    await tc.tearDown();
  }, 30000);

  it("should return 200 with list of [resources]", async () => {
    // Arrange
    await tc.[module]Helper.create[Resource](token, accountId, { name: "Item 1" });

    // Act
    const response = await supertest(tc.server)
      .get(`/accounts/${accountId}/[resources]`)
      .set("Authorization", `Bearer ${token}`);

    // Assert
    expect(response.statusCode).toBe(HttpStatus.OK);
    expect(response.body.data).toHaveLength(1);
  });

  it("should return 403 FORBIDDEN with invalid token", async () => {
    const response = await supertest(tc.server)
      .get(`/accounts/${accountId}/[resources]`)
      .set("Authorization", "Bearer invalid-token");

    expect(response.statusCode).toBe(HttpStatus.FORBIDDEN);
  });
});
```

## Template 3 — Module-Level E2E Test

```typescript
// test-e2e/[module]/[module].spec.ts
import { HttpStatus } from "@nestjs/common";
import supertest from "supertest";
import { createTestContext, type TestContext } from "test/support/test-context";

describe("[MODULE] MODULE TEST CASES", () => {
  let tc: TestContext;
  let accountId: string;
  let token: string;

  beforeAll(async () => {
    tc = await createTestContext();
    const account = await tc.accountHelper.createAccount({});
    accountId = account.id;
    token = tc.authHelper.getToken(account.userEmail);
  }, 30000);

  afterAll(async () => {
    jest.clearAllTimers();
    jest.clearAllMocks();
    await tc.tearDown();
  }, 30000);

  describe("Create [Resource]", () => {
    it("should return 400 status code if request body is empty", async () => {
      const response = await supertest(tc.server)
        .post(`/accounts/${accountId}/[resources]`)
        .set("Authorization", `Bearer ${token}`)
        .send({});

      expect(response.body.statusCode).toBe(HttpStatus.BAD_REQUEST);
    });

    it("should create a <resource> if request body is correct", async () => {
      const response = await tc.<module>Helper.create<Resource>(token, accountId, {
        name: "Test Resource",
      });
      expect(response.statusCode).toBe(HttpStatus.CREATED);
    });

    it("should return 404 NOT_FOUND with invalid account ID", async () => {
      const response = await tc.<module>Helper.create<Resource>(token, "invalid-accountId", {
        name: "Test",
      });
      expect(response.statusCode).toBe(HttpStatus.NOT_FOUND);
    });

    it("should return 403 FORBIDDEN with invalid token", async () => {
      const response = await tc.<module>Helper.create<Resource>("invalid-token", accountId, {
        name: "Test",
      });
      expect(response.statusCode).toBe(HttpStatus.FORBIDDEN);
    });
  });
});
```

## HTTP Helper Template (`test/support/helper/`)

```typescript
// test/support/helper/<module>_helper.ts
import { type Server } from "node:http";
import supertest from "supertest";

export class <Module>Helper {
  constructor(private readonly server: Server) {}

  async create<Resource>(
    token: string,
    accountId: string,
    data: { name?: string },
  ): Promise<{ id: string; statusCode: number; <resource>: Record<string, unknown> }> {
    const requestBody = { name: data.name ?? `test-<resource>-${Date.now()}` };

    const response = await supertest(this.server)
      .post(`/accounts/${accountId}/<resources>`)
      .set("Authorization", `Bearer ${token}`)
      .send(requestBody);

    return { id: response.body.id, statusCode: response.statusCode, <resource>: response.body };
  }

  async getAll<Resources>(accountId: string, token: string, filters: Record<string, unknown>) {
    const response = await supertest(this.server)
      .get(`/accounts/${accountId}/<resources>`)
      .set("Authorization", `Bearer ${token}`)
      .query(filters);
    return { statusCode: response.statusCode, data: response.body.data };
  }

  async update<Resource>(token: string, accountId: string, resourceId: string, data: Record<string, unknown>) {
    const response = await supertest(this.server)
      .patch(`/accounts/${accountId}/<resources>/${resourceId}`)
      .set("Authorization", `Bearer ${token}`)
      .send(data);
    return { statusCode: response.statusCode, <resource>: response.body };
  }

  async delete<Resource>(token: string, accountId: string, resourceId: string) {
    const result = await supertest(this.server)
      .delete(`/accounts/${accountId}/<resources>/${resourceId}`)
      .set("Authorization", `Bearer ${token}`);
    return { statusCode: result.statusCode, response: result.body };
  }
}
```
