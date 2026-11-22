// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: techonerd

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../../contents/ui" as LapTime

Item {
    id: harnessRoot
    width: 1920
    height: 1080

    // Desktop background mockup
    Rectangle {
        anchors.fill: parent
        color: "#F7F7F7"

        // Desktop window mockup behind overlay
        Rectangle {
            x: 200
            y: 150
            width: 1000
            height: 600
            radius: 8
            color: "#EAEAEA"
            border.color: "#CCCCCC"
            border.width: 1
        }
    }

    LapTime.OverlayContent {
        id: overlay
        anchors.fill: parent
        breakType: "eye"
        isDark: false
        remainingSec: 15
        totalSec: 20
        visible: true
    }
}
