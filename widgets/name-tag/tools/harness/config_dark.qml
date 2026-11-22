// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: techonerd

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Item {
    id: harnessRoot
    width: 620
    height: 480

    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.inherit: false

    function i18n(str, a, b, c) {
        if (a !== undefined) return str.replace("%1", a);
        return str;
    }

    Rectangle {
        anchors.fill: parent
        color: "#1C1C1C"
        border.color: Qt.rgba(1, 1, 1, 0.12)
        radius: Kirigami.Units.cornerRadius
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Kirigami.Icon {
                source: "configure"
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
            }

            Kirigami.Heading {
                level: 2
                text: "Name Tag Settings"
                color: Kirigami.Theme.textColor
                Layout.fillWidth: true
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            source: "../../contents/ui/configGeneral.qml"
        }
    }
}
