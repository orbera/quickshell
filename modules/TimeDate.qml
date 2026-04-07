import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    implicitWidth : layout.width + margin * 2
    implicitHeight: barSize

    property alias calArea: calArea.calArea
    property alias holidayArea: calArea.holidayArea

    SystemClock { id: clock; precision: SystemClock.Seconds }

    property date clockdate: Niri.oview ? new Date(clock.date.getTime() + clock.date.getTimezoneOffset() * 60000)
                                        : clock.date
    property color monthcolor: Niri.oview ? color12(clockdate.getMonth())
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
                + monthcolor
                + Qt.formatDate(clockdate, '">MMM</font>.dd yyyy')
    //      text: clockdate.toDateString()

            PopupCalendar { id: calArea }
        }
    }
}
