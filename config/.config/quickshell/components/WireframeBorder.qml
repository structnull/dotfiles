pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes

Shape {
    id: root
    property color strokeColor: "white"
    property real cornerSize: 10
    property real cornerExtension: 8
    property bool solidCorners: true
    property var dashPattern: [4, 4]
    readonly property real x0: 0.5
    readonly property real y0: 0.5
    readonly property real x1: width - 0.5
    readonly property real y1: height - 0.5
    readonly property real arm: cornerSize + cornerExtension
    antialiasing: true

    ShapePath {
        strokeColor: root.solidCorners ? root.strokeColor : "transparent"
        strokeWidth: 1
        capStyle: ShapePath.FlatCap
        strokeStyle: ShapePath.DashLine
        dashPattern: root.dashPattern
        fillColor: "transparent"
        startX: root.x0 + root.arm; startY: root.y0
        PathLine { x: root.x1 - root.arm; y: root.y0 }
        PathMove { x: root.x1; y: root.y0 + root.arm }
        PathLine { x: root.x1; y: root.y1 - root.arm }
        PathMove { x: root.x1 - root.arm; y: root.y1 }
        PathLine { x: root.x0 + root.arm; y: root.y1 }
        PathMove { x: root.x0; y: root.y1 - root.arm }
        PathLine { x: root.x0; y: root.y0 + root.arm }
    }

    ShapePath {
        strokeColor: root.solidCorners ? root.strokeColor : "transparent"
        strokeWidth: 2
        fillColor: "transparent"
        joinStyle: ShapePath.MiterJoin
        capStyle: ShapePath.FlatCap
        startX: root.x0; startY: root.y0 + root.arm
        PathLine { x: root.x0; y: root.y0 + root.cornerSize }
        PathLine { x: root.x0 + root.cornerSize; y: root.y0 }
        PathLine { x: root.x0 + root.arm; y: root.y0 }
        PathMove { x: root.x1 - root.arm; y: root.y0 }
        PathLine { x: root.x1 - root.cornerSize; y: root.y0 }
        PathLine { x: root.x1; y: root.y0 + root.cornerSize }
        PathLine { x: root.x1; y: root.y0 + root.arm }
        PathMove { x: root.x1; y: root.y1 - root.arm }
        PathLine { x: root.x1; y: root.y1 - root.cornerSize }
        PathLine { x: root.x1 - root.cornerSize; y: root.y1 }
        PathLine { x: root.x1 - root.arm; y: root.y1 }
        PathMove { x: root.x0 + root.arm; y: root.y1 }
        PathLine { x: root.x0 + root.cornerSize; y: root.y1 }
        PathLine { x: root.x0; y: root.y1 - root.cornerSize }
        PathLine { x: root.x0; y: root.y1 - root.arm }
    }

    ShapePath {
        strokeColor: root.solidCorners ? "transparent" : root.strokeColor
        strokeWidth: 1
        capStyle: ShapePath.FlatCap
        strokeStyle: ShapePath.DashLine
        dashPattern: root.dashPattern
        fillColor: "transparent"
        joinStyle: ShapePath.MiterJoin
        startX: root.x0 + root.cornerSize; startY: root.y0
        PathLine { x: root.x1 - root.cornerSize; y: root.y0 }
        PathLine { x: root.x1; y: root.y0 + root.cornerSize }
        PathLine { x: root.x1; y: root.y1 - root.cornerSize }
        PathLine { x: root.x1 - root.cornerSize; y: root.y1 }
        PathLine { x: root.x0 + root.cornerSize; y: root.y1 }
        PathLine { x: root.x0; y: root.y1 - root.cornerSize }
        PathLine { x: root.x0; y: root.y0 + root.cornerSize }
        PathLine { x: root.x0 + root.cornerSize; y: root.y0 }
    }
}
