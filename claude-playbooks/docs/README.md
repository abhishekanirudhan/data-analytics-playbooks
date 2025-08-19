# Claude Code Workflow Automation

This directory contains automated workflow tools that enhance Claude Code's efficiency and context management across sessions.

## Quick Start

When launching Claude Code in any project, it will automatically:

1. **Analyze project structure** using advanced Python-based analysis
2. **Set up context management** with `.claude-context/` directory  
3. **Initialize task tracking** across sessions
4. **Create handoff documentation** for session continuity

## Files Structure

```
~/.claude/
├── CLAUDE.md              # Global instructions (auto-executes workflow)
├── scripts/
│   ├── auto-launch.sh     # Main automation script
│   ├── context-analyzer.py # Advanced project analysis  
│   └── task-manager.sh    # Task management utilities
├── workflows/
│   ├── project-analyzer.md # Analysis workflow documentation
│   └── session-handoff.md  # Session continuity workflow
└── templates/
    ├── project-overview.md  # Template for project analysis
    └── session-handoff.md   # Template for session transitions
```

## Generated Project Context

Each project gets a `.claude-context/` directory with:

- **project-overview.md** - Comprehensive project analysis
- **session-state.md** - Current work state and handoffs  
- **task-tracker.md** - Cross-session task management
- **decisions.md** - Technical decisions and rationale
- **handoffs/** - Session transition logs

## Task Management Commands

```bash
# Add a new task
~/.claude/scripts/task-manager.sh add "Implement user authentication" high

# Mark task as completed  
~/.claude/scripts/task-manager.sh complete "Implement user authentication"

# Update task progress
~/.claude/scripts/task-manager.sh update "Implement user authentication" "Added login form"

# Show current tasks
~/.claude/scripts/task-manager.sh show

# Generate session summary
~/.claude/scripts/task-manager.sh summary
```

## Features

### 🔍 **Intelligent Project Analysis**
- Detects project type, languages, and frameworks
- Identifies build tools, test frameworks, and linting setup
- Analyzes git repository status and recent commits
- Scans project structure and documentation

### 📋 **Cross-Session Task Management**
- Persistent task tracking between Claude Code sessions
- Priority-based task organization  
- Progress tracking with timestamps
- Automatic task archiving and cleanup

### 🤝 **Session Handoff System**
- Comprehensive context preservation
- Structured session transition documentation
- Decision logging with rationale
- Progress state management

### 🚀 **Automated Workflow**
- Zero-configuration setup
- Runs automatically on Claude Code launch
- Fallback mechanisms for different environments
- Template-based consistent documentation

## Research-Based Optimizations

This system implements findings from research on:
- Multi-session AI context management (LCMP protocol)
- Semantic context discovery and preservation
- Task continuity and handoff mechanisms
- Workflow efficiency patterns for AI-assisted development

## Configuration

The system is automatically configured through `~/.claude/CLAUDE.md`. No additional setup required.

## Troubleshooting

If the automatic workflow doesn't run:
1. Check that `~/.claude/CLAUDE.md` contains the launch instructions
2. Ensure scripts have execute permissions: `chmod +x ~/.claude/scripts/*.sh`
3. Verify Python3 is available for advanced analysis
4. Run manually: `source ~/.claude/scripts/auto-launch.sh`

---

*Generated automatically to support Claude Code workflow optimization*