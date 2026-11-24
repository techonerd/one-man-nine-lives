// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: techonerd

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import "../../sddm/doorstep/doorstep" as DoorstepTheme

Item {
    id: harnessRoot
    width: 2560
    height: 1600

    property QtObject config: QtObject {
        property string variant: "dark"
        property string background: "background.svg"
        property string clockFormat: "hh:mm"
        property string dateFormat: "dddd, MMMM d"
        property int fontSize: 11
        property string playfulCat: "true"
        property string grabState: "reaching"
    }

    property QtObject sddm: QtObject {
        property bool canSuspend: true
        property bool canReboot: true
        property bool canPowerOff: true
        property bool canHibernate: true
        signal loginFailed()
        signal loginSucceeded()
        signal informationMessage(string message)

        function suspend() {}
        function reboot() {}
        function powerOff() {}
        function login(user, pass, session) {}
    }

    property var userModel: ListModel {
        property int lastIndex: 0
        ListElement {
            name: "techonerd"
            realName: "techonerd"
            icon: ""
            vtNumber: -1
        }
    }

    property var sessionModel: ListModel {
        property int lastIndex: 0
        ListElement {
            name: "Plasma (Wayland)"
        }
        ListElement {
            name: "Plasma (X11)"
        }
    }

    property QtObject keyboard: QtObject {
        property int currentLayout: 0
        property var layouts: [
            { shortName: "us", longName: "English (US)" }
        ]
    }

    DoorstepTheme.Main {
        id: mainUi
        anchors.fill: parent
    }
}
