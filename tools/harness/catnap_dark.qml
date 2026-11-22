// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: techonerd

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import "../../look-and-feel/one-man-nine-lives/dark/contents/lockscreen" as CatnapDark

Item {
    id: harnessRoot
    width: 2560
    height: 1600

    property string kscreenlocker_userName: "techonerd"
    property string kscreenlocker_userImage: ""

    property QtObject authenticator: QtObject {
        property string errorMessage: ""
        property string infoMessage: ""
        signal failed(int kind)
        signal succeeded()
        signal promptForSecretChanged(string msg)

        function startAuthenticating() {}
        function respond(pw) {}
    }

    property QtObject root: QtObject {
        property string notification: ""
        signal clearPassword()
    }

    CatnapDark.LockScreenUi {
        id: lockUi
        anchors.fill: parent
        Component.onCompleted: {
            for (var i = 0; i < lockUi.children.length; ++i) {
                if (lockUi.children[i].hasOwnProperty("uiVisible")) {
                    lockUi.children[i].uiVisible = true
                }
            }
        }
    }
}
