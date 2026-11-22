// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: techonerd

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Item {
    id: harnessRoot
    width: 56
    height: 320

    Kirigami.Theme.colorSet: Kirigami.Theme.Button
    Kirigami.Theme.inherit: false

    function i18n(str, a, b, c) {
        if (a !== undefined) return str.replace("%1", a);
        return str;
    }

    Rectangle {
        anchors.fill: parent
        color: "#ECECEC"
        border.color: Qt.rgba(0, 0, 0, 0.15)
        radius: Kirigami.Units.cornerRadius
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 12
        anchors.bottomMargin: 12
        spacing: 12

        Kirigami.Icon {
            source: "application-menu"
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
        }

        Loader {
            id: appletLoader
            source: "../../contents/ui/main.qml"
            visible: false
            onLoaded: {
                item.simulatedVertical = true
                item.simulatedTitle = "Dolphin"
                item.simulatedIcon = "system-file-manager"
            }
        }

        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.alignment: Qt.AlignHCenter
            sourceComponent: appletLoader.item ? appletLoader.item.fullRepresentation : null
        }

        Item { Layout.fillHeight: true }

        Kirigami.Icon {
            source: "audio-volume-high"
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
        }

        Kirigami.Icon {
            source: "network-wireless"
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
        }

        Kirigami.Icon {
            source: "preferences-system-time"
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
        }
    }
}
