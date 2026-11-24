pragma ComponentBehavior: Bound
// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: techonerd

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    // Config properties: cfg_<key> and cfg_<key>Default for every key in main.xml
    property alias cfg_eyeEnabled: eyeEnabledCheckBox.checked
    property bool cfg_eyeEnabledDefault: true

    property alias cfg_eyeIntervalMin: eyeIntervalSpinBox.value
    property int cfg_eyeIntervalMinDefault: 20

    property alias cfg_eyeLengthSec: eyeLengthSpinBox.value
    property int cfg_eyeLengthSecDefault: 20

    property alias cfg_stretchEnabled: stretchEnabledCheckBox.checked
    property bool cfg_stretchEnabledDefault: true

    property alias cfg_stretchIntervalMin: stretchIntervalSpinBox.value
    property int cfg_stretchIntervalMinDefault: 50

    property alias cfg_stretchLengthMin: stretchLengthSpinBox.value
    property int cfg_stretchLengthMinDefault: 5

    property alias cfg_snoozeMin: snoozeSpinBox.value
    property int cfg_snoozeMinDefault: 5

    property alias cfg_maxSnoozes: maxSnoozesSpinBox.value
    property int cfg_maxSnoozesDefault: 3

    property alias cfg_respectDnd: respectDndCheckBox.checked
    property bool cfg_respectDndDefault: true

    property alias cfg_eyeLabel: eyeLabelField.text
    property string cfg_eyeLabelDefault: "Eye break"

    property alias cfg_stretchLabel: stretchLabelField.text
    property string cfg_stretchLabelDefault: "Stretch break"

    property string cfg_statsDate: ""
    property string cfg_statsDateDefault: ""

    property int cfg_statsWorkSec: 0
    property int cfg_statsWorkSecDefault: 0

    property int cfg_statsBreaksTaken: 0
    property int cfg_statsBreaksTakenDefault: 0

    property int cfg_statsBreaksSkipped: 0
    property int cfg_statsBreaksSkippedDefault: 0

    Kirigami.FormLayout {
        // Eye break
        QQC2.CheckBox {
            id: eyeEnabledCheckBox
            Kirigami.FormData.label: i18n("Eye break:")
            text: i18n("Remind me")
        }

        QQC2.TextField {
            id: eyeLabelField
            Kirigami.FormData.label: i18n("Name:")
            Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            enabled: eyeEnabledCheckBox.checked
            placeholderText: i18n("Eye break")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Timing:")
            spacing: Kirigami.Units.smallSpacing
            enabled: eyeEnabledCheckBox.checked

            QQC2.Label { text: i18nc("every N minutes", "every") }
            QQC2.SpinBox {
                id: eyeIntervalSpinBox
                Accessible.name: i18nc("@label:spinbox", "Eye break interval")
                from: 1
                to: 240
                stepSize: 5
                editable: true
                textFromValue: value => i18n("%1 min", value)
                valueFromText: text => parseInt(text, 10) || 20
            }
            QQC2.Label { text: i18nc("for N seconds/minutes", "for") }
            QQC2.SpinBox {
                id: eyeLengthSpinBox
                Accessible.name: i18nc("@label:spinbox", "Eye break duration")
                from: 5
                to: 300
                stepSize: 5
                editable: true
                textFromValue: value => i18n("%1 sec", value)
                valueFromText: text => parseInt(text, 10) || 20
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        // Stretch break
        QQC2.CheckBox {
            id: stretchEnabledCheckBox
            Kirigami.FormData.label: i18n("Stretch break:")
            text: i18n("Remind me")
        }

        QQC2.TextField {
            id: stretchLabelField
            Kirigami.FormData.label: i18n("Name:")
            Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            enabled: stretchEnabledCheckBox.checked
            placeholderText: i18n("Stretch break")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Timing:")
            spacing: Kirigami.Units.smallSpacing
            enabled: stretchEnabledCheckBox.checked

            QQC2.Label { text: i18nc("every N minutes", "every") }
            QQC2.SpinBox {
                id: stretchIntervalSpinBox
                Accessible.name: i18nc("@label:spinbox", "Stretch break interval")
                from: 1
                to: 240
                stepSize: 5
                editable: true
                textFromValue: value => i18n("%1 min", value)
                valueFromText: text => parseInt(text, 10) || 50
            }
            QQC2.Label { text: i18nc("for N seconds/minutes", "for") }
            QQC2.SpinBox {
                id: stretchLengthSpinBox
                Accessible.name: i18nc("@label:spinbox", "Stretch break duration")
                from: 1
                to: 60
                stepSize: 1
                editable: true
                textFromValue: value => i18n("%1 min", value)
                valueFromText: text => parseInt(text, 10) || 5
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Snooze:")
            spacing: Kirigami.Units.smallSpacing

            QQC2.SpinBox {
                id: snoozeSpinBox
                Accessible.name: i18nc("@label:spinbox", "Snooze duration")
                from: 1
                to: 30
                editable: true
                textFromValue: value => i18n("%1 min", value)
                valueFromText: text => parseInt(text, 10) || 5
            }
            QQC2.Label { text: i18nc("snooze N minutes, up to M times", "up to") }
            QQC2.SpinBox {
                id: maxSnoozesSpinBox
                Accessible.name: i18nc("@label:spinbox", "Maximum snooze count")
                from: 1
                to: 10
                editable: true
                textFromValue: value => i18np("%1 time", "%1 times", value)
                valueFromText: text => parseInt(text, 10) || 3
            }
        }

        QQC2.CheckBox {
            id: respectDndCheckBox
            Kirigami.FormData.label: i18n("Pause during:")
            text: i18n("Do Not Disturb and screen lock")
        }
    }
}
