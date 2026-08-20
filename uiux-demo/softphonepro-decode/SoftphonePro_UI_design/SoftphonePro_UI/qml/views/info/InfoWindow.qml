import QtQuick 2.15
import Flux 1.0

import "../uicontrols"

FocusScope {
    id: root

    //height: body.height

    focus: true

    MouseArea {
        anchors.fill: parent

        onPressed: {
            initialFocusReceiver.forceActiveFocus();
        }
    }

    Rectangle {
        id: body

        width: parent.width
        height: parent.height

        color: ColorStorage.surfaceSecondary

        Row {
            id: title

            width: body.width
            height: body.height

            anchors.top: parent.top
            anchors.left: parent.left

            Image {
                id: backgroundImage
                width: title.width
                height: title.height
                anchors.top: title.top
                anchors.left: title.left
                source: AppState.updateInfo ? AppState.updateInfo.imageLink : ""
                SquareButton {
                    id: downloadButton

                    anchors.bottom:  backgroundImage.bottom
                    anchors.horizontalCenter: backgroundImage.horizontalCenter
                    anchors.bottomMargin: 20 * SettingsState.scale

                    width: 200 * SettingsState.scale
                    height: 36 * SettingsState.scale

                    radius: 28 * SettingsState.scale

                    borderWidth: 1
                    borderWidthOnHover: 2

                    color: AppState.updateInfo ? AppState.updateInfo.backgroundButtonColor : ColorStorage.sSizeButtonDefault
                    colorOnPress: AppState.updateInfo ? AppState.updateInfo.backgroundButtonColorOnPress : ColorStorage.sSizeButtonOnHover

                    borderColor: AppState.updateInfo ? AppState.updateInfo.buttonBorderColor : ColorStorage.windowBorder
                    borderColorOnHover:AppState.updateInfo ? AppState.updateInfo.buttonBorderColorOnPress : ColorStorage.windowBorder

                    property string updateLink: AppState.updateInfo.link

                    doWorkOnButtonClick: function() {
                        Qt.openUrlExternally(updateLink);
                    }

                    Text {
                        id: downloadButtonText
                        anchors.centerIn: parent

                        text: AppState.updateInfo ? AppState.updateInfo.buttonText : ""
                        color: AppState.updateInfo ? AppState.updateInfo.buttonTextColor : ColorStorage.windowBorder

                        font.pixelSize: AppState.updateInfo ? AppState.updateInfo.buttonTextSize * SettingsState.scale : 16 * SettingsState.scale
                        font.family: AppState.updateInfo ? AppState.updateInfo.family : "Segoe UI"

                        wrapMode: Text.WordWrap
                    }
                }

            }
        }

        Item {
            id: initialFocusReceiver

            anchors.bottom: body.top
            anchors.left: body.left

            width: 0 * SettingsState.scale
            height: 0 * SettingsState.scale

            focus: true

            KeyNavigation.tab: {
                return downloadButton;
            }
        }
    }
}
