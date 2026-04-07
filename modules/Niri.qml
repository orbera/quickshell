
pragma Singleton
import Quickshell
import QtQuick
import Niri 0.1
import Quickshell.Io

Singleton {
    id: root

    readonly property var focusedWindow: niri.focusedWindow
    readonly property var workspaces: niri.workspaces
    property var windowSize // -> Title.qml
    property bool oview // -> TimeDate.qml

    Niri {
        id: niri
        Component.onCompleted: connect()
        onErrorOccurred: error => console.error("Niri error:", error)
        onRawEventReceived: event => {
            const key = Object.keys(event)[0]
            if (["WindowFocusChanged", "WindowLayoutsChanged",
                 "WindowOpenedOrChanged", "WindowsChanged"].includes(key)) {
                windowSocket.write('"FocusedWindow"\n')
            }
            if (key === "OverviewOpenedOrClosed") {
                overviewSocket.write('"OverviewState"\n')
            }
        }
    }

    Socket {
        id: windowSocket // -> Title.qml
        path: Quickshell.env("NIRI_SOCKET")
        connected: true
        parser: SplitParser {
            onRead: data => {
                try {
                    root.windowSize = JSON.parse(data)?.Ok?.FocusedWindow?.layout?.window_size
                } catch (e) { console.log("windowSocket parse error:", e) }
            }
        }
    }

    Socket {
        id: overviewSocket // -> TimeDate.qml
        path: Quickshell.env("NIRI_SOCKET")
        connected: true
        parser: SplitParser {
            onRead: data => {
                try {
                    root.oview = JSON.parse(data)?.Ok?.OverviewState?.is_open ?? false
                } catch (e) { console.log("overviewSocket parse error:", e) }
            }
        }
    }
}
