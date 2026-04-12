import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    implicitHeight: barSize
    implicitWidth: screen.width

    RowLayout {
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: -(winstate.contentWidth + margin * 3) -(winname.width /2)
        width: 0
        spacing: margin

        MyText {
            id: winstate
            text: Niri.focusedWindow?.isFloating ? "floating" : ""
            font.weight: Font.Light
            font.italic: true
        }

        MyText {
            id: winname
            text: initial.elidedText(Niri.focusedWindow?.title ?? "", Text.ElideMiddle, screen.width /2).replace('…', ' ⋯ ')
            font.bold: true
            FontMetrics { id: initial; font.family: winname.font.family; font.pixelSize: winname.font.pixelSize }
        }

        MyText {
            id: winsize
            text: Niri.windowSize ? Niri.windowSize[0] + "x" + Niri.windowSize[1] : ""
            font.weight: Font.Light
        }
    }
}
