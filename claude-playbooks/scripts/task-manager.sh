#!/bin/bash

# Claude Task Management System
# Provides utilities for cross-session task tracking

CLAUDE_CONTEXT=".claude-context"
TASK_FILE="$CLAUDE_CONTEXT/task-tracker.md"

# Function to add a new task
add_task() {
    local task_desc="$1"
    local priority="${2:-normal}"
    local timestamp=$(date '+%Y-%m-%d %H:%M')
    
    echo "- [ ] **$task_desc** _(Priority: $priority, Added: $timestamp)_" >> "$TASK_FILE"
    echo "✅ Task added: $task_desc"
}

# Function to mark task as completed
complete_task() {
    local task_pattern="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M')
    
    # Replace [ ] with [x] and add completion timestamp
    sed -i.bak "/$task_pattern/s/- \[ \]/- [x]/" "$TASK_FILE"
    sed -i.bak "/$task_pattern/s/)_$/) - Completed: $timestamp)_/" "$TASK_FILE"
    
    echo "✅ Task completed: $task_pattern"
}

# Function to update task progress
update_task() {
    local task_pattern="$1"
    local progress_note="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M')
    
    # Add progress note to the task line
    sed -i.bak "/$task_pattern/s/)_$/ - Progress: $progress_note - $timestamp)_/" "$TASK_FILE"
    
    echo "📝 Task updated: $task_pattern"
}

# Function to show active tasks
show_tasks() {
    echo "📋 Current Tasks:"
    echo "=================="
    
    if [ -f "$TASK_FILE" ]; then
        # Show pending tasks
        echo -e "\n🔄 ACTIVE TASKS:"
        grep "- \[ \]" "$TASK_FILE" | head -10
        
        # Show recently completed tasks
        echo -e "\n✅ RECENTLY COMPLETED:"
        grep "- \[x\]" "$TASK_FILE" | tail -5
    else
        echo "No task file found. Initialize with: source ~/.claude/scripts/auto-launch.sh"
    fi
}

# Function to clean up old tasks
cleanup_tasks() {
    local backup_date=$(date '+%Y%m%d-%H%M%S')
    
    # Archive completed tasks older than 7 days
    cp "$TASK_FILE" "$CLAUDE_CONTEXT/task-archive-$backup_date.md"
    
    # Keep only recent completed tasks in main file
    grep -v "Completed:" "$TASK_FILE" > "$TASK_FILE.tmp"
    grep "Completed:" "$TASK_FILE" | tail -10 >> "$TASK_FILE.tmp"
    mv "$TASK_FILE.tmp" "$TASK_FILE"
    
    echo "🧹 Tasks cleaned up. Archive saved as task-archive-$backup_date.md"
}

# Function to generate session summary
session_summary() {
    echo "📊 Session Summary"
    echo "=================="
    
    local today=$(date '+%Y-%m-%d')
    local completed_today=$(grep "Completed: $today" "$TASK_FILE" | wc -l)
    local total_pending=$(grep "- \[ \]" "$TASK_FILE" | wc -l)
    
    echo "Tasks completed today: $completed_today"
    echo "Total pending tasks: $total_pending"
    
    if [ $completed_today -gt 0 ]; then
        echo -e "\n✅ Today's Completions:"
        grep "Completed: $today" "$TASK_FILE"
    fi
}

# Main command handler
case "$1" in
    "add")
        add_task "$2" "$3"
        ;;
    "complete")
        complete_task "$2"
        ;;
    "update")
        update_task "$2" "$3"
        ;;
    "show")
        show_tasks
        ;;
    "cleanup")
        cleanup_tasks
        ;;
    "summary")
        session_summary
        ;;
    *)
        echo "Usage: $0 {add|complete|update|show|cleanup|summary}"
        echo ""
        echo "Examples:"
        echo "  $0 add 'Implement user authentication' high"
        echo "  $0 complete 'Implement user authentication'"
        echo "  $0 update 'Implement user authentication' 'Added login form'"
        echo "  $0 show"
        echo "  $0 summary"
        echo "  $0 cleanup"
        ;;
esac