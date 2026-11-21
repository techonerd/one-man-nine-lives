/*
 * Whiskers - senses trouble before it lands.
 * Plasma 6 front end for the whiskers CLI (One Man Nine Lives suite).
 * Colours come from the active Plasma colour scheme, so it follows light and dark themes.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property string bin: '"$HOME/.local/bin/whiskers"'
    property var report: null
    property var events: []
    property bool busy: false
    property string lastError: ""
    property var pending: ({})

    readonly property string level: report ? report.level : "unknown"
    readonly property int problems: report ? report.problems : 0
    readonly property string symbolicIcon: Qt.resolvedUrl("../icons/whiskers-symbolic.svg")
    readonly property string appIcon: Qt.resolvedUrl("../icons/whiskers.svg")

    Plasmoid.icon: "whiskers"
    Plasmoid.status: level === "error" ? PlasmaCore.Types.NeedsAttentionStatus
                   : level === "warn" ? PlasmaCore.Types.ActiveStatus
                   : PlasmaCore.Types.PassiveStatus

    toolTipMainText: i18n("Whiskers")
    toolTipSubText: busy ? i18n("Checking…") : lastError !== "" ? lastError : headline()

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Check Now")
            icon.name: "view-refresh"
            enabled: !root.busy
            onTriggered: root.refresh()
        }
    ]

    function headline() {
        if (!report) return i18n("Senses trouble before it lands")
        if (problems === 0) return i18n("All quiet. Casper approves.")
        return i18np("1 thing needs your attention", "%1 things need your attention", problems)
    }

    function tint(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    function levelColor(l) {
        return l === "error" ? Kirigami.Theme.negativeTextColor
             : l === "warn" ? Kirigami.Theme.neutralTextColor
             : l === "info" ? Kirigami.Theme.linkColor
             : Kirigami.Theme.positiveTextColor
    }
    function levelIcon(l) {
        return l === "error" ? "data-error" : l === "warn" ? "data-warning"
             : l === "info" ? "data-information" : "checkmark"
    }
    function ago(t) {
        const s = Math.max(0, Math.floor(Date.now() / 1000) - t)
        if (s < 90) return i18n("just now")
        if (s < 3600) return i18np("1 minute ago", "%1 minutes ago", Math.floor(s / 60))
        if (s < 86400) return i18np("1 hour ago", "%1 hours ago", Math.floor(s / 3600))
        return Qt.formatDateTime(new Date(t * 1000), "ddd hh:mm")
    }

    // ------------------------------------------------------------ process runner
    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            disconnectSource(source)
            const cb = root.pending[source]
            delete root.pending[source]
            if (cb) cb(data["exit code"], data["stdout"] || "", data["stderr"] || "")
        }
    }
    function run(cmd, cb) {
        pending[cmd] = cb
        exec.connectSource(cmd)
    }

    function refresh() {
        if (busy) return
        busy = true
        run(bin + " status --json", (code, out, err) => {
            busy = false
            if (code === 0) {
                try { report = JSON.parse(out); lastError = "" }
                catch (e) { lastError = i18n("Whiskers gave an unreadable answer") }
            } else if (code === 127) {
                lastError = i18n("The whiskers command isn't installed. Run install.sh from the suite.")
            } else {
                lastError = err.trim() || i18n("whiskers stopped with code %1", code)
            }
            rebuild()
        })
        refreshEvents()
    }
    function refreshEvents() {
        run(bin + " events --json", (code, out) => {
            if (code !== 0) return
            try { events = JSON.parse(out) } catch (e) { events = [] }
            rebuild()
        })
    }

    // One flat model with sections: what needs you, what happened, notes, what's fine
    ListModel { id: rows }
    function rebuild() {
        rows.clear()
        const recs = report ? report.records : []
        const add = (section, compact, r, time) => rows.append({
            section: section, compact: compact, level: r.level || "info", title: r.title || "",
            summary: r.summary || "", fix: r.fix || "", detail: r.detail || "", time: time || 0 })
        recs.filter(r => r.level === "error" || r.level === "warn").forEach(r => add(i18n("Needs your attention"), false, r, 0))
        const dayAgo = Date.now() / 1000 - 2 * 86400
        events.filter(e => e.time > dayAgo).slice(0, 8).forEach(e => add(i18n("What happened recently"), false, e, e.time))
        recs.filter(r => r.level === "info").forEach(r => add(i18n("Good to know"), false, r, 0))
        recs.filter(r => r.level === "ok").forEach(r => add(i18n("All good"), true, r, 0))
    }

    Timer {
        interval: Math.max(5, Plasmoid.configuration.refresh_minutes) * 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
    Timer {          // the live watch writes events as they happen; pick them up quickly
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.refreshEvents()
    }
    onExpandedChanged: {
        if (root.expanded) root.refreshEvents()
    }

    TextEdit { id: clipboardHelper; visible: false }
    function copyText(t) {
        clipboardHelper.text = t
        clipboardHelper.selectAll()
        clipboardHelper.copy()
    }

    // ------------------------------------------------------------ panel / tray icon
    compactRepresentation: MouseArea {
        id: compact
        property bool wasExpanded: false
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onPressed: wasExpanded = root.expanded
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) root.refresh()
            else root.expanded = !wasExpanded
        }
        Kirigami.Icon {
            anchors.fill: parent
            source: root.symbolicIcon
            isMask: true
            color: Kirigami.Theme.textColor
            active: compact.containsMouse
        }
        Rectangle {
            visible: root.busy || root.level === "warn" || root.level === "error"
            width: Math.round(Math.min(parent.width, parent.height) * 0.42)
            height: width
            radius: width / 2
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            color: root.busy ? Kirigami.Theme.disabledTextColor : root.levelColor(root.level)
            border.color: Kirigami.Theme.backgroundColor
            border.width: 1
        }
    }

    // ------------------------------------------------------------ popup
    fullRepresentation: PlasmaExtras.Representation {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 22
        Layout.minimumHeight: Kirigami.Units.gridUnit * 16
        Layout.preferredWidth: Kirigami.Units.gridUnit * 28
        Layout.preferredHeight: Kirigami.Units.gridUnit * 30
        collapseMarginsHint: true

        header: PlasmaExtras.PlasmoidHeading {
            RowLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.largeSpacing
                Kirigami.Icon {
                    source: root.appIcon
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                }
                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true
                    PlasmaExtras.Heading {
                        level: 3
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: root.busy && !root.report ? i18n("Checking…") : root.headline()
                    }
                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        opacity: 0.7
                        font: Kirigami.Theme.smallFont
                        text: !root.report ? i18n("Whiskers")
                            : i18n("Checked %1 · live watch %2", root.ago(root.report.checked_at),
                                   root.report.watching ? i18n("on") : i18n("off"))
                    }
                }
                PlasmaComponents.BusyIndicator {
                    visible: root.busy
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                }
                PlasmaComponents.ToolButton {
                    icon.name: "view-refresh"
                    enabled: !root.busy
                    display: PlasmaComponents.AbstractButton.IconOnly
                    text: i18n("Check now")
                    onClicked: root.refresh()
                    PlasmaComponents.ToolTip.text: text
                    PlasmaComponents.ToolTip.visible: hovered
                }
                PlasmaComponents.ToolButton {
                    icon.name: "configure"
                    display: PlasmaComponents.AbstractButton.IconOnly
                    text: i18n("Settings")
                    onClicked: Plasmoid.internalAction("configure").trigger()
                    PlasmaComponents.ToolTip.text: text
                    PlasmaComponents.ToolTip.visible: hovered
                }
            }
        }

        PlasmaComponents.ScrollView {
            anchors.fill: parent
            contentWidth: availableWidth

            contentItem: ListView {
                id: list
                model: rows
                clip: true
                spacing: Kirigami.Units.smallSpacing
                topMargin: Kirigami.Units.largeSpacing
                bottomMargin: Kirigami.Units.largeSpacing
                leftMargin: Kirigami.Units.largeSpacing
                rightMargin: Kirigami.Units.largeSpacing

                section.property: "section"
                section.delegate: PlasmaExtras.Heading {
                    required property string section
                    level: 5
                    width: ListView.view.width - ListView.view.leftMargin - ListView.view.rightMargin
                    topPadding: Kirigami.Units.largeSpacing
                    bottomPadding: Kirigami.Units.smallSpacing
                    opacity: 0.75
                    text: section
                }

                delegate: Rectangle {
                    id: card
                    required property string level
                    required property string title
                    required property string summary
                    required property string fix
                    required property string detail
                    required property bool compact
                    required property real time

                    width: ListView.view.width - ListView.view.leftMargin - ListView.view.rightMargin
                    implicitHeight: body.implicitHeight + Kirigami.Units.largeSpacing * (compact ? 1 : 2)
                    radius: Kirigami.Units.cornerRadius
                    color: compact ? "transparent" : root.tint(Kirigami.Theme.textColor, 0.05)
                    border.width: compact ? 0 : 1
                    border.color: root.tint(Kirigami.Theme.textColor, 0.08)

                    Rectangle {          // level accent
                        visible: !card.compact
                        width: 3
                        radius: 1.5
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: Kirigami.Units.smallSpacing }
                        color: root.levelColor(card.level)
                    }

                    ColumnLayout {
                        id: body
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                        anchors.leftMargin: Kirigami.Units.largeSpacing + (card.compact ? 0 : Kirigami.Units.smallSpacing)
                        anchors.rightMargin: Kirigami.Units.largeSpacing
                        spacing: Kirigami.Units.smallSpacing

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing
                            Kirigami.Icon {
                                source: root.levelIcon(card.level)
                                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                                Layout.alignment: Qt.AlignTop
                            }
                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: card.title
                                font.weight: card.compact ? Font.Normal : Font.DemiBold
                                wrapMode: card.compact ? Text.NoWrap : Text.Wrap
                                elide: Text.ElideRight
                            }
                            PlasmaComponents.Label {
                                visible: card.time > 0
                                text: root.ago(card.time)
                                opacity: 0.6
                                font: Kirigami.Theme.smallFont
                            }
                        }
                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            Layout.leftMargin: Kirigami.Units.iconSizes.small + Kirigami.Units.smallSpacing
                            visible: card.summary !== ""
                            text: card.summary
                            wrapMode: card.compact ? Text.NoWrap : Text.Wrap
                            elide: Text.ElideRight
                            maximumLineCount: card.compact ? 1 : 6
                            opacity: 0.8
                            font: Kirigami.Theme.smallFont
                        }
                        RowLayout {
                            visible: card.fix !== "" && !card.compact
                            Layout.fillWidth: true
                            Layout.leftMargin: Kirigami.Units.iconSizes.small + Kirigami.Units.smallSpacing
                            spacing: Kirigami.Units.smallSpacing
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: fixText.implicitHeight + Kirigami.Units.smallSpacing * 2
                                radius: Kirigami.Units.cornerRadius
                                color: root.tint(Kirigami.Theme.textColor, 0.07)
                                PlasmaComponents.Label {
                                    id: fixText
                                    anchors.fill: parent
                                    anchors.margins: Kirigami.Units.smallSpacing
                                    text: card.fix
                                    textFormat: Text.PlainText
                                    wrapMode: Text.WrapAnywhere
                                    font.family: "monospace"
                                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                                }
                            }
                            PlasmaComponents.ToolButton {
                                icon.name: "edit-copy"
                                display: PlasmaComponents.AbstractButton.IconOnly
                                text: i18n("Copy")
                                Layout.alignment: Qt.AlignTop
                                onClicked: root.copyText(card.fix)
                                PlasmaComponents.ToolTip.text: i18n("Copy command")
                                PlasmaComponents.ToolTip.visible: hovered
                            }
                        }
                        PlasmaComponents.Label {
                            Layout.fillWidth: true
                            Layout.leftMargin: Kirigami.Units.iconSizes.small + Kirigami.Units.smallSpacing
                            visible: card.detail !== "" && !card.compact
                            text: card.detail
                            textFormat: Text.PlainText
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            opacity: 0.5
                            font: Kirigami.Theme.smallFont
                        }
                    }
                }
            }
        }

        PlasmaExtras.PlaceholderMessage {
            anchors.centerIn: parent
            width: parent.width - Kirigami.Units.gridUnit * 4
            visible: rows.count === 0
            iconName: root.lastError !== "" ? "data-error" : "view-refresh"
            text: root.busy ? i18n("Checking…") : root.lastError !== "" ? i18n("Whiskers can't check right now") : i18n("No results yet")
            explanation: root.lastError
        }
    }
}
