/*
 * Name Tag settings page.
 * Options to configure display of active window icon and title, sizing, and empty state.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property alias cfg_show_icon: showIconCheckBox.checked
    property bool cfg_show_iconDefault: true

    property alias cfg_show_title: showTitleCheckBox.checked
    property bool cfg_show_titleDefault: true

    property alias cfg_bold_title: boldTitleCheckBox.checked
    property bool cfg_bold_titleDefault: false

    property alias cfg_text_mode: textModeCombo.currentIndex
    property int cfg_text_modeDefault: 0
    property alias cfg_length_mode: lengthModeCombo.currentIndex
    property int cfg_length_modeDefault: 0
    property alias cfg_max_length: maxLengthSpinBox.value
    property int cfg_max_lengthDefault: 30
    property alias cfg_only_this_screen: thisScreenCheckBox.checked
    property bool cfg_only_this_screenDefault: true
    property alias cfg_mouse_actions: mouseActionsCheckBox.checked
    property bool cfg_mouse_actionsDefault: true
    property alias cfg_icon_size: iconSizeSpinBox.value
    property int cfg_icon_sizeDefault: 100

    property alias cfg_empty_text_mode: emptyModeCombo.currentIndex
    property int cfg_empty_text_modeDefault: 0

    property alias cfg_empty_custom_text: customTextField.text
    property string cfg_empty_custom_textDefault: ""

    Kirigami.FormLayout {
        QQC2.CheckBox {
            id: showIconCheckBox
            Kirigami.FormData.label: i18n("Display:")
            text: i18n("Show window icon")
        }

        QQC2.CheckBox {
            id: showTitleCheckBox
            text: i18n("Show window title")
        }

        QQC2.CheckBox {
            id: boldTitleCheckBox
            Kirigami.FormData.label: i18n("Typography:")
            text: i18n("Bold title text")
            enabled: showTitleCheckBox.checked
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.SpinBox {
            id: iconSizeSpinBox
            Kirigami.FormData.label: i18n("Icon size:")
            from: 30
            to: 100
            stepSize: 5
            textFromValue: (v) => i18n("%1 % of panel", v)
            valueFromText: (t) => parseInt(t, 10)
        }

        QQC2.ComboBox {
            id: textModeCombo
            Kirigami.FormData.label: i18n("Text:")
            enabled: showTitleCheckBox.checked
            model: [i18n("Window title"), i18n("Application name"), i18n("Application name — window title")]
        }

        QQC2.ComboBox {
            id: lengthModeCombo
            Kirigami.FormData.label: i18n("Length:")
            model: [i18n("Fit the title"), i18n("Fill free panel space")]
        }

        QQC2.SpinBox {
            id: maxLengthSpinBox
            Kirigami.FormData.label: i18n("Maximum length:")
            enabled: lengthModeCombo.currentIndex === 0
            from: 5
            to: 80
            stepSize: 5
            textFromValue: (v) => i18n("%1 % of screen", v)
            valueFromText: (t) => parseInt(t, 10)
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            id: thisScreenCheckBox
            Kirigami.FormData.label: i18n("Behaviour:")
            text: i18n("Only follow windows on this screen")
        }

        QQC2.CheckBox {
            id: mouseActionsCheckBox
            text: i18n("Double-click to maximise or restore, middle-click to close")
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.ComboBox {
            id: emptyModeCombo
            Kirigami.FormData.label: i18n("When no window is active:")
            model: [
                i18n("Current Activity Name (or Desktop)"),
                i18n("Fixed \"Desktop\" label"),
                i18n("Custom text"),
                i18n("Blank (hide label)")
            ]
        }

        QQC2.TextField {
            id: customTextField
            Kirigami.FormData.label: i18n("Custom label:")
            visible: emptyModeCombo.currentIndex === 2
            placeholderText: i18n("Enter label text…")
        }
    }
}
