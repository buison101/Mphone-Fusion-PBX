import QtQuick 2.15
import Flux 1.0
import "../uicontrols"

FocusScope {
    id: root

    property alias info: tmErrorInfo.text
    property bool disableCloseButton: false
    property var doWorkOnButtonClick: function() {}
    property var doWorkOnErrorClick: function() {}

    focus: true

    MouseArea {
        id: rootMouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true

        onReleased: {
            root.doWorkOnErrorClick();
        }
    }

    Rectangle {
        id: body

        height: parent.height
        anchors.left: parent.left
        anchors.right: parent.right
        color: rootMouseArea.containsMouse ? ColorStorage.surfaceErrorOnHover : ColorStorage.surfaceError

        Text {
            id: errorInfo

            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter

            color: ColorStorage.iconsAndTextPrimary

            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            font.bold: true
            font.pixelSize: 11 * SettingsState.scale

            text: tmErrorInfo.elidedText

        }

        TextMetrics {
            id:tmErrorInfo

            elide: Text.ElideRight
            elideWidth: text.length > 0 ? root.width - closeButton.width - 60 * SettingsState.scale : 0
            font.family: "Segoe UI"
            font.pixelSize: 11 * SettingsState.scale
            font.bold: true
        }
    }

    TitleButton {
        id: closeButton

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        scale: SettingsState.scale

        bodyHeight: root.height
        bodyWidth: height

        visible: !disableCloseButton

        colorDefault: "transparent"
        colorOnPress: ColorStorage.loginButtonLoginWindowOnHoverColor
        colorOnHover: ColorStorage.loginButtonLoginWindowDefaultColor

        imageWidth: width / 1.5
        imageHeight: height / 1.5

        imageColorDefault: ColorStorage.iconsAndTextPrimary
        imageColorOnHover: ColorStorage.iconsAndTextPrimary
        imageColorOnPress: ColorStorage.iconsAndTextPrimary

        imageSource: "qrc:/images/close_default.svg"

        enabled: true

        doWorkOnButtonClick: root.doWorkOnButtonClick
    }
}
