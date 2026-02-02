---
name: flutter-reviewer
description: |
  Code review skill for Flutter projects with Clean Architecture and BLoC.

  ACTIVATION: Use this skill when the user requests code review, PR review, or asks to check code quality. Triggers on phrases like "review", "ревью", "проверь код", "code review", "посмотри PR".

  USE CASES: Reviewing pull requests, checking code quality against project standards, validating Clean Architecture compliance, verifying @freezed usage, checking error handling patterns, reviewing test coverage.
---

# Flutter Code Review

## Overview

Expert code reviewer for Flutter projects with Clean Architecture and BLoC. Validates code against project standards, identifies issues, and provides constructive feedback.

## When to Use

- Reviewing pull requests
- Checking code quality
- Validating architecture compliance
- Pre-merge code review
- Code audit

## Review Process

### Step 1: Pre-Review Checks

1. **Branch verification**
   - Verify branch is feature/bugfix, NOT main/develop
   - Check branch is up-to-date with target branch

2. **Scope understanding**
   - Identify target branch
   - List all changed files
   - Understand the purpose of changes

### Step 2: File-by-File Review

For each changed file, check:

#### Architecture Compliance

- [ ] File is in correct layer (presentation/domain/data)
- [ ] Dependencies point inward (Clean Architecture rule)
- [ ] No cross-feature dependencies
- [ ] Proper separation of concerns

#### Type Safety

- [ ] NO `Map<String, dynamic>` for data models
- [ ] NO `dynamic` type usage
- [ ] ALL events and states use `@freezed`
- [ ] ALL data models are typed
- [ ] API responses converted to typed models immediately

#### BLoC Patterns

- [ ] Individual event handlers (not `event.when()`)
- [ ] No `state.when()` in BLoC handlers
- [ ] Proper state emissions
- [ ] Error handling with `Either<AppError, T>`

#### Code Quality

- [ ] Descriptive variable/function/class names
- [ ] Readable and consistent code
- [ ] No logic errors or missing edge cases
- [ ] Modular code, no unnecessary duplication
- [ ] Proper error handling

#### UI Standards

- [ ] Uses `AppColors` (no hardcoded colors)
- [ ] Uses `AppTextStyles` (no inline styles)
- [ ] Uses `AppLocalization` (no hardcoded strings)
- [ ] Uses `SVGImage()` not `SvgPicture.asset()`
- [ ] Const constructors where possible

#### Security

- [ ] Input validation present
- [ ] No secrets/credentials in code
- [ ] No SQL injection risks
- [ ] No sensitive data logging

#### Performance

- [ ] `const` constructors used
- [ ] `ListView.builder` for large lists
- [ ] `buildWhen` in BlocBuilder
- [ ] No expensive operations in build methods

### Step 3: Generated Files Check

- [ ] Generated files are up-to-date (`*.g.dart`, `*.freezed.dart`)
- [ ] Generated files are not manually edited
- [ ] `build_runner` was executed after changes

### Step 4: Test Coverage

- [ ] Unit tests for new domain logic
- [ ] Widget tests for new UI components
- [ ] BLoC tests for new state management
- [ ] Tests actually test implementation (not just mocks)

## Feedback Format

### Categories

| Level | Icon | When to Use |
|-------|------|-------------|
| **Critical** | `[CRITICAL]` | Must fix before merge (bugs, security, architecture violations) |
| **Warning** | `[WARNING]` | Should fix (performance, maintainability) |
| **Suggestion** | `[SUGGESTION]` | Nice to have improvements |
| **Note** | `[NOTE]` | Information or questions |
| **Good** | `[GOOD]` | Acknowledge good practices |

### Feedback Template

```markdown
## Code Review: [Feature/PR Name]

### Summary
Brief overview of the review findings.

### Critical Issues
- `[CRITICAL]` file.dart:42 - Description of the issue
  ```dart
  // Current code
  ```
  **Suggested fix:**
  ```dart
  // Fixed code
  ```

### Warnings
- `[WARNING]` file.dart:15 - Description

### Suggestions
- `[SUGGESTION]` file.dart:78 - Description

### Good Practices
- `[GOOD]` Proper use of @freezed in events.dart
- `[GOOD]` Clean separation of concerns

### Checklist Summary
- [ ] Architecture: OK / Issues found
- [ ] Type Safety: OK / Issues found
- [ ] BLoC Patterns: OK / Issues found
- [ ] Tests: OK / Missing coverage
```

## Investigation Rule

Before concluding a change is incorrect:

1. Look up commit context
2. Check connected components
3. Review related files
4. Fetch documentation if unsure about best practices

If change remains unclear after investigation, include in report as `[NOTE]`.

## Common Issues to Watch

### Architecture Violations

```dart
// WRONG - Data layer importing presentation
import '../presentation/feature/bloc.dart';

// WRONG - Domain depending on data
import '../data/models/user_api_model.dart';
```

### Type Safety Violations

```dart
// WRONG
final Map<String, dynamic> data = response.data;
final title = data['title'] as String?;

// CORRECT
final UserApiModel model = UserApiModel.fromJson(response.data);
final title = model.title;
```

### BLoC Violations

```dart
// WRONG - event.when in handler
on<UserEvent>((event, emit) {
  event.when(/*...*/);
});

// WRONG - state.when in handler
void _onLoad(event, emit) {
  state.when(/*...*/);
}
```

## Additional Resources

- [Full review checklist](references/checklist.md)

## Related Skills

- `flutter-dev` - Development standards being validated
- `flutter-tester` - Test coverage requirements
