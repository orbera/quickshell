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
        Region { item: timedate.regions[0] }
        Region { item: timedate.regions[1] }
        Region { item: timedate.regions[2] }
        Region { item: timedate.regions[3]; shape: Region.Ellipse }
        Region { item: systemtray }
    }
    IpcHandler {
      target: "bar"
      function toggle(): void { bar.visible ^= true }
    }

    property real barSize: 32
    property real margin:   4
    property var  fontColor:  "#a9b1d6"
    property var  fontFamily: "Maple Mono NF CN" // different font messes up margins

    Title { anchors.horizontalCenter: parent.horizontalCenter }

    TimeDate { id: timedate }

    Workspaces { anchors.verticalCenter: parent.verticalCenter }

    Statusbar { id: statusbar; anchors.right: parent.right }

    SystemTray { id: systemtray; anchors.left: timedate.right }

}
