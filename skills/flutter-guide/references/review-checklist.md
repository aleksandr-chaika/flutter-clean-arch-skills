# Code Review Checklist

## Pre-Review Checks

- [ ] Branch is feature/bugfix, NOT main/develop
- [ ] Branch is up-to-date with target branch
- [ ] Target branch identified
- [ ] All changed files listed

---

## For Each Changed File

### Structure & Organization

- [ ] File is in correct directory according to Clean Architecture
- [ ] File name follows naming conventions (`snake_case.dart`)
- [ ] File responsibility is clear and single
- [ ] Reason for change is understandable
- [ ] No unrelated changes in the file

### Clean Architecture Compliance

- [ ] Presentation layer files in `lib/presentation/`
- [ ] Domain layer files in `lib/domain/`
- [ ] Data layer files in `lib/data/`
- [ ] Dependencies point inward only
- [ ] No imports from outer layers to inner layers
- [ ] No cross-feature direct dependencies

### Type Safety

- [ ] NO `Map<String, dynamic>` for data transfer
- [ ] NO `dynamic` type anywhere
- [ ] ALL events use `@freezed`
- [ ] ALL states use `@freezed`
- [ ] ALL data models are typed
- [ ] API responses converted to models immediately
- [ ] No manual `copyWith`/`equals` implementations

### BLoC Patterns

- [ ] Individual event handlers (`on<_EventName>`)
- [ ] NO `event.when()` in handlers
- [ ] NO `state.when()` in handlers
- [ ] NO single handler for all events
- [ ] Proper state emissions
- [ ] `Either<AppError, T>` for error handling
- [ ] Repository calls wrapped in error handling

### Code Quality

- [ ] Variable names are descriptive
- [ ] Function names describe their action
- [ ] Class names follow conventions
- [ ] Code is readable without excessive comments
- [ ] No logic errors detected
- [ ] Edge cases are handled
- [ ] Code is modular
- [ ] No unnecessary duplication (DRY)
- [ ] Errors and exceptions handled appropriately

### UI Standards

- [ ] Uses `AppColors` (no hardcoded `Color(0xFF...)`)
- [ ] Uses `AppTextStyles` (no inline `TextStyle()`)
- [ ] Uses `AppLocalization` (no hardcoded user strings)
- [ ] Uses `SVGImage()` (not `SvgPicture.asset()`)
- [ ] `const` constructors where possible
- [ ] Widget classes, not functions returning widgets
- [ ] `BlocBuilder` has `buildWhen` where appropriate
- [ ] `ListView.builder` for lists (not `ListView` with children)

### Security

- [ ] Input validation present where needed
- [ ] No secrets/credentials in code
- [ ] No API keys hardcoded
- [ ] No sensitive data in logs
- [ ] No SQL injection risks
- [ ] No XSS vulnerabilities
- [ ] Proper authentication checks

### Performance

- [ ] `const` constructors used everywhere possible
- [ ] No expensive operations in `build()` methods
- [ ] No unnecessary rebuilds
- [ ] Proper caching where needed
- [ ] No memory leaks (disposed controllers/streams)
- [ ] Images are properly sized/cached

### Documentation

- [ ] Public APIs documented (if library code)
- [ ] Complex logic has explanatory comments
- [ ] Non-obvious decisions are documented
- [ ] TODO/FIXME have associated ticket numbers

### Testing

- [ ] Unit tests for new domain logic
- [ ] Widget tests for new UI components
- [ ] BLoC tests for new state management
- [ ] Tests actually test the implementation
- [ ] Tests could realistically fail
- [ ] Edge cases are tested
- [ ] Error scenarios are tested

### Style

- [ ] Matches project's style guide
- [ ] Follows established patterns in codebase
- [ ] Consistent formatting (dart format)
- [ ] No unused imports
- [ ] No unused variables/parameters

---

## Generated Files

- [ ] `*.g.dart` files are up-to-date
- [ ] `*.freezed.dart` files are up-to-date
- [ ] Generated files are not manually edited
- [ ] `build_runner` was executed after changes

---

## Overall Review

- [ ] Change set is focused on stated purpose
- [ ] No unrelated or unnecessary changes
- [ ] PR description accurately reflects changes
- [ ] All CI tests pass
- [ ] No breaking changes (or documented if intentional)
- [ ] Backwards compatibility maintained (or noted)

---

## Review Decision

| Decision | Criteria |
|----------|----------|
| **Approve** | No critical issues, minor issues can be fixed later |
| **Request Changes** | Critical issues must be fixed before merge |
| **Comment** | Questions need answers before decision |

---

## Feedback Checklist

- [ ] All critical issues marked as `[CRITICAL]`
- [ ] Warnings are actionable
- [ ] Suggestions are constructive
- [ ] Good practices acknowledged
- [ ] Tone is professional and helpful
- [ ] Solutions provided, not just problems
