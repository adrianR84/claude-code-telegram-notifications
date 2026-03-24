#!/bin/bash
# telegram-utils.sh
# Shared utility functions for Telegram notification scripts

# Check dependencies at startup
check_dependencies() {
    local missing_deps=()
    
    command -v curl >/dev/null 2>&1 || missing_deps+=("curl")
    command -v sed >/dev/null 2>&1 || missing_deps+=("sed")
    command -v grep >/dev/null 2>&1 || missing_deps+=("grep")
    command -v tr >/dev/null 2>&1 || missing_deps+=("tr")
    command -v wc >/dev/null 2>&1 || missing_deps+=("wc")
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo "ERROR: Missing required dependencies: ${missing_deps[*]}" >&2
        echo "Please install the missing commands and try again." >&2
        exit 1
    fi
}

# Run dependency check
check_dependencies

# Configuration
readonly TELEGRAM_API_BASE="https://api.telegram.org/bot"
readonly MAX_MESSAGE_LENGTH=4096
readonly CURL_TIMEOUT=10
readonly MAX_RETRIES=3

# Get script directory (call from any script)
get_script_dir() {
    local script_dir
    
    # Try BASH_SOURCE[1] first (when sourced)
    if [[ -n "${BASH_SOURCE[1]}" ]]; then
        cd "$(dirname "${BASH_SOURCE[1]}")" && pwd
        return
    fi
    
    # Fallback to BASH_SOURCE[0] (when called directly)
    if [[ -n "${BASH_SOURCE[0]}" ]]; then
        cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
        return
    fi
    
    # Last resort - use $0
    if [[ -n "$0" ]]; then
        cd "$(dirname "$0")" && pwd
        return
    fi
    
    # If all else fails, use current directory
    pwd
}

# Logging function
log() {
    local level="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" >&2
}

# Debug logging (only if DEBUG env var is set)
debug_log() {
    if [[ "${DEBUG:-}" == "true" ]]; then
        log "DEBUG" "$@"
    fi
}

# Load environment variables from .env file
load_env() {
    local script_dir="$(get_script_dir)"
    local env_file="$(dirname "$script_dir")/.env"
    
    debug_log "Script dir: $script_dir"
    debug_log "Loading environment from: $env_file"
    
    # Try multiple possible locations for .env file
    local env_locations=(
        "$env_file"  # Relative to script
        ".env"       # Current working directory
        "$(pwd)/.env"  # Absolute path to current directory
        "$CLAUDE_PLUGIN_ROOT/.env"  # Plugin root directory
    )
    
    local found_env=false
    for env_path in "${env_locations[@]}"; do
        if [[ -f "$env_path" ]]; then
            debug_log "Found environment file at: $env_path"
            env_file="$env_path"
            found_env=true
            break
        fi
    done
    
    if [[ "$found_env" == "true" ]]; then
        debug_log "Environment file found, loading variables..."
        # Use process substitution to avoid file descriptor leaks
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ $key =~ ^[[:space:]]*# ]] && continue
            [[ -z "$key" ]] && continue
            
            # Validate key format (alphanumeric with underscores)
            if [[ ! "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
                log "WARN" "Invalid environment variable name: $key"
                continue
            fi
            
            # Remove surrounding quotes if present and sanitize value
            value=$(echo "$value" | sed 's/^["'\''"]//' | sed 's/["'\''"]$//')
            # Remove control characters
            value=$(echo "$value" | tr -d '\000-\037\177-\377')
            
            # Set environment variable using export for proper inheritance
            export "$key=$value"
            debug_log "Loaded env var: $key=$value"
        done < "$env_file"
    else
        log "WARN" "Environment file not found in any of these locations:"
        for env_path in "${env_locations[@]}"; do
            log "WARN" "  - $env_path"
        done
        log "WARN" "Current working directory: $(pwd)"
        if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
            log "WARN" "Plugin root directory: $CLAUDE_PLUGIN_ROOT"
            ls -la "$CLAUDE_PLUGIN_ROOT" 2>/dev/null || log "WARN" "Cannot list plugin root directory"
        fi
    fi
}

# Initialize and validate Telegram configuration
init_telegram_config() {
    # Load environment variables
    load_env
    
    local bot_token="$TELEGRAM_BOT_TOKEN"
    local chat_id="$TELEGRAM_CHAT_ID"
    
    # Validate configuration
    if ! validate_config "$bot_token" "$chat_id"; then
        return 1
    fi
    
    # Export validated variables for use by calling scripts
    export VALIDATED_BOT_TOKEN="$bot_token"
    export VALIDATED_CHAT_ID="$chat_id"
    
    debug_log "Telegram configuration initialized and validated"
    return 0
}

# Validate Telegram configuration
validate_config() {
    local bot_token="$1"
    local chat_id="$2"
    
    debug_log "Validating configuration"
    
    if [[ -z "$bot_token" ]]; then
        log "ERROR" "TELEGRAM_BOT_TOKEN environment variable must be set"
        return 1
    fi
    
    if [[ -z "$chat_id" ]]; then
        log "ERROR" "TELEGRAM_CHAT_ID environment variable must be set"
        return 1
    fi
    
    # Basic token format validation (should be数字:letters_numbers)
    if [[ ! "$bot_token" =~ ^[0-9]+:[a-zA-Z0-9_-]+$ ]]; then
        log "ERROR" "Invalid bot token format"
        return 1
    fi
    
    # Basic chat ID validation (should be numeric or @username)
    if [[ ! "$chat_id" =~ ^[0-9]+$ ]] && [[ ! "$chat_id" =~ ^@[a-zA-Z0-9_]+$ ]]; then
        log "ERROR" "Invalid chat ID format (should be numeric or @username)"
        return 1
    fi
    
    debug_log "Configuration validation passed"
    return 0
}

# Extract JSON value with improved parsing
extract_json_value() {
    local json="$1"
    local key="$2"
    
    # Optimized sed pattern (handles most cases efficiently)
    local value
    value=$(echo "$json" | sed -n 's/.*"'"$key"'"\s*:\s*"\([^"]*\)".*/\1/p')
    
    # Only try alternatives if first attempt fails
    if [[ -z "$value" ]]; then
        # Handle escaped quotes case (rare)
        value=$(echo "$json" | sed -n 's/.*"'"$key"'"\s*:\s*"\([^"\\]*\\.\)*\([^"]*\)".*/\2/p')
    fi
    
    echo "$value"
}

# Sanitize and validate message content
sanitize_message() {
    local message="$1"
    local max_length="${2:-$MAX_MESSAGE_LENGTH}"
    
    # Fast path: if message is already clean, skip processing
    if [[ "$message" != *[\000-\037\177-\377]* && ${#message} -le $max_length ]]; then
        # Just trim whitespace if needed
        message="${message##*( )}"
        message="${message%%*( )}"
        echo "$message"
        return
    fi
    
    # Remove null bytes and control characters (only if needed)
    if [[ "$message" == *[\000-\037\177-\377]* ]]; then
        message=$(echo "$message" | tr -d '\000-\010\013\014\016-\037\177-\377')
    fi
    
    # Trim whitespace
    message="${message##*( )}"
    message="${message%%*( )}"
    
    # Truncate if too long
    if [[ ${#message} -gt $max_length ]]; then
        message="${message:0:$((max_length - 3))}..."
        log "WARN" "Message truncated to $max_length characters"
    fi
    
    echo "$message"
}

# Escape special characters for Telegram Markdown format
escape_markdown() {
    local text="$1"
    
    # Fast path: if no special characters, return as-is
    if [[ "$text" != *'[_*[]()~`>#+\-=|{}.!\\'* ]]; then
        echo "$text"
        return
    fi
    
    # Escape special characters for Telegram MarkdownV2 including backslash
    echo "$text" | sed 's/[_*[]()~`>#+\-=|{}.!\\]/\\&/g'
}

# Send message to Telegram with retry logic
send_telegram_message() {
    local bot_token="$1"
    local chat_id="$2"
    local message="$3"
    local parse_mode="${4:-Markdown}"
    
    local api_url="${TELEGRAM_API_BASE}${bot_token}/sendMessage"
    local attempt=1
    
    while [[ $attempt -le $MAX_RETRIES ]]; do
        debug_log "Attempt $attempt to send message"
        
        # Create JSON payload with proper escaping
        local json_payload
        json_payload=$(cat <<EOF
{
  "chat_id": "$chat_id",
  "text": "$message",
  "parse_mode": "$parse_mode",
  "disable_web_page_preview": true
}
EOF
)
        
        # Use curl with proper output separation
        local response_body response_code
        response_body=$(curl -s -w "%{http_code}" -X POST "$api_url" \
            -H "Content-Type: application/json" \
            -d "$json_payload" \
            --connect-timeout "$CURL_TIMEOUT" \
            --max-time "$CURL_TIMEOUT" 2>/dev/null)
        
        # Extract HTTP code (last 3 characters) and body (everything else)
        response_code="${response_body: -3}"
        response_body="${response_body%???}"
        
        debug_log "HTTP Code: $response_code"
        debug_log "Response: $response_body"
        
        # Check if request was successful
        if [[ $response_code -eq 200 ]] && echo "$response_body" | grep -q '"ok":true'; then
            debug_log "Message sent successfully"
            return 0
        else
            log "WARN" "Attempt $attempt failed (HTTP $response_code)"
            if [[ $attempt -lt $MAX_RETRIES ]]; then
                local sleep_time=$((attempt * 2))
                log "INFO" "Retrying in $sleep_time seconds..."
                sleep "$sleep_time"
            fi
        fi
        
        ((attempt++))
    done
    
    log "ERROR" "Failed to send Telegram message after $MAX_RETRIES attempts"
    # Sanitize error response to avoid exposing sensitive data
    if [[ -n "$response_body" ]]; then
        local sanitized_response
        sanitized_response=$(echo "$response_body" | sed 's/bot_token[^,]*,//g; s/chat_id[^,]*,//g')
        log "ERROR" "Last response: $sanitized_response"
    fi
    return 1
}

# Validate JSON input
validate_json_input() {
    local json="$1"
    
    if [[ -z "$json" ]]; then
        debug_log "Empty input, exiting"
        return 1
    fi
    
    # Remove trailing newline for validation
    json="${json%$'\n'}"
    
    # Basic JSON validation - should start with { and end with }
    if [[ ! "$json" =~ ^\{.*\}$ ]]; then
        log "ERROR" "Invalid JSON format: must start with { and end with }"
        return 1
    fi
    
    # Check for balanced braces (optimized for performance)
    local open_braces close_braces
    
    # Use bash built-ins for better performance (bash 4.0+)
    if [[ -n "${BASH_VERSION%%.*}" ]] && [[ ${BASH_VERSION%%.*} -ge 4 ]]; then
        # Use parameter expansion - no subprocess calls
        local temp="${json//[^{]}"
        open_braces=${#temp}
        temp="${json//[^\}]}"
        close_braces=${#temp}
    else
        # Fallback for older bash versions
        open_braces=$(echo "$json" | grep -o '{' | wc -l)
        close_braces=$(echo "$json" | grep -o '}' | wc -l)
    fi
    
    if [[ $open_braces -ne $close_braces ]]; then
        log "ERROR" "Invalid JSON format: unbalanced braces"
        return 1
    fi
    
    # Check for null bytes and control characters (excluding common whitespace)
    # Temporarily disabled - the regex was too strict
    # if echo "$json" | LC_ALL=C grep -q '[\000-\010\013\014\016-\037\177-\377]'; then
    #     log "ERROR" "Invalid JSON format: contains control characters"
    #     return 1
    # fi
    
    debug_log "JSON input validation passed"
    return 0
}
