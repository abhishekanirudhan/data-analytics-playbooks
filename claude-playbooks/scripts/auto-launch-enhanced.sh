#!/bin/bash

# Claude Code Enhanced Auto-Launch Workflow
# Integrates hooks and subagents for intelligent automation

PROJECT_ROOT="$(pwd)"
CLAUDE_DIR="$PROJECT_ROOT/.claude"
CLAUDE_CONTEXT="$CLAUDE_DIR/context"
CLAUDE_HOME="$HOME/.claude"

echo "🤖 Initializing Enhanced Claude Workflow..."

# Function to check if hooks are available
check_hooks_available() {
    if [ -d "$CLAUDE_HOME/hooks" ] && [ "$(ls -A $CLAUDE_HOME/hooks/*.json 2>/dev/null)" ]; then
        return 0
    fi
    return 1
}

# Function to check if agents are available
check_agents_available() {
    if [ -d "$CLAUDE_HOME/agents" ] && [ "$(ls -A $CLAUDE_HOME/agents/*.json 2>/dev/null)" ]; then
        return 0
    fi
    return 1
}

# Function to trigger agent
trigger_agent() {
    local agent_name=$1
    local agent_file="$CLAUDE_HOME/agents/${agent_name}.json"
    
    if [ -f "$agent_file" ]; then
        echo "🔧 Triggering ${agent_name} agent..."
        # Create agent trigger file for Claude to detect
        cat > "$CLAUDE_CONTEXT/.agent_trigger" << EOF
{
  "agent": "${agent_name}",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "trigger_type": "auto_launch",
  "project_root": "${PROJECT_ROOT}"
}
EOF
        return 0
    fi
    return 1
}

# Initialize directory structure
echo "📁 Setting up enhanced context structure..."
mkdir -p "$CLAUDE_DIR"
mkdir -p "$CLAUDE_CONTEXT/handoffs"
mkdir -p "$CLAUDE_CONTEXT/test-results"
mkdir -p "$CLAUDE_CONTEXT/reviews"

# Step 1: Load Hooks Configuration
if check_hooks_available; then
    echo "🪝 Hooks detected - Configuring automated safety and workflow checks..."
    
    # Create hooks status file
    cat > "$CLAUDE_CONTEXT/hooks-status.md" << EOF
# Active Hooks

**Generated:** $(date)

## Enabled Hooks
EOF
    
    for hook in "$CLAUDE_HOME/hooks"/*.json; do
        if [ -f "$hook" ]; then
            hook_name=$(basename "$hook" .json)
            echo "- ✅ ${hook_name}" >> "$CLAUDE_CONTEXT/hooks-status.md"
        fi
    done
    
    echo "" >> "$CLAUDE_CONTEXT/hooks-status.md"
    echo "Hooks provide automated safety checks, context updates, and workflow enforcement." >> "$CLAUDE_CONTEXT/hooks-status.md"
else
    echo "⚠️  No hooks configured - Running in basic mode"
fi

# Step 2: Trigger Project Analyzer Agent
if check_agents_available && trigger_agent "project-analyzer"; then
    echo "📊 Project Analyzer agent triggered - Advanced analysis in progress..."
    
    # Wait briefly for agent to initialize
    sleep 1
    
    # Create placeholder if agent hasn't created the file yet
    if [ ! -f "$CLAUDE_CONTEXT/project-overview.md" ]; then
        cat > "$CLAUDE_CONTEXT/project-overview.md" << EOF
# Project Overview

**Status:** Analysis in progress by project-analyzer agent...
**Started:** $(date)

The project-analyzer agent is performing comprehensive analysis including:
- Technology stack detection
- Project structure mapping
- Development environment identification
- Pattern and convention detection
- Improvement opportunity identification

This file will be updated automatically when analysis completes.
EOF
    fi
else
    echo "📊 Running fallback project analysis..."
    # Run the original Python analyzer as fallback
    if command -v python3 >/dev/null 2>&1 && [ -f "$CLAUDE_HOME/scripts/context-analyzer.py" ]; then
        python3 "$CLAUDE_HOME/scripts/context-analyzer.py" --path "$PROJECT_ROOT"
    else
        # Basic shell analysis fallback
        source "$CLAUDE_HOME/scripts/auto-launch.sh"
    fi
fi

# Step 3: Initialize Enhanced Session State
echo "🔄 Setting up intelligent session management..."
cat > "$CLAUDE_CONTEXT/session-state.md" << EOF
# Enhanced Session State

**Last Updated:** $(date)
**Session ID:** $(uuidgen 2>/dev/null || echo "session-$(date +%s)")
**Mode:** Enhanced (Hooks + Agents)

## Active Components
### Hooks
$(if check_hooks_available; then
    echo "- ✅ Safety Hook - Preventing destructive operations"
    echo "- ✅ Context Update Hook - Auto-maintaining session state"
    echo "- ✅ Git Workflow Hook - Enforcing best practices"
else
    echo "- ⚠️ No hooks configured"
fi)

### Agents
$(if check_agents_available; then
    echo "- 🤖 Project Analyzer - Comprehensive codebase analysis"
    echo "- 📋 Task Manager - Intelligent task prioritization"
    echo "- 🔍 Code Reviewer - Automated quality checks"
    echo "- 🔄 Session Handoff - Seamless context preservation"
    echo "- 🧪 Test Runner - Smart test execution"
else
    echo "- ⚠️ No agents configured"
fi)

## Current Status
- **State:** Initialized with enhanced capabilities
- **Active Tasks:** Awaiting task manager agent initialization
- **Blocking Issues:** None detected

## Automation Status
- **Hooks:** $(if check_hooks_available; then echo "Active"; else echo "Not configured"; fi)
- **Agents:** $(if check_agents_available; then echo "Available"; else echo "Not configured"; fi)
- **Context Updates:** Automatic
- **Safety Checks:** $(if check_hooks_available; then echo "Enabled"; else echo "Manual"; fi)

## Next Actions
1. Complete project analysis via agents
2. Initialize task management system
3. Configure project-specific workflows
EOF

# Step 4: Trigger Task Manager Agent
if check_agents_available && trigger_agent "task-manager"; then
    echo "📋 Task Manager agent triggered - Setting up intelligent task tracking..."
else
    # Fallback to basic task tracker
    cat > "$CLAUDE_CONTEXT/task-tracker.md" << EOF
# Task Tracker

**Last Updated:** $(date)
**Mode:** Basic (Agent not available)

## Pending Tasks
- [ ] Complete project analysis
- [ ] Review hooks and agents configuration
- [ ] Set up development environment
- [ ] Identify immediate work items

## Completed Tasks
- [x] Initialize enhanced workflow
- [x] Set up context management

## Notes
Task Manager agent is not configured. Using basic task tracking.
To enable intelligent task management, install the agent configurations.
EOF
fi

# Step 5: Create Agent Orchestration File
echo "🎭 Setting up agent orchestration..."
cat > "$CLAUDE_CONTEXT/agent-orchestration.md" << EOF
# Agent Orchestration Plan

**Generated:** $(date)

## Workflow Automation

### On Session Start
1. **project-analyzer** → Comprehensive project analysis
2. **task-manager** → Load and prioritize tasks
3. Context restoration from previous session

### During Development
- **Pre-commit:** code-reviewer → Automatic quality checks
- **File modifications:** Context hooks update session state
- **Task completion:** task-manager updates priorities

### On Session End
1. **session-handoff** → Generate comprehensive handoff
2. **task-manager** → Save task state
3. Archive session context

## Available Automations

### Safety Protocols
$(if [ -f "$CLAUDE_HOME/hooks/safety-hook.json" ]; then
    echo "- ✅ Destructive operation prevention"
    echo "- ✅ Sensitive file protection"
    echo "- ✅ Credential exposure scanning"
else
    echo "- ⚠️ Safety protocols not configured"
fi)

### Workflow Enhancements
$(if [ -f "$CLAUDE_HOME/hooks/git-workflow-hook.json" ]; then
    echo "- ✅ Git best practices enforcement"
    echo "- ✅ Automatic commit validation"
    echo "- ✅ Test reminder on commits"
else
    echo "- ⚠️ Git workflow automation not configured"
fi)

### Context Management
$(if [ -f "$CLAUDE_HOME/hooks/context-update-hook.json" ]; then
    echo "- ✅ Automatic session state updates"
    echo "- ✅ File modification tracking"
    echo "- ✅ Task status synchronization"
else
    echo "- ⚠️ Automatic context updates not configured"
fi)

## Agent Capabilities

$(if check_agents_available; then
    for agent in "$CLAUDE_HOME/agents"/*.json; do
        if [ -f "$agent" ]; then
            agent_name=$(basename "$agent" .json | tr '-' ' ' | sed 's/\b\(.\)/\u\1/g')
            echo "### ${agent_name}"
            case $(basename "$agent" .json) in
                "project-analyzer")
                    echo "- Deep codebase analysis"
                    echo "- Technology stack identification"
                    echo "- Pattern detection"
                    ;;
                "task-manager")
                    echo "- Intelligent prioritization"
                    echo "- Dependency tracking"
                    echo "- Progress monitoring"
                    ;;
                "code-reviewer")
                    echo "- Automated quality checks"
                    echo "- Security scanning"
                    echo "- Best practices validation"
                    ;;
                "session-handoff")
                    echo "- Comprehensive context capture"
                    echo "- State preservation"
                    echo "- Continuity optimization"
                    ;;
                "test-runner")
                    echo "- Smart test selection"
                    echo "- Coverage analysis"
                    echo "- Failure diagnosis"
                    ;;
            esac
            echo ""
        fi
    done
else
    echo "No agents configured. Install agent configurations to enable intelligent automation."
fi)
EOF

# Step 6: Create Quick Status Dashboard
echo "📊 Generating status dashboard..."
cat > "$CLAUDE_CONTEXT/dashboard.md" << EOF
# Claude Enhanced Workflow Dashboard

**Last Update:** $(date '+%Y-%m-%d %H:%M:%S')

## 🚀 Quick Status
| Component | Status | Details |
|-----------|--------|---------|
| Hooks | $(if check_hooks_available; then echo "✅ Active"; else echo "❌ Not configured"; fi) | $(if check_hooks_available; then echo "$(ls $CLAUDE_HOME/hooks/*.json 2>/dev/null | wc -l) hooks loaded"; else echo "Install hooks for automation"; fi) |
| Agents | $(if check_agents_available; then echo "✅ Available"; else echo "❌ Not configured"; fi) | $(if check_agents_available; then echo "$(ls $CLAUDE_HOME/agents/*.json 2>/dev/null | wc -l) agents ready"; else echo "Install agents for intelligence"; fi) |
| Context | ✅ Initialized | Auto-updating enabled |
| Project | 🔄 Analyzing | $(if [ -f "$CLAUDE_CONTEXT/.agent_trigger" ]; then echo "Agent-based analysis"; else echo "Basic analysis"; fi) |

## 📋 Active Workflows
$(if check_hooks_available || check_agents_available; then
    echo "- 🔒 Safety checks on dangerous operations"
    echo "- 📝 Automatic context updates"
    echo "- 🔄 Intelligent task management"
    echo "- 🎯 Smart code review"
    echo "- 🧪 Optimized test execution"
else
    echo "- Basic workflow only"
    echo "- Manual safety checks required"
    echo "- Manual context management"
fi)

## 🎯 Next Steps
1. $(if check_agents_available; then echo "Wait for project-analyzer to complete"; else echo "Run manual project analysis"; fi)
2. $(if check_agents_available; then echo "Review task-manager recommendations"; else echo "Manually identify tasks"; fi)
3. Begin development with enhanced automation

## 💡 Tips
- Hooks automatically enforce safety and best practices
- Agents provide intelligent assistance and automation
- Context is preserved automatically between sessions
- Use 'git commit' to trigger automatic code review
- Session handoffs are generated automatically

---
*Enhanced workflow powered by Hooks + Agents*
EOF

# Final summary
echo ""
echo "✅ Enhanced Claude workflow initialization complete!"
echo ""
echo "📊 Status Summary:"
echo "  • Project Root: $PROJECT_ROOT"
echo "  • Context Directory: $CLAUDE_CONTEXT"
if check_hooks_available; then
    echo "  • Hooks: ✅ $(ls $CLAUDE_HOME/hooks/*.json 2>/dev/null | wc -l) active"
else
    echo "  • Hooks: ❌ Not configured"
fi
if check_agents_available; then
    echo "  • Agents: ✅ $(ls $CLAUDE_HOME/agents/*.json 2>/dev/null | wc -l) available"
else
    echo "  • Agents: ❌ Not configured"
fi
echo ""
echo "🎯 Intelligent automation is $(if check_hooks_available && check_agents_available; then echo "fully active"; else echo "partially active - install missing components"; fi)"
echo ""