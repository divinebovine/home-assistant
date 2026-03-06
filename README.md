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

## Usage

Update entity names in the automation files to match your devices before using.

Notifications are sent to `notify.mobile_app_pixel_8_pro` - update this to match your device.
