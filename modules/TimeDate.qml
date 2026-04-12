import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    implicitWidth : layout.width + margin * 2
    implicitHeight: barSize

    property list<Item> regions: calendar.regions

    SystemClock { id: clock; precision: SystemClock.Seconds }

    property date clockdate: Niri.oview ? new Date(clock.date.getTime() + clock.date.getTimezoneOffset() * 60000)
                                        : clock.date
    property color monthColor: Niri.oview ? color12(clockdate.getMonth())
                                          : fontColor
    function color12(n) { return Qt.tint(fontColor, Qt.hsla(n/12, 1, 2/3, 2/3)) }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: margin

        MyText {
            text: clockdate.toTimeString()
        }
            
        MyText {
            text: Qt.formatDate(clockdate, 'ddd <font color="')
                + monthColor
                + Qt.formatDate(clockdate, '">MMM</font>.dd yyyy')
    //      text: clockdate.toDateString()

            PopupCalendar { id: calendar }
        }
    }
}
