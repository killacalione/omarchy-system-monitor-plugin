# System Monitor for Omarchy

`k3v.hardware` is an Omarchy-native, read-only System Monitor bar widget. It
shows current performance, hardware, network, storage, and systemd state in a
scrollable panel, with short-term in-memory graphs for the most useful live
metrics.

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

The panel is designed for a compact Omarchy bar popup. Screenshots are kept
outside this repository so the plugin remains source-only.

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

The supported local plugin directory is:

```text
~/.config/omarchy/plugins/k3v.hardware
```

To install from a local checkout, place or clone the directory there, then
enable it in the bar:

```bash
omarchy plugin validate ~/.config/omarchy/plugins/k3v.hardware
omarchy plugin enable k3v.hardware --section right
omarchy restart shell
```

The current shell configuration can also contain the widget ID directly in
the bar's widget list. The plugin ID is `k3v.hardware` and must not be
renamed.

## Update

This checkout is local-only and has no assumed remote URL. After configuring a
remote yourself, update safely with:

```bash
cd ~/.config/omarchy/plugins/k3v.hardware
git status --short --branch
git pull --ff-only
omarchy plugin validate .
omarchy restart shell
```

Do not overwrite local changes without reviewing them first.

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
