// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: techonerd
// CasperGrabber.qml — Interactive playful cat easter egg for Doorstep SDDM theme
//
// States: waiting -> watching -> reaching -> grabbed -> released
// Modular vector parts loaded exclusively from casper/<variant>/ per art/casper-parts/README.md

import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: root

    property bool isDark: true
    property bool playful: true
    property string forceState: ""
    property bool armExtended: false

    property real headAngle: 0
    property real armAngle: 0
    property real targetHeadAngle: 0
    property real targetArmAngle: 0
    property int tailFrame: 0

    readonly property string partsDir: "casper/" + (isDark ? "dark/" : "light/")

    implicitWidth: Kirigami.Units.gridUnit * 9
    implicitHeight: Kirigami.Units.gridUnit * 11.25
    width: implicitWidth
    height: implicitHeight

    Accessible.ignored: true

    state: "waiting"

    states: [
        State { name: "waiting" },
        State { name: "watching" },
        State { name: "reaching" },
        State { name: "grabbed" },
        State { name: "released" }
    ]

    readonly property bool isReachingOrGrabbed: state === "reaching" || state === "grabbed" || state === "released"

    onStateChanged: {
        if (state === "waiting") {
            targetHeadAngle = 0
            targetArmAngle = 0
            armExtended = false
        } else if (state === "watching") {
            targetArmAngle = 0
            armExtended = false
        }
    }

    onForceStateChanged: applyForcedState()
    Component.onCompleted: applyForcedState()

    function applyForcedState() {
        if (forceState === "") return
        state = forceState
        if (forceState === "waiting") {
            targetHeadAngle = 0
            headAngle = 0
            targetArmAngle = 0
            armAngle = 0
            armExtended = false
            tailFrame = 0
        } else if (forceState === "watching") {
            targetHeadAngle = -35
            headAngle = -35
            targetArmAngle = 0
            armAngle = 0
            armExtended = false
            tailFrame = 1
        } else if (forceState === "reaching") {
            targetHeadAngle = -45
            headAngle = -45
            targetArmAngle = -30
            armAngle = -30
            armExtended = true
            tailFrame = 2
        } else if (forceState === "grabbed") {
            targetHeadAngle = -25
            headAngle = -25
            targetArmAngle = -20
            armAngle = -20
            armExtended = false
            tailFrame = 0
        } else if (forceState === "released") {
            targetHeadAngle = -15
            headAngle = -15
            targetArmAngle = -10
            armAngle = -10
            armExtended = false
            tailFrame = 0
        }
    }

    // ---------------------------------------------------------------
    // Timers for interactive behaviors
    // ---------------------------------------------------------------
    Timer {
        id: reachTimer
        interval: 2000
        repeat: false
        onTriggered: {
            if (root.state === "reaching") {
                root.armExtended = true
            }
        }
    }

    Timer {
        id: grabDurationTimer
        interval: 2000
        repeat: false
        onTriggered: {
            root.state = "released"
            releaseCooldownTimer.restart()
        }
    }

    Timer {
        id: releaseCooldownTimer
        interval: 800
        repeat: false
        onTriggered: {
            root.armExtended = false
            if (!root.playful || root.forceState !== "") {
                root.state = "waiting"
                return
            }
            if (innerZone.containsMouse) {
                root.state = "reaching"
                reachTimer.restart()
            } else if (outerZone.containsMouse) {
                root.state = "watching"
            } else {
                root.state = "waiting"
                root.targetHeadAngle = 0
            }
        }
    }

    // Idle tail frame cycling timer (stops while grabbed)
    Timer {
        id: tailTimer
        interval: 220
        running: root.playful && root.state === "waiting" && root.forceState === "" && Kirigami.Units.longDuration > 0
        repeat: true
        onTriggered: {
            root.tailFrame = (root.tailFrame + 1) % 6
        }
    }

    // Smooth head & arm motion using Kirigami animation durations
    onTargetHeadAngleChanged: {
        if (Kirigami.Units.shortDuration > 0 && root.forceState === "") {
            headAnim.to = targetHeadAngle
            headAnim.restart()
        } else {
            headAngle = targetHeadAngle
        }
    }

    NumberAnimation {
        id: headAnim
        target: root
        property: "headAngle"
        duration: Kirigami.Units.shortDuration
        easing.type: Easing.OutQuad
    }

    onTargetArmAngleChanged: {
        if (Kirigami.Units.shortDuration > 0 && root.forceState === "") {
            armAnim.to = targetArmAngle
            armAnim.restart()
        } else {
            armAngle = targetArmAngle
        }
    }

    NumberAnimation {
        id: armAnim
        target: root
        property: "armAngle"
        duration: Kirigami.Units.shortDuration
        easing.type: Easing.OutQuad
    }

    // ---------------------------------------------------------------
    // Mouse Interaction Zones (acceptedButtons: Qt.NoButton never blocks clicks)
    // ---------------------------------------------------------------

    // Soft outer zone around cat for watching state
    MouseArea {
        id: outerZone
        anchors.centerIn: parent
        width: Math.max(parent.width * 3.5, 500)
        height: Math.max(parent.height * 3.5, 500)
        hoverEnabled: root.playful && root.forceState === ""
        acceptedButtons: Qt.NoButton
        preventStealing: false
        Accessible.ignored: true

        onPositionChanged: (mouse) => {
            if (!root.playful || root.forceState !== "") return
            var p = outerZone.mapToItem(root, mouse.x, mouse.y)
            root.trackHead(p.x, p.y)
        }
        onEntered: {
            if (!root.playful || root.forceState !== "") return
            if (root.state === "waiting") {
                root.state = "watching"
            }
        }
        onExited: {
            if (!root.playful || root.forceState !== "") return
            // The inner zone sits on top of this one, so moving closer to the cat also "exits" here
            if (innerZone.containsMouse || grabZone.containsMouse) return
            if (root.state !== "grabbed" && root.state !== "released") {
                root.state = "waiting"
                root.targetHeadAngle = 0
            }
        }
    }

    // Inner zone near the paw for reaching state
    MouseArea {
        id: innerZone
        width: root.width * 1.6
        height: root.height * 1.6
        x: -root.width * 0.45
        y: root.height * 0.15
        hoverEnabled: root.playful && root.forceState === ""
        acceptedButtons: Qt.NoButton
        preventStealing: false
        Accessible.ignored: true

        onPositionChanged: (mouse) => {
            if (!root.playful || root.forceState !== "") return
            var p = innerZone.mapToItem(root, mouse.x, mouse.y)
            root.trackHead(p.x, p.y)
            root.trackArm(p.x, p.y)
        }
        onEntered: {
            if (!root.playful || root.forceState !== "") return
            if (root.state !== "grabbed" && root.state !== "released") {
                root.state = "reaching"
                reachTimer.restart()
            }
        }
        onExited: {
            if (!root.playful || root.forceState !== "") return
            reachTimer.stop()
            root.armExtended = false
            if (root.state !== "grabbed" && root.state !== "released") {
                if (outerZone.containsMouse) {
                    root.state = "watching"
                } else {
                    root.state = "waiting"
                    root.targetHeadAngle = 0
                }
            }
        }
    }

    // ---------------------------------------------------------------
    // Visual Elements: Tail, Body, Head, Paws
    // ---------------------------------------------------------------
    Item {
        id: catContainer
        anchors.fill: parent

        // Idle swishing tail
        Image {
            id: tailImage
            x: parent.width * 0.56
            y: parent.height * 0.50
            width: parent.width * 0.44
            height: parent.height * 0.35
            source: root.partsDir + "tail-" + root.tailFrame + ".svg"
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        // Sitting Pear-shaped Torso and Right Paw
        Image {
            id: catBody
            anchors.fill: parent
            source: root.partsDir + "body.svg"
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        // Rotatable Head around Neck Pivot (stacked: head base + eyes)
        Item {
            id: headItem
            x: parent.width * 0.25
            y: parent.height * 0.04
            width: parent.width * 0.50
            height: parent.width * 0.50

            transformOrigin: Item.Bottom
            rotation: root.headAngle

            Image {
                id: headBase
                anchors.fill: parent
                source: root.partsDir + "head.svg"
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            Image {
                id: eyesOverlay
                anchors.fill: parent
                source: root.partsDir + ((root.state === "grabbed" || root.state === "released") ? "eyes-closed.svg" : "eyes-open.svg")
                fillMode: Image.PreserveAspectFit
                smooth: true
            }
        }

        // Interactive Reaching / Grabbing Paw Arm
        Item {
            id: pawArm
            x: parent.width * 0.08
            y: parent.height * 0.475
            width: parent.width * 0.375
            height: parent.height * 0.40

            transformOrigin: Item.TopRight
            rotation: root.armAngle
            scale: root.armExtended ? 1.35 : 1.0

            Behavior on scale {
                NumberAnimation {
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.OutBack
                }
            }

            // Arm segment
            Image {
                anchors.fill: parent
                source: root.partsDir + "arm.svg"
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            // Paw segment (closed in waiting/watching, open in reaching/released, cursor in grabbed)
            Image {
                anchors.fill: parent
                source: {
                    if (root.state === "grabbed") {
                        return root.partsDir + "paw-holding-cursor.svg"
                    }
                    if (root.state === "reaching" || root.state === "released") {
                        return root.partsDir + "paw-open.svg"
                    }
                    return root.partsDir + "paw-closed.svg"
                }
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            // Paw tip reference point
            Item {
                id: pawTip
                x: parent.width * 0.27
                y: parent.height * 0.85
                width: 1
                height: 1
            }

            // Grab Zone at Paw Tip
            MouseArea {
                id: grabZone
                anchors.centerIn: pawTip
                width: (root.state === "grabbed") ? (pawArm.width * 2.5) : (Kirigami.Units.gridUnit * 2.5)
                height: (root.state === "grabbed") ? (pawArm.height * 2.5) : (Kirigami.Units.gridUnit * 2.5)
                hoverEnabled: root.playful && root.forceState === ""
                acceptedButtons: Qt.NoButton
                preventStealing: false
                Accessible.ignored: true

                cursorShape: (root.state === "grabbed") ? Qt.BlankCursor : Qt.ArrowCursor

                onEntered: {
                    if (!root.playful || root.forceState !== "") return
                    if (root.state !== "grabbed" && root.state !== "released") {
                        root.triggerGrab()
                    }
                }
            }
        }
    }

    // ---------------------------------------------------------------
    // Math & Tracking Helpers
    // ---------------------------------------------------------------
    function trackHead(mx, my) {
        if (!root.playful || root.forceState !== "") return
        var pivotX = headItem.x + headItem.width * 0.5
        var pivotY = headItem.y + headItem.height * 0.85
        var dx = mx - pivotX
        var dy = my - pivotY
        var angleDeg = Math.atan2(dy, dx) * 180 / Math.PI
        // Relative to rest direction (facing towards front-left, ~ -145°)
        var diff = angleDeg - (-145)
        while (diff > 180) diff -= 360
        while (diff < -180) diff += 360
        // Clamped ±75° as specified
        root.targetHeadAngle = Math.max(-75, Math.min(75, diff))
    }

    function trackArm(mx, my) {
        if (!root.playful || root.forceState !== "") return
        var shoulderX = pawArm.x + pawArm.width * 0.75
        var shoulderY = pawArm.y + pawArm.height * 0.125
        var dx = mx - shoulderX
        var dy = my - shoulderY
        var angleDeg = Math.atan2(dy, dx) * 180 / Math.PI
        // Relative to default arm angle towards floor-left (~ 120°)
        var diff = angleDeg - 120
        while (diff > 180) diff -= 360
        while (diff < -180) diff += 360
        root.targetArmAngle = Math.max(-55, Math.min(55, diff))
    }

    function triggerGrab() {
        reachTimer.stop()
        root.state = "grabbed"
        grabDurationTimer.restart()
    }
}
