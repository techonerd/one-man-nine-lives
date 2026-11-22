// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: techonerd
// Catnap Lock Screen UI (One Man Nine Lives)
// Generated from tools/LockScreenUi.qml.in. Do not hand-edit.

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras

Item {
    id: lockScreenUi

    // Dark variant: true (white Casper on dark), false (black Casper on light)
    property bool isDark: true

    // Casper Mono Colours (Strictly from color-scheme/tabby-and-tweed/tools/generate.py)
    readonly property color monoBg: "#141414"
    readonly property color monoFg: "#E6E6E6"
    readonly property color monoFgMuted: "#A0A0A0"
    readonly property color monoRim: Qt.rgba(1, 1, 1, 0.12)
    readonly property color monoOverlay: Qt.rgba(0.08, 0.08, 0.08, 0.70)

    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.textColor: monoFg
    Kirigami.Theme.backgroundColor: monoBg

    property string errorMessage: ""
    property bool capsLockActive: false
    property bool uiVisible: true

    // User profile picture path
    readonly property string profilePhotoPath: {
        if (typeof kscreenlocker_userIcon !== "undefined" && kscreenlocker_userIcon) {
            var p = kscreenlocker_userIcon
            return p.startsWith("file://") ? p : ("file://" + p)
        }
        return ""
    }

    Connections {
        target: (typeof root !== "undefined") ? root : null
        function onClearPassword() {
            lockScreenUi.clearPassword()
        }
    }

    // Authenticator connection from kscreenlocker
    Connections {
        target: (typeof authenticator !== "undefined") ? authenticator : null

        function onFailed(kind) {
            lockScreenUi.errorMessage = qsTr("Unlocking failed. Please try again.")
            if (typeof root !== "undefined") {
                root.notification = lockScreenUi.errorMessage
            }
            shakeAnim.restart()
            passwordBox.selectAll()
            passwordBox.forceActiveFocus()
        }

        function onSucceeded() {
            Qt.quit()
        }

        function onErrorMessageChanged() {
            if (authenticator.errorMessage) {
                lockScreenUi.errorMessage = authenticator.errorMessage
            }
        }
    }

    // Background Wallpaper Image
    Image {
        id: bgImage
        anchors.fill: parent
        source: Qt.resolvedUrl("lockscreen-bg.svg")
        fillMode: Image.PreserveAspectCrop
        smooth: true
    }

    // Ambient dimming layer for focused password entry
    Rectangle {
        anchors.fill: parent
        color: lockScreenUi.isDark ? "#000000" : "#141414"
        opacity: lockScreenUi.uiVisible ? 0.35 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
        }
    }

    // Interactive Tap Area to wake UI
    MouseArea {
        anchors.fill: parent
        enabled: !lockScreenUi.uiVisible
        onClicked: {
            lockScreenUi.uiVisible = true
            passwordBox.forceActiveFocus()
        }
    }

    // Top Clock & Sleeping Cat Art Container
    ColumnLayout {
        id: topBanner
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: lockScreenUi.uiVisible ? Kirigami.Units.gridUnit * 2.5 : Kirigami.Units.gridUnit * 6
        }
        spacing: Kirigami.Units.smallSpacing

        Behavior on anchors.topMargin {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        // Curled-up Sleeping Casper Line Art (MONO)
        Image {
            id: sleepingCat
            Layout.alignment: Qt.AlignHCenter
            source: Qt.resolvedUrl("sleeping-cat.svg")
            sourceSize.width: Kirigami.Units.gridUnit * 10
            sourceSize.height: Kirigami.Units.gridUnit * 5
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: lockScreenUi.uiVisible ? 0.5 : 1.0

            Behavior on opacity {
                NumberAnimation { duration: 250 }
            }
        }

        PlasmaComponents3.Label {
            id: clockText
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatTime(new Date(), "hh:mm")
            color: lockScreenUi.monoFg
            font.pointSize: lockScreenUi.uiVisible ? 34 : 54
            font.weight: Font.DemiBold

            Behavior on font.pointSize {
                NumberAnimation { duration: 300 }
            }
        }

        PlasmaComponents3.Label {
            id: dateText
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDate(new Date(), "dddd, MMMM d")
            color: lockScreenUi.monoFgMuted
            font.pointSize: 11
        }

        PlasmaComponents3.Label {
            Layout.alignment: Qt.AlignHCenter
            visible: !lockScreenUi.uiVisible
            text: qsTr("Catnap — the sixteenth nap of the day")
            color: lockScreenUi.monoFgMuted
            font.pointSize: 10
            font.italic: true
            opacity: 0.8
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: {
                clockText.text = Qt.formatTime(new Date(), "hh:mm")
                dateText.text = Qt.formatDate(new Date(), "dddd, MMMM d")
            }
        }
    }

    // Central Frosted Glass Login Panel (MultiEffect blur + translucent overlay)
    Item {
        id: loginPanel
        width: Math.min(parent.width - Kirigami.Units.gridUnit * 3, Kirigami.Units.gridUnit * 22)
        implicitHeight: cardContent.implicitHeight + Kirigami.Units.gridUnit * 2
        anchors.centerIn: parent
        anchors.verticalCenterOffset: Kirigami.Units.gridUnit * 3.5

        opacity: lockScreenUi.uiVisible ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
        }

        // MultiEffect Background Blur Layer
        Item {
            anchors.fill: parent
            clip: true

            MultiEffect {
                x: -loginPanel.x
                y: -loginPanel.y
                width: lockScreenUi.width
                height: lockScreenUi.height
                source: bgImage
                blurEnabled: true
                blur: 0.75
            }

            Rectangle {
                anchors.fill: parent
                radius: Kirigami.Units.cornerRadius
                color: lockScreenUi.monoOverlay
                border.color: lockScreenUi.monoRim
                border.width: 1
            }
        }

        // Rejection Shake Animation
        SequentialAnimation {
            id: shakeAnim
            loops: 1

            NumberAnimation { target: loginPanel; property: "anchors.horizontalCenterOffset"; to: -14; duration: 40; easing.type: Easing.OutQuad }
            NumberAnimation { target: loginPanel; property: "anchors.horizontalCenterOffset"; to: 14; duration: 40; easing.type: Easing.OutQuad }
            NumberAnimation { target: loginPanel; property: "anchors.horizontalCenterOffset"; to: -8; duration: 40; easing.type: Easing.OutQuad }
            NumberAnimation { target: loginPanel; property: "anchors.horizontalCenterOffset"; to: 8; duration: 40; easing.type: Easing.OutQuad }
            NumberAnimation { target: loginPanel; property: "anchors.horizontalCenterOffset"; to: 0; duration: 40; easing.type: Easing.OutQuad }
        }

        ColumnLayout {
            id: cardContent
            anchors {
                fill: parent
                margins: Kirigami.Units.gridUnit * 1.5
            }
            spacing: Kirigami.Units.largeSpacing

            // Profile Picture Circle
            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Kirigami.Units.gridUnit * 4.5
                Layout.preferredHeight: Layout.preferredWidth

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: lockScreenUi.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)
                    border.color: lockScreenUi.monoRim
                    border.width: 1
                    clip: true

                    Image {
                        id: avatarImage
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        source: lockScreenUi.profilePhotoPath
                        visible: lockScreenUi.profilePhotoPath.length > 0 && status === Image.Ready
                    }

                    Image {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.smallSpacing
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        source: Qt.resolvedUrl("sleeping-cat.svg")
                        visible: !avatarImage.visible
                    }
                }
            }

            // User Display Name
            PlasmaComponents3.Label {
                Layout.alignment: Qt.AlignHCenter
                text: (typeof kscreenlocker_userName !== "undefined" && kscreenlocker_userName) ? kscreenlocker_userName : qsTr("User")
                color: lockScreenUi.monoFg
                font.pointSize: 14
                font.weight: Font.DemiBold
            }

            // Password Field (PlasmaExtras.PasswordField with native eye toggle)
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaExtras.PasswordField {
                    id: passwordBox
                    Layout.fillWidth: true
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.View
                    Kirigami.Theme.textColor: lockScreenUi.monoFg
                    Kirigami.Theme.backgroundColor: lockScreenUi.isDark ? "#141414" : "#F7F7F7"
                    color: lockScreenUi.monoFg
                    placeholderTextColor: lockScreenUi.monoFgMuted
                    placeholderText: qsTr("Enter password to unlock")
                    focus: lockScreenUi.uiVisible

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_CapsLock) {
                            lockScreenUi.capsLockActive = !lockScreenUi.capsLockActive
                        }
                    }

                    onAccepted: lockScreenUi.submitPassword()
                }

                // Unlock arrow beside the field, as tall as the field
                PlasmaComponents3.Button {
                    id: unlockButton
                    Layout.preferredWidth: passwordBox.implicitHeight
                    Layout.preferredHeight: passwordBox.implicitHeight
                    icon.name: "go-next"
                    display: PlasmaComponents3.AbstractButton.IconOnly
                    text: qsTr("Unlock")
                    onClicked: lockScreenUi.submitPassword()
                }
            }

            // Caps Lock Warning (System Semantic Icon & Color)
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                visible: lockScreenUi.capsLockActive
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: "data-warning"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Layout.preferredWidth
                    isMask: true
                    color: Kirigami.Theme.neutralTextColor
                }

                PlasmaComponents3.Label {
                    text: qsTr("Caps Lock is ON")
                    color: Kirigami.Theme.neutralTextColor
                    font.pointSize: 9
                    font.weight: Font.Medium
                }
            }

            // Error Message (System Semantic Icon & Color)
            RowLayout {
                Layout.fillWidth: true
                visible: lockScreenUi.errorMessage.length > 0
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: "dialog-error"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Layout.preferredWidth
                    isMask: true
                    color: Kirigami.Theme.negativeTextColor
                }

                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    text: lockScreenUi.errorMessage
                    color: Kirigami.Theme.negativeTextColor
                    font.pointSize: 9
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    function submitPassword() {
        var pw = passwordBox.text
        if (typeof authenticator !== "undefined" && authenticator) {
            authenticator.respond(pw)
        }
    }

    function clearPassword() {
        passwordBox.text = ""
        lockScreenUi.errorMessage = ""
    }

    Component.onCompleted: {
        passwordBox.forceActiveFocus()
    }
}
