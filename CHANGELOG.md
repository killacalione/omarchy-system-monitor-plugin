# Changelog

## Milestone 1 — Shell/plugin foundation
- Initial Omarchy third-party bar widget for System Monitor
- Added valid `manifest.json` for `k3v.hardware`
- Added bar icon and popup panel layout using Omarchy styling conventions
- Added static placeholder sections for Overview, CPU, GPU, Memory, Processes, Storage, Hardware, and Services

## Milestone 2 — NVIDIA GPU telemetry
- Replaced fake GPU placeholder values with live readings from `nvidia-smi`
- Added one-shot refresh on panel open plus a 1s timer while the popup is open
- Kept polling limited to the active panel and stopped it when closed
- Added graceful handling for command failure and unavailable values (`—`)
- Updated plugin version to `0.2.0`

## Fix Milestone 2 — repair System Monitor popup lifecycle
- Matched the plugin to Omarchy's first-party rich bar-widget pattern
- Switched the bar entry point to `Panel.qml` directly
- Removed the wrapper `BarWidget.qml` loader architecture that did not expose the correct lifecycle to the bar
- Kept the NVIDIA GPU polling active only while the panel is open
- Preserved graceful `—` values on command failure
