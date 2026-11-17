---
name: coding-standards-be
description: >
  Backend coding standards for the Bluconn NestJS + TypeScript + Prisma codebase.
  Use this skill when writing, reviewing, or evaluating backend code to ensure
  it follows the team's conventions for architecture, TypeScript, DTOs, pagination,
  auth, Prisma, and JSON:API responses.
---

# Backend Coding Standards — NestJS + TypeScript (Bluconn Codebase)

## Core Principles

- **Provide accurate, factual, thoughtful answers** — reason carefully through problems.
- **Write correct, up-to-date, bug-free, fully functional, working, secure, easy-to-read, and efficient code.**
- **If there might not be a correct answer, say so. If you do not know the answer, say so instead of guessing.**
- **Prefer iteration and modularization over code duplication.**
- **Write concise, technical TypeScript code with accurate examples.**
- **Prefer data immutability** — use `const`, avoid mutating objects/arrays, use spread operators or immutable methods.

## TypeScript

- **Strict mode always on** — `"strict": true` in tsconfig.
- **No `any` or `unknown`** unless absolutely necessary — look for existing types in the codebase first.
- **Prefer `interface` over `type`** for object shapes. Use `type` for unions and aliases only.
- **No enums in app code** — use `const` maps instead. Prisma enums from `@prisma/client` are OK.
- **No type assertions** (`as` or `!`) — exception: `!` is used for class-validator DTO definite assignment (`name!: string`).
- **Explicit return types** on all exported functions and class methods.
- **Pass multiple parameters as objects; return multiple results as objects.**
- **No `console.log`** — use `new Logger(ClassName.name)` or `@Inject(WINSTON_MODULE_NEST_PROVIDER)`.
- **Remove unnecessary log statements** in production code.

```typescript
// ✅ Good
const ORDER_STATUS = {
  PENDING: "pending",
  CONFIRMED: "confirmed",
  CANCELLED: "cancelled",
} as const;
type OrderStatus = (typeof ORDER_STATUS)[keyof typeof ORDER_STATUS];

// ❌ Bad
enum OrderStatus {
  Pending = "pending",
}
```

## Naming & File Conventions

| Thing                 | Convention             | Example                                              |
| --------------------- | ---------------------- | ---------------------------------------------------- |
| Files & directories   | camelCase              | `modules/shiftOffers`, `employee.service.ts`         |
| Classes               | PascalCase             | `EmployeesService`, `CreateEmployeeBodyDto`          |
| Variables / functions | camelCase              | `getEmployeeById`                                    |
| Boolean vars          | auxiliary verb prefix  | `isActive`, `hasPermission`, `isLoading`, `hasError` |
| Constants             | UPPER_SNAKE_CASE       | `MAX_LOGIN_ATTEMPTS`, `PAGINATION`                   |
| DTO suffix            | `BodyDto` / `QueryDto` | `CreateShiftBodyDto`, `GetShiftsQueryDto`            |

- **No magic strings or numbers** — define named constants.
- Use the `function` keyword for standalone functions, not `const`.
- **Use concise syntax for simple statements.**
- **Structure files:** constants, types, exported components/services, subcomponents/helpers.
- **Use descriptive variable names** with auxiliary verbs (e.g., `isLoading`, `hasError`).

## Error Handling and Validation

**Prioritize error handling and edge cases:**

- **Sanitize user input** — validate all inputs via DTOs with class-validator.
- **Handle errors and edge cases at the beginning of functions** — use guard clauses.
- **Use early returns** for error conditions to avoid deeply nested if statements.
- **Place the happy path last** in the function for improved readability.
- **Avoid unnecessary else statements** — use the if-return pattern instead.
- **Use guard clauses** to handle preconditions and invalid states early.
- **Implement proper error logging** — use NestJS Logger or Winston.
- **User-friendly error messages** — throw NestJS exceptions with clear messages.
- **Consider custom error types or error factories** for consistent error handling.

```typescript
// ✅ Good — guard clauses, early returns, happy path last
async function processOrder(orderId: string, userId: string): Promise<Order> {
  // Guard clauses first
  if (!orderId) {
    throw new BadRequestException("Order ID is required");
  }

  const order = await this.orderRepository.findById(orderId);
  if (!order) {
    throw new NotFoundException(`Order ${orderId} not found`);
  }

  if (order.userId !== userId) {
    throw new ForbiddenException("You do not have access to this order");
  }

  if (order.status === ORDER_STATUS.CANCELLED) {
    throw new BadRequestException("Cannot process a cancelled order");
  }

  // Happy path last
  return await this.orderRepository.update({ id: orderId, status: ORDER_STATUS.PROCESSING });
}

// ❌ Bad — nested ifs, else statements
async function processOrder(orderId: string, userId: string): Promise<Order> {
  if (orderId) {
    const order = await this.orderRepository.findById(orderId);
    if (order) {
      if (order.userId === userId) {
        if (order.status !== ORDER_STATUS.CANCELLED) {
          return await this.orderRepository.update({
            id: orderId,
            status: ORDER_STATUS.PROCESSING,
          });
        } else {
          throw new BadRequestException("Cannot process a cancelled order");
        }
      } else {
        throw new ForbiddenException("You do not have access to this order");
      }
    } else {
      throw new NotFoundException(`Order ${orderId} not found`);
    }
  } else {
    throw new BadRequestException("Order ID is required");
  }
}
```

## Project Structure

```
src/modules/[moduleName]/
├── [moduleName].module.ts
├── [moduleName].controller.ts
├── [moduleName].service.ts
├── [moduleName].repository.ts
├── [moduleName].types.ts
└── dto/
    ├── create-[resource]-body.dto.ts
    ├── update-[resource]-body.dto.ts
    └── get-[resource]s-query.dto.ts
```

## Layered Architecture

| Layer                                    | Responsibility                                                  | Must NOT               |
| ---------------------------------------- | --------------------------------------------------------------- | ---------------------- |
| **Controller**                           | HTTP in/out, auth decorators, pagination assembly, Swagger docs | Contain business logic |
| **Service**                              | All business logic, validation, orchestration                   | Touch Prisma directly  |
| **Repository**                           | Prisma DB operations only, query building                       | Contain business logic |
| **Common modules** (WhatsApp, AWS, etc.) | External service wrappers                                       | Contain business logic |

## Controllers — Standard NestJS Decorators

### Multi-Tenant URL Pattern

All endpoints use `/accounts/:accountId/[resource]s` for tenant isolation.

### REST API Conventions

- Use standard HTTP methods: `GET` (read), `POST` (create), `PATCH` (update), `DELETE` (delete)
- Resource-based URLs: `/accounts/:accountId/shifts`, `/accounts/:accountId/employees`
- Plural resource names: `/shifts`, not `/shift`
- Use path parameters for IDs: `/shifts/:shiftId`
- Use query parameters for filtering, sorting, pagination
- Return appropriate HTTP status codes: `200` (OK), `201` (Created), `204` (No Content), `400` (Bad Request), `404` (Not Found)
- HTTP method verbs: `@Get()`, `@Post()`, `@Patch()`, `@Delete()`

### Auth Decorators (no manual `@UseGuards()`)

Global `AuthGuard` is registered via `APP_GUARD`. Use decorators:

- `@AllowAnyAuthenticatedUser()` — any logged-in user (default)
- `@AllowAdminUser()` — admin only
- `@AllowOvertimeUser()` — overtime managers
- `@AllowUnauthenticated()` — public routes
- `@AllowTestToken()` — test token access

```typescript
@ApiTags("Shifts")
@Controller("/accounts/:accountId/shifts")
@AllowAnyAuthenticatedUser()
export class ShiftController {
  constructor(private readonly shiftService: ShiftService) {}

  @Post()
  @ApiOperation({ summary: "Create a new shift" })
  @ApiBody({ type: CreateShiftBodyDto })
  async createShift(
    @Param("accountId") accountId: string,
    @Body() dto: CreateShiftBodyDto,
  ): Promise<Shift> {
    return await this.shiftService.createShift({ accountId, ...dto });
  }
}
```

## Pagination — Cursor-Based

All list endpoints use cursor-based pagination:

```typescript
import { decodeCursor, buildPaginationLinksAndData, PAGINATION } from "src/utils/pagination";

@Get()
async getEmployees(@Param("accountId") accountId: string, @Query() payload: GetEmployeesQueryDto) {
  const pageSize = payload.page?.size ?? PAGINATION.defaultPageSize;
  const cursor = decodeCursor<EmployeeCursor | undefined>({
    defaultValue: undefined,
    pageCursor: payload.page?.cursor,
  });

  const { employees, totalCount } = await this.employeesService.getEmployees({
    filter: { ...payload.filter, accountId, ...cursor?.filter },
    page: { cursor, size: pageSize + 1 },
  });

  return {
    ...buildPaginationLinksAndData<Employee>({
      getItemForCursor(item) {
        return { id: item.id, createdAt: item.createdAt, filter: { ...payload.filter, accountId } };
      },
      pageSize,
      currentCursor: cursor,
      data: employees,
    }),
    totalCount,
  };
}
```

## DTOs — class-validator

```typescript
export class CreateDepartmentBodyDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  name!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  employeeIds?: string[];
}

// Update DTO
export class UpdateDepartmentBodyDto extends PartialType(CreateDepartmentBodyDto) {}
```

## Repositories — Prisma

```typescript
@Injectable()
export class DepartmentRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(params: GetDepartmentsParams): Promise<Department[]> {
    return await this.prisma.department.findMany({
      where: { accountId: params.filter.accountId },
    });
  }

  private toDO(dao: PrismaDepartment): Department {
    return { id: dao.id, name: dao.name, accountId: dao.accountId };
  }
}
```

## Modules

```typescript
@Module({
  imports: [PrismaModule],  // Import PrismaModule, not PrismaService
  controllers: [[Name]Controller],
  providers: [[Name]Service, [Name]Repository],
  exports: [[Name]Service, [Name]Repository],
})
export class [Name]Module {}
```

## Hard Rules

- **No database queries inside loops** — use `findMany`, `createMany`, `updateMany` with `IN` clauses.
- **No business logic in repositories** — DB operations only.
- **No business logic in common/shared modules**.
- Use **NestJS exceptions** (`NotFoundException`, `BadRequestException`) — never raw `throw new Error(...)`.
- Use **TypeDoc** on all public methods.
- **Modules import `PrismaModule`** — never inject `PrismaService` directly.
- **Auth is global** — use decorators, never `@UseGuards(AuthGuard)`.
- **All routes are multi-tenant** — include `accountId` in URL path.
- Guard clauses at beginning of functions — happy path last.
- No unnecessary `else` after a `return`.

## Commands

```bash
npm run lint        # eslint "{src,apps,libs,test}/**/*.ts" --fix
npm run typecheck   # tsc -p ./tsconfig.json --noEmit
npm test            # Unit tests
npm run test:e2e    # E2E tests
```
