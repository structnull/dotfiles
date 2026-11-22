pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
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
  property var allImages: []
  property bool scanFinished: false
  property bool viewInitialized: false
  property bool updatingModel: false
  property bool showLabels: true
  property bool filterable: true
  property string filterText: ""
  property color accent: ThemeService.colors.primary || "#798186"
  property color background: ThemeService.colors.surface || "#101315"
  property color foreground: ThemeService.colors.onSurface || "#cacccc"
  property int expandedWidth: Math.min(768, Math.max(sliceWidth, width - 80))
  property int sliceWidth: 108
  property int sliceHeight: 432
  property int sliceSpacing: -30
  property int skewOffset: 28
  readonly property int slicePitch: sliceWidth + sliceSpacing
  readonly property int bottomChromeHeight: showLabels ? (filterable ? 104 : 74) : 30
  readonly property var currentImage: imageModel.values[carouselList.currentIndex]

  function withAlpha(color, alpha) {
    return Qt.rgba(color.r, color.g, color.b, alpha)
  }

  function updateFilter(nextFilterText, preferredImage = currentImage) {
    filterText = nextFilterText
    if (!viewInitialized) return

    const needle = nextFilterText.toLowerCase()
    const matches = needle ? allImages.filter(image =>
      image.searchPath.includes(needle) || image.searchLabel.includes(needle)) : allImages

    updatingModel = true
    imageModel.values = matches
    if (matches.length > 0)
      centerSelection(Math.max(0, matches.indexOf(preferredImage)))
    updatingModel = false
  }

  function centerSelection(index) {
    carouselList.cancelFlick()
    carouselList.currentIndex = index
    carouselList.forceLayout()
    carouselList.positionViewAtIndex(index, ListView.SnapPosition)
    carouselList.forceLayout()
  }

  function syncViewport() {
    if (!scanFinished || carouselList.width <= 0 || carouselList.height <= 0) return

    if (!viewInitialized) {
      viewInitialized = true
      updateFilter(filterText, allImages.find(image => image.path === WallpaperService.current))
    } else if (carouselList.currentIndex >= 0 && carouselList.count > 0) {
      updatingModel = true
      centerSelection(carouselList.currentIndex)
      updatingModel = false
    }
  }

  function selectAdjacent(direction) {
    if (carouselList.count > 0)
      carouselList.currentIndex = Math.max(0, Math.min(carouselList.count - 1, carouselList.currentIndex + direction))
  }

  function applySelected() {
    if (currentImage) {
      WallpaperService.set(currentImage.path)
    }
    WallpaperService.hide()
  }

  function loadImages(paths) {
    const directory = root.imageDirs.replace(/\/+$/, "") + "/"
    allImages = paths.split("\0").filter(path => path).map(path => {
      const relativePath = path.startsWith(directory) ? path.slice(directory.length) : path
      const label = relativePath.replace(/\.[^/.]+$/, "").replace(/\//g, " / ")
        .replace(/[-_]+/g, " ").replace(/\b\w/g, match => match.toUpperCase())
      return {
        path: path,
        url: "file://" + path.split("/").map(encodeURIComponent).join("/"),
        label: label,
        searchPath: relativePath.toLowerCase(),
        searchLabel: label.toLowerCase()
      }
    })
    scanFinished = true
    Qt.callLater(root.syncViewport)
  }

  ScriptModel {
    id: imageModel
    comparisonMode: ObjectComparison.Identity
    values: []
  }

  // Rescan on open so newly copied files with older timestamps are included.
  Process {
    running: root.visible
    command: ["bash", "-c",
      "while IFS= read -r dir; do [[ -n $dir && -d $dir ]] && find -L \"$dir\" -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.bmp' -o -iname '*.webp' \\) -print0; done <<< \"$1\" | sort -zu",
      "wallpaper-picker", root.imageDirs]
    stdout: StdioCollector {
      onStreamFinished: root.loadImages(text)
    }
  }

  onVisibleChanged: {
    if (visible)
      keyHandler.forceActiveFocus()
  }
  onWindowConnected: Qt.callLater(root.syncViewport)

  onCurrentImageChanged: {
    detailPreview.source = ""
    detailDelay.restart()
  }

  Timer {
    id: detailDelay
    interval: 100
    onTriggered: detailPreview.source = root.currentImage?.url ?? ""
  }

  Image {
    id: detailPreview
    visible: false
    asynchronous: true
    cache: false
    sourceSize: Qt.size(root.expandedWidth, root.sliceHeight)
    readonly property real aspect: status === Image.Ready ? sourceSize.width / sourceSize.height : 0
  }

  Rectangle {
    anchors.fill: parent
    color: root.withAlpha(root.background, 0.72)
  }

  MouseArea {
    anchors.fill: parent
    onClicked: WallpaperService.hide()
  }

  Item {
    id: card
    width: Math.max(0, Math.min(parent.width - 80, root.expandedWidth + 13 * root.slicePitch + 40))
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
      width: Math.min(parent.width, root.expandedWidth + 13 * root.slicePitch)

      ListView {
        id: carouselList
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: parent.height + 12
        clip: true
        orientation: ListView.Horizontal
        spacing: root.sliceSpacing
        preferredHighlightBegin: (width - root.sliceWidth) / 2
        preferredHighlightEnd: preferredHighlightBegin
        highlightRangeMode: ListView.StrictlyEnforceRange
        highlightMoveDuration: root.updatingModel ? 0 : 180
        highlightMoveVelocity: -1
        snapMode: ListView.SnapToItem
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: 0
        model: imageModel
        readonly property int previewRadius: Math.ceil(Math.max(0, width - root.expandedWidth) / (2 * root.slicePitch)) + 1

        onWidthChanged: Qt.callLater(root.syncViewport)

        delegate: Item {
          id: slot
          required property int index
          required property var modelData

          // Expand the artwork around the scroll position while keeping every
          // ListView slot the same size. Neighbors share the extra width in motion.
          readonly property real offset: (x - carouselList.contentX - carouselList.preferredHighlightBegin) / root.slicePitch
          readonly property real expansion: Math.max(0, 1 - Math.abs(offset))
          readonly property real extraWidth: root.expandedWidth - root.sliceWidth
          readonly property real screenLeft: x - carouselList.contentX + tile.x
          readonly property real screenRight: screenLeft + tile.width
          readonly property bool nearViewport: screenRight > -root.slicePitch && screenLeft < carouselList.width + root.slicePitch
          readonly property bool nearSelection: Math.abs(index - carouselList.currentIndex) <= carouselList.previewRadius
          readonly property bool selected: index === carouselList.currentIndex

          width: root.sliceWidth
          height: carousel.height
          z: 1 + expansion

          Image {
            id: preview
            visible: false
            source: slot.nearViewport || slot.nearSelection ? slot.modelData.url : ""
            sourceSize: Qt.size(384, 216)
            asynchronous: true
            cache: false
            readonly property real aspect: status === Image.Ready ? sourceSize.width / sourceSize.height : 0
          }

          Item {
            id: tile
            x: slot.extraWidth * (Math.min(1, Math.max(0, slot.offset)) - 0.5)
            width: root.sliceWidth + slot.extraWidth * slot.expansion
            height: parent.height
            visible: slot.screenRight > -6 && slot.screenLeft < carouselList.width + 2

            ShaderEffect {
              id: artwork
              x: -2
              y: -2
              width: tile.width + 8
              height: tile.height + 14
              fragmentShader: "../../shaders/wallpaper-slice.frag.qsb"

              readonly property bool useDetail: slot.selected && slot.expansion > 0.999 && detailPreview.aspect > 0
                && detailPreview.source.toString() === slot.modelData.url
              property Image previewImage: useDetail ? detailPreview : preview
              property vector2d tileSize: Qt.vector2d(tile.width, tile.height)
              property real imageAspect: useDetail ? detailPreview.aspect : (preview?.aspect ?? 0)
              property real skew: root.skewOffset
              property real expansion: slot.expansion
              property color backgroundColor: root.background
              property color borderColor: Qt.rgba(
                root.foreground.r + (root.accent.r - root.foreground.r) * expansion,
                root.foreground.g + (root.accent.g - root.foreground.g) * expansion,
                root.foreground.b + (root.accent.b - root.foreground.b) * expansion,
                0.28 + 0.72 * expansion)
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (slot.selected)
                  root.applySelected()
                else
                  carouselList.currentIndex = slot.index
              }
            }
          }
        }
      }
    }

    Text {
      id: selectedLabel
      textFormat: Text.PlainText
      visible: root.showLabels
      anchors.top: carousel.bottom
      anchors.topMargin: 16
      anchors.horizontalCenter: carousel.horizontalCenter
      width: root.expandedWidth
      text: root.currentImage?.label ?? (root.filterText ? "No matches" : "")
      color: root.foreground
      style: Text.Outline
      styleColor: root.withAlpha(root.background, 0.7)
      font.pixelSize: 24
      font.weight: Font.DemiBold
      horizontalAlignment: Text.AlignHCenter
      elide: Text.ElideRight
    }

    Text {
      textFormat: Text.PlainText
      visible: root.filterable
      anchors.top: selectedLabel.bottom
      anchors.topMargin: 8
      anchors.horizontalCenter: carousel.horizontalCenter
      width: root.expandedWidth
      text: root.filterText ? ("Filter: " + root.filterText + " (" + carouselList.count + ")")
        : (WallpaperService.error || "Type to filter")
      color: WallpaperService.error && !root.filterText ? (ThemeService.colors.error || "#ff5f57") : root.foreground
      opacity: root.filterText ? 0.85 : 0.55
      style: Text.Outline
      styleColor: root.withAlpha(root.background, 0.7)
      font.pixelSize: 14
      horizontalAlignment: Text.AlignHCenter
      elide: Text.ElideRight
    }
  }

  Item {
    id: keyHandler
    focus: true
    Keys.onPressed: function(event) {
      if (event.key === Qt.Key_Escape) {
        if (root.filterText)
          root.updateFilter("")
        else
          WallpaperService.hide()
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
    windows: [root]
    active: root.visible
    onCleared: WallpaperService.hide()
  }
}
