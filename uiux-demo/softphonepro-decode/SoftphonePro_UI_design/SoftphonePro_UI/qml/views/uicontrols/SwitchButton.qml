import QtQuick 2.15
import Flux 1.0

import "../utils"

Item {

    id: root

    property string source
    property string sourceColorOnEnable: ColorStorage.switchButtonImageColorOnEnable
    property string sourceColorOnDisable: ColorStorage.switchButtonImageColorOnDisable
    property string shaderImageColor: sourceColorOnDisable

    property int imageWidth: 15 * SettingsState.scale
    property int imageHeight: 15 * SettingsState.scale

    property bool isChecked: false

    property var doWorkOnButtonClick: function() {}

    onIsCheckedChanged: {
        //Color on hovered is equal to main window title color with blacking-out
        if (isChecked || (!isChecked && mouseArea.released && mouseArea.containsMouse)) {
            body.color = body.colorOnChecked;
            shaderImageColor = sourceColorOnEnable;
        } else {
            body.color = body.colorDefault;
            shaderImageColor = sourceColorOnDisable;
        }
    }

    Rectangle {
        id: body
        height: parent.height
        width: parent.width

        readonly property string colorDefault: ColorStorage.switchButtonBaseColorOnDisable
        readonly property string colorOnChecked: ColorStorage.switchButtonBaseColorOnEnable

        border.width: 0

        color: colorDefault

        focus: true

        MouseArea {
            id: mouseArea

            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                if (!isChecked) {
                    //Color on hovered is equal to main window title color with blacking-out
                    body.color = body.colorOnChecked;
                    shaderImageColor = sourceColorOnEnable;

                    opacityRect.opacity = 0.1;
                } else {
                    opacityRect.opacity = 0.15;
                }
            }

            onExited: {
                opacityRect.opacity = 0;

                if (!isChecked) {
                    body.color = body.colorDefault;
                    shaderImageColor = sourceColorOnDisable;
                }
            }

            onPressed: {
                opacityRect.opacity = 0;
            }

            onReleased: {
                if (!containsMouse) {
                    return;
                }

                root.doWorkOnButtonClick();

                if (isChecked) {
                    opacityRect.opacity = 0.1;
                } else {
                    opacityRect.opacity = 0.15;
                }
            }
        }

        Rectangle {
            id: opacityRect

            anchors.fill: parent
            opacity: 0
            color: ColorStorage.iconsAndTextPrimary

            enabled: false
        }

        Image {
            id: buttonImage

            anchors.centerIn: parent
            visible: false

            width: imageWidth
            height: imageHeight

            sourceSize.width: width
            sourceSize.height: height
            source: root.source
        }

        IconShader {
            id: imageColor
            anchors.centerIn: parent
            imageSrcComponent: buttonImage
            imgColor: shaderImageColor
            imageWidth: buttonImage.width
            imageHeight: buttonImage.height
        }
    }
}
