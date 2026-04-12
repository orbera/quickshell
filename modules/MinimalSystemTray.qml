import Quickshell
import Quickshell.Services.SystemTray
import QtQuick

Row {
    spacing: margin
    y: margin

    Repeater {
        model: SystemTray.items

        delegate: Rectangle {
            id: trayItem
            width: barSize - margin * 2; height: width
            color: Qt.hsla(0,0,0,2/3)

            TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: modelData.activate()
            }
            TapHandler {
                acceptedButtons: Qt.MiddleButton
                onTapped: modelData.secondaryActivate()
            }
            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: modelData.display(bar, systemtray.x + (parent.width + bar.margin) * index, systemtray.y + parent.height + bar.margin)
            }

            Image {
                anchors.fill: parent
                source: modelData.icon
            }
        }
    }
}
