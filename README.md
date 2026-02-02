# Flutter Clean Architecture Skills

Claude Code skills for Flutter projects with Clean Architecture, BLoC state management, and @freezed patterns.

## Skills Included

| Skill | Description |
|-------|-------------|
| **flutter-dev** | Development patterns: Clean Architecture layers, BLoC with @freezed, Either error handling |
| **flutter-reviewer** | Code review checklist: architecture compliance, type safety, performance |
| **flutter-tester** | Testing with mocktail and bloc_test, >80% coverage target |
| **orchestrator** | Pipeline automation: dev → review → test → iterate |
| **orchestrator-agents** | Multi-agent version with parallel subagents |

## Installation

### Option 1: Copy to project

```bash
# Clone
git clone https://github.com/USERNAME/flutter-clean-arch-skills.git

# Copy skills to your project
cp -r flutter-clean-arch-skills/skills/* your-project/.claude/skills/
```

### Option 2: Personal skills (all projects)

```bash
cp -r flutter-clean-arch-skills/skills/* ~/.claude/skills/
```

## Usage

Skills activate automatically or via triggers:

```
# Development (auto-activates when editing lib/)
"Create user profile feature"

# Review
"Review my code" or "/flutter-reviewer"

# Testing
"Write tests" or "/flutter-tester"

# Full pipeline
"Execute task-1.md" or "/orchestrator"
```

## Architecture Overview

```
lib/
├── core/           # Shared utilities, errors, DI
├── data/           # API, repositories, models
├── domain/         # Entities, use cases (business logic)
├── presentation/   # Features, BLoCs, UI
└── resources/      # Colors, styles, localization
```

## Key Patterns Enforced

### Type Safety
```dart
// FORBIDDEN
Map<String, dynamic> data;

// REQUIRED
@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String name,
  }) = _UserEntity;
}
```

### BLoC Events & States
```dart
// REQUIRED - @freezed
@freezed
class UserEvent with _$UserEvent {
  const factory UserEvent.load(String id) = _Load;
}

@freezed
class UserState with _$UserState {
  const factory UserState.initial() = _Initial;
  const factory UserState.loading() = _Loading;
  const factory UserState.loaded(UserEntity user) = _Loaded;
  const factory UserState.error(AppError error) = _Error;
}
```

### Error Handling
```dart
// REQUIRED - Either<AppError, T>
Future<Either<AppError, User>> getUser(String id);

// Usage in BLoC
result.fold(
  (error) => emit(UserState.error(error)),
  (user) => emit(UserState.loaded(user)),
);
```

## Orchestrator Pipeline

```
┌─────────────────────────────────────────┐
│  1. PARSE    - Read task file           │
│  2. PLAN     - Break into subtasks      │
│  3. DEVELOP  - Implement (flutter-dev)  │
│  4. REVIEW   - Validate (flutter-review)│
│  5. TEST     - Cover (flutter-tester)   │
│  6. ITERATE  - Fix issues, repeat 4-5   │
│  7. COMPLETE - All checks pass          │
└─────────────────────────────────────────┘
```

## Task File Format

Create `task-*.md` files for orchestrator:

```markdown
# Task: Feature Name

## Description
What needs to be implemented.

## Requirements
- Requirement 1
- Requirement 2

## Acceptance Criteria
- [ ] Criteria 1
- [ ] Criteria 2
```

## License

MIT
