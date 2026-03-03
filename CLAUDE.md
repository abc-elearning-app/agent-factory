# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

**Agent Factory** is a standalone AI workflow tool — a single markdown workflow file (`agent-factory.md`) that can be installed into any project. When invoked via `/agent-factory "<description>"`, it auto-generates an AI agent definition file, runs it immediately, and refines it through a feedback loop.

There is no build system, package manager, or test runner. The "code" is markdown-based workflow instructions.

## Installation

```bash
# Install into the current project (run from target project root)
./install.sh
```

`install.sh` installs to all three supported IDEs simultaneously: `.claude/commands/` (Claude Code), `.gemini/commands/` (Gemini CLI), and `.agent/workflows/` (Antigravity). It optionally copies example agents to the detected agent directory.

## Usage

After installation, invoke in any AI IDE that supports workflows:

```
/agent-factory "thu thập tiêu đề bài viết từ VnExpress"
/agent-factory "review Python code for security issues"
/agent-factory "analyze data from a CSV file"
```

## Key Files

- `agent-factory.md` — The main workflow definition (source of truth). Symlinked from `.gemini/commands/` and `.agent/workflows/` within this repo.
- `agent-shared.md` — Companion workflow for browsing/installing agents from a shared team repository. Installed alongside `agent-factory.md`.
- `install.sh` — Copies both workflows into a target project (uses `cp`, not symlinks, for installed targets).
- `new-project.sh` — Creates a project workspace: `projects/<name>/` folder + dedicated `project/<name>` branch. Each project lives on its own branch; `projects/` is gitignored on `main`.
- `examples/` — Three reference agent files: `web-scraper.md`, `code-reviewer.md`, `data-analyzer.md`.
- `agent-factory-claude/` — Phase 1 Claude Code-specific builder (command + subagent + templates + validator). Superseded by the unified `agent-factory.md`.
- `agent-factory-gemini/` — Phase 1 Gemini CLI-specific builder. Same structure as `agent-factory-claude/`.

## Agent File Format

Generated agents use YAML frontmatter + markdown system prompt:

```yaml
---
name: kebab-case-name          # Required: [a-z0-9-], 3-40 chars
description: action-oriented description ≥10 words  # Required
tools: Read, Glob, Grep        # Required: comma-separated string
model: inherit                 # Required: sonnet|opus|haiku|inherit
color: green                   # Required: blue|green|red|purple|orange
field: data                    # Optional: frontend|backend|testing|security|data|ai|...
expertise: expert              # Optional: beginner|intermediate|expert
---

System prompt content here...
```

Generated agents are saved to the first detected directory: `./agents/` → `.claude/agents/` → `.agent/agents/`.

## Architecture: The Workflow Pipeline

The `agent-factory.md` workflow runs these steps:

1. **Preflight** — Validate description, detect/create agent directory.
2. **Clarification** (conditional) — Ask ≤3 questions if description < 20 words and lacks input source, output format, or task scope.
3. **Type Classification** — Auto-detect one of 4 agent types by keyword matching (supports EN + VI).
4. **Learn Format** — Read an existing agent or example file to infer format conventions.
5. **Generate Agent** — Name (kebab-case), select tools (3-tier safety model), write system prompt, create file, validate (3-step).
6. **Immediate Execution** — Spawn the generated agent via Task tool.
7. **Refinement Loop** — Accept feedback, update agent definition, re-run (max 10 iterations).

## Agent Types & Tool Safety

| Type | Color | Default Tools | Parallelism |
|------|-------|---------------|-------------|
| Strategic | blue | Read, Glob, Grep, WebFetch, WebSearch | Up to 4-5 agents |
| Implementation | green | Read, Write, Edit, Glob, Grep (+ask Bash) | Up to 2-3 agents |
| Quality | red | Read, Write, Edit, Bash, Glob, Grep | Sequential only |
| Coordination | purple | Read, Glob, Grep (+ask Task/Agent) | Lightweight |

**3-tier tool safety:**
- **Safe** (auto): Read, Glob, Grep, LS, WebFetch, WebSearch
- **Cautious** (auto + warn): Write, Edit, NotebookEdit
- **Restricted** (always ask user): Bash, Task, Agent

## Tests

Smoke and integration tests live in `tests/e2e/` and `tests/integration/`, organized under `epic_agent-factory/` and `epic_agent-factory-gemini/`. They are plain Python files with no external test runner configured — run directly with:

```bash
python tests/e2e/epic_agent-factory/test_smoke_01_deliverables.py
python tests/integration/epic_agent-factory/test_integration_validator_refinement.py
```

The Phase 1 validator has its own bash test runner:

```bash
bash agent-factory-claude/tests/run-validator-tests.sh
```

## Editing the Workflow

The canonical source is `agent-factory.md` in the repo root. Within this repo, `.gemini/commands/` and `.agent/workflows/` contain **committed symlinks** pointing back to the root file. `.claude/commands/` is gitignored — symlinks there are local only and must be re-created manually after a fresh clone. Edits to `agent-factory.md` auto-sync to Gemini CLI and Antigravity; Claude Code requires the local symlink to exist.

When modifying the workflow logic in `agent-factory.md`, keep these constraints:
- Clarification step: max 3 questions total
- Type detection: max 1 additional fallback question
- Refinement loop: suggest restart at iteration 5, hard stop at iteration 10
- Tool safety tiers must not be relaxed without explicit user confirmation
