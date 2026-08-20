import QtQuick 2.15
import QtQuick.Controls 2.15
import Flux 1.0

import "../uicontrols"
import "../utils"

FocusScope {
    id: root

    focus: true
    property var openCallForwardDropdown: function() {
        mainMenu.openCallForwardDropdown();
    }

    property var openEmailNotificationDropdown: function() {
        mainMenu.openEmailNotificationDropdown();
    }

    property var closeMainMenu: function() {
        mainMenu.close();
    }

    MainMenuPopup {
        id: mainMenu

        anchors.top: parent.top
        anchors.topMargin: 7 * SettingsState.scale
        anchors.left: parent.left
        anchors.leftMargin: 7 * SettingsState.scale
    }

    Rectangle {
        id: titleLayer

        anchors.fill: parent

        color: ColorStorage.titleBackgroundColor

        Rectangle {
            id: body

            anchors.top: parent.top
            anchors.left: parent.left

            readonly property string colorDefault: "transparent"
            readonly property string colorOnHover: ColorStorage.mainWindowTitleButtonOnHover
            readonly property string colorOnPress: ColorStorage.mainWindowTitleButtonOnPress

            height: root.height
            width: height

            color: colorDefault

            focus: true

            MouseArea {
                anchors.fill: parent

                hoverEnabled: true

                onEntered: {
                    opacityRect.opacity = 0.1;
                }

                onExited: {
                    opacityRect.opacity = 0;
                }

                onPressed: {
                    opacityRect.opacity = 0.15;
                }

                onReleased: {
                    if (!containsMouse) {
                        return;
                    }

                    opacityRect.opacity = 0;
                    mainMenu.open();
                }
            }

            Rectangle {
                id: opacityRect

                anchors.fill: parent
                color: ColorStorage.iconsAndTextPrimary
                opacity: 0

                enabled: false
            }
            Image {
                id: appImage

                Accessible.role: Accessible.Button
                Accessible.name: "MainMenuPopup"

                anchors.centerIn: parent
                width: 24 * SettingsState.scale
                height: width
                visible: false

                sourceSize.width: width
                sourceSize.height: height

                source: "qrc:/images/headset_white.svg"
            }

            IconShader {
                anchors.centerIn: parent
                imageSrcComponent: appImage
                imgColor: ColorStorage.mainWindowTitleAndIcons //white: "#000000" // black: #FFFFFF
                imageWidth: appImage.width
                imageHeight: appImage.height
            }
        }

        Component {
            id: baseLogoComponent

            Text {
                id: title

                font.pixelSize: 13 * SettingsState.scale
                font.family: "Segoe UI"
                font.bold: true

                color: ColorStorage.mainWindowTitleAndIcons

                text: StringStorage.appTitle
            }
        }

        Loader {
            id: baseLogoLoader


            anchors.left: body.right
            anchors.leftMargin: 8 * SettingsState.scale

            anchors.top: parent.top
            anchors.topMargin: 10 * SettingsState.scale

            sourceComponent: baseLogoComponent
        }
    }
}
