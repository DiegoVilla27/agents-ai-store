---
name: web-graphql-core
description: The ultimate architectural standard for GraphQL APIs, Schema Design, Resolvers, Real-Time Subscriptions, and N+1 Problem Batching with DataLoader.
author: Diego Villanueva
trigger: When building GraphQL APIs, designing schemas, implementing resolvers, solving N+1 query problems with DataLoader, or handling WebSocket subscriptions.
---

# Enterprise GraphQL Architecture (Schema Design & DataLoader)

GraphQL provides clients with the exact data requested, eliminating over-fetching and under-fetching. An Enterprise Staff Engineer designs scalable GraphQL servers with **Strict Schema Typing**, **DataLoader Batching (solving the $N+1$ problem)**, and **WebSocket Subscriptions**.

---

## 1. Enterprise GraphQL Schema Design (SDL)

```graphql
# schema.graphql
scalar DateTime

enum OrderStatus {
  PENDING
  PROCESSING
  SHIPPED
  DELIVERED
  CANCELLED
}

type User {
  id: ID!
  name: String!
  email: String!
  orders(limit: Int = 10): [Order!]!
  createdAt: DateTime!
}

type Order {
  id: ID!
  userId: ID!
  user: User!
  totalAmount: Float!
  status: OrderStatus!
  createdAt: DateTime!
}

input CreateOrderInput {
  userId: ID!
  totalAmount: Float!
}

type Query {
  me: User
  user(id: ID!): User
  order(id: ID!): Order
}

type Mutation {
  createOrder(input: CreateOrderInput!): Order!
}

type Subscription {
  orderStatusUpdated(orderId: ID!): Order!
}
```

---

## 2. Solving the $N+1$ Query Problem with DataLoader

Without DataLoader, fetching 50 orders and their respective users results in 1 query for orders + 50 separate queries for each user ($N+1$ bottleneck). **DataLoader** batches these 50 lookups into a single `SELECT * FROM users WHERE id IN (...)` statement.

```typescript
// dataloaders/user.loader.ts
import DataLoader from 'dataloader';
import { db } from '@/database';

export function createUserLoader() {
  return new DataLoader<string, User>(async (userIds) => {
    // 1. Single batched SQL query across all concurrent resolver calls!
    const users = await db.query.users.findMany({
      where: (user, { inArray }) => inArray(user.id, userIds as string[]),
    });

    // 2. Map database results back to the exact order of requested keys
    const userMap = new Map(users.map((u) => [u.id, u]));
    return userIds.map((id) => userMap.get(id) ?? new Error(`User not found: ${id}`));
  });
}
```

---

## 3. Resolvers Implementation with Context & Loaders

```typescript
// resolvers/order.resolver.ts
import type { GraphQLContext } from '@/types/context';

export const orderResolvers = {
  Query: {
    order: async (_: unknown, { id }: { id: string }, ctx: GraphQLContext) => {
      return ctx.db.findOrderById(id);
    },
  },

  Order: {
    // Field Resolver: Uses DataLoader for efficient user population
    user: async (parent: { userId: string }, _: unknown, ctx: GraphQLContext) => {
      return ctx.loaders.userLoader.load(parent.userId);
    },
  },

  Mutation: {
    createOrder: async (_: unknown, { input }: { input: CreateOrderInput }, ctx: GraphQLContext) => {
      if (!ctx.currentUser) throw new Error('Unauthenticated');
      const order = await ctx.db.createOrder(input);
      // Publish event for real-time subscribers
      ctx.pubsub.publish(`ORDER_STATUS_${order.id}`, { orderStatusUpdated: order });
      return order;
    },
  },
};
```

---

## 4. Query Complexity & Depth Limiting (DoS Protection)

Malicious clients can craft infinitely nested circular queries (`user -> orders -> user -> orders`) to crash servers.

**✅ ALWAYS** enforce depth and complexity limits:

```typescript
import { createComplexityLimitRule } from 'graphql-validation-complexity';
import depthLimit from 'graphql-depth-limit';

const server = new ApolloServer({
  schema,
  validationRules: [
    depthLimit(6), // Max query nesting depth = 6
    createComplexityLimitRule(1000), // Max computed cost score = 1000
  ],
});
```

---

**Execution Protocol**
1. **Always instantiate DataLoaders per request in context**: Never share a global DataLoader across requests to prevent cross-tenant data caching leaks.
2. **Always enforce Query Depth and Complexity limits**: Protects backend from recursive GraphQL denial-of-service attacks.
3. **Use custom scalars (`DateTime`, `JSON`) with explicit validation**: Prevents invalid date strings from passing runtime checks.
