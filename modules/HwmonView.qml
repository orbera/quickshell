import QtQuick
import Qt.labs.folderlistmodel
import Quickshell.Io

// based on code by m7moud_el_zayat
Item {
    id: root
    property string nameIncludes
    property string readFile
    property real   value

    function reload() { if (scanner.done) scanner.reload() }

    FolderListModel { id: folders; folder: "file:///sys/class/hwmon" }

    FileView {
        id: scanner
        property int index: 0
        property bool done: false

        path: folders.status === FolderListModel.Ready
            ? `file:///sys/class/hwmon/hwmon${Math.min(index, folders.count - 1)}/${done ? root.readFile : "name"}`
            : ""

        onLoaded: {
            if (done) {
                root.value = Number(text())
            } else if (text().includes(root.nameIncludes)) {
                Qt.callLater(() => { done = true })
            } else if (index < folders.count -1) {
                Qt.callLater(() => ++index)
            }
        }
    }
}
