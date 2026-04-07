import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root
    width: parent.width
    height: parent.height

    property alias calArea: calArea // pass up the extra regions -> shell.qml
    property alias holidayArea: holidayArea

    property point screenpos: { // get screenspace position of parent's top left point
        parent.x; parent.y
        Window.window?.x; Window.window?.y
        return parent.mapToGlobal(0, 0)
    }
    
    function mod(a, b) { return a -b * Math.floor(a /b) } // need this for a % -b
    function sw(x, a, b) { return (x > a && x < b ) } // sandwich (a < x < b)

    function doi(i) { // date of index
        var offset = mod(mod(clock.date.getDate(), 7) - clock.date.getDay(), -7) - clock.date.getDate() + i + shift
        return new Date(clock.date.getFullYear(), clock.date.getMonth(), clock.date.getDate() + offset)
    }

    property date hoveredDate: clock.date
    property int vHoveredMonth: temp
    property int temp

    property string holiplace: "US" // manually set in this file for now
    property var holidays: { holidayTick; return Object.values(cache.data ?? {}).reduce((acc, arr) => acc.concat(arr), []) }
    property int holidayTick
    property var cachedYears: Object.keys(cache.data ?? {})
    property bool fetching
    FileView {
        path: Quickshell.shellDir + "/holidays.json"
        onAdapterUpdated: writeAdapter()
        onLoadFailed: writeAdapter()
        JsonAdapter {
            id: cache
            property var data: ({})
        }
    }
    function fetchHolidays(year) {
        const cached = cache.data?.[year]
        if (cached) { return }
        const req = new XMLHttpRequest()
        req.open("GET", `https://date.nager.at/api/v3/PublicHolidays/${year}/${holiplace}`)
        req.onreadystatechange = () => {
            if (req.readyState === 4) {
                const data = JSON.parse(req.responseText)
                cache.data = Object.assign({}, cache.data ?? {}, { [year]: data })
                holidayTick++
                fetching = false
            } console.log(data)
        }
        req.send()
        fetching = true
    }
    function isHoliday(date) {
        const iso = date.toISOString().split("T")[0]
        return holidays.some(h => h.date === iso)
    }
    function holidaysOnDate(date) {
        const iso = date.toISOString().split("T")[0]
        return holidays
            .filter(h => h.date === iso)
            .map(h => h.localName)
            .join("\n")
    }

    property int overAny
    onOverAnyChanged: {
        if (overAny) { calOn = true; countdown.stop() }
        else { countdown.restart() }
    }
    HoverHandler { onHoveredChanged: {overAny += hovered ? 1 : -1; refresh()} } // root copies parent's dimensions, this
    Timer {                                                                     // enables the calendar on hovering it
        id: countdown
        interval: 500
        onTriggered: calOn = false
    }
    property bool calOn
    property int shift

    signal refresh() // to update dayBox HoverHandler logic via Connections when onHoveredChanged doesn't trigger

    Rectangle {
        id: container
        width: parent.width + (screenpos.x -margin) // this makes the calendar bigger based on
        y: parent.height + margin                   // how far to the right the praent is
        visible: Niri.oview

        Item {
            id: calArea
            width: dateLayout.implicitWidth * calOn
            height: dateLayout.implicitHeight * calOn
            HoverHandler { onHoveredChanged: overAny += hovered ? 1 : -1 }
            WheelHandler { // scroll the calendar by shifting rawdate with root.shift
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: wheel => {
                    shift += wheel.angleDelta.y < 0 ? 7 : -7
                    refresh()
                }
            }
            TapHandler {
                acceptedButtons: Qt.MiddleButton
                onTapped: { shift = 0; refresh() }
            }
        }
        
        GridLayout {
            id: dateLayout
            rowSpacing: margin
            columnSpacing: margin
            columns: 7
            visible: (calOn == true)
            
            Repeater {
                id: grid
                model: 7 * 6
            
                Item {
                    width: container.width /5  // /n -> n squares = distance from screen left to parent right
                    height: container.width /5

                    property int rawdate: index + mod(mod(clock.date.getDate(), 7) -clock.date.getDay(), -7) + shift
                    // rawdate is a numberline where 1 = start of this month
                    Rectangle {
                        id: box
                        anchors.fill: parent
                        color: box.v(rawdate) == vHoveredMonth ? Qt.alpha(Qt.darker(fontColor), 3/4)
                                                                : Qt.alpha(Qt.darker(fontColor), 1/2)
                        border.width: margin
                        border.color: rawdate == clock.date.getDate() ? Qt.alpha(monthcolor, 3/4) :
                                      rawdate == clockdate.getDate() ? Qt.darker(Qt.alpha(monthcolor, 3/4)) : // UTC date
                                      box.v(rawdate) == vHoveredMonth ?
                                      Qt.alpha(fontColor, 3/4) :
                                      Qt.alpha(Qt.darker(fontColor), 1/4)
                        function v(d) { return index -new Date(clock.date.getFullYear(), clock.date.getMonth(), d).getDate() }
                        // idk how this works but it returns a different value for different months
                        MyText {
                            id: dateNumber
                            x: parent.border.width
                            y: parent.border.width
                            text: new Date(clock.date.getFullYear(), clock.date.getMonth(), rawdate).getDate()
                            opacity: box.v(rawdate) == vHoveredMonth ? 1 : 3/4
                            color: dayBox.hovered ? color12(new Date(clock.date.setDate(rawdate)).getMonth()) : fontColor
                            font.bold: dayBox.hovered                            
                        }

                        MyText {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.rightMargin: parent.border.width
                            anchors.bottomMargin: parent.border.width
                            font.pixelSize: dateNumber.font.pixelSize * 5/8
                            bgheight: dateNumber.bgheight * 5/8
                            bgopacity: 1/2
                            text: Qt.locale().dayName(mod(index, 7), Locale.ShortFormat)
                            visible: index < 7
                        }

                        Rectangle { // isHoliday indicator
                            width: margin * 2
                            height: margin * 2
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.margins: margin * 2
                            border.width: margin / 2
                            border.color: Qt.darker(color)
                            color: color12(new Date(clock.date.setDate(rawdate)).getMonth())
                            visible: isHoliday(doi(index))
                        }
                    }
                    Item {
                        width: parent.width   // i wish i could make this bigger, but
                        height: parent.height // the hover state gets more unreliable
                        HoverHandler {
                            id: dayBox
                            onHoveredChanged: {
                                overAny += hovered ? 1 : -1
                                hoveredDate = doi(index)
                                vHoveredMonth = box.v(rawdate)
                            }
                        }
                        Connections {
                            target: root
                            function onRefresh() {
                                if (dayBox.hovered) {
                                    hoveredDate = doi(index)
                                    vHoveredMonth = box.v(rawdate)
                                } else {
                                    temp = index - rawdate // initialize vHoveredMonth via temp with v(current day)
                                }
                            }
                        }
                    }
                }
            }

            MyText {
                id: month
                Layout.columnSpan: 7
                Layout.alignment: Qt.AlignHCenter
                text: Qt.locale().monthName(hoveredDate.getMonth()) + " " + hoveredDate.getFullYear()
                color: color12(hoveredDate.getMonth())
            }            
        }
        
        MyText {
            id: holidayArea
            x: dateLayout.width + margin
            text: holiday.hovered ?
                      fetching ?
                          "fetching..."
                      :   cachedYears.includes(String(hoveredDate.getFullYear())) ?
                              "already cached!"
                          :   "fetch " + holiplace + " holidays for " + hoveredDate.getFullYear()
                  :   Qt.formatDate(hoveredDate, "MMM dd") + "\n" + holidaysOnDate(hoveredDate)
            font.underline: holiday.hovered
            visible: dateLayout.visible
            HoverHandler { id: holiday; onHoveredChanged: overAny += hovered ? 1 : -1 }
            TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: { fetchHolidays(hoveredDate.getFullYear()) }
            }
            onTextChanged: { opacity = 1; fadeTimer.restart() }
            Timer { id: fadeTimer; interval: 4000; onTriggered: holidayArea.opacity = 0 }
            Behavior on opacity { NumberAnimation { duration: 400 } }
        }
    }
}
