# Clean Architecture Reference

## Overview

Clean Architecture separates concerns into three layers with strict dependency rules.

## Layers

### Presentation Layer

**Location**: `lib/presentation/`

**Contains**:
- UI components (pages, widgets)
- BLoCs (state management)
- Events and States

**Depends on**: Domain layer only

```
presentation/
├── feature_name/
│   ├── bloc.dart           # FeatureBloc
│   ├── events.dart         # FeatureEvent (@freezed)
│   ├── states.dart         # FeatureState (@freezed)
│   └── view/
│       ├── feature_page.dart
│       └── widgets/
│           ├── feature_header.dart
│           └── feature_list.dart
└── common/
    ├── loading_widget.dart
    └── error_widget.dart
```

### Domain Layer

**Location**: `lib/domain/`

**Contains**:
- Entities (business objects)
- Repository interfaces (abstract classes)
- Use Cases (business logic)
- Domain services

**Depends on**: NOTHING (pure Dart)

```
domain/
├── entity/
│   ├── user_entity.dart
│   └── notification_entity.dart
├── repository/
│   ├── user_repository.dart      # Abstract interface
│   └── notification_repository.dart
├── usecases/
│   ├── get_user_usecase.dart
│   └── send_notification_usecase.dart
└── services/
    └── validation_service.dart
```

### Data Layer

**Location**: `lib/data/`

**Contains**:
- Repository implementations
- API models (DTOs)
- Mappers (API model → Entity)
- Data sources (remote, local)

**Depends on**: Domain layer (implements interfaces)

```
data/
├── repository/
│   ├── user_repository_impl.dart
│   └── notification_repository_impl.dart
├── network/
│   ├── api_client.dart
│   ├── models/
│   │   ├── user_api_model.dart
│   │   └── notification_api_model.dart
│   └── interceptors/
│       └── auth_interceptor.dart
├── mapper/
│   ├── user_mapper.dart
│   └── notification_mapper.dart
└── services/
    └── local_storage_service.dart
```

## Dependency Rule

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation                             │
│  (BLoC, Pages, Widgets)                                     │
│                         │                                    │
│                         │ uses                               │
│                         ▼                                    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                     Domain                           │    │
│  │  (Entities, UseCases, Repository Interfaces)         │    │
│  │                                                      │    │
│  └─────────────────────────────────────────────────────┘    │
│                         ▲                                    │
│                         │ implements                         │
│                         │                                    │
│                       Data                                   │
│  (Repository Impl, API Models, Mappers)                     │
└─────────────────────────────────────────────────────────────┘
```

## Use Case Pattern

```dart
// Abstract base
abstract class UseCase<Type, Params> {
  Future<Either<AppError, Type>> call(Params params);
}

// No parameters
class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}

// Implementation
class GetUserUseCase implements UseCase<UserEntity, GetUserParams> {
  final UserRepository _repository;

  GetUserUseCase(this._repository);

  @override
  Future<Either<AppError, UserEntity>> call(GetUserParams params) {
    return _repository.getUser(params.userId);
  }
}

@freezed
class GetUserParams with _$GetUserParams {
  const factory GetUserParams({required String userId}) = _GetUserParams;
}
```

## Repository Pattern

```dart
// Domain layer - Interface
abstract class UserRepository {
  Future<Either<AppError, UserEntity>> getUser(String id);
  Future<Either<AppError, List<UserEntity>>> getUsers();
  Future<Either<AppError, void>> updateUser(UserEntity user);
}

// Data layer - Implementation
@LazySingleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  final ApiClient _apiClient;
  final UserMapper _mapper;

  UserRepositoryImpl(this._apiClient, this._mapper);

  @override
  Future<Either<AppError, UserEntity>> getUser(String id) async {
    try {
      final response = await _apiClient.getUser(id);
      return Right(_mapper.toDomain(response));
    } on DioException catch (e) {
      return Left(ServerError(e.message ?? 'Unknown error'));
    }
  }
}
```

## Entity vs Model

| Aspect | Entity (Domain) | Model (Data) |
|--------|-----------------|--------------|
| Location | `lib/domain/entity/` | `lib/data/network/models/` |
| Purpose | Business logic | API serialization |
| Annotations | `@freezed` | `@freezed` + `@JsonSerializable` |
| Dependencies | None | json_annotation |
| Contains | Business types (enums) | String types (from API) |

```dart
// Entity - uses domain types
@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String name,
    required UserRole role,    // Domain enum
    required DateTime createdAt,
  }) = _UserEntity;
}

// Model - uses API types
@freezed
class UserApiModel with _$UserApiModel {
  const factory UserApiModel({
    required String id,
    required String name,
    required String role,      // String from API
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _UserApiModel;

  factory UserApiModel.fromJson(Map<String, dynamic> json) =>
      _$UserApiModelFromJson(json);
}
```

## Cross-Feature Communication

Features should not depend on each other directly. Use:

1. **Shared entities** in `lib/domain/entity/`
2. **Domain events** via event bus
3. **Navigation** via routes

```dart
// WRONG - Direct feature dependency
import '../other_feature/bloc.dart';

// CORRECT - Shared domain entity
import '../../domain/entity/user_entity.dart';
```
