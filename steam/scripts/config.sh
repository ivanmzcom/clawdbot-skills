#!/bin/bash
# steam config management

CONFIG_FILE="${HOME}/.steamcli.json"
KEYCHAIN_SERVICE="steam-cli"

keychain_get_apikey() {
    security find-generic-password -s "$KEYCHAIN_SERVICE" -a "apikey" -w 2>/dev/null
}

keychain_save_apikey() {
    local apikey="$1"
    security delete-generic-password -s "$KEYCHAIN_SERVICE" -a "apikey" 2>/dev/null
    security add-generic-password -s "$KEYCHAIN_SERVICE" -a "apikey" -w "$apikey" 2>/dev/null
}

config_load() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo ""
        return
    fi
    cat "$CONFIG_FILE"
}

config_get_apikey() {
    # Try Keychain first
    local key
    key=$(keychain_get_apikey 2>/dev/null)
    if [ -n "$key" ]; then
        echo "$key"
        return
    fi
    # Fall back to config
    local config
    config=$(config_load)
    if [ -z "$config" ]; then return 1; fi
    echo "$config" | jq -r '.apiKey // empty'
}

config_get_steamid() {
    local config
    config=$(config_load)
    if [ -z "$config" ]; then return 1; fi
    echo "$config" | jq -r '.steamId // empty'
}

config_save() {
    local apikey="$1"
    local steamid="$2"

    # Try saving API key to Keychain
    if keychain_save_apikey "$apikey"; then
        # Keychain worked, save config without API key
        cat > "$CONFIG_FILE" << EOF
{
  "steamId": "$steamid"
}
EOF
    else
        # Keychain unavailable, save API key in config file
        echo "Warning: Keychain unavailable, storing API key in config file." >&2
        cat > "$CONFIG_FILE" << EOF
{
  "steamId": "$steamid",
  "apiKey": "$apikey"
}
EOF
    fi
}

config_require() {
    local apikey steamid
    apikey=$(config_get_apikey)
    steamid=$(config_get_steamid)

    if [ -z "$apikey" ] || [ -z "$steamid" ]; then
        echo "Not configured. Run 'steam config' first." >&2
        exit 1
    fi
}
