// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: techonerd

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Item {
    id: harnessRoot
    width: 560
    height: 48

    Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
    Kirigami.Theme.inherit: false

    function i18n(str, a, b, c) {
        if (a !== undefined) return str.replace("%1", a);
        return str;
    }

    Rectangle {
        anchors.fill: parent
        color: "#181818"
        border.color: Qt.rgba(1, 1, 1, 0.12)
        radius: Kirigami.Units.cornerRadius
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        Kirigami.Icon {
            source: "application-menu"
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
        }

        Loader {
            id: appletLoader
            source: "../../contents/ui/main.qml"
            visible: false
            onLoaded: {
                // Empty state: no active window
                item.simulatedTitle = ""
                item.simulatedIcon = ""
            }
        }

        Loader {
            Layout.fillWidth: false
            Layout.fillHeight: true
            sourceComponent: appletLoader.item ? appletLoader.item.fullRepresentation : null
        }

        Item { Layout.fillWidth: true }

        Kirigami.Icon {
            source: "audio-volume-high"
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
        }

        Kirigami.Icon {
            source: "network-wireless"
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
        }

        Kirigami.Icon {
            source: "preferences-system-time"
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
        }
    }
}
