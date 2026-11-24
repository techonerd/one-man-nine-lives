// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: techonerd
// Doorstep SDDM Login Theme (One Man Nine Lives)
//
// Layout: clock, user(s), password with an inline arrow, a status line and round power actions,
// centred over the Casper wallpaper; session and keyboard layout sit flat in the bottom-left corner.
// Light or dark comes from theme.conf (variant=dark|light).

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import "." as Doorstep

Item {
    id: root

    width: 1920
    height: 1080

    readonly property bool isDark: !(config && config.variant === "light")
    readonly property bool playfulCat: !config || config.playfulCat !== "false"
    readonly property real baseFontSize: (config && config.fontSize) ? Number(config.fontSize) : 11

    Doorstep.Palette {
        id: palette
    }

    // Casper Mono colours (from Palette.qml, generated from color-scheme/tabby-and-tweed)
    readonly property color monoBg: isDark ? palette.darkBg : palette.lightBg
    readonly property color monoFg: isDark ? palette.darkFg : palette.lightFg
    readonly property color monoFgMuted: isDark ? palette.darkFgMuted : palette.lightFgMuted
    readonly property color monoRim: isDark ? palette.darkRim : palette.lightRim
    readonly property color monoField: isDark ? palette.darkField : palette.lightField

    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.textColor: monoFg
    Kirigami.Theme.backgroundColor: monoBg

    property string errorMessage: ""
    property string infoMessage: ""
    property bool loggingIn: false
    property bool capsLockActive: !!(keyboard && keyboard.capsLock)

    // Same rule as SDDM's own themes: no picker when the list is partial or
    // longer than the configured avatar threshold; type the name instead.
    readonly property bool hasUserList: !!(userModel && userModel.count > 0
        && userModel.containsAllUsers !== false
        && (userModel.disableAvatarsThreshold === undefined
            || userModel.count <= userModel.disableAvatarsThreshold))
    readonly property string currentUserName: hasUserList && userList.currentItem
        ? userList.currentItem.userName : usernameField.text

    function tint(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

    function startLogin() {
        if (!sddm || root.currentUserName === "" || root.loggingIn)
            return
        root.errorMessage = ""
        root.infoMessage = ""
        root.loggingIn = true
        sddm.login(root.currentUserName, passwordBox.text, sessionButton.currentIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.loggingIn = false
            root.errorMessage = qsTr("Incorrect password. Please try again.")
            passwordBox.text = ""
            shakeAnim.restart()
            passwordBox.forceActiveFocus()
        }
        function onLoginSucceeded() {
            root.errorMessage = ""
            root.infoMessage = ""
        }
        function onInformationMessage(message) {
            root.loggingIn = false
            root.infoMessage = message
        }
    }

    // Wallpaper with a light dim so text stays readable
    Image {
        id: bgImage
        anchors.fill: parent
        source: (config && config.background && config.background !== "background.svg")
            ? config.background : (root.isDark ? "background-dark.svg" : "background-light.svg")
        fillMode: Image.PreserveAspectCrop
        smooth: true
    }
    Rectangle {
        anchors.fill: parent
        color: root.tint(root.monoBg, 0.25)
    }

    // ---------------------------------------------------------------
    // Centre column
    // ---------------------------------------------------------------
    ColumnLayout {
        id: centre
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -Kirigami.Units.gridUnit * 2
        width: Math.min(parent.width - Kirigami.Units.gridUnit * 4, Kirigami.Units.gridUnit * 22)
        spacing: Kirigami.Units.largeSpacing

        SequentialAnimation {
            id: shakeAnim
            NumberAnimation { target: centre; property: "anchors.horizontalCenterOffset"; to: -12; duration: 40 }
            NumberAnimation { target: centre; property: "anchors.horizontalCenterOffset"; to: 12; duration: 40 }
            NumberAnimation { target: centre; property: "anchors.horizontalCenterOffset"; to: -6; duration: 40 }
            NumberAnimation { target: centre; property: "anchors.horizontalCenterOffset"; to: 0; duration: 40 }
        }

        // Clock
        PlasmaComponents3.Label {
            id: clockText
            Layout.alignment: Qt.AlignHCenter
            visible: !config || config.showClock !== "false"
            text: Qt.formatTime(new Date(), (config && config.clockFormat) ? config.clockFormat : "hh:mm")
            color: root.monoFg
            font.pointSize: root.baseFontSize * 4
            font.weight: Font.Light
        }
        PlasmaComponents3.Label {
            id: dateText
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: Kirigami.Units.gridUnit * 2
            visible: clockText.visible
            text: Qt.formatDate(new Date(), (config && config.dateFormat) ? config.dateFormat : "dddd, MMMM d")
            color: root.monoFgMuted
            font.pointSize: root.baseFontSize * 1.1
        }
        Timer {
            interval: 1000
            running: clockText.visible
            repeat: true
            onTriggered: {
                clockText.text = Qt.formatTime(new Date(), (config && config.clockFormat) ? config.clockFormat : "hh:mm")
                dateText.text = Qt.formatDate(new Date(), (config && config.dateFormat) ? config.dateFormat : "dddd, MMMM d")
            }
        }

        // One user at a time: the last one who logged in. ‹ › (or ←/→ in an
        // empty password field) step to other accounts, so the screen never
        // lays every account out at once.
        Item {
            id: userPicker
            visible: root.hasUserList
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 7

            ListView {
                id: userList
                anchors.fill: parent
                clip: true
                orientation: ListView.Horizontal
                model: root.hasUserList ? userModel : null
                currentIndex: (userModel && userModel.lastIndex >= 0) ? userModel.lastIndex : 0
                interactive: false
                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: 0
                preferredHighlightEnd: width
                highlightMoveDuration: Kirigami.Units.longDuration
                keyNavigationWraps: true

                delegate: Item {
                    id: userDelegate
                    required property int index
                    required property string name
                    required property string realName
                    required property string icon
                    readonly property string userName: name

                    width: userList.width
                    height: userList.height

                    Rectangle {
                        id: avatarCircle
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Kirigami.Units.gridUnit * 5
                        height: width
                        radius: width / 2
                        color: root.tint(root.monoFg, 0.08)
                        border.color: root.monoRim
                        border.width: 1
                        clip: true

                        Image {
                            id: avatarImage
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            sourceSize: Qt.size(width, height)
                            source: userDelegate.icon.length > 0
                                ? (userDelegate.icon.startsWith("file://") ? userDelegate.icon : "file://" + userDelegate.icon) : ""
                            visible: status === Image.Ready
                        }
                        Image {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing
                            fillMode: Image.PreserveAspectFit
                            source: root.isDark ? "avatar-dark.svg" : "avatar-light.svg"
                            visible: !avatarImage.visible
                        }
                    }
                    PlasmaComponents3.Label {
                        anchors.top: avatarCircle.bottom
                        anchors.topMargin: Kirigami.Units.smallSpacing
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - Kirigami.Units.gridUnit * 6
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: userDelegate.realName.length > 0 ? userDelegate.realName : userDelegate.name
                        color: root.monoFg
                        font.pointSize: root.baseFontSize * 1.2
                        font.weight: Font.DemiBold
                    }
                }
            }

            PlasmaComponents3.ToolButton {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -Kirigami.Units.gridUnit
                visible: userList.count > 1
                icon.name: "go-previous"
                display: PlasmaComponents3.AbstractButton.IconOnly
                text: qsTr("Previous user")
                PlasmaComponents3.ToolTip.text: text
                PlasmaComponents3.ToolTip.visible: hovered
                Accessible.name: text
                focusPolicy: Qt.NoFocus
                onClicked: { userList.decrementCurrentIndex(); passwordBox.forceActiveFocus() }
            }
            PlasmaComponents3.ToolButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -Kirigami.Units.gridUnit
                visible: userList.count > 1
                icon.name: "go-next"
                display: PlasmaComponents3.AbstractButton.IconOnly
                text: qsTr("Next user")
                PlasmaComponents3.ToolTip.text: text
                PlasmaComponents3.ToolTip.visible: hovered
                Accessible.name: text
                focusPolicy: Qt.NoFocus
                onClicked: { userList.incrementCurrentIndex(); passwordBox.forceActiveFocus() }
            }
        }

        // No visible users (hidden user list): type a user name
        PlasmaComponents3.TextField {
            id: usernameField
            visible: !root.hasUserList
            enabled: !root.loggingIn
            Layout.fillWidth: true
            placeholderText: qsTr("User name")
            onAccepted: passwordBox.forceActiveFocus()
            onTextEdited: {
                root.errorMessage = ""
                root.infoMessage = ""
            }
        }

        // Password with the log-in arrow beside it
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            PlasmaExtras.PasswordField {
                id: passwordBox
                Layout.fillWidth: true
                enabled: !root.loggingIn
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.View
                Kirigami.Theme.textColor: root.monoFg
                Kirigami.Theme.backgroundColor: root.monoField
                color: root.monoFg
                placeholderTextColor: root.monoFgMuted
                placeholderText: qsTr("Password")
                focus: true
                onAccepted: root.startLogin()
                onTextEdited: {
                    root.errorMessage = ""
                    root.infoMessage = ""
                }
                Keys.onLeftPressed: event => {
                    if (text.length === 0 && root.hasUserList) userList.decrementCurrentIndex()
                    else event.accepted = false
                }
                Keys.onRightPressed: event => {
                    if (text.length === 0 && root.hasUserList) userList.incrementCurrentIndex()
                    else event.accepted = false
                }
            }

            PlasmaComponents3.Button {
                id: loginButton
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                Kirigami.Theme.textColor: root.monoFg
                Kirigami.Theme.backgroundColor: root.monoField
                Layout.preferredWidth: passwordBox.implicitHeight
                Layout.preferredHeight: passwordBox.implicitHeight
                enabled: !root.loggingIn
                icon.name: root.loggingIn ? "" : "go-next"
                display: PlasmaComponents3.AbstractButton.IconOnly
                text: qsTr("Log In")
                PlasmaComponents3.ToolTip.text: text
                PlasmaComponents3.ToolTip.visible: hovered
                Accessible.name: text
                onClicked: root.startLogin()

                PlasmaComponents3.BusyIndicator {
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.smallMedium
                    height: width
                    running: root.loggingIn
                    visible: root.loggingIn
                }
            }
        }

        // One status line: error first, then info, then Caps Lock
        PlasmaComponents3.Label {
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: root.errorMessage.length > 0 ? root.errorMessage
                : (root.infoMessage.length > 0 ? root.infoMessage
                : (root.capsLockActive ? qsTr("Caps Lock is on") : " "))
            color: root.errorMessage.length > 0 ? Kirigami.Theme.negativeTextColor : root.monoFgMuted
        }
    }

    // ---------------------------------------------------------------
    // Power actions: round icons with a label underneath, below the column
    // ---------------------------------------------------------------
    component PowerAction: PlasmaComponents3.AbstractButton {
        id: action
        property string iconName
        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
        focusPolicy: Qt.TabFocus
        Accessible.name: text
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.Window
        Kirigami.Theme.textColor: root.monoFg
        // Greyed out, not hidden, when the system can't do it (as Breeze does)
        opacity: enabled ? 1.0 : 0.4
        contentItem: ColumnLayout {
            spacing: Kirigami.Units.smallSpacing
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: Kirigami.Units.gridUnit * 2.75
                implicitHeight: implicitWidth
                radius: width / 2
                color: root.tint(root.monoFg, action.pressed ? 0.24 : (action.hovered || action.activeFocus ? 0.14 : 0.0))
                border.color: action.hovered || action.activeFocus ? root.monoRim : "transparent"
                border.width: 1
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.medium
                    height: width
                    source: action.iconName
                    color: root.monoFg
                    isMask: true
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
        anchors.top: centre.bottom
        anchors.topMargin: Kirigami.Units.gridUnit
        spacing: Kirigami.Units.largeSpacing

        PowerAction {
            text: qsTr("Sleep")
            iconName: "system-suspend"
            enabled: !!(sddm && sddm.canSuspend)
            onClicked: sddm.suspend()
        }
        PowerAction {
            text: qsTr("Hibernate")
            iconName: "system-suspend-hibernate"
            enabled: !!(sddm && sddm.canHibernate)
            onClicked: sddm.hibernate()
        }
        PowerAction {
            text: qsTr("Restart")
            iconName: "system-reboot"
            enabled: !!(sddm && sddm.canReboot)
            onClicked: sddm.reboot()
        }
        PowerAction {
            text: qsTr("Shut Down")
            iconName: "system-shutdown"
            enabled: !!(sddm && sddm.canPowerOff)
            onClicked: sddm.powerOff()
        }
    }

    // ---------------------------------------------------------------
    // Footer (bottom-left): session and keyboard layout as flat buttons
    // ---------------------------------------------------------------
    RowLayout {
        id: footer
        anchors {
            bottom: parent.bottom
            left: parent.left
            margins: Kirigami.Units.smallSpacing
        }
        spacing: Kirigami.Units.smallSpacing
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.Window
        Kirigami.Theme.textColor: root.monoFg

        PlasmaComponents3.ToolButton {
            id: sessionButton
            property int currentIndex: (sessionModel && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
            readonly property string currentName: sessionNames.count > currentIndex && sessionNames.itemAt(currentIndex)
                ? sessionNames.itemAt(currentIndex).sessionName : ""
            visible: sessionNames.count > 1
            icon.name: "computer"
            text: qsTr("Desktop session: %1").arg(currentName)
            onClicked: sessionMenu.open()

            // Session names, read once from the model
            Repeater {
                id: sessionNames
                model: sessionModel
                delegate: Item {
                    required property string name
                    readonly property string sessionName: name
                }
            }

            PlasmaComponents3.Menu {
                id: sessionMenu
                y: -height
                Repeater {
                    model: sessionModel
                    delegate: PlasmaComponents3.MenuItem {
                        required property int index
                        required property string name
                        text: name
                        checkable: true
                        checked: index === sessionButton.currentIndex
                        onTriggered: sessionButton.currentIndex = index
                    }
                }
            }
        }

        PlasmaComponents3.ToolButton {
            id: keyboardButton
            visible: !!(keyboard && keyboard.layouts && keyboard.layouts.length > 1)
            icon.name: "input-keyboard"
            text: visible ? keyboard.layouts[keyboard.currentLayout].shortName.toUpperCase() : ""
            onClicked: keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length
        }
    }

    // ---------------------------------------------------------------
    // Casper Easter Egg (Interactive Sitting Cat by the Doorstep)
    // ---------------------------------------------------------------
    CasperGrabber {
        id: casper
        anchors.right: parent.right
        anchors.rightMargin: Math.round(parent.width * 0.15)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.round(parent.height * 0.12)
        isDark: root.isDark
        playful: root.playfulCat
        forceState: (config && config.grabState) ? config.grabState : ""
        Accessible.ignored: true
    }

    Component.onCompleted: {
        if (root.hasUserList)
            passwordBox.forceActiveFocus()
        else
            usernameField.forceActiveFocus()
    }
}
