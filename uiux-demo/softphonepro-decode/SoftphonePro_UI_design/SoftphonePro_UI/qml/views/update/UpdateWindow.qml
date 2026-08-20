import QtQuick 2.15
import Flux 1.0

import "../uicontrols"

FocusScope {
    id: root

    property alias name: appName.text
    property alias version: appVersion.text
    property alias description: appDescription.text
    property alias title: titleText.text
    property alias updateLink: downloadButton.updateLink

    height: body.height

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
        height: title.height + appDescription.height + downloadButton.height + 70 * SettingsState.scale

        color: ColorStorage.secondaryWindowBackground

        Row {
            id: title

            anchors.top: parent.top
            anchors.topMargin: 20 * SettingsState.scale
            anchors.left: parent.left
            anchors.leftMargin: 10 * SettingsState.scale

            spacing: 5 * SettingsState.scale

            Text {
                id: titleText
                text: qsTrId("update_window_has_new_version") + Translator.translate

                font.pixelSize: 14 * SettingsState.scale
                font.family: "Segoe UI"
                font.weight: Font.Bold
            }

            Text {
                id: appName

                text: "Softphone PRO"

                font.pixelSize: 14 * SettingsState.scale
                font.family: "Segoe UI"
                font.weight: Font.Bold

                color: ColorStorage.iconsAndTextPrimary
            }


            Text {
                id: appVersion

                anchors.baseline: appName.baseline

                visible: false

                text: AppState.updateInfo ? AppState.updateInfo.version : ""

                font.pixelSize: 16 * SettingsState.scale
                font.family: "Segoe UI"
                font.weight: Font.Bold

                color: ColorStorage.iconsAndTextPrimary
            }

        }

        Text {
            id: appDescription

            anchors.top: title.bottom
            anchors.topMargin: 10 * SettingsState.scale
            anchors.left: title.left
            anchors.right: parent.right
            anchors.rightMargin: 20 * SettingsState.scale

            text: AppState.updateInfo ? AppState.updateInfo.description : ""

            font.pixelSize: 12 * SettingsState.scale
            font.family: "Segoe UI"

            color: ColorStorage.errorWindowTextColor

            wrapMode: Text.WordWrap
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

        SquareButton {
            id: downloadButton

            anchors.top: appDescription.bottom
            anchors.topMargin: 20 * SettingsState.scale
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 20 * SettingsState.scale

            width: 200 * SettingsState.scale
            height: 36 * SettingsState.scale

            radius: 28 * SettingsState.scale

            borderWidthDefault: 1 * SettingsState.scale
            borderWidthOnHover: 1 * SettingsState.scale
            borderWidthOnPress: 1 * SettingsState.scale
            borderWidthOnDisabled: 1 * SettingsState.scale

            colorDefault: "transparent"
            colorOnPress: ColorStorage.sSizeButtonOnPress
            colorOnHover: ColorStorage.sSizeButtonOnHover
            colorOnDisabled: ColorStorage.sSizeButtonDisabled

            borderColorDefault: ColorStorage.invertedBorder
            borderColorOnDisabled: ColorStorage.grayNeutralOnPress

            property string updateLink: AppState.updateInfo.link

            doWorkOnButtonClick: function() {
                Qt.openUrlExternally(updateLink);
            }

            Text {
                anchors.centerIn: parent

                text: qsTrId("update_window_load_update") + Translator.translate
                color: downloadButton.enabled ? ColorStorage.iconsAndTextPrimary : ColorStorage.textAndDisabledIconsGrey

                font.pixelSize: 16 * SettingsState.scale
                font.family: "Segoe UI"
            }
        }
    }
}
