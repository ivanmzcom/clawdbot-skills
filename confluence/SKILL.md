---
name: confluence
description: "Interact with Confluence Server (confluence.um.es) via REST API. Search pages, read content, create/update pages, manage spaces and attachments."
---

# Confluence Server (Direct API)

Direct curl calls to Confluence Server REST API.

## API Details

- **Base URL:** `https://confluence.um.es/confluence`
- **API:** `/rest/api/`
- **User:** keychain (`security find-generic-password -s confluence -a user_email -w`)
- **Auth:** Bearer token from keychain
- **Confluence Version:** Server/Data Center

## Authentication

```bash
CONF_USER=$(security find-generic-password -s confluence -a user_email -w)
TOKEN=$(security find-generic-password -s confluence -a "$CONF_USER" -w)
AUTH="Authorization: Bearer $TOKEN"
```

All requests use: `curl -s -H "$AUTH" "https://confluence.um.es/confluence/rest/api/..."`

## Common Operations

### Search content (CQL)

```bash
# CQL search (Confluence Query Language)
curl -s -H "$AUTH" "https://confluence.um.es/confluence/rest/api/content/search?cql=type%3Dpage%20AND%20text~%22buscar%20esto%22&limit=10"
```

### Search with expand

```bash
curl -s -H "$AUTH" -G "https://confluence.um.es/confluence/rest/api/content/search" \
  --data-urlencode "cql=type=page AND space=MOVIL AND title~\"UMUapp\"" \
  --data-urlencode "expand=space,version" \
  --data-urlencode "limit=20"
```

### Get page by ID

```bash
curl -s -H "$AUTH" "https://confluence.um.es/confluence/rest/api/content/PAGE_ID?expand=body.storage,version,space"
```

### Get page body (HTML)

```bash
curl -s -H "$AUTH" "https://confluence.um.es/confluence/rest/api/content/PAGE_ID?expand=body.storage" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(d['body']['storage']['value'])
"
```

### Get page by title and space

```bash
curl -s -H "$AUTH" -G "https://confluence.um.es/confluence/rest/api/content" \
  --data-urlencode "title=Page Title" \
  --data-urlencode "spaceKey=SPACE" \
  --data-urlencode "expand=body.storage,version"
```

### Create page

```bash
curl -s -H "$AUTH" -X POST "https://confluence.um.es/confluence/rest/api/content" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "page",
    "title": "Título de la página",
    "space": {"key": "SPACE"},
    "body": {
      "storage": {
        "value": "<p>Contenido HTML de la página</p>",
        "representation": "storage"
      }
    }
  }'
```

### Create child page

```bash
curl -s -H "$AUTH" -X POST "https://confluence.um.es/confluence/rest/api/content" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "page",
    "title": "Página hija",
    "space": {"key": "SPACE"},
    "ancestors": [{"id": PARENT_PAGE_ID}],
    "body": {
      "storage": {
        "value": "<p>Contenido</p>",
        "representation": "storage"
      }
    }
  }'
```

### Update page

```bash
# Must include current version number + 1
curl -s -H "$AUTH" -X PUT "https://confluence.um.es/confluence/rest/api/content/PAGE_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "version": {"number": CURRENT_VERSION_PLUS_1},
    "title": "Título actualizado",
    "type": "page",
    "body": {
      "storage": {
        "value": "<p>Nuevo contenido</p>",
        "representation": "storage"
      }
    }
  }'
```

### Delete page

```bash
curl -s -H "$AUTH" -X DELETE "https://confluence.um.es/confluence/rest/api/content/PAGE_ID"
```

### Add comment to page

```bash
curl -s -H "$AUTH" -X POST "https://confluence.um.es/confluence/rest/api/content" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "comment",
    "container": {"id": "PAGE_ID", "type": "page"},
    "body": {
      "storage": {
        "value": "<p>Texto del comentario</p>",
        "representation": "storage"
      }
    }
  }'
```

## Spaces

### List all spaces

```bash
curl -s -H "$AUTH" "https://confluence.um.es/confluence/rest/api/space?limit=50"
```

### Get space details

```bash
curl -s -H "$AUTH" "https://confluence.um.es/confluence/rest/api/space/SPACE_KEY?expand=description.plain,homepage"
```

### Get space pages (root level)

```bash
curl -s -H "$AUTH" "https://confluence.um.es/confluence/rest/api/space/SPACE_KEY/content/page?depth=root&limit=50"
```

### Get child pages

```bash
curl -s -H "$AUTH" "https://confluence.um.es/confluence/rest/api/content/PAGE_ID/child/page?limit=50"
```

## Attachments

### List attachments on a page

```bash
curl -s -H "$AUTH" "https://confluence.um.es/confluence/rest/api/content/PAGE_ID/child/attachment"
```

### Upload attachment

```bash
curl -s -H "$AUTH" -X POST "https://confluence.um.es/confluence/rest/api/content/PAGE_ID/child/attachment" \
  -H "X-Atlassian-Token: nocheck" \
  -F "file=@/path/to/file.pdf"
```

## Labels

### Get page labels

```bash
curl -s -H "$AUTH" "https://confluence.um.es/confluence/rest/api/content/PAGE_ID/label"
```

### Add label

```bash
curl -s -H "$AUTH" -X POST "https://confluence.um.es/confluence/rest/api/content/PAGE_ID/label" \
  -H "Content-Type: application/json" \
  -d '[{"prefix": "global", "name": "mi-etiqueta"}]'
```

## User Info

### Current user

```bash
curl -s -H "$AUTH" "https://confluence.um.es/confluence/rest/api/user/current"
```

## Useful CQL Queries

- **My recent pages:** `contributor=currentUser() AND type=page ORDER BY lastModified DESC`
- **Search in space:** `type=page AND space=SPACEKEY AND text~"término"`
- **By label:** `type=page AND label="mi-etiqueta"`
- **Recently modified:** `type=page AND space=SPACEKEY AND lastModified>=now("-7d")`
- **By title:** `type=page AND title="Título exacto"`
- **Title contains:** `type=page AND title~"parcial"`

## Tips

- Confluence Server uses `/rest/api/` (not `/wiki/rest/api/` like Cloud)
- Base path includes `/confluence` — full URL: `https://confluence.um.es/confluence/rest/api/`
- Page updates require `version.number` = current version + 1
- Body format is `storage` (Confluence XHTML storage format)
- Use `expand` parameter to include additional data (body.storage, version, space, children, etc.)
- CQL (Confluence Query Language) is similar to JQL but for content
- Attachments require `X-Atlassian-Token: nocheck` header
