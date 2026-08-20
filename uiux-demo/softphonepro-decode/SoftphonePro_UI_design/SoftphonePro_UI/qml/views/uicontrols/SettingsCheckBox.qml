import QtQuick 2.15
import QtQuick.Controls 2.15

import "../utils"

CheckBox {
    id: control
    checked: true

    property string borderColor: "#6b6b6b"
    property string overlayColor: "transparent"
    topPadding: 0

    indicator: Rectangle {
        implicitWidth: 16
        implicitHeight: 16
        x: control.leftPadding
        y: parent.height / 2 - height / 2
        border.color: {
            if (parent.activeFocus) {
                return "blue"
            }
            return borderColor
        }

        opacity: enabled ? 1 : 0.3

        Image {
            id: image

            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Image.AlignLeft
            verticalAlignment: Image.AlignVCenter
            visible: false

            width: 16
            height: 16

            source: "qrc:/images/settings_check.svg"
        }

        IconShader {
            anchors.centerIn: image
            visible: control.checked
            imageSrcComponent: image
            imgColor: overlayColor
            imageWidth: image.width
            imageHeight: image.height
        }
    }
}
