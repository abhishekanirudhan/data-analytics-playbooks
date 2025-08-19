# Project Analysis Workflow

This workflow should be executed automatically when Claude Code launches in a new directory.

## Analysis Steps

### 1. Directory Reconnaissance
- Scan for key configuration files (package.json, requirements.txt, Cargo.toml, go.mod, etc.)
- Identify project type and primary language
- Check for documentation files (README, docs/)
- Examine folder structure for architecture patterns

### 2. Development Environment Detection
- Look for virtual environment indicators (venv/, .env files)
- Check for Docker configuration (Dockerfile, docker-compose.yml)
- Identify build tools and scripts
- Find test frameworks and configuration

### 3. Git Repository Analysis
- Check git status for uncommitted changes
- Review recent commit messages for context
- Identify branching strategy
- Look for CI/CD configuration (.github/, .gitlab-ci.yml)

### 4. Code Quality Assessment
- Scan for linting configuration
- Check for formatting tools (prettier, black, etc.)
- Identify testing patterns
- Look for type checking setup

### 5. Documentation Review
- Parse README for project goals and setup instructions
- Check for API documentation
- Look for architectural decision records
- Review code comments for context

## Output Generation

Create structured analysis in `.claude-context/project-overview.md` with:
- Project summary and goals
- Technology stack
- Development setup instructions
- Key files and their purposes
- Identified tasks and next steps
- Questions requiring user clarification

## Integration Points

- Update session-state.md with analysis findings
- Populate task-tracker.md with identified work items
- Log decisions in decisions.md
- Create handoff documentation for future sessions