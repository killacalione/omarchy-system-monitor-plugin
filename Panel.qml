import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "k3v.hardware"
  ipcTarget: "k3v.hardware"

  property bool gpuAvailable: false
  property string gpuModel: "—"
  property string gpuTemperature: "—"
  property string gpuUtilization: "—"
  property string gpuVramUsed: "—"
  property string gpuVramTotal: "—"
  property string gpuPowerDraw: "—"
  property string gpuPowerLimit: "—"
  property string gpuFanSpeed: "—"
  property string gpuGraphicsClock: "—"
  property string gpuMemoryClock: "—"
  property string gpuDriverVersion: "—"

  property string cpuModel: "—"
  property string cpuUsage: "—"
  property string cpuTemperature: "—"
  property string memoryUsed: "—"
  property string memoryAvailable: "—"
  property string memorySwap: "—"

  property string processCount: "—"
  property string threadCount: "—"
  property bool processAvailable: false
  property var processRows: []
  property string processError: ""
  property bool processCollectorBusy: false

  property real cpuTotalLast: NaN
  property real cpuIdleLast: NaN

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.5)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  function safeValue(raw) {
    var value = raw === undefined || raw === null ? "" : String(raw).trim()
    return value === "" ? "—" : value
  }

  function formatGiB(kib) {
    if (kib === undefined || kib === null || isNaN(Number(kib))) return "—"
    var value = Number(kib) / (1024 * 1024)
    return value.toFixed(1)
  }

  function setGpuUnavailable(reason) {
    root.gpuAvailable = false
    root.gpuModel = "—"
    root.gpuTemperature = "—"
    root.gpuUtilization = "—"
    root.gpuVramUsed = "—"
    root.gpuVramTotal = "—"
    root.gpuPowerDraw = "—"
    root.gpuPowerLimit = "—"
    root.gpuFanSpeed = "—"
    root.gpuGraphicsClock = "—"
    root.gpuMemoryClock = "—"
    root.gpuDriverVersion = "—"
    if (!root.opened) return
    if (reason && reason !== "") root.gpuModel = "Unavailable"
  }

  function handleGpuFailure(message) {
    if (!root.opened) return
    if (message && message !== "") console.warn("k3v.hardware: " + message)
    root.setGpuUnavailable(message)
  }

  function updateGpuState(rawText) {
    var text = String(rawText || "").trim()
    if (!root.opened) return
    if (!text) {
      root.handleGpuFailure("nvidia-smi returned no output")
      return
    }

    var values = text.split(",")
    if (values.length < 11) {
      root.handleGpuFailure("nvidia-smi output was malformed")
      return
    }

    root.gpuAvailable = true
    root.gpuModel = root.safeValue(values[0])
    root.gpuTemperature = root.safeValue(values[1]) + "°C"
    root.gpuUtilization = root.safeValue(values[2]) + "%"
    root.gpuVramUsed = root.safeValue(values[3]) + " MiB"
    root.gpuVramTotal = root.safeValue(values[4]) + " MiB"
    root.gpuPowerDraw = root.safeValue(values[5]) + " W"
    root.gpuPowerLimit = root.safeValue(values[6]) + " W"
    root.gpuFanSpeed = root.safeValue(values[7]) + "%"
    root.gpuGraphicsClock = root.safeValue(values[8]) + " MHz"
    root.gpuMemoryClock = root.safeValue(values[9]) + " MHz"
    root.gpuDriverVersion = root.safeValue(values[10])
  }

  function updateCpuState(rawText) {
    var text = String(rawText || "").trim()
    if (!root.opened) return
    if (!text) {
      root.cpuModel = "—"
      root.cpuUsage = "—"
      root.cpuTemperature = "—"
      root.memoryUsed = "—"
      root.memoryAvailable = "—"
      root.memorySwap = "—"
      console.warn("k3v.hardware: CPU telemetry returned no output")
      return
    }

    var values = text.split(",")
    if (values.length < 8) {
      console.warn("k3v.hardware: CPU telemetry output was malformed")
      root.cpuModel = "—"
      root.cpuUsage = "—"
      root.cpuTemperature = "—"
      root.memoryUsed = "—"
      root.memoryAvailable = "—"
      root.memorySwap = "—"
      return
    }

    var model = root.safeValue(values[0])
    var total = Number(values[1])
    var idle = Number(values[2])
    var tempC = Number(values[3])
    var memTotal = Number(values[4])
    var memAvailable = Number(values[5])
    var swapTotal = Number(values[6])
    var swapFree = Number(values[7])

    root.cpuModel = model
    if (!isNaN(tempC)) root.cpuTemperature = Math.round(tempC) + "°C"
    else root.cpuTemperature = "—"

    if (!isNaN(total) && !isNaN(idle) && !isNaN(root.cpuTotalLast) && !isNaN(root.cpuIdleLast)) {
      var totalDelta = total - root.cpuTotalLast
      var idleDelta = idle - root.cpuIdleLast
      if (totalDelta > 0) {
        var pct = 100 * (totalDelta - idleDelta) / totalDelta
        root.cpuUsage = Math.max(0, Math.min(100, pct)).toFixed(0) + "%"
      } else {
        root.cpuUsage = "—"
      }
    } else {
      root.cpuUsage = "—"
    }

    root.cpuTotalLast = total
    root.cpuIdleLast = idle

    var usedKiB = Math.max(0, memTotal - memAvailable)
    var swapUsedKiB = Math.max(0, swapTotal - swapFree)

    root.memoryUsed = root.formatGiB(usedKiB) + " / " + root.formatGiB(memTotal) + " GiB"
    root.memoryAvailable = root.formatGiB(memAvailable) + " GiB"
    if (swapTotal > 0) root.memorySwap = root.formatGiB(swapUsedKiB) + " / " + root.formatGiB(swapTotal) + " GiB"
    else root.memorySwap = "None"
  }

  function setProcessUnavailable(reason) {
    root.processAvailable = false
    root.processCount = "—"
    root.threadCount = "—"
    root.processRows = []
    if (!root.opened) {
      root.processError = ""
      return
    }
    if (reason && reason !== "") {
      if (root.processError !== reason) {
        console.warn("k3v.hardware: " + reason)
        root.processError = reason
      }
    } else {
      root.processError = ""
    }
  }

  function handleProcessFailure(message) {
    root.setProcessUnavailable(message)
  }

  function updateProcessState(rawText) {
    if (!root.opened) {
      root.processAvailable = false
      root.processCount = "—"
      root.threadCount = "—"
      root.processRows = []
      root.processError = ""
      root.processCollectorBusy = false
      return
    }
    var text = String(rawText || "").trim()
    if (!text) {
      root.handleProcessFailure("Process telemetry returned no output")
      return
    }

    var data
    try {
      data = JSON.parse(text)
    } catch (e) {
      root.handleProcessFailure("Process telemetry JSON was malformed")
      return
    }

    if (!data || typeof data !== "object") {
      root.handleProcessFailure("Process telemetry payload was invalid")
      return
    }

    if (typeof data.error === "string" && data.error !== "") {
      root.handleProcessFailure("Process telemetry failed: " + data.error)
      return
    }

    root.processAvailable = true
    root.processError = ""
    root.processCount = typeof data.processCount === "number" ? String(data.processCount) : "—"
    root.threadCount = typeof data.threadCount === "number" ? String(data.threadCount) : "—"

    var rows = []
    if (Array.isArray(data.topCpu)) {
      for (var i = 0; i < data.topCpu.length; ++i) {
        var item = data.topCpu[i]
        if (!item || typeof item !== "object") continue
        var pid = item.pid
        var name = item.name !== undefined && item.name !== null ? String(item.name).trim() : "unknown"
        if (name === "") name = "unknown"
        var cpu = Number(item.cpu)
        var rssMiB = Number(item.rssMiB)
        var label = name
        if (pid !== undefined && pid !== null && String(pid).trim() !== "") label += " [" + String(pid) + "]"
        var cpuText = isNaN(cpu) ? "—" : cpu.toFixed(1) + "%"
        var rssText = isNaN(rssMiB) ? "—" : rssMiB.toFixed(1) + " MiB"
        rows.push(label + "  " + cpuText + " · " + rssText)
      }
    }
    root.processRows = rows
  }

  function refresh() {
    if (!root.opened) return
    if (!gpuProc.running) gpuProc.running = true
    if (!cpuProc.running) cpuProc.running = true
    if (!root.processCollectorBusy && !processProc.running) {
      root.processCollectorBusy = true
      processProc.running = true
    }
  }

  readonly property var sections: [
    {
      title: "Overview",
      rows: [
        { label: "Status", value: root.gpuAvailable ? "Active" : "Unavailable" },
        { label: "GPU", value: root.gpuModel },
        { label: "Driver", value: root.gpuDriverVersion }
      ]
    },
    {
      title: "CPU",
      rows: [
        { label: "Model", value: root.cpuModel },
        { label: "Usage", value: root.cpuUsage },
        { label: "Temp", value: root.cpuTemperature }
      ]
    },
    {
      title: "GPU",
      rows: [
        { label: "Model", value: root.gpuModel },
        { label: "Utilization", value: root.gpuUtilization },
        { label: "Temperature", value: root.gpuTemperature },
        { label: "VRAM used", value: root.gpuVramUsed },
        { label: "VRAM total", value: root.gpuVramTotal },
        { label: "Power draw", value: root.gpuPowerDraw },
        { label: "Power limit", value: root.gpuPowerLimit },
        { label: "Fan speed", value: root.gpuFanSpeed },
        { label: "Graphics clock", value: root.gpuGraphicsClock },
        { label: "Memory clock", value: root.gpuMemoryClock },
        { label: "Driver", value: root.gpuDriverVersion }
      ]
    },
    {
      title: "Memory",
      rows: [
        { label: "Used", value: root.memoryUsed },
        { label: "Available", value: root.memoryAvailable },
        { label: "Swap", value: root.memorySwap }
      ]
    },
    {
      title: "Storage",
      rows: [
        { label: "Root", value: "—" },
        { label: "Free", value: "—" },
        { label: "SSD", value: "—" }
      ]
    },
    {
      title: "Hardware",
      rows: [
        { label: "Board", value: "—" },
        { label: "Kernel", value: "—" },
        { label: "Power", value: "—" }
      ]
    },
    {
      title: "Services",
      rows: [
        { label: "Network", value: "—" },
        { label: "Audio", value: "—" },
        { label: "Display", value: "—" }
      ]
    }
  ]

  onOpenedChanged: {
    if (opened) root.refresh()
    else {
      gpuProc.running = false
      cpuProc.running = false
      processProc.running = false
      root.processCollectorBusy = false
      root.processError = ""
    }
  }

  Process {
    id: processProc
    command: [
      "bash",
      "-lc",
      "python3 - <<'PY'\n" +
      "import json, os, time\n" +
      "exclude = {os.getpid(), os.getppid()}\n" +
      "def read_status(path):\n" +
      "    values = {}\n" +
      "    try:\n" +
      "        with open(path, 'r', encoding='utf-8', errors='replace') as fh:\n" +
      "            for line in fh:\n" +
      "                if ':' not in line:\n" +
      "                    continue\n" +
      "                key, val = line.split(':', 1)\n" +
      "                values[key.strip()] = val.strip()\n" +
      "    except (FileNotFoundError, PermissionError, OSError):\n" +
      "        pass\n" +
      "    return values\n\n" +
      "def sample_processes():\n" +
      "    result = {}\n" +
      "    for name in os.listdir('/proc'):\n" +
      "        if not name.isdigit():\n" +
      "            continue\n" +
      "        pid = int(name)\n" +
      "        if pid in exclude:\n" +
      "            continue\n" +
      "        stat_path = f'/proc/{pid}/stat'\n" +
      "        status_path = f'/proc/{pid}/status'\n" +
      "        try:\n" +
      "            with open(stat_path, 'r', encoding='utf-8', errors='replace') as fh:\n" +
      "                raw = fh.read().strip()\n" +
      "            if not raw or ') ' not in raw:\n" +
      "                continue\n" +
      "            left, rest = raw.split(')', 1)\n" +
      "            fields = rest.strip().split()\n" +
      "            if len(fields) < 18:\n" +
      "                continue\n" +
      "            name_text = left.split('(', 1)[1] if '(' in left else str(pid)\n" +
      "            try:\n" +
      "                with open(f'/proc/{pid}/comm', 'r', encoding='utf-8', errors='replace') as fh:\n" +
      "                    name_text = fh.read().strip()\n" +
      "            except (FileNotFoundError, PermissionError, OSError):\n" +
      "                pass\n" +
      "            status = read_status(status_path)\n" +
      "            threads = 1\n" +
      "            try:\n" +
      "                threads = int(status.get('Threads', '1'))\n" +
      "            except (TypeError, ValueError):\n" +
      "                pass\n" +
      "            rss_kib = 0\n" +
      "            try:\n" +
      "                rss_kib = float(status.get('VmRSS', '0 kB').split()[0])\n" +
      "            except (AttributeError, TypeError, ValueError):\n" +
      "                pass\n" +
      "            result[pid] = {\n" +
      "                'pid': pid,\n" +
      "                'name': name_text or str(pid),\n" +
      "                'cpu_ticks': float(fields[11]) + float(fields[12]),\n" +
      "                'rss_kib': rss_kib,\n" +
      "                'threads': threads,\n" +
      "            }\n" +
      "        except (FileNotFoundError, ProcessLookupError, PermissionError, ValueError, OSError):\n" +
      "            continue\n" +
      "    return result\n\n" +
      "try:\n" +
      "    with open('/proc/stat', 'r', encoding='utf-8', errors='replace') as fh:\n" +
      "        cpu_line = fh.readline().split()\n" +
      "    if len(cpu_line) < 5:\n" +
      "        raise ValueError('bad /proc/stat header')\n" +
      "    total1 = sum(float(v) for v in cpu_line[1:9])\n" +
      "    idle1 = float(cpu_line[4]) + float(cpu_line[5])\n" +
      "    before = sample_processes()\n" +
      "    time.sleep(0.25)\n" +
      "    with open('/proc/stat', 'r', encoding='utf-8', errors='replace') as fh:\n" +
      "        cpu_line = fh.readline().split()\n" +
      "    if len(cpu_line) < 5:\n" +
      "        raise ValueError('bad /proc/stat header')\n" +
      "    total2 = sum(float(v) for v in cpu_line[1:9])\n" +
      "    idle2 = float(cpu_line[4]) + float(cpu_line[5])\n" +
      "    after = sample_processes()\n" +
      "    total_delta = total2 - total1\n" +
      "    top = []\n" +
      "    for pid, info in after.items():\n" +
      "        previous = before.get(pid)\n" +
      "        if previous is None:\n" +
      "            continue\n" +
      "        process_delta = info['cpu_ticks'] - previous['cpu_ticks']\n" +
      "        if process_delta <= 0 or total_delta <= 0:\n" +
      "            continue\n" +
      "        cpu_pct = 100.0 * process_delta / total_delta\n" +
      "        rss_mib = info['rss_kib'] / 1024.0\n" +
      "        top.append({\n" +
      "            'pid': pid,\n" +
      "            'name': info['name'],\n" +
      "            'cpu': round(cpu_pct, 1),\n" +
      "            'rssMiB': round(rss_mib, 1),\n" +
      "            'threads': info['threads'],\n" +
      "        })\n" +
      "    top.sort(key=lambda item: (-item['cpu'], item['pid']))\n" +
      "    payload = {\n" +
      "        'processCount': len(after),\n" +
      "        'threadCount': sum(item['threads'] for item in after.values()),\n" +
      "        'topCpu': top[:5],\n" +
      "    }\n" +
      "    print(json.dumps(payload, separators=(',', ':')))\n" +
      "except Exception as exc:\n" +
      "    print(json.dumps({'processCount': 0, 'threadCount': 0, 'topCpu': [], 'error': str(exc)[:200]}, separators=(',', ':')) )\n" +
      "PY"
    ]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateProcessState(text)
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (!root.opened) return
        var msg = String(text || "").trim()
        if (msg !== "") {
          if (root.processError !== msg) {
            console.warn("k3v.hardware: " + msg)
            root.processError = msg
          }
        }
      }
    }
    onExited: function(exitCode) {
      root.processCollectorBusy = false
      if (!root.opened) {
        root.processError = ""
        return
      }
      if (exitCode !== 0 && root.processError === "") {
        root.setProcessUnavailable("Process telemetry exited with code " + exitCode)
      }
    }
  }

  Process {
    id: cpuProc
    command: [
      "bash",
      "-lc",
      "python3 - <<'PY'\n" +
      "import glob, os, re, sys\n" +
      "model=''\n" +
      "text=''\n" +
      "try:\n" +
      "    text=open('/proc/cpuinfo','r',encoding='utf-8',errors='replace').read()\n" +
      "except Exception:\n" +
      "    text=''\n" +
      "for block in text.split('\\n\\n'):\n" +
      "    for line in block.splitlines():\n" +
      "        if line.startswith('model name'):\n" +
      "            model=line.split(':',1)[1].strip(); break\n" +
      "    if model:\n" +
      "        break\n" +
      "values=open('/proc/stat','r',encoding='utf-8',errors='replace').read().splitlines()[0].split(); total=0; idle=0\n" +
      "if len(values) >= 6:\n" +
      "    total=sum(float(v) for v in values[1:9]); idle=float(values[4])+float(values[5])\n" +
      "mem_total=mem_available=swap_total=swap_free=0\n" +
      "for line in open('/proc/meminfo','r',encoding='utf-8',errors='replace').read().splitlines():\n" +
      "    if ':' not in line:\n" +
      "        continue\n" +
      "    key, value = line.split(':', 1)\n" +
      "    value = value.strip()\n" +
      "    if not value:\n" +
      "        continue\n" +
      "    value_number = value.split()[0]\n" +
      "    if key == 'MemTotal':\n" +
      "        mem_total=float(value_number)\n" +
      "    elif key == 'MemAvailable':\n" +
      "        mem_available=float(value_number)\n" +
      "    elif key == 'SwapTotal':\n" +
      "        swap_total=float(value_number)\n" +
      "    elif key == 'SwapFree':\n" +
      "        swap_free=float(value_number)\n" +
      "candidates=[]\n" +
      "for hwmon in sorted(glob.glob('/sys/class/hwmon/hwmon*')):\n" +
      "    name=open(os.path.join(hwmon,'name'),'r',encoding='utf-8',errors='replace').read().strip().lower(); labels={}\n" +
      "    for label_path in glob.glob(os.path.join(hwmon,'temp*_label')):\n" +
      "        m=re.search(r'temp(\\d+)_label', os.path.basename(label_path))\n" +
      "        if m:\n" +
      "            labels[m.group(1)] = open(label_path,'r',encoding='utf-8',errors='replace').read().strip().lower()\n" +
      "    for input_path in glob.glob(os.path.join(hwmon,'temp*_input')):\n" +
      "        m=re.search(r'temp(\\d+)_input', os.path.basename(input_path))\n" +
      "        if not m:\n" +
      "            continue\n" +
      "        label=labels.get(m.group(1), '').lower()\n" +
      "        try:\n" +
      "            temp_value=float(open(input_path,'r',encoding='utf-8',errors='replace').read().strip())/1000.0\n" +
      "        except ValueError:\n" +
      "            continue\n" +
      "        score=0\n" +
      "        if name=='k10temp':\n" +
      "            score += 10\n" +
      "        elif 'coretemp' in name:\n" +
      "            score += 9\n" +
      "        elif 'cpu' in name:\n" +
      "            score += 5\n" +
      "        if 'tdie' in label:\n" +
      "            score += 12\n" +
      "        elif 'tctl' in label:\n" +
      "            score += 10\n" +
      "        elif 'package' in label:\n" +
      "            score += 8\n" +
      "        elif 'cpu' in label:\n" +
      "            score += 7\n" +
      "        elif 'core' in label:\n" +
      "            score += 5\n" +
      "        candidates.append((score, temp_value, label))\n" +
      "temp_c=None\n" +
      "if candidates:\n" +
      "    temp_c=max(candidates, key=lambda item:item[0])[1]\n" +
      "else:\n" +
      "    sys.stderr.write('k3v.hardware: no usable CPU temperature sensor found under /sys/class/hwmon (searched Tdie/Tctl/k10temp/coretemp candidates)\\n')\n" +
      "print(','.join([str(model), str(total), str(idle), 'nan' if temp_c is None else str(temp_c), str(mem_total), str(mem_available), str(swap_total), str(swap_free)]))\n" +
      "PY"
    ]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateCpuState(text)
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (!root.opened) return
        var msg = String(text || "").trim()
        if (msg !== "") console.warn("k3v.hardware: " + msg)
      }
    }
    onExited: function(exitCode) {
      if (root.opened && exitCode !== 0) console.warn("k3v.hardware: CPU telemetry process exited with code " + exitCode)
    }
  }

  Process {
    id: gpuProc
    command: [
      "nvidia-smi",
      "--query-gpu=name,temperature.gpu,utilization.gpu,memory.used,memory.total,power.draw,power.limit,fan.speed,clocks.gr,clocks.mem,driver_version",
      "--format=csv,noheader,nounits"
    ]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateGpuState(text)
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (!root.opened) return
        var msg = String(text || "").trim()
        if (msg !== "") root.handleGpuFailure(msg)
      }
    }
    onExited: function(exitCode) {
      if (root.opened && exitCode !== 0) root.handleGpuFailure("nvidia-smi exited with code " + exitCode)
    }
  }

  Timer {
    interval: 1000
    running: root.opened
    repeat: true
    onTriggered: root.refresh()
  }

  Timer {
    interval: 2000
    running: root.opened
    repeat: true
    onTriggered: {
      if (!processProc.running) processProc.running = true
    }
  }

  function setCenterHoverRevealSuppressed(value) {
    if (root.bar && "centerHoverRevealSuppressed" in root.bar)
      root.bar.centerHoverRevealSuppressed = value
  }

  function open() {
    setCenterHoverRevealSuppressed(false)
    root.controller.show()
    Qt.callLater(function() {
      if (root.opened) setCenterHoverRevealSuppressed(true)
    })
    root.refresh()
  }

  function close() {
    setCenterHoverRevealSuppressed(false)
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root, direction)
    return false
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    tooltipText: "System Monitor"
    onPressed: function(b) {
      if (b === Qt.RightButton) root.close()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(420))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(560))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Flickable {
        id: panelFlick
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true

        Column {
          id: column
          width: panelFlick.width
          spacing: Style.space(12)
          topPadding: Style.space(8)
          bottomPadding: Style.space(8)

          BorderSurface {
            width: parent.width
            color: Util.alpha(Color.popups.background, 0.94)
            borderSpec: Border.flat(Util.alpha(root.foreground, 0.18), 1)
            radius: Style.cornerRadius
            implicitHeight: titleRow.implicitHeight + Style.space(18)

            Row {
              id: titleRow
              width: parent.width
              anchors.verticalCenter: parent.verticalCenter
              leftPadding: Style.space(12)
              rightPadding: Style.space(12)
              spacing: Style.space(8)

              Text {
                text: "System Monitor"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.subtitle
                font.bold: true
              }

              Text {
                text: root.gpuAvailable ? "Live GPU" : "Unavailable"
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                anchors.verticalCenter: parent.verticalCenter
              }
            }
          }

          Repeater {
            model: root.sections

            delegate: BorderSurface {
              width: panelFlick.width
              color: Util.alpha(Color.popups.background, 0.94)
              borderSpec: Border.flat(Util.alpha(root.foreground, 0.12), 1)
              radius: Style.cornerRadius
              implicitHeight: sectionColumn.implicitHeight + Style.space(16)

              Column {
                id: sectionColumn
                width: parent.width
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Style.space(10)
                spacing: Style.space(8)

                PanelSectionHeader {
                  width: parent.width
                  text: modelData.title.toUpperCase()
                  foreground: root.foreground
                  fontFamily: root.fontFamily
                }

                Repeater {
                  model: modelData.rows

                  delegate: Item {
                    width: sectionColumn.width
                    implicitHeight: Math.max(labelText.implicitHeight, valueText.implicitHeight)

                    Text {
                      id: labelText
                      anchors.left: parent.left
                      text: modelData.label
                      color: root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.body
                    }

                    Text {
                      id: valueText
                      anchors.right: parent.right
                      text: modelData.value
                      color: root.dim
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.bodySmall
                    }
                  }
                }
              }
            }
          }

          BorderSurface {
            width: panelFlick.width
            color: Util.alpha(Color.popups.background, 0.94)
            borderSpec: Border.flat(Util.alpha(root.foreground, 0.12), 1)
            radius: Style.cornerRadius
            implicitHeight: processSectionColumn.implicitHeight + Style.space(16)

            Column {
              id: processSectionColumn
              width: parent.width
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: parent.top
              anchors.margins: Style.space(10)
              spacing: Style.space(8)

              PanelSectionHeader {
                width: parent.width
                text: "PROCESSES"
                foreground: root.foreground
                fontFamily: root.fontFamily
              }

              Item {
                width: processSectionColumn.width
                implicitHeight: Math.max(processCountText.implicitHeight, processCountValue.implicitHeight)

                Text {
                  id: processCountText
                  anchors.left: parent.left
                  text: "Processes"
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                }

                Text {
                  id: processCountValue
                  anchors.right: parent.right
                  text: root.processAvailable ? root.processCount : "—"
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                }
              }

              Item {
                width: processSectionColumn.width
                implicitHeight: Math.max(processThreadsText.implicitHeight, processThreadsValue.implicitHeight)

                Text {
                  id: processThreadsText
                  anchors.left: parent.left
                  text: "Threads"
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                }

                Text {
                  id: processThreadsValue
                  anchors.right: parent.right
                  text: root.processAvailable ? root.threadCount : "—"
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                }
              }

              Text {
                width: processSectionColumn.width
                text: "TOP CPU"
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                visible: root.processAvailable || root.processRows.length > 0
              }

              Repeater {
                model: root.processRows.length > 0 ? root.processRows : ["—"]
                delegate: Text {
                  width: processSectionColumn.width
                  text: modelData
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                }
              }
            }
          }
        }
      }
    }
  }
}
