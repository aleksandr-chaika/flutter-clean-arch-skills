# Flutter Clean Architecture Skills

Complete development pipeline for **Flutter projects** with Clean Architecture and BLoC state management.

One orchestrator accepts a task and coordinates the **full pipeline** through isolated sub-agents.
**QE verification** via Maestro E2E tests. **Asana** integration for task management.

---

## Architecture v3 (Skills + Agents + Hooks + QE)

```
+-----------------------------------------------------------------------+
|  User: /orchestrator                                                    |
|              |                                                          |
|              v                                                          |
|  +----------------------------------+                                   |
|  |  orchestrator (Skill)            | <- Single user-invocable skill    |
|  |  Coordinates entire pipeline     |                                   |
|  +----------------+-----------------+                                   |
|                   | Task(subagent_type="...")                            |
|    +--------------+-----------------------------+                       |
|    v              v              v               v                      |
|  +--------+  +----------+  +----------+  +-------------+               |
|  |   PM   |  | Flutter  |  | Flutter  |  |   Maestro   |               |
|  |  agent  |  |   dev    |  | reviewer |  |   QE E2E    |               |
|  +----+---+  +----+-----+  +----+-----+  +------+------+               |
|       |           |              |               |                      |
|  flutter-pm  flutter-dev  flutter-reviewer  maestro-tester              |
|  (Asana)     flutter-tester                                             |
|                                                                         |
|  Knowledge Skills (preloaded into agents):                              |
|  flutter-guide | maestro-flutter                                        |
|                                                                         |
|  Hooks: Telegram notifications                                          |
|  (permission_prompt, task complete, agent complete)                      |
+-----------------------------------------------------------------------+
```

---

## Quick Start

### Installation

```bash
cd your-project
./path/to/flutter-clean-arch-skills/install.sh

# Or manually:
cp -r skills/* .claude/skills/
cp -r agents/* .claude/agents/
cp -r hooks/* .claude/hooks/
cp settings-hooks.json .claude/settings.json
```

### Usage

```
/orchestrator

Task: Create user profile screen with edit functionality
- Display user info
- Edit name and avatar
- Save to server
```

### With Asana Tasks

```
/orchestrator

Tasks from Asana:
- https://app.asana.com/0/PROJECT/TASK_1
- https://app.asana.com/0/PROJECT/TASK_2
```

**Orchestrator automatically:**
1. PM parses input, checks registry, plans test cases
2. flutter-dev implements features (Clean Architecture + BLoC)
3. flutter-reviewer reviews and fixes code
4. flutter-tester writes unit/widget/flow tests (80%+ coverage)
5. **maestro-tester** -- QE E2E verification via Maestro on emulator
6. Updates registry, generates final report

---

## Package Structure

```
flutter-clean-arch-skills/
├── skills/                          # 3 skills
│   ├── orchestrator/                # User-invocable (/orchestrator)
│   │   └── SKILL.md
│   ├── flutter-guide/               # Knowledge base (NOT user-invocable)
│   │   ├── SKILL.md
│   │   └── references/ (6 files)
│   └── maestro-flutter/             # QE knowledge base
│       ├── SKILL.md
│       └── references/ (2 files)
├── agents/                          # 5 agents
│   ├── flutter-pm.md               # PM (model: inherit, Asana + test cases)
│   ├── flutter-dev.md              # Flutter dev (model: sonnet)
│   ├── flutter-reviewer.md         # Flutter review (model: haiku)
│   ├── flutter-tester.md           # Flutter tests (model: sonnet)
│   └── maestro-tester.md           # QE E2E (model: sonnet, Maestro MCP)
├── hooks/
│   └── telegram-notify.sh          # Telegram notifications
├── settings-hooks.json             # Hook config
├── install.sh                      # Auto-installation
├── marketplace.json
└── README.md
```

---

## Skills vs Agents

| Aspect | Skills | Agents |
|--------|--------|--------|
| Context | Shared with main | Isolated |
| Tools | Inherited | Own set |
| Model | Current | Configurable (sonnet/haiku) |
| Invocation | `/orchestrator` | `Task(subagent_type="agent-name")` |
| Knowledge skills | `user-invocable: false` | Preloaded via `skills:` |

### Model Assignments

| Agent | Model | Reason |
|-------|-------|--------|
| flutter-pm | inherit | Full reasoning for decomposition + Asana parsing |
| flutter-dev | sonnet | Quality code generation |
| flutter-reviewer | haiku | Fast pattern matching |
| flutter-tester | sonnet | Quality test generation |
| maestro-tester | sonnet | QE E2E: flow generation + result analysis |

---

## Pipeline Flow

```
PHASE 1: PM ANALYSIS
    |  flutter-pm: Asana parsing -> registry lookup -> classify ->
    |  decompose -> Maestro test cases
    v
PHASE 2: TODO CHECKLIST
    |  Orchestrator creates TodoWrite from PM plan
    v
PHASE 3: EXECUTE (sequential agents)
    |  flutter-dev -> domain -> data -> presentation
    v
PHASE 4: REVIEW (auto-fix)
    |  flutter-reviewer: fix all issues, max 3 cycles
    v
PHASE 5: TESTS (MANDATORY -- unit/widget/flow)
    |  flutter-tester: BLoC + widget + flow tests, 80%+ coverage
    v
PHASE 6: QE E2E (MANDATORY for UI tasks)
    |  maestro-tester: TestKeys -> YAML flows -> build -> run on emulator
    v
PHASE 7: CLOSE
    |  Update REGISTRY.md -> Final report
    v
COMPLETE
```

---

## Stack

| Technology | Purpose |
|-----------|---------|
| Flutter 3.x | UI framework |
| flutter_bloc | State management (BLoC pattern) |
| freezed | Immutable models, events, states |
| Dio | HTTP client |
| Dartz | Either error handling |
| GetIt | Dependency injection |
| mocktail | Test mocking |
| bloc_test | BLoC testing |
| Maestro | E2E testing |

---

## Quality Gates

| Stage | Check | Criteria |
|-------|-------|----------|
| PM | Maestro Test Cases | >=3 TC for Flutter features |
| DEVELOP | Build | `flutter build` succeeds |
| DEVELOP | Analyze | `flutter analyze` zero issues |
| REVIEW | Critical | Zero [CRITICAL] issues |
| TEST | Pass | All tests pass |
| TEST | Coverage | >=80% on new code |
| **QE** | **maestro test** | **All TC PASS** |

---

## Testing Pyramid

```
          +-------------------+
          |     Maestro       |  10% -- E2E user journeys
          |    (QE Phase 6)   |  Real emulator/device
          +--------+----------+
                   |
        +----------+----------+
        |  Widget + Flow Tests |  20% -- UI + state management
        |    (Phase 5)         |  flutter-tester
        +----------+----------+
                   |
  +----------------+----------------+
  |           Unit Tests             |  70% -- Business logic
  |  flutter-tester: BLoC, UseCases  |  mocktail, bloc_test
  +----------------------------------+
```

---

## Telegram Hooks

Automatic Telegram notifications:
- **Permission prompt** -- when Claude waits for confirmation
- **Task complete** -- when main task is done
- **Agent complete** -- when a sub-agent finishes

Setup (env vars):
```bash
export TELEGRAM_BOT_TOKEN="your-token"
export TELEGRAM_CHAT_ID="your-chat-id"
```

---

## Examples

### Full feature
```
/orchestrator
Create user profile screen with edit functionality
```

### Asana task
```
/orchestrator
https://app.asana.com/0/1234567890/9876543210
```

### Bug fix
```
/orchestrator
BLoC does not update list after deleting an item
```

### Multiple Asana tasks
```
/orchestrator
Tasks:
- https://app.asana.com/0/PROJECT/TASK_1
- https://app.asana.com/0/PROJECT/TASK_2
```

---

## License

MIT
