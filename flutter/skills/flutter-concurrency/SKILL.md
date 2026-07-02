---
name: flutter-concurrency
description: The ultimate architectural standard for Flutter Concurrency The Dart Event Loop, Isolate.run() for JSON parsing, Long-Lived Isolates, and Background Services.
author: Diego Villanueva
trigger: When parsing large JSONs, performing heavy calculations, avoiding UI jank, or implementing multithreading via Isolates.
---

# Flutter Concurrency & Isolate Architecture

Dart is inherently **Single-Threaded**. It relies entirely on an Event Loop. If you perform heavy, synchronous operations (like parsing a massive JSON payload or processing an image) on the main thread, the Event Loop is blocked. The UI will freeze completely.

To achieve 120 FPS, you MUST understand the difference between Asynchronous execution (`Future`) and True Concurrency (`Isolates`).

## 1. The Async Illusion (`Future` != Concurrency)

A massive misconception among junior developers is that marking a function `async` puts it on a background thread. **It does not.** 

An `async` function still runs on the Main UI Thread. It simply yields control back to the Event Loop when it hits an `await`. If the code *between* the `await` statements is heavy, the app will still freeze.

```dart
// ❌ ATROCIOUS: This will freeze the UI completely, even though it returns a Future!
Future<int> calculateFibonacci(int n) async {
  if (n <= 1) return n;
  return await calculateFibonacci(n - 1) + await calculateFibonacci(n - 2); 
}
```

## 2. One-Off Tasks (`Isolate.run()`)

The **16ms Rule**: If any synchronous block of code takes more than 16 milliseconds to execute, the app drops a frame.

Whenever you parse a JSON response larger than 1MB, decode an image, or perform heavy math, you MUST spawn a new Isolate. In modern Dart, use `Isolate.run()` (which replaces the older `compute()` function).

```dart
// ✅ ALWAYS: Use Isolate.run() for heavy synchronous tasks
import 'dart:convert';
import 'dart:isolate';

class UserRepository {
  Future<List<User>> fetchUsers() async {
    final response = await httpClient.get('/users'); // 10MB of JSON
    
    // ❌ BAD: jsonDecode blocks the Main Thread
    // final data = jsonDecode(response.body); 

    // ✅ GOOD: Spawns a background thread, parses JSON, and returns the result safely
    final users = await Isolate.run(() => _parseUsers(response.body));
    return users;
  }
}

// CRITICAL: This function must be top-level or static. It cannot access 'this' or UI context.
List<User> _parseUsers(String jsonString) {
  final List<dynamic> parsed = jsonDecode(jsonString);
  return parsed.map((json) => User.fromJson(json)).toList();
}
```

## 3. Long-Lived Isolates (Bidirectional Communication)

`Isolate.run()` creates a thread, does the work, and destroys the thread. Spawning isolates is expensive (takes ~50ms). If you need continuous background processing (e.g., an audio processor or a continuous WebSocket parser), you must create a **Long-Lived Isolate**.

Isolates **Share Nothing**. They do not share memory. They communicate exclusively by sending messages through a `SendPort` and `ReceivePort`.

```dart
// ✅ ALWAYS: Setup SendPort/ReceivePort for continuous isolate work
import 'dart:isolate';

class AudioProcessor {
  SendPort? _isolateSendPort;
  final ReceivePort _mainReceivePort = ReceivePort();

  Future<void> start() async {
    // 1. Spawn the isolate, passing the Main Thread's SendPort
    await Isolate.spawn(_audioWorker, _mainReceivePort.sendPort);

    // 2. Listen for messages from the isolate
    _mainReceivePort.listen((message) {
      if (message is SendPort) {
        // The first message is the Isolate's SendPort. Save it so we can talk to it!
        _isolateSendPort = message;
      } else {
        // Handle processed audio data
        print('Processed chunk: $message');
      }
    });
  }

  void processChunk(List<int> bytes) {
    // Send data TO the isolate
    _isolateSendPort?.send(bytes);
  }
}

// The Worker Function (Runs in the Isolate)
void _audioWorker(SendPort mainSendPort) {
  // 1. Create a port to receive messages from Main
  final isolateReceivePort = ReceivePort();
  
  // 2. Send our port back to Main so they can talk to us
  mainSendPort.send(isolateReceivePort.sendPort);

  // 3. Listen for work
  isolateReceivePort.listen((message) {
    if (message is List<int>) {
      // Do heavy audio processing...
      final result = 'Processed ${message.length} bytes';
      
      // Send result back to Main
      mainSendPort.send(result);
    }
  });
}
```

## 4. True Background Execution (App Closed)

**CRITICAL RULE**: Isolates are tied to the Flutter Engine. If the user swipes away (kills) the app, the Main UI Thread dies, and **all Isolates die with it**.

If you need to upload a large video, sync a database, or fetch geofencing data while the app is completely closed or in the background, Isolates will fail. You MUST use OS-level Background Services.

- **For Scheduled Tasks**: Use `workmanager` (Android WorkManager / iOS BackgroundTasks).
- **For Continuous Tasks**: Use `flutter_background_service` (Android Foreground Service with persistent notification).

```dart
// ✅ ALWAYS: Use Workmanager for OS-level background sync
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point') // MUST be present to survive minification
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // This runs completely independently of the UI lifecycle
    await DatabaseSyncUseCase().execute();
    return Future.value(true);
  });
}

void main() {
  Workmanager().initialize(callbackDispatcher);
  Workmanager().registerPeriodicTask(
    "1", 
    "syncTask", 
    frequency: Duration(hours: 1), // Minimum 15 mins on Android
  );
  runApp(MyApp());
}
```

---

**Execution Protocol**
1. **Never pass UI elements to Isolates**: You cannot pass `BuildContext`, `Widget`, or native platform channels directly into an Isolate.
2. **Platform Channels in Isolates**: Historically, Isolates could not use plugins (e.g., `SharedPreferences`). Since Flutter 3.7+, use `BackgroundIsolateBinaryMessenger.ensureInitialized()` inside the worker to enable Platform Channels in background isolates.
3. **Use Future.wait for Parallel Async**: If you have 3 independent API calls, DO NOT `await` them sequentially. Use `await Future.wait([api1(), api2(), api3()])` to fire them concurrently on the Event Loop.
