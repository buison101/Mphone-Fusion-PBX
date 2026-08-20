import QtQuick 2.15
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.15
import Flux 1.0

Item {
    width: parent.width
    height: {
        if (!body.visible) {
            return 0
        }

        return 10 * SettingsState.scale
    }

    property alias account: account.text
    property int currentCallDirection

    Rectangle {
        id: body

        width: parent.width
        height: parent.height
        visible: currentCallDirection != SipCall.Conference

        color: "transparent"

        Rectangle {
            anchors.left: parent.left
            anchors.right: accountLayout.left
            anchors.rightMargin: 20 * SettingsState.scale
            anchors.verticalCenter: accountLayout.verticalCenter
            anchors.horizontalCenterOffset: 2

            height: 1

            color: ColorStorage.textAndDisabledIconsGrey //white: "#ACACAC" //black: #545454
        }

        RowLayout {
            id: accountLayout

            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter:  parent.horizontalCenter

            Text {
                id: account
                Layout.maximumWidth: 150 * SettingsState.scale
                Layout.minimumWidth: 10 * SettingsState.scale

                Layout.fillHeight: true
                Layout.fillWidth: true

                elide: Text.ElideRight

                font.pixelSize: 12 * SettingsState.scale
                font.family: "Segoe UI"

                color: ColorStorage.textAndDisabledIconsGrey //white: "#ACACAC" //black: #545454

                MouseArea {
                    hoverEnabled: true
                    anchors.fill: parent
                    ToolTip {
                        id: toolTip
                        visible: parent.containsMouse && content.text && account.implicitWidth > account.width
                        delay: 1000
                        timeout: 5000
                        clip: true
                        background: Rectangle {
                            id: background
                            color: ColorStorage.iconsAndTextPrimary
                        }
                        contentItem: Text {
                            id: content
                            text: account.text ? account.text : ""
                            color: ColorStorage.mainWindowBackground
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.left: accountLayout.right
            anchors.leftMargin: 20 * SettingsState.scale
            anchors.verticalCenter: accountLayout.verticalCenter
            anchors.horizontalCenterOffset: 2

            height: 1

            color: ColorStorage.textAndDisabledIconsGrey //white: "#ACACAC" //black: #545454
        }
    }
}
