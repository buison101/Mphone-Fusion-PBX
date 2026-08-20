import QtQuick 2.15
import QtQuick.Controls 2.15
import Flux 1.0

import "../utils"

MenuItem {
    id: root

    property alias actionLabel: action.text
    property alias shortcutLabel: shortcut.text
    property bool isChecked: false
    property int textLeftMargin: 5 * SettingsState.scale
    property bool roundBottomCorners: false
    property bool roundTopCorners: false
    property int elementWidth: 215 * SettingsState.scale
    property int elementHeight: 30 * SettingsState.scale
    property int topMargin: 0 * SettingsState.scale
    property int bottomMargin: 0 * SettingsState.scale
    property bool ignoreHover: false
    property bool lastItem: false
    property var resetIgnoreHover: function() {}

    Shortcut {
        enabled: true
        sequence: root.shortcut

        onActivated: {
            root.triggered();
        }
    }

    onHighlightedChanged: {
        if (highlighted) {
            root.forceActiveFocus();
            body.color = body.colorOnHover;
        } else {
            body.color = body.colorDefault;
        }
    }

    background: Rectangle {
        id: border

        color: "transparent"

        implicitWidth: root.elementWidth
        implicitHeight: root.elementHeight

        Rectangle {
            id: body

            anchors.top: parent.top
            anchors.topMargin: root.topMargin
            anchors.left: parent.left
            anchors.leftMargin: 1 * SettingsState.scale

            radius: roundBottomCorners || roundTopCorners ? 8 * SettingsState.scale : 0

            implicitWidth: border.width - 2 * SettingsState.scale
            implicitHeight: border.height - root.topMargin - root.bottomMargin

            opacity: enabled ? 1 : 0.3

            readonly property string colorDefault: ColorStorage.surfaceSecondary
            readonly property string colorOnHover: ColorStorage.mainWindowBackground

            color: colorDefault

            onActiveFocusChanged: {
                if(!activeFocus) {
                    body.color = body.colorDefault;
                    root.highlighted = false;
                }
            }

            MouseArea {
                enabled: root.enabled

                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    if (root.ignoreHover && mouseX > 5 && mouseX < parent.width - 5) {
                        if (lastItem && mouseY > 5) {
                            return;
                        } else if (!lastItem) {
                            return;
                        }
                    }
                    body.color = body.colorOnHover;
                    root.highlighted = true;
                    body.forceActiveFocus();
                }

                onExited: {
                    root.resetIgnoreHover();
                    body.color = body.colorDefault;
                    root.highlighted = false;
                }

                onReleased: {
                    if (containsMouse) {
                        root.triggered();
                        body.color = body.colorDefault;
                        root.highlighted = false;
                    }
                }
            }

            Rectangle {
                id: bottomCorners

                anchors.bottom: parent.bottom

                height: parent.height / 3
                width: parent.width
                color: parent.color
                enabled: false
                visible: roundTopCorners
            }

            Rectangle {
                id: topCorners

                anchors.top: parent.top

                height: parent.height / 3
                width: parent.width
                color: parent.color
                enabled: false
                visible: roundBottomCorners
            }
        }
    }

    contentItem: Rectangle {
        width: body.width
        height: body.height

        color: "transparent"

        Image {
            id: image
            source: root.isChecked ? "qrc:/images/check.svg" : ""

            width: 18 * SettingsState.scale
            height: 18 * SettingsState.scale
            visible: false

            sourceSize.width: width
            sourceSize.height: height

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
        }

        IconShader {
            visible: root.isChecked
            anchors.centerIn: image
            imageSrcComponent: image
            imgColor: ColorStorage.iconsAndTextSecondary

            imageWidth: image.width
            imageHeight: image.height
        }

        Text {
            id: action

            anchors.left: image.right
            anchors.leftMargin: root.textLeftMargin
            anchors.verticalCenter: parent.verticalCenter

            font.family: "Segoe UI"
            font.pixelSize: 12 * SettingsState.scale

            color: root.enabled ? ColorStorage.iconsAndTextPrimary : ColorStorage.iconsAndTextSecondary
        }

        Text {
            id: shortcut

            anchors.right: parent.right
            anchors.rightMargin: 10 * SettingsState.scale
            anchors.verticalCenter: parent.verticalCenter

            font.family: "Segoe UI"
            font.pixelSize: 12 * SettingsState.scale

            color: root.enabled ? ColorStorage.iconsAndTextPrimary : ColorStorage.iconsAndTextSecondary
        }
    }
}
