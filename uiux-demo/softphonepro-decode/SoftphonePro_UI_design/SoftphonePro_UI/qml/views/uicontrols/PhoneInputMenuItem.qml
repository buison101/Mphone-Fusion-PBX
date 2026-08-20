import QtQuick 2.15
import QtQuick.Controls 2.15
import Flux 1.0

MenuItem {
    id: root

    property double scale: 1

    property alias actionLabel: tmAction.text
    property alias shortcutLabel: shortcut.text
    property string colorDefault: ColorStorage.surfaceSecondary
    property string colorOnHover: ColorStorage.secondaryWindowBackground
    property bool roundBottomCorners: false
    property bool roundTopCorners: false
    property bool roundCorners: false

    readonly property int elementWidth: 215 * scale
    property int elementHeight: 30 * scale
    property int topMargin: 0 * scale
    property int bottomMargin: 0 * scale

    Shortcut {
        enabled: true
        sequence: root.shortcut

        onActivated: {
            root.triggered();
        }
    }

    onHighlightedChanged: {
        if (highlighted) {
            body.color = colorOnHover;
        } else {
            body.color = colorDefault;
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
            anchors.right: parent.right
            anchors.leftMargin: 1
            anchors.rightMargin: 1
            radius: roundCorners || roundBottomCorners || roundTopCorners ? 8 * SettingsState.scale : 0

            implicitWidth: border.width
            implicitHeight: border.height - root.topMargin - root.bottomMargin

            readonly property string colorDefault: root.colorDefault
            readonly property string colorOnHover: root.colorOnHover

            color: colorDefault

            MouseArea {
                enabled: root.enabled

                anchors.fill: parent
                hoverEnabled: true

                onEntered: {
                    body.color = body.colorOnHover;
                    root.forceActiveFocus();
                }

                onExited: {
                    body.color = body.colorDefault;
                }

                onReleased: {
                    root.triggered();
                }
            }

            Rectangle {
                id: bottomCorners

                anchors.bottom: parent.bottom

                height: parent.height / 3
                width: parent.width
                color: parent.color
                enabled: false
                visible: roundTopCorners && !roundBottomCorners
            }

            Rectangle {
                id: topCorners

                anchors.top: parent.top

                height: parent.height / 3
                width: parent.width
                color: parent.color
                enabled: false
                visible: roundBottomCorners && !roundTopCorners
            }
        }
    }

    contentItem: Rectangle {
        width: body.width
        height: body.height

        color: "transparent"

        TextMetrics {
            id: tmAction

            elide: Text.ElideRight
            elideWidth: text.length > 0 ? parent.width - 25 * root.scale : 0
            font.family: "Segoe UI"
        }

        TextEdit {
            id: action

            anchors.left: parent.left
            anchors.leftMargin: 10 * root.scale
            anchors.verticalCenter: parent.verticalCenter

            font.family: "Segoe UI"
            font.pixelSize: 12 * root.scale

            color: root.enabled ? ColorStorage.iconsAndTextPrimary : ColorStorage.disabledButtonsGrey
            text: tmAction.elidedText

            function elided(){return text !== tmAction.text}

            MouseArea {
                id: displayActionMouseArea

                anchors.fill: parent

                hoverEnabled: true

                ToolTip {
                    visible: displayActionMouseArea.containsMouse && content.text && action.elided()

                    delay: 1000
                    timeout: 5000
                    contentItem: Text {
                        id: content
                        text: tmAction.text
                        color: ColorStorage.mainWindowBackground
                        wrapMode: Text.WordWrap
                    }

                    background: Rectangle {
                        color: ColorStorage.iconsAndTextPrimary
                    }
                }

                onEntered: {
                    body.color = body.colorOnHover;
                    root.forceActiveFocus();
                }

                onExited: {
                    body.color = body.colorDefault;
                }

                onReleased: {
                    root.triggered();
                }
            }
        }

        Text {
            id: shortcut

            anchors.right: parent.right
            anchors.rightMargin: 10 *root. scale
            anchors.verticalCenter: parent.verticalCenter

            font.family: "Segoe UI"
            font.pixelSize: 12 * root.scale

            color: root.enabled ? ColorStorage.iconsAndTextPrimary : ColorStorage.disabledButtonsGrey
        }
    }
}
