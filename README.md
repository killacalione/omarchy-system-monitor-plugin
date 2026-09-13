# System Monitor for Omarchy

`k3v.hardware` is an Omarchy-native, read-only System Monitor bar widget. It
shows current performance, hardware, network, storage, and systemd state in a
scrollable panel, with short-term in-memory graphs for the most useful live
metrics.

Open one native bar widget to see the health of your whole Linux desktop
without leaving Omarchy.

## Why install it?

- **One glance:** CPU, GPU, memory, storage, network, hardware, and service
  health in one scrollable panel
- **Native experience:** theme-aware Omarchy UI with click, keyboard, Escape,
  and shell open/close support
- **Read-only by design:** no background daemon, service controls, or settings
  changes
- **Graceful fallbacks:** optional tools and unavailable sensors degrade to
  clear `—` or `Not exposed` values instead of failing the panel
- **Privacy-conscious:** excludes serial numbers, saved network secrets,
  BSSIDs, MAC addresses, and command controls

## Features

- **Performance:** CPU, GPU, memory, network RX/TX, and CPU/GPU temperature
  sparklines covering approximately the latest 60 seconds
- **GPU:** NVIDIA model, utilization, temperature, VRAM, power, fan, clocks,
  and driver
- **CPU:** model, delta-based utilization, and temperature
- **Memory:** used, available, and swap in GiB
- **Processes:** process/thread counts, top CPU consumers, and RSS memory
- **Storage:** root filesystem usage and free space plus physical drive
  inventory with binary units and SSD/HDD/NVMe classification
- **Hardware/PCI:** board, BIOS, firmware mode, kernel, architecture, PCI
  endpoints, drivers, BDF addresses, and link data
- **Network:** primary interface, state, IPv4, gateway, DNS, link speed,
  live rates, cumulative totals, and adapter inventory
- **Services/systemd:** system/user manager health, service counts, failed
  services, important services, audio status, display status, and network
  status

## Screenshots

The panel is designed for a compact Omarchy bar popup. Add a root-level
`preview.png` or `preview.webp` to this repository to show the panel in the
marketplace listing.

## Requirements

Required:

- Omarchy shell with Quickshell and the third-party plugin loader
- Linux `/proc` and `/sys` interfaces
- Python 3 standard library
- `systemd`/`systemctl`
- `util-linux` tools: `findmnt` and `lsblk`
- `ip` from the system networking tools

Required only for corresponding optional telemetry:

- `pciutils`/`lspci` for PCI inventory
- `resolvectl` for per-link DNS discovery, with `/etc/resolv.conf` as fallback
- `nvidia-smi` for NVIDIA GPU telemetry; without it, GPU values degrade to `—`

## Installation

Install directly from the public repository:

```bash
omarchy plugin add https://github.com/killacalione/omarchy-system-monitor-plugin.git --enable
```

The plugin is installed as `k3v.hardware`. To place it in the bar's right
section:

```bash
omarchy plugin enable k3v.hardware --section right
omarchy restart shell
```

For a local checkout, place or clone the directory at
`~/.config/omarchy/plugins/k3v.hardware`, then validate and enable it with the
same commands.

The current shell configuration can also contain the widget ID directly in
the bar's widget list. The plugin ID is `k3v.hardware` and must not be
renamed.

## Update

Update the installed git-managed plugin with:

```bash
omarchy plugin update k3v.hardware
omarchy restart shell
```

Do not overwrite local changes without reviewing them first. For a local
checkout managed outside Omarchy, use `git pull --ff-only` after reviewing
`git status --short --branch`, then run `omarchy plugin validate .`.

## Uninstall / Disable

Disable the widget without removing its files:

```bash
omarchy plugin disable k3v.hardware
omarchy restart shell
```

If the checkout is no longer needed, remove only the plugin directory after
disabling it.

## Data Sources

Telemetry is collected read-only from Linux `/proc` and `/sys`, `nvidia-smi`,
`lspci`, `ip`, `resolvectl` or `/etc/resolv.conf`, `findmnt`, `lsblk`, and
`systemctl`/`systemctl --user`. Graphs consume the existing live properties;
they do not launch additional collectors.

## Polling

- GPU and CPU/memory: approximately every 1 second while open
- Processes: approximately every 2 seconds while open
- Storage: approximately every 5 seconds while open
- Hardware/PCI: one collection when opened
- Network stats: approximately every 1 second while open
- Network metadata: approximately every 5 seconds while open
- Services/systemd: approximately every 5 seconds while open
- Graph history sampler: one in-memory sample per second while open

All collectors and timers stop when the panel closes. Graph history is reset
for the next open.

## Privacy

The plugin intentionally does not collect or display hardware serial numbers,
UUIDs, MAC addresses, BSSIDs, Wi-Fi passwords, service secrets, credentials,
environment variables, or service command lines.

## Permissions

Monitoring is read-only and normal use does not require `sudo`, polkit
changes, or elevated privileges.

## Collector safety

Collectors run through `/usr/bin/python3` with a minimal `PATH` and `LC_ALL`
environment. They do not invoke a login shell, use absolute paths for external
telemetry tools, cap emitted output at 64 KiB per stream, and enforce
subprocess and collector deadlines. A timed-out collector is terminated by
its process group and its telemetry is discarded.

## Limitations

- PSU telemetry is not exposed on this desktop, so the panel reports
  `Not exposed`
- NVIDIA values depend on `nvidia-smi`
- There are no service or process controls
- Graph history is session-local and is not persistent
- SMART monitoring and DIMM inventory are not implemented
- Deep PCI names may be elided in the compact panel
- Other Linux hardware, drivers, and systemd configurations may expose
  different values

## Troubleshooting

Validate the plugin and reload the shell:

```bash
omarchy plugin validate ~/.config/omarchy/plugins/k3v.hardware
omarchy restart shell
omarchy-shell shell ping
omarchy-shell shell toggle k3v.hardware '{}'
```

Inspect recent user-shell messages:

```bash
journalctl --user --since "10 minutes ago" --no-pager
```

Check the two systemd scopes independently:

```bash
systemctl is-system-running
systemctl --user is-system-running
systemctl list-units --type=service --all --no-pager
systemctl --user list-units --type=service --all --no-pager
```

If one optional tool is unavailable, the affected telemetry should show `—`
without preventing the rest of the panel from loading.
