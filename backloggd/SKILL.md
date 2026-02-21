---
name: backloggd
description: "Gestiona Backloggd usando el CLI local backloggd-mini (sin llamadas API directas en la skill)."
---

# Backloggd (CLI-only)

Esta skill usa **solo CLI**.
No documenta ni recomienda llamadas HTTP directas.

## CLI

- Script local: `~/clawd/bin/backloggd-mini`
- En repo de skills: `backloggd/bin/backloggd-mini`

## Requisitos

- Keychain con servicio `backloggd`:
  - `username`
  - `csrf_token`
  - `cookie_header`

## Uso

```bash
backloggd-mini help
```

### Backlog ordenado

```bash
backloggd-mini backlog --sort release --asc
backloggd-mini backlog --sort title --asc
backloggd-mini backlog --sort added --desc
```

Campos de sort típicos:
`release, title, added, rating, user-rating, popular, trending, time, avg-play-time, avg-finish-time, last_played, shuffle`

### Logs y estado

```bash
backloggd-mini log <game_id> <wishlist|backlog|playing|play>
backloggd-mini unlog <game_id>
backloggd-mini set-status <game_id> <status_id>
```

Status IDs:
- `0` Completed
- `2` Abandoned
- `3` Retired
- `4` Shelved
- `5` Played

### Ratings

```bash
backloggd-mini rate <game_id> <rating>
backloggd-mini unrate <game_id>
```

### Listas

```bash
backloggd-mini list-add <game_id> <list_ids_csv>
backloggd-mini list-create <name>
backloggd-mini list-update <list_id> <name>
backloggd-mini list-delete <list_id>
backloggd-mini list-stats <list_id>
```

### Carpetas

```bash
backloggd-mini folder-create <name>
backloggd-mini folder-delete <folder_id>
backloggd-mini folder-assign <folder_id> <list_ids_csv>
```

### Social

```bash
backloggd-mini like-review <review_id>
backloggd-mini unlike-review <review_id>
backloggd-mini comment-add <review_id> <texto>
backloggd-mini comment-edit <comment_id> <texto>
backloggd-mini comment-delete <comment_id>
backloggd-mini report <review_id> <reason>
```

## Nota

Si una acción falla por sesión caducada, vuelve a capturar `csrf_token` y `cookie_header` en keychain.
