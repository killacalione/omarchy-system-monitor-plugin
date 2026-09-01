import QtQuick
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

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.5)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  readonly property var sections: [
    {
      title: "Overview",
      rows: [
        { label: "Status", value: "Healthy" },
        { label: "Uptime", value: "18h 42m" },
        { label: "Load", value: "42%" }
      ]
    },
    {
      title: "CPU",
      rows: [
        { label: "Model", value: "AMD Ryzen 7" },
        { label: "Usage", value: "38%" },
        { label: "Temp", value: "58°C" }
      ]
    },
    {
      title: "GPU",
      rows: [
        { label: "Model", value: "Radeon RX 7800 XT" },
        { label: "Usage", value: "41%" },
        { label: "VRAM", value: "16 GB" }
      ]
    },
    {
      title: "Memory",
      rows: [
        { label: "Used", value: "22.4 GB" },
        { label: "Available", value: "11.8 GB" },
        { label: "Swap", value: "0.0 GB" }
      ]
    },
    {
      title: "Processes",
      rows: [
        { label: "Active", value: "286" },
        { label: "Threads", value: "1,930" },
        { label: "Top", value: "btop" }
      ]
    },
    {
      title: "Storage",
      rows: [
        { label: "Root", value: "71%" },
        { label: "Free", value: "354 GB" },
        { label: "SSD", value: "NVMe" }
      ]
    },
    {
      title: "Hardware",
      rows: [
        { label: "Board", value: "Custom" },
        { label: "Kernel", value: "Linux 6.12" },
        { label: "Power", value: "AC" }
      ]
    },
    {
      title: "Services",
      rows: [
        { label: "Network", value: "Online" },
        { label: "Audio", value: "Ready" },
        { label: "Display", value: "Normal" }
      ]
    }
  ]

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
                text: "Placeholder"
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
