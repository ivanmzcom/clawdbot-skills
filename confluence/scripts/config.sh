#!/bin/bash
# confluence config management

CONFIG_DIR="${HOME}/.config/confluence-cli"
CONFIG_FILE="${CONFIG_DIR}/config.json"
KEYCHAIN_SERVICE="confluence-cli"

config_init() {
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
    fi
}

keychain_get_token() {
    security find-internet-password -s "$KEYCHAIN_SERVICE" -a "token" -w 2>/dev/null
}

keychain_save_token() {
    local token="$1"
    security add-internet-password -s "$KEYCHAIN_SERVICE" -a "token" -w "$token" -U 2>/dev/null || \
    security add-internet-password -s "$KEYCHAIN_SERVICE" -a "token" -w "$token" 2>/dev/null
}

keychain_delete_token() {
    security delete-internet-password -s "$KEYCHAIN_SERVICE" -a "token" 2>/dev/null || true
}

config_load() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo ""
        return
    fi
    cat "$CONFIG_FILE"
}

config_get_url() {
    local config
    config=$(config_load)
    if [ -z "$config" ]; then return 1; fi
    echo "$config" | jq -r '.url // empty'
}

config_get_username() {
    local config
    config=$(config_load)
    if [ -z "$config" ]; then return 1; fi
    echo "$config" | jq -r '.username // empty'
}

config_get_token() {
    # Try Keychain first
    local token
    token=$(keychain_get_token 2>/dev/null)
    if [ -n "$token" ]; then
        echo "$token"
        return
    fi
    # Fall back to config file
    local config
    config=$(config_load)
    if [ -z "$config" ]; then return 1; fi
    echo "$config" | jq -r '.token // empty'
}

config_save() {
    local url="$1"
    local username="$2"
    local token="$3"

    config_init

    # Save token to Keychain
    keychain_save_token "$token"

    # Save config without token
    cat > "$CONFIG_FILE" << EOF
{
  "url": "$url",
  "username": "$username"
}
EOF
}

config_validate() {
    local url username token
    url=$(config_get_url)
    username=$(config_get_username)
    token=$(config_get_token)

    if [ -z "$url" ] || [ -z "$username" ] || [ -z "$token" ]; then
        return 1
    fi
    return 0
}

config_require() {
    if ! config_validate; then
        echo "Not configured. Run 'confluence config' first." >&2
        exit 1
    fi
}
