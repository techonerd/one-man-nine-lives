/*
 * Whiskers settings. Built from the installed checks ("whiskers plugins --json"), so it adapts to
 * each device and to checks you add yourself. Changes are written straight to
 * ~/.config/whiskers/whiskers.conf through the whiskers CLI.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasma5support as P5Support

KCM.SimpleKCM {
    id: page

    // Only widget-side setting (main.xml); Plasma 6 expects both properties
    property alias cfg_refresh_minutes: refreshMinutes.value
    property int cfg_refresh_minutesDefault

    readonly property string bin: '"$HOME/.local/bin/whiskers"'
    property var general: ({})
    property var checks: []
    property bool loaded: false
    property var pending: ({})

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            disconnectSource(source)
            const cb = page.pending[source]
            delete page.pending[source]
            if (cb) cb(data["exit code"], data["stdout"] || "", data["stderr"] || "")
        }
    }
    function run(cmd, cb) { pending[cmd] = cb; exec.connectSource(cmd) }
    function quote(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }

    function load() {
        run(bin + " config list --json", (code, out, err) => {
            if (code !== 0) { showError(err || i18n("The whiskers command isn't installed.")); return }
            try { general = JSON.parse(out) } catch (e) {}
            run(bin + " plugins --json", (c2, o2) => {
                try { checks = JSON.parse(o2) } catch (e) { checks = [] }
                loaded = true
            })
        })
    }
    function save(key, value) {
        run(bin + " config set " + key + " " + quote(value), (code, out, err) => {
            if (code !== 0) showError(err.trim())
            else message.visible = false
        })
    }
    function showError(t) { message.text = t; message.visible = true }

    Component.onCompleted: load()

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        Kirigami.InlineMessage {
            id: message
            Layout.fillWidth: true
            type: Kirigami.MessageType.Error
            visible: false
        }
        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: page.loaded
            type: Kirigami.MessageType.Information
            text: i18n("Changes to alerts and checks are saved right away and also apply to the whiskers command.")
        }

        Kirigami.FormLayout {
            Layout.fillWidth: true

            Kirigami.Separator {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: i18n("Alerts")
            }
            QQC2.CheckBox {
                Kirigami.FormData.label: i18n("Notifications:")
                text: i18n("Tell me about new problems")
                enabled: page.loaded
                checked: page.general.notify === "true"
                onToggled: page.save("general.notify", checked)
            }
            QQC2.CheckBox {
                Kirigami.FormData.label: i18n("Live watch:")
                text: i18n("Explain crashes, failed services and sleep problems as they happen")
                enabled: page.loaded
                checked: page.general.live === "true"
                onToggled: page.save("general.live", checked)
            }
            QQC2.SpinBox {
                Kirigami.FormData.label: i18n("Full check every:")
                enabled: page.loaded
                from: 1; to: 48
                value: parseInt(page.general.interval_hours || "4")
                textFromValue: (v) => i18np("%1 hour", "%1 hours", v)
                valueFromText: (t) => parseInt(t)
                onValueModified: page.save("general.interval_hours", value)
            }
            QQC2.SpinBox {
                Kirigami.FormData.label: i18n("Remind again after:")
                enabled: page.loaded
                from: 1; to: 168
                value: parseInt(page.general.remind_hours || "24")
                textFromValue: (v) => i18np("%1 hour", "%1 hours", v)
                valueFromText: (t) => parseInt(t)
                onValueModified: page.save("general.remind_hours", value)
            }
            QQC2.SpinBox {
                id: refreshMinutes
                Kirigami.FormData.label: i18n("Refresh this widget every:")
                from: 5; to: 240; stepSize: 5
                textFromValue: (v) => i18np("%1 minute", "%1 minutes", v)
                valueFromText: (t) => parseInt(t)
            }
        }

        Kirigami.Heading {
            level: 4
            text: i18n("What Whiskers watches")
            Layout.topMargin: Kirigami.Units.largeSpacing
        }

        Repeater {
            model: page.checks

            delegate: Kirigami.AbstractCard {
                id: checkCard
                required property var modelData
                Layout.fillWidth: true
                enabled: modelData.applies

                contentItem: ColumnLayout {
                    spacing: Kirigami.Units.smallSpacing

                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Kirigami.Heading {
                                level: 5
                                text: checkCard.modelData.name
                            }
                            QQC2.Label {
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                                opacity: 0.7
                                text: checkCard.modelData.applies ? checkCard.modelData.description
                                                                  : i18n("Not used on this device.")
                            }
                        }
                        QQC2.Switch {
                            Accessible.name: i18nc("@action:switch %1 is a check name", "Watch %1", checkCard.modelData.name)
                            checked: checkCard.modelData.enabled && checkCard.modelData.applies
                            onToggled: page.save(checkCard.modelData.id + ".enabled", checked)
                        }
                    }

                    Kirigami.FormLayout {
                        Layout.fillWidth: true
                        visible: checkCard.modelData.options.length > 0 && checkCard.modelData.enabled && checkCard.modelData.applies

                        Repeater {
                            model: checkCard.modelData.options
                            delegate: RowLayout {
                                id: optRow
                                required property var modelData
                                readonly property string key: checkCard.modelData.id + "." + modelData.key
                                Kirigami.FormData.label: modelData.label + ":"

                                QQC2.SpinBox {
                                    Accessible.name: optRow.modelData.label
                                    visible: optRow.modelData.type === "int"
                                    from: optRow.modelData.min !== undefined ? optRow.modelData.min : 0
                                    to: optRow.modelData.max !== undefined ? optRow.modelData.max : 100000
                                    value: parseInt(optRow.modelData.value)
                                    onValueModified: page.save(optRow.key, value)
                                }
                                QQC2.CheckBox {
                                    Accessible.name: optRow.modelData.label
                                    visible: optRow.modelData.type === "bool"
                                    checked: optRow.modelData.value === "true"
                                    onToggled: page.save(optRow.key, checked)
                                }
                                QQC2.TextField {
                                    visible: optRow.modelData.type === "string"
                                    Layout.preferredWidth: Kirigami.Units.gridUnit * 14
                                    text: optRow.modelData.value
                                    placeholderText: optRow.modelData.placeholder || ""
                                    onEditingFinished: page.save(optRow.key, text)
                                }
                                QQC2.Button {
                                    visible: optRow.modelData.type === "file"
                                    icon.name: "document-edit"
                                    text: i18n("Edit list…")
                                    onClicked: page.run("xdg-open " + page.quote(optRow.modelData.value), () => {})
                                }
                                QQC2.Label {
                                    visible: (optRow.modelData.unit || "") !== ""
                                    text: optRow.modelData.unit || ""
                                    opacity: 0.7
                                }
                            }
                        }
                    }
                }
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
            wrapMode: Text.Wrap
            opacity: 0.7
            text: i18n("Add your own checks as small scripts in ~/.config/whiskers/checks.d/. They appear here automatically.")
        }
    }
}
