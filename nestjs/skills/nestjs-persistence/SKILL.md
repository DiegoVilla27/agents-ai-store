---
name: nestjs-persistence
description: >
  Professional persistence patterns: Repository Pattern and Data Mappers.
  Trigger: When implementing database access, ORM integration, or data mapping.
metadata:
  author: Diego Villanueva
  version: "1.0"
---

# NestJS Persistence & ORM Mastery

## 🏛️ The Repository Pattern

The Infrastructure layer must implement the Domain ports (interfaces).

### Repository Interface (Domain)
```typescript
export interface IUserRepository {
  findById(id: string): Promise<User | null>;
  save(user: User): Promise<void>;
}
```

### Prisma Implementation (Infrastructure)
```typescript
@Injectable()
export class PrismaUserRepository implements IUserRepository {
  constructor(private prisma: PrismaService) {}
  
  async findById(id: string): Promise<User | null> {
    const record = await this.prisma.user.findUnique({ where: { id } });
    return record ? UserMapper.toDomain(record) : null;
  }
}
```

## 🔄 Data Mappers (Domain <-> Persistence)

Never leak ORM entities (Prisma/TypeORM) into your business logic.

```typescript
// ✅ ALWAYS
export class UserMapper {
  static toDomain(raw: any): User {
    return new User({
      id: raw.id,
      email: raw.email,
      // map other fields
    });
  }
  
  static toPersistence(user: User): any {
    return {
      id: user.id,
      email: user.email,
    };
  }
}
```

## 🚀 Performance
- Use **Dataloader** for GraphQL to solve the N+1 problem.
- Always use **Transactions** for operations involving multiple entities.
