#!/bin/bash
# dsget config management

CONFIG_FILE="${HOME}/Library/Preferences/dsget-nodejs/config.json"
KEYCHAIN_SERVICE="dsget-nas"

# Ensure config directory exists
config_init() {
    local config_dir
    config_dir=$(dirname "$CONFIG_FILE")
    if [ ! -d "$config_dir" ]; then
        mkdir -p "$config_dir"
    fi
}

# Keychain password management (macOS)
keychain_get_password() {
    local server="$1"
    local host
    host=$(echo "$server" | jq -r '.server.config.host')
    
    # Try to get password from Keychain
    security find-internet-password -s "$host" -a "$(echo "$server" | jq -r '.server.credentials.username')" -w 2>/dev/null
}

keychain_save_password() {
    local server="$1"
    local host username password
    host=$(echo "$server" | jq -r '.server.config.host')
    username=$(echo "$server" | jq -r '.server.credentials.username')
    password=$(echo "$server" | jq -r '.server.credentials.password')
    
    # Save to Keychain (create or replace)
    security add-internet-password -s "$host" -a "$username" -w "$password" -U 2>/dev/null || \
    security add-internet-password -s "$host" -a "$username" -w "$password" 2>/dev/null
}

keychain_delete_password() {
    local server="$1"
    local host username
    host=$(echo "$server" | jq -r '.server.config.host')
    username=$(echo "$server" | jq -r '.server.credentials.username')
    
    security delete-internet-password -s "$host" -a "$username" 2>/dev/null
}

# Validate config schema
config_validate() {
    local config="$1"
    
    # Check if it's valid JSON
    if ! echo "$config" | jq -e . > /dev/null 2>&1; then
        echo "error: invalid json"
        return 1
    fi
    
    # Check for required fields (new format: .server.config)
    if echo "$config" | jq -e '.server.config | has("host") | not' > /dev/null 2>&1; then
        # Check old format: .config (deprecated)
        if echo "$config" | jq -e '.config | has("host")' > /dev/null 2>&1; then
            echo "warning: using deprecated config format"
            return 0
        fi
        echo "error: missing required fields"
        return 1
    fi
    
    return 0
}

# Get server config
config_get_server() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo ""
        return
    fi
    
    local config
    config=$(cat "$CONFIG_FILE")
    
    # Validate config
    local validation
    validation=$(config_validate "$config")
    if [ $? -ne 0 ]; then
        echo "$validation" >&2
        echo ""
        return
    fi
    
    # Warn about deprecated format
    if echo "$config" | jq -e '.config | has("host")' > /dev/null 2>&1; then
        echo "Warning: config file uses deprecated format" >&2
    fi
    
    echo "$config"
}

# Get credentials (try Keychain first, fall back to config file)
config_get_credentials() {
    local config="$1"
    local host username password keychain_pwd
    
    host=$(echo "$config" | jq -r '.server.config.host')
    username=$(echo "$config" | jq -r '.server.credentials.username')
    
    # Try Keychain first
    keychain_pwd=$(keychain_get_password "$config" 2>/dev/null)
    if [ -n "$keychain_pwd" ]; then
        password="$keychain_pwd"
    else
        # Fall back to config file
        password=$(echo "$config" | jq -r '.server.credentials.password')
    fi
    
    echo "$username:$password"
}

# Save server config (with Keychain)
config_save() {
    local host="$1"
    local port="$2"
    local use_https="$3"
    local sid="$4"
    local username="$5"
    local password="$6"
    
    config_init
    
    # Escape special characters for JSON
    local escaped_password
    escaped_password=$(echo "$password" | sed 's/\\/\\\\/g; s/"/\\"/g')
    
    cat > "$CONFIG_FILE" << EOF
{
  "server": {
    "config": {
      "host": "$host",
      "port": $port,
      "useHTTPS": $use_https,
      "sid": "$sid"
    },
    "credentials": {
      "username": "$username",
      "password": ""
    }
  }
}
EOF
    
    # Save password to Keychain (store separately from config)
    local temp_config
    temp_config=$(cat "$CONFIG_FILE")
    temp_config=$(echo "$temp_config" | jq --arg pwd "$password" '.server.credentials.password = $pwd')
    keychain_save_password "$temp_config"
    
    # Update config without password
    cat > "$CONFIG_FILE" << EOF
{
  "server": {
    "config": {
      "host": "$host",
      "port": $port,
      "useHTTPS": $use_https,
      "sid": "$sid"
    },
    "credentials": {
      "username": "$username",
      "password": ""
    }
  }
}
EOF
}

# Update session ID
config_update_sid() {
    local sid="$1"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        return 1
    fi
    
    local server
    server=$(cat "$CONFIG_FILE")
    local host port use_https username password
    
    host=$(echo "$server" | jq -r '.server.config.host')
    port=$(echo "$server" | jq -r '.server.config.port')
    use_https=$(echo "$server" | jq -r '.server.config.useHTTPS')
    username=$(echo "$server" | jq -r '.server.credentials.username')
    
    # Get password from Keychain
    password=$(keychain_get_password "$server" 2>/dev/null)
    
    if [ -z "$password" ]; then
        # Fall back to config file (legacy)
        password=$(echo "$server" | jq -r '.server.credentials.password')
    fi
    
    # Escape special characters for JSON
    local escaped_password
    escaped_password=$(echo "$password" | sed 's/\\/\\\\/g; s/"/\\"/g')
    
    cat > "$CONFIG_FILE" << EOF
{
  "server": {
    "config": {
      "host": "$host",
      "port": $port,
      "useHTTPS": $use_https,
      "sid": "$sid"
    },
    "credentials": {
      "username": "$username",
      "password": ""
    }
  }
}
EOF
}

# Clear session (keep credentials)
config_clear_session() {
    if [ ! -f "$CONFIG_FILE" ]; then
        return
    fi
    
    local server
    server=$(cat "$CONFIG_FILE")
    local host port use_https username password
    
    host=$(echo "$server" | jq -r '.server.config.host')
    port=$(echo "$server" | jq -r '.server.config.port')
    use_https=$(echo "$server" | jq -r '.server.config.useHTTPS')
    username=$(echo "$server" | jq -r '.server.credentials.username')
    
    cat > "$CONFIG_FILE" << EOF
{
  "server": {
    "config": {
      "host": "$host",
      "port": $port,
      "useHTTPS": $use_https,
      "sid": null
    },
    "credentials": {
      "username": "$username",
      "password": ""
    }
  }
}
EOF
}

# Clear all config (including Keychain)
config_clear() {
    if [ -f "$CONFIG_FILE" ]; then
        local server
        server=$(cat "$CONFIG_FILE")
        keychain_delete_password "$server" 2>/dev/null
        rm "$CONFIG_FILE"
    fi
}
