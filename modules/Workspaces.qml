import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    x: margin
    width: workspaceLayout.implicitWidth

    property int boxSize: (barSize + 2) - (margin * 3)
    property real borderRatio: 1/3
    property real inactiveRatio: 3/4

    ColumnLayout {
        id: workspaceLayout
        anchors.centerIn: parent
        spacing: margin
        visible: Niri.workspaces.count != 2

        Repeater {
            model: Niri.workspaces

            Item {
                width: boxSize
                height: boxSize
                visible: index != Niri.workspaces.count

                Rectangle {
                    anchors.centerIn: parent
                    width:   model.isActive ? boxSize : boxSize * inactiveRatio
                    height:  model.isActive ? boxSize : boxSize * inactiveRatio
                    opacity: model.isActive ? 7/8 : 1/2
                    color:        model.isActive ? Qt.darker(fontColor) : fontColor
                    border.color: model.isActive ? fontColor : Qt.darker(fontColor)
                    border.width: boxSize * (borderRatio / 2)
                }
            }
        }
    }
}
