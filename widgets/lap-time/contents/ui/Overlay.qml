pragma ComponentBehavior: Bound
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: techonerd
// Lap Time overlay: compact non-dimming card for eye breaks, and multi-screen stretch breaks.
//
// Uses PlasmaCore.Dialog window roles because a plain QtQuick Window can't stay on top on
// Wayland (Qt.WindowStaysOnTopHint is ignored there).
// - Eye breaks: a single Dialog sized to the card itself, floating centered on the active screen,
//   leaving the rest of the display completely interactive without capturing background clicks.
// - Stretch breaks: one Dialog per monitor via Qt.application.screens, each positioned to that
//   monitor's screen geometry with a shared countdown; dismissing or completing on any monitor closes all.
// Takes keyboard focus so Esc skips, Return or keypad Enter completes, and does not close on deactivation.

import QtQuick
import QtQuick.Window
import QtQml.Models
import org.kde.plasma.core as PlasmaCore

Item {
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

    // 1. Eye Break: Compact floating dialog sized to the card on the active screen
    PlasmaCore.Dialog {
        id: eyeDialog
        visible: overlayWindow.visible && overlayWindow.breakType === "eye"
        type: PlasmaCore.Dialog.CriticalNotification
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        location: PlasmaCore.Types.Floating
        backgroundHints: PlasmaCore.Dialog.NoBackground
        hideOnWindowDeactivate: false

        x: Screen.virtualX + Math.max(0, Math.round((Screen.width - width) / 2))
        y: Screen.virtualY + Math.max(0, Math.round((Screen.height - height) / 2))

        onVisibleChanged: {
            if (visible) {
                requestActivate()
                eyeContent.forceActiveFocus()
            }
        }

        mainItem: OverlayContent {
            id: eyeContent
            breakType: "eye"
            remainingSec: overlayWindow.remainingSec
            totalSec: overlayWindow.totalSec
            snoozeCount: overlayWindow.snoozeCount
            maxSnoozes: overlayWindow.maxSnoozes
            snoozeMin: overlayWindow.snoozeMin
            focus: true

            onSnoozeRequested: overlayWindow.snoozeRequested()
            onSkipRequested: overlayWindow.skipRequested()
            onCompleted: overlayWindow.completed()
        }
    }

    // 2. Stretch Break: Full-screen dimmed dialog on every connected screen
    Instantiator {
        id: stretchInstantiator
        model: Qt.application.screens
        active: overlayWindow.visible && overlayWindow.breakType === "stretch"

        delegate: PlasmaCore.Dialog {
            id: stretchDialog
            required property var modelData
            required property int index

            visible: overlayWindow.visible && overlayWindow.breakType === "stretch"
            type: PlasmaCore.Dialog.CriticalNotification
            flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
            location: PlasmaCore.Types.Floating
            backgroundHints: PlasmaCore.Dialog.NoBackground
            hideOnWindowDeactivate: false

            x: stretchDialog.modelData ? stretchDialog.modelData.geometry.x : 0
            y: stretchDialog.modelData ? stretchDialog.modelData.geometry.y : 0

            onVisibleChanged: {
                if (visible && stretchDialog.index === 0) {
                    requestActivate()
                    stretchContent.forceActiveFocus()
                }
            }

            mainItem: OverlayContent {
                id: stretchContent
                width: stretchDialog.modelData ? stretchDialog.modelData.geometry.width : Screen.width
                height: stretchDialog.modelData ? stretchDialog.modelData.geometry.height : Screen.height
                breakType: "stretch"
                remainingSec: overlayWindow.remainingSec
                totalSec: overlayWindow.totalSec
                snoozeCount: overlayWindow.snoozeCount
                maxSnoozes: overlayWindow.maxSnoozes
                snoozeMin: overlayWindow.snoozeMin
                focus: stretchDialog.index === 0

                onSnoozeRequested: overlayWindow.snoozeRequested()
                onSkipRequested: overlayWindow.skipRequested()
                onCompleted: overlayWindow.completed()
            }
        }
    }
}
