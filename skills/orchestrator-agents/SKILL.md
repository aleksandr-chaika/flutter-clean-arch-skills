---
name: orchestrator-agents
description: |
  Multi-agent orchestrator that spawns specialized subagents for development tasks.

  ACTIVATION: Use this skill when user says "execute with agents", "запусти агентов", "parallel development", or wants maximum automation with subagent delegation.

  USE CASES: Large features requiring parallel work, complex refactoring, full automation pipeline with independent agents for dev/review/test.
---

# Multi-Agent Orchestrator

## Overview

Spawns specialized subagents using the Task tool for parallel and sequential development workflows. Each agent operates independently with its own context and expertise.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      ORCHESTRATOR (Main Agent)                  │
│                                                                 │
│   Reads task → Plans work → Coordinates agents → Reports        │
└─────────────────────────────────────────────────────────────────┘
                              │
           ┌──────────────────┼──────────────────┐
           ▼                  ▼                  ▼
    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
    │  DEV AGENT  │    │REVIEW AGENT │    │ TEST AGENT  │
    │             │    │             │    │             │
    │ Implements  │───▶│  Validates  │───▶│   Tests     │
    │ features    │    │  quality    │    │   code      │
    └─────────────┘    └─────────────┘    └─────────────┘
```

## Agent Definitions

### Development Agent

```
Prompt template for Task tool:

You are a Flutter developer implementing a feature.

TASK FILE: {task_content}

RULES (from flutter-dev skill):
1. Use @freezed for all events and states
2. Use Either<AppError, T> for error handling
3. Follow Clean Architecture: Domain → Data → Presentation
4. Use AppColors, AppTextStyles, AppLocalization
5. Individual BLoC event handlers (not event.when())

DELIVER:
1. All source files with full implementation
2. Run build_runner after @freezed classes
3. List of created/modified files

DO NOT write tests - another agent handles that.
```

### Review Agent

```
Prompt template for Task tool:

You are a code reviewer for Flutter Clean Architecture.

FILES TO REVIEW: {file_list}

CHECKLIST (from flutter-reviewer skill):
- [ ] Architecture: dependencies point inward
- [ ] Type safety: no Map<String, dynamic>, no dynamic
- [ ] BLoC: individual handlers, proper state emissions
- [ ] UI: AppColors, AppTextStyles, AppLocalization, SVGImage
- [ ] Performance: const constructors, buildWhen

DELIVER:
1. Review report with [CRITICAL], [WARNING], [SUGGESTION] items
2. Specific file:line references
3. Code fixes for critical issues

Format: Standard review template from flutter-reviewer.
```

### Test Agent

```
Prompt template for Task tool:

You are a Flutter test engineer.

FILES TO TEST: {file_list}

RULES (from flutter-tester skill):
1. Use mocktail for mocking
2. Use bloc_test for BLoC tests
3. Given-When-Then pattern
4. Target >80% coverage
5. Test: happy path, error cases, edge cases

DELIVER:
1. Test files mirroring source structure
2. All tests passing
3. Coverage report
```

## Execution Modes

### Mode 1: Sequential Pipeline

```
1. Parse task file
2. Launch DEV AGENT → wait for completion
3. Launch REVIEW AGENT → wait for completion
4. If critical issues: return to step 2 with fixes
5. Launch TEST AGENT → wait for completion
6. If tests fail: return to step 2 with fixes
7. Complete
```

**Implementation:**

```markdown
## Step 1: Parse Task

Read task-*.md and extract requirements.

## Step 2: Development

Use Task tool:
- subagent_type: "general-purpose"
- prompt: [DEV AGENT prompt with task content]
- Wait for completion

## Step 3: Review

Use Task tool:
- subagent_type: "general-purpose"
- prompt: [REVIEW AGENT prompt with file list]
- Wait for completion

## Step 4: Handle Review Issues

If [CRITICAL] issues found:
- Create fix list
- Return to Step 2 with fixes as additional context

## Step 5: Testing

Use Task tool:
- subagent_type: "general-purpose"
- prompt: [TEST AGENT prompt with file list]
- Wait for completion

## Step 6: Handle Test Failures

If tests fail:
- Analyze failures
- Return to Step 2 with fix requirements
```

### Mode 2: Parallel Exploration + Sequential Execution

```
1. Parse task file
2. Launch EXPLORE agents in parallel:
   - Explore existing codebase patterns
   - Explore similar features
   - Explore test patterns
3. Synthesize exploration results
4. Execute sequential pipeline with context
```

**Implementation:**

```markdown
## Parallel Exploration Phase

Launch 3 Task agents simultaneously:

Task 1 (Explore):
- subagent_type: "Explore"
- prompt: "Find existing BLoC patterns in lib/presentation/"

Task 2 (Explore):
- subagent_type: "Explore"
- prompt: "Find repository patterns in lib/data/"

Task 3 (Explore):
- subagent_type: "Explore"
- prompt: "Find test patterns in test/"

## Synthesis

Combine exploration results into development context.

## Sequential Execution

Proceed with Mode 1 using enriched context.
```

### Mode 3: Background Agents

```
1. Launch DEV AGENT in background
2. Continue conversation with user
3. Check on agent progress
4. When complete, launch next stage
```

**Implementation:**

```markdown
## Background Development

Use Task tool with run_in_background: true

Check progress:
- Read output_file periodically
- Or use TaskOutput tool

## Foreground Interaction

While agent works:
- Discuss requirements with user
- Answer questions
- Plan next steps
```

## Task Tool Usage Examples

### Launch Dev Agent

```
Tool: Task
Parameters:
  description: "Implement user profile feature"
  subagent_type: "general-purpose"
  prompt: |
    You are implementing a Flutter feature.

    TASK:
    Create user profile screen with edit functionality.

    REQUIREMENTS:
    - UserEntity with name, email, avatar
    - GetUserUseCase, UpdateUserUseCase
    - UserBloc with LoadUser, UpdateUser events
    - UserProfilePage with edit form

    RULES:
    - @freezed for events/states
    - Either<AppError, T> for errors
    - Clean Architecture layers

    Create all necessary files and run build_runner.
```

### Launch Review Agent

```
Tool: Task
Parameters:
  description: "Review user profile implementation"
  subagent_type: "general-purpose"
  prompt: |
    Review these Flutter files for Clean Architecture compliance:

    FILES:
    - lib/domain/entity/user_entity.dart
    - lib/domain/usecases/get_user_usecase.dart
    - lib/presentation/profile/bloc.dart
    - lib/presentation/profile/view/profile_page.dart

    CHECK:
    - [ ] @freezed usage
    - [ ] Either error handling
    - [ ] No Map<String, dynamic>
    - [ ] Individual BLoC handlers
    - [ ] AppColors/AppTextStyles/AppLocalization

    Report issues as [CRITICAL], [WARNING], [SUGGESTION].
```

### Launch Test Agent

```
Tool: Task
Parameters:
  description: "Write tests for user profile"
  subagent_type: "general-purpose"
  prompt: |
    Write tests for user profile feature.

    SOURCE FILES:
    - lib/domain/usecases/get_user_usecase.dart
    - lib/domain/usecases/update_user_usecase.dart
    - lib/presentation/profile/bloc.dart

    REQUIREMENTS:
    - Use mocktail for mocks
    - Use bloc_test for BLoC
    - Given-When-Then pattern
    - Test success and error cases

    Create test files and verify all pass.
```

### Parallel Exploration

```
Tool: Task (call 3 times in single message)

Task 1:
  description: "Explore BLoC patterns"
  subagent_type: "Explore"
  prompt: "Find all BLoC implementations in lib/presentation/"

Task 2:
  description: "Explore repository patterns"
  subagent_type: "Explore"
  prompt: "Find repository implementations in lib/data/"

Task 3:
  description: "Explore test structure"
  subagent_type: "Explore"
  prompt: "Analyze test organization in test/"
```

## Iteration Protocol

```
MAX_ITERATIONS = 3

for iteration in 1..MAX_ITERATIONS:
    result = run_pipeline()

    if result.all_passed:
        return SUCCESS

    if iteration == MAX_ITERATIONS:
        return BLOCKED(result.issues)

    # Feed issues back to dev agent
    context.add(result.issues)
```

## Error Recovery

### Agent Timeout
```
If Task tool times out:
1. Check output_file for partial results
2. Resume agent with context
3. Or restart from last successful stage
```

### Agent Failure
```
If agent reports inability to complete:
1. Log failure reason
2. Simplify task scope
3. Retry with reduced requirements
4. Escalate to user if still failing
```

## Output Format

### Pipeline Report

```markdown
## Pipeline Execution Report

### Task: [name]

### Stages Completed:
1. ✓ PARSE - Requirements extracted
2. ✓ DEV - Implementation complete
3. ✓ REVIEW - No critical issues
4. ✓ TEST - All tests passing

### Iterations: 2
- Iteration 1: Review found 2 critical issues
- Iteration 2: All passed

### Agents Used:
- DEV AGENT: 1 invocation
- REVIEW AGENT: 2 invocations
- TEST AGENT: 1 invocation

### Files Created: 8
### Tests Written: 12
### Coverage: 85%

### Summary:
Feature implemented successfully with full test coverage.
```

## When to Use Which Mode

| Scenario | Mode |
|----------|------|
| Simple feature | Sequential (Mode 1) |
| Complex feature, need context | Parallel Explore + Sequential (Mode 2) |
| Long task, want to continue chatting | Background (Mode 3) |
| Multiple independent components | Parallel Dev agents |

## Limitations

1. **Context isolation** - Each agent has fresh context, must pass all needed info in prompt
2. **No shared state** - Agents cannot see each other's work directly
3. **Token limits** - Large codebases may need chunked processing
4. **Review quality** - Automated review catches patterns, not logic errors

## Related Skills

- `orchestrator` - Single-agent version (simpler, less overhead)
- `flutter-dev` - Development patterns for agents
- `flutter-reviewer` - Review checklist for agents
- `flutter-tester` - Test patterns for agents
