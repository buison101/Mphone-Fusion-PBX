import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.15
import Flux 1.0

import "../utils"


FocusScope {
    id: scope

    implicitHeight: 30 * SettingsState.scale
    implicitWidth: 200 * SettingsState.scale

    property int sliderWidth: 200

    property alias imgWidth: volume.width
    property alias imgHeight: volume.height
    property string tooltipText: ""

    property string imageMicOff
    property string imageMicLow
    property string imageMicMedium
    property string imageMicHigh

    property string colorBeforeHandle
    property string colorAfterHandle

    property string imageColor: "black"

    property int sliderSize: 0 * SettingsState.scale

    focus: true

    Image {
        id: volume

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        width: 30 * SettingsState.scale
        height: 30 * SettingsState.scale
        visible: false

        sourceSize.width: width
        sourceSize.height: height

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            ToolTip {
                visible: parent.visible && parent.containsMouse && scope.tooltipText.length > 0

                delay: 1000
                timeout: 5000
                contentItem: Text {
                    text: scope.tooltipText
                    color: ColorStorage.mainWindowBackground
                    wrapMode: Text.WordWrap
                }

                background: Rectangle {
                    color: ColorStorage.iconsAndTextPrimary
                }
            }
        }

        state: "micOff"

        states: [
            State {
                name: "micOff"

                PropertyChanges {
                    target: volume
                    source: imageMicOff == "" ? "qrc:/images/volume_off_white.svg" : imageMicOff
                }
            },

            State {
                name: "micLow"

                PropertyChanges {
                    target: volume
                    source: imageMicLow == "" ? "qrc:/images/volume_low_white.svg" : imageMicLow
                }
            },

            State {
                name: "micMedium"

                PropertyChanges {
                    target: volume
                    source: imageMicMedium == "" ? "qrc:/images/volume_medium_white.svg" : imageMicMedium
                }
            },

            State {
                name: "micHigh"

                PropertyChanges {
                    target: volume
                    source: imageMicHigh == "" ? "qrc:/images/volume_high_white.svg" : imageMicHigh
                }
            }
        ]
    }

    IconShader {
        anchors.centerIn: volume
        imageSrcComponent: volume
        imgColor: scope.imageColor
        imageWidth: volume.width
        imageHeight: volume.height
    }

    Slider {
        id: slider

        anchors.verticalCenter: volume.verticalCenter
        anchors.left: volume.right
        anchors.leftMargin: 1 * SettingsState.scale
        anchors.right: parent.rigth

        focus: true

        snapMode: Slider.SnapAlways
        stepSize : 0.025

        Timer {
            id: sliderTimer

            interval: 500
            running: false
            repeat: false

            onTriggered: {
                if (slider.position != SettingsState.volumeLevelOutput) {
                    ActionProvider.adjustOutputSoundLevel(slider.position);
                }
            }
        }

        value: SettingsState.volumeLevelSpeakerDevice

        onPositionChanged: {
            sliderTimer.restart();
        }

        background: Rectangle {
            readonly property bool horizontal: slider.orientation === Qt.Horizontal

            x: slider.leftPadding + (horizontal ? 0 : (slider.availableWidth - width) / 2)
            y: slider.topPadding + (horizontal ? (slider.availableHeight - height) / 2 : 0)

            implicitWidth: horizontal ? scope.sliderWidth * SettingsState.scale : 2 * SettingsState.scale
            implicitHeight: horizontal ? 2 * SettingsState.scale : 200 * SettingsState.scale

            width: horizontal ? slider.availableWidth : implicitWidth
            height: horizontal ? implicitHeight : slider.availableHeight

            color: "transparent"

            Rectangle {
                id: beforeHandle

                anchors.left: parent.left

                width: parent.width * slider.visualPosition
                height: parent.height

                color: colorBeforeHandle == "" ? ColorStorage.iconsAndTextSecondary : colorBeforeHandle
            }

            Rectangle {
                id: afterHandle

                anchors.left: beforeHandle.right

                width: parent.width - beforeHandle.width
                height: parent.height

                color: colorAfterHandle == "" ? ColorStorage.grayNeutralOnPress : colorAfterHandle
            }
        }


        handle: Rectangle {
            readonly property bool horizontal: slider.orientation === Qt.Horizontal

            x: slider.leftPadding + (horizontal ? slider.visualPosition * (slider.availableWidth - width) : (slider.availableWidth - width) / 2)
            y: slider.topPadding + (horizontal ? (slider.availableHeight - height) / 2 : slider.visualPosition * (slider.availableHeight - height))

            implicitWidth: sliderSize == 0 ? 20 * SettingsState.scale : sliderSize
            implicitHeight: sliderSize == 0 ? 20 * SettingsState.scale : sliderSize

            radius: width / 2

            color: slider.pressed ? ColorStorage.grayNeutralOnPress : ColorStorage.iconsAndTextSecondary

            z: 1 * SettingsState.scale

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                ToolTip {
                visible: parent.visible && parent.containsMouse && scope.tooltipText.length > 0

                delay: 1000
                timeout: 5000
                contentItem: Text {
                    text: scope.tooltipText
                    color: ColorStorage.mainWindowBackground
                    wrapMode: Text.WordWrap
                }

                background: Rectangle {
                    color: ColorStorage.iconsAndTextPrimary
                }
            }
                // prevent stealing mouse events from slider
                onClicked: mouse.accepted = false;
                onPressed: mouse.accepted = false;
                onReleased: mouse.accepted = false;
                onDoubleClicked: mouse.accepted = false;
                onPositionChanged: mouse.accepted = false;
                onPressAndHold: mouse.accepted = false;
            }

            onXChanged: {

                if (slider.visualPosition == 0.0) {
                    volume.state = "micOff";
                    return;
                }

                if (slider.visualPosition > 0.0 && slider.visualPosition <= 0.33) {
                    volume.state = "micLow";
                    return;
                }

                if (slider.visualPosition > 0.33 && slider.visualPosition <= 0.66) {
                    volume.state = "micMedium";
                    return;
                }

                if (slider.visualPosition > 0.66 && slider.visualPosition <= 1.0) {
                    volume.state = "micHigh";
                    return;
                }
            }
        }
    }
}
