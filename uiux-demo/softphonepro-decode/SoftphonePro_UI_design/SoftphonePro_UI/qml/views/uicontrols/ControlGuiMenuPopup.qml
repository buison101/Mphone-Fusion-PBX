import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import Flux 1.0

import "../utils"

FocusScope {
    id: root

    focus: true

    implicitWidth: controlGuiMenuLoader.width
    implicitHeight: controlGuiMenuLoader.height

    onXChanged: {
            //when we open the control gui menu for the first time, qml incorrectly sets the window coordinates by x
            x = 137 * SettingsState.scale;
        }

    function open() {
        controlGuiMenuLoader.item.menu.open();
        controlGuiMenuLoader.item.requestActivate();

                controlGuiMenuLoader.item.x = mainWindow.x + root.x - 6 * SettingsState.scale;
                controlGuiMenuLoader.item.y = mainWindow.y + root.y - 6 * SettingsState.scale;
        root.implicitWidth = Qt.binding(function() { return controlGuiMenuLoader.item.width; });
        root.implicitHeight = Qt.binding(function() { return controlGuiMenuLoader.item.height; });
    }

    Component {
        id: controlGuiMenuComponent

        ApplicationWindow {
            id: window

            color: "transparent"

            flags: Qt.FramelessWindowHint | Qt.WindowMinimizeButtonHint
            property alias menu: menu
            property int windowRescale: AppFeatures.osType == OSType.MacOS ? 0 : 12 * SettingsState.scale

            width: scope.width + windowRescale
            height: scope.height + windowRescale
            visible: menu.visible

            property bool alwaysOnTop: mainWindow.alwaysOnTop

            onAlwaysOnTopChanged: {
                var flags = window.flags;
                flags = alwaysOnTop ? (flags | Qt.WindowStaysOnTopHint)
                                    : (flags & ~Qt.WindowStaysOnTopHint);
                window.flags = flags;
            }
            FocusScope {
                id: scope

                property alias menu: menu

                implicitWidth: menu.width
                implicitHeight: menu.height

                focus: true

                Menu {
                    id: menu

                    cascade: true
                    focus: true

                    margins: AppFeatures.osType == OSType.MacOS ? 0 : 6 * SettingsState.scale

                    onActiveFocusChanged: {
                        if (!activeFocus) {
                            close();
                        }
                    }

                    implicitWidth: item.width

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

                    MainMenuItem {
                        isChecked: SettingsState.twoWindowMode
                        actionLabel: qsTrId("settings_two_window_mode") + Translator.translate
                        topMargin: 1 * SettingsState.scale
                        roundTopCorners: true
                        onTriggered: {
                            ActionProvider.showTwoWindowMode(!isChecked)
                        }
                    }

                    MainMenuItem {
                        isChecked: SettingsState.multiWindowMode
                        actionLabel: qsTrId("settings_multi_window_mode") + Translator.translate

                        onTriggered: {
                            ActionProvider.showMultiWindowMode(!isChecked)
                        }
                    }

                    MainMenuItem {
                        isChecked: SettingsState.compactWindowMode
                        actionLabel: qsTrId("settings_compact_mode") + Translator.translate

                        onTriggered: {
                            ActionProvider.showCompactWindowMode(!isChecked);
                            mainWindow.requestActivate();
                        }
                    }

                    MainMenuSeparator {
                        color: ColorStorage.menuBorderColor
                    }

                    MainMenuItem {
                        id: item

                        elementWidth: 235 * SettingsState.scale

                        isChecked: SettingsState.showActiveCallsWindow
                        actionLabel: qsTrId("main_menu_active_calls_window") + Translator.translate

                        onTriggered: {
                            if (SettingsState.compactWindowMode) {
                                ActionProvider.showCompactWindowMode(false);
                            }
                            ActionProvider.showActiveCallsWindow(!isChecked);
                        }
                    }

                    MainMenuItem {
                        isChecked: SettingsState.showContactsWindow
                        actionLabel: qsTrId("main_menu_contacts_window") + Translator.translate

                        onTriggered: {
                            if (SettingsState.compactWindowMode) {
                                ActionProvider.showCompactWindowMode(false);
                            }
                            ActionProvider.showContactsWindow(!isChecked);
                        }
                    }

                    MainMenuItem {
                        id: callHistoryItem

                        isChecked: SettingsState.showHistoryWindow
                        actionLabel: qsTrId("main_menu_calls_history_window") + Translator.translate

                        onTriggered: {
                            if (SettingsState.compactWindowMode) {
                                ActionProvider.showCompactWindowMode(false);
                            }
                            ActionProvider.showHistoryWindow(!isChecked);
                        }
                    }

                    MainMenuItem {
                        id: messagingWindowItem

                        enabled: visible

                        visible: !AppFeatures.hideMessagingWindow && SettingsState.messagingEnable

                        //hiding messagingWindowItem in case of a disabled feature
                        height: {
                            if (AppFeatures.hideMessagingWindow || !SettingsState.messagingEnable)
                                return 0
                        }

                        isChecked: SettingsState.showMessagingWindow
                        actionLabel: qsTrId("main_menu_messaging_window") + Translator.translate

                        onTriggered: {
                            if (SettingsState.compactWindowMode) {
                                ActionProvider.showCompactWindowMode(false);
                            }
                            ActionProvider.showMessagingWindow(!isChecked);
                        }
                    }

                    MainMenuItem {
                        id: statisticWindowItem

                        enabled: visible

                        visible: !AppFeatures.hideStatisticsWindow

                        isChecked: SettingsState.showPersonalStatisticsWindow
                        actionLabel: qsTrId("main_menu_statistics_window") + Translator.translate

                        onTriggered: {
                            if (SettingsState.compactWindowMode) {
                                ActionProvider.showCompactWindowMode(false);
                            }
                            ActionProvider.showPersonalStatisticsWindow(!isChecked);
                        }
                    }

                    MainMenuSeparator {
                        id: middleSeparator
                        color: ColorStorage.menuBorderColor
                        anchors.top: {
                            if(!AppFeatures.hideStatisticsWindow)
                                return statisticWindowItem.bottom
                            if(!AppFeatures.hideMessagingWindow && SettingsState.messagingEnable)
                                return messagingWindowItem.bottom
                            return callHistoryItem.bottom
                        }
                    }

                    MainMenuItem {
                        id: alwaysOnTopItem
                        anchors.top: middleSeparator.bottom
                        enabled: true

                        isChecked: SettingsState.alwaysOnTop
                        actionLabel: qsTrId("main_menu_always_on_top") + Translator.translate

                        onTriggered: {
                            ActionProvider.alwaysOnTopEnable(!isChecked);
                        }
                    }

                    MainMenuItem {
                        id: restorePositionsItem
                        anchors.top: alwaysOnTopItem.bottom
                        actionLabel: qsTrId("settings_interface_windows_reset_positions") + Translator.translate
                        roundBottomCorners: true
                        bottomMargin: 1 * SettingsState.scale
                        onTriggered: {
                            ActionProvider.notifyWindowsRestorePositions();
                        }
                    }
                }
            }
        }
    }
    Loader {
        id: controlGuiMenuLoader
        sourceComponent: controlGuiMenuComponent
    }
}
