#!/bin/bash

# Claude Code Context Preservation Module
# Provides utilities for safe context updates without data loss

# Configuration
CLAUDE_DIR="${CLAUDE_DIR:-.claude}"
CLAUDE_CONTEXT="${CLAUDE_CONTEXT:-$CLAUDE_DIR/context}"
BACKUP_DIR="$CLAUDE_CONTEXT/backups"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Generate timestamp and session ID
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
SESSION_ID="${SESSION_ID:-$(uuidgen 2>/dev/null || echo "session-$(date +%s)")}"

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to create timestamped backup
create_backup() {
    local file="$1"
    if [ -f "$file" ]; then
        local backup_name="$(basename "$file").$(date +%Y%m%d_%H%M%S).bak"
        cp "$file" "$BACKUP_DIR/$backup_name"
        echo -e "${GREEN}✓ Backup created: $backup_name${NC}"
        return 0
    fi
    return 1
}

# Function to safely update a markdown file section
update_section() {
    local file="$1"
    local section="$2"
    local new_content="$3"

    if [ ! -f "$file" ]; then
        echo -e "${RED}✗ File not found: $file${NC}"
        return 1
    fi

    create_backup "$file"

    # Use awk to update the specific section
    awk -v section="$section" -v content="$new_content" '
    BEGIN { in_section = 0; printed = 0 }
    $0 ~ "^## " section { in_section = 1; print; print content; printed = 1; next }
    in_section && /^##/ { in_section = 0 }
    !in_section { print }
    END { if (!printed) { print "\n## " section "\n" content } }
    ' "$file" > "$file.tmp"

    mv "$file.tmp" "$file"
    echo -e "${GREEN}✓ Updated section: $section${NC}"
}

# Function to append to a specific section
append_to_section() {
    local file="$1"
    local section="$2"
    local content="$3"

    if [ ! -f "$file" ]; then
        echo -e "${RED}✗ File not found: $file${NC}"
        return 1
    fi

    create_backup "$file"

    # Find section and append content
    awk -v section="$section" -v content="$content" '
    BEGIN { in_section = 0 }
    $0 ~ "^## " section { in_section = 1; print; next }
    in_section && /^##/ { print content "\n"; in_section = 0 }
    { print }
    END { if (in_section) print content }
    ' "$file" > "$file.tmp"

    mv "$file.tmp" "$file"
    echo -e "${GREEN}✓ Appended to section: $section${NC}"
}

# Function to update timestamps in markdown files
update_timestamps() {
    local file="$1"

    if [ -f "$file" ]; then
        sed -i.tmp "s/\*\*Last Updated:\*\*.*/\*\*Last Updated:\*\* $TIMESTAMP/" "$file"
        sed -i.tmp "s/\*\*Current Session:\*\*.*/\*\*Current Session:\*\* $SESSION_ID/" "$file"
        rm -f "$file.tmp"
        echo -e "${GREEN}✓ Updated timestamps in: $(basename "$file")${NC}"
    fi
}

# Function to merge task lists intelligently
merge_tasks() {
    local file="$1"
    local new_tasks="$2"
    local section="${3:-Pending Tasks}"

    if [ ! -f "$file" ]; then
        echo -e "${RED}✗ Task file not found${NC}"
        return 1
    fi

    create_backup "$file"

    # Extract existing tasks
    local existing_tasks=$(sed -n "/^## $section/,/^##/p" "$file" | grep "^- \[.\]")

    # Add only unique new tasks
    while IFS= read -r task; do
        if [ -n "$task" ] && ! echo "$existing_tasks" | grep -Fq "$task"; then
            sed -i.tmp "/^## $section/a\\
$task" "$file"
            echo -e "${GREEN}✓ Added task: $task${NC}"
        fi
    done <<< "$new_tasks"

    rm -f "$file.tmp"
}

# Function to track task state changes
update_task_state() {
    local file="$1"
    local task_pattern="$2"
    local new_state="$3"  # pending|in_progress|completed

    if [ ! -f "$file" ]; then
        echo -e "${RED}✗ Task file not found${NC}"
        return 1
    fi

    create_backup "$file"

    case "$new_state" in
        "pending")
            sed -i.tmp "/$task_pattern/s/- \[.\]/- [ ]/" "$file"
            ;;
        "in_progress")
            sed -i.tmp "/$task_pattern/s/- \[.\]/- [~]/" "$file"
            ;;
        "completed")
            sed -i.tmp "/$task_pattern/s/- \[.\]/- [x]/" "$file"
            sed -i.tmp "/$task_pattern/s/$/ - Completed: $TIMESTAMP/" "$file"
            ;;
        *)
            echo -e "${RED}✗ Invalid state: $new_state${NC}"
            return 1
            ;;
    esac

    rm -f "$file.tmp"
    echo -e "${GREEN}✓ Task updated to: $new_state${NC}"
}

# Function to add session activity log entry
log_activity() {
    local file="$1"
    local activity="$2"

    local log_entry="- $TIMESTAMP: $activity"

    if [ -f "$file" ]; then
        append_to_section "$file" "Session Activity Log" "$log_entry"
    else
        echo "$log_entry" >> "$CLAUDE_CONTEXT/activity.log"
    fi
}

# Function to generate session summary
generate_summary() {
    local context_dir="${1:-$CLAUDE_CONTEXT}"

    echo -e "${BLUE}═══════════════════════════════════════════${NC}"
    echo -e "${BLUE}       📊 Context Summary${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════${NC}"

    # Check each context file
    for file in project-overview.md task-tracker.md decisions.md session-state.md; do
        if [ -f "$context_dir/$file" ]; then
            local lines=$(wc -l < "$context_dir/$file")
            local size=$(du -h "$context_dir/$file" | cut -f1)
            local modified=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$context_dir/$file" 2>/dev/null || stat -c "%y" "$context_dir/$file" 2>/dev/null | cut -d' ' -f1,2)
            echo -e "  ✓ $file"
            echo -e "    Size: $size | Lines: $lines | Modified: $modified"
        else
            echo -e "  ✗ $file (not found)"
        fi
    done

    # Task statistics
    if [ -f "$context_dir/task-tracker.md" ]; then
        local pending=$(grep -c "^- \[ \]" "$context_dir/task-tracker.md" 2>/dev/null || echo 0)
        local in_progress=$(grep -c "^- \[~\]" "$context_dir/task-tracker.md" 2>/dev/null || echo 0)
        local completed=$(grep -c "^- \[x\]" "$context_dir/task-tracker.md" 2>/dev/null || echo 0)

        echo ""
        echo -e "${YELLOW}📋 Task Statistics:${NC}"
        echo -e "  Pending: $pending | In Progress: $in_progress | Completed: $completed"

        if [ $((pending + in_progress + completed)) -gt 0 ]; then
            local completion_rate=$((completed * 100 / (pending + in_progress + completed)))
            echo -e "  Completion Rate: ${completion_rate}%"
        fi
    fi

    # Session count
    if [ -f "$context_dir/session-state.md" ]; then
        local sessions=$(grep -c "^## Session:" "$context_dir/session-state.md" 2>/dev/null || echo 0)
        echo ""
        echo -e "${YELLOW}🔄 Session History:${NC}"
        echo -e "  Total Sessions: $sessions"
        echo -e "  Current Session: $SESSION_ID"
    fi

    # Backup status
    if [ -d "$BACKUP_DIR" ]; then
        local backup_count=$(ls -1 "$BACKUP_DIR" 2>/dev/null | wc -l)
        local backup_size=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
        echo ""
        echo -e "${YELLOW}💾 Backup Status:${NC}"
        echo -e "  Backups: $backup_count files | Total Size: ${backup_size:-0}"
    fi

    echo -e "${BLUE}═══════════════════════════════════════════${NC}"
}

# Function to restore from backup
restore_from_backup() {
    local backup_file="$1"
    local target_file="$2"

    if [ ! -f "$BACKUP_DIR/$backup_file" ]; then
        echo -e "${RED}✗ Backup not found: $backup_file${NC}"
        return 1
    fi

    if [ -f "$target_file" ]; then
        create_backup "$target_file"
    fi

    cp "$BACKUP_DIR/$backup_file" "$target_file"
    echo -e "${GREEN}✓ Restored from backup: $backup_file${NC}"
}

# Function to clean old backups (keep last N)
clean_old_backups() {
    local keep_count="${1:-10}"

    if [ ! -d "$BACKUP_DIR" ]; then
        return 0
    fi

    local backup_count=$(ls -1 "$BACKUP_DIR" 2>/dev/null | wc -l)

    if [ "$backup_count" -gt "$keep_count" ]; then
        local remove_count=$((backup_count - keep_count))
        ls -1t "$BACKUP_DIR" | tail -n "$remove_count" | while read -r file; do
            rm "$BACKUP_DIR/$file"
            echo -e "${YELLOW}🗑 Removed old backup: $file${NC}"
        done
    fi

    echo -e "${GREEN}✓ Backup cleanup complete (kept last $keep_count)${NC}"
}

# Export functions for use by other scripts
export -f create_backup
export -f update_section
export -f append_to_section
export -f update_timestamps
export -f merge_tasks
export -f update_task_state
export -f log_activity
export -f generate_summary
export -f restore_from_backup
export -f clean_old_backups

# If sourced directly, show available functions
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    echo -e "${BLUE}Claude Context Preservation Module${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════${NC}"
    echo ""
    echo "Available functions:"
    echo "  • create_backup <file>"
    echo "  • update_section <file> <section> <content>"
    echo "  • append_to_section <file> <section> <content>"
    echo "  • update_timestamps <file>"
    echo "  • merge_tasks <file> <tasks> [section]"
    echo "  • update_task_state <file> <pattern> <state>"
    echo "  • log_activity <file> <activity>"
    echo "  • generate_summary [context_dir]"
    echo "  • restore_from_backup <backup> <target>"
    echo "  • clean_old_backups [keep_count]"
    echo ""
    echo "Source this file to use: source $0"
fi