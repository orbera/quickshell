import Quickshell
import QtQuick

Text {
    id: parentText
    color: fontColor
    font.pixelSize: barSize * 25/33 - margin * 3/2 // not universal
    font.family: fontFamily
    leftPadding: margin
    rightPadding: margin

    property alias bgopacity: bg.opacity
    property alias bgheight: bg.height

    Rectangle {
        id: bg
        anchors.centerIn: parent
        width: parent.width * (text.length != 0)
        height: parent.lineCount * (barSize - margin * 2)
        z: - 1
        color: Qt.hsla(0,0,0,2/3)
    }
}
