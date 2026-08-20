import QtQuick 2.15
import Flux 1.0

import "../uicontrols"

FocusScope {
    id: root

    property alias title: title.text
    property alias description: description.text
    property alias errLink: errorLink.link
    property alias errLinkText: errorLink.linkText
    property alias errLinkEnable: errorLink.visible

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
            var height = titleLayer.height + description.height + description.anchors.topMargin;

            if (errorLink.visible) {
                height += errorLink.height + errorLink.anchors.topMargin;
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

                text: ""
            }
        }

        Text {
            id: description

            anchors.top: titleLayer.bottom
            anchors.topMargin: 8 * SettingsState.scale
            anchors.left: parent.left
            anchors.leftMargin: 16 * SettingsState.scale
            anchors.right: parent.right
            anchors.rightMargin: 16 * SettingsState.scale

            text: ""

            font.pixelSize: 12 * SettingsState.scale
            font.family: "Segoe UI"

            color: ColorStorage.iconsAndTextPrimary

            wrapMode: Text.WordWrap
        }

        Text {
            id: errorLink

            anchors.top: description.bottom
            anchors.topMargin: 11 * SettingsState.scale
            anchors.left: parent.left
            anchors.leftMargin: 16 * SettingsState.scale
            anchors.right: parent.right
            anchors.rightMargin: 16 * SettingsState.scale

            property string link: ""
            property string linkText: ""

            visible: true

            text: "<a href='" + link + "'>" + linkText + "</a>" + Translator.translate

            font.pixelSize: 12 * SettingsState.scale
            font.family: "Segoe UI"

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
    }
}
