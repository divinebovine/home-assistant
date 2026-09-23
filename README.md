# Home Assistant Configuration

My personal Home Assistant configuration files and automations.

## Overview

This repository contains automations for:

- Door security and auto-locking
- Battery monitoring for all smart devices
- Smoke alarm notifications  
- Smart irrigation with weather skipping
- Pool maintenance alerts

## Structure

- `automations/` - YAML automation files
- `input_number/` - Helper entities
- `timers/` - Timer configurations

## Automations

### Door Security

Auto-locks doors after 1 hour when closed and unlocked. Sends alerts for doors left open.

### Battery Monitoring

Daily monitoring of battery levels for all smart devices. Alerts when batteries get low.

### Smoke Alarm

Emergency notifications for smoke detection with escalating alerts.

### Irrigation

Smart watering schedule (Tuesdays/Saturdays) with weather-based skipping.

### Pool Maintenance

Monitors pump flow rate and alerts when skimmers may be clogged.

### Garage Freezer Plug Monitor

Alerts when the garage freezer's Zooz ZEN14 goes offline (stopgap for a
GFCI that's been tripping), repeating every 15 minutes until power is
restored, with a confirmation when it comes back online. Each alert
reports which irrigation zone was running or ran most recently.

The ZEN14 never reports on its own, so Z-Wave JS won't notice it lost
power unless something talks to it. A watchdog pings it every 30 seconds
(every 2 minutes while it's offline). A startup check restarts the alert
if Home Assistant restarts while the plug is down. Remove the watchdog
once the GFCI fault is fixed.

Requires `button.garage_outdoor_double_plug_ping` to be enabled. To keep
the pings out of history, add to `configuration.yaml` (not in this repo):

```yaml
recorder:
  exclude:
    entities:
      - button.garage_outdoor_double_plug_ping
      - automation.safety_garage_freezer_plug_ping_watchdog
```

## Usage

Update entity names in the automation files to match your devices before using.

Notifications are sent to `notify.mobile_app_pixel_8_pro` - update this to match your device.
