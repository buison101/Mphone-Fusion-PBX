import QtQuick 2.15
import Flux 1.0

Item {
    id: root

    property alias digit: digit.text
    property alias characters: characters.text
    property alias sizeNum: body.size
    property alias widthNum: body.widthSize
    property alias sizeDigit: body.sizeDigit
    property alias sizeCharacters: body.sizeCharacters

    property string buttonColorOnHover: ""
    property string buttonColorOnPress: ""

    implicitWidth: body.width
    implicitHeight: body.height

    property var doWorkOnButtonClick: function() {}

    Rectangle {
        id: body

        width: widthSize
        height: size
        radius: 8 * SettingsState.scale

        property int size: 72 * SettingsState.scale
        property int widthSize: 105 * SettingsState.scale
        property int sizeDigit: 30 * SettingsState.scale
        property int sizeCharacters: 13 * SettingsState.scale

        readonly property string colorDefault: ColorStorage.numButtonDefault
        readonly property string colorOnHover: root.buttonColorOnHover
        readonly property string colorOnPress: root.buttonColorOnPress

        color: colorDefault

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
                body.color = body.colorOnHover;
            }

            onExited: {
                body.color = body.colorDefault;
            }

            onPressed: {
                body.color = body.colorOnPress;
                digit.color = digit.colorOnPress;
                characters.color = characters.colorOnPress;
            }

            onReleased: {
                body.color = body.colorDefault;
                digit.color = digit.colorDefault;
                characters.color = characters.colorDefault;
                root.doWorkOnButtonClick();
            }
        }

        Text {
            id: digit

            anchors.top: parent.top
            anchors.topMargin: 5 * SettingsState.scale
            anchors.horizontalCenter: parent.horizontalCenter
            bottomPadding: -5

            readonly property string colorDefault: ColorStorage.iconsAndTextPrimary
            readonly property string colorOnPress: ColorStorage.iconsAndTextPrimary

            color: colorDefault

            font.family: "Segoe UI"
            font.pixelSize: sizeDigit
            font.bold: true
        }

        Text {
            id: characters

            anchors.top: digit.bottom
            anchors.horizontalCenter: digit.horizontalCenter

            readonly property string colorDefault: ColorStorage.additionalText
            readonly property string colorOnPress: ColorStorage.additionalText

            color: colorDefault

            font.family: "Segoe UI"
            font.pixelSize: sizeCharacters
            font.bold: true
        }
    }
}
