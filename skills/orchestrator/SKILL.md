---
name: orchestrator
description: |
  Development pipeline orchestrator for Flutter projects.

  ACTIVATION: Use this skill when user says "execute task", "исполни задачу", "implement feature", "реализуй фичу", or references a task-*.md file.

  USE CASES: Orchestrating full development cycle from task file to tested, reviewed code. Manages pipeline: development → review → testing → iteration.
---

# Development Orchestrator

## Overview

Orchestrates the full development pipeline for Flutter features. Reads task specifications, implements code, reviews, tests, and iterates until quality standards are met.

## Pipeline Stages

```
┌─────────────────────────────────────────────────────────────────┐
│                    ORCHESTRATOR PIPELINE                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. PARSE      Read task-*.md, extract requirements             │
│       ↓                                                         │
│  2. PLAN       Break into subtasks, identify affected files     │
│       ↓                                                         │
│  3. DEVELOP    Implement using flutter-dev patterns             │
│       ↓                                                         │
│  4. REVIEW     Validate using flutter-reviewer checklist        │
│       ↓                                                         │
│  5. TEST       Write tests using flutter-tester patterns        │
│       ↓                                                         │
│  6. ITERATE    Fix issues from review/tests, repeat 4-5         │
│       ↓                                                         │
│  7. COMPLETE   All checks pass, summarize changes               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Execution Protocol

### Stage 1: PARSE

```markdown
## Parsing Task: [filename]

**Requirements extracted:**
- [ ] Requirement 1
- [ ] Requirement 2

**Acceptance criteria:**
- [ ] Criteria 1
- [ ] Criteria 2

**Dependencies identified:**
- Existing code: [files]
- New code needed: [files]
```

### Stage 2: PLAN

Use TodoWrite to create task breakdown:

```markdown
## Implementation Plan

### Files to create:
1. lib/domain/entity/feature_entity.dart
2. lib/domain/usecases/feature_usecase.dart
3. lib/data/repository/feature_repository_impl.dart
4. lib/presentation/feature/bloc.dart
5. lib/presentation/feature/events.dart
6. lib/presentation/feature/states.dart
7. lib/presentation/feature/view/feature_page.dart

### Files to modify:
1. lib/core/di/injection.dart - register dependencies
```

### Stage 3: DEVELOP

Switch to **flutter-dev** mode:

1. Create files following Clean Architecture order:
   - Domain entities first
   - Domain use cases
   - Data repositories
   - Presentation BLoC
   - UI components

2. Apply all flutter-dev rules:
   - @freezed for events/states
   - Either<AppError, T> for errors
   - Type-safe models
   - AppColors, AppTextStyles, AppLocalization

3. Run build_runner after @freezed changes:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

### Stage 4: REVIEW

Switch to **flutter-reviewer** mode:

Perform self-review checklist:

```markdown
## Self-Review

### Architecture Compliance
- [ ] Files in correct layers
- [ ] Dependencies point inward
- [ ] No cross-feature dependencies

### Type Safety
- [ ] No Map<String, dynamic>
- [ ] No dynamic types
- [ ] All events/states use @freezed

### BLoC Patterns
- [ ] Individual event handlers
- [ ] Proper state emissions
- [ ] Either error handling

### UI Standards
- [ ] AppColors used
- [ ] AppTextStyles used
- [ ] AppLocalization for strings
- [ ] SVGImage() for SVGs

### Issues Found:
1. [CRITICAL] file:line - description
2. [WARNING] file:line - description
```

**If issues found → Go to Stage 6 (ITERATE)**

### Stage 5: TEST

Switch to **flutter-tester** mode:

1. Create test files mirroring source structure
2. Write tests for:
   - Use cases (unit tests)
   - Repositories (unit tests)
   - BLoCs (bloc_test)
   - Key widgets (widget tests)

3. Run tests:
   ```bash
   flutter test
   ```

4. Check coverage:
   ```bash
   flutter test --coverage
   ```

**If tests fail → Go to Stage 6 (ITERATE)**

### Stage 6: ITERATE

```markdown
## Iteration [N]

### Issues to fix:
1. Review issue: [description] → [fix]
2. Test failure: [description] → [fix]

### Changes made:
- file.dart: [what changed]
```

After fixes:
- Re-run Stage 4 (REVIEW)
- Re-run Stage 5 (TEST)
- Repeat until all pass

**Max iterations: 3** - if still failing, report to user with details.

### Stage 7: COMPLETE

```markdown
## Task Complete ✓

### Summary
- Files created: [count]
- Files modified: [count]
- Tests written: [count]
- Coverage: [X]%

### Created Files:
- lib/domain/entity/feature_entity.dart
- lib/domain/usecases/feature_usecase.dart
- ...

### Modified Files:
- lib/core/di/injection.dart

### Test Results:
All [N] tests passing

### Next Steps (if any):
- Manual testing recommended for: [areas]
- Integration with: [other features]
```

## Task File Format

Expected format for `task-*.md`:

```markdown
# Task: [Feature Name]

## Description
Brief description of what needs to be implemented.

## Requirements
- Requirement 1
- Requirement 2

## Acceptance Criteria
- [ ] Criteria 1
- [ ] Criteria 2

## Technical Notes (optional)
- API endpoint: /api/v1/feature
- Design reference: [link]

## Out of Scope
- What NOT to implement
```

## Error Handling

### Build Errors
```bash
# If build_runner fails
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Test Errors
1. Read error message carefully
2. Check if mock is missing
3. Verify test setup
4. Fix and re-run

### Unresolvable Issues
If stuck after 3 iterations:
```markdown
## Blocked: [Issue]

**Attempted fixes:**
1. Fix 1 - result
2. Fix 2 - result
3. Fix 3 - result

**Needs user input:**
- Question or decision needed
```

## Quality Gates

Each stage has quality gates that must pass:

| Stage | Gate | Criteria |
|-------|------|----------|
| DEVELOP | Build | `flutter build` succeeds |
| REVIEW | Critical | Zero [CRITICAL] issues |
| TEST | Pass | All tests pass |
| TEST | Coverage | >80% on new code |

## Related Skills

- `flutter-dev` - Development patterns (Stage 3)
- `flutter-reviewer` - Review checklist (Stage 4)
- `flutter-tester` - Testing patterns (Stage 5)
