---
name: nestjs-graphql-federation
description: The ultimate architectural standard for Apollo Federation 2.0 with NestJS, Subgraphs, @key Entities, DataLoader N+1 Prevention, and Supergraph Gateway Orchestration.
author: Diego Villanueva
trigger: When building GraphQL subgraphs in NestJS, implementing Apollo Federation 2.0, resolving @key entities, or optimizing resolvers with DataLoader.
---

# Enterprise NestJS Apollo Federation 2.0 Architecture

Apollo Federation 2.0 allows modular domain teams to build autonomous **GraphQL Subgraphs** in NestJS while presenting a unified, schema-composed **Supergraph Gateway** to client applications.

---

## 1. Subgraph Configuration with `@nestjs/graphql`

```bash
npm install @nestjs/graphql @nestjs/apollo @apollo/subgraph graphql dataloader
```

```typescript
// src/app.module.ts (Users Subgraph)
import { Module } from '@nestjs/common';
import { GraphQLModule } from '@nestjs/graphql';
import { ApolloFederationDriver, ApolloFederationDriverConfig } from '@nestjs/apollo';
import { UsersModule } from './modules/users/users.module';

@Module({
  imports: [
    GraphQLModule.forRoot<ApolloFederationDriverConfig>({
      driver: ApolloFederationDriver,
      autoSchemaFile: {
        federation: 2, // Apollo Federation 2.0 Spec
      },
    }),
    UsersModule,
  ],
})
export class AppModule {}
```

---

## 2. Federated Entity Definition with `@Directive` (`@key`)

```typescript
// src/modules/users/entities/user.entity.ts
import { ObjectType, Field, ID, Directive } from '@nestjs/graphql';

@ObjectType()
@Directive('@key(fields: "id")') // Federated Primary Key
export class User {
  @Field(() => ID)
  id: string;

  @Field()
  email: string;

  @Field()
  fullName: string;
}
```

---

## 3. Resolving Federated Entities & Reference Resolution

```typescript
// src/modules/users/resolvers/users.resolver.ts
import { Resolver, Query, Args, ResolveReference } from '@nestjs/graphql';
import { User } from '../entities/user.entity';
import { UsersService } from '../services/users.service';

@Resolver(() => User)
export class UsersResolver {
  constructor(private readonly usersService: UsersService) {}

  @Query(() => User, { name: 'user' })
  async getUser(@Args('id') id: string): Promise<User> {
    return this.usersService.findById(id);
  }

  // Called automatically by Apollo Gateway when another subgraph references User
  @ResolveReference()
  async resolveReference(reference: { __typename: string; id: string }): Promise<User> {
    return this.usersService.findById(reference.id);
  }
}
```

---

## 4. DataLoader Pattern (Solving the N+1 Query Problem)

```typescript
// src/modules/users/dataloaders/user.loader.ts
import { Injectable, Scope } from '@nestjs/common';
import DataLoader from 'dataloader';
import { UsersService } from '../services/users.service';
import { User } from '../entities/user.entity';

@Injectable({ scope: Scope.REQUEST })
export class UserDataLoader {
  public readonly batchUsers = new DataLoader<string, User>(async (userIds: readonly string[]) => {
    // 1 single SQL query `WHERE id IN (...)` for 100 items instead of 100 individual queries!
    const users = await this.usersService.findByIds([...userIds]);
    const userMap = new Map(users.map((u) => [u.id, u]));
    return userIds.map((id) => userMap.get(id)!);
  });

  constructor(private readonly usersService: UsersService) {}
}
```

---

**Execution Protocol**
1. **Always use DataLoader for nested GraphQL fields**: Prevents fatal N+1 database queries.
2. **Implement `@ResolveReference()` on all federated entities**: Enables cross-subgraph data composition.
3. **Use Apollo Federation 2.0 directives**: `@shareable`, `@inaccessible`, `@override` for clean schema governance.
