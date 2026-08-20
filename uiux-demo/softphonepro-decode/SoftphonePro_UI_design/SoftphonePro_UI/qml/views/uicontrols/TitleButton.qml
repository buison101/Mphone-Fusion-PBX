import QtQuick 2.15
import Flux 1.0

import "../utils"

Item {
    id: root

    property double scale: 1
    property alias colorDefault: body.colorDefault
    property alias colorOnHover: body.colorOnHover
    property alias colorOnPress: body.colorOnPress

    property alias imageSource: image.source

    property string imageColorDefault: "black"
    property string imageColorOnHover: imageColorDefault
    property string imageColorOnPress: imageColorDefault
    property string imageColorOnDisabled: imageColorDefault

    property alias imageWidth: image.width
    property alias imageHeight: image.height
    property int bodyWidth: 24 * root.scale
    property int bodyHeight: 24 * root.scale

    property var doWorkOnButtonClick: function() {}

    implicitWidth: body.width
    implicitHeight: body.height

    Rectangle {
        id: body

        implicitWidth: bodyWidth
        implicitHeight: bodyHeight

        property string colorDefault: "transparent"
        property string colorOnHover: ColorStorage.redOnHover
        property string colorOnPress: ColorStorage.redOnPress

        color: colorDefault

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
                if (containsMouse) {
                    root.doWorkOnButtonClick();

                    opacityRect.opacity = 0;
                    return;
                }

                opacityRect.opacity = 0;
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
            id: image

            property string imageColorDefault: root.imageColorDefault
            property string imageColorOnHover: imageColorDefault
            property string imageColorOnPress: imageColorDefault

            width: 20 * root.scale
            height: 20 * root.scale
            visible: false
            smooth: true
        }

        IconShader {
            id: imageShader
            anchors.centerIn: parent
            visible: image.source != ""
            imageSrcComponent: image
            imgColor: image.imageColorDefault
            imageWidth: 20 * root.scale
            imageHeight: 20 * root.scale
        }
    }
}

