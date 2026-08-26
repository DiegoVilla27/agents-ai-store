---
name: react-native-camera-media
description: The ultimate architectural standard for Camera Capture, Image Picking, Media Library, and File Uploads in React Native with expo-camera, expo-image-picker, and expo-file-system.
author: Diego Villanueva
trigger: When capturing photos/videos with the camera, picking images from the gallery, scanning barcodes, or uploading media files in React Native / Expo.
---

# Enterprise React Native Camera & Media Architecture

Handling media on mobile devices requires runtime permission checks, memory-optimized image compression, barcode scanning, and direct multipart streaming to cloud storage (**AWS S3 / Cloudflare R2**).

---

## 1. Image & Video Picker (`expo-image-picker`)

```bash
npx expo install expo-image-picker expo-file-system expo-camera
```

```typescript
// src/services/media-picker.service.ts
import * as ImagePicker from 'expo-image-picker';
import { Alert } from 'react-native';

export class MediaPickerService {
  static async pickImageFromGallery(allowsEditing = true): Promise<ImagePicker.ImagePickerAsset | null> {
    const { status } = await ImagePicker.requestMediaLibraryPermissionsAsync();

    if (status !== 'granted') {
      Alert.alert('Permission Denied', 'Please enable photo library access in device settings.');
      return null;
    }

    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      allowsEditing,
      aspect: [1, 1], // Square avatar crop
      quality: 0.8,   // Compress image to ~300KB
    });

    if (result.canceled || !result.assets[0]) {
      return null;
    }

    return result.assets[0];
  }
}
```

---

## 2. Full-Screen Camera & Barcode Scanner (`expo-camera`)

```tsx
// src/features/camera/components/ScannerCamera.tsx
import { useState } from 'react';
import { StyleSheet, Text, View, Pressable } from 'react-native';
import { CameraView, useCameraPermissions, BarcodeScanningResult } from 'expo-camera';

export function ScannerCamera({ onScan }: { onScan: (code: string) => void }) {
  const [permission, requestPermission] = useCameraPermissions();
  const [scanned, setScanned] = useState(false);

  if (!permission) return <View />;

  if (!permission.granted) {
    return (
      <View className="flex-1 items-center justify-center p-6">
        <Text className="mb-4 text-center text-lg text-zinc-800 dark:text-zinc-100">
          Camera permission is required to scan QR codes.
        </Text>
        <Pressable
          onPress={requestPermission}
          className="rounded-xl bg-blue-600 px-6 py-3"
        >
          <Text className="font-bold text-white">Grant Permission</Text>
        </Pressable>
      </View>
    );
  }

  const handleBarcodeScanned = (result: BarcodeScanningResult) => {
    if (scanned) return;
    setScanned(true);
    onScan(result.data);
  };

  return (
    <View className="flex-1">
      <CameraView
        style={StyleSheet.absoluteFillObject}
        facing="back"
        barcodeScannerSettings={{
          barcodeTypes: ['qr', 'ean13', 'code128'],
        }}
        onBarcodeScanned={scanned ? undefined : handleBarcodeScanned}
      />
      {scanned && (
        <View className="absolute bottom-10 left-0 right-0 items-center">
          <Pressable
            onPress={() => setScanned(false)}
            className="rounded-full bg-black/70 px-8 py-4 backdrop-blur-md"
          >
            <Text className="font-semibold text-white">Tap to Scan Again</Text>
          </Pressable>
        </View>
      )}
    </View>
  );
}
```

---

## 3. Direct Streaming Upload to Cloud Storage (`expo-file-system`)

```typescript
// src/services/file-upload.service.ts
import * as FileSystem from 'expo-file-system';

export class FileUploadService {
  static async uploadAvatar(localUri: string, uploadUrl: string): Promise<FileSystem.FileSystemUploadResult> {
    return await FileSystem.uploadAsync(uploadUrl, localUri, {
      fieldName: 'file',
      httpMethod: 'POST',
      uploadType: FileSystem.FileSystemUploadType.MULTIPART,
      headers: {
        'Accept': 'application/json',
      },
    });
  }
}
```

---

**Execution Protocol**
1. **Always compress before uploading (`quality: 0.7-0.8`)**: Prevents uploading 12MB raw smartphone photos over cellular connections.
2. **Handle permission denial gracefully**: Guide users to OS settings via `Linking.openSettings()` if previously rejected.
3. **Unmount camera views when navigating away**: Prevents camera sensors from draining battery in the background.
