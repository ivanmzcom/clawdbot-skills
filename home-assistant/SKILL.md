# Home Assistant Skill

Control your Home Assistant smart home using `hass-cli` bash script.

## Installation

1. Install hass-cli:
   ```bash
   brew install homeassistant-cli/tap/homeassistant-cli
   ```

2. Configure your Home Assistant URL and token:
   ```bash
   # Using environment variables (recommended)
   export HASS_SERVER="http://192.168.0.96:8123"
   export HASS_TOKEN="your_long_lived_access_token"
   ```

3. Or create a config file:
   ```bash
   mkdir -p ~/.config/hass-cli
   echo 'server: http://192.168.0.96:8123' > ~/.config/hass-cli/config.yaml
   echo 'token: your_token' >> ~/.config/hass-cli/config.yaml
   ```

## Getting Your Token

1. Go to your Home Assistant: https://ha.ncrd.es
2. Click your **Profile** (bottom left)
3. Scroll to **Long-Lived Access Tokens**
4. Click **Create Token**
5. Copy and use token

## Important: Token Location

**The Home Assistant token is stored in macOS Keychain under the name `homeassistant`.**

To retrieve it:
```bash
security find-generic-password -s "homeassistant" -w
```

This token is used for all Home Assistant API calls from Clawdbot.

## Location

Use `hass-cli` command directly (installed via Homebrew).

## Commands

### General Info

```bash
hass-cli info                          # Basic Home Assistant info
hass-cli system info                   # System details
hass-cli config                        # Configuration
```

### Entities

```bash
hass-cli state list                    # List all entities
hass-cli state get <entity_id>         # Get entity state (e.g., climate.b846baa4)
hass-cli entity info <entity_id>       # Detailed entity info
hass-cli entity list                   # List all entities with details
```

### Devices

```bash
hass-cli device list                   # List all devices
hass-cli device info <device_id>       # Device details
```

### Areas

```bash
hass-cli area list                     # List all areas
hass-cli area info <area_id>           # Area details
```

### Services

```bash
hass-cli service list                  # List all services
hass-cli service call <service>        # Call a service
hass-cli service call <service> --arguments "key=value,key2=value2"
```

### Events

```bash
hass-cli event list                    # List event types
hass-cli event fire <event_type>       # Fire an event
```

## Controlling Devices (Examples)

### Climate/Thermostat

```bash
# Turn on heat to 24°C
hass-cli service call climate.set_temperature --arguments "entity_id=climate.b846baa4,temperature=24,hvac_mode=heat"

# Turn off climate
hass-cli service call climate.set_temperature --arguments "entity_id=climate.b846baa4,hvac_mode=off"

# Set preset mode
hass-cli service call climate.set_preset_mode --arguments "entity_id=climate.b846baa4,preset_mode=eco"
```

### Media Players (TV, Orange TV)

```bash
# Turn on/off
hass-cli service call media_player.turn_on --arguments "entity_id=media_player.lg_webos_tv_ur78006lk"
hass-cli service call media_player.turn_off --arguments "entity_id=media_player.orange_tv"

# Set volume (0.0 to 1.0)
hass-cli service call media_player.volume_set --arguments "entity_id=media_player.lg_webos_tv_ur78006lk,volume_level=0.5"

# Volume up/down
hass-cli service call media_player.volume_up --arguments "entity_id=media_player.lg_webos_tv_ur78006lk"
hass-cli service call media_player.volume_down --arguments "entity_id=media_player.lg_webos_tv_ur78006lk"
```

### Switches

```bash
# Turn on
hass-cli service call switch.turn_on --arguments "entity_id=switch.b846baa4_panel_luminoso"

# Turn off
hass-cli service call switch.turn_off --arguments "entity_id=switch.b846baa4_panel_luminoso"
```

### Lights

```bash
# Turn on
hass-cli service call light.turn_on --arguments "entity_id=light.living_room"

# Turn off
hass-cli service call light.turn_off --arguments "entity_id=light.living_room"

# Set brightness (0-255)
hass-cli service call light.turn_on --arguments "entity_id=light.living_room,brightness=128"

# Set color (if supported)
hass-cli service call light.turn_on --arguments "entity_id=light.living_room,rgb_color=[255,0,0]"
```

### Covers (Blinds, Gates)

```bash
# Open
hass-cli service call cover.open_cover --arguments "entity_id=cover.garage_door"

# Close
hass-cli service call cover.close_cover --arguments "entity_id=cover.garage_door"

# Stop
hass-cli service call cover.stop_cover --arguments "entity_id=cover.garage_door"

# Set position
hass-cli service call cover.set_cover_position --arguments "entity_id=cover.blind_living_room,position=50"
```

### Vacuum

```bash
# Start cleaning
hass-cli service call vacuum.start --arguments "entity_id=vacuum.roborock"

# Return to dock
hass-cli service call vacuum.return_to_home --arguments "entity_id=vacuum.roborock"

# Stop
hass-cli service call vacuum.stop --arguments "entity_id=vacuum.roborock"
```

### Automation

```bash
# Trigger automation
hass-cli service call automation.trigger --arguments "entity_id=automation.morning_routine"

# Turn on/off automation
hass-cli service call automation.turn_on --arguments "entity_id=automation.morning_routine"
hass-cli service call automation.turn_off --arguments "entity_id=automation.morning_routine"
```

### Scene

```bash
# Activate scene
hass-cli service call scene.turn_on --arguments "entity_id=scene.movie_time"
```

## Usage Examples

- "Show my Home Assistant devices"
- "Turn on living room lights"
- "Set thermostat to 24 degrees"
- "Turn off TV"
- "What's temperature in living room?"
- "Start vacuum cleaner"
- "Close garage door"
- "Activate movie mode scene"
- "List all climate devices"
- "Show device battery levels"

## Iván's Devices (Example)

| Entity ID | Type | Location |
|-----------|------|----------|
| climate.b846baa4 | Climate | Planta baja |
| climate.b8907ffd | Climate | Planta arriba |
| switch.b846baa4_* | Switches | Planta baja |
| switch.b8907ffd_* | Switches | - |
| media_player.orange_tv | Media Player | Salón |
| media_player.lg_webos_tv_ur78006lk | Media Player | Salón |
| sensor.iphone_de_ivan_* | Sensors | iPhone |
| sensor.ipad_pro_11_m5_* | Sensors | iPad Pro |
| binary_sensor.garaje_movimiento | Sensor | Garaje |
| binary_sensor.garaje_persona | Sensor | Garaje |
| camera.garaje_fluent | Camera | Garaje |
| binary_sensor.puerta_garaje_coche | Sensor | Garaje |
| sensor.puerta_garaje_coche_bateria | Sensor | Garaje |

## Notes

- **Token location:** Keychain under name `homeassistant`
- Use `hass-cli --insecure` if you have SSL certificate issues
- Entity IDs are case-insensitive but must match exactly
- Temperature is in Celsius
- Brightness is 0-255
- Volume level is 0.0 to 1.0
- Position is 0-100%
- Some services require additional arguments (check HA docs)
