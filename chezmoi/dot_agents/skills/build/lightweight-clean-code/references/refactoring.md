# Refactoring into lightweight clean code

Use this when converting heavier code — repository pattern, rich entities/
aggregates, fat controllers or services — into the lightweight style. The goal is
to **move logic inward to the use case and flatten abstractions**, preserving
behaviour at every step. Don't just rename files; relocate responsibility.

## Construct mapping

| You have                                       | It becomes                                                               | Notes                                                                                                                                               |
|------------------------------------------------|--------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|
| `Controller` / route handler with logic        | Thin **primary adapter** + a **use case**                                | Move every business `if` into the use case; the adapter only parses, validates the request, calls the use case, maps the response.                  |
| `XRepository` class / `IXRepository` interface | **Secondary adapter** = plain exported functions                         | `save`, `findById` → `createX`, `retrieveX`. Delete the interface; the function signature is the port. The use case imports the functions directly. |
| ORM entity / `@Entity` class                   | Plain **DTO `type`**                                                     | Drop decorators and methods. Keep persistence config wherever your driver needs it, but the in-code model is a plain shape.                         |
| Rich domain entity / aggregate with methods    | **DTO `type`** + rules in the **use case** + a **domain schema**         | Method bodies that enforce invariants move into use-case guards and the pre-persist schema validation.                                              |
| Value object (`Email`, `Money`, `PostCode`)    | Primitive (or small `type`/branded type) + **schema/`shared` validator** | The class's validation rule becomes a schema constraint or a pure function in `shared/`.                                                            |
| `DomainService`                                | Logic absorbed into the relevant **use case**                            | If genuinely shared across use cases, extract a pure helper in `shared/` — not a stateful service class.                                            |
| Mapper / assembler between entity and DTO      | Usually deleted                                                          | With a single plain shape there's far less to map. Keep only edge mapping (e.g. DB row ↔ DTO) inside the secondary adapter.                         |
| DI container registration / providers          | Direct module imports                                                    | Drop the container. Use cases import secondary-adapter functions by name; tests mock the module (or pass functions as params if you prefer).        |

## Before / after

### Repository class → secondary-adapter functions

**Before**
```ts
export interface ICustomerRepository {
  save(c: Customer): Promise<Customer>;
  findById(id: string): Promise<Customer | null>;
}

@injectable()
export class CustomerRepository implements ICustomerRepository {
  constructor(@inject('Db') private db: Db) {}
  async save(c: Customer) { /* ORM call */ }
  async findById(id: string) { /* ORM call */ }
}
```

**After** — `adapters/secondary/database-adapter/database-adapter.ts`
```ts
import { CustomerAccountDto } from '@dto/customer-account';
import { db } from '@config/db';

export async function createAccount(
  account: CustomerAccountDto
): Promise<CustomerAccountDto> {
  await db.put(account);
  return account;
}

export async function retrieveAccount(id: string): Promise<CustomerAccountDto> {
  return db.get(id);
}
```
No interface, no class, no container. The use case does
`import { createAccount, retrieveAccount } from '@adapters/secondary/database-adapter'`.

### Rich entity → DTO + use-case rules + schema

**Before** — invariants and behaviour live on the class
```ts
export class CustomerAccount {
  private constructor(private props: Props) {}

  static create(props: Props): CustomerAccount {
    if (!props.firstName) throw new Error('first name required');
    return new CustomerAccount(props);
  }

  upgrade() {
    if (this.props.paymentStatus === 'Invalid') throw new Error('payment invalid');
    if (this.props.subscriptionType === 'Upgraded') throw new Error('already upgraded');
    this.props.subscriptionType = 'Upgraded';
  }
}
```

**After** — DTO is a plain shape; rules live in the use case; shape correctness is
guaranteed by validating against the domain schema before persistence.
```ts
// dto/customer-account/customer-account.ts
export type CustomerAccountDto = {
  id: string;
  firstName: string;
  subscriptionType: SubscriptionType;
  paymentStatus: PaymentStatus;
  // ...
};

// use-cases/upgrade-customer-account/upgrade-customer-account.ts
export async function upgradeCustomerAccountUseCase(id: string) {
  const account = await retrieveAccount(id);

  if (account.paymentStatus === PaymentStatus.Invalid)
    throw new PaymentInvalidError('payment invalid');
  if (account.subscriptionType === SubscriptionType.Upgraded)
    throw new SubscriptionAlreadyUpgradedError('already upgraded');

  account.subscriptionType = SubscriptionType.Upgraded;

  schemaValidator(schema, account); // replaces the entity's structural guarantees
  await updateAccount(account);
  return account;
}
```

### Fat controller → thin primary adapter + use case

**Before**
```ts
@Post()
async create(@Body() body: any) {
  if (!body.firstName) throw new BadRequestException();
  const exists = await this.repo.findByName(body.firstName);
  if (exists) throw new ConflictException();
  const saved = await this.repo.save({ ...body, status: 'Valid' });
  await this.bus.emit('created', saved);
  return saved;
}
```

**After** — controller becomes a thin adapter; all rules move into the use case
```ts
// primary adapter
async create(@Body() body: unknown) {
  schemaValidator(inputSchema, body);
  return this.toResponse(await createCustomerAccountUseCase(body as NewCustomerAccountDto));
}

// use case owns the uniqueness rule, the defaulting, persistence and the event
export async function createCustomerAccountUseCase(input: NewCustomerAccountDto) {
  if (await accountExistsByName(input.firstName))
    throw new AccountAlreadyExistsError('account already exists');
  const account = { /* build full dto, defaults */ };
  schemaValidator(schema, account);
  const saved = await createAccount(account);
  await publishEvent(saved, /* ... */);
  return saved;
}
```

## Sequencing a safe refactor

1. **Characterise behaviour first.** If tests are thin, add a use-case-level test
   capturing current behaviour before moving anything.
2. **Create the use case** and move business rules into it from the
   controller/service/entity, one rule at a time, keeping tests green.
3. **Introduce secondary-adapter functions** wrapping the existing repository
   calls; point the use case at them; then delete the repository class/interface.
4. **Flatten the entity** to a DTO once its behaviour has moved out; add the
   domain schema and validate before persist.
5. **Thin the controller** down to a primary adapter last.
6. **Delete** now-dead mappers, interfaces, DI registrations, and base classes.

Keep each step small and behaviour-preserving. The end state should read as:
*adapter parses → use case decides → secondary adapter performs.*
