# Claude Code Telegram Notifications

A Claude Code plugin that sends real-time notifications to your Telegram bot when Claude Code events occur.

## 🚀 Features

- **Real-time Notifications**: Get instant Telegram alerts for Claude Code events
- **Event Types**: Supports both `Notification` and `Stop` hooks
- **Secure Configuration**: Uses environment variables for bot token and chat ID
- **Cross-Platform**: Works on Windows, macOS, and Linux with bash scripts
- **Robust Error Handling**: Comprehensive validation and retry logic
- **Performance Optimized**: Fast-path processing for clean content
- **Security Hardened**: Input sanitization and injection protection
- **Markdown Support**: Proper Telegram MarkdownV2 formatting
- **Debug Mode**: Optional verbose logging for troubleshooting

## 📦 Installation

### Option 1: Via Plugin Marketplace (Recommended)

First, add the marketplace:

```bash
/plugin marketplace add https://github.com/adrianR84/claude-code-plugins-adi
```

Then install the plugin:

```bash
/plugin install telegram-notifications@claude-code-plugins-adi
```

### Option 2: Direct Plugin Install

```bash
claude-code plugin install https://github.com/adrianR84/claude-code-telegram-notifications
```

### Option 3: Local Installation for Development

```bash
# Clone the repository
git clone https://github.com/adrianR84/claude-code-telegram-notifications.git
cd claude-code-telegram-notifications

# Install locally
claude-code plugin install ./
```

## ⚙️ Configuration

1. **Copy the environment template:**

   ```bash
   cp .env.example .env
   ```

2. **Edit `.env` with your Telegram bot details:**
   ```bash
   # Get these from @BotFather on Telegram
   TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz
   TELEGRAM_CHAT_ID=123456789
   ```

### Getting Telegram Credentials

1. **Create a Telegram Bot:**
   - Message @BotFather on Telegram
   - Send `/newbot`
   - Follow the instructions to create your bot
   - Copy the bot token

2. **Get Your Chat ID:**
   - Message your bot on Telegram
   - Visit `https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates`
   - Find your `chat_id` in the response (positive number or @username)

## 🧪 Testing

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

## 📁 Project Structure

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

## 🔧 How It Works

1. **Hook Registration**: The plugin registers `Notification` and `Stop` hooks with Claude Code
2. **Event Detection**: When events occur, Claude Code triggers the corresponding hook
3. **Message Processing**: Scripts parse the JSON input and extract relevant information
4. **Security Validation**: All inputs are validated and sanitized before processing
5. **Telegram API**: Messages are sent to your Telegram bot using the Bot API
6. **Error Handling**: Failed requests are retried with exponential backoff

## 🛡️ Security Features

- **Input Validation**: Comprehensive JSON structure and content validation
- **Sanitization**: Control characters and dangerous content removed
- **Environment Protection**: Invalid variable names rejected
- **Injection Prevention**: Protection against command injection attacks
- **Resource Management**: Proper cleanup and file descriptor handling
- **Error Isolation**: Sensitive data filtered from error logs

## ⚡ Performance Optimizations

- **Fast-Path Processing**: Skip unnecessary processing for clean content
- **Optimized JSON Parsing**: Single regex pattern with minimal fallbacks
- **Bash Built-ins**: Use parameter expansion instead of subprocess calls
- **Intelligent Caching**: Avoid redundant operations
- **Efficient Retry Logic**: Exponential backoff with reasonable limits

## 🔍 Debugging

Enable debug mode for detailed logging:

```bash
DEBUG=true bash ./scripts/telegram-notification.sh
```

Debug output includes:

- Environment loading details
- JSON parsing steps
- Telegram API responses
- Error stack traces

## 📋 Requirements

- **Claude Code**: Latest version with plugin support
- **Bash**: Version 4.0+ recommended (fallbacks for older versions)
- **curl**: For HTTP requests to Telegram API
- **sed**: For text processing
- **grep**: For pattern matching
- **tr**: For character translation
- **wc**: For counting operations

## 🚨 Troubleshooting

### Common Issues

1. **"TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID environment variables must be set"**
   - Make sure you've created `.env` from `.env.example`
   - Verify the values are correct and have no extra spaces

2. **"Failed to send Telegram notification"**
   - Check your bot token is valid
   - Verify your chat ID is correct (numeric or @username)
   - Ensure your bot can message you (send it a message first)

3. **"Invalid JSON format"**
   - The hook input should be valid JSON
   - Check for unbalanced braces or missing quotes

4. **"Missing required dependencies"**
   - Install missing commands: `curl`, `sed`, `grep`, `tr`, `wc`
   - On Windows: Use Git Bash or WSL

### Getting Help

- **GitHub Issues**: [Report bugs](https://github.com/adrianR84/claude-code-telegram-notifications/issues)
- **Discussions**: [Ask questions](https://github.com/adrianR84/claude-code-telegram-notifications/discussions)
- **Wiki**: [Documentation](https://github.com/adrianR84/claude-code-telegram-notifications/wiki)

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 🌟 Acknowledgments

# Optional

DEBUG=true # Enable debug logging

````

Check if your bot works:

```bash
token="YOUR_BOT_TOKEN"
curl -s "https://api.telegram.org/bot$token/getMe"
````

## License

MIT

## About

Telegram bot notifications for Claude Code events using the official Telegram Bot API.
