# Mocking Guide with mocktail

## Setup

### Install Dependencies

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0
  bloc_test: ^9.1.0
```

### Create Mock Classes

```dart
// test/helpers/mocks.dart
import 'package:mocktail/mocktail.dart';

// Repository mocks
class MockUserRepository extends Mock implements UserRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}

// UseCase mocks
class MockGetUserUseCase extends Mock implements GetUserUseCase {}
class MockLoginUseCase extends Mock implements LoginUseCase {}

// Service mocks
class MockApiClient extends Mock implements ApiClient {}
class MockLocalStorage extends Mock implements LocalStorage {}

// BLoC mocks (for widget tests)
class MockUserBloc extends MockBloc<UserEvent, UserState> implements UserBloc {}
class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}
```

### Register Fallback Values

```dart
// test/helpers/register_fallbacks.dart
void registerFallbacks() {
  // Params
  registerFallbackValue(const GetUserParams(userId: ''));
  registerFallbackValue(const LoginParams(email: '', password: ''));

  // Entities
  registerFallbackValue(UserEntity.empty());

  // Enums
  registerFallbackValue(UserRole.guest);
}

// In test setUp or setUpAll
void main() {
  setUpAll(() {
    registerFallbacks();
  });
}
```

## Stubbing Patterns

### Basic Return Value

```dart
// Return success
when(() => mockRepository.getUser(any()))
    .thenAnswer((_) async => Right(testUser));

// Return error
when(() => mockRepository.getUser(any()))
    .thenAnswer((_) async => Left(ServerError('Error')));

// Return void
when(() => mockRepository.deleteUser(any()))
    .thenAnswer((_) async => const Right(unit));
```

### Conditional Returns

```dart
// Different returns based on input
when(() => mockRepository.getUser('123'))
    .thenAnswer((_) async => Right(user1));
when(() => mockRepository.getUser('456'))
    .thenAnswer((_) async => Right(user2));
when(() => mockRepository.getUser('999'))
    .thenAnswer((_) async => const Left(NotFoundError()));
```

### Sequential Returns

```dart
// Return different values on subsequent calls
var callCount = 0;
when(() => mockRepository.getUser(any())).thenAnswer((_) async {
  callCount++;
  if (callCount == 1) return Right(user1);
  if (callCount == 2) return Right(user2);
  return const Left(ServerError('Too many calls'));
});
```

### Throwing Exceptions

```dart
// Throw exception
when(() => mockApiClient.get(any()))
    .thenThrow(DioException(
      requestOptions: RequestOptions(path: ''),
      type: DioExceptionType.connectionTimeout,
    ));

// Throw on specific input
when(() => mockRepository.getUser('invalid'))
    .thenThrow(ArgumentError('Invalid user ID'));
```

### Delayed Response

```dart
// Simulate network delay
when(() => mockRepository.getUser(any()))
    .thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 100));
      return Right(testUser);
    });
```

## Verification Patterns

### Basic Verification

```dart
// Called once
verify(() => mockRepository.getUser('123')).called(1);

// Called multiple times
verify(() => mockRepository.getUser(any())).called(3);

// Called with specific argument
verify(() => mockRepository.updateUser(
  argThat(isA<UserEntity>().having((u) => u.name, 'name', 'New Name')),
)).called(1);
```

### Never Called

```dart
// Verify method was never called
verifyNever(() => mockRepository.deleteUser(any()));

// Verify no interactions at all
verifyZeroInteractions(mockRepository);
```

### Verification Order

```dart
// Verify call order
verifyInOrder([
  () => mockRepository.getUser('123'),
  () => mockRepository.updateUser(any()),
  () => mockRepository.saveUser(any()),
]);
```

### Capturing Arguments

```dart
// Capture single argument
verify(() => mockRepository.updateUser(captureAny())).called(1);
final captured = verify(() => mockRepository.updateUser(captureAny())).captured;
final updatedUser = captured.first as UserEntity;
expect(updatedUser.name, 'New Name');

// Capture multiple calls
verify(() => mockRepository.log(captureAny())).called(3);
final allCaptured = verify(() => mockRepository.log(captureAny())).captured;
expect(allCaptured, ['Start', 'Process', 'End']);
```

### Custom Matchers

```dart
// Using argThat with custom matcher
verify(() => mockRepository.updateUser(
  argThat(
    isA<UserEntity>()
        .having((u) => u.id, 'id', '123')
        .having((u) => u.name, 'name', startsWith('New')),
  ),
)).called(1);

// Using predicate
verify(() => mockRepository.getUsers(
  argThat(predicate<UserFilter>((f) => f.role == UserRole.admin)),
)).called(1);
```

## BLoC Testing with MockBloc

### Setup MockBloc

```dart
class MockUserBloc extends MockBloc<UserEvent, UserState> implements UserBloc {}

void main() {
  late MockUserBloc mockBloc;

  setUp(() {
    mockBloc = MockUserBloc();
  });

  tearDown(() {
    mockBloc.close();
  });
}
```

### Stubbing State

```dart
// Return specific state
when(() => mockBloc.state).thenReturn(const UserState.loading());

// Return loaded state with data
when(() => mockBloc.state).thenReturn(UserState.loaded(user: testUser));
```

### Stubbing Stream

```dart
// Emit sequence of states
whenListen(
  mockBloc,
  Stream.fromIterable([
    const UserState.loading(),
    UserState.loaded(user: testUser),
  ]),
  initialState: const UserState.initial(),
);
```

### Verifying Events

```dart
// Verify event was added
verify(() => mockBloc.add(const UserEvent.loadUser(userId: '123'))).called(1);

// Verify with any matcher
verify(() => mockBloc.add(any(that: isA<UserEvent>()))).called(1);
```

## Common Patterns

### Testing Error Scenarios

```dart
group('error handling', () {
  test('should return ServerError on network failure', () async {
    when(() => mockApiClient.get(any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionTimeout,
      ),
    );

    final result = await repository.getUser('123');

    expect(result.isLeft(), true);
    result.fold(
      (error) {
        expect(error, isA<ServerError>());
        expect(error.message, contains('timeout'));
      },
      (_) => fail('Should return error'),
    );
  });

  test('should return NotFoundError on 404', () async {
    when(() => mockApiClient.get(any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 404,
        ),
      ),
    );

    final result = await repository.getUser('999');

    expect(result.isLeft(), true);
    result.fold(
      (error) => expect(error, isA<NotFoundError>()),
      (_) => fail('Should return error'),
    );
  });
});
```

### Testing Cache Behavior

```dart
test('should return cached value on second call', () async {
  when(() => mockApiClient.get(any()))
      .thenAnswer((_) async => testUserJson);

  // First call - from API
  final result1 = await repository.getUser('123');
  expect(result1.isRight(), true);

  // Second call - should use cache
  final result2 = await repository.getUser('123');
  expect(result2.isRight(), true);

  // API should only be called once
  verify(() => mockApiClient.get(any())).called(1);
});
```

### Testing Concurrent Calls

```dart
test('should handle concurrent calls correctly', () async {
  var callCount = 0;
  when(() => mockApiClient.get(any())).thenAnswer((_) async {
    callCount++;
    await Future.delayed(const Duration(milliseconds: 50));
    return testUserJson;
  });

  // Make concurrent calls
  final results = await Future.wait([
    repository.getUser('123'),
    repository.getUser('123'),
    repository.getUser('123'),
  ]);

  // All should succeed
  for (final result in results) {
    expect(result.isRight(), true);
  }

  // Should deduplicate calls (if implemented)
  // verify(() => mockApiClient.get(any())).called(1);
});
```

## Best Practices

1. **Reset mocks in setUp** - Use fresh mocks for each test
2. **Register fallbacks in setUpAll** - Do once for all tests
3. **Verify in order of importance** - Critical verifications first
4. **Use descriptive matchers** - Make failures easy to understand
5. **Don't over-mock** - Use real objects when possible
6. **Clean up in tearDown** - Close streams, BLoCs
