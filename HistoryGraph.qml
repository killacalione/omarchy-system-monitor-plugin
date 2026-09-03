import QtQuick
import QtQuick.Shapes
import qs.Commons

Item {
  id: root

  property var values: []
  property var secondaryValues: []
  property real minimum: 0
  property real maximum: 100
  property bool autoScale: false
  property string unit: "%"
  property string primaryLabel: ""
  property string secondaryLabel: ""
  property color foreground: Color.foreground
  property color primaryColor: Color.accent
  property color secondaryColor: Color.muted
  property real lineWidth: 1.5
  implicitHeight: 72

  function finiteValues(source) {
    var result = []
    if (!Array.isArray(source)) return result
    for (var i = 0; i < source.length; ++i) {
      var value = Number(source[i])
      if (isFinite(value)) result.push(value)
    }
    return result
  }

  function scaleMaximum() {
    if (!root.autoScale) return Math.max(root.minimum + 1, root.maximum)
    var all = finiteValues(root.values).concat(finiteValues(root.secondaryValues))
    var maxValue = 0
    for (var i = 0; i < all.length; ++i) maxValue = Math.max(maxValue, all[i])
    return Math.max(root.minimum + 1, maxValue * 1.15, 1)
  }

  function points(source) {
    var result = []
    var values = finiteValues(source)
    if (values.length === 0 || root.width <= 0 || root.height <= 0) return result
    var high = root.scaleMaximum()
    var low = root.minimum
    var span = Math.max(1, high - low)
    var step = values.length > 1 ? root.width / (values.length - 1) : 0
    for (var i = 0; i < values.length; ++i) {
      var fraction = Math.max(0, Math.min(1, (values[i] - low) / span))
      result.push(Qt.point(values.length === 1 ? root.width : i * step, root.height - fraction * root.height))
    }
    return result
  }

  readonly property var primaryPath: root.points(root.values)
  readonly property var secondaryPath: root.points(root.secondaryValues)

  Rectangle {
    anchors.fill: parent
    color: "transparent"
    border.color: Util.alpha(root.foreground, 0.16)
    border.width: 1
  }

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      strokeWidth: 1
      strokeColor: Util.alpha(root.foreground, 0.08)
      fillColor: "transparent"
      startX: 0
      startY: root.height / 2
      PathLine { x: root.width; y: root.height / 2 }
    }

    ShapePath {
      strokeWidth: root.lineWidth
      strokeColor: root.primaryColor
      fillColor: "transparent"
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin
      PathPolyline { path: root.primaryPath }
    }

    ShapePath {
      strokeWidth: root.lineWidth
      strokeColor: root.secondaryColor
      fillColor: "transparent"
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin
      PathPolyline { path: root.secondaryPath }
    }
  }
}
