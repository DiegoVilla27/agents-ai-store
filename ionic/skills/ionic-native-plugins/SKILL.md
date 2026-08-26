---
name: ionic-native-plugins
description: The ultimate architectural standard for Building Custom Capacitor Native Plugins in Swift (iOS) and Kotlin (Android) with TypeScript Bridges.
author: Diego Villanueva
trigger: When building custom native integrations, writing custom Capacitor plugins, or bridging iOS/Android platform SDKs.
---

# Enterprise Custom Capacitor Plugin Architecture

When ready-made Capacitor plugins do not meet specialized enterprise needs (custom Bluetooth POS terminals, proprietary thermal printers, specialized MDM SDKs), an Enterprise Ionic Architect authors custom Capacitor native plugins.

---

## 1. Plugin Anatomy

A Capacitor plugin consists of three primary components:
1. **TypeScript Definitions & Web Fallback**: The developer API interface.
2. **Swift Implementation (iOS)**: Native iOS implementation inheriting from `CAPPlugin`.
3. **Kotlin Implementation (Android)**: Native Android implementation inheriting from `Plugin`.

---

## 2. TypeScript Definition & Registration

```typescript
// plugins/thermal-printer/src/definitions.ts
export interface PrintOptions {
  content: string;
  fontSize?: number;
  align?: 'left' | 'center' | 'right';
  cutPaper?: boolean;
}

export interface ThermalPrinterPlugin {
  printText(options: PrintOptions): Promise<{ success: boolean }>;
  getPrinterStatus(): Promise<{ connected: boolean; paperStatus: 'OK' | 'LOW' | 'EMPTY' }>;
}
```

```typescript
// plugins/thermal-printer/src/index.ts
import { registerPlugin } from '@capacitor/core';
import type { ThermalPrinterPlugin } from './definitions';

const ThermalPrinter = registerPlugin<ThermalPrinterPlugin>('ThermalPrinter', {
  web: () => import('./web').then(m => new m.ThermalPrinterWeb()),
});

export * from './definitions';
export { ThermalPrinter };
```

```typescript
// plugins/thermal-printer/src/web.ts
import { WebPlugin } from '@capacitor/core';
import type { ThermalPrinterPlugin, PrintOptions } from './definitions';

export class ThermalPrinterWeb extends WebPlugin implements ThermalPrinterPlugin {
  async printText(options: PrintOptions): Promise<{ success: boolean }> {
    console.warn('ThermalPrinter not available on Web platform. Mock print:', options);
    return { success: true };
  }

  async getPrinterStatus(): Promise<{ connected: boolean; paperStatus: 'OK' | 'LOW' | 'EMPTY' }> {
    return { connected: false, paperStatus: 'OK' };
  }
}
```

---

## 3. Native iOS Implementation (Swift)

```swift
// ios/Plugin/ThermalPrinterPlugin.swift
import Foundation
import Capacitor

@objc(ThermalPrinterPlugin)
public class ThermalPrinterPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "ThermalPrinterPlugin"
    public let jsName = "ThermalPrinter"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "printText", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getPrinterStatus", returnType: CAPPluginReturnPromise)
    ]

    @objc func printText(_ call: CAPPluginCall) {
        guard let content = call.getString("content") else {
            call.reject("Must provide content string to print")
            return
        }

        let cutPaper = call.getBool("cutPaper", false)

        // Dispatch to background thread for hardware I/O
        DispatchQueue.global(qos: .userInitiated).async {
            // Hardware printing logic here...
            DispatchQueue.main.async {
                call.resolve([
                    "success": true
                ])
            }
        }
    }

    @objc func getPrinterStatus(_ call: CAPPluginCall) {
        call.resolve([
            "connected": true,
            "paperStatus": "OK"
        ])
    }
}
```

---

## 4. Native Android Implementation (Kotlin)

```kotlin
// android/src/main/java/com/enterprise/printer/ThermalPrinterPlugin.kt
package com.enterprise.printer

import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import com.getcapacitor.JSObject

@CapacitorPlugin(name = "ThermalPrinter")
class ThermalPrinterPlugin : Plugin() {

    @PluginMethod
    fun printText(call: PluginCall) {
        val content = call.getString("content")
        if (content == null) {
            call.reject("Must provide content string to print")
            return
        }

        val cutPaper = call.getBoolean("cutPaper", false) ?: false

        // Execute background print logic
        activity.runOnUiThread {
            val ret = JSObject()
            ret.put("success", true)
            call.resolve(ret)
        }
    }

    @PluginMethod
    fun getPrinterStatus(call: PluginCall) {
        val ret = JSObject()
        ret.put("connected", true)
        ret.put("paperStatus", "OK")
        call.resolve(ret)
    }
}
```

---

## 5. Angular Injectable Wrapper

```typescript
// core/plugins/printer.service.ts
import { Injectable } from '@angular/core';
import { ThermalPrinter, PrintOptions } from '@plugins/thermal-printer';

@Injectable({ providedIn: 'root' })
export class PrinterService {
  async printReceipt(content: string): Promise<boolean> {
    const result = await ThermalPrinter.printText({
      content,
      cutPaper: true,
      align: 'center'
    });
    return result.success;
  }
}
```

---

**Execution Protocol**
1. **Always provide a TypeScript Web fallback**: Web developers must be able to run `ionic serve` without native compiler crashes.
2. **Never block the native main thread**: Heavy hardware I/O (Bluetooth, USB, NFC) must execute in native background dispatch queues/coroutines.
3. **Use `call.reject(msg)` with descriptive error messages**: Return structured errors that Angular can catch cleanly.
4. **Wrap custom plugins in Angular services**: Maintain clean dependency injection throughout the app.
