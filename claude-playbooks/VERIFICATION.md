# Claude Workflow Automation - Verification Guide

Complete guide for verifying and troubleshooting the Claude Code workflow automation system.

## 🔍 Quick Verification

Run this command to verify your installation:

```bash
bash -c '
echo "Checking Claude Workflow Installation..."
echo "========================================"
PASS=0
FAIL=0

# Check main directory
if [ -d "$HOME/.claude" ]; then
    echo "✅ Claude directory exists"
    ((PASS++))
else
    echo "❌ Claude directory not found at $HOME/.claude"
    ((FAIL++))
fi

# Check CLAUDE.md
if [ -f "$HOME/.claude/CLAUDE.md" ]; then
    echo "✅ CLAUDE.md exists"
    if grep -q "auto-launch.sh" "$HOME/.claude/CLAUDE.md"; then
        echo "✅ CLAUDE.md contains auto-launch instruction"
        ((PASS++))
    else
        echo "⚠️  CLAUDE.md missing auto-launch instruction"
        ((FAIL++))
    fi
    ((PASS++))
else
    echo "❌ CLAUDE.md not found"
    ((FAIL++))
fi

# Check scripts
for script in auto-launch.sh context-analyzer.py task-manager.sh; do
    if [ -f "$HOME/.claude/scripts/$script" ]; then
        echo "✅ $script exists"
        ((PASS++))
        if [ -x "$HOME/.claude/scripts/$script" ]; then
            echo "✅ $script is executable"
            ((PASS++))
        else
            echo "⚠️  $script is not executable"
            ((FAIL++))
        fi
    else
        echo "❌ $script not found"
        ((FAIL++))
    fi
done

# Check Python
if command -v python3 >/dev/null 2>&1; then
    echo "✅ Python3 is installed ($(python3 --version))"
    ((PASS++))
else
    echo "⚠️  Python3 not found (advanced features limited)"
fi

echo "========================================"
echo "Results: $PASS passed, $FAIL failed"
if [ $FAIL -eq 0 ]; then
    echo "🎉 Installation verified successfully!"
else
    echo "⚠️  Some issues detected. See troubleshooting below."
fi
'
```

## 📋 Manual Verification Steps

### 1. Directory Structure Check

```bash
# List Claude directory structure
tree ~/.claude/ -L 2

# Expected output:
# ~/.claude/
# ├── CLAUDE.md
# ├── README.md
# ├── scripts/
# │   ├── auto-launch.sh
# │   ├── context-analyzer.py
# │   └── task-manager.sh
# ├── templates/
# │   ├── project-overview.md
# │   └── session-handoff.md
# └── workflows/
#     ├── project-analyzer.md
#     └── session-handoff.md
```

### 2. File Permissions Check

```bash
# Check script permissions
ls -la ~/.claude/scripts/

# All .sh and .py files should have execute permissions (x)
# If not, fix with:
chmod +x ~/.claude/scripts/*.sh
chmod +x ~/.claude/scripts/*.py
```

### 3. CLAUDE.md Content Verification

```bash
# Check if auto-launch instruction exists
grep -n "auto-launch" ~/.claude/CLAUDE.md

# Should show a line containing:
# Execute this by running: `source ~/.claude/scripts/auto-launch.sh`
```

### 4. Functional Test

```bash
# Create a test directory
mkdir -p ~/test-claude-workflow
cd ~/test-claude-workflow

# Create test files
echo "# Test Project" > README.md
echo "console.log('test');" > index.js

# Run the workflow
source ~/.claude/scripts/auto-launch.sh

# Check if context was created
ls -la .claude-context/

# Should see:
# - project-overview.md
# - session-state.md
# - task-tracker.md
# - decisions.md
```

## 🔧 Common Issues & Solutions

### Issue: "Command not found: source"

**Solution:** Use bash instead of sh
```bash
bash -c "source ~/.claude/scripts/auto-launch.sh"
```

### Issue: "Permission denied" when running scripts

**Solution:** Fix permissions
```bash
chmod +x ~/.claude/scripts/*.sh
chmod +x ~/.claude/scripts/*.py
```

### Issue: Python analyzer not running

**Check Python installation:**
```bash
which python3
python3 --version
```

**Solution for macOS:**
```bash
brew install python3
```

**Solution for Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install python3
```

### Issue: Context directory not created

**Debug the script:**
```bash
# Run with debug output
bash -x ~/.claude/scripts/auto-launch.sh
```

**Check for errors in output and fix accordingly**

### Issue: Task manager not working

**Test task manager directly:**
```bash
# Test adding a task
~/.claude/scripts/task-manager.sh add "Test task" high

# Test showing tasks
~/.claude/scripts/task-manager.sh show
```

**If errors occur, check:**
1. Script exists and is executable
2. Current directory has write permissions
3. .claude-context directory exists

## 🧪 Complete System Test

Run this comprehensive test to verify all features:

```bash
#!/bin/bash
# Save as test-claude-system.sh and run

echo "🧪 Claude Workflow System Test"
echo "=============================="

# Setup test environment
TEST_DIR="$HOME/claude-test-$(date +%s)"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "📁 Test directory: $TEST_DIR"

# Create test project files
cat > README.md << 'EOF'
# Test Project
This is a test project for Claude workflow verification.
EOF

cat > package.json << 'EOF'
{
  "name": "test-project",
  "version": "1.0.0",
  "scripts": {
    "test": "echo 'test'",
    "build": "echo 'build'"
  }
}
EOF

cat > index.js << 'EOF'
console.log('Hello Claude!');
EOF

# Initialize git repo
git init >/dev/null 2>&1
git add . >/dev/null 2>&1
git commit -m "Initial commit" >/dev/null 2>&1

echo "✅ Test project created"

# Run workflow
echo "🔄 Running workflow automation..."
source ~/.claude/scripts/auto-launch.sh

# Verify context creation
echo "📋 Checking generated files..."

FILES_OK=true
for file in project-overview.md session-state.md task-tracker.md decisions.md; do
    if [ -f ".claude-context/$file" ]; then
        echo "✅ $file created"
    else
        echo "❌ $file missing"
        FILES_OK=false
    fi
done

# Test task manager
echo "📝 Testing task management..."
~/.claude/scripts/task-manager.sh add "Test task 1" high
~/.claude/scripts/task-manager.sh add "Test task 2" normal
~/.claude/scripts/task-manager.sh complete "Test task 1"
~/.claude/scripts/task-manager.sh show

# Test Python analyzer if available
if command -v python3 >/dev/null 2>&1; then
    echo "🐍 Testing Python analyzer..."
    python3 ~/.claude/scripts/context-analyzer.py --path . --verbose
fi

# Cleanup
echo ""
echo "🧹 Test complete!"
echo "Test directory: $TEST_DIR"
echo "To remove test directory: rm -rf $TEST_DIR"

if [ "$FILES_OK" = true ]; then
    echo "✅ All tests passed!"
else
    echo "⚠️  Some tests failed. Check output above."
fi
```

## 📊 Performance Verification

Check system performance:

```bash
# Time the workflow execution
time source ~/.claude/scripts/auto-launch.sh

# Expected: < 5 seconds for most projects
```

Check file sizes:

```bash
# Check context file sizes
du -sh .claude-context/*

# Files should be reasonably sized (< 100KB each typically)
```

## 🔄 Reinstallation

If verification fails, reinstall:

```bash
# Backup existing setup
mv ~/.claude ~/.claude.backup

# Reinstall from playbook
cd ~/Projects/master-playbooks/claude-playbooks
./install.sh
```

## 📞 Support Checklist

Before seeking help, verify:

- [ ] Claude directory exists at `~/.claude`
- [ ] CLAUDE.md contains auto-launch instruction
- [ ] All scripts are present and executable
- [ ] Python3 is installed (optional but recommended)
- [ ] You can manually run `source ~/.claude/scripts/auto-launch.sh`
- [ ] Context directory is created in projects
- [ ] Task manager commands work

## 🎯 Expected Behavior

When working correctly, you should see:

1. **On Claude Code launch:** Automatic workflow execution message
2. **In projects:** `.claude-context/` directory with 4+ files
3. **Task management:** Ability to add, update, and complete tasks
4. **Session continuity:** Previous session state preserved
5. **Project analysis:** Accurate detection of project type and tools

---

**Verification Guide Version:** 1.0.0  
**Last Updated:** 2025