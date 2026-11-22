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
        color: "#141414"

        // Open app window in background
        Rectangle {
            x: 150
            y: 100
            width: 1200
            height: 750
            radius: 8
            color: "#1E1E1E"
            border.color: "#333333"
            border.width: 1
        }
    }

    LapTime.OverlayContent {
        id: overlay
        anchors.fill: parent
        breakType: "stretch"
        isDark: true
        remainingSec: 275 // 4m 35s
        totalSec: 300 // 5m
        snoozeMin: 5
        maxSnoozes: 3
        snoozeCount: 0
        visible: true
    }
}
