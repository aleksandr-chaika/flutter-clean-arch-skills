---
name: flutter-tester
description: |
  Testing skill for Flutter projects using mocktail and bloc_test.

  ACTIVATION: Use this skill when the user requests to write tests, add test coverage, or asks about testing patterns. Triggers on phrases like "write tests", "напиши тесты", "add coverage", "протестируй", "покрой тестами".

  USE CASES: Writing unit tests for UseCases and Repositories, creating BLoC tests with bloc_test, implementing widget tests, setting up mocks with mocktail, achieving >80% coverage target.
---

# Flutter Testing

## Overview

Testing skill for Flutter projects with Clean Architecture. Uses mocktail for mocking and bloc_test for BLoC testing. Target: >80% coverage on Domain and Data layers.

## When to Use

- Writing unit tests for UseCases, Repositories, Services
- Creating BLoC tests
- Implementing widget tests for screens and components
- Setting up test infrastructure
- Improving code coverage

## Test Structure

```
test/
├── unit/
│   ├── domain/
│   │   ├── usecases/
│   │   │   └── get_user_usecase_test.dart
│   │   └── services/
│   ├── data/
│   │   ├── repository/
│   │   │   └── user_repository_impl_test.dart
│   │   └── mapper/
│   └── presentation/
│       └── bloc/
│           └── user_bloc_test.dart
├── widget/
│   ├── pages/
│   │   └── user_page_test.dart
│   └── widgets/
│       └── user_avatar_test.dart
├── integration/
│   └── user_flow_test.dart
└── helpers/
    ├── mocks.dart
    ├── test_data.dart
    └── pump_app.dart
```

## Testing Pyramid

| Layer | Coverage | Focus |
|-------|----------|-------|
| Unit tests | ~70% | BLoC, UseCases, Repositories, Mappers |
| Widget tests | ~20% | Screens, Components |
| Integration tests | ~10% | E2E flows |

## Given-When-Then Pattern (AAA)

```dart
test('should return user when repository succeeds', () async {
  // Given (Arrange)
  when(() => mockRepository.getUser(any()))
      .thenAnswer((_) async => Right(testUser));

  // When (Act)
  final result = await useCase(GetUserParams(userId: '123'));

  // Then (Assert)
  expect(result, Right(testUser));
  verify(() => mockRepository.getUser('123')).called(1);
});
```

## BLoC Testing with bloc_test

### Basic BLoC Test

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetUserUseCase extends Mock implements GetUserUseCase {}

void main() {
  late MockGetUserUseCase mockGetUser;
  late UserBloc bloc;

  setUp(() {
    mockGetUser = MockGetUserUseCase();
    bloc = UserBloc(mockGetUser);
  });

  tearDown(() {
    bloc.close();
  });

  group('UserBloc', () {
    blocTest<UserBloc, UserState>(
      'emits [loading, loaded] when LoadUser succeeds',
      build: () {
        when(() => mockGetUser(any()))
            .thenAnswer((_) async => Right(testUser));
        return bloc;
      },
      act: (bloc) => bloc.add(const UserEvent.loadUser(userId: '123')),
      expect: () => [
        const UserState.loading(),
        UserState.loaded(user: testUser),
      ],
      verify: (_) {
        verify(() => mockGetUser(const GetUserParams(userId: '123'))).called(1);
      },
    );

    blocTest<UserBloc, UserState>(
      'emits [loading, error] when LoadUser fails',
      build: () {
        when(() => mockGetUser(any()))
            .thenAnswer((_) async => Left(ServerError('Network error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const UserEvent.loadUser(userId: '123')),
      expect: () => [
        const UserState.loading(),
        const UserState.error(error: ServerError('Network error')),
      ],
    );
  });
}
```

### Testing State Transitions

```dart
blocTest<UserBloc, UserState>(
  'emits correct sequence when updating user name',
  seed: () => UserState.loaded(user: testUser),
  build: () {
    when(() => mockUpdateUser(any()))
        .thenAnswer((_) async => Right(updatedUser));
    return bloc;
  },
  act: (bloc) => bloc.add(const UserEvent.updateName(name: 'New Name')),
  expect: () => [
    UserState.loaded(user: testUser, isUpdating: true),
    UserState.loaded(user: updatedUser, isUpdating: false),
  ],
);
```

## Mocking with mocktail

### Creating Mocks

```dart
// mocks.dart
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements UserRepository {}
class MockApiClient extends Mock implements ApiClient {}
class MockGetUserUseCase extends Mock implements GetUserUseCase {}

// Register fallback values for custom types
void setUpMocktailFallbacks() {
  registerFallbackValue(const GetUserParams(userId: ''));
  registerFallbackValue(UserEntity.empty());
}
```

### Stubbing Methods

```dart
// Return a value
when(() => mockRepository.getUser(any()))
    .thenAnswer((_) async => Right(testUser));

// Return an error
when(() => mockRepository.getUser(any()))
    .thenAnswer((_) async => Left(ServerError('Error')));

// Throw an exception
when(() => mockRepository.getUser(any()))
    .thenThrow(Exception('Unexpected error'));

// Capture arguments
when(() => mockRepository.updateUser(captureAny()))
    .thenAnswer((_) async => Right(unit));

final captured = verify(() => mockRepository.updateUser(captureAny())).captured;
expect(captured.first.name, 'New Name');
```

### Verification

```dart
// Called once
verify(() => mockRepository.getUser('123')).called(1);

// Called multiple times
verify(() => mockRepository.getUser(any())).called(3);

// Never called
verifyNever(() => mockRepository.deleteUser(any()));

// No more interactions
verifyNoMoreInteractions(mockRepository);
```

## Widget Testing

### Basic Widget Test

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockUserBloc extends MockBloc<UserEvent, UserState> implements UserBloc {}

void main() {
  late MockUserBloc mockBloc;

  setUp(() {
    mockBloc = MockUserBloc();
  });

  testWidgets('displays user name when loaded', (tester) async {
    // Given
    when(() => mockBloc.state).thenReturn(
      UserState.loaded(user: testUser),
    );

    // When
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<UserBloc>.value(
          value: mockBloc,
          child: const UserPage(),
        ),
      ),
    );

    // Then
    expect(find.text(testUser.name), findsOneWidget);
  });

  testWidgets('shows loading indicator when loading', (tester) async {
    when(() => mockBloc.state).thenReturn(const UserState.loading());

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<UserBloc>.value(
          value: mockBloc,
          child: const UserPage(),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
```

### Testing Interactions

```dart
testWidgets('triggers LoadUser on button tap', (tester) async {
  when(() => mockBloc.state).thenReturn(const UserState.initial());

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<UserBloc>.value(
        value: mockBloc,
        child: const UserPage(),
      ),
    ),
  );

  await tester.tap(find.byKey(const Key('load_button')));
  await tester.pump();

  verify(() => mockBloc.add(const UserEvent.loadUser(userId: '123'))).called(1);
});
```

## What to Mock vs Real

| Mock | Use Real |
|------|----------|
| Repositories | Entities/Models |
| DataSources | Pure functions |
| External APIs | Mappers |
| Network clients | Domain services (unit tests) |
| BLoCs (in widget tests) | Validators |

## Coverage Target

- **>80%** on `lib/domain/` and `lib/data/`
- Exclude generated files (`*.g.dart`, `*.freezed.dart`)
- Focus on:
  - Happy path
  - Error scenarios
  - Edge cases (null, empty, boundary values)

### Run Coverage

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Anti-Patterns

| Pattern | Issue | Solution |
|---------|-------|----------|
| `Future.delayed` in tests | Flaky, slow | Use `FakeAsync` |
| Empty tests | No verification | Always have `expect()` |
| Over-mocking | Tests mock themselves | Use real Entities |
| Shared mutable state | Tests affect each other | Fresh setup per test |
| Testing implementation | Brittle tests | Test behavior |

## Additional Resources

- [Test patterns and templates](references/test-patterns.md)
- [Mocking guide](references/mocking-guide.md)

## Related Skills

- `flutter-dev` - Code patterns being tested
- `flutter-reviewer` - Test coverage validation
