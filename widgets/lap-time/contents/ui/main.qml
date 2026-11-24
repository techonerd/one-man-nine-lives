pragma ComponentBehavior: Bound
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: techonerd
// Lap Time Plasma 6 Applet (Break reminder with Casper overlay)

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    function tint(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    // Named colour roles from the active scheme (Window set), the same in light and dark
    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.inherit: false
    readonly property color amberAccent: Kirigami.Theme.highlightColor

    readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    property bool isDark: (0.2126 * Kirigami.Theme.backgroundColor.r + 0.7152 * Kirigami.Theme.backgroundColor.g
                           + 0.0722 * Kirigami.Theme.backgroundColor.b) < 0.5

    // Safe Configuration Access (works inside Plasma and test harness)
    readonly property var config: (typeof Plasmoid !== "undefined" && Plasmoid.configuration) ? Plasmoid.configuration : null

    readonly property bool eyeEnabled: config ? config.eyeEnabled : true
    readonly property int eyeIntervalSec: Math.max(10, (config ? config.eyeIntervalMin : 20) * 60)
    readonly property int eyeLengthSec: Math.max(5, (config ? config.eyeLengthSec : 20))
    readonly property string eyeLabel: (config && config.eyeLabel) ? config.eyeLabel : i18n("Eye break")

    readonly property bool stretchEnabled: config ? config.stretchEnabled : true
    readonly property int stretchIntervalSec: Math.max(30, (config ? config.stretchIntervalMin : 50) * 60)
    readonly property int stretchLengthSec: Math.max(10, (config ? config.stretchLengthMin : 5) * 60)
    readonly property string stretchLabel: (config && config.stretchLabel) ? config.stretchLabel : i18n("Stretch break")

    readonly property int snoozeSec: Math.max(60, (config ? config.snoozeMin : 5) * 60)
    readonly property int maxSnoozes: Math.max(1, (config ? config.maxSnoozes : 3))
    readonly property bool respectDnd: config ? config.respectDnd : true

    // Internal stats fallbacks for test harness
    property int statsWorkSec: config ? config.statsWorkSec : 0
    property int statsBreaksTaken: config ? config.statsBreaksTaken : 0
    property int statsBreaksSkipped: config ? config.statsBreaksSkipped : 0

    // Timers & States
    property int eyeSecRemaining: eyeIntervalSec
    property int stretchSecRemaining: stretchIntervalSec
    property int currentSnoozeCount: 0
    property bool isPaused: false
    property var pauseUntil: null // Date object or null

    // System Environment States
    property bool isScreenLocked: false
    property bool isDndInhibited: false
    property int userIdleMs: 0
    property bool isUserIdle: userIdleMs > 60000 // > 1 minute idle

    // Active Break State
    property string activeBreakType: "" // "" | "eye" | "stretch"

    // Overlay Window Component
    Overlay {
        id: breakOverlay
        snoozeMin: root.config ? root.config.snoozeMin : 5
        maxSnoozes: root.maxSnoozes
        snoozeCount: root.currentSnoozeCount

        onSnoozeRequested: root.snoozeActiveBreak()
        onSkipRequested: root.skipActiveBreak()
        onCompleted: root.completeActiveBreak()
    }

    // ----------------------------------------------------
    // DATA ENGINES (Plasma5Support): Idle Time & Lock/DND
    // ----------------------------------------------------

    // 1. Idle time from the laptime-idle helper (real keyboard/mouse/touch input only;
    //    playing music or video doesn't count as activity). Plasma's own idle time can't be
    //    polled on Wayland, so without the helper Lap Time counts all unlocked time as work.
    property bool idleHelperRunning: false
    Plasma5Support.DataSource {
        id: idleSource
        engine: "executable"
        connectedSources: []
        readonly property string cmd: "cat \"$XDG_RUNTIME_DIR/laptime-idle\" 2>/dev/null || echo missing"

        onNewData: (sourceName, sourceData) => {
            var out = (sourceData["stdout"] || "").trim()
            if (out.indexOf("idle ") === 0) {
                root.idleHelperRunning = true
                root.userIdleMs = Math.max(0, Date.now() - (parseInt(out.substring(5), 10) || Date.now()))
            } else {
                root.idleHelperRunning = (out === "active")
                root.userIdleMs = 0
            }
            // Away for longer than the stretch break: count the break as taken
            if (root.userIdleMs > (root.stretchLengthSec * 1000) && root.activeBreakType === "stretch") {
                root.completeActiveBreak()
            }
            idleSource.disconnectSource(sourceName)
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: idleSource.connectSource(idleSource.cmd)
    }

    // 2. Lock & DND polling via executable engine
    Plasma5Support.DataSource {
        id: execSource
        engine: "executable"
        connectedSources: []

        readonly property string cmdLock6: "qdbus6 org.freedesktop.ScreenSaver /ScreenSaver org.freedesktop.ScreenSaver.GetActive"
        readonly property string cmdDnd6: "qdbus6 org.freedesktop.Notifications /org/freedesktop/Notifications org.freedesktop.DBus.Properties.Get org.freedesktop.Notifications Inhibited"
        readonly property string cmdLock: "qdbus org.freedesktop.ScreenSaver /ScreenSaver org.freedesktop.ScreenSaver.GetActive"
        readonly property string cmdDnd: "qdbus org.freedesktop.Notifications /org/freedesktop/Notifications org.freedesktop.DBus.Properties.Get org.freedesktop.Notifications Inhibited"

        onNewData: (sourceName, sourceData) => {
            var out = (sourceData["stdout"] || "").trim().toLowerCase()
            if (sourceName.indexOf("ScreenSaver") !== -1) {
                root.isScreenLocked = (out === "true")
            } else if (sourceName.indexOf("Notifications") !== -1) {
                root.isDndInhibited = (out === "true")
            }
            execSource.disconnectSource(sourceName)
        }

        function poll() {
            connectSource(cmdLock6)
            connectSource(cmdDnd6)
        }
    }

    Timer {
        id: dbusPollTimer
        interval: 30000 // every 30s
        running: true
        repeat: true
        onTriggered: execSource.poll()
    }

    // ----------------------------------------------------
    // MAIN 1-SECOND TIMER
    // ----------------------------------------------------
    Timer {
        id: clockTicker
        interval: 1000
        running: true
        repeat: true

        onTriggered: {
            // Check daily stats rollover
            root.checkDateRollover()

            // If pause has expired, unpause
            if (root.isPaused && root.pauseUntil) {
                if (new Date() >= root.pauseUntil) {
                    root.isPaused = false
                    root.pauseUntil = null
                }
            }

            // Only count work when not paused, screen is unlocked, and user is active
            var isWorking = !root.isPaused && !root.isScreenLocked && !root.isUserIdle

            // Away from the keyboard for at least a break's length: that break was taken
            if (root.activeBreakType === "") {
                if (root.userIdleMs >= root.eyeLengthSec * 1000)
                    root.eyeSecRemaining = root.eyeIntervalSec
                if (root.userIdleMs >= root.stretchLengthSec * 1000)
                    root.stretchSecRemaining = root.stretchIntervalSec
            }

            if (isWorking && root.activeBreakType === "") {
                // Increment today's work time
                root.addWorkSec(1)

                // Decrement Eye break
                if (root.eyeEnabled) {
                    root.eyeSecRemaining -= 1
                    if (root.eyeSecRemaining <= 0) {
                        root.triggerEyeBreak()
                    }
                }

                // Decrement Stretch break
                if (root.stretchEnabled) {
                    root.stretchSecRemaining -= 1
                    if (root.stretchSecRemaining <= 0) {
                        root.triggerStretchBreak()
                    }
                }
            } else if (root.activeBreakType !== "") {
                // Break is currently active, countdown overlay
                breakOverlay.remainingSec -= 1
                if (breakOverlay.remainingSec <= 0) {
                    root.completeActiveBreak()
                }
            }
        }
    }

    // ----------------------------------------------------
    // BREAK TRIGGERS & ACTIONS
    // ----------------------------------------------------
    function triggerEyeBreak() {
        if (root.respectDnd && root.isDndInhibited) {
            // Silently reset in DND
            root.eyeSecRemaining = root.eyeIntervalSec
            return
        }
        root.activeBreakType = "eye"
        breakOverlay.breakType = "eye"
        breakOverlay.totalSec = root.eyeLengthSec
        breakOverlay.remainingSec = root.eyeLengthSec
        breakOverlay.visible = true
    }

    function triggerStretchBreak() {
        if (root.respectDnd && root.isDndInhibited) {
            // Postpone slightly in DND
            root.stretchSecRemaining = 120
            return
        }
        root.activeBreakType = "stretch"
        breakOverlay.breakType = "stretch"
        breakOverlay.totalSec = root.stretchLengthSec
        breakOverlay.remainingSec = root.stretchLengthSec
        breakOverlay.visible = true
    }

    function completeActiveBreak() {
        if (root.activeBreakType === "eye") {
            root.eyeSecRemaining = root.eyeIntervalSec
        } else if (root.activeBreakType === "stretch") {
            root.stretchSecRemaining = root.stretchIntervalSec
            root.currentSnoozeCount = 0
            root.addBreaksTaken()
        }
        root.activeBreakType = ""
        breakOverlay.visible = false
    }

    function skipActiveBreak() {
        if (root.activeBreakType === "stretch") {
            root.addBreaksSkipped()
            root.stretchSecRemaining = root.stretchIntervalSec
            root.currentSnoozeCount = 0
        } else if (root.activeBreakType === "eye") {
            root.eyeSecRemaining = root.eyeIntervalSec
        }
        root.activeBreakType = ""
        breakOverlay.visible = false
    }

    function snoozeActiveBreak() {
        if (root.activeBreakType === "" || root.currentSnoozeCount >= root.maxSnoozes)
            return
        root.currentSnoozeCount += 1
        if (root.activeBreakType === "eye")
            root.eyeSecRemaining = root.snoozeSec
        else
            root.stretchSecRemaining = root.snoozeSec
        root.activeBreakType = ""
        breakOverlay.visible = false
    }

    function pauseForHours(hours) {
        root.isPaused = true
        var d = new Date()
        d.setHours(d.getHours() + hours)
        root.pauseUntil = d
    }

    function pauseUntilTomorrow() {
        root.isPaused = true
        var d = new Date()
        d.setDate(d.getDate() + 1)
        d.setHours(6, 0, 0, 0)
        root.pauseUntil = d
    }

    function resumeWork() {
        root.isPaused = false
        root.pauseUntil = null
    }

    function addWorkSec(n) {
        root.statsWorkSec += n
        if (root.config) root.config.statsWorkSec = root.statsWorkSec
    }

    function addBreaksTaken() {
        root.statsBreaksTaken += 1
        if (root.config) root.config.statsBreaksTaken = root.statsBreaksTaken
    }

    function addBreaksSkipped() {
        root.statsBreaksSkipped += 1
        if (root.config) root.config.statsBreaksSkipped = root.statsBreaksSkipped
    }

    function checkDateRollover() {
        var today = new Date().toDateString()
        var curDate = root.config ? root.config.statsDate : ""
        if (curDate !== today) {
            if (root.config) root.config.statsDate = today
            root.statsWorkSec = 0
            root.statsBreaksTaken = 0
            root.statsBreaksSkipped = 0
            if (root.config) {
                root.config.statsWorkSec = 0
                root.config.statsBreaksTaken = 0
                root.config.statsBreaksSkipped = 0
            }
        }
    }

    function formatTimeRemaining(sec) {
        if (sec <= 0) return i18n("now")
        var m = Math.floor(sec / 60)
        var s = sec % 60
        if (m === 0) return i18nc("seconds", "%1 s", s)
        return i18nc("minutes and seconds", "%1 min %2 s", m, s)
    }

    function formatHoursMin(totalSec) {
        var h = Math.floor(totalSec / 3600)
        var m = Math.floor((totalSec % 3600) / 60)
        if (h === 0) return i18nc("minutes", "%1 min", m)
        return i18nc("hours and minutes", "%1 h %2 min", h, m)
    }

    // Full representation colors strictly adhering to Tabby & Tweed / Casper Mono
    readonly property color monoFg: Kirigami.Theme.textColor
    readonly property color monoMuted: Kirigami.Theme.disabledTextColor

    // Progress fraction to next break (0.0 to 1.0)
    readonly property real nextBreakFraction: {
        var eyeFrac = 1.0 - (eyeSecRemaining / Math.max(1, eyeIntervalSec))
        var stretchFrac = 1.0 - (stretchSecRemaining / Math.max(1, stretchIntervalSec))
        return Math.max(0.0, Math.min(1.0, Math.max(eyeFrac, stretchFrac)))
    }

    // Tooltip configuration
    toolTipMainText: i18n("Lap Time")
    toolTipSubText: {
        if (root.isPaused && root.pauseUntil) return i18n("Paused until %1", Qt.formatTime(root.pauseUntil, "hh:mm"))
        return i18n("Next %1: %2 | Next %3: %4\nWorked today: %5",
                    root.eyeLabel, root.formatTimeRemaining(root.eyeSecRemaining),
                    root.stretchLabel, root.formatTimeRemaining(root.stretchSecRemaining),
                    root.formatHoursMin(root.statsWorkSec))
    }

    // ----------------------------------------------------
    // COMPACT REPRESENTATION (Panel Icon + Progress Ring)
    // ----------------------------------------------------
    compactRepresentation: MouseArea {
        id: compactRoot
        implicitWidth: Kirigami.Units.gridUnit * 2
        implicitHeight: Kirigami.Units.gridUnit * 2
        hoverEnabled: true

        property bool wasExpanded: false
        onPressed: wasExpanded = root.expanded
        onClicked: root.expanded = !wasExpanded

        // Progress ring canvas
        Canvas {
            id: ringCanvas
            anchors.fill: parent
            anchors.margins: 1

            property real progress: root.nextBreakFraction
            property color ringColor: root.isPaused ? Kirigami.Theme.neutralTextColor : root.amberAccent

            onProgressChanged: requestPaint()
            onRingColorChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                var cx = width / 2
                var cy = height / 2
                var radius = Math.min(cx, cy) - 2

                // Track ring
                ctx.beginPath()
                ctx.arc(cx, cy, radius, 0, 2 * Math.PI)
                ctx.strokeStyle = root.tint(ringColor, 0.2)
                ctx.lineWidth = 2.5
                ctx.stroke()

                // Active progress arc
                if (progress > 0.01) {
                    ctx.beginPath()
                    var startAngle = -Math.PI / 2
                    var endAngle = startAngle + (progress * 2 * Math.PI)
                    ctx.arc(cx, cy, radius, startAngle, endAngle)
                    ctx.strokeStyle = ringColor
                    ctx.lineWidth = 2.5
                    ctx.lineCap = "round"
                    ctx.stroke()
                }
            }
        }

        Kirigami.Icon {
            anchors.centerIn: parent
            width: parent.width - 8
            height: parent.height - 8
            source: "chronometer"
        }
    }

    // ----------------------------------------------------
    // FULL REPRESENTATION (Panel Popup Dialog & Window)
    // ----------------------------------------------------
    fullRepresentation: Item {
        id: popupRoot
        implicitWidth: Kirigami.Units.gridUnit * 20
        implicitHeight: Math.max(Kirigami.Units.gridUnit * 23, popupLayout.implicitHeight + Kirigami.Units.gridUnit * 2)
        Layout.minimumWidth: Kirigami.Units.gridUnit * 18
        Layout.minimumHeight: Kirigami.Units.gridUnit * 20
        Layout.preferredWidth: implicitWidth
        Layout.preferredHeight: implicitHeight

        ColumnLayout {
            id: popupLayout
            anchors.fill: parent
            anchors.margins: Kirigami.Units.gridUnit
            spacing: Kirigami.Units.largeSpacing

            // Header: Title and Status Badge
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: "chronometer"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Layout.preferredWidth
                    isMask: true
                    color: root.monoFg
                }

                PlasmaExtras.Heading {
                    level: 3
                    text: i18n("Lap Time")
                    Layout.fillWidth: true
                    color: root.monoFg
                }

                Rectangle {
                    radius: Kirigami.Units.cornerRadius
                    implicitHeight: statusText.implicitHeight + Kirigami.Units.smallSpacing
                    implicitWidth: statusText.implicitWidth + Kirigami.Units.largeSpacing
                    color: root.isPaused
                        ? root.tint(Kirigami.Theme.neutralTextColor, 0.18)
                        : (root.isUserIdle ? root.tint(Kirigami.Theme.neutralTextColor, 0.18) : root.tint(Kirigami.Theme.positiveTextColor, 0.18))
                    border.color: root.tint(Kirigami.Theme.textColor, 0.12)
                    border.width: 1

                    PlasmaComponents3.Label {
                        id: statusText
                        anchors.centerIn: parent
                        text: root.isPaused ? i18n("Paused") : (root.isUserIdle ? i18n("Idle") : i18n("Tracking"))
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        font.weight: Font.Bold
                        color: root.isPaused
                            ? Kirigami.Theme.neutralTextColor
                            : (root.isUserIdle ? Kirigami.Theme.neutralTextColor : Kirigami.Theme.positiveTextColor)
                    }
                }
            }

            // Warning banner if idle tracking helper is not running
            Kirigami.InlineMessage {
                Layout.fillWidth: true
                type: Kirigami.MessageType.Warning
                visible: !root.idleHelperRunning
                text: i18n("Lap Time can't tell when you're away, so time away counts as work.")
                actions: [
                    Kirigami.Action {
                        text: i18n("How to Fix")
                        icon.name: "help-browser"
                        onTriggered: Qt.openUrlExternally("https://github.com/techonerd/one-man-nine-lives/blob/main/widgets/lap-time/README.md#idle-tracking-laptime-idle-helper")
                    }
                ]
            }

            // Card 1: Eye Break
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: eyeCardLayout.implicitHeight + Kirigami.Units.largeSpacing
                radius: Kirigami.Units.cornerRadius
                clip: true
                color: root.tint(root.monoFg, 0.04)
                border.color: root.tint(Kirigami.Theme.textColor, 0.12)
                border.width: 1

                RowLayout {
                    id: eyeCardLayout
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing * 1.5

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        PlasmaComponents3.Label {
                            text: root.eyeLabel
                            font.weight: Font.Medium
                            color: root.monoFg
                        }

                        PlasmaComponents3.Label {
                            text: root.eyeEnabled ? i18n("in %1", root.formatTimeRemaining(root.eyeSecRemaining)) : i18n("Disabled")
                            color: root.eyeEnabled ? root.monoFg : root.monoMuted
                            font: Kirigami.Theme.smallFont
                        }
                    }

                    PlasmaComponents3.Button {
                        text: i18n("Take Now")
                        enabled: root.eyeEnabled && root.activeBreakType === ""
                        onClicked: root.triggerEyeBreak()
                    }
                }

                // Accent progress indicator along card bottom
                Rectangle {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    height: 2
                    width: parent.width * Math.max(0.0, Math.min(1.0, 1.0 - (root.eyeSecRemaining / Math.max(1, root.eyeIntervalSec))))
                    color: root.amberAccent
                    visible: root.eyeEnabled
                }
            }

            // Card 2: Stretch Break
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: stretchCardLayout.implicitHeight + Kirigami.Units.largeSpacing
                radius: Kirigami.Units.cornerRadius
                clip: true
                color: root.tint(root.monoFg, 0.04)
                border.color: root.tint(Kirigami.Theme.textColor, 0.12)
                border.width: 1

                RowLayout {
                    id: stretchCardLayout
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing * 1.5

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        PlasmaComponents3.Label {
                            text: root.stretchLabel
                            font.weight: Font.Medium
                            color: root.monoFg
                        }

                        PlasmaComponents3.Label {
                            text: root.stretchEnabled ? i18n("in %1", root.formatTimeRemaining(root.stretchSecRemaining)) : i18n("Disabled")
                            color: root.stretchEnabled ? root.monoFg : root.monoMuted
                            font: Kirigami.Theme.smallFont
                        }
                    }

                    PlasmaComponents3.Button {
                        text: i18n("Take Now")
                        enabled: root.stretchEnabled && root.activeBreakType === ""
                        onClicked: root.triggerStretchBreak()
                    }
                }

                // Accent progress indicator along card bottom
                Rectangle {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    height: 2
                    width: parent.width * Math.max(0.0, Math.min(1.0, 1.0 - (root.stretchSecRemaining / Math.max(1, root.stretchIntervalSec))))
                    color: root.amberAccent
                    visible: root.stretchEnabled
                }
            }

            // Quick Pause / Resume Controls
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents3.Button {
                    Layout.fillWidth: true
                    visible: !root.isPaused
                    icon.name: "media-playback-pause"
                    text: i18n("Pause for 1 Hour")
                    onClicked: root.pauseForHours(1)
                }

                PlasmaComponents3.Button {
                    Layout.fillWidth: true
                    visible: !root.isPaused
                    icon.name: "appointment-recurring"
                    text: i18n("Pause Until Tomorrow")
                    onClicked: root.pauseUntilTomorrow()
                }

                PlasmaComponents3.Button {
                    Layout.fillWidth: true
                    visible: root.isPaused
                    icon.name: "media-playback-start"
                    text: i18n("Resume Tracking")
                    highlighted: true
                    onClicked: root.resumeWork()
                }
            }

            Item { Layout.fillHeight: true }

            // Today's Ergonomics Stats
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: statsRowLayout.implicitHeight + Kirigami.Units.largeSpacing
                radius: Kirigami.Units.cornerRadius
                color: root.tint(root.monoFg, 0.04)
                border.color: root.tint(Kirigami.Theme.textColor, 0.12)
                border.width: 1

                RowLayout {
                    id: statsRowLayout
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 2

                        PlasmaExtras.Heading {
                            level: 4
                            Layout.alignment: Qt.AlignHCenter
                            text: root.formatHoursMin(root.statsWorkSec)
                            color: root.monoFg
                        }

                        PlasmaComponents3.Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: i18n("Worked")
                            font: Kirigami.Theme.smallFont
                            color: root.monoMuted
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        color: root.tint(Kirigami.Theme.textColor, 0.12)
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 2

                        PlasmaExtras.Heading {
                            level: 4
                            Layout.alignment: Qt.AlignHCenter
                            text: String(root.statsBreaksTaken)
                            color: root.monoFg
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 2

                            Kirigami.Icon {
                                source: "checkmark"
                                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                Layout.preferredHeight: Layout.preferredWidth
                                color: Kirigami.Theme.positiveTextColor
                                isMask: true
                            }

                            PlasmaComponents3.Label {
                                text: i18n("Taken")
                                font: Kirigami.Theme.smallFont
                                color: root.monoMuted
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        color: root.tint(Kirigami.Theme.textColor, 0.12)
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 2

                        PlasmaExtras.Heading {
                            level: 4
                            Layout.alignment: Qt.AlignHCenter
                            text: String(root.statsBreaksSkipped)
                            color: root.monoFg
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 2

                            Kirigami.Icon {
                                source: "media-skip-forward"
                                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                Layout.preferredHeight: Layout.preferredWidth
                                color: Kirigami.Theme.neutralTextColor
                                isMask: true
                            }

                            PlasmaComponents3.Label {
                                text: i18n("Skipped")
                                font: Kirigami.Theme.smallFont
                                color: root.monoMuted
                            }
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        root.checkDateRollover()
        execSource.poll()
    }
}
