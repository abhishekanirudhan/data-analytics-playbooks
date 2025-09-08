# Claude Code Hooks and Agents Integration Guide

## Overview

This enhanced version of the Claude Playbooks integrates **Hooks** and **Subagents** to provide intelligent, automated workflow management that goes beyond simple scripting.

## 🪝 Hooks System

Hooks are event-driven scripts that intercept and modify Claude Code's behavior at specific points in the workflow.

### Available Hooks

#### 1. Safety Hook (`safety-hook.json`)
**Purpose**: Prevents destructive operations and enforces security best practices

**Features**:
- Blocks dangerous commands (rm -rf /, fork bombs)
- Warns about overly permissive file permissions
- Scans for exposed credentials in environment files
- Requires confirmation for sudo operations

**Events**: `PreToolUse`

**Example Scenarios**:
- Prevents accidental deletion of critical directories
- Warns when modifying sensitive configuration files
- Blocks potential security vulnerabilities

#### 2. Context Update Hook (`context-update-hook.json`)
**Purpose**: Automatically maintains session context and tracking

**Features**:
- Logs all file modifications with timestamps
- Updates task status based on file changes
- Tracks key actions (commits, installations)
- Classifies user requests by intent

**Events**: `PostToolUse`, `UserPromptSubmit`

**Example Scenarios**:
- Automatically updates task tracker when related files change
- Maintains comprehensive session history
- Provides context for session handoffs

#### 3. Git Workflow Hook (`git-workflow-hook.json`)
**Purpose**: Enforces git best practices and workflow standards

**Features**:
- Validates commits before execution
- Suggests running tests before committing
- Checks for conventional commit format
- Warns about pushing to protected branches
- Logs commit history to decision tracker

**Events**: `PreToolUse`, `PostToolUse`

**Example Scenarios**:
- Reminds to run tests before committing
- Prevents pushing directly to main branch
- Automatically updates task status on commit

## 🤖 Subagents System

Subagents are specialized AI assistants that handle specific aspects of the development workflow with focused capabilities.

### Available Agents

#### 1. Project Analyzer Agent (`project-analyzer.json`)
**Purpose**: Comprehensive project analysis and context generation

**Capabilities**:
- Detects technology stack and frameworks
- Maps project structure
- Identifies build and test commands
- Detects coding patterns and conventions
- Suggests improvements

**Triggers**: Session start, new project, major changes

**Output**: Detailed project overview in `.claude/context/project-overview.md`

#### 2. Task Manager Agent (`task-manager.json`)
**Purpose**: Intelligent task prioritization and tracking

**Capabilities**:
- Analyzes task dependencies
- Calculates priority scores
- Identifies blockers
- Suggests parallel work opportunities
- Estimates completion times

**Triggers**: Task updates, new requests, blocker detection

**Output**: Organized task list in `.claude/context/task-tracker.md`

#### 3. Code Reviewer Agent (`code-reviewer.json`)
**Purpose**: Automated code review and quality assurance

**Capabilities**:
- Static code analysis
- Security vulnerability scanning
- Complexity checking
- Test coverage analysis
- Best practices validation

**Triggers**: Pre-commit, file edits, PR creation

**Output**: Review reports with severity levels and suggestions

#### 4. Session Handoff Agent (`session-handoff.json`)
**Purpose**: Creates comprehensive handoff documents

**Capabilities**:
- Captures session state and progress
- Documents decisions and patterns
- Identifies urgent items and blockers
- Generates quick-start guides
- Estimates context recovery time

**Triggers**: Session end, context switch, long pauses

**Output**: Detailed handoff in `.claude/context/handoffs/`

#### 5. Test Runner Agent (`test-runner.json`)
**Purpose**: Intelligent test execution and coverage

**Capabilities**:
- Detects test frameworks automatically
- Runs only affected tests
- Parallel test execution
- Flaky test detection
- Coverage trend analysis

**Triggers**: File changes, pre-commit, dependency updates

**Output**: Test results in `.claude/context/test-results/`

## 🔧 Installation

### Quick Setup

1. **Install the enhanced playbook**:
```bash
cd ~/Projects/playbooks/claude-playbooks
./install.sh --enhanced
```

2. **Verify installation**:
```bash
ls -la ~/.claude/hooks/
ls -la ~/.claude/agents/
```

3. **Test the enhanced workflow**:
```bash
cd ~/your-project
source ~/.claude/scripts/auto-launch-enhanced.sh
```

### Manual Installation

1. **Copy hook configurations**:
```bash
cp -r hooks/* ~/.claude/hooks/
```

2. **Copy agent configurations**:
```bash
cp -r agents/* ~/.claude/agents/
```

3. **Use enhanced auto-launch script**:
```bash
cp scripts/auto-launch-enhanced.sh ~/.claude/scripts/
chmod +x ~/.claude/scripts/auto-launch-enhanced.sh
```

4. **Update CLAUDE.md to use enhanced script**:
```bash
# Edit ~/.claude/CLAUDE.md to run:
source ~/.claude/scripts/auto-launch-enhanced.sh
```

## 📋 Configuration

### Customizing Hooks

Hooks can be customized by editing the JSON files in `~/.claude/hooks/`:

```json
{
  "name": "custom-hook",
  "events": ["PreToolUse"],
  "enabled": true,
  "priority": 95,
  "script": {
    // Hook logic here
  }
}
```

### Configuring Agents

Agents can be configured in `~/.claude/agents/`:

```json
{
  "name": "custom-agent",
  "trigger": "manual|auto",
  "capabilities": {
    "tools": ["Read", "Write", "Bash"],
    "permissions": {
      // Agent permissions
    }
  }
}
```

### Priority System

- **Hooks**: Higher priority (100) executes first
- **Agents**: Priority determines execution order when multiple agents trigger

## 🎯 Usage Examples

### Example 1: Safe Development Workflow

1. Start Claude Code in your project
2. Safety hook automatically activates
3. Attempt a dangerous operation:
   ```bash
   rm -rf /important-dir  # Hook blocks this
   ```
4. Hook prevents execution and warns user

### Example 2: Automated Code Review

1. Make code changes
2. Commit changes:
   ```bash
   git commit -m "feat: add new feature"
   ```
3. Git workflow hook triggers code-reviewer agent
4. Agent analyzes changes and provides feedback
5. Commit proceeds if no critical issues

### Example 3: Intelligent Task Management

1. User requests: "Help me fix the authentication bug"
2. Context update hook classifies as "bug_fix"
3. Task manager agent:
   - Creates bug fix task
   - Analyzes dependencies
   - Suggests related tasks
   - Updates priorities

### Example 4: Seamless Session Handoff

1. Work on project for several hours
2. Session ends or pauses
3. Session handoff agent automatically:
   - Captures all changes
   - Documents decisions
   - Creates handoff document
4. Next session starts with full context

## 🔄 Workflow Integration

### Complete Development Cycle

1. **Session Start**:
   - Project analyzer runs comprehensive analysis
   - Task manager loads and prioritizes tasks
   - Hooks activate for safety and automation

2. **During Development**:
   - Safety hook prevents dangerous operations
   - Context hook tracks all changes
   - Git hook enforces best practices
   - Agents provide intelligent assistance

3. **Session End**:
   - Session handoff agent creates documentation
   - Task manager saves state
   - Context preserved for next session

## 🚀 Advanced Features

### Agent Chaining

Agents can trigger other agents:
```
User Request → Task Manager → Code Reviewer → Test Runner
```

### Conditional Hooks

Hooks can have complex conditions:
```json
"condition": "tool.name === 'Bash' && project.type === 'python'"
```

### Smart Test Selection

Test runner agent uses multiple strategies:
- Affected files only
- Dependency-based selection
- Risk-based prioritization
- Time-optimized execution

## 📊 Performance Impact

- **Hooks**: Minimal overhead (<100ms per event)
- **Agents**: Async execution, no blocking
- **Context Updates**: Instant file operations
- **No background processes**: Everything event-driven

## 🔒 Security Considerations

- All hooks run locally, no external connections
- Agents have restricted permissions
- Sensitive file protection built-in
- Credential scanning automatic
- Git operations validated

## 🐛 Troubleshooting

### Hooks Not Triggering

1. Check hook is enabled:
```bash
cat ~/.claude/hooks/safety-hook.json | grep enabled
```

2. Verify hook events match your actions

3. Check hook priority (higher executes first)

### Agents Not Running

1. Verify agent trigger conditions
2. Check agent permissions
3. Look for trigger files in `.claude/context/`

### Context Not Updating

1. Ensure context-update-hook is enabled
2. Check write permissions on `.claude/context/`
3. Verify hook conditions match your workflow

## 📚 Best Practices

1. **Start Simple**: Enable one hook/agent at a time
2. **Customize Gradually**: Modify configurations based on your workflow
3. **Monitor Performance**: Disable unused hooks/agents
4. **Regular Updates**: Keep configurations synchronized
5. **Project-Specific**: Add custom hooks for specific projects

## 🔮 Future Enhancements

- **ML-based priority prediction**
- **Cross-project learning**
- **Custom agent creation UI**
- **Hook composition system**
- **Performance analytics dashboard**

## 📝 Contributing

To add new hooks or agents:

1. Create configuration file in appropriate directory
2. Follow existing schema and patterns
3. Test thoroughly in isolation
4. Document capabilities and usage
5. Submit to playbook repository

---

**Version**: 2.0.0  
**Enhanced with**: Hooks + Agents  
**Compatible with**: Claude Code (all versions)