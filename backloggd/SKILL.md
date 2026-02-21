---
name: backloggd
description: "Backloggd (no oficial): endpoints REST reverse-engineered para consultar y automatizar acciones de colección, backlog, logs y listas."
---

# Backloggd (Reverse-engineered API)

Backloggd no publica API oficial. Este skill documenta endpoints detectados en frontend + pruebas reales.

## Base

- Host: `https://backloggd.com`
- Estilo: mezcla de rutas `/api/...` y rutas funcionales (`/log/`, `/rate/:id`, etc.)
- Auth: sesión web (cookies) + CSRF para mutaciones

## Credenciales/sesión en Keychain

- `backloggd/username`
- `backloggd/csrf_token`
- `backloggd/cookie_header`

Leer:

```bash
USER=$(security find-generic-password -s backloggd -a username -w)
CSRF=$(security find-generic-password -s backloggd -a csrf_token -w)
COOKIE=$(security find-generic-password -s backloggd -a cookie_header -w)
```

Headers reutilizables:

```bash
AUTH_HEADERS=(
  -H "X-CSRF-Token: $CSRF"
  -H "Cookie: $COOKIE"
  -H "X-Requested-With: XMLHttpRequest"
  -H "Accept: application/json, text/javascript, */*; q=0.01"
  -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8"
)
```

---

## 1) Ver backlog ordenado por campos (lo más útil)

Backloggd permite ordenar por URL en el perfil:

Base:

```bash
https://backloggd.com/u/$USER/backlog/<campo>/
https://backloggd.com/u/$USER/backlog/<campo>:asc/
```

Campos detectados:

- `added`
- `release`
- `title`
- `rating`
- `user-rating`
- `popular`
- `trending`
- `time`
- `avg-play-time`
- `avg-finish-time`
- `last_played`
- `shuffle`

### Ejemplo: backlog por fecha de lanzamiento ASC

```bash
USER=$(security find-generic-password -s backloggd -a username -w)

curl -s "https://backloggd.com/u/$USER/backlog/release:asc/" | \
python3 - <<'PY'
import sys,re,html
src=sys.stdin.read()
for title in re.findall(r'<img[^>]*alt="([^"]+)"', src):
    print(html.unescape(title))
PY
```

### Ejemplo: backlog por título ASC

```bash
curl -s "https://backloggd.com/u/$USER/backlog/title:asc/"
```

---

## 2) Endpoints confirmados por acciones

## Lectura / render

- `GET /api/daily-tip/`
- `POST /games/render/` (discovery con filtros serializados)
- `GET /library/get/:game_id`
- `GET /library/render/` (render de entrada librería)
- `GET /genres/fetch/all/`
- `GET /platforms/fetch/all/`

## Logs / estado / rating

- `POST /log/`
  - ejemplo: marcar como wishlist o played
- `PATCH /log/status/`
  - cambia estado (`status_id`)
- `DELETE /unlog/`
- `POST /rate/:game_id`
- `DELETE /delete-rating/`
- `POST /api/user/games/logs` (batch de info de logs)

## Listas / carpetas

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

## Social

- `POST /api/user/reviews/likes` (con `ids`)
- `POST /like/` / `DELETE /unlike/`
- `POST /like/game/` / `DELETE /unlike/game/`
- `POST /comment/`, `POST /comment/edit/`, `DELETE /comment/destroy/`
- `POST /report/`, `PATCH /report/status/`

## Widgets

- `POST /widget/load/`
- `GET /widget/render/`
- `GET /widget/settings/render/`
- `POST /widget/set/`

---

## 3) Ejemplos claros de acciones

### A) Crear lista nueva

```bash
curl -s -X POST "https://backloggd.com/api/new-list/" "${AUTH_HEADERS[@]}"
```

### B) Añadir juego a varias listas (quick add)

```bash
GAME_ID=25076
# form-encoded repetido: list_ids[]=1&list_ids[]=2
curl -s -X POST "https://backloggd.com/api/list/quick/$GAME_ID" \
  "${AUTH_HEADERS[@]}" \
  --data "list_ids[]=1&list_ids[]=2"
```

### C) Marcar juego como played (crea log tipo play)

```bash
GAME_ID=25076
curl -s -X POST "https://backloggd.com/log/" \
  "${AUTH_HEADERS[@]}" \
  --data "type=play&game_id=$GAME_ID"
```

### D) Cambiar estado de log

```bash
GAME_ID=25076
STATUS_ID=2
curl -s -X PATCH "https://backloggd.com/log/status/" \
  "${AUTH_HEADERS[@]}" \
  --data "game_id=$GAME_ID&status_id=$STATUS_ID"
```

IDs de estado detectados en `#quick-play-type-modal`:

- `0` → **Completed** — Beat your main objective
- `2` → **Abandoned** — Unfinished and staying that way
- `3` → **Retired** — Finished with a game that lacks an ending
- `4` → **Shelved** — Unfinished but may pick up again later
- `5` → **Played** — Nothing specific

Ejemplo rápido (marcar como Completed):

```bash
curl -s -X PATCH "https://backloggd.com/log/status/" \
  "${AUTH_HEADERS[@]}" \
  --data "game_id=25076&status_id=0"
```

### E) Puntuar juego

```bash
GAME_ID=25076
RATING=4.5
curl -s -X POST "https://backloggd.com/rate/$GAME_ID" \
  "${AUTH_HEADERS[@]}" \
  --data "rating=$RATING"
```

### F) Ver likes del usuario para reviews concretas

```bash
curl -s -X POST "https://backloggd.com/api/user/reviews/likes" \
  "${AUTH_HEADERS[@]}" \
  --data "ids[]=123&ids[]=456"
```

---

## 4) Filtros de backlog (formato URL)

El frontend serializa filtros y los añade a la URL tras el sort.
Ejemplo conceptual:

```text
/u/<user>/backlog/release:asc/<serialized_filters>/
```

Valores detectados en formularios:

- `filters[genre]`
- `filters[category]`
- `filters[release_platform]`
- `filters[played_platform]`
- `filters[played_on_platform]`
- `filters[game_status]`
- `filters[game_ownership]`
- toggles como `filters[covers]`, `filters[mastered]`, etc.

---

## 5) Troubleshooting

- **401/403**: cookie o CSRF caducados → recapturar desde pestaña logueada.
- **422**: payload inválido o falta header CSRF.
- **200 HTML en vez de JSON**: endpoint no-API o sesión no válida.

---

## 6) Mini CLI (bash)

Existe un mini CLI en:

- Local workspace: `~/clawd/bin/backloggd-mini`
- Repo skills: `backloggd/bin/backloggd-mini`

Comandos implementados:

```bash
backloggd-mini backlog [--sort campo] [--asc|--desc]
backloggd-mini log <game_id> <wishlist|backlog|playing|play>
backloggd-mini set-status <game_id> <status_id>
backloggd-mini rate <game_id> <rating>
backloggd-mini list-add <game_id> <list_ids_csv>
```

Cobertura vs skill:

- ✅ Backlog ordenado por campo
- ✅ Logs: crear, cambiar estado, borrar
- ✅ Ratings: crear y borrar
- ✅ Listas: quick add + create/update/delete + stats
- ✅ Carpetas: create/delete/assign listas
- ✅ Social base: like/unlike review, comment add/edit/delete, report
- ❌ Widgets (load/render/settings/set)

## 7) Seguridad

- Nunca guardar cookies/tokens en texto plano en repo.
- Guardar en Keychain y refrescar cuando caduquen.
- Esta API no es oficial: puede romper sin aviso.
