import QtQuick 2.15
import Flux 1.0

import "../uicontrols"

FocusScope {
    id: root

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
        height: {
            if (!AppState.licenseInfo) {
                return 0;
            }

            var height = titleLayer.height + description.height + description.anchors.topMargin;

            if (errorLink.visible) {
                height += errorLink.height + errorLink.anchors.topMargin;
            }

            if (buyMoreButton.visible || buyButtons.visible) {
                height += buyMoreButton.height + buyMoreButton.anchors.topMargin;
            }

            // bottom margin
            height += 20 * SettingsState.scale;
        }

        color: ColorStorage.secondaryWindowBackground

        Rectangle {
            id: titleLayer

            anchors.top: parent.top
            anchors.left: parent.left

            color: "transparent"
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

                color: ColorStorage.secondaryWindowTitleAndIcons //white: "#000000" //black: #FFFFFF

                text: AppState.licenseInfo ? AppState.licenseInfo.title : ""
            }
        }

        Text {
            id: description

            anchors.top: titleLayer.bottom
            anchors.topMargin: 10 * SettingsState.scale
            anchors.left: parent.left
            anchors.leftMargin: 16 * SettingsState.scale
            anchors.right: parent.right
            anchors.rightMargin: 16 * SettingsState.scale

            text: AppState.licenseInfo ? AppState.licenseInfo.description : ""

            font.pixelSize: 12 * SettingsState.scale
            font.family: "Segoe UI"

            color: ColorStorage.errorWindowTextColor

            wrapMode: Text.WordWrap
        }

        Text {
            id: errorLink

            anchors.top: description.bottom
            anchors.topMargin: 5 * SettingsState.scale
            anchors.left: parent.left
            anchors.leftMargin: 16 * SettingsState.scale
            anchors.rightMargin: 16 * SettingsState.scale

            visible: AppState.licenseInfo && AppState.licenseInfo.state != License.DemoActive &&
                     AppState.licenseInfo.state != License.DemoFinished && AppState.licenseInfo.errorLink != ""

            text: "<a href='" + (AppState.licenseInfo ? AppState.licenseInfo.errorLink : "")
                  + "'>" + qsTrId("license_info_error_link_desc") + "</a>" + Translator.translate

            font.pixelSize: 12 * SettingsState.scale
            font.family: "Segoe UI"

            color: ColorStorage.errorWindowTextColor

            wrapMode: Text.WordWrap

            onLinkActivated: Qt.openUrlExternally(link)

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
        }

        Item {
            id: initialFocusReceiver

            anchors.bottom: body.top
            anchors.left: body.left

            width: 0 * SettingsState.scale
            height: 0 * SettingsState.scale

            focus: true
        }


        SquareButton {
            id: buyMoreButton

            anchors.top: errorLink.visible ? errorLink.bottom : description.bottom
            anchors.topMargin: 20 * SettingsState.scale
            anchors.left: parent.left
            anchors.leftMargin: 16 * SettingsState.scale
            anchors.right:  parent.right
            anchors.rightMargin: 16 * SettingsState.scale

            height: 24 * SettingsState.scale

            visible: AppState.licenseInfo && AppState.licenseInfo.state == License.UserCountExceed

            radius: 8 * SettingsState.scale

            borderWidth: 1
            borderWidthOnHover: 2

            color: ColorStorage.white
            colorOnPress: ColorStorage.sSizeButtonOnPress

            borderColor: ColorStorage.windowBorder
            borderColorOnHover: ColorStorage.windowBorder

            doWorkOnButtonClick: function() {
                Qt.openUrlExternally(AppState.licenseInfo.buyMoreLink);
            }

            Text {
                anchors.centerIn: parent

                text: qsTrId("license_info_buy_more_desc") + Translator.translate
                color: ColorStorage.windowBorder

                font.pixelSize: 13 * SettingsState.scale
                font.family: "Segoe UI"
            }
        }

        Row {
            id: buyButtons

            anchors.top: errorLink.visible ? errorLink.bottom : description.bottom
            anchors.topMargin: 20 * SettingsState.scale
            anchors.left: parent.left
            anchors.leftMargin: 16 * SettingsState.scale
            anchors.right: parent.right
            anchors.rightMargin:  16 * SettingsState.scale

            spacing: 15 * SettingsState.scale

            visible: AppState.licenseInfo && AppState.licenseInfo.state == License.DemoFinished


            SquareButton {
                id: buyButton

                width: (parent.width - parent.spacing) / 2
                height: 24 * SettingsState.scale

                radius: 8 * SettingsState.scale

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

                doWorkOnButtonClick: function() {
                    Qt.openUrlExternally(AppState.licenseInfo.buyLink);
                }

                Text {
                    anchors.centerIn: parent

                    text: qsTrId("license_info_buy_desc") + Translator.translate
                    color: buyButton.enabled ? ColorStorage.iconsAndTextPrimary : ColorStorage.textAndDisabledIconsGrey

                    font.pixelSize: 13 * SettingsState.scale
                    font.family: "Segoe UI"
                }
            }

            SquareButton {
                id: enterLicenseButton

                width: (parent.width - parent.spacing) / 2
                height: 24 * SettingsState.scale

                visible: true

                radius: 8 * SettingsState.scale

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

                doWorkOnButtonClick: function() {
                    ActionProvider.quickEnterLicenseKey();
                }

                Text {
                    anchors.centerIn: parent

                    text: qsTrId("license_info_enter_license_desc") + Translator.translate
                    color: enterLicenseButton.enabled ? ColorStorage.iconsAndTextPrimary : ColorStorage.textAndDisabledIconsGrey

                    font.pixelSize: 13 * SettingsState.scale
                    font.family: "Segoe UI"
                }
            }
        }
    }
}
