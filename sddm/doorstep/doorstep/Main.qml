// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: techonerd
// Doorstep SDDM Login Theme (One Man Nine Lives)

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras

Item {
    id: root

    width: 1920
    height: 1080

    // Variant mode: default dark (white Casper), switchable to light (black Casper)
    property bool isDark: (config && config.variant === "light") ? false : true

    // Casper Mono Colours (Strictly from color-scheme/tabby-and-tweed/tools/generate.py)
    readonly property color monoBg: isDark ? "#141414" : "#F7F7F7"
    readonly property color monoFg: isDark ? "#E6E6E6" : "#1C1C1C"
    readonly property color monoFgMuted: isDark ? "#A0A0A0" : "#666666"
    readonly property color monoRim: isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.12)
    readonly property color monoOverlay: isDark ? Qt.rgba(0.08, 0.08, 0.08, 0.70) : Qt.rgba(0.97, 0.97, 0.97, 0.75)

    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.textColor: monoFg
    Kirigami.Theme.backgroundColor: monoBg

    property string errorMessage: ""
    property bool capsLockActive: false

    // Current selected user from userModel
    readonly property var currentUserItem: (userModel && userModel.count > 0 && userSelectCombo.currentIndex >= 0)
        ? userModel.get(userSelectCombo.currentIndex)
        : null

    readonly property bool isUserAlreadyLoggedIn: currentUserItem && currentUserItem.vtNumber !== undefined && currentUserItem.vtNumber >= 0

    // System profile picture file path
    readonly property string profilePhotoPath: {
        if (currentUserItem && currentUserItem.icon && currentUserItem.icon.length > 0) {
            var p = currentUserItem.icon
            return p.startsWith("file://") ? p : ("file://" + p)
        }
        return ""
    }

    Connections {
        target: sddm

        function onLoginFailed() {
            root.errorMessage = qsTr("Incorrect password. Please try again.")
            shakeAnim.restart()
            passwordBox.selectAll()
            passwordBox.forceActiveFocus()
        }

        function onLoginSucceeded() {
            root.errorMessage = ""
        }

        function onInformationMessage(message) {
            root.errorMessage = message
        }
    }

    // Wallpaper Background
    Image {
        id: bgImage
        anchors.fill: parent
        source: {
            if (config && config.background && config.background !== "background.svg") {
                return config.background
            }
            return root.isDark ? "background-dark.svg" : "background-light.svg"
        }
        fillMode: Image.PreserveAspectCrop
        smooth: true
    }

    // Top Bar: Clock, Date and Dark/Light Mode Switcher
    RowLayout {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: Kirigami.Units.gridUnit * 1.5
        }

        ColumnLayout {
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.Label {
                id: clockText
                text: Qt.formatTime(new Date(), (config && config.clockFormat) ? config.clockFormat : "hh:mm")
                color: root.monoFg
                font.pointSize: 34
                font.weight: Font.DemiBold
            }

            PlasmaComponents3.Label {
                id: dateText
                text: Qt.formatDate(new Date(), (config && config.dateFormat) ? config.dateFormat : "dddd, MMMM d")
                color: root.monoFgMuted
                font.pointSize: 11
            }

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: {
                    clockText.text = Qt.formatTime(new Date(), (config && config.clockFormat) ? config.clockFormat : "hh:mm")
                    dateText.text = Qt.formatDate(new Date(), (config && config.dateFormat) ? config.dateFormat : "dddd, MMMM d")
                }
            }
        }

        Item { Layout.fillWidth: true }

        // Mode Switcher (Casper Mono Dark / Light)
        PlasmaComponents3.ToolButton {
            icon.name: root.isDark ? "weather-clear-night" : "weather-clear"
            text: root.isDark ? qsTr("Dark") : qsTr("Light")
            focusPolicy: Qt.NoFocus
            onClicked: root.isDark = !root.isDark
        }
    }

    // Central Frosted Glass Login Panel
    Item {
        id: loginPanel
        width: Math.min(parent.width - Kirigami.Units.gridUnit * 3, Kirigami.Units.gridUnit * 22)
        implicitHeight: cardContent.implicitHeight + Kirigami.Units.gridUnit * 2
        anchors.centerIn: parent

        // MultiEffect Background Blur Layer
        Item {
            anchors.fill: parent
            clip: true

            MultiEffect {
                x: -loginPanel.x
                y: -loginPanel.y
                width: root.width
                height: root.height
                source: bgImage
                blurEnabled: true
                blur: 0.75
            }

            // Glass Overlay & Rim Border
            Rectangle {
                anchors.fill: parent
                radius: Kirigami.Units.cornerRadius
                color: root.monoOverlay
                border.color: root.monoRim
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

            // Profile Picture
            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Kirigami.Units.gridUnit * 4.5
                Layout.preferredHeight: Layout.preferredWidth

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: root.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)
                    border.color: root.monoRim
                    border.width: 1
                    clip: true

                    // Primary: User's Profile Photo File
                    Image {
                        id: userProfilePhoto
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        source: root.profilePhotoPath
                        visible: root.profilePhotoPath.length > 0 && status === Image.Ready
                    }

                    // Fallback: Casper Mascot Emblem (if no user photo file exists)
                    Image {
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.smallSpacing
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        source: root.isDark ? "doorstep-cat-dark.svg" : "doorstep-cat-light.svg"
                        visible: !userProfilePhoto.visible
                    }
                }
            }

            // User Display Name
            PlasmaComponents3.Label {
                Layout.alignment: Qt.AlignHCenter
                text: {
                    if (root.currentUserItem) {
                        return root.currentUserItem.realName || root.currentUserItem.name || "User"
                    }
                    return qsTr("Welcome home")
                }
                color: root.monoFg
                font.pointSize: 14
                font.weight: Font.DemiBold
            }

            // Active Session Indicator (if user is already logged in on a VT)
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                visible: root.isUserAlreadyLoggedIn
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: "system-switch-user"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Layout.preferredWidth
                }

                PlasmaComponents3.Label {
                    text: qsTr("Session active on TTY %1").arg(root.currentUserItem?.vtNumber ?? "")
                    color: root.monoFgMuted
                    font.pointSize: 9
                }
            }

            // User Selection Dropdown (if multiple accounts exist)
            PlasmaComponents3.ComboBox {
                id: userSelectCombo
                Layout.fillWidth: true
                visible: userModel && userModel.count > 1
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                Kirigami.Theme.textColor: root.monoFg
                Kirigami.Theme.backgroundColor: root.isDark ? "#242424" : "#E8E8E8"

                model: userModel
                textRole: "name"
                currentIndex: (userModel && userModel.lastIndex >= 0) ? userModel.lastIndex : 0

                onCurrentIndexChanged: {
                    root.errorMessage = ""
                    passwordBox.text = ""
                    passwordBox.forceActiveFocus()
                }
            }

            // Username input (if userModel is empty)
            PlasmaComponents3.TextField {
                id: usernameField
                Layout.fillWidth: true
                visible: !userModel || userModel.count === 0
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.View
                Kirigami.Theme.textColor: root.monoFg
                Kirigami.Theme.backgroundColor: root.isDark ? "#141414" : "#F7F7F7"
                color: root.monoFg
                placeholderTextColor: root.monoFgMuted
                placeholderText: qsTr("Username")
                onAccepted: passwordBox.forceActiveFocus()
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
                    Kirigami.Theme.textColor: root.monoFg
                    Kirigami.Theme.backgroundColor: root.isDark ? "#141414" : "#F7F7F7"
                    color: root.monoFg
                    placeholderTextColor: root.monoFgMuted
                    placeholderText: qsTr("Password")
                    focus: true

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_CapsLock) {
                            root.capsLockActive = !root.capsLockActive
                        }
                    }

                    onAccepted: root.startLogin()
                }

                // Log-in arrow beside the field, as tall as the field
                PlasmaComponents3.Button {
                    id: loginButton
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    Kirigami.Theme.textColor: root.monoFg
                    Kirigami.Theme.backgroundColor: root.isDark ? "#242424" : "#E8E8E8"
                    Layout.preferredWidth: passwordBox.implicitHeight
                    Layout.preferredHeight: passwordBox.implicitHeight
                    icon.name: "go-next"
                    display: PlasmaComponents3.AbstractButton.IconOnly
                    text: root.isUserAlreadyLoggedIn ? qsTr("Unlock") : qsTr("Log In")
                    onClicked: root.startLogin()
                }
            }

            // Caps Lock Warning (System Semantic Icon & Color)
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                visible: root.capsLockActive
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
                visible: root.errorMessage.length > 0
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
                    text: root.errorMessage
                    color: Kirigami.Theme.negativeTextColor
                    font.pointSize: 9
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    // Power actions: round icon buttons with a label underneath, centred below the card
    component PowerAction: PlasmaComponents3.AbstractButton {
        id: action
        property string iconName
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.Window
        Kirigami.Theme.textColor: root.monoFg
        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
        focusPolicy: Qt.TabFocus
        Accessible.name: text
        contentItem: ColumnLayout {
            spacing: Kirigami.Units.smallSpacing
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: Kirigami.Units.gridUnit * 2.5
                implicitHeight: implicitWidth
                radius: width / 2
                color: Qt.rgba(root.monoFg.r, root.monoFg.g, root.monoFg.b,
                               action.pressed ? 0.24 : (action.hovered || action.activeFocus ? 0.14 : 0.06))
                border.color: root.monoRim
                border.width: 1
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.smallMedium
                    height: width
                    source: action.iconName
                    isMask: true
                    color: root.monoFg
                }
            }
            PlasmaComponents3.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: action.text
                color: root.monoFg
                elide: Text.ElideRight
            }
        }
    }

    RowLayout {
        id: powerActions
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: loginPanel.bottom
        anchors.topMargin: Kirigami.Units.gridUnit
        spacing: Kirigami.Units.largeSpacing

        PowerAction {
            text: qsTr("Sleep")
            iconName: "system-suspend"
            visible: !!(sddm && sddm.canSuspend)
            onClicked: sddm.suspend()
        }
        PowerAction {
            text: qsTr("Restart")
            iconName: "system-reboot"
            visible: !!(sddm && sddm.canReboot)
            onClicked: sddm.reboot()
        }
        PowerAction {
            text: qsTr("Shut Down")
            iconName: "system-shutdown"
            visible: !!(sddm && sddm.canPowerOff)
            onClicked: sddm.powerOff()
        }
    }

    // Footer: session and keyboard layout at the bottom left, no panel behind them
    RowLayout {
        id: footer
        anchors {
            bottom: parent.bottom
            left: parent.left
            margins: Kirigami.Units.largeSpacing
        }
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents3.ComboBox {
            id: sessionCombo
            Kirigami.Theme.inherit: false
            Kirigami.Theme.colorSet: Kirigami.Theme.Button
            Kirigami.Theme.textColor: root.monoFg
            Kirigami.Theme.backgroundColor: root.isDark ? "#242424" : "#E8E8E8"
            Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            flat: true
            model: sessionModel
            textRole: "name"
            currentIndex: (sessionModel && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
        }

        PlasmaComponents3.ComboBox {
            id: keyboardCombo
            Kirigami.Theme.inherit: false
            Kirigami.Theme.colorSet: Kirigami.Theme.Button
            Kirigami.Theme.textColor: root.monoFg
            Kirigami.Theme.backgroundColor: root.isDark ? "#242424" : "#E8E8E8"
            Layout.preferredWidth: Kirigami.Units.gridUnit * 6
            flat: true
            visible: keyboard && keyboard.layouts && keyboard.layouts.length > 1
            model: keyboard ? keyboard.layouts : []
            textRole: "shortName"
            currentIndex: keyboard ? keyboard.currentLayout : 0
            onCurrentIndexChanged: {
                if (keyboard && currentIndex >= 0) {
                    keyboard.currentLayout = currentIndex
                }
            }
        }
    }

    function startLogin() {
        var user = ""
        if (userModel && userModel.count > 0 && userSelectCombo.currentIndex >= 0) {
            user = userModel.get(userSelectCombo.currentIndex).name
        } else {
            user = usernameField.text
        }

        var sessionIdx = sessionCombo.currentIndex >= 0 ? sessionCombo.currentIndex : 0
        var password = passwordBox.text

        if (sddm) {
            sddm.login(user, password, sessionIdx)
        }
    }

    Component.onCompleted: {
        passwordBox.forceActiveFocus()
    }
}
