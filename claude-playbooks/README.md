# Claude Code Workflow Automation Playbook

Complete setup guide for implementing Claude Code's automated workflow system on any machine.

## 🚀 Quick Installation

```bash
# Clone or download this playbook
cd ~/Projects/master-playbooks/claude-playbooks

# Run the installation script
./install.sh
```

## 📋 What This Installs

A comprehensive workflow automation system that:

1. **Auto-analyzes** projects when Claude Code launches
2. **Maintains context** between Claude sessions
3. **Tracks tasks** persistently across sessions
4. **Documents decisions** and technical choices
5. **Creates handoffs** for seamless session transitions

## 🗂️ Playbook Contents

```
claude-playbooks/
├── install.sh              # One-click installation script
├── README.md              # This file
├── CLAUDE.md.template     # Global instructions template
├── scripts/               # Core automation scripts
│   ├── auto-launch.sh     # Main workflow trigger
│   ├── context-analyzer.py # Advanced project analysis
│   └── task-manager.sh    # Task management utilities
├── templates/             # Document templates
│   ├── project-overview.md # Project analysis template
│   └── session-handoff.md  # Session transition template
├── workflows/             # Workflow documentation
│   ├── project-analyzer.md # Analysis workflow guide
│   └── session-handoff.md  # Handoff workflow guide
└── docs/                  # Additional documentation
    └── README.md          # Detailed system documentation
```

## 🔧 Manual Installation

If you prefer manual setup or the script fails:

### 1. Create Directory Structure
```bash
mkdir -p ~/.claude/{scripts,templates,workflows}
```

### 2. Copy Core Files
```bash
# Copy scripts
cp scripts/* ~/.claude/scripts/
chmod +x ~/.claude/scripts/*.sh
chmod +x ~/.claude/scripts/*.py

# Copy templates
cp templates/* ~/.claude/templates/

# Copy workflows
cp workflows/* ~/.claude/workflows/

# Copy CLAUDE.md
cp CLAUDE.md.template ~/.claude/CLAUDE.md
```

### 3. Verify Installation
```bash
# Check files exist
ls -la ~/.claude/scripts/auto-launch.sh
ls -la ~/.claude/CLAUDE.md

# Test the workflow
cd ~/any-project
source ~/.claude/scripts/auto-launch.sh
```

## 📖 How It Works

### On Every Claude Code Launch

Claude automatically reads `~/.claude/CLAUDE.md` which instructs it to:

1. Run `source ~/.claude/scripts/auto-launch.sh`
2. Analyze the current project structure
3. Create/update `.claude-context/` directory
4. Load any existing session state and tasks

### Generated Context Structure

Each project gets a `.claude-context/` directory:

```
.claude-context/
├── project-overview.md    # Auto-generated project analysis
├── session-state.md       # Current work state
├── task-tracker.md        # Persistent task list
├── decisions.md           # Technical decisions log
└── handoffs/             # Session transition files
```

### Task Management

Use the task manager throughout your work:

```bash
# Add a task
~/.claude/scripts/task-manager.sh add "Implement feature X" high

# Complete a task
~/.claude/scripts/task-manager.sh complete "Implement feature X"

# Show all tasks
~/.claude/scripts/task-manager.sh show

# Generate session summary
~/.claude/scripts/task-manager.sh summary
```

## 🎯 Key Features

### Intelligent Project Analysis
- Auto-detects languages, frameworks, and tools
- Identifies build commands and test suites
- Analyzes git status and recent commits
- Scans documentation and project structure

### Cross-Session Continuity
- Tasks persist between Claude sessions
- Session handoffs preserve context
- Decision logging maintains rationale
- Progress tracking with timestamps

### Zero Configuration
- Works immediately after installation
- No per-project setup required
- Automatic workflow triggering
- Fallback modes for different environments

## 🔍 Troubleshooting

### Workflow Not Running Automatically

1. Verify CLAUDE.md contains launch instructions:
```bash
cat ~/.claude/CLAUDE.md | grep "auto-launch"
```

2. Check script permissions:
```bash
ls -la ~/.claude/scripts/*.sh
# Should show executable permissions (x)
```

3. Test manually:
```bash
source ~/.claude/scripts/auto-launch.sh
```

### Python Analyzer Not Working

The system works without Python but with reduced features. To enable full analysis:

```bash
# Check Python installation
python3 --version

# If missing, install Python 3
# macOS: brew install python3
# Ubuntu: sudo apt-get install python3
# Windows: Download from python.org
```

### Context Files Not Created

1. Check working directory:
```bash
pwd  # Should be in a project directory
```

2. Verify script execution:
```bash
bash -x ~/.claude/scripts/auto-launch.sh
```

3. Check for errors in output

## 🔄 Updating the System

To update your installation with new features:

```bash
# Backup existing setup
cp -r ~/.claude ~/.claude.backup

# Run install script again
./install.sh
```

## 🤝 Contributing

To improve this playbook:

1. Test changes locally
2. Document new features
3. Update both the playbook and installed versions
4. Share improvements with the team

## 📚 Advanced Usage

### Customizing for Specific Projects

Add project-specific instructions to `.claude-context/project-instructions.md`:

```markdown
# Project-Specific Instructions

## Coding Standards
- Use 2-space indentation
- Follow ESLint configuration
- Write tests for all new features

## Workflow
- Create feature branches
- Run tests before committing
- Update documentation
```

### Creating Custom Templates

Add new templates to `~/.claude/templates/` for specific workflows:

```bash
# Create a bug fix template
cat > ~/.claude/templates/bug-fix.md << 'EOF'
# Bug Fix Session

## Issue Description
[Describe the bug]

## Root Cause Analysis
[Investigation findings]

## Solution Approach
[How to fix it]

## Testing Plan
[How to verify the fix]
EOF
```

### Integrating with Git Hooks

Add to `.git/hooks/post-checkout`:

```bash
#!/bin/bash
# Auto-run Claude workflow on branch switch
if [ -f ~/.claude/scripts/auto-launch.sh ]; then
    source ~/.claude/scripts/auto-launch.sh
fi
```

## 📊 Performance Impact

- Initial analysis: ~2-5 seconds for most projects
- Context file generation: < 1 second
- Task operations: Instant
- Memory usage: Minimal (text files only)
- No background processes

## 🔒 Security Considerations

- All files stored locally in your home directory
- No network requests or external dependencies
- No sensitive data collection
- Git-ignored by default (add `.claude-context` to `.gitignore`)

## 📝 License

This workflow automation system is provided as-is for productivity enhancement.

---

**Version:** 1.0.0  
**Last Updated:** 2025  
**Compatibility:** Claude Code (all versions)