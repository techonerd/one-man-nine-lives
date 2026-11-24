pragma ComponentBehavior: Bound
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: techonerd
// Lap Time Overlay Visual Content (Eye break card & Fullscreen stretch break)

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

Item {
    id: overlayContent

    property string breakType: "stretch"
    readonly property bool isEye: breakType === "eye"

    // Break definitions: texts, Casper picture and default behavior
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
    property bool isDark: (0.2126 * Kirigami.Theme.backgroundColor.r + 0.7152 * Kirigami.Theme.backgroundColor.g
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

    readonly property real preferredCardWidth: Math.max(overlayContent.isEye ? Kirigami.Units.gridUnit * 20 : Kirigami.Units.gridUnit * 26,
                                                        buttonRow.implicitWidth + (overlayContent.isEye ? Kirigami.Units.gridUnit * 2 : Kirigami.Units.gridUnit * 4))
    readonly property real preferredCardHeight: cardLayout.implicitHeight + (overlayContent.isEye ? Kirigami.Units.gridUnit * 2 : Kirigami.Units.gridUnit * 4)

    implicitWidth: isEye ? preferredCardWidth : Screen.width
    implicitHeight: isEye ? preferredCardHeight : Screen.height

    Keys.onEscapePressed: overlayContent.skipRequested()
    Keys.onReturnPressed: overlayContent.completed()
    Keys.onEnterPressed: overlayContent.completed()

    // ----------------------------------------------------
    // BREAK CARD (stretch: dimmed full-screen backdrop; eye: smaller non-dimming card)
    // ----------------------------------------------------
    Item {
        id: stretchOverlay
        anchors.fill: parent

        // Dimmed backdrop layer for screen obscuration (stretch break only; eye break leaves screen undimmed)
        Rectangle {
            id: stretchBackdrop
            anchors.fill: parent
            color: overlayContent.tint(overlayContent.monoBg, 0.85)
            visible: !overlayContent.isEye
        }

        // Center card
        Item {
            id: centerCard
            width: (parent.width > 0) ? Math.min(parent.width - (overlayContent.isEye ? 0 : Kirigami.Units.gridUnit * 2), overlayContent.preferredCardWidth) : overlayContent.preferredCardWidth
            height: (parent.height > 0) ? Math.min(parent.height - (overlayContent.isEye ? 0 : Kirigami.Units.gridUnit * 2), overlayContent.preferredCardHeight) : overlayContent.preferredCardHeight
            anchors.centerIn: parent

            // Card background & 1px rim border
            Rectangle {
                anchors.fill: parent
                radius: Kirigami.Units.cornerRadius * 2
                color: overlayContent.isEye ? overlayContent.monoBg : overlayContent.monoOverlay
                border.color: overlayContent.monoRim
                border.width: 1
            }

            ColumnLayout {
                id: cardLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: overlayContent.isEye ? Kirigami.Units.gridUnit * 1.5 : Kirigami.Units.gridUnit * 2
                spacing: overlayContent.isEye ? Kirigami.Units.mediumSpacing : Kirigami.Units.largeSpacing

                // Casper resting on your lap
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: overlayContent.isEye ? Kirigami.Units.gridUnit * 6 : Kirigami.Units.gridUnit * 10
                    Layout.preferredHeight: overlayContent.isEye ? Kirigami.Units.gridUnit * 3.5 : Kirigami.Units.gridUnit * 5.5

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

                    Kirigami.Heading {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                        text: overlayContent.current.title
                        color: overlayContent.monoFg
                        level: overlayContent.isEye ? 2 : 1
                    }

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                        text: overlayContent.current.message
                        color: overlayContent.monoFgMuted
                        font: Kirigami.Theme.defaultFont
                    }
                }

                // Countdown Timer Display
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
                    color: overlayContent.monoFg
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * (overlayContent.isEye ? 2.5 : 3.5)
                    font.weight: Font.DemiBold
                }

                // Ergonomic tip
                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    text: i18n("Tip: %1", overlayContent.current.tip)
                    color: overlayContent.monoFgMuted
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    font.italic: true
                }

                // Action Buttons
                RowLayout {
                    id: buttonRow
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: overlayContent.isEye ? Kirigami.Units.mediumSpacing : Kirigami.Units.largeSpacing
                    spacing: overlayContent.isEye ? Kirigami.Units.mediumSpacing : Kirigami.Units.largeSpacing

                    // Snooze Button
                    PlasmaComponents3.Button {
                        icon.name: "alarm-symbolic"
                        text: i18nc("@action:button %1 is minutes, %2 is count left", "Snooze (%1 min, %2 left)",
                                    overlayContent.snoozeMin,
                                    Math.max(0, overlayContent.maxSnoozes - overlayContent.snoozeCount))
                        enabled: overlayContent.snoozeCount < overlayContent.maxSnoozes
                        onClicked: overlayContent.snoozeRequested()
                    }

                    // Skip Button
                    PlasmaComponents3.Button {
                        icon.name: "media-skip-forward"
                        text: i18n("Skip (Esc)")
                        onClicked: overlayContent.skipRequested()
                    }

                    // I'm on it / Done Button
                    PlasmaComponents3.Button {
                        id: doneButton
                        icon.name: "dialog-ok"
                        text: i18n("I'm on it")
                        highlighted: true
                        focus: true
                        onClicked: overlayContent.completed()
                    }
                }
            }
        }
    }
}
