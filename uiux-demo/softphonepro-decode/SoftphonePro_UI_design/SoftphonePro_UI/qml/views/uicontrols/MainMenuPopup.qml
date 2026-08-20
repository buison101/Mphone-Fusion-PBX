import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import Flux 1.0

import "../utils"

FocusScope {
    id: root

    focus: true
    implicitWidth: menu.width
    implicitHeight: menu.height

    function open() {
        menu.open();
        menu.currentIndex = 0;
        if (!AppFeatures.hideCallForwarding) {
            callForwardItem.openDropdown();
        } else if (!AppFeatures.hideEmailNotifications) {
            emailNotificationItem.openDropdown();
        }
    }

    function close() {
        if (menu.opened) {
            menu.close();
        }
    }

    property var openCallForwardDropdown: function() {
        if (AppFeatures.hideCallForwarding) {
            return;
        }
        if (callForwardItem.dropdownVisible) {
            callForwardItem.closeDropdown();
            menu.close();
            menu.forceActiveFocus();
        } else {
            callForwardItem.ignoreHover = true;
            menu.setIgnoreHover(true);
            menu.open();
            callForwardItem.highlighted = true;
            callForwardItem.openDropdown();
        }
    }

    property var openEmailNotificationDropdown: function() {
        if (AppFeatures.hideEmailNotifications) {
            return;
        }
        if (emailNotificationItem.dropdownVisible) {
            emailNotificationItem.closeDropdown();
            menu.close();
            menu.forceActiveFocus();
        } else {
            emailNotificationItem.ignoreHover = true;
            menu.setIgnoreHover(true);
            menu.open();
            emailNotificationItem.highlighted = true;
            emailNotificationItem.openDropdown();
        }
    }

    Menu {
        id: menu

        function setIgnoreHover(flag) {
            itemHelp.ignoreHover = flag;
            itemLogout.ignoreHover = flag;
            itemQuit.ignoreHover = flag;
            itemSettings.ignoreHover = flag;
        }

        onClosed: {
            callForwardItem.highlighted = false;
            emailNotificationItem.highlighted = false;
        }

        focus: true
        property bool secondaryMenuFocused: callForwardItem.viewVisible || emailNotificationItem.viewVisible

        onActiveFocusChanged: {
            if (!secondaryMenuFocused && !activeFocus) {
                close();
            }
        }

        onSecondaryMenuFocusedChanged: {
            if (!secondaryMenuFocused && !activeFocus) {
                close();
            }
        }

        implicitWidth: itemSettings.width

        background: Rectangle {
            radius: 8 * SettingsState.scale
            color: "transparent"

            MenuShadow {
                scale: SettingsState.scale
                anchors.fill: parent
                bodyColor: ColorStorage.surfaceSecondary
                shadowColor: ColorStorage.menuShadowColor
            }
        }

        MainMenuItemWithDropdown {
            id: callForwardItem
            anchors.top: parent.top
            actionLabel: qsTrId("call_forward_combobox_title") + Translator.translate
            model: AppState.callForwardModel
            roundTopCorners: visible
            topMargin: 1 * SettingsState.scale
            elementHeight: !AppFeatures.hideCallForwarding ? 30 * SettingsState.scale : 0

            hoverEnabled: false

            visible: !AppFeatures.hideCallForwarding
            enabled: visible

            doWorkOnListItemClick: function(idx) {
                ActionProvider.changeCallForward(idx);
                menu.close();
            }
        }

        MainMenuItemWithDropdown {
            id: emailNotificationItem
            anchors.top: !AppFeatures.hideCallForwarding ? callForwardItem.bottom : parent.top
            actionLabel: qsTrId("email_notify_combobox_title") + Translator.translate
            model: AppState.emailNotifyModel
            elementHeight: !AppFeatures.hideEmailNotifications ? 30 * SettingsState.scale : 0

            hoverEnabled: false

            roundTopCorners: !callForwardItem.visible

            visible: !AppFeatures.hideEmailNotifications
            enabled: visible

            doWorkOnListItemClick: function(idx) {
                ActionProvider.changeEmailNotify(idx)
                menu.close();
            }
        }

        MainMenuSeparator {
            id: separator
            anchors.top: separator.bottom
            color: ColorStorage.menuBorderColor
            hoverEnabled: false
            visible: emailNotificationItem.visible || callForwardItem.visible
        }

        MainMenuItem {
            id: itemHelp
            actionLabel: qsTrId("main_menu_help") + Translator.translate
            anchors.top: separator.bottom
            visible: false//!AppFeatures.callifi && !AppFeatures.insideTelecom
            enabled: visible
            textLeftMargin: -4 * SettingsState.scale

            hoverEnabled: false

            roundTopCorners: !emailNotificationItem.visible && !callForwardItem.visible

            resetIgnoreHover: function() {
                menu.setIgnoreHover(false);
            }
            onTriggered: {
                    Qt.openUrlExternally(StringStorage.getHelpURL(SettingsState.languageIsoCode));
            }
        }

        MainMenuItem {
            id: itemSettings

            anchors.top: itemHelp.visible ? itemHelp.bottom : separator.bottom
            textLeftMargin: -4 * SettingsState.scale
            actionLabel: qsTrId("main_menu_settings_window") + Translator.translate
            shortcutLabel: "Ctrl+S"

            hoverEnabled: false

            roundTopCorners: !emailNotificationItem.visible && !callForwardItem.visible && !itemHelp.visible

            resetIgnoreHover: function() {
                menu.setIgnoreHover(false);
            }
            onTriggered: {
                ActionProvider.showSettingsWindow(true);
            }
        }

        MainMenuItem {
            id: itemLogout
            visible: AppFeatures.provisioningOn
            enabled: visible
            textLeftMargin: -4 * SettingsState.scale
            actionLabel: qsTrId("main_menu_logout") + Translator.translate
            anchors.top: itemSettings.bottom

            hoverEnabled: false

            resetIgnoreHover: function() {
                menu.setIgnoreHover(false);
            }
            onTriggered: {
                ActionProvider.tryRestartApplication(true);

            }
        }

        MainMenuItem {
            id: itemQuit
            anchors.top: itemLogout.visible ? itemLogout.bottom : itemSettings.bottom
            actionLabel: qsTrId("main_menu_quit") + Translator.translate
            shortcutLabel: "Ctrl+Q"
            textLeftMargin: -4 * SettingsState.scale
            bottomMargin: 1 * SettingsState.scale
            roundBottomCorners: true
            lastItem: true

            hoverEnabled: false

            resetIgnoreHover: function() {
                menu.setIgnoreHover(false);
            }
            onTriggered: {
                ActionProvider.tryQuitApplication();
            }
        }
    }
}
