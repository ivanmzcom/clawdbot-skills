# Clawdbot Skills

Mis skills personalizadas para [Clawdbot](https://github.com/clawdbot/clawdbot).

## Skills disponibles

| Skill | Descripción |
|-------|-------------|
| [apple-mail](./apple-mail/) | Busca y lee emails de Apple Mail via AppleScript |
| [synology-dsget](./synology-dsget/) | Gestiona Synology NAS via CLI: Download Station, File Station y RSS Feeds |
| [trakt](./trakt/) | Consulta próximos episodios, watchlist e historial de Trakt.tv |

## Instalación

Copia la carpeta de la skill que quieras usar a tu directorio de skills de Clawdbot:

```bash
cp -r trakt /ruta/a/tu/workspace/skills/
```

## Requisitos

Cada skill puede tener sus propios requisitos. Consulta el `SKILL.md` de cada una para más detalles.

### synology-dsget

Requiere el CLI [dsget-cli](https://github.com/ivanmzcom/dsget-cli):

```bash
npm install -g https://github.com/ivanmzcom/dsget-cli/tarball/v1.0.0
```

### trakt

Requiere el CLI [trakt-cli](https://github.com/ivanmzcom/trakt-cli):

```bash
npm install -g https://github.com/ivanmzcom/trakt-cli/tarball/v1.0.0
```

## Licencia

MIT
