import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "modules"

PanelWindow {
    id: bar
    WlrLayershell.layer: WlrLayer.Overlay
    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    color: "transparent"
    mask: Niri.oview ? on : off
    Region { id: off }
    Region { id: on
        Region { item: timedate }
        Region { item: timedate.calArea }
        Region { item: timedate.holidayArea }
    }
    IpcHandler {
      target: "bar"
      function toggle(): void { bar.visible ^= true }
    }

    property real barSize: 32
    property real margin: 4
    property var  fontColor: "#a9b1d6"
    property var  fontFamily: "Maple Mono NF CN" // different font messes up margins

    Title { anchors.horizontalCenter: parent.horizontalCenter }

    TimeDate { id: timedate }

    Workspaces { anchors.verticalCenter: parent.verticalCenter }

    Statusbar { anchors.right: parent.right }

}
