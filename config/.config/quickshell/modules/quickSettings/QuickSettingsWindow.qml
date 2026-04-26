pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import "../../components/"
import "./pages/"

QsPopupWindow {
    id: root

    popupWidth: 400
    popupMaxHeight: 700
    anchorSide: "right"
    contentImplicitHeight: pageStack.children[pageStack.currentIndex]?.item?.implicitHeight ?? 0
    property string pendingWifiSsid: ""

    onClosing: pageStack.currentIndex = 0
    onVisibleChanged: OsdService.suppressed = visible

    StackLayout {
        id: pageStack
        anchors.fill: parent
        currentIndex: 0

        // ==========================
        // PAGE 0: DASHBOARD
        // ==========================
        Loader {
            Layout.fillWidth: true
            active: pageStack.currentIndex === 0

            sourceComponent: Component {
                DashboardPage {
                    onCloseWindow: root.closeWindow()
                }
            }
        }

        // ==========================
        // PAGE 1: WI-FI
        // ==========================
        Loader {
            Layout.fillWidth: true
            active: pageStack.currentIndex === 1

            sourceComponent: Component {
                WifiPage {
                    onBackRequested: pageStack.currentIndex = 0
                    onPasswordRequested: ssid => {
                        root.pendingWifiSsid = ssid;
                        pageStack.currentIndex = 2;
                    }
                }
            }
        }

        // ==========================
        // PAGE 2: WI-FI PASSWORD
        // ==========================
        Loader {
            Layout.fillWidth: true
            active: pageStack.currentIndex === 2

            sourceComponent: Component {
                WifiPasswordPage {
                    targetSsid: root.pendingWifiSsid
                    onCancelled: pageStack.currentIndex = 1
                    onConnectClicked: password => {
                        NetworkService.connect(targetSsid, password);
                        pageStack.currentIndex = 1;
                    }
                }
            }
        }

        // ==========================
        // PAGE 3: BLUETOOTH
        // ==========================
        Loader {
            Layout.fillWidth: true
            active: pageStack.currentIndex === 3

            sourceComponent: Component {
                BluetoothPage {
                    onBackRequested: pageStack.currentIndex = 0
                }
            }
        }

        // ==========================
        // PAGE 4: AUDIO
        // ==========================
        Loader {
            Layout.fillWidth: true
            active: pageStack.currentIndex === 4

            sourceComponent: Component {
                AudioPage {
                    onBackRequested: pageStack.currentIndex = 0
                }
            }
        }

    }
}
