---
name: ionic-camera-media
description: The ultimate architectural standard for Camera, Filesystem, and Media operations with Capacitor Camera, Filesystem, and Share plugins.
author: Diego Villanueva
trigger: When capturing photos/videos, accessing the device gallery, saving files to the filesystem, or sharing content natively.
---

# Enterprise Ionic Camera & Media Architecture

Native media access is one of the most common requirements in mobile apps. Capacitor provides first-class plugins for Camera, Filesystem, and Share functionality.

## 1. Camera Service (Photo Capture & Gallery)

```typescript
// core/plugins/camera.service.ts
import { Injectable } from '@angular/core';
import { Capacitor } from '@capacitor/core';
import {
  Camera, CameraResultType, CameraSource, Photo, GalleryPhotos
} from '@capacitor/camera';

@Injectable({ providedIn: 'root' })
export class CameraService {
  async takePhoto(): Promise<Photo> {
    await this.ensurePermissions();
    return Camera.getPhoto({
      quality: 85,
      allowEditing: false,
      resultType: CameraResultType.Uri,
      source: CameraSource.Camera,
      width: 1200,
      height: 1200,
      correctOrientation: true,
      saveToGallery: false,
    });
  }

  async pickFromGallery(): Promise<Photo> {
    await this.ensurePermissions();
    return Camera.getPhoto({
      quality: 85,
      allowEditing: false,
      resultType: CameraResultType.Uri,
      source: CameraSource.Photos,
      width: 1200,
      height: 1200,
    });
  }

  async pickMultiple(limit = 10): Promise<GalleryPhotos> {
    await this.ensurePermissions();
    return Camera.pickImages({
      quality: 85,
      width: 1200,
      height: 1200,
      limit,
    });
  }

  async photoToBase64(photo: Photo): Promise<string> {
    if (photo.base64String) return photo.base64String;

    // Read the file from the temporary URI
    const response = await fetch(photo.webPath!);
    const blob = await response.blob();
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onloadend = () => resolve((reader.result as string).split(',')[1]);
      reader.onerror = reject;
      reader.readAsDataURL(blob);
    });
  }

  private async ensurePermissions(): Promise<void> {
    const permissions = await Camera.checkPermissions();

    if (permissions.camera === 'denied' || permissions.photos === 'denied') {
      throw new Error('Camera/Photo permissions permanently denied. Please enable in Settings.');
    }

    if (permissions.camera !== 'granted' || permissions.photos !== 'granted') {
      const request = await Camera.requestPermissions();
      if (request.camera !== 'granted') {
        throw new Error('Camera permission not granted');
      }
    }
  }
}
```

## 2. Filesystem Service (Save, Read, Delete)

```typescript
// core/plugins/filesystem.service.ts
import { Injectable } from '@angular/core';
import {
  Filesystem, Directory, Encoding, WriteFileResult
} from '@capacitor/filesystem';

@Injectable({ providedIn: 'root' })
export class FilesystemService {
  async saveImage(base64Data: string, fileName: string): Promise<WriteFileResult> {
    return Filesystem.writeFile({
      path: `images/${fileName}`,
      data: base64Data,
      directory: Directory.Data,
      recursive: true, // Create directories if they don't exist
    });
  }

  async readFile(path: string): Promise<string> {
    const result = await Filesystem.readFile({
      path,
      directory: Directory.Data,
    });
    return result.data as string;
  }

  async deleteFile(path: string): Promise<void> {
    await Filesystem.deleteFile({
      path,
      directory: Directory.Data,
    });
  }

  async listFiles(directory: string): Promise<string[]> {
    const result = await Filesystem.readdir({
      path: directory,
      directory: Directory.Data,
    });
    return result.files.map(f => f.name);
  }

  async getFileUri(path: string): Promise<string> {
    const result = await Filesystem.getUri({
      path,
      directory: Directory.Data,
    });
    return Capacitor.convertFileSrc(result.uri);
  }

  async downloadFile(url: string, fileName: string): Promise<string> {
    const response = await fetch(url);
    const blob = await response.blob();
    const base64 = await this.blobToBase64(blob);

    const result = await Filesystem.writeFile({
      path: `downloads/${fileName}`,
      data: base64,
      directory: Directory.Data,
      recursive: true,
    });

    return result.uri;
  }

  private blobToBase64(blob: Blob): Promise<string> {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onloadend = () => resolve((reader.result as string).split(',')[1]);
      reader.onerror = reject;
      reader.readAsDataURL(blob);
    });
  }
}
```

## 3. Share Service (Native Sharing)

```typescript
// core/plugins/share.service.ts
import { Injectable } from '@angular/core';
import { Share, ShareResult } from '@capacitor/share';

@Injectable({ providedIn: 'root' })
export class ShareService {
  async shareText(title: string, text: string, url?: string): Promise<ShareResult> {
    return Share.share({ title, text, url, dialogTitle: title });
  }

  async shareFile(title: string, filePath: string): Promise<ShareResult> {
    return Share.share({
      title,
      files: [filePath],
      dialogTitle: title,
    });
  }

  async canShare(): Promise<boolean> {
    const result = await Share.canShare();
    return result.value;
  }
}
```

## 4. Image Upload with Progress

```typescript
// features/profile/services/avatar-upload.service.ts
@Injectable({ providedIn: 'root' })
export class AvatarUploadService {
  private readonly camera = inject(CameraService);
  private readonly http = inject(HttpClient);

  upload(photo: Photo): Observable<number | string> {
    return new Observable(observer => {
      this.camera.photoToBase64(photo).then(base64 => {
        const blob = this.base64ToBlob(base64, 'image/jpeg');
        const formData = new FormData();
        formData.append('avatar', blob, 'avatar.jpg');

        const req = new HttpRequest('POST', '/api/avatar', formData, {
          reportProgress: true,
        });

        this.http.request(req).subscribe({
          next: (event) => {
            if (event.type === HttpEventType.UploadProgress && event.total) {
              observer.next(Math.round((event.loaded / event.total) * 100));
            } else if (event instanceof HttpResponse) {
              observer.next(event.body.url);
              observer.complete();
            }
          },
          error: (err) => observer.error(err),
        });
      });
    });
  }

  private base64ToBlob(base64: string, mime: string): Blob {
    const byteChars = atob(base64);
    const byteArrays = [];
    for (let offset = 0; offset < byteChars.length; offset += 512) {
      const slice = byteChars.slice(offset, offset + 512);
      const byteNumbers = new Array(slice.length).fill(0).map((_, i) => slice.charCodeAt(i));
      byteArrays.push(new Uint8Array(byteNumbers));
    }
    return new Blob(byteArrays, { type: mime });
  }
}
```

---

**Execution Protocol**
1. **Always check and request permissions before accessing camera/gallery**: Never assume permissions are granted.
2. **Always use `CameraResultType.Uri`**: Avoid Base64 for the initial capture to prevent memory issues. Convert to Base64 only when needed for upload.
3. **Always use `Capacitor.convertFileSrc()`**: To display native file paths in `<img>` tags.
4. **Always handle file cleanup**: Delete temporary files after upload to prevent storage bloat.
5. **Always wrap media plugins in injectable services**: For testability and abstraction.
