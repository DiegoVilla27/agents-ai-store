---
name: express-file-uploads
description: The ultimate architectural standard for Secure File Uploads in Express.js with Multer, S3/Cloud Streaming, Magic Number MIME Validation, and Quota Enforcement.
author: Diego Villanueva
trigger: When handling file uploads, validating image/document uploads, streaming files to S3, preventing malicious file uploads, or configuring Multer in Express.
---

# Enterprise Express.js Secure File Upload Architecture

File upload handling is one of the most vulnerable attack vectors in web backends (malicious executable uploads, zip bombs, denial-of-service via memory exhaustion). An Enterprise Express Architect enforces stream processing, buffer magic number verification, and cloud bucket isolation.

---

## 1. Magic Number MIME Verification (File Signature Inspection)

**❌ NEVER** trust the client-provided `file.mimetype` or file extension (`.jpg`). Attackers can rename `malicious.exe` to `photo.jpg`.
**✅ ALWAYS** verify the initial bytes of the file buffer (**Magic Numbers**) using `file-type`.

```bash
npm install multer file-type @aws-sdk/client-s3 @aws-sdk/lib-storage
npm install -D @types/multer
```

```typescript
// src/common/storage/file-validator.ts
import { fileTypeFromBuffer } from 'file-type';
import { AppError } from '../errors/AppError';

const ALLOWED_IMAGE_MIMES = ['image/jpeg', 'image/png', 'image/webp', 'image/avif'];

export async function validateImageBuffer(buffer: Buffer): Promise<{ ext: string; mime: string }> {
  // Read true magic number signature from binary header
  const fileType = await fileTypeFromBuffer(buffer);

  if (!fileType || !ALLOWED_IMAGE_MIMES.includes(fileType.mime)) {
    throw new AppError(400, 'Invalid file content: only authentic JPEG, PNG, WebP, and AVIF images are permitted.');
  }

  return fileType;
}
```

---

## 2. Multer Memory & Size Boundary Configuration

```typescript
// src/common/storage/multer.config.ts
import multer from 'multer';
import { AppError } from '../errors/AppError';

// Store in memory buffer for stream upload to S3
const storage = multer.memoryStorage();

export const uploadAvatar = multer({
  storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // Strict 5MB limit
    files: 1,                  // Maximum 1 file per request
  },
  fileFilter: (req, file, cb) => {
    // Initial coarse extension check
    if (!file.originalname.match(/\.(jpg|jpeg|png|webp)$/i)) {
      return cb(new AppError(400, 'Only image files are allowed'));
    }
    cb(null, true);
  },
});
```

---

## 3. Direct Streaming to Cloud Storage (AWS S3 / Cloudflare R2)

```typescript
// src/common/storage/s3-storage.service.ts
import { S3Client } from '@aws-sdk/client-s3';
import { Upload } from '@aws-sdk/lib-storage';
import { env } from '@/config/env';
import { validateImageBuffer } from './file-validator';

const s3Client = new S3Client({
  region: env.AWS_REGION,
  credentials: {
    accessKeyId: env.AWS_ACCESS_KEY_ID,
    secretAccessKey: env.AWS_SECRET_ACCESS_KEY,
  },
});

export class S3StorageService {
  static async uploadAvatar(userId: string, buffer: Buffer): Promise<string> {
    // 1. Rigorous Magic Number verification
    const { ext, mime } = await validateImageBuffer(buffer);

    // 2. Generate random collision-free filename
    const key = `avatars/${userId}/${crypto.randomUUID()}.${ext}`;

    // 3. Stream upload using S3 Multipart Upload
    const parallelUpload = new Upload({
      client: s3Client,
      params: {
        Bucket: env.AWS_S3_BUCKET,
        Key: key,
        Body: buffer,
        ContentType: mime,
        CacheControl: 'public, max-age=31536000, immutable',
      },
    });

    await parallelUpload.done();

    // 4. Return CDN URL
    return `${env.CDN_BASE_URL}/${key}`;
  }
}
```

---

## 4. Controller Implementation

```typescript
// src/modules/users/controllers/avatar.controller.ts
import { Request, Response } from 'express';
import { S3StorageService } from '@/common/storage/s3-storage.service';
import { AppError } from '@/common/errors/AppError';

export class AvatarController {
  async upload(req: Request, res: Response): Promise<void> {
    if (!req.file) {
      throw new AppError(400, 'No file uploaded');
    }

    const userId = req.user!.userId;
    const avatarUrl = await S3StorageService.uploadAvatar(userId, req.file.buffer);

    // Save avatar URL in DB
    await userService.updateAvatarUrl(userId, avatarUrl);

    res.status(200).json({
      success: true,
      avatarUrl,
    });
  }
}
```

---

## 5. Route Integration

```typescript
// src/modules/users/routes/user.routes.ts
import { Router } from 'express';
import { authenticate } from '@/common/middlewares/auth.middleware';
import { uploadAvatar } from '@/common/storage/multer.config';
import { AvatarController } from '../controllers/avatar.controller';

const router = Router();
const controller = new AvatarController();

router.post(
  '/users/avatar',
  authenticate,
  uploadAvatar.single('avatar'),
  (req, res, next) => controller.upload(req, res, next)
);

export default router;
```

---

**Execution Protocol**
1. **Never trust `req.file.mimetype`**: Inspect buffer magic numbers using `file-type`.
2. **Never store user uploads on local server disk**: Local storage breaks auto-scaling and ephemeral container clusters (ECS/Kubernetes). Always stream to S3 / Cloudflare R2.
3. **Always set `Cache-Control: immutable` on unique S3 keys**: Offloads asset bandwidth to Edge CDN.
4. **Enforce strict Multer `fileSize` limits**: Prevents memory exhaustion attacks.
