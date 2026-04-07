import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

// generalized form of code by m7moud_el_zayat
Item {
    id: root
    property alias msInterval: timer.interval
    property alias nameIncludes: fileview.nameIncludes
    property alias readFile: fileview.readFile
    property real value

    FolderListModel { id: folderListModel; folder: "file:///sys/class/hwmon" }

    FileView {
        id: fileview
        property int index: 0
        property bool done: false

        property string fileName: "name"
        property string nameIncludes
        property string readFile

        path: folderListModel.status === FolderListModel.Ready ? `file:///sys/class/hwmon/hwmon${Math.min(index, folderListModel.count - 1)}/${fileName}` : ""

        onLoaded: {
            if (!done) {
                if (text().includes(nameIncludes)) {
                    Qt.callLater(() => {
                        done = true;
                        fileName = readFile;
                    });
            } else if (index < folderListModel.count - 1)
                Qt.callLater(() => ++index);
            } else
                root.value = Number(text());
        }
    }
    
    Timer {
        id: timer
        running: true
        repeat: true

        onTriggered: fileview.reload()
    }
}
