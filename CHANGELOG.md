# Changelog

## Milestone 9 bugfix — Performance graph layout
- Corrected graph component and metric-wrapper implicit sizing so each Performance graph reserves its header, spacing, and full 72px drawing area without overlap
- Constrained long current-value labels to the existing card width while preserving right alignment and the existing 0.9.0 version

## Milestone 9 — Performance graphs and short-term history
- Added a reusable `HistoryGraph.qml` component using theme-driven QtQuick Shapes sparklines for CPU, GPU, memory, network RX/TX, and CPU/GPU temperature history
- Added one in-memory 1-second history sampler with bounded 61-sample buffers, fixed 0–100% utilization scaling, 20–100°C temperature scaling, and recent-window auto-scaling for network rates
- Reset history on panel open and clear it on close; invalid or unavailable telemetry is skipped rather than recorded as zero
- Kept graph data sourced exclusively from existing CPU, GPU, memory, and network properties without duplicate collectors, persistent storage, daemons, or background services
- Updated the plugin version to `0.9.0`

## Milestone 8 — systemd service telemetry
- Added read-only system and user systemd manager health, service counts, running states, and failed-service visibility
- Added defensive plain-output discovery of important services while preserving system/user scope and excluding environment, credentials, and ExecStart data
- Added live PipeWire/WirePlumber audio summary and actual Hyprland user-service display status where available
- Added compact Systemd and detailed Important Services and Failed Services sections while preserving the live Network, Audio, and Display rows
- Kept service collection lifecycle-bound to the open panel with immediate refresh and approximately 5-second polling, guarded against overlapping collectors
- Added no service controls or other mutating systemd operations; all telemetry remains read-only
- Updated the plugin version to `0.8.0`

## Milestone 7 — Network telemetry
- Added read-only default-route detection, interface typing, and current connection state using `ip`, `/sys/class/net`, and local Linux interfaces without mutating network settings
- Reported active IPv4, default gateway, DNS resolvers, and current link speed for the primary interface while intentionally excluding MAC addresses, BSSIDs, saved secrets, and private network credentials
- Added live receive/send rate calculations from `rx_bytes` and `tx_bytes` deltas, plus cumulative received/sent totals in binary units for the active interface
- Added a dedicated network metadata collector and a separate network stats collector to avoid repeated expensive metadata discovery and to keep rate polling independent of connection discovery
- Added a `Network` section and an `Adapters` list that show the physical/default interface and the non-loopback adapter inventory while excluding loopback, Docker, bridge, and container interfaces from the user-facing network list
- Kept the network polling lifecycle tied to the panel open/close state: metadata refreshes at ~5s while open, stats sampling at ~1s while open, and no continued polling after close
- Updated the plugin version to `0.7.0`

## Milestone 6 — Hardware and PCI telemetry
- Added a dedicated read-only hardware collector that gathers motherboard DMI metadata, BIOS/firmware details, kernel and architecture info, and a single-shot hardware inventory pass when the panel opens
- Reported motherboard vendor/model and BIOS version from unprivileged `/sys/class/dmi/id` data while intentionally excluding serial numbers, UUIDs, and other unique identifiers from the UI and JSON payload
- Detects UEFI vs. Legacy BIOS mode from `/sys/firmware/efi` and shares kernel release plus machine architecture directly from native interfaces without invoking `sudo` or `dmidecode`
- Added PCI/PCIe endpoint inventory using `lspci -D -nn -mm -k`, plus sysfs link-speed and width inspection from `/sys/bus/pci/devices/<BDF>` where available
- Listed meaningful endpoint devices, filtered out host bridges and dummy bridge entries, and surfaced kernel-bound drivers alongside address, class, vendor/model, and link widths/speeds
- Added a compact PCI devices section below Hardware with a filtered user-visible count and honest handling for missing PCI link data or absent PSU telemetry
- Kept the hardware collector to one-shot lifecycle behavior on panel open, with no repeated polling while the panel remains open and no hardware collector left running after close
- Documented the honest limitation that normal desktop systems may expose no real PSU power telemetry; the panel shows `Not exposed` instead of guessing power supply values
- Updated the plugin version to `0.6.0`

## Milestone 5 — Storage telemetry
- Fixed physical-drive binary capacity formatting so live disk rows report the correct GiB scale instead of an off-by-one unit jump
- Added a dedicated read-only storage collector using `os.statvfs()` for root filesystem usage and `findmnt`/`lsblk` JSON metadata for root identity and physical disk inventory
- Reported root filesystem total, used, available space, filesystem type, source, and usage percentage without altering mounts or partition state
- Discovered and classified physical drives by model, capacity, transport, and rotational status while filtering out zram/loop/partition entries
- Added compact dynamic drive rows to the panel and kept storage polling limited to the open panel lifecycle with a 5s refresh interval
- Kept storage telemetry independent from GPU/CPU/process telemetry and resilient to missing or malformed read-only metadata
- Updated the plugin version to `0.5.0`

## Milestone 4 — Process telemetry
- Added live process count and thread count using `/proc` enumeration and `/proc/[pid]/status` metadata
- Added top five live CPU consumers based on delta-sampled `/proc/[pid]/stat` and `/proc/stat` totals, normalized to total machine CPU capacity
- Displayed resident memory per process via `VmRSS` from `/proc/[pid]/status` and converted it to MiB for compact rows
- Kept process polling constrained to the active panel lifecycle and prevented overlapping collectors
- Added defensive handling for disappearing or unreadable PIDs without crashing the shell
- Updated the plugin version to `0.4.0`

## Milestone 3 — CPU/RAM/temperature telemetry
- Added live CPU model, CPU usage, and CPU temperature telemetry from `/proc/cpuinfo`, `/proc/stat`, and the detected `hwmon` temperature sensor
- Added live memory usage and swap totals from `/proc/meminfo`, using `MemTotal - MemAvailable` for used memory and `SwapTotal - SwapFree` for swap usage
- Kept CPU/RAM/temp polling active only while the panel is open and gracefully fall back to `—` when a source is unavailable
- Updated the plugin version to `0.3.0`

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
