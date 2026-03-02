# Agent Factory for Claude Code

Meta-agent that generates Claude Code slash commands and subagents from natural language descriptions in Vietnamese.

## Installation

```bash
# From agent-factory-claude directory:
bash install.sh /path/to/your/project

# Or from your project directory:
bash /path/to/agent-factory-claude/install.sh
```

## Usage

In your Claude Code project, run:

```
/agent-factory
```

Or with a description:

```
/agent-factory tạo command đếm số dòng trong file
```

The agent builder will:
1. Ask 3-5 clarifying questions in Vietnamese
2. Auto-detect whether to create a command or agent
3. Generate the file with correct format
4. Validate and auto-fix (up to 5 rounds)
5. Install to the correct directory
6. Explain how to use it

## What Gets Generated

- **Slash commands** → `.claude/commands/<name>.md`
- **Subagents** → `.claude/agents/<name>.md`

## Requirements

- Claude Code CLI (latest stable)
- No other dependencies
