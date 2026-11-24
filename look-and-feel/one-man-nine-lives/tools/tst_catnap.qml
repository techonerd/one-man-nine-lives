// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: techonerd
// Headless test of Catnap: animated sleeping Casper lock-screen wallpaper.
// Run (nothing is installed):
//   QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input look-and-feel/one-man-nine-lives/tools/tst_catnap.qml -import /usr/lib/x86_64-linux-gnu/qt6/qml

import QtQuick
import QtTest

Item {
    id: testRoot
    width: 2560
    height: 1600

    Component {
        id: catnapComponent
        Loader {
            source: "../catnap/contents/ui/main.qml"
        }
    }

    function findItem(item, name) {
        if (!item) return null
        if (item.source && item.source.toString().indexOf(name) !== -1) return item
        for (let i = 0; i < item.children.length; ++i) {
            const res = testRoot.findItem(item.children[i], name)
            if (res) return res
        }
        return null
    }

    TestCase {
        name: "CatnapWallpaper"
        when: windowShown

        function createCatnap(props) {
            const loader = createTemporaryObject(catnapComponent, testRoot)
            verify(loader !== null, "Loader should be created")
            verify(loader.item !== null, "Catnap WallpaperItem should be instantiated")
            if (props) {
                for (let k in props) {
                    loader.item[k] = props[k]
                }
            }
            return loader.item
        }

        function test_standalone_runs_cleanly() {
            const cat = createCatnap()
            compare(cat.sceneWidth, 2560)
            compare(cat.sceneHeight, 1600)
            verify(cat.width > 0, "Width should be valid")
            verify(cat.height > 0, "Height should be valid")
        }

        function test_deterministic_seed_and_clock_stepping() {
            const cat = createCatnap({ seed: 42, still: false })
            cat.clockMs = 1600
            const b1 = cat.breathScale
            verify(Math.abs(b1 - 1.025) < 0.001, "At 1600ms inhale peak, breathScale should be ~1.025")

            cat.clockMs = 5000
            const b2 = cat.breathScale

            // Return to 1600ms; should be identical
            cat.clockMs = 1600
            compare(cat.breathScale, b1)
        }

        function test_still_flag_freezes_all_motion() {
            const cat = createCatnap({ seed: 101, still: true })

            // Advance clock to various times (inhale peak, flick times, etc.)
            const testTimes = [0, 800, 1600, 2500, 12000, 13000, 14000, 25000]
            for (let i = 0; i < testTimes.length; ++i) {
                cat.clockMs = testTimes[i]
                compare(cat.breathScale, 1.0)
                compare(cat.tailBaseAngle, 0.0)
                compare(cat.tailMidAngle, 0.0)
                compare(cat.tailTipAngle, 0.0)
                compare(cat.flicking, false)
                compare(cat.tickInterval, 125)
            }
        }

        function test_breath_cycle_timing_and_rise() {
            const cat = createCatnap({ seed: 777, still: false })

            // Test breath lengths over 50 breaths
            for (let i = 0; i < 50; ++i) {
                const len = cat.breathLength(i)
                verify(len >= 3700 && len <= 4300, "Breath " + i + " length (" + len + ") must be within [3.7s, 4.3s]")
            }

            // Inhale rise test:
            cat.clockMs = 0
            verify(Math.abs(cat.breathScale - 1.0) < 0.0001, "BreathScale at t=0 should be 1.0")

            cat.clockMs = 1600
            verify(Math.abs(cat.breathScale - 1.025) < 0.0001, "BreathScale at inhale peak (1.6s) must be 1.025 (2.5% rise)")

            cat.clockMs = 3500
            verify(Math.abs(cat.breathScale - 1.0) < 0.0001, "BreathScale at end of exhale (3.5s) must be 1.0")

            // Rest period until next breath
            cat.clockMs = 3650
            verify(Math.abs(cat.breathScale - 1.0) < 0.0001, "BreathScale during rest period must be 1.0")
        }

        function test_flick_triggering_angles_and_tick_adaptation() {
            const cat = createCatnap({ seed: 1234, still: false })

            // Find exact start of the first flick:
            // Step in 200ms increments (flick duration is at least 2000ms)
            let firstFlickStart = -1
            for (let t = 0; t <= 25000; t += 200) {
                cat.clockMs = t
                if (cat.flicking) {
                    let l = t - 200, r = t
                    while (l < r) {
                        const m = (l + r) >> 1
                        cat.clockMs = m
                        if (cat.flicking) r = m
                        else l = m + 1
                    }
                    firstFlickStart = l
                    break
                }
            }

            verify(firstFlickStart >= 10000 && firstFlickStart <= 18000,
                   "First flick start (" + firstFlickStart + "ms) must be between 10s and 18s")

            // Tick interval adapts to 33ms during flick
            cat.clockMs = firstFlickStart
            compare(cat.flicking, true)
            compare(cat.tickInterval, 33)

            // Check flick duration is 2.0s (2000ms)
            cat.clockMs = firstFlickStart + 1999
            compare(cat.flicking, true)
            compare(cat.tickInterval, 33)

            // Check stagger: base starts at 0ms, mid at 120ms, tip at 240ms
            cat.clockMs = firstFlickStart + 50
            verify(cat.tailBaseAngle > 0.0, "Base tail should start moving first")
            compare(cat.tailMidAngle, 0.0)
            compare(cat.tailTipAngle, 0.0)

            cat.clockMs = firstFlickStart + 170
            verify(cat.tailBaseAngle > 0.0, "Base tail moving")
            verify(cat.tailMidAngle > 0.0, "Mid tail should start after 120ms")
            compare(cat.tailTipAngle, 0.0)

            cat.clockMs = firstFlickStart + 300
            verify(cat.tailBaseAngle > 0.0, "Base moving")
            verify(cat.tailMidAngle > 0.0, "Mid moving")
            verify(cat.tailTipAngle > 0.0, "Tip tail should start after 240ms")

            // Sample across the flick to check maximum segment angles
            let maxBase = 0, maxMid = 0, maxTip = 0
            for (let offset = 0; offset <= 2000; offset += 20) {
                cat.clockMs = firstFlickStart + offset
                if (cat.tailBaseAngle > maxBase) maxBase = cat.tailBaseAngle
                if (cat.tailMidAngle > maxMid) maxMid = cat.tailMidAngle
                if (cat.tailTipAngle > maxTip) maxTip = cat.tailTipAngle
            }

            verify(Math.abs(maxBase - 3.0) < 0.05, "Base max angle must be ~3 deg (got " + maxBase + ")")
            verify(Math.abs(maxMid - 6.0) < 0.05, "Mid max angle must be ~6 deg (got " + maxMid + ")")
            verify(Math.abs(maxTip - 10.0) < 0.05, "Tip max angle must be ~10 deg (got " + maxTip + ")")
        }

        function test_aspect_ratios_and_bottom_right_anchoring() {
            const cat = createCatnap()
            const ratios = [
                { name: "16:10", w: 2560, h: 1600 },
                { name: "16:9", w: 1920, h: 1080 },
                { name: "21:9", w: 2560, h: 1080 },
                { name: "4:3", w: 1600, h: 1200 }
            ]

            const partNames = ["body", "head", "tail-base", "tail-mid", "tail-tip"]

            for (let i = 0; i < ratios.length; ++i) {
                const r = ratios[i]
                cat.width = r.w
                cat.height = r.h
                wait(20)

                let minX = 999999, minY = 999999, maxX = -999999, maxY = -999999
                for (let p = 0; p < partNames.length; ++p) {
                    const item = testRoot.findItem(cat, partNames[p])
                    verify(item !== null, "Found " + partNames[p])
                    const p0 = item.mapToItem(cat, 0, 0)
                    const p1 = item.mapToItem(cat, item.width, item.height)
                    if (p0.x < minX) minX = p0.x
                    if (p0.y < minY) minY = p0.y
                    if (p1.x > maxX) maxX = p1.x
                    if (p1.y > maxY) maxY = p1.y
                }

                verify(minX >= 0, r.name + " (" + r.w + "x" + r.h + "): minX (" + minX + ") must be >= 0")
                verify(maxX <= r.w, r.name + " (" + r.w + "x" + r.h + "): maxX (" + maxX + ") must be <= " + r.w)
                verify(minY >= 0, r.name + " (" + r.w + "x" + r.h + "): minY (" + minY + ") must be >= 0")
                verify(maxY <= r.h, r.name + " (" + r.w + "x" + r.h + "): maxY (" + maxY + ") must be <= " + r.h)

                const marginRight = r.w - maxX
                const marginBottom = r.h - maxY
                verify(marginRight >= 0, r.name + ": marginRight (" + marginRight + ") must be non-negative")
                verify(marginBottom >= 0, r.name + ": marginBottom (" + marginBottom + ") must be non-negative")
            }
        }

        function test_tail_tip_travel_at_peak() {
            const cat = createCatnap({ seed: 1234, still: false, width: 2560, height: 1600 })
            cat.clockMs = 0

            const tip = testRoot.findItem(cat, "tail-tip")
            verify(tip !== null, "Found tail-tip item")

            // Reference point on the physical tip curl at rest (0 deg)
            const tipPointX = tip.width * 0.1
            const tipPointY = tip.height * 0.1
            const pRest = tip.mapToItem(cat, tipPointX, tipPointY)

            // Find first flick start
            let firstFlickStart = -1
            for (let t = 0; t <= 25000; t += 200) {
                cat.clockMs = t
                if (cat.flicking) {
                    let l = t - 200, r = t
                    while (l < r) {
                        const m = (l + r) >> 1
                        cat.clockMs = m
                        if (cat.flicking) r = m
                        else l = m + 1
                    }
                    firstFlickStart = l
                    break
                }
            }
            verify(firstFlickStart > 0, "Flick found")

            // Sample across the 2.0s flick duration to find peak travel
            let maxTravel = 0
            for (let off = 0; off <= 2000; off += 10) {
                cat.clockMs = firstFlickStart + off
                const pNow = tip.mapToItem(cat, tipPointX, tipPointY)
                const d = Math.hypot(pNow.x - pRest.x, pNow.y - pRest.y)
                if (d > maxTravel) maxTravel = d
            }

            // Spec requirement: 25 - 32 px at 2560x1600 (nominal ~28 px)
            verify(maxTravel >= 25.0 && maxTravel <= 32.0,
                   "Peak tail tip travel (" + maxTravel.toFixed(2) + " px) must be within [25, 32] px")
        }

        function test_double_flick_second_wave() {
            // Seed 3 produces hasSecondFlick(0) === true
            const cat = createCatnap({ seed: 3, still: false })
            verify(cat.hasSecondFlick(0), "Seed 3 flick 0 must trigger double flick")

            // Find start of flick 0
            let firstFlickStart = -1
            for (let t = 0; t <= 20000; t += 200) {
                cat.clockMs = t
                if (cat.flicking) {
                    let l = t - 200, r = t
                    while (l < r) {
                        const m = (l + r) >> 1
                        cat.clockMs = m
                        if (cat.flicking) r = m
                        else l = m + 1
                    }
                    firstFlickStart = l
                    break
                }
            }

            // 1. Primary flick (0 to 2000ms): full angles
            cat.clockMs = firstFlickStart + 1000
            compare(cat.flicking, true)
            compare(cat.tickInterval, 33)

            // 2. 0.4s pause between flicks (2000ms to 2400ms): tail at rest, 125ms idle timer
            cat.clockMs = firstFlickStart + 2200
            compare(cat.flicking, false)
            compare(cat.tickInterval, 125)
            compare(cat.tailBaseAngle, 0.0)
            compare(cat.tailMidAngle, 0.0)
            compare(cat.tailTipAngle, 0.0)

            // 3. Second flick (2400ms to 4400ms): half angles (max 1.5, 3.0, 5.0)
            cat.clockMs = firstFlickStart + 2400
            compare(cat.flicking, true)
            compare(cat.tickInterval, 33)

            let maxBase2 = 0, maxMid2 = 0, maxTip2 = 0
            for (let off = 2400; off <= 4400; off += 20) {
                cat.clockMs = firstFlickStart + off
                if (cat.tailBaseAngle > maxBase2) maxBase2 = cat.tailBaseAngle
                if (cat.tailMidAngle > maxMid2) maxMid2 = cat.tailMidAngle
                if (cat.tailTipAngle > maxTip2) maxTip2 = cat.tailTipAngle
            }

            verify(Math.abs(maxBase2 - 1.5) < 0.05, "Second flick base max angle must be ~1.5 deg (got " + maxBase2 + ")")
            verify(Math.abs(maxMid2 - 3.0) < 0.05, "Second flick mid max angle must be ~3.0 deg (got " + maxMid2 + ")")
            verify(Math.abs(maxTip2 - 5.0) < 0.05, "Second flick tip max angle must be ~5.0 deg (got " + maxTip2 + ")")

            // 4. After second flick: back to idle
            cat.clockMs = firstFlickStart + 4400
            compare(cat.flicking, false)
            compare(cat.tickInterval, 125)
            compare(cat.tailBaseAngle, 0.0)
            compare(cat.tailMidAngle, 0.0)
            compare(cat.tailTipAngle, 0.0)
        }
    }
}
