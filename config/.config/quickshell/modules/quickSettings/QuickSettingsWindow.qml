pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import QtQuick.Layouts
import qs.services
import "../../components/"
import "./pages/"

QsPopupWindow {
    id: root

    popupWidth: 400
    popupMaxHeight: 700
    anchorSide: "right"
    contentImplicitHeight: pageStack.children[pageStack.currentIndex]?.implicitHeight ?? 0
    property string pendingWifiSsid: ""

    onClosing: pageStack.currentIndex = 0
    property bool _networkWindowRegistered: false

    function syncNetworkWindow() {
        if (_networkWindowRegistered === visible)
            return;
        _networkWindowRegistered = visible;
        if (visible)
            NetworkService.acquireSettingsWindow();
        else
            NetworkService.releaseSettingsWindow();
    }

    onVisibleChanged: {
        OsdService.suppressed = visible;
        syncNetworkWindow();
    }
    Component.onCompleted: syncNetworkWindow()
    Component.onDestruction: {
        if (_networkWindowRegistered)
            NetworkService.releaseSettingsWindow();
    }

    StackLayout {
        id: pageStack
        anchors.fill: parent
        currentIndex: 0

        // ==========================
        // PAGE 0: DASHBOARD
        // ==========================
        Item {
            id: page0Host
            implicitHeight: page0Loader.active ? page0Loader.item.implicitHeight : 0
            LazyLoader {
                id: page0Loader
                active: pageStack.currentIndex === 0

                component: Component {
                    DashboardPage {
                        parent: page0Host
                        width: pageStack.width
                        height: pageStack.height
                        onCloseWindow: root.closeWindow()
                    }
                }
            }
        }

        // ==========================
        // PAGE 1: WI-FI
        // ==========================
        Item {
            id: page1Host
            implicitHeight: page1Loader.active ? page1Loader.item.implicitHeight : 0
            LazyLoader {
                id: page1Loader
                active: pageStack.currentIndex === 1

                component: Component {
                    WifiPage {
                        parent: page1Host
                        width: pageStack.width
                        height: pageStack.height
                        onBackRequested: pageStack.currentIndex = 0
                        onPasswordRequested: ssid => {
                            root.pendingWifiSsid = ssid;
                            pageStack.currentIndex = 2;
                        }
                    }
                }
            }
        }

        // ==========================
        // PAGE 2: WI-FI PASSWORD
        // ==========================
        Item {
            id: page2Host
            implicitHeight: page2Loader.active ? page2Loader.item.implicitHeight : 0
            LazyLoader {
                id: page2Loader
                active: pageStack.currentIndex === 2

                component: Component {
                    WifiPasswordPage {
                        parent: page2Host
                        width: pageStack.width
                        height: pageStack.height
                        targetSsid: root.pendingWifiSsid
                        onCancelled: pageStack.currentIndex = 1
                        onConnectClicked: password => {
                            NetworkService.connect(targetSsid, password);
                            pageStack.currentIndex = 1;
                        }
                    }
                }
            }
        }

        // ==========================
        // PAGE 3: BLUETOOTH
        // ==========================
        Item {
            id: page3Host
            implicitHeight: page3Loader.active ? page3Loader.item.implicitHeight : 0
            LazyLoader {
                id: page3Loader
                active: pageStack.currentIndex === 3

                component: Component {
                    BluetoothPage {
                        parent: page3Host
                        width: pageStack.width
                        height: pageStack.height
                        onBackRequested: pageStack.currentIndex = 0
                    }
                }
            }
        }

        // ==========================
        // PAGE 4: AUDIO
        // ==========================
        Item {
            id: page4Host
            implicitHeight: page4Loader.active ? page4Loader.item.implicitHeight : 0
            LazyLoader {
                id: page4Loader
                active: pageStack.currentIndex === 4

                component: Component {
                    AudioPage {
                        parent: page4Host
                        width: pageStack.width
                        height: pageStack.height
                        onBackRequested: pageStack.currentIndex = 0
                    }
                }
            }
        }
    }
}
