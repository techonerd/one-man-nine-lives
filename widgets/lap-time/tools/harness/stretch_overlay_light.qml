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

        // Open app window in background
        Rectangle {
            x: 150
            y: 100
            width: 1200
            height: 750
            radius: 8
            color: "#EAEAEA"
            border.color: "#CCCCCC"
            border.width: 1
        }
    }

    LapTime.OverlayContent {
        id: overlay
        anchors.fill: parent
        breakType: "stretch"
        isDark: false
        remainingSec: 275 // 4m 35s
        totalSec: 300 // 5m
        snoozeMin: 5
        maxSnoozes: 3
        snoozeCount: 0
        visible: true
    }
}
