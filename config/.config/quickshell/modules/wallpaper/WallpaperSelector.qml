pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services

PanelWindow {
  id: root

  visible: WallpaperService.selectorVisible
  anchors { top: true; bottom: true; left: true; right: true }
  color: "transparent"
  WlrLayershell.namespace: "qs_wallpaper"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
  exclusionMode: ExclusionMode.Ignore

  property string imageDirs: Quickshell.env("HOME") + "/Pictures/wallpapers"
  property int selectedIndex: 0
  property bool imagesLoaded: false
  property bool showLabels: true
  property bool filterable: true
  property string filterText: ""
  property color accent: ThemeService.colors.primary || "#798186"
  property color background: ThemeService.colors.surface || "#101315"
  property color foreground: ThemeService.colors.onSurface || "#cacccc"
  property int expandedWidth: 768
  property int sliceWidth: 108
  property int sliceHeight: 432
  property int sliceSpacing: -30
  property int skewOffset: 28
  property int preloadRadius: 8
  property int bottomChromeHeight: showLabels ? (filterable ? 104 : 74) : 30

  function fileUrl(path) {
    return "file://" + path.split("/").map(encodeURIComponent).join("/")
  }

  function shellQuote(value) {
    return "'" + String(value).replace(/'/g, "'\\''") + "'"
  }

  function withAlpha(color, alpha) {
    return Qt.rgba(color.r, color.g, color.b, alpha)
  }

  function currentPath() {
    if (imageModel.count === 0 || !itemMatches(selectedIndex)) return ""
    return imageModel.get(selectedIndex).filePath
  }

  function nameForPath(path) {
    return path.split("/").pop().replace(/\.[^/.]+$/, "")
  }

  function relativePath(path) {
    var prefix = root.imageDirs.replace(/\/+$/, "") + "/"
    return path.indexOf(prefix) === 0 ? path.slice(prefix.length) : path
  }

  function labelForPath(path) {
    return relativePath(path).replace(/\.[^/.]+$/, "").replace(/\//g, " / ").replace(/[-_]+/g, " ").replace(/\b\w/g, function(match) { return match.toUpperCase() })
  }

  function currentLabel() {
    var path = currentPath()
    if (!path) return filterText ? "No matches" : ""
    return labelForPath(path)
  }

  function itemMatches(index) {
    if (index < 0 || index >= imageModel.count) return false
    if (!filterText) return true

    var path = imageModel.get(index).filePath
    var needle = filterText.toLowerCase()
    return relativePath(path).toLowerCase().indexOf(needle) !== -1 || labelForPath(path).toLowerCase().indexOf(needle) !== -1
  }

  function matchingCount() {
    if (!filterText) return imageModel.count

    var count = 0
    for (var i = 0; i < imageModel.count; i++) {
      if (itemMatches(i)) count++
    }
    return count
  }

  function firstMatchingIndex() {
    for (var i = 0; i < imageModel.count; i++) {
      if (itemMatches(i)) return i
    }
    return -1
  }

  function indexForPath(path) {
    if (!path) return -1

    for (var i = 0; i < imageModel.count; i++) {
      if (imageModel.get(i).filePath === path) return i
    }
    return -1
  }

  function filteredPosition(index) {
    if (!filterText) return index

    var position = 0
    for (var i = 0; i < index; i++) {
      if (itemMatches(i)) position++
    }
    return position
  }

  function selectedFilteredPosition() {
    if (!filterText) return selectedIndex
    return itemMatches(selectedIndex) ? filteredPosition(selectedIndex) : 0
  }

  function select(index, immediate) {
    if (imageModel.count === 0) return
    if (index < 0) index = 0
    else if (index >= imageModel.count) index = imageModel.count - 1
    if (!itemMatches(index)) return
    if (index === selectedIndex && immediate !== true) return

    selectedIndex = index
  }

  function selectAdjacent(direction) {
    if (!filterText) {
      select(selectedIndex + direction)
      return
    }

    var index = selectedIndex + direction
    while (index >= 0 && index < imageModel.count) {
      if (itemMatches(index)) {
        select(index)
        return
      }
      index += direction
    }
  }

  function updateFilter(nextFilterText) {
    filterText = nextFilterText

    if (!itemMatches(selectedIndex)) {
      var first = firstMatchingIndex()
      if (first >= 0) selectedIndex = first
    }
  }

  function applySelected() {
    var path = currentPath()
    if (!path) {
      cancel()
      return
    }

    WallpaperService.set(path)
    ThemeService.generateFromImage(path)
    WallpaperService.hide()
  }

  function cancel() {
    WallpaperService.hide()
  }

  function loadRows(rows) {
    var paths = rows.split("\n")
    imageModel.clear()
    for (var i = 0; i < paths.length; i++) {
      var row = paths[i]
      if (!row) continue

      var columns = row.split("\t")
      addImage(columns[0], columns[1])
    }

    var currentIndex = indexForPath(WallpaperService.current)
    select(currentIndex >= 0 ? currentIndex : 0, true)
    imagesLoaded = true
    keyHandler.forceActiveFocus()
  }

  ListModel { id: imageModel }

  function addImage(path, thumbnailPath) {
    if (!path) return
    var fileName = path.split("/").pop()

    for (var i = imageModel.count - 1; i >= 0; i--) {
      if (imageModel.get(i).filePath === path)
        imageModel.remove(i)
    }

    imageModel.append({ filePath: path, fileName: fileName, thumbnailPath: thumbnailPath || path })
  }

  Process {
    id: loadImagesProc
    property string output: ""
    command: ["bash", "-lc", "cache_dir=${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/image-selector; manifest=\"$cache_dir/wallpapers.tsv\"; mkdir -p \"$cache_dir\"; rebuild=0; [[ -s $manifest ]] || rebuild=1; if [[ $rebuild -eq 0 ]]; then while IFS= read -r dir; do [[ -n $dir && -d $dir ]] || continue; if find -L \"$dir\" \\( -type d -newer \"$manifest\" -o \\( -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.bmp' -o -iname '*.webp' \\) -newer \"$manifest\" \\) \\) -print -quit | grep -q .; then rebuild=1; break; fi; done <<< " + shellQuote(root.imageDirs) + "; fi; if [[ $rebuild -eq 1 ]]; then tmp=\"$manifest.$$\"; while IFS= read -r dir; do [[ -n $dir && -d $dir ]] && find -L \"$dir\" -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.bmp' -o -iname '*.webp' \\) -printf '%p\\t%p\\n'; done <<< " + shellQuote(root.imageDirs) + " | sort > \"$tmp\"; mv \"$tmp\" \"$manifest\"; fi; cat \"$manifest\""]
    stdout: SplitParser {
      onRead: function(data) {
        loadImagesProc.output += data + "\n"
      }
    }
    onExited: {
      root.loadRows(output)
    }
  }

  onVisibleChanged: {
    if (visible) {
      if (!imagesLoaded) {
        loadImagesProc.output = ""
        loadImagesProc.running = true
      } else {
        keyHandler.forceActiveFocus()
      }
    }
  }

  Rectangle {
    anchors.fill: parent
    color: root.withAlpha(root.background, 0.72)
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.cancel()
  }

  Item {
    id: card
    width: Math.min(parent.width - 80, root.expandedWidth + 13 * (root.sliceWidth + root.sliceSpacing) + 40)
    height: root.sliceHeight + 30 + root.bottomChromeHeight
    anchors.centerIn: parent

    MouseArea { anchors.fill: parent; onClicked: {} }

    Item {
      id: carousel
      anchors.top: parent.top
      anchors.topMargin: 30
      anchors.bottom: parent.bottom
      anchors.bottomMargin: root.bottomChromeHeight
      anchors.horizontalCenter: parent.horizontalCenter
      width: root.expandedWidth + 13 * (root.sliceWidth + root.sliceSpacing)
      clip: false

      readonly property real itemStep: root.sliceWidth + root.sliceSpacing
      readonly property real previewX: (width - root.expandedWidth) / 2

      Repeater {
        model: imageModel

        delegate: Item {
          id: item
          required property int index
          required property string filePath
          required property string fileName
          required property string thumbnailPath

          readonly property bool matched: root.itemMatches(index)
          readonly property int relativeIndex: root.filteredPosition(index) - root.selectedFilteredPosition()
          readonly property bool selected: matched && index === root.selectedIndex
          readonly property bool nearby: matched && Math.abs(relativeIndex) <= root.preloadRadius

          visible: nearby
          x: selected ? carousel.previewX : (relativeIndex < 0 ? carousel.previewX + relativeIndex * carousel.itemStep : carousel.previewX + root.expandedWidth + root.sliceSpacing + (relativeIndex - 1) * carousel.itemStep)
          width: selected ? root.expandedWidth : root.sliceWidth
          height: carousel.height
          z: selected ? 100 : 50 - Math.min(Math.abs(relativeIndex), 40)

          Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
          Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

          readonly property real skAbs: Math.abs(root.skewOffset)
          readonly property real topLeft: root.skewOffset >= 0 ? skAbs : 0
          readonly property real topRight: root.skewOffset >= 0 ? width : width - skAbs
          readonly property real bottomRight: root.skewOffset >= 0 ? width - skAbs : width
          readonly property real bottomLeft: root.skewOffset >= 0 ? 0 : skAbs

          Item {
            id: maskShape
            anchors.fill: parent
            visible: false
            layer.enabled: true

            Shape {
              anchors.fill: parent
              antialiasing: true
              preferredRendererType: Shape.CurveRenderer
              ShapePath {
                fillColor: "white"
                strokeColor: "transparent"
                startX: item.topLeft; startY: 0
                PathLine { x: item.topRight; y: 0 }
                PathLine { x: item.bottomRight; y: item.height }
                PathLine { x: item.bottomLeft; y: item.height }
                PathLine { x: item.topLeft; y: 0 }
              }
            }
          }

          Shape {
            x: item.selected ? 4 : 2
            y: item.selected ? 10 : 5
            width: item.width
            height: item.height
            opacity: item.selected ? 0.5 : 0.32
            antialiasing: true
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
              fillColor: root.background
              strokeColor: "transparent"
              startX: item.topLeft; startY: 0
              PathLine { x: item.topRight; y: 0 }
              PathLine { x: item.bottomRight; y: item.height }
              PathLine { x: item.bottomLeft; y: item.height }
              PathLine { x: item.topLeft; y: 0 }
            }
          }

          Item {
            anchors.fill: parent
            layer.enabled: true
            layer.smooth: true
            layer.effect: MultiEffect {
              maskEnabled: true
              maskSource: maskShape
              maskThresholdMin: 0.3
              maskSpreadAtMin: 0.3
            }

            Image {
              id: image
              anchors.fill: parent
              source: item.nearby ? root.fileUrl(item.thumbnailPath) : ""
              sourceSize.width: item.selected ? root.expandedWidth : root.sliceWidth + Math.abs(root.skewOffset)
              sourceSize.height: root.sliceHeight
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              cache: false
              smooth: true
            }

            Rectangle {
              anchors.fill: parent
              color: root.withAlpha(root.background, item.selected ? 0 : 0.42)
              Behavior on color { ColorAnimation { duration: 120 } }
            }
          }

          Shape {
            anchors.fill: parent
            antialiasing: true
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
              fillColor: "transparent"
              strokeColor: item.selected ? root.accent : root.withAlpha(root.foreground, 0.28)
              strokeWidth: item.selected ? 3 : 1
              startX: item.topLeft; startY: 0
              PathLine { x: item.topRight; y: 0 }
              PathLine { x: item.bottomRight; y: item.height }
              PathLine { x: item.bottomLeft; y: item.height }
              PathLine { x: item.topLeft; y: 0 }
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: item.selected ? root.applySelected() : root.select(index)
          }
        }
      }
    }

    Text {
      id: selectedLabel
      visible: root.showLabels
      anchors.top: carousel.bottom
      anchors.topMargin: 16
      anchors.horizontalCenter: carousel.horizontalCenter
      width: root.expandedWidth
      text: root.currentLabel()
      color: root.foreground
      style: Text.Outline
      styleColor: root.withAlpha(root.background, 0.7)
      font.pixelSize: 24
      font.weight: Font.DemiBold
      horizontalAlignment: Text.AlignHCenter
      elide: Text.ElideRight
    }

    Text {
      visible: root.filterable
      anchors.top: selectedLabel.bottom
      anchors.topMargin: 8
      anchors.horizontalCenter: carousel.horizontalCenter
      width: root.expandedWidth
      text: root.filterText ? ("Filter: " + root.filterText + " (" + root.matchingCount() + ")") : "Type to filter"
      color: root.foreground
      opacity: root.filterText ? 0.85 : 0.55
      style: Text.Outline
      styleColor: root.withAlpha(root.background, 0.7)
      font.pixelSize: 14
      horizontalAlignment: Text.AlignHCenter
      elide: Text.ElideRight
    }
  }

  // Focus Grab
  Item {
    id: keyHandler
    focus: true
    Keys.onPressed: function(event) {
      if (event.key === Qt.Key_Escape) {
        if (root.filterText) {
          root.updateFilter("")
        } else {
          root.cancel()
        }
        event.accepted = true
      } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
        root.applySelected()
        event.accepted = true
      } else if (event.key === Qt.Key_Backspace && root.filterable) {
        if (root.filterText.length > 0)
          root.updateFilter(root.filterText.slice(0, -1))
        event.accepted = true
      } else if (event.key === Qt.Key_Left) {
        root.selectAdjacent(-1)
        event.accepted = true
      } else if (event.key === Qt.Key_Right) {
        root.selectAdjacent(1)
        event.accepted = true
      } else if (root.filterable && event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127 && (event.modifiers === Qt.NoModifier || event.modifiers === Qt.ShiftModifier)) {
        root.updateFilter(root.filterText + event.text)
        event.accepted = true
      }
    }
  }

  HyprlandFocusGrab {
      id: focusGrab
      windows: [root]
      active: root.visible
      onCleared: WallpaperService.hide()
  }
}
