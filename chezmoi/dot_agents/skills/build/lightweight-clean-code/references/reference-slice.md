# Reference slice: `create-customer-account`

A complete worked example of one feature in the lightweight clean code style,
adapted from Lee Gilmore's `serverless-clean-code-experience`. Use it to match
the house style and copy structure. The transport here is AWS Lambda + API
Gateway, but the **shape is framework-agnostic** — for Express/Nest, the primary
adapter becomes a controller/route handler and the rest is identical.

Flow for this feature: `primary adapter → use case → (database adapter, event adapter)`.

## Contents
- [DTOs](#dtos) — plain types + enums
- [Domain schema](#domain-schema) — validates the full object before persistence
- [Input schema](#input-schema) — validates the incoming request at the edge
- [Use case](#use-case) — all the business logic
- [Secondary adapters](#secondary-adapters) — thin tech wrappers
- [Primary adapter](#primary-adapter) — thin transport handler
- [Use-case test](#use-case-test) — mock the secondary adapters

---

## DTOs

`dto/customer-account/customer-account.ts` — plain shapes. Note the separate
*input* DTO (`NewCustomerAccountDto`) for the request payload vs the stored
`CustomerAccountDto`. No classes, no methods.

```ts
import { CustomerAddressDto } from '@dto/customer-address';
import { CustomerPlaylistDto } from '@dto/customer-playlist';

export enum SubscriptionType {
  Basic = 'Basic',
  Upgraded = 'Upgraded',
}

export enum PaymentStatus {
  Valid = 'Valid',
  Invalid = 'Invalid',
}

// the full stored shape
export type CustomerAccountDto = {
  id: string;
  created: string;
  updated: string;
  firstName: string;
  surname: string;
  subscriptionType: SubscriptionType;
  paymentStatus: PaymentStatus;
  playlists: CustomerPlaylistDto[];
  customerAddress: CustomerAddressDto;
};

// the request payload shape — only what the caller supplies
export type NewCustomerAccountDto = {
  firstName: string;
  surname: string;
  customerAddress: CustomerAddressDto;
};
```

## Domain schema

`schemas/customer-account.schema.ts` — JSON Schema (AJV) for the **whole** object.
The use case validates against this right before persisting, so storage is always
valid. This is what replaces value-object/entity invariants. Compose from smaller
schemas where it helps.

```ts
import { schema as addressSchema } from '@schemas/customer-address.schema';
import { schema as playlistSchema } from '@schemas/customer-playlist.schema';

export const schema = {
  type: 'object',
  required: [
    'id', 'firstName', 'surname', 'paymentStatus', 'subscriptionType',
    'playlists', 'created', 'updated', 'customerAddress',
  ],
  maxProperties: 9,
  minProperties: 9,
  properties: {
    id: { type: 'string' },
    firstName: { type: 'string', pattern: '^[a-zA-Z]+$' },
    surname: { type: 'string', pattern: '^[a-zA-Z]+$' },
    paymentStatus: { type: 'string', enum: ['Valid', 'Invalid'] },
    subscriptionType: { type: 'string', enum: ['Basic', 'Upgraded'] },
    created: { type: 'string' },
    updated: { type: 'string' },
    playlists: { type: 'array', items: { ...playlistSchema } },
    customerAddress: { ...addressSchema },
  },
};
```

## Input schema

`adapters/primary/create-customer-account/create-customer-account.schema.ts` —
validates only the request payload, at the edge. Tighter than the domain schema
(e.g. exactly the three input fields).

```ts
export const schema = {
  type: 'object',
  required: ['firstName', 'surname', 'customerAddress'],
  maxProperties: 3,
  minProperties: 3,
  properties: {
    firstName: { type: 'string', pattern: '^[a-zA-Z]+$' },
    surname: { type: 'string', pattern: '^[a-zA-Z]+$' },
    customerAddress: {
      type: 'object',
      required: ['addressLineOne', 'postCode'],
      properties: {
        addressLineOne: { type: 'string', pattern: '^[a-zA-Z0-9 _.-]+$' },
        postCode: { type: 'string', pattern: '^[a-zA-Z0-9 _.-]+$' },
        // ...other optional address lines
      },
    },
  },
};
```

## Use case

`use-cases/create-customer-account/create-customer-account.ts` — the brain.
Receives an input DTO, builds the full object, validates it, calls the secondary
adapters directly, returns the DTO. Note the JSDoc "Primary course". For a
business-rule example see [below](#business-rules-example).

```ts
import * as customerAccountCreatedEvent from '@events/customer-account-created';

import {
  CustomerAccountDto,
  NewCustomerAccountDto,
  PaymentStatus,
  SubscriptionType,
} from '@dto/customer-account';

import { createAccount } from '@adapters/secondary/database-adapter';
import { publishEvent } from '@adapters/secondary/event-adapter';
import { getISOString } from '@shared/date-utils';
import { logger } from '@packages/logger';
import { schema } from '@schemas/customer-account.schema';
import { schemaValidator } from '@packages/schema-validator';
import { v4 as uuid } from 'uuid';

/**
 * Create a new Customer Account
 * Input: NewCustomerAccountDto
 * Output: CustomerAccountDto
 *
 * Primary course:
 *  1. Build the new customer account
 *  2. Validate it before persisting
 *  3. Persist it via the database adapter
 *  4. Publish a CustomerAccountCreated event
 */
export async function createCustomerAccountUseCase(
  newCustomer: NewCustomerAccountDto
): Promise<CustomerAccountDto> {
  const createdDate = getISOString();

  const newCustomerAccount: CustomerAccountDto = {
    id: uuid(),
    created: createdDate,
    updated: createdDate,
    subscriptionType: SubscriptionType.Basic,
    paymentStatus: PaymentStatus.Valid,
    playlists: [],
    firstName: newCustomer.firstName,
    surname: newCustomer.surname,
    customerAddress: newCustomer.customerAddress,
  };

  // validate the full object so what we store is always valid
  schemaValidator(schema, newCustomerAccount);

  const createdAccount = await createAccount(newCustomerAccount);
  logger.info(`customer account created for ${createdAccount.id}`);

  await publishEvent(
    createdAccount,
    customerAccountCreatedEvent.eventName,
    customerAccountCreatedEvent.eventSource,
    customerAccountCreatedEvent.eventVersion,
    createdDate
  );

  return createdAccount;
}
```

### Business-rules example

How rules are enforced in the use case (from `upgrade-customer-account`). Rules
are plain guards that `throw` named errors; the "validate before persist" step
keeps the object valid.

```ts
export async function upgradeCustomerAccountUseCase(
  id: string
): Promise<CustomerAccountDto> {
  const updatedDate = getISOString();

  const customerAccount = await retrieveAccount(id);

  if (customerAccount.paymentStatus === PaymentStatus.Invalid) {
    throw new PaymentInvalidError('Payment is invalid - unable to upgrade');
  }
  if (customerAccount.subscriptionType === SubscriptionType.Upgraded) {
    throw new SubscriptionAlreadyUpgradedError(
      'Subscription is already upgraded - unable to upgrade'
    );
  }

  customerAccount.subscriptionType = SubscriptionType.Upgraded;
  customerAccount.updated = updatedDate;

  schemaValidator(schema, customerAccount); // still valid after the change
  await updateAccount(customerAccount);
  // ...publish event, return dto
  return customerAccount;
}
```

## Secondary adapters

`adapters/secondary/database-adapter/database-adapter.ts` — plain async functions,
one per operation, accepting/returning DTOs. No repository class. The use case
imports these by name. Note: the only "decisions" here are technical (table name,
SDK call) — never business rules.

```ts
import * as AWS from 'aws-sdk';
import { CustomerAccountDto } from '@dto/customer-account';
import { config } from '@config/config';

const dynamoDb = new AWS.DynamoDB.DocumentClient();

export async function createAccount(
  customerAccount: CustomerAccountDto
): Promise<CustomerAccountDto> {
  await dynamoDb
    .put({ TableName: config.get('tableName'), Item: customerAccount })
    .promise();
  return customerAccount;
}

export async function retrieveAccount(id: string): Promise<CustomerAccountDto> {
  const { Item } = await dynamoDb
    .get({ TableName: config.get('tableName'), Key: { id } })
    .promise();
  return { ...(Item as CustomerAccountDto) };
}
```

`adapters/secondary/event-adapter/event-adapter.ts` follows the same idea —
one `publishEvent(...)` function wrapping the bus client.

> **Other stacks:** for Postgres this file would wrap a `pg`/Prisma/Knex call;
> for an outbound HTTP integration it would wrap `fetch`/axios. Same signature
> style (DTO in, DTO out), still no repository class.

## Primary adapter

`adapters/primary/create-customer-account/create-customer-account.adapter.ts` —
thin. Validate the request, call the use case, map success/errors to the response.
All business logic is elsewhere.

```ts
import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { NewCustomerAccountDto, CustomerAccountDto } from '@dto/customer-account';
import { ValidationError } from '@errors/validation-error';
import { createCustomerAccountUseCase } from '@use-cases/create-customer-account';
import { errorHandler } from '@packages/apigw-error-handler';
import { schema } from './create-customer-account.schema';
import { schemaValidator } from '@packages/schema-validator';

export const createCustomerAccountAdapter = async ({
  body,
}: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    if (!body) throw new ValidationError('no body');

    const customerAccount: NewCustomerAccountDto = JSON.parse(body);
    schemaValidator(schema, customerAccount); // validate request shape at the edge

    const created: CustomerAccountDto =
      await createCustomerAccountUseCase(customerAccount);

    return { statusCode: 201, body: JSON.stringify(created) };
  } catch (error) {
    return errorHandler(error); // maps named errors -> status codes
  }
};

// transport/observability wiring lives only here (e.g. middy + powertools)
export const handler = createCustomerAccountAdapter;
```

> **Express equivalent:** `export async function createCustomerAccount(req, res)`
> that does `schemaValidator(schema, req.body)`, `await createCustomerAccountUseCase(req.body)`,
> `res.status(201).json(created)`, with a `catch` delegating to error middleware.

## Named error

`errors/validation-error.ts` — tiny, one per file, set `name`.

```ts
export class ValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ValidationError';
  }
}
```

## Use-case test

Mock the secondary adapters; assert behaviour and rule enforcement. The use case
is trivially testable precisely because it has no transport or SDK concerns.

```ts
import * as databaseAdapter from '@adapters/secondary/database-adapter/database-adapter';
import * as eventAdapter from '@adapters/secondary/event-adapter/event-adapter';
import { createCustomerAccountUseCase } from '@use-cases/create-customer-account/create-customer-account';

describe('create-customer-account-use-case', () => {
  beforeEach(() => {
    jest.spyOn(databaseAdapter, 'createAccount').mockResolvedValue(customerAccountDto);
    jest.spyOn(eventAdapter, 'publishEvent').mockResolvedValue();
  });

  it('throws when the input is invalid', async () => {
    newCustomerAccountDto.firstName = '±';
    await expect(
      createCustomerAccountUseCase(newCustomerAccountDto)
    ).rejects.toThrow();
  });

  it('publishes the created event', async () => {
    await createCustomerAccountUseCase(newCustomerAccountDto);
    expect(eventAdapter.publishEvent).toHaveBeenCalled();
  });
});
```
