import QtQuick 2.15
import QtQuick.Layouts 1.3
import Flux 1.0

import "../utils"

Item {
    id: root

    implicitWidth: 300 * SettingsState.scale
    implicitHeight: 53 * SettingsState.scale

    property string name: ""
    property string company: ""
    property string crm: ""
    property string link: ""

    readonly property string colorDefault: ColorStorage.mainWindowBackground
    readonly property string colorOnHover: ColorStorage.surfaceSecondary
    readonly property string colorOnPress: ColorStorage.buttonSecondaryOnPress

    property string imageColorDefault: ""

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onEntered: {
            body.color = root.colorOnHover;
        }

        onExited: {
            if (pressed) {
                return;
            }
            body.color = root.colorDefault;
        }

        onPressed: {
            body.color = root.colorOnPress;
        }

        onReleased: {
            if (containsMouse && link.length != 0) {
                Qt.openUrlExternally(root.link);
                body.color = root.colorOnHover;
                return;
            }
            body.color = root.colorDefault;
        }
    }

    Rectangle {
        id: body

        anchors.fill: parent

        radius: 8 * SettingsState.scale
        color: root.colorDefault

        Rectangle {
            id: imageBorder

            anchors.top: parent.top
            anchors.left: parent.left

            width: 58 * SettingsState.scale
            height: 58 * SettingsState.scale
            color: "transparent"

            Image {
                id: image

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                visible: false

                width: 32 * SettingsState.scale
                height: 32 * SettingsState.scale

                sourceSize.width: width
                sourceSize.height: height

                source: "qrc:/images/account_circle.svg"   
            }

            IconShader {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

                imageSrcComponent: image
                imgColor: root.imageColorDefault
                imageWidth: image.width
                imageHeight: image.height
            }


        }

        Rectangle {
            id: infoBorder

            width: parent.width - imageBorder.width
            height: 53 * SettingsState.scale

            anchors.top: parent.top
            anchors.left: imageBorder.right
            color: "transparent"

            property int crmNameLeftMargin: 5 * SettingsState.scale
            property int crmNameRightMargin: 5 * SettingsState.scale

            Text {
                id: firstName

                anchors.left: parent.left
                anchors.top: parent.top
                anchors.topMargin: 11 * SettingsState.scale
                anchors.right: parent.right
                anchors.rightMargin: 20 * SettingsState.scale

                elide: Text.ElideRight

                font.pixelSize: 13 * SettingsState.scale
                font.family: "Segoe UI"
                font.bold: true
                color: ColorStorage.iconsAndTextPrimary

                text: root.name
            }

            Text {
                id: companyName

                anchors.top: firstName.bottom
                anchors.topMargin: 1 * SettingsState.scale
                anchors.left: parent.left

                elide: Text.ElideRight

                font.pixelSize: 14 * SettingsState.scale
                font.family: "Segoe UI"

                color: ColorStorage.iconsAndTextSecondary
                text: root.company

                function getWidth() {
                    if (companyName.text.length == 0) {
                        return 0;
                    }

                    var maxWidth = parent.width - crmName.implicitWidth - parent.crmNameLeftMargin - parent.crmNameRightMargin;
                    if ( companyName.implicitWidth > maxWidth) {
                        return maxWidth;
                    }

                    return companyName.implicitWidth;
                }

                onTextChanged: {
                    companyName.width = getWidth();
                }
            }

            Text {
                id: crmName

                anchors.verticalCenter: companyName.verticalCenter
                anchors.left: companyName.right
                anchors.leftMargin: companyName.width == 0 ? 0 : parent.crmNameLeftMargin
                anchors.right: parent.right
                anchors.rightMargin: parent.crmNameRightMargin

                font.pixelSize: 14 * SettingsState.scale
                font.family: "Segoe UI"

                color: ColorStorage.iconsAndTextSecondary
                text: root.crm

                onTextChanged: {
                    var maxCompanyWidth = parent.width - crmName.implicitWidth - parent.crmNameLeftMargin - parent.crmNameRightMargin;
                    if (companyName.width > maxCompanyWidth) {
                        companyName.width = maxCompanyWidth;
                    }
                }
            }
        }
    }
}
