/*
    SPDX-FileCopyrightText: 2023-2026 techonerd
    SPDX-License-Identifier: GPL-3.0-or-later

    "Morning Stretch" splash screen for Plasma 6 (One Man Nine Lives suite).
    Main animation centred at its own aspect ratio on black, with the original
    animated loader at the bottom.
*/

import QtQuick
import org.kde.kirigami as Kirigami

Rectangle {
    id: root
    color: "black"              // plasma-polish: allow hard-colour morning-stretch.gif has pure black (0,0,0) edges; palette #141414 causes visible seam

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

    // Spinning Yarn: the loader under the animation (a braided yarn ring around Casper)
    AnimatedImage {
        id: busyIndicator
        width: Kirigami.Units.gridUnit * 4
        height: Kirigami.Units.gridUnit * 4
        y: parent.height - Kirigami.Units.gridUnit * 8
        anchors.horizontalCenter: parent.horizontalCenter
        source: "images/spinning-yarn.gif"
        fillMode: Image.PreserveAspectFit
        cache: false
        asynchronous: false
        playing: true
    }
}
