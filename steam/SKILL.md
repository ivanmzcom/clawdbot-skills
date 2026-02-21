---
name: steam
description: "Query Steam via direct API calls. View owned games, recent activity, achievements, player stats, wishlist, and friend list. Use when the user asks about their Steam library, playtime, achievements, or gaming activity."
---

# Steam (Direct API)

Direct curl calls to Steam Web API.

## Credentials

- **API Key:** keychain (`security find-generic-password -s steam -a ivan -w`)
- **Steam ID:** keychain (`security find-generic-password -s steam -a steamid -w`)
- **Profile:** https://steamcommunity.com/id/ivanmzcom

## Setup

```bash
STEAM_KEY=$(security find-generic-password -s steam -a ivan -w)
STEAM_ID=$(security find-generic-password -s steam -a steamid -w)
```

## Recently Played Games

```bash
curl -s "https://api.steampowered.com/IPlayerService/GetRecentlyPlayedGames/v1/?key=$STEAM_KEY&steamid=$STEAM_ID" | python3 -c "
import sys,json
data = json.load(sys.stdin)['response']
for g in data.get('games',[]):
    total_h = g['playtime_forever'] / 60
    recent_h = g.get('playtime_2weeks',0) / 60
    print(f'{g[\"name\"]} — {recent_h:.1f}h (2 semanas) / {total_h:.1f}h total')
"
```

## Owned Games

```bash
curl -s "https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/?key=$STEAM_KEY&steamid=$STEAM_ID&include_appinfo=1&include_played_free_games=1" | python3 -c "
import sys,json
data = json.load(sys.stdin)['response']
games = sorted(data.get('games',[]), key=lambda g: -g.get('playtime_forever',0))
print(f'Total: {data[\"game_count\"]} juegos')
for g in games[:20]:
    hours = g['playtime_forever'] / 60
    print(f'{hours:7.1f}h  {g[\"name\"]}')
"
```

## Game Achievements

```bash
APP_ID=123456  # Steam App ID

curl -s "https://api.steampowered.com/ISteamUserStats/GetPlayerAchievements/v1/?key=$STEAM_KEY&steamid=$STEAM_ID&appid=$APP_ID&l=spanish" | python3 -c "
import sys,json
data = json.load(sys.stdin)['playerstats']
achs = data.get('achievements',[])
done = sum(1 for a in achs if a['achieved'])
total = len(achs)
print(f'{data[\"gameName\"]}: {done}/{total} ({done/total*100:.0f}%)')
for a in achs:
    icon = '✅' if a['achieved'] else '❌'
    print(f'  {icon} {a[\"apiname\"]}')
"
```

## Achievement Percentage (global)

```bash
curl -s "https://api.steampowered.com/ISteamUserStats/GetGlobalAchievementPercentagesForApp/v2/?gameid=$APP_ID" | python3 -c "
import sys,json
data = json.load(sys.stdin)['achievementpercentages']['achievements']
for a in sorted(data, key=lambda x: -x['percent'])[:20]:
    print(f'{a[\"percent\"]:5.1f}%  {a[\"name\"]}')
"
```

## Player Summary (profile info)

```bash
curl -s "https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/?key=$STEAM_KEY&steamids=$STEAM_ID" | python3 -c "
import sys,json
p = json.load(sys.stdin)['response']['players'][0]
print(f'Name: {p[\"personaname\"]}')
print(f'Profile: {p[\"profileurl\"]}')
print(f'Status: {[\"Offline\",\"Online\",\"Busy\",\"Away\",\"Snooze\",\"Looking to trade\",\"Looking to play\"][p.get(\"personastate\",0)]}')
if p.get('gameextrainfo'):
    print(f'Playing: {p[\"gameextrainfo\"]}')
"
```

## Friend List

```bash
curl -s "https://api.steampowered.com/ISteamUser/GetFriendList/v1/?key=$STEAM_KEY&steamid=$STEAM_ID" | python3 -c "
import sys,json
friends = json.load(sys.stdin)['friendslist']['friends']
print(f'{len(friends)} amigos')
# Get names (batch)
ids = ','.join(f['steamid'] for f in friends[:100])
import urllib.request
url = f'https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/?key=$(STEAM_KEY)&steamids={ids}'
"
```

## Wishlist

Steam wishlist is public by default and doesn't need API key:

```bash
curl -s "https://store.steampowered.com/wishlist/profiles/$STEAM_ID/wishlistdata/?p=0" | python3 -c "
import sys,json
data = json.load(sys.stdin)
for appid, info in sorted(data.items(), key=lambda x: x[1].get('priority', 999)):
    print(f'{info[\"name\"]}')
"
```

## Search Game by Name

To find an App ID from a game name:

```bash
curl -s "https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/?key=$STEAM_KEY&steamid=$STEAM_ID&include_appinfo=1" | python3 -c "
import sys,json
data = json.load(sys.stdin)['response']
for g in data.get('games',[]):
    if 'search term' in g['name'].lower():
        print(f'{g[\"appid\"]} — {g[\"name\"]} — {g[\"playtime_forever\"]/60:.1f}h')
"
```

## Game News

```bash
curl -s "https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=$APP_ID&count=5&maxlength=300" | python3 -c "
import sys,json
data = json.load(sys.stdin)['appnews']['newsitems']
for n in data:
    print(f'{n[\"title\"]}')
    print(f'  {n[\"url\"]}')
"
```

## Tips

- **App IDs:** Needed for achievements, news, stats. Find via owned games search or https://store.steampowered.com/app/APPID
- **Rate limits:** Steam API has rate limits (~100k calls/day). Don't loop aggressively.
- **Language:** Add `&l=spanish` to most endpoints for localized content.
- **Private profiles:** Some endpoints require the profile to be public.
