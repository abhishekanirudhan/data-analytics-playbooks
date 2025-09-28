#!/bin/bash

# Claude Code Auto-Launch Workflow
# Automatically analyzes project context and sets up session management
# FIXED: Now preserves existing context instead of overwriting

PROJECT_ROOT="$(pwd)"
CLAUDE_DIR="$PROJECT_ROOT/.claude"
CLAUDE_CONTEXT="$CLAUDE_DIR/context"

echo "🤖 Initializing Claude workflow automation..."

# Check if .claude directory exists, create if not
if [ ! -d "$CLAUDE_DIR" ]; then
    echo "📁 Creating .claude directory..."
    mkdir -p "$CLAUDE_DIR"
fi

# Create context directory structure within .claude
mkdir -p "$CLAUDE_CONTEXT/handoffs"

# Helper function to update or create file with timestamp
update_file_section() {
    local file="$1"
    local section="$2"
    local content="$3"
    local temp_file="${file}.tmp"

    if [ -f "$file" ]; then
        # File exists - preserve and update
        echo "📝 Updating $section in existing file..."

        # Create backup
        cp "$file" "${file}.bak"

        # Update the Last Updated timestamp
        sed -i.tmp "s/\*\*Last Updated:\*\*.*/\*\*Last Updated:\*\* $(date)/" "$file" 2>/dev/null || true

        # For session state, append new session info
        if [[ "$section" == "session-state" ]]; then
            echo "" >> "$file"
            echo "---" >> "$file"
            echo "## New Session: $(date)" >> "$file"
            echo "$content" >> "$file"
        fi
    else
        # File doesn't exist - create new
        echo "📄 Creating new $section file..."
        echo "$content" > "$file"
    fi
}

# Step 1: Advanced Project Context Analysis
echo "📊 Running comprehensive project analysis..."

# Check if project analysis already exists
if [ -f "$CLAUDE_CONTEXT/project-overview.md" ]; then
    echo "✅ Project overview exists. Running incremental update..."
    # Run Python analyzer if available (it will handle updates)
    if command -v python3 >/dev/null 2>&1 && [ -f "$HOME/.claude/scripts/context-analyzer.py" ]; then
        python3 "$HOME/.claude/scripts/context-analyzer.py" --path "$PROJECT_ROOT" --update
    fi
else
    echo "🔍 First time analysis - generating full context..."
    # Check if Python analyzer is available and run it
    if command -v python3 >/dev/null 2>&1 && [ -f "$HOME/.claude/scripts/context-analyzer.py" ]; then
        python3 "$HOME/.claude/scripts/context-analyzer.py" --path "$PROJECT_ROOT"
    else
        # Fallback to basic shell analysis
        echo "⚠️  Python analyzer not available, using basic analysis..."

        cat > "$CLAUDE_CONTEXT/project-analysis.md" << EOF
# Project Analysis

**Generated:** $(date)
**Location:** $PROJECT_ROOT

## Project Structure
\`\`\`
$(find . -maxdepth 3 -type f -name "*.md" -o -name "*.json" -o -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.go" -o -name "*.rs" -o -name "README*" -o -name "package.json" -o -name "requirements.txt" -o -name "Cargo.toml" -o -name "go.mod" | head -20)
\`\`\`

## Key Files Detected
$(ls -la | grep -E "(README|package\.json|requirements\.txt|Cargo\.toml|go\.mod|setup\.py)" 2>/dev/null || echo "No standard project files detected")

## Git Status
$(git status --porcelain 2>/dev/null || echo "Not a git repository")

## Analysis Required
- [ ] Determine project type and main language
- [ ] Identify build/test commands
- [ ] Review existing documentation
- [ ] Understand project goals and architecture
EOF
    fi
fi

# Step 2: Initialize or Update Session State
echo "🔄 Setting up session management..."

SESSION_ID="$(uuidgen 2>/dev/null || echo "session-$(date +%s)")"
SESSION_CONTENT="
**Session ID:** $SESSION_ID
**Started:** $(date)
**Working Directory:** $PROJECT_ROOT

### Session Goals
- Continue from previous session state
- Maintain task continuity
- Preserve technical decisions

### Session Activity
- Session initialized at $(date +%H:%M:%S)
"

if [ -f "$CLAUDE_CONTEXT/session-state.md" ]; then
    echo "📋 Loading previous session state..."
    # Append new session info to existing file
    echo "" >> "$CLAUDE_CONTEXT/session-state.md"
    echo "---" >> "$CLAUDE_CONTEXT/session-state.md"
    echo "## Session: $SESSION_ID" >> "$CLAUDE_CONTEXT/session-state.md"
    echo "$SESSION_CONTENT" >> "$CLAUDE_CONTEXT/session-state.md"

    # Show previous session summary
    echo "📊 Previous session summary:"
    tail -20 "$CLAUDE_CONTEXT/session-state.md" | head -10
else
    cat > "$CLAUDE_CONTEXT/session-state.md" << EOF
# Session State

**Last Updated:** $(date)

## Session: $SESSION_ID
$SESSION_CONTENT

## Session History
| Session ID | Start Time | Status | Notes |
|------------|------------|--------|-------|
| $SESSION_ID | $(date) | Active | Initial session |
EOF
fi

# Step 3: Initialize or Preserve Task Tracker
echo "📋 Setting up task tracking..."

if [ -f "$CLAUDE_CONTEXT/task-tracker.md" ]; then
    echo "✅ Task tracker exists - preserving tasks..."
    # Just update the timestamp
    sed -i.tmp "s/\*\*Last Updated:\*\*.*/\*\*Last Updated:\*\* $(date)/" "$CLAUDE_CONTEXT/task-tracker.md" 2>/dev/null || true

    # Show pending tasks summary
    echo "📌 Pending tasks from previous session:"
    grep "- \[ \]" "$CLAUDE_CONTEXT/task-tracker.md" | head -5 || echo "No pending tasks"
else
    cat > "$CLAUDE_CONTEXT/task-tracker.md" << EOF
# Task Tracker

**Last Updated:** $(date)
**Session:** $SESSION_ID

## Active Tasks
_Tasks will be preserved across sessions_

## Pending Tasks
- [ ] Complete project analysis
- [ ] Review existing code and documentation
- [ ] Identify immediate improvements

## Completed Tasks
- [x] Initialize Claude workflow automation - $(date)
- [x] Set up persistent context management - $(date)

## Task History
| Date | Task | Status | Session | Notes |
|------|------|--------|---------|-------|
| $(date +%Y-%m-%d) | Initialize workflow | Completed | $SESSION_ID | Auto-setup with persistence |

## Resources & Links
- Project Root: $PROJECT_ROOT
- Context Directory: $CLAUDE_CONTEXT
EOF
fi

# Step 4: Initialize or Preserve Decision Log
echo "📝 Setting up decision tracking..."

if [ -f "$CLAUDE_CONTEXT/decisions.md" ]; then
    echo "✅ Decision log exists - preserving history..."
    # Add session marker
    echo "" >> "$CLAUDE_CONTEXT/decisions.md"
    echo "---" >> "$CLAUDE_CONTEXT/decisions.md"
    echo "### Session $SESSION_ID - $(date)" >> "$CLAUDE_CONTEXT/decisions.md"
    echo "_New decisions will be added below_" >> "$CLAUDE_CONTEXT/decisions.md"
else
    cat > "$CLAUDE_CONTEXT/decisions.md" << EOF
# Technical Decisions & Rationale

**Last Updated:** $(date)
**Current Session:** $SESSION_ID

## Architecture Decisions
_Decisions are preserved across sessions_

### Session $SESSION_ID - $(date)
_New session - decisions will be documented here_

## Technology Choices
*To be determined based on project analysis*

## Abandoned Approaches
*Document rejected solutions and why*

## Open Questions
- What is the primary goal of this project?
- What development workflow should be followed?
- Are there specific coding standards or patterns to follow?

## Decision History
| Date | Decision | Rationale | Session | Impact |
|------|----------|-----------|---------|--------|
| $(date +%Y-%m-%d) | Use persistent context | Maintain continuity across sessions | $SESSION_ID | High |
EOF
fi

# Step 5: Create session handoff file for this session
echo "📄 Creating session handoff file..."
HANDOFF_FILE="$CLAUDE_CONTEXT/handoffs/session-$SESSION_ID.md"
cat > "$HANDOFF_FILE" << EOF
# Session Handoff - $SESSION_ID

**Created:** $(date)
**Project:** $PROJECT_ROOT

## Session Summary
- Session started at $(date)
- Context preserved from previous sessions
- Ready for continued work

## Active Context
- Previous tasks loaded from task-tracker.md
- Decision history maintained in decisions.md
- Project overview available in project-overview.md

## Next Session
To continue this work, the next session will:
1. Load this handoff file
2. Resume pending tasks
3. Maintain decision continuity
EOF

echo "✅ Claude workflow automation complete!"
echo "📁 Context directory: $CLAUDE_CONTEXT"
echo "🔄 Session ID: $SESSION_ID"
echo "📊 Context preserved from previous sessions"
echo "🎯 Ready to continue work"

# Show summary of preserved context
echo ""
echo "📈 Context Summary:"
echo "-------------------"
[ -f "$CLAUDE_CONTEXT/task-tracker.md" ] && echo "✓ Tasks preserved: $(grep -c "- \[ \]" "$CLAUDE_CONTEXT/task-tracker.md" 2>/dev/null || echo "0") pending"
[ -f "$CLAUDE_CONTEXT/decisions.md" ] && echo "✓ Decisions preserved: $(grep -c "^###" "$CLAUDE_CONTEXT/decisions.md" 2>/dev/null || echo "0") sessions"
[ -f "$CLAUDE_CONTEXT/session-state.md" ] && echo "✓ Session history maintained"
echo "✓ Handoff created: session-$SESSION_ID.md"