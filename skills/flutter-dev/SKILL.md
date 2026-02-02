---
name: flutter-dev
description: |
  Flutter development skill for Clean Architecture projects with BLoC state management.

  PROACTIVE ACTIVATION: Use this skill automatically when creating or modifying Flutter/Dart code. When working with files in lib/, this skill's patterns should guide all component authoring, state management, and architecture decisions.

  USE CASES: Creating features with Clean Architecture layers, implementing BLoC with @freezed events/states, writing type-safe models, implementing Either error handling, creating UI components following project conventions.
---

# Flutter Development

## Overview

Expert Flutter developer skill for Clean Architecture projects with BLoC pattern. Enforces type safety, proper state management, and project conventions.

## When to Use

- Creating new features or screens
- Implementing BLoC (events, states, bloc)
- Creating domain entities and use cases
- Writing data layer (repositories, API models, mappers)
- Building UI components

## Project Structure

```
lib/
├── app.dart                    # App entry point
├── main.dart                   # Main file
├── core/
│   ├── error/                  # AppError, Failures
│   ├── extensions/             # Extension methods
│   ├── utils/                  # Utility functions
│   └── di/                     # Dependency Injection (GetIt)
├── data/
│   ├── mapper/                 # Entity <-> Model mappers
│   ├── network/
│   │   ├── api_client.dart
│   │   ├── models/             # API models (@JsonSerializable)
│   │   └── interceptors/
│   ├── repository/             # Repository implementations
│   └── services/               # Data services
├── domain/
│   ├── entity/                 # Domain entities (@freezed)
│   ├── services/               # Domain services
│   └── usecases/               # Use Cases
├── presentation/
│   ├── feature_name/
│   │   ├── bloc.dart           # BLoC class
│   │   ├── events.dart         # Events (@freezed)
│   │   ├── states.dart         # States (@freezed)
│   │   └── view/               # UI components
│   └── common/                 # Shared widgets
└── resources/
    ├── colors/                 # AppColors
    ├── text_styles/            # AppTextStyles
    └── localization/           # AppLocalization
```

## Clean Architecture

### Dependency Rule

Dependencies always point inward: `Presentation → Domain ← Data`

- **Presentation** depends on Domain (uses entities, calls use cases)
- **Data** depends on Domain (implements repository interfaces)
- **Domain** depends on NOTHING (pure business logic)

## Critical Rules

### 1. MANDATORY: @freezed for Events and States

```dart
// CORRECT
@freezed
class FeatureEvent with _$FeatureEvent {
  const factory FeatureEvent.started() = _Started;
  const factory FeatureEvent.loadData({required int id}) = _LoadData;
}

@freezed
class FeatureState with _$FeatureState {
  const factory FeatureState.initial() = _Initial;
  const factory FeatureState.loading() = _Loading;
  const factory FeatureState.loaded(Data data) = _Loaded;
  const factory FeatureState.error(AppError error) = _Error;
}

// WRONG - Never do this!
abstract class FeatureEvent {}
class LoadDataEvent extends FeatureEvent { ... }
```

### 2. BLoC Individual Event Handlers

```dart
// CORRECT - Individual handlers
class FeatureBloc extends Bloc<FeatureEvent, FeatureState> {
  FeatureBloc() : super(const FeatureState.initial()) {
    on<_Started>(_onStarted);
    on<_LoadData>(_onLoadData);
  }

  Future<void> _onLoadData(_LoadData event, Emitter<FeatureState> emit) async {
    emit(const FeatureState.loading());
    final result = await _repository.getData(event.id);
    result.fold(
      (error) => emit(FeatureState.error(error)),
      (data) => emit(FeatureState.loaded(data)),
    );
  }
}

// WRONG - Never use event.when() in handlers
on<FeatureEvent>((event, emit) async {
  await event.when(
    started: () => _handleStarted(emit),
    loadData: (id) => _handleLoadData(id, emit),
  );
});
```

### 3. Either for Error Handling

```dart
// Repository interface
abstract class UserRepository {
  Future<Either<AppError, User>> getUser(int id);
}

// Usage in BLoC
final result = await _getUser(userId);
result.fold(
  (error) => emit(FeatureState.error(error)),
  (user) => emit(FeatureState.loaded(user)),
);
```

### 4. Type-Safe Models

```dart
// FORBIDDEN
Map<String, dynamic> event;  // No type safety!
dynamic data;                // Avoid dynamic
event['title'] ?? '';        // No compile-time checks

// REQUIRED - Domain Entity
@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String name,
    required UserRole role,
  }) = _UserEntity;
}

// REQUIRED - API Model
@freezed
@JsonSerializable()
class UserApiModel with _$UserApiModel {
  const factory UserApiModel({
    required String id,
    required String name,
    required String role,
  }) = _UserApiModel;

  factory UserApiModel.fromJson(Map<String, dynamic> json) =>
      _$UserApiModelFromJson(json);
}

// REQUIRED - Mapper
extension UserApiMapper on UserApiModel {
  UserEntity toDomain() => UserEntity(
    id: id,
    name: name,
    role: UserRole.fromString(role),
  );
}
```

## Anti-Patterns

| Pattern | Status | Reason |
|---------|--------|--------|
| `Map<String, dynamic>` for data | FORBIDDEN | No type safety |
| `event.when()` in BLoC handlers | FORBIDDEN | Use individual handlers |
| `state.when()` in BLoC handlers | FORBIDDEN | Use pattern matching only in UI |
| Single handler for all events | FORBIDDEN | Hard to maintain |
| Hardcoded strings in UI | FORBIDDEN | Use AppLocalization |
| `SvgPicture.asset()` | FORBIDDEN | Use SVGImage() |

## UI Guidelines

### Required Patterns

```dart
// Colors
Container(color: AppColors.primary)

// Text styles
Text('Title', style: AppTextStyles.headline)

// Localization - ALL user-facing text
Text(AppLocalization.welcomeMessage)

// SVG images
SVGImage(asset: Assets.icons.home)

// Const constructors
const SizedBox(height: 16)
```

### BlocBuilder with buildWhen

```dart
BlocBuilder<FeatureBloc, FeatureState>(
  buildWhen: (previous, current) => previous != current,
  builder: (context, state) {
    return state.when(
      initial: () => const SizedBox.shrink(),
      loading: () => const LoadingWidget(),
      loaded: (data) => DataWidget(data: data),
      error: (error) => ErrorWidget(error: error),
    );
  },
)
```

## Code Generation

After creating/modifying @freezed or @JsonSerializable classes:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Additional Resources

- [Clean Architecture details](references/clean-architecture.md)
- [BLoC patterns and anti-patterns](references/bloc-patterns.md)
- [UI guidelines](references/ui-guidelines.md)

## Related Skills

- `flutter-tester` - write tests for your code
- `flutter-reviewer` - validate code quality
