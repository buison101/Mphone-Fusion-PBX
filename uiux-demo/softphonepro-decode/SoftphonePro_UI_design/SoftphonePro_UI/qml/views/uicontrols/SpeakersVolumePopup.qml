import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import Flux 1.0

FocusScope {
    id: root

    focus: true
    implicitWidth: phonesDropdownLoader.width
    implicitHeight: phonesDropdownLoader.height

    property bool alwaysOnTop: false
    property string sliderBackgroudColor

    onImplicitWidthChanged: {
        if (Screen.desktopAvailableWidth < root.x + root.width) {
            root.x -= root.width;
            phonesDropdownLoader.item.x = root.x;
        }
    }

    onImplicitHeightChanged: {
        if (Screen.desktopAvailableHeight < root.y + root.height) {
            root.y -= root.height;
            phonesDropdownLoader.item.y = root.y;
        }
    }

    function open() {
        phonesDropdownLoader.item.dropdown.open();
        phonesDropdownLoader.item.requestActivate();

        if (Screen.desktopAvailableWidth < root.x + root.width) {
            root.x -= root.width;
        }

        if (Screen.desktopAvailableHeight < root.y + root.height) {
            root.y -= root.height;
        }

        phonesDropdownLoader.item.x = root.x;
        phonesDropdownLoader.item.y = root.y;

        root.implicitWidth = Qt.binding(function() { return phonesDropdownLoader.item.width; });
        root.implicitHeight = Qt.binding(function() { return phonesDropdownLoader.item.height; });
    }

    Component {
        id: phonesDropdownComponent

        ApplicationWindow {
            id: window

            property alias dropdown: dropdown

            flags: Qt.FramelessWindowHint | Qt.WindowMinimizeButtonHint

            width: scope.width
            height: scope.height

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

                property var doWorkOnListItemClick: function(phone) {
                    if (AppState.activeCall) {
                        ActionProvider.transferCall(AppState.activeCall.id, phone);
                    }
                }

                Popup {
                    id: dropdown

                    width: border.width
                    height: border.height

                    closePolicy: Popup.CloseOnPressOutside

                    contentItem: Rectangle {
                        anchors.fill: parent
                        color: "transparent"

                        Rectangle {
                            id: border

                            width: 260 * SettingsState.scale
                            height: 35 * SettingsState.scale

                            border.color: ColorStorage.windowBorder
                            border.width: 1 * SettingsState.scale
                            color: sliderBackgroudColor
                            enabled: visible
                            focus: true

                            VolumeSlider {
                                id: slider

                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 10 * SettingsState.scale
                                anchors.right: parent.right
                                anchors.rightMargin: 20 * SettingsState.scale
                                imageColor: ColorStorage.iconsAndTextSecondary
                                imgWidth: 26 * SettingsState.scale
                                imgHeight: 26 * SettingsState.scale
                                colorBeforeHandle: ColorStorage.iconsAndTextSecondary
                                colorAfterHandle: ColorStorage.sSizeButtonImageDisabled

                                onActiveFocusChanged: {
                                    if (!activeFocus) {
                                        dropdown.visible = false;
                                    }
                                }
                            }
                        }
                    }

                    background: Rectangle {
                        border.color: ColorStorage.sSizeButtonBorderDefault
                        border.width: 1 * SettingsState.scale
                        color: ColorStorage.surfaceSecondary
                    }
                }
            }
        }
    }

    Loader {
        id: phonesDropdownLoader
        sourceComponent: phonesDropdownComponent
    }
}
