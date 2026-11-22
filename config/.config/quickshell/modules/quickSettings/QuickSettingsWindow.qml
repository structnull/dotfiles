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
    readonly property bool wifiView: visible && (pageStack.currentIndex === 1 || pageStack.currentIndex === 2)
    property bool wifiRegistered: false
    readonly property bool audioView: visible && pageStack.currentIndex === 4
    property bool audioRegistered: false

    onWifiViewChanged: {
        if (wifiRegistered === wifiView)
            return;
        wifiRegistered = wifiView;
        if (wifiView)
            NetworkService.acquireWifiView();
        else
            NetworkService.releaseWifiView(root);
    }
    onAudioViewChanged: {
        if (audioRegistered === audioView)
            return;
        audioRegistered = audioView;
        if (audioView) {
            AudioService.audioPageConsumers++;
            AudioService.refreshDevices();
        } else {
            AudioService.audioPageConsumers--;
        }
    }
    onVisibleChanged: OsdService.suppress(root, visible)
    Component.onDestruction: {
        OsdService.suppress(root, false);
        if (wifiRegistered)
            NetworkService.releaseWifiView(root);
        if (audioRegistered)
            AudioService.audioPageConsumers--;
    }

    Connections {
        target: NetworkService

        function onPasswordRequired(owner) {
            if (owner === root && root.wifiView)
                pageStack.currentIndex = 2;
        }

        function onPendingNetworkChanged() {
            if (!NetworkService.pendingNetwork && pageStack.currentIndex === 2)
                pageStack.currentIndex = 1;
        }
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
                active: root.visible && pageStack.currentIndex === 0

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
                active: root.visible && pageStack.currentIndex === 1

                component: Component {
                    WifiPage {
                        parent: page1Host
                        width: pageStack.width
                        height: pageStack.height
                        onBackRequested: pageStack.currentIndex = 0
                        onConnectRequested: network => NetworkService.connectNetwork(network, root)
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
                active: root.visible && pageStack.currentIndex === 2

                component: Component {
                    WifiPasswordPage {
                        parent: page2Host
                        width: pageStack.width
                        height: pageStack.height
                        targetSsid: NetworkService.pendingNetwork?.name ?? ""
                        errorText: NetworkService.connectionError
                        onCancelled: NetworkService.cancelPassword(root)
                        onConnectClicked: password => {
                            pageStack.currentIndex = 1;
                            NetworkService.submitPassword(root, password);
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
                active: root.visible && pageStack.currentIndex === 3

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
                active: root.visible && pageStack.currentIndex === 4

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
