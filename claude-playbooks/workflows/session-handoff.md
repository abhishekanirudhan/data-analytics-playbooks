# Session Handoff Workflow

Manages context transfer between Claude Code sessions.

## Session Start Protocol

### 1. Context Loading
- Read `.claude-context/session-state.md` for current status
- Review `task-tracker.md` for pending work
- Check `decisions.md` for technical context
- Load any handoff notes from previous sessions

### 2. Continuity Assessment
- Verify project state hasn't changed significantly
- Check for new files, commits, or external changes
- Validate that previous context is still relevant
- Identify any blocking issues that emerged

### 3. Priority Evaluation
- Review active tasks and their urgency
- Check for any user-added requirements
- Assess task dependencies and ordering
- Update priorities based on current context

## Session End Protocol

### 1. State Documentation
- Update `session-state.md` with current work status
- Document any decisions made during the session
- Record insights gained about the project
- Note any blocking issues or questions

### 2. Task Status Update
- Mark completed tasks in `task-tracker.md`
- Update progress on partially completed tasks
- Add newly identified tasks to the backlog
- Document task relationships and dependencies

### 3. Handoff Creation
```markdown
# Handoff: [Date/Time]

## Session Summary
- **Duration:** [Time spent]
- **Focus Area:** [Main work area]
- **Key Achievements:** [What was accomplished]

## Current State
- **Active Work:** [What's currently in progress]
- **Blocking Issues:** [Any impediments]
- **Next Priority:** [What should be tackled next]

## Context for Next Session
- **Background:** [Important context to remember]
- **Decisions Made:** [Key choices and rationale]
- **Resources:** [Relevant files, docs, links]

## Recommendations
- **Immediate Actions:** [What to do first]
- **Investigation Areas:** [What needs research]
- **User Clarifications:** [Questions to ask user]
```

## Emergency Handoff

For interrupted sessions:
- Auto-save current state to `handoffs/emergency-[timestamp].md`
- Capture current tool state and context
- Mark tasks as "interrupted" rather than "pending"
- Flag session as requiring immediate continuation