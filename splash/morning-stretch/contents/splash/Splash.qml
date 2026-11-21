/*
    SPDX-FileCopyrightText: 2023-2026 techonerd
    SPDX-License-Identifier: GPL-3.0-or-later

    "Morning Stretch" splash screen for Plasma 6 (One Man Nine Lives suite).
    Main animation centred at its own aspect ratio on black, with the original
    animated loader at the bottom.
*/

import QtQuick

Rectangle {
    id: root
    color: "black"              // fills the area around the animation: no stretching

    property int stage          // set by ksplashqml as the session starts

    // Main animation: keeps its own aspect ratio, centred, black bars around it
    AnimatedImage {
        id: hero
        anchors.fill: parent
        source: "images/morning-stretch.gif"
        fillMode: Image.PreserveAspectFit
        horizontalAlignment: Image.AlignHCenter
        verticalAlignment: Image.AlignVCenter
        cache: false            // decode frames as they play instead of keeping all of them in RAM
        asynchronous: false     // show the first frame immediately (no black flash, then pop-in)
        smooth: true            // set to false for a sharper but more pixelated look when upscaled
    }

    // Original loader at the bottom (same size/position as the Plasma 5 version)
    AnimatedImage {
        id: busyIndicator
        width: 75
        height: 75
        y: parent.height - 150
        anchors.horizontalCenter: parent.horizontalCenter
        source: "images/busy.gif"
        fillMode: Image.PreserveAspectFit
        cache: false
        asynchronous: false
        playing: true
    }
}
