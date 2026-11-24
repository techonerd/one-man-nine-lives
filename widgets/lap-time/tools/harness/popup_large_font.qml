// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: techonerd
// Large font (1.5x) verification harness for Lap Time popup dialog

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

PlasmaComponents3.Control {
    id: harnessRoot
    width: 480
    height: 580

    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.inherit: false
    font.pointSize: 15

    background: Rectangle {
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

    contentItem: Loader {
        anchors.fill: parent
        anchors.margins: 12
        sourceComponent: appletLoader.item ? appletLoader.item.fullRepresentation : null
    }
}
