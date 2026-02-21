---
name: synology-dsget
description: "Manage Synology NAS via direct API calls: Download Station (add/pause/resume/delete torrents, magnets, URLs), File Station (browse folders, create folders, file info), and RSS Feeds (list, view items, download). Use when managing downloads on a Synology NAS or browsing NAS files."
---

# Synology NAS Management (Direct API)

Direct curl calls to Synology DSM API. No CLI dependency needed.

## Connection Details

- **Host:** `nas.ncrd.es`
- **Port:** 443 (HTTPS)
- **User:** ivan
- **Password:** keychain (`security find-generic-password -s synology -a ivan -w`)
- **Base URL:** `https://nas.ncrd.es:443`
- **Entry point:** `/webapi/entry.cgi`

## Authentication

### Login (get SID)

```bash
NAS="https://nas.ncrd.es:443"
NAS_PASS=$(security find-generic-password -s synology -a ivan -w)

SID=$(curl -sk "$NAS/webapi/entry.cgi?api=SYNO.API.Auth&method=login&version=7&account=ivan&passwd=$NAS_PASS&session=DownloadStation&format=sid" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['sid'])")
echo $SID
```

### Logout

```bash
curl -sk "$NAS/webapi/auth.cgi?api=SYNO.API.Auth&method=logout&version=1&session=DownloadStation&_sid=$SID"
```

## Download Station - Tasks

### List all tasks

```bash
curl -sk "$NAS/webapi/DownloadStation/task.cgi?api=SYNO.DownloadStation.Task&method=list&version=1&additional=detail,transfer&_sid=$SID" | python3 -c "
import sys,json
data = json.load(sys.stdin)
if data['success']:
    for t in data['data']['tasks']:
        title = t['title']
        status = t['status']
        transfer = t.get('additional',{}).get('transfer',{})
        dl = transfer.get('speed_download',0)
        ul = transfer.get('speed_upload',0)
        sz = t.get('size',0)
        done = transfer.get('size_downloaded',0)
        pct = (done/sz*100) if sz > 0 else 0
        print(f'{status:12s} {pct:5.1f}% ↓{dl/1024:.0f}KB/s ↑{ul/1024:.0f}KB/s {title}')
"
```

### Filter by status

```bash
# downloading | seeding | paused | finished | waiting | error
curl -sk "$NAS/webapi/DownloadStation/task.cgi?api=SYNO.DownloadStation.Task&method=list&version=1&additional=transfer&_sid=$SID" | python3 -c "
import sys,json
data = json.load(sys.stdin)
if data['success']:
    for t in data['data']['tasks']:
        if t['status'] == 'downloading':
            print(f'{t[\"title\"]}')
"
```

### Add magnet/URL

```bash
curl -sk -X POST "$NAS/webapi/DownloadStation/task.cgi" \
  -d "api=SYNO.DownloadStation.Task&method=create&version=1&uri=MAGNET_OR_URL&destination=video/tvshows/Series Name&_sid=$SID"
```

### Add torrent file

⚠️ **Torrent files MUST have `.torrent` extension** or Download Station will reject them.

When receiving torrent files from Telegram (UUID names without extension):
```bash
# Check what's inside
strings "/path/to/uuid-file" | head -3

# Rename and upload
cp "/path/to/uuid-file" "/tmp/filename.torrent"
```

Upload via DownloadStation2 API (multipart):

```bash
TORRENT_FILE="/tmp/filename.torrent"
DEST="video/tvshows/Series Name"

curl -sk -X POST "$NAS/webapi/entry.cgi?_sid=$SID" \
  -F "api=SYNO.DownloadStation2.Task" \
  -F "version=2" \
  -F "method=create" \
  -F 'type="file"' \
  -F 'file=["torrent"]' \
  -F "create_list=false" \
  -F "destination=\"$DEST\"" \
  -F "torrent=@$TORRENT_FILE;type=application/x-bittorrent"
```

### Pause / Resume / Delete tasks

```bash
# Pause (comma-separated IDs for multiple)
curl -sk "$NAS/webapi/DownloadStation/task.cgi?api=SYNO.DownloadStation.Task&method=pause&version=1&id=TASK_ID&_sid=$SID"

# Resume
curl -sk "$NAS/webapi/DownloadStation/task.cgi?api=SYNO.DownloadStation.Task&method=resume&version=1&id=TASK_ID&_sid=$SID"

# Delete
curl -sk "$NAS/webapi/DownloadStation/task.cgi?api=SYNO.DownloadStation.Task&method=delete&version=1&id=TASK_ID&_sid=$SID"
```

### Task info

```bash
curl -sk "$NAS/webapi/DownloadStation/task.cgi?api=SYNO.DownloadStation.Task&method=getinfo&version=1&id=TASK_ID&additional=detail,transfer,file,tracker&_sid=$SID"
```

## File Station

### List shared folders

```bash
curl -sk "$NAS/webapi/entry.cgi?api=SYNO.FileStation.List&method=list_share&version=2&_sid=$SID" | python3 -c "
import sys,json
data = json.load(sys.stdin)
if data['success']:
    for s in data['data']['shares']:
        print(s['path'], s['name'])
"
```

### List files in folder

```bash
curl -sk "$NAS/webapi/entry.cgi?api=SYNO.FileStation.List&method=list&version=2&folder_path=/video/tvshows&additional=size&_sid=$SID" | python3 -c "
import sys,json
data = json.load(sys.stdin)
if data['success']:
    for f in data['data']['files']:
        ftype = 'd' if f['isdir'] else 'f'
        sz = f.get('additional',{}).get('size',0)
        print(f'[{ftype}] {f[\"name\"]:50s} {sz/1024/1024:>8.1f}MB')
"
```

### Create folder

```bash
curl -sk "$NAS/webapi/entry.cgi?api=SYNO.FileStation.CreateFolder&method=create&version=2&folder_path=/video/tvshows&name=Series Name (Year)&_sid=$SID"
```

### File/folder info

```bash
curl -sk "$NAS/webapi/entry.cgi?api=SYNO.FileStation.List&method=getinfo&version=2&path=/video/tvshows/folder&additional=size,time&_sid=$SID"
```

## RSS Feeds

### List feeds

```bash
curl -sk "$NAS/webapi/DownloadStation/RSSsite.cgi?api=SYNO.DownloadStation.RSS.Site&method=list&version=1&_sid=$SID"
```

### Feed items

```bash
curl -sk "$NAS/webapi/DownloadStation/RSSfeed.cgi?api=SYNO.DownloadStation.RSS.Feed&method=list&version=1&id=FEED_ID&_sid=$SID"
```

## Session Reuse

To avoid logging in every time, store the SID and reuse it. It expires after ~24h or on logout.

```bash
# Store SID for the session
export SYNO_SID="$SID"
```

## Destination Guidelines

When adding a torrent, determine the correct destination folder:

⚠️ **Paths must NOT start with `/` when used as destination**

| Content Type | Destination | 
|--------------|-------------|
| **Movie** | `video/movies` |
| **Complete series** | `video/tvshows/<Series Name>` |
| **Season pack** | `video/tvshows/<Series Name>` |
| **Single episode** | `video/tvshows/<Series Name>/Season X` |

### Finding the right folder

**⚠️ Always check existing folder structure before adding episodes!**

1. List tvshows to find the series folder
2. If found, check its structure (season folders vs loose files)
3. Match the existing pattern
4. If new series: create folder first, then add
