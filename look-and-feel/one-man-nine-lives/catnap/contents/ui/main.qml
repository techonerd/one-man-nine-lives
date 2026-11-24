// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: techonerd
// main.qml — Catnap: animated sleeping Casper lock-screen wallpaper

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import "parts.js" as Parts

WallpaperItem {
    id: root

    // Contract properties for tests and previews:
    property real clockMs: 0
    property bool still: (typeof Kirigami !== "undefined" && Kirigami.Units.longDuration === 0)
    property int seed: 0

    readonly property int tickInterval: flicking ? 33 : 125
    readonly property real breathScale: still ? 1.0 : _breathScale
    readonly property real tailBaseAngle: still ? 0.0 : _tailBaseAngle
    readonly property real tailMidAngle: still ? 0.0 : _tailMidAngle
    readonly property real tailTipAngle: still ? 0.0 : _tailTipAngle
    readonly property bool flicking: still ? false : _flicking

    // Internal state properties
    property real _breathScale: 1.0
    property real _breathScaleHead: 1.0
    property real _tailBaseAngle: 0.0
    property real _tailMidAngle: 0.0
    property real _tailTipAngle: 0.0
    property bool _flicking: false

    property real _lastWallMs: 0
    property var _breathStarts: []
    property var _breathLengths: []
    property var _flickStarts: []

    readonly property real sceneWidth: (typeof Parts !== "undefined" && Parts.sceneW) ? Parts.sceneW : 2560
    readonly property real sceneHeight: (typeof Parts !== "undefined" && Parts.sceneH) ? Parts.sceneH : 1600
    // Anchor to bottom-right corner: scale uniformly by min(width/sceneW, height/sceneH)
    readonly property real scaleFactor: (width > 0 && height > 0) ? Math.min(width / sceneWidth, height / sceneHeight) : 1.0
    readonly property real dpr: (typeof Screen !== "undefined" && Screen.devicePixelRatio > 0) ? Screen.devicePixelRatio : 1.0

    implicitWidth: sceneWidth
    implicitHeight: sceneHeight

    Accessible.ignored: true

    onClockMsChanged: _updateMotion()
    onSeedChanged: {
        _breathStarts = []
        _breathLengths = []
        _flickStarts = []
        _updateMotion()
    }
    onStillChanged: _updateMotion()
    Component.onCompleted: _updateMotion()

    // Single master timer driving the motion
    Timer {
        id: motionTimer
        interval: root.tickInterval
        running: root.visible && !root.still
        repeat: true

        onRunningChanged: {
            root._lastWallMs = running ? Date.now() : 0
        }

        onTriggered: {
            const now = Date.now()
            if (root._lastWallMs > 0) {
                root.clockMs += (now - root._lastWallMs)
            } else {
                root.clockMs += interval
            }
            root._lastWallMs = now
        }
    }

    // Helper functions for deterministic PRNG and motion curves
    function _prng(s, i, stream) {
        let h = ((s * 1000003) ^ (i * 374761393) ^ (stream * 668265263)) >>> 0
        h = (h ^ (h >>> 13)) * 1274126177 >>> 0
        h = (h ^ (h >>> 16)) * 2246822519 >>> 0
        return ((h ^ (h >>> 13)) >>> 0) / 4294967296
    }

    function _breathDuration(s, i) {
        return 3700 + _prng(s, i, 1) * 600
    }

    function _flickPeriod(s, j) {
        return 10000 + _prng(s, j, 2) * 8000
    }

    function _flickHasDouble(s, j) {
        return _prng(s, j, 3) < 0.25
    }

    function _flickTotalDuration(s, j) {
        return _flickHasDouble(s, j) ? 4400 : 2000
    }

    function _ensureBreathsUpTo(targetTime) {
        const s = root.seed !== 0 ? root.seed : 1337
        if (_breathStarts.length === 0) {
            _breathStarts.push(0)
            _breathLengths.push(_breathDuration(s, 0))
        }
        while (_breathStarts[_breathStarts.length - 1] + _breathLengths[_breathLengths.length - 1] <= targetTime) {
            const nextIdx = _breathStarts.length
            const prevEnd = _breathStarts[nextIdx - 1] + _breathLengths[nextIdx - 1]
            _breathStarts.push(prevEnd)
            _breathLengths.push(_breathDuration(s, nextIdx))
        }
    }

    function _getBreathProgress(targetTime) {
        if (targetTime < 0) {
            return 0.0
        }
        _ensureBreathsUpTo(targetTime)
        let low = 0
        let high = _breathStarts.length - 1
        let idx = 0
        while (low <= high) {
            const mid = (low + high) >> 1
            if (_breathStarts[mid] <= targetTime) {
                idx = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        const t = targetTime - _breathStarts[idx]
        if (t < 1600) {
            const u = t / 1600
            return 0.5 * (1.0 - Math.cos(Math.PI * u))
        } else if (t < 3500) {
            const u = (t - 1600) / 1900
            return 0.5 * (1.0 + Math.cos(Math.PI * u))
        } else {
            return 0.0
        }
    }

    function _ensureFlicksUpTo(targetTime) {
        const s = root.seed !== 0 ? root.seed : 1337
        if (_flickStarts.length === 0) {
            _flickStarts.push(_flickPeriod(s, 0))
        }
        while (_flickStarts[_flickStarts.length - 1] + _flickTotalDuration(s, _flickStarts.length - 1) <= targetTime) {
            const nextIdx = _flickStarts.length
            const prevStart = _flickStarts[nextIdx - 1]
            const period = _flickPeriod(s, nextIdx)
            _flickStarts.push(prevStart + period)
        }
    }

    function _segAngle(tSeg, maxAngle) {
        if (tSeg <= 0 || tSeg >= 1760) {
            return 0.0
        }
        const tOut = 792.0
        const tBack = 968.0
        if (tSeg < tOut) {
            const u = tSeg / tOut
            return maxAngle * 0.5 * (1.0 - Math.cos(Math.PI * u))
        } else {
            const u = (tSeg - tOut) / tBack
            return maxAngle * 0.5 * (1.0 + Math.cos(Math.PI * u))
        }
    }

    function _updateMotion() {
        if (root.still) {
            _breathScale = 1.0
            _breathScaleHead = 1.0
            _tailBaseAngle = 0.0
            _tailMidAngle = 0.0
            _tailTipAngle = 0.0
            _flicking = false
            return
        }

        const timeMs = Math.max(0, root.clockMs)

        // Breathing: rise 2.5%, head follows at 60% of that rise, 150 ms later
        const bProgress = _getBreathProgress(timeMs)
        _breathScale = 1.0 + 0.025 * bProgress

        const headProgress = _getBreathProgress(timeMs - 150)
        _breathScaleHead = 1.0 + 0.025 * headProgress

        // Tail flicking: every 10-18s, lasting 2s (one in four gets a second flick 0.4s later)
        _ensureFlicksUpTo(timeMs)
        let low = 0
        let high = _flickStarts.length - 1
        let fIdx = -1
        while (low <= high) {
            const mid = (low + high) >> 1
            if (_flickStarts[mid] <= timeMs) {
                fIdx = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }

        const s = root.seed !== 0 ? root.seed : 1337
        const hasDouble = fIdx >= 0 ? _flickHasDouble(s, fIdx) : false
        const totalDuration = hasDouble ? 4400 : 2000

        if (fIdx >= 0 && timeMs < _flickStarts[fIdx] + totalDuration) {
            const tFlick = timeMs - _flickStarts[fIdx]
            if (tFlick < 2000) {
                // Primary flick
                _flicking = true
                _tailBaseAngle = _segAngle(tFlick - 0, 3.0)
                _tailMidAngle = _segAngle(tFlick - 120, 6.0)
                _tailTipAngle = _segAngle(tFlick - 240, 10.0)
            } else if (hasDouble && tFlick >= 2400 && tFlick < 4400) {
                // Second smaller flick (half the angle) 0.4s later
                _flicking = true
                const tSecond = tFlick - 2400
                _tailBaseAngle = _segAngle(tSecond - 0, 1.5)
                _tailMidAngle = _segAngle(tSecond - 120, 3.0)
                _tailTipAngle = _segAngle(tSecond - 240, 5.0)
            } else {
                // Pause between flicks (or trailing buffer)
                _flicking = false
                _tailBaseAngle = 0.0
                _tailMidAngle = 0.0
                _tailTipAngle = 0.0
            }
        } else {
            _flicking = false
            _tailBaseAngle = 0.0
            _tailMidAngle = 0.0
            _tailTipAngle = 0.0
        }
    }

    function breathLength(i) {
        const s = root.seed !== 0 ? root.seed : 1337
        return _breathDuration(s, i)
    }

    function hasSecondFlick(j) {
        const s = root.seed !== 0 ? root.seed : 1337
        return _flickHasDouble(s, j)
    }

    // 1. Background: quarter screen resolution
    Image {
        id: bgImage
        anchors.fill: parent
        source: "../images/background.svg"
        asynchronous: true
        cache: true
        sourceSize: Qt.size(Math.max(1, Math.round(root.width / 4)), Math.max(1, Math.round(root.height / 4)))
        fillMode: Image.PreserveAspectCrop
    }

    // Cat parts container
    Item {
        id: catContainer
        anchors.fill: parent

        // 2. Tail segments: nested so angles add up (tailTip -> tailMid -> tailBase)
        // Positioned in bottom-right corner relative to screen edges
        Image {
            id: tailBaseImage
            property var part: (typeof Parts !== "undefined" && Parts.tailBase) ? Parts.tailBase : null
            visible: part !== null
            x: part ? (root.width - (root.sceneWidth - part.x) * root.scaleFactor) : 0
            y: part ? (root.height - (root.sceneHeight - part.y) * root.scaleFactor) : 0
            width: part ? (part.w * root.scaleFactor) : 0
            height: part ? (part.h * root.scaleFactor) : 0
            source: "../images/tail-base.svg"
            asynchronous: true
            cache: true
            sourceSize: Qt.size(Math.max(1, Math.round(width * root.dpr)), Math.max(1, Math.round(height * root.dpr)))

            transform: Rotation {
                origin.x: tailBaseImage.part ? ((tailBaseImage.part.pivotX - tailBaseImage.part.x) * root.scaleFactor) : 0
                origin.y: tailBaseImage.part ? ((tailBaseImage.part.pivotY - tailBaseImage.part.y) * root.scaleFactor) : 0
                angle: root.tailBaseAngle
            }

            Image {
                id: tailMidImage
                property var part: (typeof Parts !== "undefined" && Parts.tailMid) ? Parts.tailMid : null
                property var parentPart: tailBaseImage.part
                visible: part !== null
                x: (part && parentPart) ? ((part.x - parentPart.x) * root.scaleFactor) : 0
                y: (part && parentPart) ? ((part.y - parentPart.y) * root.scaleFactor) : 0
                width: part ? (part.w * root.scaleFactor) : 0
                height: part ? (part.h * root.scaleFactor) : 0
                source: "../images/tail-mid.svg"
                asynchronous: true
                cache: true
                sourceSize: Qt.size(Math.max(1, Math.round(width * root.dpr)), Math.max(1, Math.round(height * root.dpr)))

                transform: Rotation {
                    origin.x: tailMidImage.part ? ((tailMidImage.part.pivotX - tailMidImage.part.x) * root.scaleFactor) : 0
                    origin.y: tailMidImage.part ? ((tailMidImage.part.pivotY - tailMidImage.part.y) * root.scaleFactor) : 0
                    angle: root.tailMidAngle
                }

                Image {
                    id: tailTipImage
                    property var part: (typeof Parts !== "undefined" && Parts.tailTip) ? Parts.tailTip : null
                    property var parentPart: tailMidImage.part
                    visible: part !== null
                    x: (part && parentPart) ? ((part.x - parentPart.x) * root.scaleFactor) : 0
                    y: (part && parentPart) ? ((part.y - parentPart.y) * root.scaleFactor) : 0
                    width: part ? (part.w * root.scaleFactor) : 0
                    height: part ? (part.h * root.scaleFactor) : 0
                    source: "../images/tail-tip.svg"
                    asynchronous: true
                    cache: true
                    sourceSize: Qt.size(Math.max(1, Math.round(width * root.dpr)), Math.max(1, Math.round(height * root.dpr)))

                    transform: Rotation {
                        origin.x: tailTipImage.part ? ((tailTipImage.part.pivotX - tailTipImage.part.x) * root.scaleFactor) : 0
                        origin.y: tailTipImage.part ? ((tailTipImage.part.pivotY - tailTipImage.part.y) * root.scaleFactor) : 0
                        angle: root.tailTipAngle
                    }
                }
            }
        }

        // 3. Body (scales from the floor line so the cat does not float; drawn over tail base)
        Image {
            id: bodyImage
            property var part: (typeof Parts !== "undefined" && Parts.body) ? Parts.body : null
            visible: part !== null
            x: part ? (root.width - (root.sceneWidth - part.x) * root.scaleFactor) : 0
            y: part ? (root.height - (root.sceneHeight - part.y) * root.scaleFactor) : 0
            width: part ? (part.w * root.scaleFactor) : 0
            height: part ? (part.h * root.scaleFactor) : 0
            source: "../images/body.svg"
            asynchronous: true
            cache: true
            sourceSize: Qt.size(Math.max(1, Math.round(width * root.dpr)), Math.max(1, Math.round(height * root.dpr)))

            transform: Scale {
                origin.x: bodyImage.part ? ((bodyImage.part.pivotX - bodyImage.part.x) * root.scaleFactor) : 0
                origin.y: bodyImage.part ? ((bodyImage.part.pivotY - bodyImage.part.y) * root.scaleFactor) : 0
                xScale: 1.0
                yScale: root.breathScale
            }
        }

        // 4. Head (follows body rise at 60%, 150 ms later; drawn over body)
        Image {
            id: headImage
            property var part: (typeof Parts !== "undefined" && Parts.head) ? Parts.head : null
            property var bodyPart: (typeof Parts !== "undefined" && Parts.body) ? Parts.body : null
            readonly property real riseOffset: (bodyPart && !root.still) ? (0.6 * (root._breathScaleHead - 1.0) * bodyPart.h * root.scaleFactor) : 0.0

            visible: part !== null
            x: part ? (root.width - (root.sceneWidth - part.x) * root.scaleFactor) : 0
            y: part ? ((root.height - (root.sceneHeight - part.y) * root.scaleFactor) - riseOffset) : 0
            width: part ? (part.w * root.scaleFactor) : 0
            height: part ? (part.h * root.scaleFactor) : 0
            source: "../images/head.svg"
            asynchronous: true
            cache: true
            sourceSize: Qt.size(Math.max(1, Math.round(width * root.dpr)), Math.max(1, Math.round(height * root.dpr)))
        }
    }
}
