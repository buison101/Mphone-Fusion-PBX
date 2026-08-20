import QtQuick 2.15
import Flux 1.0

import "../main"
import "../uicontrols"

FocusScope {
    id: root

    implicitWidth: 363 * SettingsState.scale
    implicitHeight: 180 * SettingsState.scale

    property alias input: inputLayer

    property var tryMakeCall: function() {
        if (!inputLayer.disableWorkFunction) {
            ActionProvider.makeCallViaClipboard(inputLayer.edit.text);
            inputLayer.secondsDisabledLeft = 0;
            inputLayer.disableWorkFunction = true;
        }
    }

    Rectangle {
        width: parent.width
        height: parent.height

        color: ColorStorage.secondaryWindowBackground


        Rectangle {
            id: titleLayer

            anchors.top: parent.top
            anchors.left: parent.left

            color: ColorStorage.secondaryWindowTitleBackgroundColor
            width: parent.width
            height: 31 * SettingsState.scale

            Text {
                id: title

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 16 * SettingsState.scale

                font.pixelSize: 12 * SettingsState.scale
                font.family: "Segoe UI"
                font.bold: true

                color: ColorStorage.secondaryWindowTitleAndIcons

                text: qsTrId("clipboard_window_title") + Translator.translate
            }
        }

        SeparatorWithAccount {
            id: separatorWithAccount

            anchors.top: titleLayer.bottom
            anchors.topMargin: 12 * SettingsState.scale
            anchors.left: parent.left
            anchors.leftMargin: 16 * SettingsState.scale
            anchors.right: parent.right
            anchors.rightMargin: 16 * SettingsState.scale

            account: AppState.sipAccount
        }

        PhoneInput {
            id: inputLayer

            fromClipboard: true

            anchors.top: separatorWithAccount.bottom
            anchors.topMargin: -9 * SettingsState.scale
            anchors.left: parent.left
            anchors.leftMargin: 20 * SettingsState.scale

            edit.text: AppState.clipboardNumber
            edit.enabled: true
            backspaceButton.enabled: false
            backspaceButton.visible: false

            focus: true

            implicitWidth: parent.width - 40 * SettingsState.scale

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
        }

        SquareButton {
            id: callButton

            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 56 * SettingsState.scale

            scale: SettingsState.scale

            colorDefault: ColorStorage.green
            colorOnHover: ColorStorage.greenOnHover
            colorOnPress: ColorStorage.greenOnPress
            colorOnDisabled: ColorStorage.disabledButtonsGrey

            imageColorDefault: ColorStorage.white
            imageColorOnHover: ColorStorage.white
            imageColorOnPress: ColorStorage.white
            imageColorOnDisabled: ColorStorage.textAndDisabledIconsGrey

            imageWidth: 28 * SettingsState.scale
            imageHeight: 28 * SettingsState.scale

            imageDefault: "qrc:/images/call_default.svg"

            doWorkOnButtonClick: function() {
                tryMakeCall();
            }
        }
    }

}
