pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.UPower
import qs.config
import "../../components/"

BarButton {
    id: root

    readonly property string icon: {
        if (PowerProfiles.profile === PowerProfile.Performance)
            return "";
        if (PowerProfiles.profile === PowerProfile.PowerSaver)
            return "";
        return "";
    }

    contentItem: iconText
    onClicked: {
        if (PowerProfiles.profile === PowerProfile.PowerSaver) {
            PowerProfiles.profile = PowerProfile.Balanced;
            return;
        }
        if (PowerProfiles.profile === PowerProfile.Balanced) {
            PowerProfiles.profile = PowerProfiles.hasPerformanceProfile ? PowerProfile.Performance : PowerProfile.PowerSaver;
            return;
        }
        PowerProfiles.profile = PowerProfile.PowerSaver;
    }
    onRightClicked: PowerProfiles.profile = PowerProfile.Balanced

    Text {
        id: iconText
        anchors.centerIn: parent
        text: root.icon
        font.family: Config.font
        font.pixelSize: Config.fontSizeNormal
        font.bold: true
        color: Config.textColor
    }
}
