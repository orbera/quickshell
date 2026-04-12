import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: root
    width: parent.width
    height: parent.height
    visible: Niri.oview

    property list<Item> regions: monthGrid.visible ? [monthGrid, holidayDisplay, openGlobe, globe] : [null, null, null, null]

    property point screenpos: { parent.x; parent.y; Window.window?.x; Window.window?.y; return parent.mapToGlobal(0, 0) }
    property real cellSize: (screenpos.x + root.width -margin) /5

    property string holiplace: globe.selected
    property string holiISO: globe.selectediso
    property bool fetching
    property int holidayTick
    FileView {
        path: Quickshell.shellDir + "/holidays.json"
        onAdapterUpdated: writeAdapter()
        onLoadFailed: writeAdapter()
        onLoaded: Qt.callLater(() => { globe.selected = cache.selected || "" })
        JsonAdapter {
            id: cache
            property var data: ({})
            property string selected: ""
        }
    }
    function fetchHolidays(year) {
        if (!holiISO || cache.data?.[holiISO]?.[year]) return
        var country = holiISO
        fetching = true
        const req = new XMLHttpRequest()
        req.open("GET", `https://date.nager.at/api/v3/publicholidays/${year}/${country}`)
        req.onreadystatechange = () => {
            if (req.readyState !== 4) return
            if (req.status !== 200) {
                console.warn("Holiday fetch failed:", req.status, req.responseText)
                fetching = false
                return
            }
            cache.data = Object.assign(cache.data, {
              [country]: Object.assign(cache.data[country] || {}, {
                [year]: JSON.parse(req.responseText)
              })
            })
            console.log("Fetched", country, year)
            holidayTick++
            fetching = false
        }
        req.send()
    }
    property var holidayMap: {
        holidayTick
        const map = {}
        for (const country of Object.values(cache.data ?? {}))
            for (const arr of Object.values(country))
                for (const h of arr)
                    (map[h.date] = map[h.date] ?? []).push(h.localName)
        return map
    }
    function cachedCountries(year) { holidayTick; return Object.keys(cache.data ?? {}).filter(c => cache.data[c]?.[year]) }
    function holidaysOnDate(date) { return [...new Set(holidayMap[date.toISOString().split("T")[0]] ?? [])].join("\n") }
    Connections {
        target: globe
        function onSelectedChanged() { Qt.callLater(() => { cache.selected = globe.selected }) }
    }


    property int firstNdate: 1 -new Date(clock.date.getFullYear(), clock.date.getMonth(), 1).getDay()
    function makeCell(ndate) {
        const fullDate = new Date(clock.date.getFullYear(), clock.date.getMonth(), ndate)
        return {
            ndate,
            fullDate,
            date: fullDate.getDate(),
            month: fullDate.getMonth(),
            year: fullDate.getFullYear()
        }
    }
    property var cellInfo: Array.from({length: 42}, (_, i) => makeCell(firstNdate + i))
    property var hoveredCell: cellInfo[clock.date.getDate() -cellInfo[0].ndate]
    property int hoveredIndex
    signal refresh()
    function resetCalendar() {
        firstNdate = 1 -new Date(clock.date.getFullYear(), clock.date.getMonth(), 1).getDay()
        cellInfo = Array.from({length: 42}, (_, i) => makeCell(firstNdate + i))
        refresh()
    }
    property int currentDay: clock.date.getDate()
    onCurrentDayChanged: resetCalendar()

    property bool overAny: baseArea.hovered || gridArea.hovered || holiArea.hovered || openArea.hovered || globeArea.hovered
    HoverHandler { id: baseArea }
    onOverAnyChanged: {
        if(overAny) { monthGrid.visible = true; cooldown.stop() }
        else { cooldown.restart() }
    }
    Timer {
        id: cooldown
        interval: 600
        onTriggered: monthGrid.visible = false
    }

    GridLayout {
		id: monthGrid
        y: root.height + margin
		rowSpacing: 0
        columnSpacing: 0
        columns: 7
        visible: false

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: wheel => {
                if(wheel.angleDelta.y < 0) {
                    cellInfo = cellInfo.slice(7).concat( [0,1,2,3,4,5,6].map(i => makeCell(firstNdate + 42 + i)) )
                    firstNdate += 7
                }
                else {
                    cellInfo = [0,1,2,3,4,5,6].map(i => makeCell(firstNdate -7 + i)).concat( cellInfo.slice(0, 35) )
                    firstNdate -= 7
                }
                refresh()
            }
        }
        TapHandler { acceptedButtons: Qt.MiddleButton; onTapped: resetCalendar() }
        HoverHandler { id: gridArea }

        Repeater {
            model: 7 * 6

            Item {
                Layout.preferredWidth:  cellSize + margin
                Layout.preferredHeight: cellSize + margin
                property var cell: cellInfo[index]

                Rectangle {
                    anchors.fill: parent
                    anchors.rightMargin: margin
                    anchors.bottomMargin: margin

                    color: Qt.alpha(Qt.darker(fontColor), cell.month == hoveredCell.month ? 3/4 : 1/2)
                    border.width: margin
                    border.color:
                        cell.ndate == clock.date.getDate()    ? color12(cell.month) :
                        cell.ndate == clock.date.getUTCDate() ? Qt.darker(color12(cell.month)) :
                        cell.month == hoveredCell.month       ? fontColor :
                                                                Qt.alpha(Qt.darker(fontColor), 3/4)

                    MyText {
                        x: parent.border.width
                        y: parent.border.width
                        text: cell.date
                        color: cellArea.hovered ? color12(cell.month) : fontColor
                        font.bold: cellArea.hovered
                        opacity: cell.month == hoveredCell.month ? 1 : 3/4
                    }

                    Rectangle {
                        width:  margin * 2
                        height: margin * 2
                        anchors { bottom: parent.bottom; right: parent.right; margins: margin * 2 }
                        border { width: margin /2; color: Qt.darker(color) }
                        color: color12(cell.month)
                        visible: holidaysOnDate(cell.fullDate).length > 0
                    }
                }

                function updateHoveredCell() {
                    if (cellArea.hovered) {
                        hoveredCell = cell
                        hoveredIndex = index
                    }
                }
                HoverHandler { id: cellArea; onHoveredChanged: updateHoveredCell() }
                Connections { target: root; function onRefresh() { updateHoveredCell() } }
            }
        }
    }

    MyText {
        x: (monthGrid.width -width) /2
        y: monthGrid.height + height + margin
        text: Qt.formatDate(hoveredCell.fullDate, "MMMM yyyy")
        color: color12(hoveredCell.month)
        visible: monthGrid.visible
    }

    property string cachedCountriesForYear: {
        holidayTick; holiISO
        return Object.keys(cache.data ?? {})
            .filter(c => cache.data[c]?.[hoveredCell.year])
            .join(", ")
    }
    MyText {
        id: holidayDisplay
        x: monthGrid.width
        y: monthGrid.y + Math.max(0, (monthGrid.height /6) * (((hoveredIndex -hoveredCell.date + 1) /7) |0))
        text:
        (function() {
            if (!holiArea.hovered) {
                return Qt.formatDate(hoveredCell.fullDate, "MMM dd\n") +
                       holidaysOnDate(hoveredCell.fullDate)
            }
            if (fetching) {
                return "fetching..."
            }
            if (holiplace === "") {
                return "select country for holiday fetching..."
            }
            const cached = cachedCountries(hoveredCell.year)
            return (cached.includes(holiISO) ? "" : `click to fetch holidays:\n${hoveredCell.year} (${holiplace})\n`)
                 + (cached.length            ? `cached: ${cached.join(", ")}` : "")
        })()
        font.bold: holiArea.hovered
        visible: monthGrid.visible && !globeArea.hovered

        TapHandler { onTapped: { fetchHolidays(hoveredCell.year) } }
        HoverHandler { id: holiArea }
    }

    property bool globeOn
    Globe {
        id: globe
        x: monthGrid.width + margin*2
        z: -2
        width:  openGlobe.y + openGlobe.height
        height: openGlobe.y + openGlobe.height
        visible: monthGrid.visible && globeOn
        clickable: globeArea.hovered

        HoverHandler { id: globeArea }
    }
    MyText {
        id: openGlobe
        anchors.top: monthGrid.bottom
        anchors.right: monthGrid.right
        anchors.rightMargin: margin
        text: (holiplace == "" && holiArea.hovered) ? "-> 󰇨" : globeOn ? "󰇧" : "󰇨"
        visible: monthGrid.visible

        TapHandler { onTapped: globeOn ^= true }
        HoverHandler { id: openArea }
    }
}
