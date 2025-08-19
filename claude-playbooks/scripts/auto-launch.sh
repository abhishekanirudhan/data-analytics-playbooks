#!/bin/bash

# Claude Code Auto-Launch Workflow
# Automatically analyzes project context and sets up session management

PROJECT_ROOT="$(pwd)"
CLAUDE_CONTEXT="$PROJECT_ROOT/.claude-context"

echo "🤖 Initializing Claude workflow automation..."

# Create context directory structure
mkdir -p "$CLAUDE_CONTEXT/handoffs"

# Step 1: Advanced Project Context Analysis
echo "📊 Running comprehensive project analysis..."

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

# Step 2: Initialize Session State
echo "🔄 Setting up session management..."
cat > "$CLAUDE_CONTEXT/session-state.md" << 'EOF'
# Session State

**Last Updated:** $(date)
**Session ID:** $(uuidgen 2>/dev/null || echo "session-$(date +%s)")

## Current Status
- **State:** Initialized
- **Active Tasks:** None
- **Blocking Issues:** None

## Context Summary
Project context analysis initiated. Awaiting Claude to complete analysis and begin work.

## Next Actions
1. Complete project analysis
2. Identify immediate tasks
3. Set up task tracking

## Handoff Notes
New session initialized. No previous context to inherit.
EOF

# Step 3: Initialize Task Tracker
echo "📋 Setting up task tracking..."
cat > "$CLAUDE_CONTEXT/task-tracker.md" << 'EOF'
# Task Tracker

**Last Updated:** $(date)

## Active Tasks
None - awaiting task identification

## Pending Tasks
- [ ] Complete project analysis
- [ ] Identify project goals and requirements
- [ ] Set up development environment if needed

## Completed Tasks
- [x] Initialize Claude workflow automation
- [x] Set up context management structure

## Task History
| Date | Task | Status | Notes |
|------|------|--------|-------|
| $(date +%Y-%m-%d) | Initialize workflow | Completed | Auto-setup complete |

## Resources & Links
- Project Root: $PROJECT_ROOT
- Context Directory: $CLAUDE_CONTEXT
EOF

# Step 4: Create Decision Log
echo "📝 Setting up decision tracking..."
cat > "$CLAUDE_CONTEXT/decisions.md" << 'EOF'
# Technical Decisions & Rationale

**Last Updated:** $(date)

## Architecture Decisions
*To be populated during analysis*

## Technology Choices
*To be determined based on project analysis*

## Abandoned Approaches
*Document rejected solutions and why*

## Open Questions
- What is the primary goal of this project?
- What development workflow should be followed?
- Are there specific coding standards or patterns to follow?
EOF

echo "✅ Claude workflow automation complete!"
echo "📁 Context directory: $CLAUDE_CONTEXT"
echo "🎯 Ready for Claude to begin project analysis"