import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "k3v.hardware"
  ipcTarget: "k3v.hardware"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

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

  function safeValue(raw) {
    var value = raw === undefined || raw === null ? "" : String(raw).trim()
    return value === "" ? "—" : value
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

  function refresh() {
    if (root.opened && !gpuProc.running) gpuProc.running = true
  }

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.5)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

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
        { label: "Model", value: "—" },
        { label: "Usage", value: "—" },
        { label: "Temp", value: "—" }
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
        { label: "Used", value: "—" },
        { label: "Available", value: "—" },
        { label: "Swap", value: "—" }
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

  function open() {
    setCenterHoverRevealSuppressed(false)
    root.controller.show()
    Qt.callLater(function() {
      if (root.opened) setCenterHoverRevealSuppressed(true)
    })
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
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function setCenterHoverRevealSuppressed(value) {
    if (root.bar && "centerHoverRevealSuppressed" in root.bar)
      root.bar.centerHoverRevealSuppressed = value
  }

  IpcHandler {
    target: "k3v.hardware"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
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
