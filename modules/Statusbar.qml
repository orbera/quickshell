import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    width: statusLayout.width + margin * 2
    height: barSize

    property real cpuPerc
    property real usedMemory
    property real totalMemory
    property real usedMemoryPerc
    property real uptime

    property int gpuPercent
    property int msInterval: 2000

    RowLayout {
        id: statusLayout
        anchors.centerIn: parent
        spacing: margin

        MyText {
            text: Math.round(usedMemoryPerc * 100) + "% "
                + ""
        }

        MyText {
            text: Math.round(cpuPerc * 100) + "% "
                + Math.round(cpuTemp.value / 1000) + "°C "
                + ""
        }

        MyText {
            text: gpuPercent + "% "
                + Math.round(gpuTemp.value / 1000) + "°C "
                + gpuFan.value + "rpm   "
            MyText {
                text: "󰢮"
                anchors.right: parent.right
                font.pixelSize: parent.font.pixelSize * 3/2
                y: (parent.font.pixelSize - font.pixelSize) / 2
                bgopacity: 0
            }
            color: (gpuTemp.value < gpuCritTemp.value) ? fontColor : "red"
        }
    }

    SystemClock { precision: SystemClock.Seconds; onSecondsChanged: procUptime.reload() }
    function pad(n){ var padded = n.toString().padStart(2, "0"); return padded; }
    MyText {
        x: (screen.width / 2) - parent.x - (width / 2)
        y: margin - parent.y
        text: Math.floor(uptime/3600) + ":" + pad(Math.floor(uptime/60) % 60) + ":" + pad(Math.floor(uptime) % 60)
        visible: Niri.oview
    }

    HwmonView {
        id: cpuTemp
        msInterval: root.msInterval
        nameIncludes: "temp"
        readFile: "temp3_input"
    }
/*! HwmonView {  // enable temperature control in bios
        id: cpuCritTemp
        msInterval: root.msInterval
        nameIncludes: "temp"
        readFile: "temp3_crit"
    } */

    // current values only work for amd
    
    FileView {
        id: procGpu
        path: "/sys/class/drm/card1/device/gpu_busy_percent"
        onLoaded: gpuPercent = this.text()
    }

    HwmonView {
        id: gpuTemp
        msInterval: root.msInterval
        nameIncludes: "amdgpu"
        readFile: "temp1_input"
    }
    HwmonView {
        id: gpuCritTemp
        msInterval: root.msInterval
        nameIncludes: "amdgpu"
        readFile: "temp1_crit"
    }

    HwmonView {
        id: gpuFan
        msInterval: root.msInterval
        nameIncludes: "amdgpu"
        readFile: "fan1_input"
    }

    // all below by m7moud_el_zayat

    Timer {
        interval: root.msInterval
        running: true
        repeat: true

        onTriggered: {
            procStat.reload();
            procMemInfo.reload();
            procGpu.reload()
        }
    }

    // Real-time CPU Usage
    FileView {
        id: procStat
        path: "file:///proc/stat"

        property real lastCpuIdle
        property real lastCpuTotal

        onLoaded: {
            const cpuTimes = text().split(' ').slice(2, 9).map(Number);

            const idle = cpuTimes[3] + cpuTimes[4];
            const total = cpuTimes.reduce((acc, cur) => acc + cur, 0);

            const idleDiff = idle - lastCpuIdle;
            const totalDiff = total - lastCpuTotal;

            root.cpuPerc = lastCpuTotal > 0 && totalDiff > 0 ? 1 - idleDiff / totalDiff : 0;

            lastCpuIdle = idle;
            lastCpuTotal = total;
        }
    }

    // Memory Usage
    FileView {
        id: procMemInfo
        path: "file:///proc/meminfo"

        onLoaded: {
            const memNumbers = text().split('\n').map(m => parseInt(m.split(':')[1]));

            root.totalMemory = memNumbers[0] / (1024 * 1024)
            root.usedMemory = (memNumbers[0] - memNumbers[2]) / (1024 * 1024);
            root.usedMemoryPerc = 1 - memNumbers[2] / memNumbers[0]
        }
    }

    // Uptime
    FileView {
        id: procUptime
        path: "file:///proc/uptime"

        onLoaded: root.uptime = parseInt(text())
    }
}
