# Claude Code Telegram Notifications

Telegram bot notifications for [Claude Code](https://claude.ai/code) events using the Telegram Bot API.

## Features

- **Notification Hook**: Sends a Telegram notification when Claude Code sends notifications (e.g., asking for input, tool permission requests)
- **Stop Hook**: Sends a Telegram notification when Claude Code finishes responding
- **Robust Error Handling**: Comprehensive validation and error reporting
- **Retry Logic**: Automatic retries with exponential backoff for network issues
- **Message Sanitization**: Input validation and message length limits
- **Debug Mode**: Enable debug logging with `DEBUG=true` environment variable
- **Cross-Platform**: Works on Linux, macOS, and Windows (with WSL/Git Bash)
- **Security Hardened**: Input sanitization, dependency validation, and environment variable protection
- **Production Ready**: Comprehensive error handling and resource management

## Prerequisites

- Bash shell (Linux, macOS, or Windows with WSL/Git Bash)
- curl command-line tool
- Internet connection for Telegram API access
- Telegram bot and chat ID

## Setup

### 1. Create a Telegram Bot

1. Open Telegram and search for `@BotFather`
2. Send `/newbot` to create a new bot
3. Follow the instructions to name your bot
4. Save the bot token (looks like: `1234567890:ABCdefGHIjklMNOpqrsTUVwxyz`)

### 2. Get Your Chat ID

1. Open Telegram and search for `@userinfobot`
2. Send any message to the bot
3. The bot will reply with your chat ID (looks like: `123456789`)

### 3. Configure the Plugin

1. Copy `.env.example` to `.env`:

   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and replace with your actual values:
   ```env
   TELEGRAM_BOT_TOKEN=1234567890:ABCdefGHIjklMNOpqrsTUVwxyz
   TELEGRAM_CHAT_ID=123456789
   ```

## Installation

### Option 1: Via Plugin Marketplace (Recommended)

First, add the marketplace:

```
/plugin marketplace add /path/to/claude-code-telegram-notifications
```

Then install the plugin:

```
/plugin install telegram-notifications@claude-code-telegram-notifications
```

### Option 2: Direct Plugin Install

```
/plugin install /path/to/claude-code-telegram-notifications
```

### Option 3: Local Installation (for development)

```
/plugin marketplace add /path/to/claude-code-telegram-notifications
/plugin install telegram-notifications@claude-code-telegram-notifications
```

## Usage

Once installed and configured, the plugin automatically:

1. Sends a Telegram notification when Claude Code needs your attention
2. Sends a "Finished responding" notification when Claude completes a response

## Hook Events

The plugin responds to these Claude Code hook events:

- `Notification` - Triggered when Claude Code sends notifications
- `Stop` - Triggered when Claude Code finishes responding

## Project Structure

```
claude-code-telegram-notifications/
├── .claude-plugin/
│   ├── plugin.json          # Plugin manifest
│   └── marketplace.json     # Marketplace manifest
├── hooks/
│   └── hooks.json           # Hook configuration
├── scripts/
│   ├── telegram-utils.sh         # Shared utility functions
│   ├── telegram-notification.sh  # Notification handler
│   └── telegram-stop.sh          # Stop event handler
├── tests/
│   ├── test-security.sh          # Security and functionality tests
│   ├── test-performance.sh        # Performance benchmarking
│   ├── test-function.sh          # Basic function tests
│   ├── run-all-tests.sh          # Test runner
│   └── README.md                 # Test documentation
├── .env.example             # Environment variables template
├── .env                     # Your actual configuration (create this)
└── README.md
```

## Testing

### Quick Test

```bash
# Run all tests
bash tests/run-all-tests.sh

# Or run individual test suites
bash tests/test-security.sh
bash tests/test-performance.sh
bash tests/test-function.sh
```

### Manual Testing

Test the notification hook:

```bash
# Test notification
echo '{"message": "Test notification", "notification_type": "info"}' | bash ./scripts/telegram-notification.sh

# Test stop notification
bash ./scripts/telegram-stop.sh

# Test with debug mode
DEBUG=true echo '{"message": "Debug test", "notification_type": "info"}' | bash ./scripts/telegram-notification.sh
```

### Test Coverage

The test suite includes:

- **Security Tests**: Input validation, sanitization, and vulnerability checks
- **Performance Tests**: Benchmarking of critical operations
- **Function Tests**: Basic functionality and loading verification

See `tests/README.md` for detailed test information.

## Troubleshooting

### Common Issues

1. **"TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID environment variables must be set"**
   - Make sure you've created `.env` from `.env.example`
   - Verify the values are correct and have no extra spaces

2. **"Failed to send Telegram notification"**
   - Check your bot token is correct
   - Verify your chat ID is correct
   - Ensure you've started a chat with your bot first

3. **Script permissions**
   - Make scripts executable:
     ```bash
     chmod +x scripts/*.sh
     ```

4. **Debug mode**
   - Enable debug logging:
     ```bash
     export DEBUG=true
     ```
   - Or add to `.env` file:
     ```env
     DEBUG=true
     ```

### Security Features

The plugin includes comprehensive security measures:

- **Input Validation**: All JSON input is validated for structure and content
- **Message Sanitization**: Control characters and dangerous content are removed
- **Environment Protection**: Invalid environment variable names are rejected
- **Dependency Checking**: Required commands are verified at startup
- **Error Sanitization**: Sensitive data is removed from error logs
- **Resource Management**: Proper file descriptor handling and cleanup

### Advanced Configuration

The plugin supports additional environment variables in your `.env` file:

```env
# Required
TELEGRAM_BOT_TOKEN=your_bot_token_here
TELEGRAM_CHAT_ID=your_chat_id_here

# Optional
DEBUG=true                    # Enable debug logging
```

Check if your bot works:

```bash
token="YOUR_BOT_TOKEN"
curl -s "https://api.telegram.org/bot$token/getMe"
```

## License

MIT

## About

Telegram bot notifications for Claude Code events using the official Telegram Bot API.
