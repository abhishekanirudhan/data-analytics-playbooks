# Claude Code Workflow Automation - Quick Start Guide

## 🎯 Purpose

This playbook sets up an intelligent workflow automation system that makes Claude Code automatically:
- Analyze and understand your projects
- Maintain context between sessions
- Track tasks persistently
- Create documentation for session handoffs

## ⚡ 30-Second Setup

```bash
cd ~/Projects/playbooks/claude-playbooks
./install.sh
```

That's it! Claude Code will now automatically run the workflow when you launch it in any project.

## 📦 What Gets Installed

Location: `~/.claude/`

- **CLAUDE.md** - Global instructions that Claude reads on every launch
- **scripts/** - Automation scripts for project analysis and task management
- **templates/** - Document templates for consistent formatting
- **workflows/** - Workflow documentation and guides

## 🔄 How It Works

1. **You:** Launch Claude Code in any project
2. **Claude:** Automatically reads `~/.claude/CLAUDE.md`
3. **System:** Runs project analysis workflow
4. **Result:** Creates `.claude-context/` with project analysis, task tracking, and session state

## 📁 Files in This Playbook

```
claude-playbooks/
├── install.sh           # One-click installer
├── README.md           # Full documentation
├── QUICKSTART.md       # This file
├── VERIFICATION.md     # Testing guide
├── CLAUDE.md.template  # Global instructions
├── scripts/            # Core automation
├── templates/          # Document templates
└── workflows/          # Workflow guides
```

## ✅ Verify Installation

After installing, test it:

```bash
# Quick verification
ls ~/.claude/CLAUDE.md && echo "✅ Installed" || echo "❌ Not installed"

# Full test
cd ~/any-project
source ~/.claude/scripts/auto-launch.sh
ls .claude-context/
```

## 🛠️ Daily Usage

Claude will automatically run the workflow, but you can also:

```bash
# Add a task
~/.claude/scripts/task-manager.sh add "Build new feature" high

# Show tasks
~/.claude/scripts/task-manager.sh show

# Complete a task
~/.claude/scripts/task-manager.sh complete "Build new feature"
```

## 🔧 Troubleshooting

If automation doesn't run:

1. Check installation: `ls ~/.claude/`
2. Test manually: `source ~/.claude/scripts/auto-launch.sh`
3. See VERIFICATION.md for detailed troubleshooting

## 📚 Learn More

- **README.md** - Complete feature documentation
- **VERIFICATION.md** - Testing and troubleshooting
- **docs/** - Additional documentation

## 🚀 Next Steps

1. ✅ Run `./install.sh`
2. ✅ Launch Claude Code in any project
3. ✅ Watch it automatically analyze your project
4. ✅ Start using task management
5. ✅ Enjoy seamless session continuity!

---

**Setup Time:** < 1 minute  
**No configuration required**  
**Works with all projects**