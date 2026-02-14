pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import "../../components/"
import "./pages/"

QsPopupWindow {
    id: root

    popupWidth: 400
    popupMaxHeight: 700
    anchorSide: "right"
    contentImplicitHeight: pageStack.children[pageStack.currentIndex]?.implicitHeight ?? popupMaxHeight - 32

    onClosing: pageStack.currentIndex = 0
    onVisibleChanged: OsdService.suppressed = visible

    StackLayout {
        id: pageStack
        anchors.fill: parent
        currentIndex: 0

        // ==========================
        // PAGE 0: DASHBOARD
        // ==========================
        DashboardPage {
            onCloseWindow: root.closeWindow()
        }

        // ==========================
        // PAGE 1: WI-FI
        // ==========================
        WifiPage {
            onBackRequested: pageStack.currentIndex = 0
            onPasswordRequested: ssid => {
                wifiPasswordPage.targetSsid = ssid;
                pageStack.currentIndex = 2;
            }
        }

        // ==========================
        // PAGE 2: WI-FI PASSWORD
        // ==========================
        WifiPasswordPage {
            id: wifiPasswordPage
            onCancelled: pageStack.currentIndex = 1
            onConnectClicked: password => {
                NetworkService.connect(targetSsid, password);
                pageStack.currentIndex = 1;
            }
        }

        // ==========================
        // PAGE 3: BLUETOOTH
        // ==========================
        BluetoothPage {
            onBackRequested: pageStack.currentIndex = 0
        }

        // ==========================
        // PAGE 4: AUDIO
        // ==========================
        AudioPage {
            onBackRequested: pageStack.currentIndex = 0
        }

    }
}
