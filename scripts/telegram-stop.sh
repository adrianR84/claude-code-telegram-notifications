#!/bin/bash
# telegram-stop.sh
# Sends a Telegram notification when Claude Code finishes responding.

# Always show basic info for debugging
echo "=== Telegram Stop Hook Debug ==="
echo "Working directory: $(pwd)"
echo "Script location: ${BASH_SOURCE[0]}"
echo "CLAUDE_PLUGIN_ROOT: ${CLAUDE_PLUGIN_ROOT:-NOT_SET}"
echo "=============================="

# Load utilities
source "$(dirname "${BASH_SOURCE[0]}")/telegram-utils.sh"

# Initialize and validate Telegram configuration
if ! init_telegram_config; then
    exit 1
fi

# Try to read any input from stdin (in case Claude passes context)
raw_input=""
if read -t 1; then
    raw_input=$(cat)
    echo "Read from stdin: '$raw_input'"
elif [[ -p /dev/stdin ]]; then
    raw_input=$(cat)
    echo "Read from stdin (pipe): '$raw_input'"
fi

# Extract message from input if available, otherwise use default
if [[ -n "$raw_input" ]]; then
    # Try to extract meaningful content from the input
    task_info=$(echo "$raw_input" | grep -o '"message":"[^"]*"' | sed 's/"message":"\([^"]*\)"/\1/' | head -c 50)
    if [[ -n "$task_info" ]]; then
        message="✅ Completed: $task_info"
    else
        message="✅ Finished responding"
    fi
else
    message="✅ Finished responding"
fi

# Format the message for Telegram
title="*Claude Code*"
telegram_message="$title

$message"

# Escape special characters for Telegram Markdown format
escaped_message=$(escape_markdown "$telegram_message")

# Send to Telegram Bot API with retry logic
if send_telegram_message "$VALIDATED_BOT_TOKEN" "$VALIDATED_CHAT_ID" "$escaped_message"; then
    debug_log "Stop notification sent successfully"
    exit 0
else
    exit 1
fi
