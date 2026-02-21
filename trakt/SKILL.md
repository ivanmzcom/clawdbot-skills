---
name: trakt
description: "Track TV shows and movies with Trakt.tv via direct API calls. Use when the user asks about upcoming episodes, TV show schedule, watchlist, or watch history."
---

# Trakt.tv (Direct API)

Direct curl calls to Trakt.tv API. No CLI dependency needed.

## API Details

- **Base URL:** `https://api.trakt.tv`
- **Client ID:** keychain (`security find-generic-password -s trakt -a client_id -w`)
- **Client Secret:** keychain (`security find-generic-password -s trakt -a client_secret -w`)
- **Access Token:** keychain (`security find-generic-password -s trakt -a access_token -w`)
- **Refresh Token:** keychain (`security find-generic-password -s trakt -a refresh_token -w`)
- **Token Expiry:** `~/.config/trakt/config.json` → `expiresAt` (epoch ms)

## Authentication

Tokens are already stored in Keychain. Before each request, check if the token needs refreshing:

### Refresh token (if expired)

```bash
TRAKT_CLIENT_ID="$(security find-generic-password -s trakt -a client_id -w)"
TRAKT_CLIENT_SECRET="$(security find-generic-password -s trakt -a client_secret -w)"
REFRESH_TOKEN=$(security find-generic-password -s trakt -a refresh_token -w)

RESPONSE=$(curl -s -X POST "https://api.trakt.tv/oauth/token" \
  -H "Content-Type: application/json" \
  -d "{\"refresh_token\":\"$REFRESH_TOKEN\",\"client_id\":\"$TRAKT_CLIENT_ID\",\"client_secret\":\"$TRAKT_CLIENT_SECRET\",\"grant_type\":\"refresh_token\"}")

NEW_ACCESS=$(echo "$RESPONSE" | jq -r '.access_token')
NEW_REFRESH=$(echo "$RESPONSE" | jq -r '.refresh_token')
CREATED=$(echo "$RESPONSE" | jq -r '.created_at')
EXPIRES_IN=$(echo "$RESPONSE" | jq -r '.expires_in')
EXPIRES_AT=$(( (CREATED + EXPIRES_IN) * 1000 ))

security add-generic-password -U -s trakt -a access_token -w "$NEW_ACCESS"
security add-generic-password -U -s trakt -a refresh_token -w "$NEW_REFRESH"
echo "{\"expiresAt\":$EXPIRES_AT}" > ~/.config/trakt/config.json
```

## Making Requests

All authenticated requests need these headers:

```bash
TRAKT_TOKEN=$(security find-generic-password -s trakt -a access_token -w)
TRAKT_CLIENT_ID="$(security find-generic-password -s trakt -a client_id -w)"

curl -s "https://api.trakt.tv/ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "trakt-api-version: 2" \
  -H "trakt-api-key: $TRAKT_CLIENT_ID" \
  -H "Authorization: Bearer $TRAKT_TOKEN"
```

## Upcoming Episodes

```bash
TRAKT_TOKEN=$(security find-generic-password -s trakt -a access_token -w)
TRAKT_CLIENT_ID="$(security find-generic-password -s trakt -a client_id -w)"
TODAY=$(date "+%Y-%m-%d")
DAYS=7

curl -s "https://api.trakt.tv/calendars/my/shows/$TODAY/$DAYS" \
  -H "Content-Type: application/json" \
  -H "trakt-api-version: 2" \
  -H "trakt-api-key: $TRAKT_CLIENT_ID" \
  -H "Authorization: Bearer $TRAKT_TOKEN" | python3 -c "
import sys,json
for ep in json.load(sys.stdin):
    show = ep['show']['title']
    s = ep['episode']['season']
    e = ep['episode']['number']
    title = ep['episode'].get('title','')
    air = ep.get('first_aired','')[:10]
    print(f'{air} {show} S{s:02d}E{e:02d} - {title}')
"
```

## Watchlist

```bash
curl -s "https://api.trakt.tv/users/me/watchlist" \
  -H "Content-Type: application/json" \
  -H "trakt-api-version: 2" \
  -H "trakt-api-key: $TRAKT_CLIENT_ID" \
  -H "Authorization: Bearer $TRAKT_TOKEN" | python3 -c "
import sys,json
for item in json.load(sys.stdin):
    t = item['type']
    if t == 'movie':
        name = item['movie']['title']
        year = item['movie'].get('year','')
        print(f'[M] {name} ({year})')
    elif t == 'show':
        name = item['show']['title']
        year = item['show'].get('year','')
        print(f'[TV] {name} ({year})')
"
```

## Watch History

```bash
LIMIT=20

curl -s "https://api.trakt.tv/users/me/history?limit=$LIMIT" \
  -H "Content-Type: application/json" \
  -H "trakt-api-version: 2" \
  -H "trakt-api-key: $TRAKT_CLIENT_ID" \
  -H "Authorization: Bearer $TRAKT_TOKEN" | python3 -c "
import sys,json
for item in json.load(sys.stdin):
    t = item['type']
    when = item['watched_at'][:10]
    if t == 'movie':
        name = item['movie']['title']
        year = item['movie'].get('year','')
        print(f'{when} [M] {name} ({year})')
    elif t == 'episode':
        show = item['show']['title']
        s = item['episode']['season']
        e = item['episode']['number']
        title = item['episode'].get('title','')
        print(f'{when} [TV] {show} S{s:02d}E{e:02d} - {title}')
"
```

## Token Check Helper

Before making requests, check if token is expired:

```bash
EXPIRES_AT=$(python3 -c "import json; print(json.load(open('$HOME/.config/trakt/config.json')).get('expiresAt',0))")
NOW_MS=$(python3 -c "import time; print(int(time.time()*1000))")
if [ "$NOW_MS" -ge "$EXPIRES_AT" ]; then
  echo "Token expired, refreshing..."
  # Run refresh token block above
fi
```
