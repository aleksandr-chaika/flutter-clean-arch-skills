# BLoC Patterns Reference

## File Structure

Each feature has its own BLoC with three files:

```
feature_name/
├── bloc.dart       # FeatureBloc class
├── events.dart     # FeatureEvent (@freezed)
├── states.dart     # FeatureState (@freezed)
└── view/
```

## Events (@freezed)

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'events.freezed.dart';

@freezed
class UserEvent with _$UserEvent {
  // Lifecycle events
  const factory UserEvent.started() = _Started;

  // Data loading
  const factory UserEvent.loadUser({required String userId}) = _LoadUser;

  // User actions
  const factory UserEvent.updateName({required String name}) = _UpdateName;
  const factory UserEvent.deleteUser() = _DeleteUser;

  // Pagination
  const factory UserEvent.loadMore() = _LoadMore;
  const factory UserEvent.refresh() = _Refresh;
}
```

## States (@freezed)

### Simple State Pattern

```dart
@freezed
class UserState with _$UserState {
  const factory UserState.initial() = _Initial;
  const factory UserState.loading() = _Loading;
  const factory UserState.loaded({required UserEntity user}) = _Loaded;
  const factory UserState.error({required AppError error}) = _Error;
}
```

### Complex State with Data Retention

```dart
@freezed
class UserState with _$UserState {
  const factory UserState({
    required UserEntity? user,
    required bool isLoading,
    required AppError? error,
    @Default(false) bool isUpdating,
  }) = _UserState;

  factory UserState.initial() => const UserState(
    user: null,
    isLoading: false,
    error: null,
  );
}
```

## BLoC Implementation

### Correct Pattern - Individual Handlers

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'bloc.freezed.dart';

@injectable
class UserBloc extends Bloc<UserEvent, UserState> {
  final GetUserUseCase _getUser;
  final UpdateUserUseCase _updateUser;

  UserBloc(this._getUser, this._updateUser) : super(const UserState.initial()) {
    on<_Started>(_onStarted);
    on<_LoadUser>(_onLoadUser);
    on<_UpdateName>(_onUpdateName);
    on<_DeleteUser>(_onDeleteUser);
  }

  Future<void> _onStarted(_Started event, Emitter<UserState> emit) async {
    // Initial setup if needed
  }

  Future<void> _onLoadUser(_LoadUser event, Emitter<UserState> emit) async {
    emit(const UserState.loading());

    final result = await _getUser(GetUserParams(userId: event.userId));

    result.fold(
      (error) => emit(UserState.error(error: error)),
      (user) => emit(UserState.loaded(user: user)),
    );
  }

  Future<void> _onUpdateName(_UpdateName event, Emitter<UserState> emit) async {
    final currentState = state;
    if (currentState is! _Loaded) return;

    emit(UserState.loaded(user: currentState.user.copyWith(name: event.name)));
  }
}
```

### State Checking in Handlers

```dart
Future<void> _onUpdateName(_UpdateName event, Emitter<UserState> emit) async {
  // Pattern 1: Check with is
  final currentState = state;
  if (currentState is! _Loaded) return;

  // Now safe to access currentState.user
  final updatedUser = currentState.user.copyWith(name: event.name);
  emit(UserState.loaded(user: updatedUser));
}

// For complex state with data retention
Future<void> _onUpdateName(_UpdateName event, Emitter<UserState> emit) async {
  if (state.user == null) return;

  emit(state.copyWith(isUpdating: true));

  final result = await _updateUser(UpdateUserParams(name: event.name));

  result.fold(
    (error) => emit(state.copyWith(isUpdating: false, error: error)),
    (user) => emit(state.copyWith(isUpdating: false, user: user)),
  );
}
```

## Anti-Patterns

### NEVER: event.when() in handlers

```dart
// WRONG - This is forbidden!
on<UserEvent>((event, emit) async {
  await event.when(
    started: () => _handleStarted(emit),
    loadUser: (userId) => _handleLoadUser(userId, emit),
  );
});
```

### NEVER: state.when() in handlers

```dart
// WRONG - state.when is for UI only!
Future<void> _onSomeEvent(event, emit) async {
  state.when(
    initial: () => doSomething(),
    loading: () => doSomethingElse(),
    // ...
  );
}
```

### NEVER: Single handler for all events

```dart
// WRONG - Hard to maintain
on<UserEvent>((event, emit) async {
  if (event is _Started) {
    // ...
  } else if (event is _LoadUser) {
    // ...
  }
});
```

## UI Usage

### BlocBuilder

```dart
BlocBuilder<UserBloc, UserState>(
  builder: (context, state) {
    return state.when(
      initial: () => const SizedBox.shrink(),
      loading: () => const CircularProgressIndicator(),
      loaded: (user) => UserProfile(user: user),
      error: (error) => ErrorMessage(error: error.message),
    );
  },
)
```

### BlocBuilder with buildWhen

```dart
BlocBuilder<UserBloc, UserState>(
  buildWhen: (previous, current) {
    // Only rebuild when loaded state changes
    return previous.maybeWhen(
      loaded: (prevUser) => current.maybeWhen(
        loaded: (currUser) => prevUser != currUser,
        orElse: () => true,
      ),
      orElse: () => true,
    );
  },
  builder: (context, state) {
    // ...
  },
)
```

### BlocListener

```dart
BlocListener<UserBloc, UserState>(
  listenWhen: (previous, current) => current is _Error,
  listener: (context, state) {
    if (state is _Error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error.message)),
      );
    }
  },
  child: // ...
)
```

### BlocConsumer

```dart
BlocConsumer<UserBloc, UserState>(
  listenWhen: (previous, current) => current is _Error,
  listener: (context, state) {
    // Show error snackbar
  },
  buildWhen: (previous, current) => current is! _Error,
  builder: (context, state) {
    // Build UI
  },
)
```

## Event Transformers

### Debounce for search

```dart
on<_SearchChanged>(
  _onSearchChanged,
  transformer: debounce(const Duration(milliseconds: 300)),
);

EventTransformer<E> debounce<E>(Duration duration) {
  return (events, mapper) => events.debounceTime(duration).flatMap(mapper);
}
```

### Sequential for ordered operations

```dart
on<_Submit>(
  _onSubmit,
  transformer: sequential(),
);

EventTransformer<E> sequential<E>() {
  return (events, mapper) => events.asyncExpand(mapper);
}
```

## Testing BLoC

See `flutter-tester` skill for comprehensive BLoC testing patterns.
