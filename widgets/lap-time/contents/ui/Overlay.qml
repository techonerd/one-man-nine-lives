pragma ComponentBehavior: Bound
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: techonerd
// Lap Time overlay: eye-break card and full-screen stretch break.
//
// Uses PlasmaCore.Dialog window roles because a plain QtQuick Window can't stay on top on
// Wayland (Qt.WindowStaysOnTopHint is ignored there):
// every break is a CriticalNotification covering the screen with the same centred card; it
// takes keyboard focus so Esc works, and it doesn't close when you click elsewhere: only
// Snooze, Skip/Esc, "I'm on it" or the end of the countdown close it.

import QtQuick
import QtQuick.Window
import org.kde.plasma.core as PlasmaCore

PlasmaCore.Dialog {
    id: overlayWindow

    property string breakType: "stretch" // "eye" or "stretch"
    property int remainingSec: 20
    property int totalSec: 20
    property int snoozeCount: 0
    property int maxSnoozes: 3
    property int snoozeMin: 5

    signal snoozeRequested()
    signal skipRequested()
    signal completed()


    visible: false
    type: PlasmaCore.Dialog.CriticalNotification
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    location: PlasmaCore.Types.Floating
    backgroundHints: PlasmaCore.Dialog.NoBackground
    hideOnWindowDeactivate: false

    x: Screen.virtualX
    y: Screen.virtualY

    onVisibleChanged: {
        if (visible) {
            requestActivate()
            content.forceActiveFocus()
        }
    }

    mainItem: OverlayContent {
        id: content
        width: Screen.width
        height: Screen.height
        focus: true
        breakType: overlayWindow.breakType
        remainingSec: overlayWindow.remainingSec
        totalSec: overlayWindow.totalSec
        snoozeCount: overlayWindow.snoozeCount
        maxSnoozes: overlayWindow.maxSnoozes
        snoozeMin: overlayWindow.snoozeMin

        Keys.onEscapePressed: overlayWindow.skipRequested()

        onSnoozeRequested: overlayWindow.snoozeRequested()
        onSkipRequested: overlayWindow.skipRequested()
        onCompleted: overlayWindow.completed()
    }
}
