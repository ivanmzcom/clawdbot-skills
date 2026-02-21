---
name: backloggd
description: "Reverse-engineered Backloggd REST endpoints (authenticated and public) using browser session + direct HTTP calls. Use for watchlist/log/list interactions and lightweight automation."
---

# Backloggd (Reverse-engineered REST API)

Ingeniería inversa sobre `backloggd.com` desde sesión activa en navegador.

## Base

- **Web:** `https://backloggd.com`
- **API style:** endpoints REST-ish bajo `/api/...` + endpoints auxiliares (`/log/`, `/rate/`, etc.)
- **Auth real:** cookie de sesión del navegador + CSRF token en requests mutantes

## Secretos en Keychain (local)

- `security find-generic-password -s backloggd -a username -w`
- `security find-generic-password -s backloggd -a csrf_token -w`
- `security find-generic-password -s backloggd -a cookie_header -w`

> Nota: `cookie_header`/`csrf_token` pueden caducar. Si fallan (401/403/422), recaptúralos desde navegador.

## Headers base para llamadas autenticadas

```bash
CSRF=$(security find-generic-password -s backloggd -a csrf_token -w)
COOKIE=$(security find-generic-password -s backloggd -a cookie_header -w)

AUTH_HEADERS=(
  -H "X-CSRF-Token: $CSRF"
  -H "Cookie: $COOKIE"
  -H "X-Requested-With: XMLHttpRequest"
  -H "Accept: application/json, text/javascript, */*; q=0.01"
  -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8"
)
```

## Endpoints confirmados (bundle JS + runtime)

### Públicos / lectura

- `GET /api/daily-tip/` ✅ devuelve JSON
- `POST /games/render/` (filtros)
- `GET /genres/fetch/all/`
- `GET /platforms/fetch/all/`
- `GET /library/get/`
- `GET /library/render/`
- `GET /stats/`, `GET /stats/game/`

### Usuario / logs / ratings

- `POST /log/` (alta de estado, p.ej. wishlist)
- `PATCH /log/status/`
- `DELETE /unlog/`
- `POST /rate/`
- `DELETE /delete-rating/`
- `POST /api/user/games/logs` (batch info de logs)
- `PATCH /user/log/resolve-merge`

### Likes / reviews / social

- `POST /api/user/reviews/likes` (`ids[]`)
- `POST /like/` / `DELETE /unlike/`
- `POST /like/game/` / `DELETE /unlike/game/`
- `POST /report/` / `PATCH /report/status/`
- `POST /comment/`, `POST /comment/edit/`, `DELETE /comment/destroy/`

### Listas / carpetas

- `POST /api/new-list/`
- `POST /api/list/`
- `PUT /api/list/`
- `PATCH /api/list/`
- `DELETE /api/list/`
- `POST /api/list/quick/:game_id`
- `PUT /api/list/stats/`
- `POST /api/list/folder`
- `DELETE /api/list/folder`
- `PUT /api/list/folder/lists/`

### Widgets

- `POST /widget/load/`
- `GET /widget/render/`
- `GET /widget/settings/render/`
- `POST /widget/set/`

## Ejemplos rápidos

### Tip diario

```bash
curl -s "https://backloggd.com/api/daily-tip/"
```

### Crear lista nueva

```bash
curl -s "https://backloggd.com/api/new-list/" \
  -X POST \
  "${AUTH_HEADERS[@]}"
```

### Añadir juego a listas rápidas

```bash
GAME_ID=12345
LIST_IDS="1,2"

curl -s "https://backloggd.com/api/list/quick/$GAME_ID" \
  -X POST \
  "${AUTH_HEADERS[@]}" \
  --data "list_ids[]=${LIST_IDS//,/&list_ids[]=}"
```

### Cambiar estado de log

```bash
GAME_ID=12345
STATUS_ID=2

curl -s "https://backloggd.com/log/status/" \
  -X PATCH \
  "${AUTH_HEADERS[@]}" \
  --data "game_id=$GAME_ID&status_id=$STATUS_ID"
```

## Método de reverse engineering usado

1. Sesión ya iniciada en navegador.
2. Inspección de recursos y JS bundle (`application-*.js`).
3. Extracción de `type + url` en llamadas `ajax`.
4. Verificación de endpoints con `fetch/curl`.
5. Guardado de datos sensibles mínimos en Keychain.

## Limitaciones

- API no oficial → puede romper sin aviso.
- Parte del auth depende de cookie de sesión web (no token API estable).
- Algunos endpoints requieren payload exacto/contexto UI para funcionar.
