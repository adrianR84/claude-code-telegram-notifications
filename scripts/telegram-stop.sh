#!/bin/bash
# telegram-stop.sh
# Sends a Telegram notification when Claude Code finishes responding.

# Load utilities
source "$(dirname "${BASH_SOURCE[0]}")/telegram-utils.sh"

# Initialize and validate Telegram configuration
if ! init_telegram_config; then
    exit 1
fi

# Format the message for Telegram
title="🤖 Claude Code"
message="✅ Finished responding"

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
