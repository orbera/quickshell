import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts

Item {
    id: root
    width: statusLayout.width + margin * 2
    height: barSize

    property real cpuPerc
    property real usedMemoryPerc
    property real uptime
    property int  gpuPerc

    property int msInterval: 2000

    RowLayout {
        id: statusLayout
        anchors.centerIn: parent
        spacing: margin

        MyText {
            text: "  "
            Gauge { value: usedMemoryPerc; nCharsBack: 3 }
        }

        MyText {
            text: Math.round(cpuTemp.value /1000) + "°C   "
            Gauge { value: cpuPerc; nCharsBack: 3 }
        }

        MyText {
            text: gpuFan.value + "rpm " + Math.round(gpuTemp.value /1000) + "°C     "
            Gauge { value: gpuPerc /100; nCharsBack: 4 }
            MyText {
                text: "󰢮"
                anchors.right: parent.right
                font.pixelSize: parent.font.pixelSize * 3/2
                y: (parent.font.pixelSize - font.pixelSize) /(5/3)
                bgopacity: 0
            }
            color: gpuTemp.value > gpuCritTemp.value ? "red" : fontColor
        }
    }

    function pad(n) { return n.toString().padStart(2, "0") }
    MyText {
        x: screen.width/2 -parent.x -width/2
        y: margin -parent.y
        text: Math.floor(uptime /3600) + ":" + pad(Math.floor(uptime /60) % 60) + ":" + pad(Math.floor(uptime) % 60)
        visible: Niri.oview
    }

    SystemClock { precision: SystemClock.Seconds; onSecondsChanged: procUptime.reload() }

    component Arc: Shape {
        id: pieShape
        width: parent.height; height: width
        layer.enabled: true
        layer.samples: 4
        preferredRendererType: Shape.CurveRenderer
        property real sweep: 1
        property alias color: shape.strokeColor
        ShapePath {
            id: shape
            fillColor: "transparent"
            strokeColor: fontColor
            strokeWidth: barSize /9
            capStyle: ShapePath.FlatCap
            PathAngleArc {
                centerX: pieShape.width /2; centerY: centerX
                radiusX: pieShape.width /4; radiusY: radiusX
                startAngle: 90
                sweepAngle: sweep * 360
                moveToStart: true
            }
        }
    }

    component Gauge: Item {
        width: parent.width
        height: parent.height
        property alias value: valueArc.sweep
        property int nCharsBack
        TextEdit {
            id: check
            text: parent.parent.text
            font: parent.parent.font
            leftPadding: parent.parent.leftPadding
            rightPadding: parent.parent.rightPadding
            visible: false
        }
        readonly property int c: check.text.length - nCharsBack
        readonly property real arcX: (3 * check.positionToRectangle(Math.min(c,     check.length)).x
                                         -check.positionToRectangle(Math.min(c + 1, check.length)).x) /2
        Arc { x: arcX; color: Qt.alpha(Qt.darker(fontColor), 1/3) }
        Arc { x: arcX; id: valueArc }
    }

    Timer {
        interval: root.msInterval
        running: true
        repeat: true
        onTriggered: {
            procStat.reload()
            procMemInfo.reload()
            procGpu.reload()
            cpuTemp.reload()
            gpuTemp.reload()
            gpuCritTemp.reload()
            gpuFan.reload()
        }
    }

// current values only work for amd gpus
    FileView {
        id: procGpu
        path: "file:///sys/class/drm/card1/device/gpu_busy_percent"
        onLoaded: gpuPerc = parseInt(text())
    }
    HwmonView { id: gpuTemp;     nameIncludes: "amdgpu"; readFile: "temp1_input" }
    HwmonView { id: gpuCritTemp; nameIncludes: "amdgpu"; readFile: "temp1_crit"  }
    HwmonView { id: gpuFan;      nameIncludes: "amdgpu"; readFile: "fan1_input"  }

    HwmonView { id: cpuTemp;     nameIncludes: "temp";   readFile: "temp3_input" }

// all below based on code by m7moud_el_zayat
    FileView {
        id: procStat
        path: "file:///proc/stat"
        property real lastCpuIdle
        property real lastCpuTotal
        onLoaded: {
            const cpuTimes = text().split(' ').slice(2, 9).map(Number)
            const idle  = cpuTimes[3] + cpuTimes[4]
            const total = cpuTimes.reduce((a, b) => a + b, 0)
            const idleDiff  = idle  -lastCpuIdle
            const totalDiff = total -lastCpuTotal
            root.cpuPerc = lastCpuTotal > 0 && totalDiff > 0 ? 1 -idleDiff/totalDiff : 0
            lastCpuIdle  = idle
            lastCpuTotal = total
        }
    }
    FileView {
        id: procMemInfo
        path: "file:///proc/meminfo"
        onLoaded: {
            const m = text().split('\n').map(line => parseInt(line.split(':')[1]))
            root.usedMemoryPerc = 1 -m[2]/m[0]
        }
    }
    FileView {
        id: procUptime
        path: "file:///proc/uptime"
        onLoaded: root.uptime = parseInt(text())
    }
}
