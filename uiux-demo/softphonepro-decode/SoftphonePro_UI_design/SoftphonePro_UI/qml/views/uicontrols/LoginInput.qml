import QtQuick 2.15
import QtQuick.Controls 2.15
import AuthEngineModule 1.0
import Flux 1.0

FocusScope {
    id: root

    implicitWidth: 200 * AuthEngine.scale
    implicitHeight: 30 * AuthEngine.scale

    focus: true

    property alias edit: edit
    property alias placeholder: editPlaceholder
    property string textColor: ColorStorage.iconsAndTextPrimary

    property var setFocus: function() {
       edit.forceActiveFocus();
    }

    Loader {
        id: loader
    }

    Rectangle {
        id: body

        width: root.implicitWidth
        height: root.implicitHeight

        color: ColorStorage.mainWindowBackground
        clip: true

        radius: 8 * AuthEngine.scale

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton

            onPressed: {
                // destroy old Menu element if it exists
                loader.sourceComponent = null;
            }

            onReleased: {
                // need to save selected text because it would
                // lost after mouse click
                edit.lastSelectionBegin = edit.selectionStart;
                edit.lastSelectionEnd = edit.selectionEnd;

                loader.sourceComponent = contextMenuComponent;

                // restore selection
                edit.select(edit.lastSelectionBegin, edit.lastSelectionEnd);
            }
        }

        Text {
            id: editPlaceholder

            anchors.verticalCenter: edit.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 10 * AuthEngine.scale

            font.family: "Segoe UI"

            visible: edit.text == "" && text != ""
        }

        TextInput {
            id: edit

            anchors.fill: parent

            leftPadding: 10 * AuthEngine.scale

            selectByMouse: true
            selectionColor: ColorStorage.selectionInputColor
            selectedTextColor: ColorStorage.iconsAndTextPrimary

            font.family: "Segoe UI"
            font.pixelSize: 14

            color: textColor

            verticalAlignment: Text.AlignVCenter

            focus: true

            property int lastSelectionBegin: 0
            property int lastSelectionEnd: 0
        }
    }
}
