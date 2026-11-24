// SPDX-License-Identifier: GPL-3.0-or-later
// Headless test of Doorstep's playful cat: moves the pointer in small steps and checks the
// cat goes waiting -> watching -> reaching -> grabbed, and calms down when the pointer leaves.
// Run (nothing is installed):
//   QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input sddm/doorstep/tools/tst_casper_grabber.qml \
//       -import /usr/lib/x86_64-linux-gnu/qt6/qml

import QtQuick
import QtTest
import "../doorstep" as Doorstep

Item {
    id: scene
    width: 1600
    height: 1000

    Component {
        id: catComponent
        Doorstep.CasperGrabber { x: 1100; y: 600 }
    }

    TestCase {
        name: "CasperGrabber"
        when: windowShown

        // Walk the pointer from (x0, y0) to (x1, y1) in small steps; return the states seen, in order
        function walk(cat, x0, y0, x1, y1, seen) {
            for (let t = 0; t <= 1.0001; t += 0.005) {
                mouseMove(scene, x0 + (x1 - x0) * t, y0 + (y1 - y0) * t)
                wait(4)
                if (seen[seen.length - 1] !== cat.state)
                    seen.push(cat.state)
            }
            return seen
        }

        function test_approach_to_paw_is_grabbed() {
            const cat = createTemporaryObject(catComponent, scene)
            mouseMove(scene, 200, 900)
            wait(20)
            const seen = walk(cat, 200, 900, cat.x - 10, cat.y + cat.height * 0.75, [cat.state])
            compare(seen.join(" > "), "waiting > watching > reaching > grabbed")
        }

        function test_leaving_calms_the_cat() {
            const cat = createTemporaryObject(catComponent, scene)
            mouseMove(scene, 200, 900)
            wait(20)
            // close to the cat, but not at the paw
            const near = [cat.x + cat.width / 2, cat.y - cat.height * 0.5]
            walk(cat, 200, 900, near[0], near[1], [])
            compare(cat.state, "watching")
            walk(cat, near[0], near[1], 100, 100, [])
            compare(cat.state, "waiting")
            compare(cat.targetHeadAngle, 0)
        }

        function test_not_playful_ignores_pointer() {
            const cat = createTemporaryObject(catComponent, scene, { playful: false })
            walk(cat, 200, 900, cat.x - 10, cat.y + cat.height * 0.75, [])
            compare(cat.state, "waiting")
        }
    }
}
