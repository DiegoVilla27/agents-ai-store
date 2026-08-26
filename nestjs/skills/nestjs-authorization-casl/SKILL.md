---
name: nestjs-authorization-casl
description: The ultimate architectural standard for Attribute-Based Access Control (ABAC) and Granular Permissions in NestJS with CASL, @CheckPolicies(), and AbilityFactory.
author: Diego Villanueva
trigger: When implementing fine-grained permissions, Attribute-Based Access Control (ABAC), policy guards, or CASL authorization rules in NestJS.
---

# Enterprise NestJS Authorization with CASL (ABAC)

Role-Based Access Control (RBAC) (e.g. `USER`, `ADMIN`) fails when rules depend on resource ownership (e.g. *"A user can only edit an article if they are the author, unless the article is already published"*). **Attribute-Based Access Control (ABAC)** with **CASL** solves this cleanly.

---

## 1. Defining Actions & Subjects with CASL

```bash
npm install @casl/ability
```

```typescript
// src/common/casl/casl.types.ts
import { InferSubjects } from '@casl/ability';
import { UserEntity } from '@/modules/users/entities/user.entity';
import { ArticleEntity } from '@/modules/articles/entities/article.entity';

export enum Action {
  Manage = 'manage', // Wildcard for all actions
  Create = 'create',
  Read = 'read',
  Update = 'update',
  Delete = 'delete',
}

export type Subjects = InferSubjects<typeof ArticleEntity | typeof UserEntity> | 'all';
```

---

## 2. The CaslAbilityFactory (Rule Definition)

```typescript
// src/common/casl/casl-ability.factory.ts
import { AbilityBuilder, createMongoAbility, MongoAbility, ExtractSubjectType } from '@casl/ability';
import { Injectable } from '@nestjs/common';
import { Action, Subjects } from './casl.types';
import { UserEntity } from '@/modules/users/entities/user.entity';
import { ArticleEntity } from '@/modules/articles/entities/article.entity';

export type AppAbility = MongoAbility<[Action, Subjects]>;

@Injectable()
export class CaslAbilityFactory {
  createForUser(user: UserEntity): AppAbility {
    const { can, cannot, build } = new AbilityBuilder<AppAbility>(createMongoAbility);

    if (user.role === 'ADMIN') {
      can(Action.Manage, 'all'); // Admin can do anything
    } else {
      // 1. Anyone can read published articles
      can(Action.Read, ArticleEntity, { isPublished: true });

      // 2. Authors can read their own drafts
      can(Action.Read, ArticleEntity, { authorId: user.id });

      // 3. Authors can update their own unpublished articles
      can(Action.Update, ArticleEntity, { authorId: user.id, isPublished: false });

      // 4. Cannot delete published articles unless admin
      cannot(Action.Delete, ArticleEntity, { isPublished: true });
    }

    return build({
      detectSubjectType: (item) => item.constructor as ExtractSubjectType<Subjects>,
    });
  }
}
```

---

## 3. Policy Decorator & PoliciesGuard

```typescript
// src/common/casl/policy-handler.ts
import { AppAbility } from './casl-ability.factory';

interface IPolicyHandler {
  handle(ability: AppAbility): boolean;
}

type PolicyHandlerCallback = (ability: AppAbility) => boolean;
export type PolicyHandler = IPolicyHandler | PolicyHandlerCallback;
```

```typescript
// src/common/casl/check-policies.decorator.ts
import { SetMetadata } from '@nestjs/common';
import { PolicyHandler } from './policy-handler';

export const CHECK_POLICIES_KEY = 'check_policy';
export const CheckPolicies = (...handlers: PolicyHandler[]) =>
  SetMetadata(CHECK_POLICIES_KEY, handlers);
```

```typescript
// src/common/casl/policies.guard.ts
import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { CaslAbilityFactory } from './casl-ability.factory';
import { CHECK_POLICIES_KEY } from './check-policies.decorator';
import { PolicyHandler } from './policy-handler';

@Injectable()
export class PoliciesGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private caslAbilityFactory: CaslAbilityFactory
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const policyHandlers =
      this.reflector.get<PolicyHandler[]>(CHECK_POLICIES_KEY, context.getHandler()) || [];

    if (policyHandlers.length === 0) return true;

    const { user } = context.switchToHttp().getRequest();
    if (!user) throw new ForbiddenException('User context missing');

    const ability = this.caslAbilityFactory.createForUser(user);

    const isAllowed = policyHandlers.every((handler) => {
      if (typeof handler === 'function') return handler(ability);
      return handler.handle(ability);
    });

    if (!isAllowed) {
      throw new ForbiddenException('You do not have permission to execute this operation');
    }

    return true;
  }
}
```

---

## 4. Protecting Endpoints with `@CheckPolicies()`

```typescript
// src/modules/articles/controllers/articles.controller.ts
import { Controller, Post, Body, UseGuards, Param, Patch } from '@nestjs/common';
import { CheckPolicies } from '@/common/casl/check-policies.decorator';
import { PoliciesGuard } from '@/common/casl/policies.guard';
import { Action } from '@/common/casl/casl.types';
import { ArticleEntity } from '../entities/article.entity';

@Controller('articles')
@UseGuards(PoliciesGuard)
export class ArticlesController {
  @Patch(':id')
  @CheckPolicies((ability) => ability.can(Action.Update, ArticleEntity))
  async updateArticle(@Param('id') id: string, @Body() updateDto: any) {
    return this.articlesService.update(id, updateDto);
  }
}
```

---

**Execution Protocol**
1. **Never hardcode permissions in controller bodies**: Use declarative `@CheckPolicies()` guards.
2. **Always test abilities with unit tests**: Test matrices of User Roles $\times$ Resource States.
3. **Use subject instances for runtime checks**: Pass the loaded entity instance into `ability.can(Action.Update, articleInstance)` when ownership logic is checked.
