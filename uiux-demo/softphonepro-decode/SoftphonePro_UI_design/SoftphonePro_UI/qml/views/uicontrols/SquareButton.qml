import QtQuick 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.15
import Flux 1.0

import "../utils"

FocusScope {
    id: root

    property int radius: 0
    property double scale: 1

    property alias color: innerBody.color
    property string colorDefault: "white"
    property string colorOnHover: colorDefault
    property string colorOnPress: colorDefault
    property string colorOnDisabled: colorDefault

    property int borderWidth: 0
    property double borderWidthDefault: 0
    property double borderWidthOnHover: 0
    property double borderWidthOnPress: 0
    property double borderWidthOnDisabled: 0

    property string borderColor: "transparent"
    property string borderColorDefault: "white"
    property string borderColorOnHover: borderColorDefault
    property string borderColorOnPress: borderColorDefault
    property string borderColorOnDisabled: borderColorDefault

    property alias imageWidth: image.width
    property alias imageHeight: image.height

    property string imageColorDefault: "black"
    property string imageColorOnHover: "black"
    property string imageColorOnPress: "black"
    property string imageColorOnDisabled: "black"

    property alias imageDefault: image.source

    property alias description: description.text
    property alias descriptionColor: description.color

    property bool hovered: mouseArea.containsMouse
    property alias propagateMouseEvents: mouseArea.propagateComposedEvents
    property bool pressed: mouseArea.pressed

    property var doWorkOnButtonClick: function() {}

    property string tooltipText: ""
    property int toolTipTimeout: 5000
    property int toolTipDelay: 2000

    focus: true
    state: "enabled"

    onActiveFocusChanged: {
        if (activeFocus) {
            state = "hovered";
        } else {
            state = "default";
        }
    }

    Keys.onReturnPressed: {
        root.doWorkOnButtonClick();
    }

    Keys.onEnterPressed: {
        root.doWorkOnButtonClick();
    }

    onVisibleChanged:
    {
        if (root.enabled) {
            if (mouseArea.containsMouse || activeFocus) {
                state = "hovered";
            } else {
                state = "default";
            }
        }
        else {
            state = "disabled";
        }
    }

    onEnabledChanged: {
        if (root.enabled) {
            state = "default";
        }
        else {
            state = "disabled";
        }
    }

    ToolTip {
        id:toolTip

        visible: parent.visible && parent.hovered && tooltipText.length > 0
        delay: toolTipDelay
        timeout: toolTipTimeout
        font: content.font
        contentItem: Text{
            id: content
            text: tooltipText
            font.pixelSize: 11
            color: ColorStorage.mainWindowBackground
            wrapMode: Text.WordWrap
        }

        background: Rectangle {
            color: ColorStorage.iconsAndTextPrimary
        }
    }

    Rectangle {
        id: innerBody

        anchors.centerIn: parent

        width: root.width
        height: root.height
        radius: root.radius

        color: root.colorDefault
        border.width: root.borderWidthDefault
        border.color: root.borderColorDefault

        MouseArea {
            id: mouseArea

            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                if (root.state == "disabled") {
                    return;
                }

                root.state = "hovered";
                forceActiveFocus();
            }

            onExited: {
                if (root.state == "disabled" || root.state == "pressed") {
                    return;
                }

                root.state = "default";
            }

            onPressed: {
                if (root.state == "disabled") {
                    return;
                }

                root.state = "pressed";
            }

            onReleased: {
                if (root.state == "disabled") {
                    return;
                }

                if (containsMouse) {
                    root.doWorkOnButtonClick();
                    root.state = "hovered";
                    return;
                }

                root.state = "default";
            }
        }

        Row {
            anchors.centerIn: parent

            spacing: 10 * root.scale

            Image {
                id: image

                width: 22 * root.scale
                height: 22 * root.scale
                visible: false

                property string shaderImageColor: root.imageColorDefault

                sourceSize.width: width
                sourceSize.height: height
                source: root.imageDefault

            }

            IconShader {
                id: imageColor
                visible: image.source != ""
                imageSrcComponent: image
                imgColor: image.shaderImageColor
                imageWidth: image.width
                imageHeight: image.height
            }

            Text {
                id: description

                anchors.verticalCenter: image.verticalCenter

                visible: {
                    return description.text.length > 0;
                }

                font.pixelSize: 16 * root.scale
                font.family: "Segoe UI"

                color: ColorStorage.menuBorderColor
            }
        }
    }

    states: [

        State {
            name: "default"

            PropertyChanges {
                target: innerBody
                color: colorDefault
                border.color: borderColorDefault
                border.width: root.borderWidthDefault
            }

            PropertyChanges {
                target: image
                shaderImageColor: imageColorDefault
            }
        },

        State {
            name: "hovered"

            PropertyChanges {
                target: innerBody
                color: colorOnHover
                border.color: borderColorOnHover
                border.width: root.borderWidthOnHover
            }

            PropertyChanges {
                target: image
                shaderImageColor: imageColorOnHover
            }
        },

        State {
            name: "pressed"

            PropertyChanges {
                target: innerBody
                color: colorOnPress
                border.color: borderColorOnPress
                border.width: root.borderWidthOnPress
            }

            PropertyChanges {
                target: image
                shaderImageColor: imageColorOnPress
            }
        },

        State {
            name: "disabled"

            PropertyChanges {
                target: innerBody
                color: colorOnDisabled
                border.color: borderColorOnDisabled
                border.width: root.borderWidthOnDisabled
            }

            PropertyChanges {
                target: image
                shaderImageColor: imageColorOnDisabled
            }
        }
    ]
}
