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

  property string storageRoot: "—"
  property string storageFree: "—"
  property string storageUsage: "—"
  property string storageFilesystem: "—"
  property string storageSource: "—"
  property bool storageAvailable: false
  property var storageDrives: []
  property var driveRows: ["—"]
  property string storageError: ""
  property bool storageCollectorBusy: false
  property var storageRows: [
    { label: "Root", value: root.storageRoot },
    { label: "Free", value: root.storageFree },
    { label: "Usage", value: root.storageUsage },
    { label: "Filesystem", value: root.storageFilesystem },
    { label: "Source", value: root.storageSource }
  ]

  property string hardwareBoard: "—"
  property string hardwareBios: "—"
  property string hardwareFirmware: "—"
  property string hardwareKernel: "—"
  property string hardwareArch: "—"
  property string hardwarePower: "Not exposed"
  property int hardwarePciCount: 0
  property var hardwarePci: []
  property var pciRows: []
  property string hardwareError: ""
  property bool hardwareCollectorBusy: false

  property string networkConnection: "—"
  property string networkInterface: "—"
  property string networkState: "—"
  property string networkIPv4: "—"
  property string networkGateway: "—"
  property string networkLink: "—"
  property string networkReceiving: "—"
  property string networkSending: "—"
  property string networkReceivedTotal: "—"
  property string networkSentTotal: "—"
  property string networkDNS: "—"
  property string networkServiceSummary: "Disconnected"
  property var networkRows: [
    { label: "Connection", value: root.networkConnection },
    { label: "Interface", value: root.networkInterface },
    { label: "State", value: root.networkState },
    { label: "IPv4", value: root.networkIPv4 },
    { label: "Gateway", value: root.networkGateway },
    { label: "Link", value: root.networkLink },
    { label: "Receiving", value: root.networkReceiving },
    { label: "Sending", value: root.networkSending },
    { label: "Received", value: root.networkReceivedTotal },
    { label: "Sent", value: root.networkSentTotal },
    { label: "DNS", value: root.networkDNS }
  ]
  property var networkAdapters: []
  property var networkAdapterRows: []
  property string networkError: ""
  property bool networkMetaBusy: false
  property bool networkStatsBusy: false
  property real networkPrevRx: NaN
  property real networkPrevTx: NaN
  property real networkPrevTime: NaN

  property string systemdSystemState: "—"
  property string systemdUserState: "—"
  property int systemdSystemLoaded: 0
  property int systemdSystemActive: 0
  property int systemdSystemRunning: 0
  property int systemdSystemFailed: 0
  property int systemdUserLoaded: 0
  property int systemdUserActive: 0
  property int systemdUserRunning: 0
  property int systemdUserFailed: 0
  property string systemdAudioSummary: "—"
  property string systemdDisplaySummary: "—"
  property string systemdSummary: "—"
  property var systemdRows: []
  property var systemdImportantRows: []
  property var systemdFailedRows: []
  property string systemdError: ""
  property bool serviceCollectorBusy: false

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

  function storageUnitFor(bytes) {
    var value = Number(bytes)
    if (isNaN(value) || value < 0) return "GiB"
    return value >= 1024 * 1024 * 1024 * 1024 ? "TiB" : "GiB"
  }

  function formatStorageValue(bytes, unit) {
    var value = Number(bytes)
    if (isNaN(value) || value < 0) return "—"
    var target = unit === "TiB" ? 1024 * 1024 * 1024 * 1024 : 1024 * 1024 * 1024
    var scaled = value / target
    return scaled.toFixed(1)
  }

  function formatBinaryBytes(bytes) {
    if (bytes === undefined || bytes === null || isNaN(Number(bytes))) return "—"
    var value = Number(bytes)
    if (value < 0) value = 0
    var units = ["B", "KiB", "MiB", "GiB", "TiB", "PiB"]
    var unitIndex = 0
    var scaled = value
    while (scaled >= 1024 && unitIndex < units.length - 1) {
      scaled /= 1024
      unitIndex += 1
    }
    return scaled.toFixed(1) + " " + units[unitIndex]
  }

  function formatStorageSize(bytes) {
    return root.formatBinaryBytes(bytes)
  }

  function formatRate(bytesPerSecond) {
    var value = Number(bytesPerSecond)
    if (isNaN(value) || value < 0) return "—"
    var units = ["B/s", "KiB/s", "MiB/s", "GiB/s"]
    var unitIndex = 0
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024
      unitIndex += 1
    }
    if (unitIndex === 0) return Math.max(0, value).toFixed(0) + " " + units[unitIndex]
    return Math.max(0, value).toFixed(1) + " " + units[unitIndex]
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

  function setStorageUnavailable(reason) {
    root.storageAvailable = false
    root.storageRoot = "—"
    root.storageFree = "—"
    root.storageUsage = "—"
    root.storageFilesystem = "—"
    root.storageSource = "—"
    root.storageRows = [
      { label: "Root", value: root.storageRoot },
      { label: "Free", value: root.storageFree },
      { label: "Usage", value: root.storageUsage },
      { label: "Filesystem", value: root.storageFilesystem },
      { label: "Source", value: root.storageSource }
    ]
    root.storageDrives = []
    root.driveRows = ["—"]
    if (!root.opened) {
      root.storageError = ""
      return
    }
    if (reason && reason !== "") {
      if (root.storageError !== reason) {
        console.warn("k3v.hardware: " + reason)
        root.storageError = reason
      }
    } else {
      root.storageError = ""
    }
  }

  function handleStorageFailure(message) {
    root.setStorageUnavailable(message)
  }

  function setHardwareUnavailable(reason) {
    root.hardwareBoard = "—"
    root.hardwareBios = "—"
    root.hardwareFirmware = "—"
    root.hardwareKernel = "—"
    root.hardwareArch = "—"
    root.hardwarePower = "Not exposed"
    root.hardwarePciCount = 0
    root.hardwarePci = []
    root.pciRows = []
    if (!root.opened) {
      root.hardwareError = ""
      root.hardwareCollectorBusy = false
      return
    }
    if (reason && reason !== "") {
      if (root.hardwareError !== reason) {
        console.warn("k3v.hardware: " + reason)
        root.hardwareError = reason
      }
    } else {
      root.hardwareError = ""
    }
  }

  function handleHardwareFailure(message) {
    root.setHardwareUnavailable(message)
  }

  function updateHardwareState(rawText) {
    if (!root.opened) {
      root.hardwareCollectorBusy = false
      return
    }
    var text = String(rawText || "").trim()
    if (!text) {
      root.handleHardwareFailure("Hardware telemetry returned no output")
      return
    }

    var data
    try {
      data = JSON.parse(text)
    } catch (e) {
      root.handleHardwareFailure("Hardware telemetry JSON was malformed")
      return
    }

    if (!data || typeof data !== "object") {
      root.handleHardwareFailure("Hardware telemetry payload was invalid")
      return
    }

    if (typeof data.error === "string" && data.error !== "") {
      root.handleHardwareFailure("Hardware telemetry failed: " + data.error)
      return
    }

    var system = data.system && typeof data.system === "object" ? data.system : {}
    var board = root.safeValue(system.board)
    if (board === "—") {
      var vendor = root.safeValue(system.boardVendor)
      var name = root.safeValue(system.boardName)
      var version = root.safeValue(system.boardVersion)
      if (vendor !== "—" || name !== "—") {
        board = [vendor, name].filter(function(value) { return value !== "—" && value !== ""; }).join(" ").trim() || "—"
      }
      if (board === "—" && version !== "—") board = version
    }
    root.hardwareBoard = board !== "—" ? board : "—"
    root.hardwareBios = root.safeValue(system.biosVersion)
    root.hardwareFirmware = root.safeValue(system.firmwareMode)
    root.hardwareKernel = root.safeValue(system.kernelRelease)
    root.hardwareArch = root.safeValue(system.architecture)
    root.hardwarePower = system.powerTelemetry === true ? "Available" : "Not exposed"

    var pciItems = Array.isArray(data.filtered) ? data.filtered : (Array.isArray(data.pci) ? data.pci : [])
    root.hardwarePci = pciItems
    root.hardwarePciCount = pciItems.length
    var rows = []
    for (var i = 0; i < pciItems.length; ++i) {
      var item = pciItems[i]
      if (!item || typeof item !== "object") continue
      var name = root.safeValue(item.name)
      if (name === "—") name = root.safeValue(item.device)
      var detailParts = []
      if (item.address && String(item.address).trim() !== "") detailParts.push(String(item.address).trim())
      if (item.driver && String(item.driver).trim() !== "") detailParts.push(String(item.driver).trim())
      if (item.currentLinkWidth && Number(item.currentLinkWidth) > 0) {
        detailParts.push("x" + String(Number(item.currentLinkWidth)))
      }
      if (item.currentLinkSpeed && String(item.currentLinkSpeed).trim() !== "") {
        detailParts.push(String(item.currentLinkSpeed).trim())
      }
      if (detailParts.length === 0) detailParts.push("PCI device")
      rows.push({ title: name, detail: detailParts.join(" · ") })
    }
    root.pciRows = rows
    root.hardwareError = ""
  }

  function updateNetworkState(rawText) {
    if (!root.opened) {
      root.networkConnection = "—"
      root.networkInterface = "—"
      root.networkState = "—"
      root.networkIPv4 = "—"
      root.networkGateway = "—"
      root.networkLink = "—"
      root.networkReceiving = "—"
      root.networkSending = "—"
      root.networkReceivedTotal = "—"
      root.networkSentTotal = "—"
      root.networkDNS = "—"
      root.networkServiceSummary = "Disconnected"
      root.networkRows = [
        { label: "Connection", value: root.networkConnection },
        { label: "Interface", value: root.networkInterface },
        { label: "State", value: root.networkState },
        { label: "IPv4", value: root.networkIPv4 },
        { label: "Gateway", value: root.networkGateway },
        { label: "Link", value: root.networkLink },
        { label: "Receiving", value: root.networkReceiving },
        { label: "Sending", value: root.networkSending },
        { label: "Received", value: root.networkReceivedTotal },
        { label: "Sent", value: root.networkSentTotal },
        { label: "DNS", value: root.networkDNS }
      ]
      root.networkAdapters = []
      root.networkAdapterRows = []
      root.networkError = ""
      root.networkMetaBusy = false
      return
    }

    var text = String(rawText || "").trim()
    if (!text) {
      root.networkError = "Network metadata returned no output"
      console.warn("k3v.hardware: " + root.networkError)
      return
    }

    var data
    try {
      data = JSON.parse(text)
    } catch (e) {
      root.networkError = "Network metadata JSON was malformed"
      console.warn("k3v.hardware: " + root.networkError)
      return
    }

    if (!data || typeof data !== "object") {
      root.networkError = "Network metadata payload was invalid"
      console.warn("k3v.hardware: " + root.networkError)
      return
    }

    if (typeof data.error === "string" && data.error !== "") {
      root.networkError = "Network metadata failed: " + data.error
      console.warn("k3v.hardware: " + root.networkError)
      return
    }

    root.networkError = ""
    root.networkConnection = root.safeValue(data.connection)
    root.networkInterface = root.safeValue(data.interface)
    root.networkState = root.safeValue(data.state)
    root.networkIPv4 = root.safeValue(data.ipv4)
    root.networkGateway = root.safeValue(data.gateway)
    root.networkLink = root.safeValue(data.link)
    root.networkDNS = root.safeValue(data.dns)
    root.networkServiceSummary = root.safeValue(data.summary)
    if (root.networkServiceSummary === "—") root.networkServiceSummary = root.networkState === "Connected" ? (root.networkConnection !== "—" ? root.networkConnection : "Connected") : "Disconnected"

    var adapters = Array.isArray(data.adapters) ? data.adapters : []
    root.networkAdapters = adapters
    var adapterRows = []
    for (var i = 0; i < adapters.length; ++i) {
      var item = adapters[i]
      if (!item || typeof item !== "object") continue
      var name = root.safeValue(item.name)
      var typeText = root.safeValue(item.type)
      var stateText = root.safeValue(item.state)
      var label = name !== "—" ? name : "Unknown"
      if (typeText !== "—") label += " · " + typeText
      if (stateText !== "—") label += " · " + stateText
      adapterRows.push(label)
    }
    root.networkAdapterRows = adapterRows.length > 0 ? adapterRows : ["—"]

    root.networkRows = [
      { label: "Connection", value: root.networkConnection },
      { label: "Interface", value: root.networkInterface },
      { label: "State", value: root.networkState },
      { label: "IPv4", value: root.networkIPv4 },
      { label: "Gateway", value: root.networkGateway },
      { label: "Link", value: root.networkLink },
      { label: "Receiving", value: root.networkReceiving },
      { label: "Sending", value: root.networkSending },
      { label: "Received", value: root.networkReceivedTotal },
      { label: "Sent", value: root.networkSentTotal },
      { label: "DNS", value: root.networkDNS }
    ]
  }

  function updateNetworkStats(rawText) {
    var text = String(rawText || "").trim()
    if (!text) {
      if (root.opened) {
        root.networkReceiving = "—"
        root.networkSending = "—"
      }
      return
    }

    var data
    try {
      data = JSON.parse(text)
    } catch (e) {
      if (root.opened) {
        root.networkReceiving = "—"
        root.networkSending = "—"
      }
      return
    }

    if (!data || typeof data !== "object") return
    var rxBytes = Number(data.rxBytes)
    var txBytes = Number(data.txBytes)
    if (isNaN(rxBytes) || isNaN(txBytes)) return

    var currentTime = Date.now()
    var previousTs = Number(root.networkPrevTime)
    var previousRx = Number(root.networkPrevRx)
    var previousTx = Number(root.networkPrevTx)
    var deltaSeconds = 0
    if (!isNaN(previousTs) && previousTs > 0 && currentTime > previousTs) {
      deltaSeconds = Math.max(0.25, (currentTime - previousTs) / 1000.0)
    }

    if (!isNaN(previousRx) && !isNaN(previousTx) && !isNaN(previousTs) && previousTs > 0 && currentTime > previousTs) {
      var rxDelta = Math.max(0, rxBytes - previousRx)
      var txDelta = Math.max(0, txBytes - previousTx)
      if (rxBytes < previousRx || txBytes < previousTx) {
        rxDelta = 0
        txDelta = 0
      }
      root.networkReceiving = root.formatRate(rxDelta / deltaSeconds)
      root.networkSending = root.formatRate(txDelta / deltaSeconds)
    } else {
      root.networkReceiving = "—"
      root.networkSending = "—"
    }

    root.networkPrevRx = rxBytes
    root.networkPrevTx = txBytes
    root.networkPrevTime = currentTime
    root.networkReceivedTotal = root.formatBinaryBytes(rxBytes)
    root.networkSentTotal = root.formatBinaryBytes(txBytes)
    root.networkRows = [
      { label: "Connection", value: root.networkConnection },
      { label: "Interface", value: root.networkInterface },
      { label: "State", value: root.networkState },
      { label: "IPv4", value: root.networkIPv4 },
      { label: "Gateway", value: root.networkGateway },
      { label: "Link", value: root.networkLink },
      { label: "Receiving", value: root.networkReceiving },
      { label: "Sending", value: root.networkSending },
      { label: "Received", value: root.networkReceivedTotal },
      { label: "Sent", value: root.networkSentTotal },
      { label: "DNS", value: root.networkDNS }
    ]
  }

  function updateSystemdState(rawText) {
    var text = String(rawText || "").trim()
    if (!text) {
      root.systemdError = "Service telemetry returned no output"
      return
    }
    var data
    try {
      data = JSON.parse(text)
    } catch (e) {
      root.systemdError = "Service telemetry JSON was malformed"
      return
    }
    if (!data || typeof data !== "object") {
      root.systemdError = "Service telemetry payload was invalid"
      return
    }
    function managerValue(manager, key) {
      var value = manager && manager[key]
      return value === undefined || value === null ? 0 : Number(value)
    }
    function managerState(manager) {
      var value = manager && typeof manager.state === "string" ? manager.state.trim() : ""
      return value === "" ? "—" : value
    }
    function stateLabel(service) {
      var active = String(service.activeState || "")
      var sub = String(service.subState || "")
      if (active === "failed") return "failed"
      if (active === "active" && sub === "running") return "running"
      if (active === "active") return "active"
      return active === "" ? "—" : active
    }
    function displayName(service) {
      var description = String(service.description || "").trim()
      return description !== "" && description !== service.unit ? description : String(service.unit || "Unknown service")
    }
    function scopeLabel(service) {
      return String(service.scope || "unknown") + " · " + stateLabel(service)
    }
    var system = data.systemManager || {}
    var user = data.userManager || {}
    root.systemdSystemState = managerState(system)
    root.systemdUserState = managerState(user)
    root.systemdSystemLoaded = managerValue(system, "loaded")
    root.systemdSystemActive = managerValue(system, "active")
    root.systemdSystemRunning = managerValue(system, "running")
    root.systemdSystemFailed = managerValue(system, "failed")
    root.systemdUserLoaded = managerValue(user, "loaded")
    root.systemdUserActive = managerValue(user, "active")
    root.systemdUserRunning = managerValue(user, "running")
    root.systemdUserFailed = managerValue(user, "failed")
    var importantRows = []
    var important = Array.isArray(data.importantServices) ? data.importantServices : []
    for (var i = 0; i < important.length; ++i) {
      if (important[i] && typeof important[i] === "object")
        importantRows.push({ title: displayName(important[i]), detail: scopeLabel(important[i]) })
    }
    var failedRows = []
    var failed = Array.isArray(data.failedServices) ? data.failedServices : []
    for (var j = 0; j < failed.length; ++j) {
      if (failed[j] && typeof failed[j] === "object")
        failedRows.push({ title: displayName(failed[j]), detail: scopeLabel(failed[j]) })
    }
    root.systemdImportantRows = importantRows
    root.systemdFailedRows = failedRows
    var audio = data.audio || {}
    var pipewire = audio.pipewire
    var wireplumber = audio.wireplumber
    var pulse = audio.pipewirePulse
    var audioPresent = !!pipewire || !!wireplumber || !!pulse
    var audioHealthy = pipewire && pipewire.activeState === "active" && pipewire.subState === "running" &&
      wireplumber && wireplumber.activeState === "active" && wireplumber.subState === "running"
    if (!audioPresent) root.systemdAudioSummary = "—"
    else if (audioHealthy) root.systemdAudioSummary = "PipeWire · Active"
    else root.systemdAudioSummary = "Degraded"
    var display = data.display
    root.systemdDisplaySummary = display && display.activeState === "active" && display.subState === "running" ? "Hyprland · Active" : "—"
    root.systemdSummary = root.systemdSystemState === "—" ? "—" :
      root.systemdSystemState.charAt(0).toUpperCase() + root.systemdSystemState.slice(1) +
      " · " + (root.systemdSystemFailed + root.systemdUserFailed) + " failed"
    root.systemdRows = [
      { label: "System manager", value: root.systemdSystemState },
      { label: "System services", value: root.systemdSystemActive + " active · " + root.systemdSystemFailed + " failed" },
      { label: "User manager", value: root.systemdUserState },
      { label: "User services", value: root.systemdUserActive + " active · " + root.systemdUserFailed + " failed" }
    ]
    root.systemdError = ""
  }

  function updateStorageState(rawText) {
    if (!root.opened) {
      root.storageAvailable = false
      root.storageRoot = "—"
      root.storageFree = "—"
      root.storageUsage = "—"
      root.storageFilesystem = "—"
      root.storageSource = "—"
      root.storageDrives = []
      root.driveRows = ["—"]
      root.storageError = ""
      root.storageCollectorBusy = false
      return
    }

    var text = String(rawText || "").trim()
    if (!text) {
      root.handleStorageFailure("Storage telemetry returned no output")
      return
    }

    var data
    try {
      data = JSON.parse(text)
    } catch (e) {
      root.handleStorageFailure("Storage telemetry JSON was malformed")
      return
    }

    if (!data || typeof data !== "object") {
      root.handleStorageFailure("Storage telemetry payload was invalid")
      return
    }

    if (typeof data.error === "string" && data.error !== "") {
      root.handleStorageFailure("Storage telemetry failed: " + data.error)
      return
    }

    var rootPayload = data.root && typeof data.root === "object" ? data.root : {}
    var totalBytes = Number(rootPayload.totalBytes)
    var availableBytes = Number(rootPayload.availableBytes)
    var usedBytes = Number(rootPayload.usedBytes)
    var usagePercent = Number(rootPayload.usagePercent)

    if (isNaN(totalBytes) || totalBytes <= 0) {
      root.handleStorageFailure("Storage telemetry did not report a valid root size")
      return
    }

    root.storageAvailable = true
    root.storageError = ""
    var unit = root.storageUnitFor(totalBytes)
    root.storageRoot = root.formatStorageValue(usedBytes, unit) + " / " + root.formatStorageValue(totalBytes, unit) + " " + unit
    root.storageFree = root.formatStorageValue(availableBytes, unit) + " " + unit
    root.storageUsage = (!isNaN(usagePercent) ? Math.max(0, Math.min(100, usagePercent)).toFixed(0) : "0") + "%"
    root.storageFilesystem = root.safeValue(rootPayload.filesystem)
    root.storageSource = root.safeValue(rootPayload.source)
    root.storageRows = [
      { label: "Root", value: root.storageRoot },
      { label: "Free", value: root.storageFree },
      { label: "Usage", value: root.storageUsage },
      { label: "Filesystem", value: root.storageFilesystem },
      { label: "Source", value: root.storageSource }
    ]

    var rows = []
    if (Array.isArray(data.drives)) {
      for (var i = 0; i < data.drives.length; ++i) {
        var item = data.drives[i]
        if (!item || typeof item !== "object") continue
        var name = item.name !== undefined && item.name !== null ? String(item.name).trim() : ""
        var model = item.model !== undefined && item.model !== null ? String(item.model).trim() : ""
        var sizeBytes = Number(item.sizeBytes)
        if (name === "" && model === "") continue
        if (isNaN(sizeBytes)) continue
        var label = model !== "" ? model : name
        var typeText = item.type !== undefined && item.type !== null ? String(item.type).trim() : "Disk"
        if (typeText === "") typeText = "Disk"
        rows.push(label + "  " + root.formatStorageSize(sizeBytes) + " · " + typeText)
      }
    }
    root.storageDrives = rows
    root.driveRows = rows.length > 0 ? rows : ["—"]
  }

  function refresh() {
    if (!root.opened) return
    if (!gpuProc.running) gpuProc.running = true
    if (!cpuProc.running) cpuProc.running = true
    if (!root.processCollectorBusy && !processProc.running) {
      root.processCollectorBusy = true
      processProc.running = true
    }
    if (!root.storageCollectorBusy && !storageProc.running) {
      root.storageCollectorBusy = true
      storageProc.running = true
    }
    if (!root.hardwareCollectorBusy && !hardwareProc.running) {
      root.hardwareCollectorBusy = true
      hardwareProc.running = true
    }
    if (!root.networkMetaBusy && !networkMetaProc.running) {
      root.networkMetaBusy = true
      networkMetaProc.running = true
    }
    if (!root.networkStatsBusy && !networkStatsProc.running) {
      root.networkStatsBusy = true
      networkStatsProc.running = true
    }
  }

  function refreshNetworkMetadata() {
    if (!root.opened) return
    if (!root.networkMetaBusy && !networkMetaProc.running) {
      root.networkMetaBusy = true
      networkMetaProc.running = true
    }
  }

  function refreshNetworkStats() {
    if (!root.opened) return
    if (!root.networkStatsBusy && !networkStatsProc.running) {
      root.networkStatsBusy = true
      networkStatsProc.running = true
    }
  }

  function refreshSystemd() {
    if (!root.opened) return
    if (!root.serviceCollectorBusy && !serviceProc.running) {
      root.serviceCollectorBusy = true
      serviceProc.running = true
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
      rows: root.storageRows
    },
    {
      title: "Hardware",
      rows: [
        { label: "Board", value: root.hardwareBoard },
        { label: "BIOS", value: root.hardwareBios },
        { label: "Firmware", value: root.hardwareFirmware },
        { label: "Kernel", value: root.hardwareKernel },
        { label: "Arch", value: root.hardwareArch },
        { label: "PCI devices", value: String(root.hardwarePciCount) },
        { label: "Power", value: root.hardwarePower }
      ]
    },
    {
      title: "Network",
      rows: root.networkRows
    },
    {
      title: "Services",
      rows: [
        { label: "Network", value: root.networkServiceSummary },
        { label: "Audio", value: root.systemdAudioSummary },
        { label: "Display", value: root.systemdDisplaySummary },
        { label: "Systemd", value: root.systemdSummary }
      ]
    },
    {
      title: "Systemd",
      rows: root.systemdRows
    },
    {
      title: "Important Services",
      rows: root.systemdImportantRows.length > 0
        ? root.systemdImportantRows.map(function(item) { return { label: item.title, value: item.detail } })
        : [{ label: "Services", value: "—" }]
    },
    {
      title: "Failed Services",
      rows: root.systemdFailedRows.length > 0
        ? root.systemdFailedRows.map(function(item) { return { label: item.title, value: item.detail } })
        : [{ label: "Failed", value: "None" }]
    }
  ]

  onOpenedChanged: {
    if (opened) {
      root.refresh()
      networkMetaTimer.start()
      networkStatsTimer.start()
    } else {
      gpuProc.running = false
      cpuProc.running = false
      processProc.running = false
      storageProc.running = false
      hardwareProc.running = false
      networkMetaProc.running = false
      networkStatsProc.running = false
      serviceProc.running = false
      networkMetaTimer.stop()
      networkStatsTimer.stop()
      serviceTimer.stop()
      root.processCollectorBusy = false
      root.storageCollectorBusy = false
      root.hardwareCollectorBusy = false
      root.networkMetaBusy = false
      root.networkStatsBusy = false
      root.serviceCollectorBusy = false
      root.networkPrevRx = NaN
      root.networkPrevTx = NaN
      root.networkPrevTime = NaN
      root.processError = ""
      root.storageError = ""
      root.hardwareError = ""
      root.networkError = ""
      root.systemdError = ""
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

  Process {
    id: hardwareProc
    command: [
      "bash",
      "-lc",
      "python3 - <<'PY'\n" +
      "import json, os, re, shlex, subprocess\n" +
      "\n" +
      "def read_text(path):\n" +
      "    try:\n" +
      "        with open(path, 'r', encoding='utf-8', errors='replace') as fh:\n" +
      "            return fh.read().strip()\n" +
      "    except (FileNotFoundError, PermissionError, OSError):\n" +
      "        return ''\n" +
      "\n" +
      "def clean_value(value):\n" +
      "    if value is None:\n" +
      "        return ''\n" +
      "    value = str(value).strip()\n" +
      "    return value.replace('\\x00', '')\n" +
      "\n" +
      "def clean_name(value):\n" +
      "    value = clean_value(value)\n" +
      "    if not value:\n" +
      "        return ''\n" +
      "    no_suffix = re.sub(r'\\s+\\[[^\\]]+\\]$', '', value).strip()\n" +
      "    inner = ''\n" +
      "    if '[' in value and value.endswith(']'):\n" +
      "        inner = value.split('[', 1)[1][:-1].strip()\n" +
      "    if no_suffix and re.search(r'(Controller|Adapter|Ethernet|Wireless|Audio|USB|SATA|NVMe|Network|Compatible|PCIe|HD)', no_suffix, re.I):\n" +
      "        return no_suffix\n" +
      "    if inner and not re.fullmatch(r'[0-9A-Fa-fxX]+', inner):\n" +
      "        return inner\n" +
      "    return no_suffix or value\n" +
      "\n" +
      "def parse_width(value):\n" +
      "    clean = clean_value(value)\n" +
      "    if not clean:\n" +
      "        return None\n" +
      "    try:\n" +
      "        return int(float(clean))\n" +
      "    except ValueError:\n" +
      "        return None\n" +
      "\n" +
      "def dmi_value(name):\n" +
      "    if not os.path.isdir('/sys/class/dmi/id'):\n" +
      "        return ''\n" +
      "    value = read_text(os.path.join('/sys/class/dmi/id', name))\n" +
      "    if value == 'To Be Filled By O.E.M.':\n" +
      "        return ''\n" +
      "    if value and value.lower() == 'unknown':\n" +
      "        return ''\n" +
      "    return value\n" +
      "\n" +
      "dmi_dir = '/sys/class/dmi/id' if os.path.isdir('/sys/class/dmi/id') else '/sys/devices/virtual/dmi/id'\n" +
      "if os.path.isdir(dmi_dir):\n" +
      "    dmi_lookup = {key: read_text(os.path.join(dmi_dir, key)) for key in os.listdir(dmi_dir) if os.path.isfile(os.path.join(dmi_dir, key))}\n" +
      "else:\n" +
      "    dmi_lookup = {}\n" +
      "\n" +
      "for key in ('board_vendor', 'board_name', 'board_version', 'bios_vendor', 'bios_version', 'bios_date', 'sys_vendor', 'product_name', 'product_version'):\n" +
      "    value = clean_value(dmi_lookup.get(key, ''))\n" +
      "    if value in {'', 'To Be Filled By O.E.M.', 'Unknown', 'unknown'}:\n" +
      "        dmi_lookup[key] = ''\n" +
      "    else:\n" +
      "        dmi_lookup[key] = value\n" +
      "\n" +
      "board_vendor = clean_name(dmi_lookup.get('board_vendor') or '')\n" +
      "board_name = clean_name(dmi_lookup.get('board_name') or '')\n" +
      "board_version = clean_name(dmi_lookup.get('board_version') or '')\n" +
      "bios_vendor = clean_name(dmi_lookup.get('bios_vendor') or '')\n" +
      "bios_version = clean_name(dmi_lookup.get('bios_version') or '')\n" +
      "bios_date = clean_name(dmi_lookup.get('bios_date') or '')\n" +
      "board = ''\n" +
      "if board_vendor and board_name and board_vendor.lower() not in board_name.lower():\n" +
      "    board = f'{board_vendor} {board_name}'\n" +
      "elif board_name:\n" +
      "    board = board_name\n" +
      "elif board_vendor:\n" +
      "    board = board_vendor\n" +
      "\n" +
      "power_sources = []\n" +
      "power_dir = '/sys/class/power_supply'\n" +
      "if os.path.isdir(power_dir):\n" +
      "    power_sources = sorted(os.listdir(power_dir))\n" +
      "power_telemetry = any((name.lower().startswith(('ac', 'psu', 'ups', 'adapter')) or ('psu' in name.lower())) for name in power_sources)\n" +
      "\n" +
      "pci_raw = []\n" +
      "try:\n" +
      "    lspci_out = subprocess.check_output(['lspci', '-D', '-nn', '-mm', '-k'], stderr=subprocess.DEVNULL, text=True, env={**os.environ, 'LC_ALL': 'C'})\n" +
      "except Exception as exc:\n" +
      "    lspci_out = ''\n" +
      "\n" +
      "for line in lspci_out.splitlines():\n" +
      "    line = line.strip()\n" +
      "    if not line:\n" +
      "        continue\n" +
      "    if ' ' not in line:\n" +
      "        continue\n" +
      "    address, _, remainder = line.partition(' ')\n" +
      "    if not re.match(r'^[0-9a-fA-F]{4}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}\\.[0-9a-fA-F]$', address):\n" +
      "        continue\n" +
      "    try:\n" +
      "        tokens = shlex.split(remainder)\n" +
      "    except ValueError:\n" +
      "        continue\n" +
      "    if len(tokens) < 3:\n" +
      "        continue\n" +
      "    class_name = re.sub(r'\\s+\\[[0-9A-Fa-f]+\\]$', '', tokens[0]).strip()\n" +
      "    vendor_name = re.sub(r'\\s+\\[[0-9A-Fa-f]+\\]$', '', tokens[1]).strip()\n" +
      "    device_name = re.sub(r'\\s+\\[[0-9A-Fa-f]+\\]$', '', tokens[2]).strip()\n" +
      "    driver = ''\n" +
      "    driver_link = '/sys/bus/pci/devices/' + address + '/driver'\n" +
      "    if os.path.islink(driver_link):\n" +
      "        try:\n" +
      "            driver = os.path.basename(os.readlink(driver_link))\n" +
      "        except OSError:\n" +
      "            driver = ''\n" +
      "    base = '/sys/bus/pci/devices/' + address\n" +
      "    current_speed = read_text(os.path.join(base, 'current_link_speed'))\n" +
      "    max_speed = read_text(os.path.join(base, 'max_link_speed'))\n" +
      "    current_width = parse_width(read_text(os.path.join(base, 'current_link_width')) )\n" +
      "    max_width = parse_width(read_text(os.path.join(base, 'max_link_width')) )\n" +
      "    title = clean_name(device_name) or clean_name(vendor_name) or class_name\n" +
      "    if vendor_name and title and vendor_name.lower() not in title.lower():\n" +
      "        title = vendor_name + ' ' + title\n" +
      "    pci_raw.append({\n" +
      "        'address': address,\n" +
      "        'class': class_name or 'Unknown',\n" +
      "        'vendor': vendor_name,\n" +
      "        'device': device_name,\n" +
      "        'name': title,\n" +
      "        'driver': driver,\n" +
      "        'currentLinkSpeed': current_speed,\n" +
      "        'currentLinkWidth': current_width,\n" +
      "        'maxLinkSpeed': max_speed,\n" +
      "        'maxLinkWidth': max_width\n" +
      "    })\n" +
      "\n" +
      "filtered = []\n" +
      "for item in pci_raw:\n" +
      "    class_name = (item.get('class') or '').lower()\n" +
      "    name_text = (item.get('name') or '').lower()\n" +
      "    if any(token in class_name for token in ['host bridge', 'pci bridge', 'isa bridge', 'smbus', 'lpc bridge', 'root complex', 'non-essential instrumentation', 'data fabric', 'dummy host bridge']):\n" +
      "        continue\n" +
      "    if 'dummy function' in name_text or 'dummy host bridge' in name_text:\n" +
      "        continue\n" +
      "    filtered.append({\n" +
      "        'address': item.get('address'),\n" +
      "        'class': item.get('class'),\n" +
      "        'vendor': item.get('vendor'),\n" +
      "        'device': item.get('device'),\n" +
      "        'name': item.get('name'),\n" +
      "        'driver': item.get('driver'),\n" +
      "        'currentLinkSpeed': item.get('currentLinkSpeed'),\n" +
      "        'currentLinkWidth': item.get('currentLinkWidth'),\n" +
      "        'maxLinkSpeed': item.get('maxLinkSpeed'),\n" +
      "        'maxLinkWidth': item.get('maxLinkWidth')\n" +
      "    })\n" +
      "\n" +
      "payload = {\n" +
      "    'system': {\n" +
      "        'board': board,\n" +
      "        'boardVendor': board_vendor,\n" +
      "        'boardName': board_name,\n" +
      "        'boardVersion': board_version,\n" +
      "        'biosVendor': bios_vendor,\n" +
      "        'biosVersion': bios_version,\n" +
      "        'biosDate': bios_date,\n" +
      "        'firmwareMode': 'UEFI' if os.path.exists('/sys/firmware/efi') else 'Legacy BIOS',\n" +
      "        'kernelRelease': os.uname().release,\n" +
      "        'architecture': os.uname().machine,\n" +
      "        'powerTelemetry': bool(power_telemetry)\n" +
      "    },\n" +
      "    'pci': pci_raw,\n" +
      "    'filtered': filtered\n" +
      "}\n" +
      "print(json.dumps(payload, separators=(',', ':')) )\n" +
      "PY"
    ]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateHardwareState(text)
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (!root.opened) return
        var msg = String(text || "").trim()
        if (msg !== "") {
          if (root.hardwareError !== msg) {
            console.warn("k3v.hardware: " + msg)
            root.hardwareError = msg
          }
        }
      }
    }
    onExited: function(exitCode) {
      root.hardwareCollectorBusy = false
      if (!root.opened) {
        root.hardwareError = ""
        return
      }
      if (exitCode !== 0 && root.hardwareError === "") {
        root.setHardwareUnavailable("Hardware telemetry exited with code " + exitCode)
      }
    }
  }

  Timer {
    id: networkMetaTimer
    interval: 5000
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refreshNetworkMetadata()
  }

  Timer {
    id: networkStatsTimer
    interval: 1000
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refreshNetworkStats()
  }

  Process {
    id: networkMetaProc
    command: [
      "bash",
      "-lc",
      "python3 - <<'PY'\n" +
      "import json, os, re, subprocess\n" +
      "\n" +
      "def read_text(path):\n" +
      "    try:\n" +
      "        with open(path, 'r', encoding='utf-8', errors='replace') as fh:\n" +
      "            return fh.read().strip()\n" +
      "    except (FileNotFoundError, PermissionError, OSError):\n" +
      "        return ''\n" +
      "\n" +
      "def jcall(args):\n" +
      "    try:\n" +
      "        return json.loads(subprocess.check_output(args, stderr=subprocess.DEVNULL, text=True, env={**os.environ, 'LC_ALL': 'C'}))\n" +
      "    except Exception:\n" +
      "        return []\n" +
      "\n" +
      "def dedupe(items):\n" +
      "    seen = set()\n" +
      "    out = []\n" +
      "    for item in items:\n" +
      "        value = str(item).strip()\n" +
      "        if value and value not in seen:\n" +
      "            seen.add(value)\n" +
      "            out.append(value)\n" +
      "    return out\n" +
      "\n" +
      "links = jcall(['ip', '-j', 'link', 'show'])\n" +
      "addresses = jcall(['ip', '-j', 'addr', 'show'])\n" +
      "routes = jcall(['ip', '-j', 'route', 'show', 'default'])\n" +
      "default_iface = ''\n" +
      "default_gateway = ''\n" +
      "for route in routes:\n" +
      "    if route.get('dst') == 'default':\n" +
      "        dev = str(route.get('dev') or '').strip()\n" +
      "        if dev:\n" +
      "            default_iface = dev\n" +
      "            default_gateway = str(route.get('gateway') or '').strip()\n" +
      "            break\n" +
      "\n" +
      "if not default_iface:\n" +
      "    for item in links:\n" +
      "        name = str(item.get('ifname') or '').strip()\n" +
      "        if not name or name == 'lo':\n" +
      "            continue\n" +
      "        operstate = str(item.get('operstate') or '').lower()\n" +
      "        if operstate in {'up', 'unknown'} and not name.startswith(('docker', 'veth', 'br-', 'virbr', 'cni', 'flannel')):\n" +
      "            default_iface = name\n" +
      "            break\n" +
      "\n" +
      "iface = default_iface\n" +
      "iface_type = 'Other'\n" +
      "state = 'Disconnected'\n" +
      "ipv4 = ''\n" +
      "gateway = default_gateway\n" +
      "link_speed = ''\n" +
      "ssid = ''\n" +
      "dns_servers = []\n" +
      "\n" +
      "for info in addresses:\n" +
      "    if str(info.get('ifname') or '').strip() != iface:\n" +
      "        continue\n" +
      "    for addr in info.get('addr_info') or []:\n" +
      "        if str(addr.get('family') or '').lower() == 'inet':\n" +
      "            ipv4 = str(addr.get('local') or '').strip()\n" +
      "            break\n" +
      "\n" +
      "for item in links:\n" +
      "    if str(item.get('ifname') or '').strip() != iface:\n" +
      "        continue\n" +
      "    oper = str(item.get('operstate') or '').strip()\n" +
      "    if oper.lower() in {'up', 'unknown'}:\n" +
      "        state = 'Connected'\n" +
      "    if os.path.exists(f'/sys/class/net/{iface}/wireless'):\n" +
      "        iface_type = 'Wi-Fi'\n" +
      "    elif iface.startswith(('tun', 'tap', 'wg', 'tailscale')):\n" +
      "        iface_type = 'Tunnel'\n" +
      "    elif iface.startswith(('veth', 'docker', 'cni', 'virbr', 'br-')):\n" +
      "        iface_type = 'Virtual'\n" +
      "    elif str(item.get('link_type') or '').lower() in {'ether'}:\n" +
      "        iface_type = 'Ethernet'\n" +
      "    break\n" +
      "\n" +
      "if iface and os.path.exists(f'/sys/class/net/{iface}/speed'):\n" +
      "    try:\n" +
      "        val = int(read_text(f'/sys/class/net/{iface}/speed'))\n" +
      "        if val >= 0:\n" +
      "            link_speed = f'{(val / 1000.0):.1f} Gbps' if val >= 1000 else f'{val} Mbps'\n" +
      "    except Exception:\n" +
      "        pass\n" +
      "\n" +
      "if iface_type == 'Wi-Fi':\n" +
      "    try:\n" +
      "        iw = subprocess.check_output(['iw', 'dev', iface, 'link'], stderr=subprocess.DEVNULL, text=True, env={**os.environ, 'LC_ALL': 'C'})\n" +
      "        match = re.search(r'SSID:(.*)', iw, re.MULTILINE)\n" +
      "        if match:\n" +
      "            ssid = match.group(1).strip()\n" +
      "        bitrate_match = re.search(r'tx bitrate: ([0-9]+)\.?([0-9]*)', iw, re.IGNORECASE)\n" +
      "        if bitrate_match and not link_speed:\n" +
      "            bitrate = float(bitrate_match.group(1)) + (float(bitrate_match.group(2) or 0) / 10.0)\n" +
      "            if bitrate >= 1000:\n" +
      "                link_speed = f'{bitrate / 1000.0:.1f} Gbps'\n" +
      "            else:\n" +
      "                link_speed = f'{bitrate:.0f} Mbps'\n" +
      "    except Exception:\n" +
      "        pass\n" +
      "\n" +
      "dns_servers = []\n" +
      "try:\n" +
      "    resolv = subprocess.check_output(['resolvectl', 'status'], stderr=subprocess.DEVNULL, text=True, env={**os.environ, 'LC_ALL': 'C'})\n" +
      "    current_section = None\n" +
      "    for line in resolv.splitlines():\n" +
      "        section_match = re.match(r'^\\s*Link\\s+\\d+\\s+\\(([^)]+)\\)\\s*$', line)\n" +
      "        if section_match:\n" +
      "            current_section = section_match.group(1).strip()\n" +
      "            continue\n" +
      "        if current_section != iface:\n" +
      "            continue\n" +
      "        if 'Current DNS Server:' in line:\n" +
      "            current = line.split('Current DNS Server:', 1)[1].strip()\n" +
      "            if current and current not in dns_servers:\n" +
      "                dns_servers.append(current)\n" +
      "        elif 'DNS Servers:' in line:\n" +
      "            suffix = line.split('DNS Servers:', 1)[1].strip()\n" +
      "            for token in re.split(r'\\s+', suffix):\n" +
      "                token = token.strip()\n" +
      "                if token and token not in dns_servers:\n" +
      "                    dns_servers.append(token)\n" +
      "    if not dns_servers:\n" +
      "        for line in resolv.splitlines():\n" +
      "            if 'Current DNS Server:' in line:\n" +
      "                value = line.split('Current DNS Server:', 1)[1].strip()\n" +
      "                if value:\n" +
      "                    dns_servers.append(value)\n" +
      "                    break\n" +
      "except Exception:\n" +
      "    pass\n" +
      "if not dns_servers:\n" +
      "    try:\n" +
      "        for line in open('/etc/resolv.conf', 'r', encoding='utf-8', errors='replace').read().splitlines():\n" +
      "            if line.startswith('nameserver'):\n" +
      "                value = line.split()[1].strip()\n" +
      "                if value:\n" +
      "                    dns_servers.append(value)\n" +
      "    except Exception:\n" +
      "        pass\n" +
      "dns_servers = dedupe(dns_servers)[:3]\n" +
      "connection = ssid or (iface_type if iface_type != 'Other' else 'Disconnected')\n" +
      "if iface_type == 'Ethernet':\n" +
      "    connection = 'Ethernet'\n" +
      "elif iface_type == 'Wi-Fi' and ssid:\n" +
      "    connection = ssid\n" +
      "elif iface_type == 'Wi-Fi':\n" +
      "    connection = 'Wi‑Fi'\n" +
      "if iface_type == 'Other' and iface.startswith('tun'):\n" +
      "    connection = 'Tunnel'\n" +
      "summary = 'Disconnected'\n" +
      "if state == 'Connected':\n" +
      "    summary = f'{connection} · {link_speed}' if link_speed else connection\n" +
      "    if iface_type == 'Wi-Fi':\n" +
      "        summary = f'Wi‑Fi · Connected'\n" +
      "else:\n" +
      "    summary = 'Disconnected'\n" +
      "\n" +
      "adapters = []\n" +
      "for item in links:\n" +
      "    name = str(item.get('ifname') or '').strip()\n" +
      "    if not name or name == 'lo' or name.startswith(('docker', 'veth', 'br-', 'virbr', 'cni', 'flannel')):\n" +
      "        continue\n" +
      "    oper = str(item.get('operstate') or 'DOWN').strip().lower()\n" +
      "    link_type = str(item.get('link_type') or '').lower()\n" +
      "    kind = 'Other'\n" +
      "    if os.path.exists(f'/sys/class/net/{name}/wireless'):\n" +
      "        kind = 'Wi-Fi'\n" +
      "    elif name.startswith(('tun', 'tap', 'wg', 'tailscale')):\n" +
      "        kind = 'Tunnel'\n" +
      "    elif link_type == 'ether':\n" +
      "        kind = 'Ethernet'\n" +
      "    elif name.startswith(('veth', 'docker', 'cni', 'virbr', 'br-')):\n" +
      "        kind = 'Virtual'\n" +
      "    adapters.append({'name': name, 'type': kind, 'state': 'Connected' if oper in {'up', 'unknown'} else 'Disconnected', 'primary': name == iface})\n" +
      "\n" +
      "payload = {'interface': iface or '—', 'connection': connection or '—', 'state': state, 'ipv4': ipv4 or '—', 'gateway': gateway or '—', 'link': link_speed or '—', 'dns': ', '.join(dns_servers) if dns_servers else '—', 'summary': summary, 'adapters': adapters}\n" +
      "print(json.dumps(payload, separators=(',', ':')) )\n" +
      "PY"
    ]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateNetworkState(text)
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (!root.opened) return
        var msg = String(text || "").trim()
        if (msg !== "") {
          console.warn("k3v.hardware: " + msg)
        }
      }
    }
    onExited: function(exitCode) {
      root.networkMetaBusy = false
      if (!root.opened) return
      if (exitCode !== 0 && root.networkError === "") {
        root.networkError = "Network metadata exited with code " + exitCode
        console.warn("k3v.hardware: " + root.networkError)
      }
    }
  }

  Process {
    id: networkStatsProc
    command: [
      "bash",
      "-lc",
      "python3 - <<'PY'\n" +
      "import json, os, subprocess\n" +
      "\n" +
      "routes = []\n" +
      "try:\n" +
      "    routes = json.loads(subprocess.check_output(['ip', '-j', 'route', 'show', 'default'], stderr=subprocess.DEVNULL, text=True, env={**os.environ, 'LC_ALL': 'C'}))\n" +
      "except Exception:\n" +
      "    routes = []\n" +
      "iface = ''\n" +
      "for route in routes:\n" +
      "    dev = str(route.get('dev') or '').strip()\n" +
      "    if dev:\n" +
      "        iface = dev\n" +
      "        break\n" +
      "if not iface:\n" +
      "    try:\n" +
      "        for entry in os.listdir('/sys/class/net'):\n" +
      "            if entry == 'lo':\n" +
      "                continue\n" +
      "            if entry.startswith(('docker', 'veth', 'br-', 'virbr', 'cni', 'flannel')):\n" +
      "                continue\n" +
      "            path = '/sys/class/net/' + entry\n" +
      "            if os.path.isdir(path):\n" +
      "                oper = ''\n" +
      "                try:\n" +
      "                    oper = open(path + '/operstate', 'r', encoding='utf-8', errors='replace').read().strip().lower()\n" +
      "                except Exception:\n" +
      "                    oper = ''\n" +
      "                if oper in {'up', 'unknown'}:\n" +
      "                    iface = entry\n" +
      "                    break\n" +
      "    except Exception:\n" +
      "        pass\n" +
      "rx_bytes = 0\n" +
      "tx_bytes = 0\n" +
      "if iface:\n" +
      "    try:\n" +
      "        rx_path = '/sys/class/net/' + iface + '/statistics/rx_bytes'\n" +
      "        tx_path = '/sys/class/net/' + iface + '/statistics/tx_bytes'\n" +
      "        rx_bytes = int(open(rx_path, 'r', encoding='utf-8', errors='replace').read().strip() or 0)\n" +
      "        tx_bytes = int(open(tx_path, 'r', encoding='utf-8', errors='replace').read().strip() or 0)\n" +
      "    except Exception:\n" +
      "        rx_bytes = 0\n" +
      "        tx_bytes = 0\n" +
      "print(json.dumps({'iface': iface, 'rxBytes': rx_bytes, 'txBytes': tx_bytes}, separators=(',', ':')) )\n" +
      "PY"
    ]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateNetworkStats(text)
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
      root.networkStatsBusy = false
      if (!root.opened) return
      if (exitCode !== 0) {
        root.networkReceiving = "—"
        root.networkSending = "—"
      }
    }
  }

  Process {
    id: serviceProc
    command: [
      "bash",
      "-lc",
      "python3 - <<'PY'\n" +
      "import json, os, subprocess\n" +
      "\n" +
      "LIST = ['systemctl', '--no-pager', '--no-legend', '--plain', '--full', 'list-units', '--type=service', '--all']\n" +
      "IMPORTANT = ('NetworkManager', 'networkd', 'bluetooth', 'pipewire', 'wireplumber', 'sshd', 'ssh.service', 'sunshine', 'tailscale', 'docker', 'podman', 'libvirt', 'cups', 'power-profiles-daemon')\n" +
      "\n" +
      "def call(args):\n" +
      "    try:\n" +
      "        return subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, env={**os.environ, 'LC_ALL': 'C'}, check=False)\n" +
      "    except OSError:\n" +
      "        return None\n" +
      "\n" +
      "def manager_state(user):\n" +
      "    args = ['systemctl'] + (['--user'] if user else []) + ['is-system-running']\n" +
      "    result = call(args)\n" +
      "    if result is None:\n" +
      "        return 'unknown'\n" +
      "    state = result.stdout.strip().splitlines()\n" +
      "    return state[0].strip() if state and state[0].strip() else 'unknown'\n" +
      "\n" +
      "def parse_units(user):\n" +
      "    result = call((['systemctl', '--user'] if user else ['systemctl']) + LIST[1:])\n" +
      "    if result is None or result.returncode != 0:\n" +
      "        return None\n" +
      "    services = []\n" +
      "    for line in result.stdout.splitlines():\n" +
      "        parts = line.strip().split(None, 4)\n" +
      "        if len(parts) < 4 or not parts[0].endswith('.service'):\n" +
      "            continue\n" +
      "        unit, load, active, sub = parts[:4]\n" +
      "        description = parts[4].strip() if len(parts) == 5 else ''\n" +
      "        services.append({'unit': unit, 'description': description, 'scope': 'user' if user else 'system', 'loadState': load, 'activeState': active, 'subState': sub})\n" +
      "    return services\n" +
      "\n" +
      "def manager(services, state):\n" +
      "    units = services or []\n" +
      "    return {'state': state, 'loaded': sum(1 for x in units if x['loadState'] == 'loaded'), 'active': sum(1 for x in units if x['activeState'] == 'active'), 'running': sum(1 for x in units if x['activeState'] == 'active' and x['subState'] == 'running'), 'failed': sum(1 for x in units if x['activeState'] == 'failed')}\n" +
      "\n" +
      "system = parse_units(False)\n" +
      "user = parse_units(True)\n" +
      "all_services = (system or []) + (user or [])\n" +
      "important = [x for x in all_services if x['loadState'] == 'loaded' and any(token.lower() in x['unit'].lower() for token in IMPORTANT)]\n" +
      "failed = [x for x in all_services if x['activeState'] == 'failed']\n" +
      "audio = {}\n" +
      "display = None\n" +
      "for item in user or []:\n" +
      "    unit = item['unit']\n" +
      "    if unit == 'pipewire.service': audio['pipewire'] = item\n" +
      "    elif unit == 'pipewire-pulse.service': audio['pipewirePulse'] = item\n" +
      "    elif unit == 'wireplumber.service': audio['wireplumber'] = item\n" +
      "    elif unit.startswith('wayland-wm@') and unit.endswith('.service'): display = item\n" +
      "payload = {'systemManager': manager(system, manager_state(False)), 'userManager': manager(user, manager_state(True)), 'services': all_services, 'importantServices': important, 'failedServices': failed[:5], 'audio': audio, 'display': display}\n" +
      "print(json.dumps(payload, separators=(',', ':')))\n" +
      "PY"
    ]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateSystemdState(text)
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (root.opened && String(text || "").trim() !== "")
          console.warn("k3v.hardware: systemd collector: " + String(text).trim())
      }
    }
    onExited: function(exitCode) {
      root.serviceCollectorBusy = false
      if (root.opened && exitCode !== 0 && root.systemdError === "")
        root.systemdError = "Service collector exited with code " + exitCode
    }
  }

  Process {
    id: storageProc
    command: [
      "bash",
      "-lc",
      "LC_ALL=C python3 - <<'PY'\n" +
      "import json, os, shutil, subprocess\n" +
      "root_info = {'source': None, 'filesystem': None, 'totalBytes': 0, 'usedBytes': 0, 'availableBytes': 0, 'usagePercent': 0.0}\n" +
      "try:\n" +
      "    st = os.statvfs('/')\n" +
      "    block_size = st.f_frsize or st.f_bsize or 4096\n" +
      "    total = st.f_blocks * block_size\n" +
      "    available = st.f_bavail * block_size\n" +
      "    used = max(0, total - available)\n" +
      "    root_info['totalBytes'] = int(total)\n" +
      "    root_info['availableBytes'] = int(available)\n" +
      "    root_info['usedBytes'] = int(used)\n" +
      "    root_info['usagePercent'] = round((100.0 * used / total), 1) if total else 0.0\n" +
      "except Exception:\n" +
      "    pass\n" +
      "if shutil.which('findmnt'):\n" +
      "    try:\n" +
      "        data = json.loads(subprocess.check_output(['findmnt', '-J', '-T', '/'], stderr=subprocess.DEVNULL, text=True, env={**os.environ, 'LC_ALL': 'C'}))\n" +
      "        filesystems = data.get('filesystems') or []\n" +
      "        if filesystems:\n" +
      "            first = filesystems[0]\n" +
      "            if isinstance(first, dict):\n" +
      "                root_info['source'] = first.get('source') or None\n" +
      "                root_info['filesystem'] = first.get('fstype') or None\n" +
      "    except Exception:\n" +
      "        pass\n" +
      "drives = []\n" +
      "if shutil.which('lsblk'):\n" +
      "    try:\n" +
      "        data = json.loads(subprocess.check_output(['lsblk', '-J', '-b', '-d', '-o', 'NAME,PATH,TYPE,SIZE,MODEL,TRAN,ROTA,RM'], stderr=subprocess.DEVNULL, text=True, env={**os.environ, 'LC_ALL': 'C'}))\n" +
      "        for item in (data.get('blockdevices') or []):\n" +
      "            if not isinstance(item, dict):\n" +
      "                continue\n" +
      "            name = str(item.get('name') or '').strip()\n" +
      "            if not name or item.get('type') != 'disk':\n" +
      "                continue\n" +
      "            if name.startswith(('zram', 'loop', 'ram', 'dm-')):\n" +
      "                continue\n" +
      "            model = str(item.get('model') or '').strip()\n" +
      "            transport = str(item.get('tran') or '').strip().lower()\n" +
      "            rotational = bool(item.get('rota'))\n" +
      "            removable = bool(item.get('rm'))\n" +
      "            if removable:\n" +
      "                disk_type = 'Removable'\n" +
      "            elif transport == 'nvme':\n" +
      "                disk_type = 'NVMe'\n" +
      "            elif rotational:\n" +
      "                disk_type = 'HDD'\n" +
      "            elif transport in {'sata', 'ata', 'sas', 'usb'}:\n" +
      "                disk_type = 'SSD'\n" +
      "            else:\n" +
      "                disk_type = transport.upper() if transport else 'Disk'\n" +
      "            size = item.get('size')\n" +
      "            try:\n" +
      "                size_value = int(size) if size is not None else 0\n" +
      "            except (TypeError, ValueError):\n" +
      "                size_value = 0\n" +
      "            drives.append({\n" +
      "                'name': name,\n" +
      "                'model': model or name,\n" +
      "                'sizeBytes': size_value,\n" +
      "                'transport': transport.upper() if transport else 'Disk',\n" +
      "                'rotational': rotational,\n" +
      "                'removable': removable,\n" +
      "                'type': disk_type,\n" +
      "            })\n" +
      "    except Exception:\n" +
      "        pass\n" +
      "print(json.dumps({'root': root_info, 'drives': drives}, separators=(',', ':')) )\n" +
      "PY"
    ]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateStorageState(text)
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (!root.opened) return
        var msg = String(text || "").trim()
        if (msg !== "") root.handleStorageFailure(msg)
      }
    }
    onExited: function(exitCode) {
      root.storageCollectorBusy = false
      if (!root.opened) {
        root.storageError = ""
        return
      }
      if (exitCode !== 0 && root.storageError === "") {
        root.setStorageUnavailable("Storage telemetry exited with code " + exitCode)
      }
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

  Timer {
    interval: 5000
    running: root.opened
    repeat: true
    onTriggered: {
      if (!root.storageCollectorBusy && !storageProc.running) {
        root.storageCollectorBusy = true
        storageProc.running = true
      }
    }
  }

  Timer {
    id: serviceTimer
    interval: 5000
    running: root.opened
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refreshSystemd()
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
                      width: Math.min(parent.width * 0.42, 150)
                      text: modelData.label
                      color: root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.body
                      elide: Text.ElideRight
                    }

                    Text {
                      id: valueText
                      anchors.right: parent.right
                      width: Math.min(parent.width * 0.52, 220)
                      text: modelData.value
                      color: root.dim
                      horizontalAlignment: Text.AlignRight
                      elide: Text.ElideRight
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
            implicitHeight: pciSectionColumn.implicitHeight + Style.space(16)
            visible: root.hardwarePciCount > 0 || root.hardwareError !== ""

            Column {
              id: pciSectionColumn
              width: parent.width
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: parent.top
              anchors.margins: Style.space(10)
              spacing: Style.space(8)

              PanelSectionHeader {
                width: parent.width
                text: "PCI DEVICES"
                foreground: root.foreground
                fontFamily: root.fontFamily
              }

              Repeater {
                model: root.pciRows.length > 0 ? root.pciRows : [{ title: "—", detail: "—" }]
                delegate: Column {
                  width: pciSectionColumn.width
                  spacing: Style.space(2)

                  Text {
                    width: parent.width
                    text: modelData.title
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    elide: Text.ElideRight
                  }

                  Text {
                    width: parent.width
                    text: modelData.detail
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    elide: Text.ElideRight
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
            implicitHeight: adapterSectionColumn.implicitHeight + Style.space(16)

            Column {
              id: adapterSectionColumn
              width: parent.width
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: parent.top
              anchors.margins: Style.space(10)
              spacing: Style.space(8)

              PanelSectionHeader {
                width: parent.width
                text: "ADAPTERS"
                foreground: root.foreground
                fontFamily: root.fontFamily
              }

              Repeater {
                model: root.networkAdapterRows.length > 0 ? root.networkAdapterRows : ["—"]
                delegate: Text {
                  width: adapterSectionColumn.width
                  text: modelData
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  elide: Text.ElideRight
                }
              }
            }
          }

          BorderSurface {
            width: panelFlick.width
            color: Util.alpha(Color.popups.background, 0.94)
            borderSpec: Border.flat(Util.alpha(root.foreground, 0.12), 1)
            radius: Style.cornerRadius
            implicitHeight: driveSectionColumn.implicitHeight + Style.space(16)

            Column {
              id: driveSectionColumn
              width: parent.width
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: parent.top
              anchors.margins: Style.space(10)
              spacing: Style.space(8)

              PanelSectionHeader {
                width: parent.width
                text: "DRIVES"
                foreground: root.foreground
                fontFamily: root.fontFamily
              }

              Repeater {
                model: root.driveRows.length > 0 ? root.driveRows : ["—"]
                delegate: Text {
                  width: driveSectionColumn.width
                  text: modelData
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  elide: Text.ElideRight
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
