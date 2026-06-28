---
name: lightweight-clean-code
description: >-
  Write or refactor TypeScript backend code using the "lightweight clean code"
  architecture — a hexagonal/ports-and-adapters style stripped down to three
  layers: primary adapters (transport), use cases (all business logic), and
  secondary adapters (talking to infrastructure). It deliberately drops the
  repository pattern and entity/aggregate/value-object classes, replacing them
  with plain DTOs plus schema validation, while still honouring the underlying
  principles. Use this skill whenever the user asks to build a new feature/slice,
  scaffold a use case, or refactor existing TypeScript backend code (Lambda
  handlers, Express/Nest controllers, services, repositories, domain models)
  toward a cleaner, thinner, use-case-centric structure — even if they don't say
  the exact words "lightweight clean code" but describe wanting use cases,
  primary/secondary adapters, no repositories, or DTOs instead of rich entities.
---

# Lightweight Clean Code

## What this is

A pragmatic take on hexagonal architecture (ports & adapters / onion) for
TypeScript backends. It keeps the strong boundary between business logic and
infrastructure, but throws out the ceremony that usually comes with full Clean
Code / DDD implementations.

The whole picture is three rings of responsibility and a strict one-way flow:

```
  transport in                                       infrastructure out
 (HTTP, queue, ─►  Primary Adapter ─►  Use Case ─►  Secondary Adapter ─► DB / bus /
  schedule)         (handler)          (the brain)   (thin tech wrapper)   API / etc.
```

A request only ever travels **primary adapter → use case → secondary adapter(s)**.
Nothing flows backwards, and adapters never call each other.

## The three lightweight moves

This is what makes it "lightweight" versus textbook clean architecture. When you
write or refactor, these are the decisions that matter most:

1. **All business logic lives in the use case.** There are no domain-model
   classes carrying behaviour. The use case orchestrates the steps *and* enforces
   the business rules (e.g. "you can't upgrade an account that's already
   upgraded"). If you find logic in a handler, a repository, or a model class,
   it belongs in the use case.

2. **No repository pattern.** The use case calls secondary-adapter functions
   directly (`createAccount(...)`, `publishEvent(...)`), imported by name. There
   is no `IRepository` interface, no repository class, no ORM-style abstraction
   layer in between. The exported function signature of the secondary adapter
   *is* the port.

3. **No entity / aggregate / value-object classes — but keep the principles.**
   Data is modelled as plain `type` DTOs and `enum`s, not classes with methods.
   The invariants those classes used to protect are enforced two ways instead:
   business rules in the use case, and **schema validation** of the full object
   before it is persisted. So the object is still "always valid" — just without
   the class machinery.

Hold these moves in tension with the principles they replace. We're removing the
*code constructs*, not the *thinking*: boundaries, invariants, and a single
source of truth for rules all still apply.

## Folder structure (feature-sliced)

Organise by feature, not by technical type. A new capability touches one
use-case folder and one primary-adapter folder, reusing shared secondary
adapters.

```
src/
  adapters/
    primary/
      <feature>/
        <feature>.adapter.ts      # transport handler: parse, validate input, call use case, map result/errors
        <feature>.schema.ts       # validation schema for the *incoming* request shape
    secondary/
      <tech>-adapter/             # e.g. database-adapter, event-adapter, payment-adapter
        <tech>-adapter.ts         # plain exported async functions, one per operation
        index.ts                  # re-export
  use-cases/
    <feature>/
      <feature>.ts                # exports <feature>UseCase(); all business logic
      index.ts                    # re-export
  dto/
    <entity>/<entity>.ts          # plain types + enums (Dto suffix), no classes
  schemas/
    <entity>.schema.ts            # schema for the *full domain object*, validated before persistence
  errors/
    <name>-error.ts               # tiny Error subclasses, one per file
  events/<event-name>.ts          # event metadata (name/source/version) — only if event-driven
  shared/<util>.ts                # pure helpers (date, id, money) — no I/O
  config/config.ts                # configuration access
```

Adapt the names to the stack. The **primary adapter** is whatever receives the
request — a Lambda handler, an Express route handler, a Nest controller method, a
queue consumer. The **secondary adapter** is whatever performs the side effect —
a DynamoDB/Postgres data-access module, an HTTP client, an event publisher. The
architecture is identical regardless; only the edges change.

## Responsibilities at a glance

| Layer             | Does                                                                                                                                   | Must NOT do                                                  |
|-------------------|----------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------|
| Primary adapter   | Parse transport input, validate request shape, call the use case, translate the result and any thrown errors into a transport response | Contain business rules, talk to a database/bus directly      |
| Use case          | Construct the domain object, apply business rules, validate before persisting, call secondary adapters, return a DTO                   | Know about HTTP/transport details, know SDK/driver specifics |
| Secondary adapter | One side effect against one technology, returning/accepting DTOs                                                                       | Contain business rules or decisions                          |
| DTO               | Describe shape (`type` + `enum`)                                                                                                       | Carry behaviour/methods                                      |
| Schema            | Validate a shape                                                                                                                       | —                                                            |

Keep adapters thin and dumb; keep the use case smart. If you're unsure where a
line of code goes, ask "is this a business decision?" If yes → use case. "Is this
how we talk to a specific technology?" → secondary adapter. "Is this how we
read/write the wire?" → primary adapter.

## Conventions

- **Naming.** Use case: `verbNounUseCase`. Primary adapter: `verbNounAdapter`
  (plus an exported `handler`/route binding). Secondary adapter functions are
  plain verbs: `createAccount`, `retrieveAccount`, `publishEvent`. DTOs end in
  `Dto` (`CustomerAccountDto`, and a separate input DTO like
  `NewCustomerAccountDto` for the request payload). Errors are `PascalCaseError`.
- **Wiring / dependency injection.** Default to direct module imports (the
  reference style); tests mock the secondary-adapter module. This is the leanest
  option and keeps call sites clean. If a use case needs to be unit-tested
  without module mocking, passing the secondary-adapter functions in as
  parameters is an acceptable variant — but don't introduce port *interfaces* or
  DI containers; that's the ceremony we're avoiding.
- **Validate twice, on purpose.** Validate the *request shape* at the primary
  adapter (reject garbage early) and validate the *full domain object* in the use
  case right before persistence (guarantee it's always stored valid). The second
  validation is what replaces value-object/entity guards.
- **Errors.** Define small named `Error` subclasses (one per file). Use cases
  `throw` them for rule violations; the primary adapter catches and maps them to
  status codes via a single error handler. Don't return error tuples from use
  cases.
- **Use cases stay pure of transport.** No request/response objects, no status
  codes, no SDK clients inside a use case. It receives a DTO and returns a DTO.
- **Document the primary course.** A short JSDoc on the use case listing the
  numbered happy-path steps is the reference house style and makes intent obvious.

## Writing a new slice

When asked to build a feature, scaffold the slice end to end:

1. **Define the DTOs** in `dto/` — the stored shape and the input shape. Use
   `enum`s for closed value sets. No classes.
2. **Write the use case** in `use-cases/<feature>/`. Construct the object, apply
   rules (throwing named errors), validate against the domain schema, then call
   the secondary adapter(s). Return the DTO. Add the JSDoc primary course.
3. **Add/extend a secondary adapter** for each side effect, as a plain async
   function returning/accepting DTOs.
4. **Write the primary adapter**: validate the incoming request against the input
   schema, call the use case, map success and caught errors to the transport
   response.
5. **Add the schemas** (input + domain) and any **named errors**.
6. **Write tests** for the use case by mocking the secondary adapters and
   asserting behaviour and rule enforcement (see the reference example).

Match whatever conventions and libraries already exist in the user's repo
(validation lib, test runner, transport framework). The architecture is the
constant; the tooling adapts to the project.

## Refactoring existing code

When converting heavier code (repository pattern, rich entities, fat
controllers/services) into this style, the goal is to **move logic inward to the
use case and flatten the abstractions** — not to rename files. Work in this order
and preserve behaviour at every step:

1. Identify the business operation and create a use case for it.
2. Pull business rules *out of* controllers, services, entities, and
   repositories *into* the use case.
3. Replace the repository class with plain secondary-adapter functions; have the
   use case call them directly.
4. Turn entity/aggregate/value-object classes into plain DTO `type`s; move their
   guard logic into use-case rules + a domain schema validated before persist.
5. Reduce the controller/handler to a thin primary adapter.

For the detailed before/after recipes and the construct-mapping table, read
`references/refactoring.md`.

## Anti-patterns (signs it's drifting back to heavy clean code)

- A `Repository` class or `IRepository` interface reappearing.
- Domain classes growing methods, or `new CustomerAccount(...)` with behaviour.
- Business `if`s leaking into handlers or secondary adapters.
- Port interfaces / DI containers wrapping the secondary adapters.
- Use cases importing transport types (request/response) or SDK clients.

If you see these while writing or reviewing, pull the logic back into the use
case and delete the abstraction.

## Reference material

- `references/reference-slice.md` — a complete, annotated worked example (DTO,
  schemas, use case with business rules, primary + secondary adapters, and a
  use-case test). Read this to match the exact house style and to copy structure.
- `references/refactoring.md` — construct-mapping table and before/after
  transformations for converting repository/entity-heavy code into the
  lightweight style.

Read the relevant reference file when you need concrete code to imitate; the body
above is enough for the high-level shape.
