---
name: nestjs-openapi-docs
description: The ultimate architectural standard for NestJS OpenAPI (Swagger) Automated AST Metadata Extraction, Perfect Endpoint Documentation, Security Definitions, and Client Generation.
author: Diego Villanueva
trigger: When configuring Swagger UI, documenting REST controllers, building DTOs, or standardizing API contracts.
---

# NestJS OpenAPI (Swagger) Architecture

The API Contract is the most critical asset of a backend team. If your documentation is out of sync with your code, the frontend will break. 

NestJS provides a world-class OpenAPI (Swagger) integration that generates documentation directly from your TypeScript code. You must never write raw OpenAPI JSON or YAML files manually.

## 1. The Swagger CLI Plugin (The Ultimate Secret)

By default, to make a DTO property appear in Swagger, you have to decorate it with `@ApiProperty()`. This is tedious and pollutes the code.

You MUST enable the `@nestjs/swagger` CLI plugin in your `nest-cli.json`. It hooks into the TypeScript compiler (AST) and automatically infers `@ApiProperty()` for every single class property based on its TypeScript type!

```json
// ✅ ALWAYS: Enable the Swagger CLI Plugin (nest-cli.json)
{
  "compilerOptions": {
    "plugins": [
      {
        "name": "@nestjs/swagger",
        "options": {
          "classValidatorShim": true,
          "introspectComments": true // Uses your /** comments */ as descriptions!
        }
      }
    ]
  }
}
```
*With this enabled, a simple `email: string` field is instantly added to Swagger without any decorators.*

## 2. Advanced DTO Documentation

While the CLI plugin does 90% of the work, you still need `@ApiProperty()` for complex types like Enums, Arrays of classes, or to provide examples (which frontend developers rely heavily upon).

```typescript
// ✅ ALWAYS: Use ApiProperty for explicit examples and complex types
import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsEnum, MinLength } from 'class-validator';

export enum UserRole {
  ADMIN = 'ADMIN',
  USER = 'USER',
}

export class CreateUserDto {
  @IsEmail()
  @ApiProperty({ example: 'john.doe@acme.com', description: 'The corporate email address' })
  email: string;

  @MinLength(8)
  @ApiProperty({ example: 'Str0ngP@ssw0rd!' })
  password: string;

  @IsEnum(UserRole)
  @ApiProperty({ enum: UserRole, default: UserRole.USER })
  role: UserRole;
}

// Global Error DTO for standardizing error responses
export class ErrorResponseDto {
  @ApiProperty({ example: 400 })
  statusCode: number;

  @ApiProperty({ example: 'Validation failed' })
  message: string | string[];

  @ApiProperty({ example: 'Bad Request' })
  error: string;
}
```

## 3. Perfect Endpoint Documentation (The Gold Standard)

Controllers must be strictly and exhaustively documented. The frontend developer should never have to ask you "what does this return if it fails?".

You MUST document every possible parameter (Query, Param, Header) and every possible HTTP response code (200, 201, 400, 401, 403, 404, 500).

```typescript
// ✅ ALWAYS: The "Perfect Endpoint" Documentation Standard
import { Controller, Get, Post, Body, Param, Query, Headers } from '@nestjs/common';
import { 
  ApiTags, 
  ApiOperation, 
  ApiOkResponse, 
  ApiCreatedResponse, 
  ApiBadRequestResponse, 
  ApiUnauthorizedResponse,
  ApiForbiddenResponse,
  ApiNotFoundResponse,
  ApiInternalServerErrorResponse,
  ApiParam,
  ApiQuery,
  ApiHeader,
  ApiBearerAuth 
} from '@nestjs/swagger';

@ApiTags('Users') // Groups all routes in this controller under "Users"
@ApiBearerAuth() // Indicates this controller requires the JWT configured in main.ts
@Controller('users')
export class UsersController {
  
  @Get(':id')
  @ApiOperation({ 
    summary: 'Retrieve a User by ID', 
    description: 'Fetches detailed profile information for a specific corporate user. Requires ADMIN privileges.' 
  })
  // Inputs
  @ApiParam({ name: 'id', description: 'The UUID of the user', example: '123e4567-e89b-12d3-a456-426614174000' })
  @ApiQuery({ name: 'includeDetails', required: false, type: Boolean, description: 'Include nested address relationships' })
  @ApiHeader({ name: 'x-tenant-id', required: true, description: 'The enterprise tenant identifier' })
  // Success Responses
  @ApiOkResponse({ description: 'The user was successfully found.', type: UserResponseDto })
  // Error Responses (MANDATORY)
  @ApiBadRequestResponse({ description: 'Invalid UUID format supplied.', type: ErrorResponseDto })
  @ApiUnauthorizedResponse({ description: 'Missing or invalid JWT token.', type: ErrorResponseDto })
  @ApiForbiddenResponse({ description: 'User does not have ADMIN privileges.', type: ErrorResponseDto })
  @ApiNotFoundResponse({ description: 'No user found with the provided ID.', type: ErrorResponseDto })
  @ApiInternalServerErrorResponse({ description: 'Database connectivity failure.', type: ErrorResponseDto })
  getUser(
    @Param('id') id: string,
    @Query('includeDetails') includeDetails: boolean,
    @Headers('x-tenant-id') tenantId: string
  ) {
    return this.usersService.findById(id, includeDetails, tenantId);
  }
}
```

### 3.1 Composite Decorators (DRY Documentation)

Documenting 5 errors per endpoint clutters the code. You MUST use NestJS's `applyDecorators` to create a custom composite decorator for standard errors.

```typescript
// ✅ ALWAYS: Create a composite decorator for repetitive error documentation
import { applyDecorators } from '@nestjs/common';
import { ApiBadRequestResponse, ApiUnauthorizedResponse, ApiInternalServerErrorResponse } from '@nestjs/swagger';

export function ApiStandardErrors() {
  return applyDecorators(
    ApiBadRequestResponse({ description: 'Invalid input data (Validation Error).', type: ErrorResponseDto }),
    ApiUnauthorizedResponse({ description: 'Missing or invalid JWT.', type: ErrorResponseDto }),
    ApiInternalServerErrorResponse({ description: 'Internal server error.', type: ErrorResponseDto }),
  );
}

// Usage in Controller:
@Post()
@ApiOperation({ summary: 'Create a user' })
@ApiCreatedResponse({ type: UserResponseDto })
@ApiStandardErrors() // Inserts the 400, 401, and 500 documentation instantly!
create(@Body() dto: CreateUserDto) { ... }
```

## 4. Security Definitions (JWT)

If your API requires authentication, you must configure Swagger so the "Authorize" button appears. Otherwise, developers cannot test protected routes via the UI.

```typescript
// ✅ ALWAYS: Configure Security Definitions in main.ts
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  const config = new DocumentBuilder()
    .setTitle('Acme Enterprise API')
    .setDescription('The core backend services for Acme Corp')
    .setVersion('1.0')
    .addBearerAuth(
      { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' },
      'access-token', // This name must match the parameter in @ApiBearerAuth('access-token')
    )
    .build();

  const document = SwaggerModule.createDocument(app, config);
  
  // Hide Swagger in production environments!
  if (process.env.NODE_ENV !== 'production') {
    SwaggerModule.setup('docs', app, document);
  }

  await app.listen(3000);
}
```

## 5. Client Generation (The Endgame)

The entire purpose of OpenAPI in NestJS is not just to have a pretty web page (`/docs`). The goal is **Code Generation**.

You MUST use tools like `Orval` or `OpenAPI Generator` on the frontend (React/Next.js). These tools read the `swagger-spec.json` generated by NestJS and instantly create TypeScript interfaces and `TanStack Query` hooks for every single endpoint.

```bash
// Example frontend configuration (orval.config.js)
module.exports = {
  acmeApi: {
    input: 'http://localhost:3000/docs-json', // Read directly from NestJS
    output: {
      mode: 'tags-split',
      target: 'src/api/endpoints',
      client: 'react-query', // Generates useCreateUserMutation() automatically!
    },
  },
};
```

---

**Execution Protocol**
1. **Never expose `/docs` in Production**: The Swagger UI exposes your entire attack surface to hackers. Wrap the `SwaggerModule.setup()` in an environment check (`NODE_ENV !== 'production'`) or protect the route with basic auth if it must be public.
2. **Mapped Types for DTOs**: To avoid duplicating code for Update endpoints, use `@nestjs/swagger` mapped types (`PartialType`, `PickType`, `OmitType`). Do NOT use the ones from `@nestjs/mapped-types`, or the Swagger plugin won't be able to read the inherited properties.
