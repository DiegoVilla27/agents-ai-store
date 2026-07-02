---
name: flutter-testing-expert
description: The ultimate architectural standard for Flutter Testing mocktail Unit Tests, Riverpod override Widget Tests, Golden Tests, and Patrol E2E.
author: Diego Villanueva
trigger: When writing tests, mocking dependencies, fixing test failures, or setting up E2E pipelines.
---

# Enterprise Flutter Testing Architecture

A codebase without tests is legacy code. In Flutter, you must master the Testing Pyramid. 

**The Rule of Mocks**: NEVER make real network requests or read real databases in Unit or Widget tests. You MUST mock all external dependencies.

## 1. Unit Testing (Domain & Data Layers)

Unit tests verify the pure logic of your app (UseCases, Repositories, Mappers). 

**✅ ALWAYS** use `mocktail` (the modern alternative to `mockito` that doesn't require code generation).
**✅ ALWAYS** follow the AAA pattern (Arrange, Act, Assert).

```dart
// ✅ ALWAYS: Use Mocktail and AAA for Unit Tests
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// 1. Create the Mock
class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockUserRepository mockRepository;
  late GetUserUseCase useCase;

  setUp(() {
    mockRepository = MockUserRepository();
    useCase = GetUserUseCase(mockRepository);
  });

  test('Should return User when repository is successful', () async {
    // Arrange
    final tUser = User(id: 1, name: 'Diego');
    when(() => mockRepository.getUser(1))
        .thenAnswer((_) async => Right(tUser));

    // Act
    final result = await useCase.execute(1);

    // Assert
    expect(result, Right(tUser));
    verify(() => mockRepository.getUser(1)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
```

## 2. Widget Testing (Presentation Layer)

Widget tests instantiate pieces of the UI in a headless environment. 
If your UI uses Riverpod, you MUST wrap the widget in a `ProviderScope` and override the providers to inject Mock classes.

```dart
// ✅ ALWAYS: Override dependencies in Widget Tests
testWidgets('Displays User name when loaded', (WidgetTester tester) async {
  // Arrange
  final mockUserNotifier = MockUserNotifier();
  when(() => mockUserNotifier.state).thenReturn(const AsyncData(User(name: 'Diego')));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userNotifierProvider.overrideWith(() => mockUserNotifier),
      ],
      child: const MaterialApp(home: UserScreen()),
    ),
  );

  // Act
  // pump() renders 1 frame. pumpAndSettle() renders frames until all animations finish.
  await tester.pumpAndSettle();

  // Assert
  expect(find.text('Diego'), findsOneWidget);
  expect(find.byType(CircularProgressIndicator), findsNothing);
});
```

## 3. Golden Tests (Visual Regressions)

Widget tests check if a widget exists in the tree, but they DO NOT check if it looks correct. If someone changes the primary color from Blue to Red, the Widget test will still pass.

**✅ ALWAYS** use Golden Tests (`alchemist` or `golden_toolkit`) for your Design System (Buttons, Cards, Typography). Golden tests take a pixel-perfect screenshot of the widget and compare it against a saved baseline image.

```dart
// ✅ ALWAYS: Use Golden Tests for atomic UI components
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  testGoldens('Primary Button renders correctly', (tester) async {
    final builder = DeviceBuilder()
      ..overrideDevicesForAllScenarios(devices: [Device.phone, Device.tabletPortrait])
      ..addScenario(
        name: 'Enabled state',
        widget: const PrimaryButton(text: 'Click Me', isEnabled: true),
      )
      ..addScenario(
        name: 'Disabled state',
        widget: const PrimaryButton(text: 'Click Me', isEnabled: false),
      );

    await tester.pumpDeviceBuilder(builder);
    await screenMatchesGolden(tester, 'primary_button_states');
  });
}
```
*(Run `flutter test --update-goldens` to generate the baseline images. Commit them to Git).*

## 4. Integration Testing (E2E with Patrol)

The standard Flutter `integration_test` package has a fatal flaw: **It cannot interact with native OS dialogs**. If your app asks for Location Permission, the standard test will hang forever because it cannot tap the iOS/Android "Allow" button.

**✅ ALWAYS** use `patrol` for End-to-End testing. It bridges Flutter with native UIAutomator/XCTest.

```dart
// ✅ ALWAYS: Use Patrol for E2E tests to interact with the OS
import 'package:patrol/patrol.dart';

void main() {
  patrolTest(
    'User can login and accept location permission',
    ($) async {
      // Launch the app
      await $.pumpWidgetAndSettle(const MyApp());

      // Flutter Interactions
      await $(#emailField).enterText('admin@acme.com');
      await $(#passwordField).enterText('password123');
      await $(#loginButton).tap();

      // NATIVE OS INTERACTION (Impossible with standard integration_test)
      if (await $.native.isPermissionDialogVisible()) {
        await $.native.grantPermissionWhenInUse();
      }

      // Verify success
      expect($(#dashboardScreen), findsOneWidget);
    },
  );
}
```

---

**Execution Protocol**
1. **Never test Third-Party Code**: Do not write tests to verify that Dio makes HTTP calls or that Isar saves to the database. Test YOUR code, not theirs. Wrap them in a Facade/Repository and mock them.
2. **SetupAll vs Setup**: Use `setUpAll()` for heavy initialization that only needs to happen once per file (like registering Fallback Values in mocktail). Use `setUp()` to reset variables before every single `test()`.
3. **Registering Fallback Values**: In `mocktail`, if a mock function accepts a custom object (like a `User`), you must register a fallback value before using `any()`. Put this in `setUpAll(() => registerFallbackValue(FakeUser()));`.
