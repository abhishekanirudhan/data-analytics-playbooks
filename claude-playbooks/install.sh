#!/bin/bash

# Claude Code Workflow Automation - Installation Script
# This script sets up the complete Claude workflow automation system on a new machine

set -e  # Exit on error

CLAUDE_HOME="$HOME/.claude"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENHANCED_MODE=false

# Check for enhanced mode flag
if [ "$1" == "--enhanced" ] || [ "$1" == "-e" ]; then
    ENHANCED_MODE=true
fi

echo "======================================"
echo "Claude Code Workflow Automation Setup"
if [ "$ENHANCED_MODE" = true ]; then
    echo "     🚀 ENHANCED MODE (Hooks + Agents)"
fi
echo "======================================"
echo ""

# Check if Claude directory already exists
if [ -d "$CLAUDE_HOME" ]; then
    echo "⚠️  Claude directory already exists at $CLAUDE_HOME"
    read -p "Do you want to backup existing and continue? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        BACKUP_DIR="$CLAUDE_HOME.backup.$(date +%Y%m%d-%H%M%S)"
        echo "📦 Backing up existing directory to $BACKUP_DIR..."
        mv "$CLAUDE_HOME" "$BACKUP_DIR"
    else
        echo "❌ Installation cancelled"
        exit 1
    fi
fi

echo "📁 Creating Claude directory structure..."
mkdir -p "$CLAUDE_HOME"/{scripts,templates,workflows}

# Create additional directories for enhanced mode
if [ "$ENHANCED_MODE" = true ]; then
    mkdir -p "$CLAUDE_HOME"/{hooks,agents}
    echo "🪝 Creating hooks and agents directories..."
fi

echo "📝 Copying workflow files..."
cp -r "$SCRIPT_DIR/scripts/"* "$CLAUDE_HOME/scripts/" 2>/dev/null || true
cp -r "$SCRIPT_DIR/templates/"* "$CLAUDE_HOME/templates/" 2>/dev/null || true
cp -r "$SCRIPT_DIR/workflows/"* "$CLAUDE_HOME/workflows/" 2>/dev/null || true

# Copy enhanced components if in enhanced mode
if [ "$ENHANCED_MODE" = true ]; then
    echo "🪝 Installing hooks..."
    if [ -d "$SCRIPT_DIR/hooks" ]; then
        cp -r "$SCRIPT_DIR/hooks/"* "$CLAUDE_HOME/hooks/" 2>/dev/null || true
        echo "  ✅ Installed $(ls -1 $SCRIPT_DIR/hooks/*.json 2>/dev/null | wc -l) hooks"
    fi
    
    echo "🤖 Installing agents..."
    if [ -d "$SCRIPT_DIR/agents" ]; then
        cp -r "$SCRIPT_DIR/agents/"* "$CLAUDE_HOME/agents/" 2>/dev/null || true
        echo "  ✅ Installed $(ls -1 $SCRIPT_DIR/agents/*.json 2>/dev/null | wc -l) agents"
    fi
fi

echo "📄 Setting up CLAUDE.md global instructions..."
if [ -f "$SCRIPT_DIR/CLAUDE.md.template" ]; then
    cp "$SCRIPT_DIR/CLAUDE.md.template" "$CLAUDE_HOME/CLAUDE.md"
else
    # Create minimal CLAUDE.md if template not found
    # Use enhanced script if in enhanced mode
    if [ "$ENHANCED_MODE" = true ]; then
        LAUNCH_SCRIPT="auto-launch-enhanced.sh"
    else
        LAUNCH_SCRIPT="auto-launch.sh"
    fi
    
    cat > "$CLAUDE_HOME/CLAUDE.md" << EOF
# Claude Project Instructions

## Automatic Workflow on Launch
ALWAYS perform these steps when Claude Code launches in a new project:

1. **Project Analysis**: Run the project context analysis workflow
2. **Session Setup**: Initialize or load session state management
3. **Task Continuity**: Check for pending tasks from previous sessions

Execute this by running: \`source ~/.claude/scripts/$LAUNCH_SCRIPT\`

## Python Development Best Practices

### Virtual Environment Usage
When working with Python projects, always use a virtual environment to manage dependencies:

1. Create a virtual environment: `python3 -m venv venv`
2. Activate the virtual environment: `source venv/bin/activate`
3. Install dependencies: `pip install -r requirements.txt`
4. Deactivate when done: `deactivate`

This ensures isolated dependency management and prevents conflicts with system-wide packages.

# important-instruction-reminders
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.
EOF
fi

echo "📚 Copying documentation..."
if [ -f "$SCRIPT_DIR/docs/README.md" ]; then
    cp "$SCRIPT_DIR/docs/README.md" "$CLAUDE_HOME/README.md"
fi

# Copy enhanced documentation if in enhanced mode
if [ "$ENHANCED_MODE" = true ] && [ -f "$SCRIPT_DIR/docs/HOOKS_AND_AGENTS.md" ]; then
    cp "$SCRIPT_DIR/docs/HOOKS_AND_AGENTS.md" "$CLAUDE_HOME/HOOKS_AND_AGENTS.md"
    echo "  ✅ Installed enhanced documentation"
fi

echo "🔧 Setting executable permissions..."
chmod +x "$CLAUDE_HOME/scripts/"*.sh 2>/dev/null || true
chmod +x "$CLAUDE_HOME/scripts/"*.py 2>/dev/null || true

echo "✅ Verifying installation..."

# Verification checks
VERIFICATION_PASSED=true

# Check if main scripts exist
if [ ! -f "$CLAUDE_HOME/scripts/auto-launch.sh" ]; then
    echo "❌ auto-launch.sh not found"
    VERIFICATION_PASSED=false
fi

if [ ! -f "$CLAUDE_HOME/scripts/context-analyzer.py" ]; then
    echo "❌ context-analyzer.py not found"
    VERIFICATION_PASSED=false
fi

if [ ! -f "$CLAUDE_HOME/scripts/task-manager.sh" ]; then
    echo "❌ task-manager.sh not found"
    VERIFICATION_PASSED=false
fi

if [ ! -f "$CLAUDE_HOME/CLAUDE.md" ]; then
    echo "❌ CLAUDE.md not found"
    VERIFICATION_PASSED=false
fi

# Check Python availability
if ! command -v python3 >/dev/null 2>&1; then
    echo "⚠️  Python3 not found - advanced analysis features will be limited"
fi

if [ "$VERIFICATION_PASSED" = true ]; then
    echo ""
    echo "✅ Installation completed successfully!"
    echo ""
    echo "======================================"
    echo "🎉 Claude Code Workflow Automation Ready!"
    if [ "$ENHANCED_MODE" = true ]; then
        echo "      Enhanced with Hooks + Agents"
    fi
    echo "======================================"
    echo ""
    echo "The system is now installed and configured at: $CLAUDE_HOME"
    echo ""
    
    if [ "$ENHANCED_MODE" = true ]; then
        echo "🚀 Enhanced Features Installed:"
        if [ -d "$CLAUDE_HOME/hooks" ] && [ "$(ls -A $CLAUDE_HOME/hooks/*.json 2>/dev/null)" ]; then
            echo "  🪝 Hooks: $(ls -1 $CLAUDE_HOME/hooks/*.json 2>/dev/null | wc -l) active"
            echo "     - Safety checks on dangerous operations"
            echo "     - Automatic context updates"
            echo "     - Git workflow enforcement"
        fi
        if [ -d "$CLAUDE_HOME/agents" ] && [ "$(ls -A $CLAUDE_HOME/agents/*.json 2>/dev/null)" ]; then
            echo "  🤖 Agents: $(ls -1 $CLAUDE_HOME/agents/*.json 2>/dev/null | wc -l) available"
            echo "     - Project analyzer for deep analysis"
            echo "     - Task manager for intelligent prioritization"
            echo "     - Code reviewer for quality assurance"
            echo "     - Session handoff for continuity"
            echo "     - Test runner for smart testing"
        fi
        echo ""
    fi
    
    echo "📋 What happens now:"
    echo "1. Claude Code will automatically read $CLAUDE_HOME/CLAUDE.md on launch"
    echo "2. The workflow automation will run when you start a new project"
    echo "3. Context files will be created in each project's .claude/ directory"
    if [ "$ENHANCED_MODE" = true ]; then
        echo "4. Hooks will automatically enforce safety and best practices"
        echo "5. Agents will provide intelligent assistance"
    fi
    echo ""
    echo "🚀 Quick Test:"
    echo "To test the installation, run:"
    echo "  cd ~/some-project"
    if [ "$ENHANCED_MODE" = true ]; then
        echo "  source ~/.claude/scripts/auto-launch-enhanced.sh"
    else
        echo "  source ~/.claude/scripts/auto-launch.sh"
    fi
    echo ""
    echo "📖 Documentation:"
    echo "See $CLAUDE_HOME/README.md for detailed usage instructions"
    if [ "$ENHANCED_MODE" = true ]; then
        echo "See $CLAUDE_HOME/HOOKS_AND_AGENTS.md for enhanced features"
    fi
    echo ""
else
    echo ""
    echo "❌ Installation verification failed!"
    echo "Please check the error messages above and try again."
    echo "You may need to manually copy missing files from the playbook."
    exit 1
fi

# Optional: Create a test project to verify
read -p "Would you like to create a test project to verify the setup? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    TEST_DIR="$HOME/claude-test-project-$(date +%Y%m%d-%H%M%S)"
    echo "📁 Creating test project at $TEST_DIR..."
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"
    
    # Create a simple test file
    echo "# Test Project" > README.md
    echo "print('Hello Claude!')" > main.py
    
    echo "🔄 Running workflow automation..."
    source "$CLAUDE_HOME/scripts/auto-launch.sh"
    
    echo ""
    echo "✅ Test complete! Check $TEST_DIR/.claude-context/ for generated files"
    echo "You can delete the test project with: rm -rf $TEST_DIR"
fi

echo ""
echo "======================================"
echo "Installation complete! 🎉"
echo "======================================