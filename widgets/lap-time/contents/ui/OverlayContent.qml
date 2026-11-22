pragma ComponentBehavior: Bound
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: techonerd
// Lap Time Overlay Visual Content (Eye break strip & Fullscreen stretch break)

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

Item {
    id: overlayContent

    property string breakType: "stretch"

    // Every break uses the same card; only these texts, the Casper picture and the duration
    // differ. Add a new break by adding an entry here (and a timer in main.qml).
    readonly property var breaks: ({
        "eye": {
            title: i18n("Eye break"),
            message: i18n("Look at something about 6 metres (20 feet) away until the timer ends."),
            tip: i18n("Blink slowly a few times; it rewets your eyes."),
            art: "sitting"
        },
        "stretch": {
            title: i18n("Time to stretch"),
            message: i18n("Casper has claimed your lap. Stand up, stretch and take a breather."),
            tip: i18n("Roll your shoulders back 5 times, unclench your jaw and stretch your spine upward."),
            art: "sleeping"
        }
    })
    readonly property var current: breaks[breakType] || breaks["stretch"]
    property int remainingSec: 20
    property int totalSec: 20
    property int snoozeCount: 0
    property int maxSnoozes: 3
    property int snoozeMin: 5
    // Colours come from the active colour scheme's named roles (Window set), so the same
    // names give the right light or dark value; nothing is hard-coded per variant.
    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.inherit: false
    function tint(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    readonly property bool isDark: (0.2126 * Kirigami.Theme.backgroundColor.r + 0.7152 * Kirigami.Theme.backgroundColor.g
                                    + 0.0722 * Kirigami.Theme.backgroundColor.b) < 0.5
    readonly property color monoBg: Kirigami.Theme.backgroundColor
    readonly property color monoFg: Kirigami.Theme.textColor
    readonly property color monoFgMuted: Kirigami.Theme.disabledTextColor
    readonly property color monoOverlay: tint(Kirigami.Theme.backgroundColor, 0.75)
    readonly property color monoRim: tint(Kirigami.Theme.textColor, 0.12)
    readonly property color amberAccent: Kirigami.Theme.highlightColor

    signal snoozeRequested()
    signal skipRequested()
    signal completed()

    // ----------------------------------------------------
    // BREAK CARD (full-screen dimmed backdrop, centred card; same for every break)
    // ----------------------------------------------------
    Item {
        id: stretchOverlay
        anchors.fill: parent

        // Dimmed backdrop layer for screen obscuration & blur source
        Item {
            id: stretchBackdrop
            anchors.fill: parent

            Rectangle {
                anchors.fill: parent
                color: overlayContent.tint(overlayContent.monoBg, 0.85)
            }
        }

        // Center card with frosted glass
        Item {
            id: centerCard
            width: Math.min(parent.width - Kirigami.Units.gridUnit * 4,
                            Math.max(Kirigami.Units.gridUnit * 26, buttonRow.implicitWidth + Kirigami.Units.gridUnit * 4))
            height: Math.min(parent.height - Kirigami.Units.gridUnit * 4, cardLayout.implicitHeight + Kirigami.Units.gridUnit * 4)
            anchors.centerIn: parent

            // MultiEffect Frosted Glass Layer
            Item {
                anchors.fill: parent
                clip: true

                MultiEffect {
                    x: -centerCard.x
                    y: -centerCard.y
                    width: stretchOverlay.width
                    height: stretchOverlay.height
                    source: stretchBackdrop
                    blurEnabled: true
                    blur: 0.75
                }

                // Frosted glass translucent overlay & 1px rim border matching Doorstep
                Rectangle {
                    anchors.fill: parent
                    radius: Kirigami.Units.cornerRadius * 2
                    color: overlayContent.monoOverlay
                    border.color: overlayContent.monoRim
                    border.width: 1
                }
            }

            ColumnLayout {
                id: cardLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Kirigami.Units.gridUnit * 2
                spacing: Kirigami.Units.largeSpacing

                // Casper resting on your lap
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 5.5

                    Image {
                        anchors.fill: parent
                        source: "casper-" + overlayContent.current.art + (overlayContent.isDark ? "-dark" : "-light") + ".svg"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }
                }

                // Title & Subtitle
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                        text: overlayContent.current.title
                        color: overlayContent.monoFg
                        font.pointSize: 18
                        font.weight: Font.Bold
                    }

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                        text: overlayContent.current.message
                        color: overlayContent.monoFgMuted
                        font.pointSize: 11
                    }
                }

                // Countdown Timer Display (amber accent)
                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                    text: {
                        var m = Math.floor(overlayContent.remainingSec / 60)
                        var s = overlayContent.remainingSec % 60
                        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
                    }
                    color: overlayContent.amberAccent
                    font.pointSize: 36
                    font.weight: Font.DemiBold
                }

                // Ergonomic tip
                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    text: i18n("Tip: %1", overlayContent.current.tip)
                    color: overlayContent.monoFgMuted
                    font.pointSize: 10
                    font.italic: true
                }

                // Action Buttons
                RowLayout {
                    id: buttonRow
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.largeSpacing

                    // Snooze Button
                    PlasmaComponents3.Button {
                        icon.name: "alarm-symbolic"
                        icon.color: overlayContent.monoFg
                        text: i18n("Snooze (%1m)", overlayContent.snoozeMin)
                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.textColor: overlayContent.monoFg
                        enabled: overlayContent.snoozeCount < overlayContent.maxSnoozes
                        onClicked: overlayContent.snoozeRequested()
                    }

                    // Skip Button
                    PlasmaComponents3.Button {
                        icon.name: "media-skip-forward"
                        icon.color: overlayContent.monoFg
                        text: i18n("Skip (Esc)")
                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.textColor: overlayContent.monoFg
                        onClicked: overlayContent.skipRequested()
                    }

                    // I'm on it / Done Button
                    PlasmaComponents3.Button {
                        icon.name: "dialog-ok"
                        icon.color: overlayContent.monoFg
                        text: i18n("I'm on it")
                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.textColor: overlayContent.monoFg
                        highlighted: true
                        onClicked: overlayContent.completed()
                    }
                }
            }
        }
    }
}
