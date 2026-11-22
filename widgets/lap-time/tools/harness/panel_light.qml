// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: techonerd

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: harnessRoot
    width: 360
    height: 56

    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.inherit: false

    Rectangle {
        anchors.fill: parent
        color: "#F7F7F7"
        border.color: Qt.rgba(0, 0, 0, 0.12)
        radius: Kirigami.Units.cornerRadius
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 16

        Kirigami.Icon {
            source: "application-menu"
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
        }

        Item { Layout.fillWidth: true }

        Loader {
            id: appletLoader
            source: "../../contents/ui/main.qml"
            visible: false
            onLoaded: {
                item.isDark = false
                item.eyeSecRemaining = 380
                item.stretchSecRemaining = 1200
            }
        }

        Loader {
            Layout.preferredWidth: 44
            Layout.preferredHeight: 44
            sourceComponent: appletLoader.item ? appletLoader.item.compactRepresentation : null
        }

        Item { Layout.fillWidth: true }

        Kirigami.Icon {
            source: "audio-volume-high"
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
        }

        Kirigami.Icon {
            source: "network-wireless"
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
        }
    }
}
