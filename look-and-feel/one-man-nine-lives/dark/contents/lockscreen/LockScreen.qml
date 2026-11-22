// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: techonerd
// Catnap: Plasma 6 Lock Screen (One Man Nine Lives)

import QtQuick

Item {
    id: root

    property bool debug: false
    property string notification
    property bool viewVisible: false

    signal clearPassword()
    signal notificationRepeated()

    LayoutMirroring.enabled: Application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    implicitWidth: 800
    implicitHeight: 600

    LockScreenUi {
        anchors.fill: parent
    }
}
