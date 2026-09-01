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
    if (reason && reason !== "") root.gpuModel = "Unavailable"
  }

  function handleGpuFailure(message) {
    if (message && message !== "") console.warn("k3v.hardware: " + message)
    root.setGpuUnavailable(message)
  }

  function updateGpuState(rawText) {
    var text = String(rawText || "").trim()
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

  function refresh() {
    if (!root.opened) return
    if (!gpuProc.running) gpuProc.running = true
    if (!cpuProc.running) cpuProc.running = true
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
      title: "Processes",
      rows: [
        { label: "Active", value: "—" },
        { label: "Threads", value: "—" },
        { label: "Top", value: "—" }
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
        var msg = String(text || "").trim()
        if (msg !== "") console.warn("k3v.hardware: " + msg)
      }
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) console.warn("k3v.hardware: CPU telemetry process exited with code " + exitCode)
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
        var msg = String(text || "").trim()
        if (msg !== "") root.handleGpuFailure(msg)
      }
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) root.handleGpuFailure("nvidia-smi exited with code " + exitCode)
    }
  }

  Timer {
    interval: 1000
    running: root.opened
    repeat: true
    onTriggered: root.refresh()
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
        }
      }
    }
  }
}
