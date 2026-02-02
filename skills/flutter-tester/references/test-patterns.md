# Test Patterns Reference

## Unit Test Templates

### UseCase Test Template

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late GetUserUseCase useCase;
  late MockUserRepository mockRepository;

  setUp(() {
    mockRepository = MockUserRepository();
    useCase = GetUserUseCase(mockRepository);
  });

  setUpAll(() {
    registerFallbackValue(const GetUserParams(userId: ''));
  });

  group('GetUserUseCase', () {
    const tUserId = '123';
    final tUser = UserEntity(
      id: tUserId,
      name: 'Test User',
      email: 'test@example.com',
    );

    test('should return UserEntity when repository succeeds', () async {
      // Given
      when(() => mockRepository.getUser(any()))
          .thenAnswer((_) async => Right(tUser));

      // When
      final result = await useCase(const GetUserParams(userId: tUserId));

      // Then
      expect(result, Right(tUser));
      verify(() => mockRepository.getUser(tUserId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return ServerError when repository fails', () async {
      // Given
      const tError = ServerError('Network error');
      when(() => mockRepository.getUser(any()))
          .thenAnswer((_) async => const Left(tError));

      // When
      final result = await useCase(const GetUserParams(userId: tUserId));

      // Then
      expect(result, const Left(tError));
      verify(() => mockRepository.getUser(tUserId)).called(1);
    });
  });
}
```

### Repository Implementation Test Template

```dart
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}
class MockUserMapper extends Mock implements UserMapper {}

void main() {
  late UserRepositoryImpl repository;
  late MockApiClient mockApiClient;
  late MockUserMapper mockMapper;

  setUp(() {
    mockApiClient = MockApiClient();
    mockMapper = MockUserMapper();
    repository = UserRepositoryImpl(mockApiClient, mockMapper);
  });

  group('getUser', () {
    const tUserId = '123';
    final tApiModel = UserApiModel(
      id: tUserId,
      name: 'Test',
      email: 'test@example.com',
    );
    final tEntity = UserEntity(
      id: tUserId,
      name: 'Test',
      email: 'test@example.com',
    );

    test('should return UserEntity when API call succeeds', () async {
      // Given
      when(() => mockApiClient.getUser(any()))
          .thenAnswer((_) async => tApiModel);
      when(() => mockMapper.toDomain(any())).thenReturn(tEntity);

      // When
      final result = await repository.getUser(tUserId);

      // Then
      expect(result, Right(tEntity));
      verify(() => mockApiClient.getUser(tUserId)).called(1);
      verify(() => mockMapper.toDomain(tApiModel)).called(1);
    });

    test('should return ServerError when API throws DioException', () async {
      // Given
      when(() => mockApiClient.getUser(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          message: 'Network error',
        ),
      );

      // When
      final result = await repository.getUser(tUserId);

      // Then
      expect(result.isLeft(), true);
      result.fold(
        (error) => expect(error, isA<ServerError>()),
        (_) => fail('Should return error'),
      );
    });

    test('should return ServerError when API throws unknown error', () async {
      // Given
      when(() => mockApiClient.getUser(any()))
          .thenThrow(Exception('Unknown error'));

      // When
      final result = await repository.getUser(tUserId);

      // Then
      expect(result.isLeft(), true);
    });
  });
}
```

### Mapper Test Template

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserMapper', () {
    test('should correctly map UserApiModel to UserEntity', () {
      // Given
      final apiModel = UserApiModel(
        id: '123',
        name: 'Test User',
        email: 'test@example.com',
        role: 'admin',
        createdAt: '2024-01-15T10:30:00Z',
      );

      // When
      final entity = apiModel.toDomain();

      // Then
      expect(entity.id, '123');
      expect(entity.name, 'Test User');
      expect(entity.email, 'test@example.com');
      expect(entity.role, UserRole.admin);
      expect(entity.createdAt, DateTime.utc(2024, 1, 15, 10, 30));
    });

    test('should handle unknown role gracefully', () {
      // Given
      final apiModel = UserApiModel(
        id: '123',
        name: 'Test',
        email: 'test@example.com',
        role: 'unknown_role',
        createdAt: '2024-01-15T10:30:00Z',
      );

      // When
      final entity = apiModel.toDomain();

      // Then
      expect(entity.role, UserRole.guest); // Default value
    });
  });
}
```

## BLoC Test Templates

### Comprehensive BLoC Test

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetUserUseCase extends Mock implements GetUserUseCase {}
class MockUpdateUserUseCase extends Mock implements UpdateUserUseCase {}

void main() {
  late UserBloc bloc;
  late MockGetUserUseCase mockGetUser;
  late MockUpdateUserUseCase mockUpdateUser;

  final tUser = UserEntity(
    id: '123',
    name: 'Test User',
    email: 'test@example.com',
  );

  setUp(() {
    mockGetUser = MockGetUserUseCase();
    mockUpdateUser = MockUpdateUserUseCase();
    bloc = UserBloc(mockGetUser, mockUpdateUser);
  });

  setUpAll(() {
    registerFallbackValue(const GetUserParams(userId: ''));
    registerFallbackValue(const UpdateUserParams(name: ''));
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state is UserState.initial()', () {
    expect(bloc.state, const UserState.initial());
  });

  group('LoadUser', () {
    blocTest<UserBloc, UserState>(
      'emits [loading, loaded] when successful',
      build: () {
        when(() => mockGetUser(any()))
            .thenAnswer((_) async => Right(tUser));
        return bloc;
      },
      act: (bloc) => bloc.add(const UserEvent.loadUser(userId: '123')),
      expect: () => [
        const UserState.loading(),
        UserState.loaded(user: tUser),
      ],
      verify: (_) {
        verify(() => mockGetUser(const GetUserParams(userId: '123'))).called(1);
      },
    );

    blocTest<UserBloc, UserState>(
      'emits [loading, error] when fails',
      build: () {
        when(() => mockGetUser(any()))
            .thenAnswer((_) async => const Left(ServerError('Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const UserEvent.loadUser(userId: '123')),
      expect: () => [
        const UserState.loading(),
        const UserState.error(error: ServerError('Error')),
      ],
    );
  });

  group('UpdateName', () {
    blocTest<UserBloc, UserState>(
      'does nothing when not in loaded state',
      build: () => bloc,
      seed: () => const UserState.initial(),
      act: (bloc) => bloc.add(const UserEvent.updateName(name: 'New')),
      expect: () => [],
      verify: (_) {
        verifyNever(() => mockUpdateUser(any()));
      },
    );

    blocTest<UserBloc, UserState>(
      'emits updated state when in loaded state',
      build: () {
        when(() => mockUpdateUser(any()))
            .thenAnswer((_) async => Right(tUser.copyWith(name: 'New Name')));
        return bloc;
      },
      seed: () => UserState.loaded(user: tUser),
      act: (bloc) => bloc.add(const UserEvent.updateName(name: 'New Name')),
      expect: () => [
        UserState.loaded(user: tUser, isUpdating: true),
        UserState.loaded(user: tUser.copyWith(name: 'New Name')),
      ],
    );
  });
}
```

## Widget Test Templates

### Page Test with BLoC

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUserBloc extends MockBloc<UserEvent, UserState> implements UserBloc {}

void main() {
  late MockUserBloc mockBloc;

  setUp(() {
    mockBloc = MockUserBloc();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      home: BlocProvider<UserBloc>.value(
        value: mockBloc,
        child: const UserPage(),
      ),
    );
  }

  group('UserPage', () {
    testWidgets('shows loading indicator when loading', (tester) async {
      // Given
      when(() => mockBloc.state).thenReturn(const UserState.loading());

      // When
      await tester.pumpWidget(buildTestWidget());

      // Then
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows user data when loaded', (tester) async {
      // Given
      final user = UserEntity(id: '1', name: 'John Doe', email: 'john@example.com');
      when(() => mockBloc.state).thenReturn(UserState.loaded(user: user));

      // When
      await tester.pumpWidget(buildTestWidget());

      // Then
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john@example.com'), findsOneWidget);
    });

    testWidgets('shows error message when error', (tester) async {
      // Given
      when(() => mockBloc.state)
          .thenReturn(const UserState.error(error: ServerError('Network error')));

      // When
      await tester.pumpWidget(buildTestWidget());

      // Then
      expect(find.text('Network error'), findsOneWidget);
    });

    testWidgets('triggers LoadUser when refresh button tapped', (tester) async {
      // Given
      when(() => mockBloc.state).thenReturn(const UserState.initial());

      // When
      await tester.pumpWidget(buildTestWidget());
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      // Then
      verify(() => mockBloc.add(any(that: isA<_LoadUser>()))).called(1);
    });
  });
}
```

### Isolated Widget Test

```dart
void main() {
  group('UserAvatar', () {
    testWidgets('displays initials when no image', (tester) async {
      // Given & When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              name: 'John Doe',
              imageUrl: null,
            ),
          ),
        ),
      );

      // Then
      expect(find.text('JD'), findsOneWidget);
    });

    testWidgets('displays image when imageUrl provided', (tester) async {
      // Given & When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              name: 'John Doe',
              imageUrl: 'https://example.com/avatar.png',
            ),
          ),
        ),
      );

      // Then
      expect(find.byType(Image), findsOneWidget);
    });
  });
}
```

## Helper Functions

### pumpApp Helper

```dart
// test/helpers/pump_app.dart
extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    List<BlocProvider> providers = const [],
  }) {
    return pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: providers,
          child: widget,
        ),
      ),
    );
  }
}

// Usage
await tester.pumpApp(
  const UserPage(),
  providers: [
    BlocProvider<UserBloc>.value(value: mockBloc),
  ],
);
```

### Test Data Factory

```dart
// test/helpers/test_data.dart
class TestData {
  static UserEntity user({
    String id = '123',
    String name = 'Test User',
    String email = 'test@example.com',
    UserRole role = UserRole.user,
  }) {
    return UserEntity(
      id: id,
      name: name,
      email: email,
      role: role,
    );
  }

  static List<UserEntity> users(int count) {
    return List.generate(
      count,
      (i) => user(id: '$i', name: 'User $i'),
    );
  }
}

// Usage
final testUser = TestData.user(name: 'Custom Name');
final testUsers = TestData.users(10);
```
