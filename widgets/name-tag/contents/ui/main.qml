pragma ComponentBehavior: Bound
/*
 * Name Tag - active window icon and title widget for Plasma 6.
 * Shows the active window's icon and title in the panel.
 * Uses public org.kde.taskmanager APIs only.
 * Follows Kirigami and Plasma theme colors strictly.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager

PlasmoidItem {
    id: root

    // Form factor & orientation (support real Plasma and test harnesses)
    property bool simulatedVertical: false
    // Plasma formFactor: Planar = 0, Horizontal = 1, Vertical = 2
    readonly property bool isVertical: simulatedVertical || ((typeof Plasmoid !== "undefined" && Plasmoid.formFactor) ? Plasmoid.formFactor === 2 : false)

    // Safe configuration access (Plasma runtime or test harnesses)
    property var simulatedConfig: null
    readonly property var config: simulatedConfig || ((typeof Plasmoid !== "undefined" && Plasmoid.configuration) ? Plasmoid.configuration : null)

    readonly property bool cfgShowIcon: config ? config.show_icon : true
    readonly property bool cfgShowTitle: config ? config.show_title : true
    readonly property bool cfgBoldTitle: config ? config.bold_title : false
    readonly property int cfgIconSize: config ? config.icon_size : 100
    readonly property int cfgTextMode: config ? config.text_mode : 0          // 0 title, 1 app name, 2 app — title
    readonly property int cfgLengthMode: config ? config.length_mode : 0      // 0 fit title, 1 fill free space
    readonly property int cfgMaxLength: config ? config.max_length : 30       // % of screen width (fit mode)
    readonly property bool cfgThisScreen: config ? config.only_this_screen : true
    readonly property bool cfgMouseActions: config ? config.mouse_actions : true
    readonly property bool cfgMiddleClickClose: config ? config.middle_click_close : false
    readonly property int cfgEmptyMode: config ? config.empty_text_mode : 0
    readonly property string cfgEmptyCustomText: (config && config.empty_custom_text) || ""

    // Models & Helpers (Public APIs only)
    TaskManager.TasksModel {
        id: tasksModel
        filterByVirtualDesktop: true
        filterByCurrentVirtualDesktop: true
        filterByActivity: true
        filterNotMinimized: false
        filterByScreen: root.cfgThisScreen
        screenGeometry: (typeof Plasmoid !== "undefined" && Plasmoid.containment) ? Plasmoid.containment.screenGeometry : Qt.rect(0, 0, 0, 0)
    }

    TaskManager.ActivityInfo {
        id: activityInfo
    }

    TaskManager.VirtualDesktopInfo {
        id: virtualDesktopInfo
    }

    // Active Task Tracking
    property var activeIndex: tasksModel.activeTask
    property string simulatedTitle: ""
    property var simulatedIcon: ""

    readonly property bool hasActiveWindow: simulatedTitle !== "" || (activeIndex && activeIndex.valid)
    readonly property string windowTitle: simulatedTitle !== "" ? simulatedTitle : (hasActiveWindow ? String(tasksModel.data(activeIndex, Qt.DisplayRole) || "") : "")
    readonly property string appName: hasActiveWindow && simulatedTitle === "" ? String(tasksModel.data(activeIndex, TaskManager.AbstractTasksModel.AppName) || "") : ""
    readonly property string activeTitle: {
        if (root.cfgTextMode === 1 && root.appName !== "")
            return root.appName;
        if (root.cfgTextMode === 2 && root.appName !== "" && root.appName !== root.windowTitle)
            return root.appName + " — " + root.windowTitle;
        return root.windowTitle;
    }
    readonly property var activeIcon: simulatedIcon !== "" ? simulatedIcon : (hasActiveWindow ? (tasksModel.data(activeIndex, Qt.DecorationRole) || "application-x-executable") : "")

    function fallbackTitle() {
        if (root.cfgEmptyMode === 1) {
            return i18n("Desktop");
        } else if (root.cfgEmptyMode === 2) {
            return root.cfgEmptyCustomText || i18n("Desktop");
        } else if (root.cfgEmptyMode === 3) {
            return "";
        }
        // mode === 0: activity name or Desktop
        const actName = activityInfo.activityName(activityInfo.currentActivity);
        if (actName && actName.trim() !== "") {
            return actName;
        }
        return i18n("Desktop");
    }

    function fallbackIcon() {
        if (root.cfgEmptyMode === 0) {
            const actIcon = activityInfo.activityIcon(activityInfo.currentActivity);
            if (actIcon && actIcon.trim() !== "") {
                return actIcon;
            }
        }
        return "user-desktop";
    }

    readonly property string currentTitle: root.hasActiveWindow ? root.activeTitle : root.fallbackTitle()
    readonly property var currentIcon: root.hasActiveWindow ? root.activeIcon : root.fallbackIcon()

    // Tooltip & Plasmoid metadata
    toolTipMainText: root.currentTitle !== "" ? root.currentTitle : i18n("Desktop")
    toolTipSubText: root.hasActiveWindow ? i18n("Active Window") : i18n("No Active Window")

    preferredRepresentation: fullRepresentation

    fullRepresentation: Item {
        id: container

        // Panel thickness drives the icon, so it resizes live with the panel and the setting
        readonly property real thickness: root.isVertical ? width : height
        readonly property int iconPx: Math.max(Kirigami.Units.iconSizes.small, Math.round(thickness * root.cfgIconSize / 100))
        readonly property int maxLengthPx: Math.round(Screen.width * root.cfgMaxLength / 100)

        Layout.fillHeight: !root.isVertical
        Layout.fillWidth: root.isVertical || root.cfgLengthMode === 1
        Layout.minimumWidth: root.isVertical ? -1 : (iconItem.visible ? iconPx : 0)
        Layout.preferredWidth: root.isVertical ? -1 : Math.min(contentLayout.implicitWidth, maxLengthPx)
        Layout.maximumWidth: root.isVertical ? -1 : (root.cfgLengthMode === 1 ? Infinity : maxLengthPx)
        Layout.minimumHeight: root.isVertical ? contentLayout.implicitHeight : -1

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            enabled: (root.cfgMouseActions || root.cfgMiddleClickClose) && root.hasActiveWindow && root.simulatedTitle === ""
            Accessible.role: Accessible.Button
            Accessible.name: root.currentTitle
            onDoubleClicked: (mouse) => {
                if (mouse.button === Qt.LeftButton && root.cfgMouseActions)
                    tasksModel.requestToggleMaximized(root.activeIndex);
            }
            onClicked: (mouse) => {
                if (mouse.button === Qt.MiddleButton && root.cfgMiddleClickClose)
                    tasksModel.requestClose(root.activeIndex);
            }
        }

        GridLayout {
            id: contentLayout
            anchors.fill: parent
            rows: root.isVertical ? 2 : 1
            columns: root.isVertical ? 1 : 2
            rowSpacing: Kirigami.Units.smallSpacing
            columnSpacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                id: iconItem
                visible: root.cfgShowIcon && (root.hasActiveWindow || root.currentTitle.length > 0)
                source: root.currentIcon
                roundToIconSize: false
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: container.iconPx
                Layout.preferredHeight: container.iconPx
                Layout.maximumWidth: container.iconPx
                Layout.maximumHeight: container.iconPx
            }

            PlasmaComponents.Label {
                id: titleLabel
                visible: root.cfgShowTitle && root.currentTitle.length > 0
                text: root.currentTitle
                font.bold: root.cfgBoldTitle
                color: Kirigami.Theme.textColor
                elide: Text.ElideRight
                maximumLineCount: root.isVertical ? 2 : 1
                wrapMode: root.isVertical ? Text.Wrap : Text.NoWrap
                horizontalAlignment: root.isVertical ? Text.AlignHCenter : Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
            }
        }
    }
}
