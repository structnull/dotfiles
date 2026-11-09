pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes

Shape {
    id: root
    property real radius: 8
    property color strokeColor: "white"
    antialiasing: true

    ShapePath {
        strokeColor: root.strokeColor
        strokeWidth: 1
        strokeStyle: ShapePath.DashLine
        dashPattern: [2, 4]
        fillColor: "transparent"
        capStyle: ShapePath.FlatCap
        startX: root.radius; startY: 0
        PathLine { x: root.width - root.radius; y: 0 }
        PathArc { x: root.width; y: root.radius; radiusX: root.radius; radiusY: root.radius }
        PathLine { x: root.width; y: root.height - root.radius }
        PathArc { x: root.width - root.radius; y: root.height; radiusX: root.radius; radiusY: root.radius }
        PathLine { x: root.radius; y: root.height }
        PathArc { x: 0; y: root.height - root.radius; radiusX: root.radius; radiusY: root.radius }
        PathLine { x: 0; y: root.radius }
        PathArc { x: root.radius; y: 0; radiusX: root.radius; radiusY: root.radius }
    }
}
