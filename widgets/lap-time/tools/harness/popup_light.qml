// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: techonerd

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: harnessRoot
    width: 420
    height: 500

    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.inherit: false

    Rectangle {
        anchors.fill: parent
        color: "#F7F7F7"
        border.color: Qt.rgba(0, 0, 0, 0.12)
        radius: Kirigami.Units.cornerRadius * 2
    }

    Loader {
        id: appletLoader
        source: "../../contents/ui/main.qml"
        visible: false
        onLoaded: {
            item.isDark = false
            item.eyeSecRemaining = 420
            item.stretchSecRemaining = 1450
            item.statsWorkSec = 9800 // 2h 43m
            item.statsBreaksTaken = 5
            item.statsBreaksSkipped = 1
        }
    }

    Loader {
        anchors.fill: parent
        anchors.margins: 12
        sourceComponent: appletLoader.item ? appletLoader.item.fullRepresentation : null
    }
}
