import QtQuick 2.15
import QtQuick.Controls 2.15
import "." as SoftphonePro
import Flux 1.0

import "../utils"


FocusScope {
    id: root

    property alias edit: edit
    property alias deleteButton: deleteButton
    property alias placeholder: editPlaceholder
    property alias body: body
    property bool contextMenuIsOpen: false

    focus: true

    Component {
        id: contextMenuComponent

        // Menu element should be placed into Component
        // to crete every time new Menu element
        Menu {
            id: contextMenu
            closePolicy: Popup.NoAutoClose
            background: Rectangle {
                implicitWidth: 200 * SettingsState.scale
                implicitHeight: 40 * SettingsState.scale
                radius: 8 * SettingsState.scale
                color: "transparent"

                MenuShadow {
                    scale: SettingsState.scale
                    anchors.fill: parent
                    bodyColor: ColorStorage.surfaceSecondary
                    shadowColor: ColorStorage.menuShadowColor
                }
            }

            PhoneInputMenuItem {
                enabled: edit.hasTextSelected()
                topMargin: 1 * SettingsState.scale
                actionLabel: qsTrId("clipboard_cut") + Translator.translate
                shortcutLabel: "Ctrl+X"

                roundTopCorners: true

                onTriggered: {
                    edit.cut();
                    root.forceActiveFocus();
                }
            }

            PhoneInputMenuItem {
                enabled: edit.hasTextSelected()
                actionLabel: qsTrId("clipboard_copy") + Translator.translate
                shortcutLabel: "Ctrl+C"

                onTriggered: {
                    edit.copy();
                    root.forceActiveFocus();
                }
            }

            PhoneInputMenuItem {
                enabled: {
                    var text = SystemClipboard.getText();

                    if (text) {
                        return true;
                    }

                    return false;
                }

                roundBottomCorners: true
                bottomMargin: 1 * SettingsState.scale

                actionLabel: qsTrId("clipboard_paste") + Translator.translate
                shortcutLabel: "Ctrl+V"

                onTriggered: {
                    edit.paste();
                    root.forceActiveFocus();
                }
            }

            onActiveFocusChanged: {
                if (!activeFocus) {
                    contextMenu.close();
                    contextMenuIsOpen = false;
                }
            }

            Component.onCompleted: {
                contextMenuIsOpen = true;
                contextMenu.open();
            }
        }
    }

    Loader {
        id: loader
    }

    Rectangle {
        id: body

        width: root.width
        height: root.height

        color: ColorStorage.mainWindowBackground
        clip: true

        radius: 8 * SettingsState.scale

        border.color: parent.activeFocus ? ColorStorage.grayNeutralOnPress : "transparent"

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            hoverEnabled: true

            cursorShape: Qt.IBeamCursor

            onPressed: {
                // destroy old Menu element if it exists
                loader.sourceComponent = null;

            }

            onReleased: {
                // need to save selected text because it would
                // lost after mouse click
                edit.lastSelectionBegin = edit.selectionStart
                edit.lastSelectionEnd = edit.selectionEnd

                loader.sourceComponent = contextMenuComponent;

                // restore selection
                edit.select(edit.lastSelectionBegin, edit.lastSelectionEnd);
            }
        }

        TextInput {
            id: edit

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: deleteButton.left
            anchors.rightMargin: 10 * SettingsState.scale
            anchors.leftMargin: 10 * SettingsState.scale

            clip: true

            font.family: "Segoe UI"
            font.pixelSize: body.height / 2.5

            color: ColorStorage.iconsAndTextPrimary

            selectByMouse: true
            selectionColor: ColorStorage.selectionInputColor
            selectedTextColor: ColorStorage.iconsAndTextPrimary
            focus: true

            property int lastSelectionBegin: 0
            property int lastSelectionEnd: 0

            function hasTextSelected() {
                return lastSelectionEnd > lastSelectionBegin;
            }

            Text {
                id: editPlaceholder

                anchors.verticalCenter: edit.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 3 * SettingsState.scale

                font.family: "Segoe UI"
                font.pixelSize: body.height / 3

                text: qsTrId("search_input_placeholder_text") + Translator.translate

                color: ColorStorage.additionalText

                visible: edit.text == "" && text != "" && !parent.activeFocus
            }

            Shortcut {
                enabled: edit.activeFocus && edit.text.length > 0

                sequence: "Esc"

                onActivated: {
                    edit.text = "";
                }
            }
        }



        SoftphonePro.SquareButton {
            id: deleteButton

            property bool isSearchIcon: edit.activeFocus == false && edit.text.length == 0
            anchors.right: parent.right
            anchors.rightMargin: 10 * SettingsState.scale
            anchors.verticalCenter: edit.verticalCenter

            width: height
            height: parent.height / 2
            radius: 8 * SettingsState.scale

            imageWidth: width
            imageHeight: height

            colorDefault: "transparent"
            colorOnPress: isSearchIcon ? "transparent" : ColorStorage.grayNeutralOnHover

            imageColorDefault: ColorStorage.additionalText
            imageColorOnHover: ColorStorage.additionalText
            imageColorOnPress: ColorStorage.additionalText

            imageDefault: isSearchIcon ? "qrc:/images/search.svg" : "qrc:/images/close_default.svg"

            enabled: true
            visible: true

            doWorkOnButtonClick: function() {
                edit.text = "";
            }
        }
    }
}
