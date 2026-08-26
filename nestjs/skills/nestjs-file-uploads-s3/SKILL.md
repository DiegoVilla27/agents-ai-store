---
name: nestjs-file-uploads-s3
description: The ultimate architectural standard for Secure Multipart File Uploads in NestJS with FileInterceptor, AWS S3 / Cloudflare R2 Streaming, and Magic Number MIME Validation.
author: Diego Villanueva
trigger: When handling file/image uploads in NestJS, streaming to AWS S3 or Cloudflare R2, validating buffer magic numbers, or configuring FileInterceptor.
---

# Enterprise NestJS Secure File Upload Architecture (S3 & R2)

Handling user uploads securely requires strict file size boundaries, true binary **Magic Number verification** (preventing `.exe` disguised as `.png`), and streaming directly to cloud object storage (**AWS S3 / Cloudflare R2**) without saving ephemeral files to container disks.

---

## 1. Magic Number Binary Header Validator

```bash
npm install @aws-sdk/client-s3 @aws-sdk/lib-storage file-type multer
npm install -D @types/multer
```

```typescript
// src/common/storage/file-signature.validator.ts
import { PipeTransform, Injectable, BadRequestException } from '@nestjs/common';
import { fileTypeFromBuffer } from 'file-type';

const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'];

@Injectable()
export class ParseFileMagicNumberPipe implements PipeTransform<Express.Multer.File, Promise<Express.Multer.File>> {
  async transform(file: Express.Multer.File): Promise<Express.Multer.File> {
    if (!file || !file.buffer) {
      throw new BadRequestException('File is required');
    }

    // Inspect first bytes of buffer for authentic magic number signature
    const detectedType = await fileTypeFromBuffer(file.buffer);

    if (!detectedType || !ALLOWED_MIME_TYPES.includes(detectedType.mime)) {
      throw new BadRequestException(
        `Invalid file format. Detected [${detectedType?.mime || 'unknown'}]. Permitted: [${ALLOWED_MIME_TYPES.join(', ')}]`
      );
    }

    return file;
  }
}
```

---

## 2. S3 / R2 Cloud Storage Service (Streaming)

```typescript
// src/common/storage/s3-storage.service.ts
import { Injectable } from '@nestjs/common';
import { S3Client } from '@aws-sdk/client-s3';
import { Upload } from '@aws-sdk/lib-storage';
import { randomUUID } from 'crypto';
import { extname } from 'path';

@Injectable()
export class S3StorageService {
  private readonly s3Client: S3Client;
  private readonly bucketName = process.env.AWS_S3_BUCKET || 'enterprise-assets';

  constructor() {
    this.s3Client = new S3Client({
      region: process.env.AWS_REGION || 'us-east-1',
      credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID || '',
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || '',
      },
    });
  }

  async uploadFile(file: Express.Multer.File, folder = 'uploads'): Promise<string> {
    const extension = extname(file.originalname);
    const key = `${folder}/${randomUUID()}${extension}`;

    const parallelUpload = new Upload({
      client: this.s3Client,
      params: {
        Bucket: this.bucketName,
        Key: key,
        Body: file.buffer,
        ContentType: file.mimetype,
        CacheControl: 'public, max-age=31536000, immutable',
      },
    });

    await parallelUpload.done();
    return `${process.env.CDN_BASE_URL}/${key}`;
  }
}
```

---

## 3. Controller Implementation with FileInterceptor

```typescript
// src/modules/users/controllers/user-avatar.controller.ts
import { Controller, Post, UseInterceptors, UploadedFile, UseGuards } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { ParseFileMagicNumberPipe } from '@/common/storage/file-signature.validator';
import { S3StorageService } from '@/common/storage/s3-storage.service';

@Controller('users')
export class UserAvatarController {
  constructor(private readonly s3Service: S3StorageService) {}

  @Post('avatar')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: {
        fileSize: 5 * 1024 * 1024, // Strict 5MB limit
        files: 1,
      },
    })
  )
  async uploadAvatar(
    @UploadedFile(ParseFileMagicNumberPipe) file: Express.Multer.File
  ) {
    const cdnUrl = await this.s3Service.uploadFile(file, 'avatars');
    return { avatarUrl: cdnUrl };
  }
}
```

---

**Execution Protocol**
1. **Never trust `file.mimetype`**: Inspect buffer magic numbers using `file-type`.
2. **Never save files to local disk storage (`/tmp`) in containers**: Stream directly from memory buffer to S3 / Cloudflare R2.
3. **Always set `Cache-Control: immutable` on unique S3 keys**: Ensures ultra-fast CDN edge caching.
