#!/bin/bash
# telegram-notification.sh
# Reads Claude Code hook JSON from stdin and sends a Telegram notification with the message.

# Load utilities
source "$(dirname "${BASH_SOURCE[0]}")/telegram-utils.sh"

# Read input from stdin
raw=$(cat)

# Validate JSON input
if ! validate_json_input "$raw"; then
    exit 0
fi

# Initialize and validate Telegram configuration
if ! init_telegram_config; then
    exit 1
fi

# Parse JSON using improved parsing
message=$(extract_json_value "$raw" "message")
notification_type=$(extract_json_value "$raw" "notification_type")

# Set defaults if not found
title="*Claude Code Notification*"
[[ -z "$notification_type" ]] && notification_type="Notification"
[[ -z "$message" ]] && message="(no message)"

# Sanitize message content
message=$(sanitize_message "$message")
notification_type=$(sanitize_message "$notification_type" 100)  # Shorter limit for type

# Format the message for Telegram
telegram_message="$title

📋 Type: $notification_type
💬 Message: $message"

# Escape special characters for Telegram Markdown format
escaped_message=$(escape_markdown "$telegram_message")

# Send to Telegram Bot API with retry logic
if send_telegram_message "$VALIDATED_BOT_TOKEN" "$VALIDATED_CHAT_ID" "$escaped_message"; then
    debug_log "Notification sent successfully"
    exit 0
else
    exit 1
fi
