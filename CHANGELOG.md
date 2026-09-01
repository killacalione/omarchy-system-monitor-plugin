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
