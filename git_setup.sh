#!/bin/bash
cd /Users/abhishekanirudhan/Projects/playbooks

# Initialize git repository
git init

# Add remote
git remote add origin https://github.com/abhishekanirudhan/data-analytics-playbooks.git

# Check status
git status

# Stage changes
git add claude-playbooks/CLAUDE.md.template

# Create commit
git commit -m "feat: add auto-launch hook to Claude Code workflow automation

- Updated CLAUDE.md.template with AUTO-LAUNCH HOOK section
- Claude Code now automatically runs workflow on startup
- Added clear instructions for automatic project analysis
- Preserved existing Python best practices and instruction reminders

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# Push changes
git push -u origin main