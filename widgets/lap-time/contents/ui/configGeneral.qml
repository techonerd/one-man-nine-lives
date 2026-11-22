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
        // Section: Eye Break
        QQC2.CheckBox {
            id: eyeEnabledCheckBox
            Kirigami.FormData.label: i18n("Eye break:")
            text: i18n("Enable 20-20-20 eye break reminders")
        }

        QQC2.TextField {
            id: eyeLabelField
            Kirigami.FormData.label: i18n("Label:")
            enabled: eyeEnabledCheckBox.checked
            placeholderText: i18n("Eye break")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Every:")
            spacing: Kirigami.Units.smallSpacing
            enabled: eyeEnabledCheckBox.checked

            QQC2.SpinBox {
                id: eyeIntervalSpinBox
                from: 1
                to: 240
                stepSize: 5
                textFromValue: value => i18n("%1 min", value)
                valueFromText: text => parseInt(text, 10) || 20
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Duration:")
            spacing: Kirigami.Units.smallSpacing
            enabled: eyeEnabledCheckBox.checked

            QQC2.SpinBox {
                id: eyeLengthSpinBox
                from: 5
                to: 300
                stepSize: 5
                textFromValue: value => i18n("%1 sec", value)
                valueFromText: text => parseInt(text, 10) || 20
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        // Section: Stretch Break
        QQC2.CheckBox {
            id: stretchEnabledCheckBox
            Kirigami.FormData.label: i18n("Stretch break:")
            text: i18n("Enable full stretch break reminders")
        }

        QQC2.TextField {
            id: stretchLabelField
            Kirigami.FormData.label: i18n("Label:")
            enabled: stretchEnabledCheckBox.checked
            placeholderText: i18n("Stretch break")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Every:")
            spacing: Kirigami.Units.smallSpacing
            enabled: stretchEnabledCheckBox.checked

            QQC2.SpinBox {
                id: stretchIntervalSpinBox
                from: 1
                to: 240
                stepSize: 5
                textFromValue: value => i18n("%1 min", value)
                valueFromText: text => parseInt(text, 10) || 50
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Duration:")
            spacing: Kirigami.Units.smallSpacing
            enabled: stretchEnabledCheckBox.checked

            QQC2.SpinBox {
                id: stretchLengthSpinBox
                from: 1
                to: 60
                stepSize: 1
                textFromValue: value => i18n("%1 min", value)
                valueFromText: text => parseInt(text, 10) || 5
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        // Section: Behavior & Ergonomics
        RowLayout {
            Kirigami.FormData.label: i18n("Snooze duration:")
            spacing: Kirigami.Units.smallSpacing

            QQC2.SpinBox {
                id: snoozeSpinBox
                from: 1
                to: 30
                stepSize: 1
                textFromValue: value => i18n("%1 min", value)
                valueFromText: text => parseInt(text, 10) || 5
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Maximum snoozes:")
            spacing: Kirigami.Units.smallSpacing

            QQC2.SpinBox {
                id: maxSnoozesSpinBox
                from: 1
                to: 10
                stepSize: 1
                textFromValue: value => i18n("%1 times", value)
                valueFromText: text => parseInt(text, 10) || 3
            }
        }

        QQC2.CheckBox {
            id: respectDndCheckBox
            Kirigami.FormData.label: i18n("Disturbances:")
            text: i18n("Respect Do Not Disturb and Screen Lock")
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            type: Kirigami.MessageType.Information
            text: i18n("Lap Time tracks your lap time and reminds you when it is time to stretch. Breaks are never forced: you can always snooze, skip, or press Esc.")
            visible: true
        }
    }
}
