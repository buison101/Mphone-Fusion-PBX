import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtGraphicalEffects 1.15
import Flux 1.0

import "../utils"
import "../main"

FocusScope {
    id: root

    focus: true
    implicitWidth: dialpadLoader.width
    implicitHeight: dialpadLoader.height

    property bool alwaysOnTop: false

    property bool activeLoader: true

    onImplicitWidthChanged: {
        if (Screen.desktopAvailableWidth < root.x + root.width) {
            root.x -= root.width;
            dialpadLoader.item.x = root.x;
        }
    }

    onImplicitHeightChanged: {
        if (Screen.desktopAvailableHeight < root.y + root.height) {
            root.y -= root.height;
            dialpadLoader.item.y = root.y;
        }
    }

    function open() {
        dialpadLoader.item.dropdown.open();
        dialpadLoader.item.requestActivate();

        if (Screen.desktopAvailableWidth < root.x + root.width) {
            root.x -= root.width;
        }

        if (Screen.desktopAvailableHeight < root.y + root.height) {
            root.y -= root.height;
        }

        dialpadLoader.item.x = root.x;
        dialpadLoader.item.y = root.y;

        root.implicitWidth = Qt.binding(function() { return dialpadLoader.item.width; });
        root.implicitHeight = Qt.binding(function() { return dialpadLoader.item.height; });
    }

    Component {
        id: dialpadComponent

        ApplicationWindow {
            id: window

            property alias dropdown: dropdown

            flags: Qt.FramelessWindowHint | Qt.WindowMinimizeButtonHint

            width: scope.width + 16 * SettingsState.scale
            height: scope.height + 16 * SettingsState.scale
            color: "transparent"
            visible: dropdown.visible

            property bool alwaysOnTop: root.alwaysOnTop

            onAlwaysOnTopChanged: {
                var flags = window.flags;
                flags = root.alwaysOnTop ? (flags | Qt.WindowStaysOnTopHint)
                                         : (flags & ~Qt.WindowStaysOnTopHint);
                window.flags = flags;
            }

            FocusScope {
                id: scope

                implicitWidth: dropdown.width
                implicitHeight: dropdown.height

                focus: true

                Popup {
                    id: dropdown
                    margins: 8 * SettingsState.scale
                    width: 364 * SettingsState.scale
                    height: 404 * SettingsState.scale
                    closePolicy: Popup.CloseOnPressOutside

                    contentItem: Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        PhoneInput{

                            id: phoneInput

                            Accessible.role: Accessible.Button
                            Accessible.name: "PhoneInputLayer"

                            anchors.top: parent.top
                            anchors.topMargin: 26 * SettingsState.scale
                            anchors.left: parent.left
                            anchors.leftMargin: 20 * SettingsState.scale

                            implicitWidth: parent.width - 40 * SettingsState.scale
                            implicitHeight: 20 * SettingsState.scale
                            focus: true

                            Keys.onReturnPressed: {
                                tryMakeCall();
                            }

                            Keys.onEnterPressed: {
                                tryMakeCall();
                            }

                            property var timeNow: AppState.timeNow
                            property int secondsDisabledMax: 2
                            property int secondsDisabledLeft: 0
                            property bool disableWorkFunction: false

                            onTimeNowChanged: {
                                if (secondsDisabledLeft == secondsDisabledMax) {
                                    return;
                                }

                                secondsDisabledLeft += 1;

                                if (secondsDisabledLeft == secondsDisabledMax) {
                                    disableWorkFunction = false;
                                }
                            }

                            onEnabledChanged: {
                                if (!enabled) {
                                    return;
                                }

                                secondsDisabledLeft = 0;
                                disableWorkFunction = true;
                            }

                            onVisibleChanged: {
                                if (visible) {
                                    forceActiveFocus()
                                }
                            }

                            onContextMenuIsOpenChanged: {
                                if (!contextMenuIsOpen) {
                                    window.requestActivate();
                                    if (!activeFocus && !pad.activeFocus) {
                                        dropdown.close();
                                    }
                                }
                            }

                            onActiveFocusChanged: {
                                if (!activeFocus && !pad.activeFocus && !contextMenuIsOpen) {
                                    dropdown.visible = false;
                                }
                            }
                        }

                        MainMenuSeparator {
                            id: separator
                            width: parent.width
                            anchors.top: phoneInput.bottom
                            anchors.topMargin: 25 * SettingsState.scale
                            height: 1 * SettingsState.scale
                            color: ColorStorage.menuBorderColor
                        }


                        FocusScope {
                            id: pad

                            width: 362 * SettingsState.scale
                            height: 314 * SettingsState.scale
                            anchors.top: separator.bottom
                            focus: true

                            NumPad {
                                id: numpad
                                buttonColorOnHover: ColorStorage.mainWindowNumButtonOnHover
                                buttonColorOnPress: ColorStorage.mainWindowNumButtonOnPress
                                focus: true
                                anchors {
                                    fill: parent
                                    leftMargin: 20 * SettingsState.scale
                                    topMargin: 16 * SettingsState.scale
                                }
                            }
                        }
                    } 

                    background: Rectangle {
                        radius: 8 * SettingsState.scale
                        color: ColorStorage.mainWindowBackground
                        MouseArea{
                            anchors.fill: parent
                            onPressed: {
                                pad.forceActiveFocus();
                            }
                        }
                        MenuShadow {
                            scale: SettingsState.scale
                            anchors.fill: parent
                            visible: dropdown.visible
                            bodyColor: ColorStorage.mainWindowBackground
                            shadowColor: ColorStorage.menuShadowColor
                        }
                    }
                }
            }
        }
    }

    Loader {
        id: dialpadLoader
        sourceComponent: dialpadComponent
        active: activeLoader
    }
}
