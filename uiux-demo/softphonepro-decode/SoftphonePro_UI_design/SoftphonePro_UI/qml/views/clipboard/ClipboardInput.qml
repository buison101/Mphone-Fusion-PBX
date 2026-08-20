import QtQuick 2.15
import QtQuick.Controls 2.15
import Flux 1.0

import "../uicontrols"

FocusScope {
    implicitWidth: body.width
    implicitHeight: body.height

    focus: true

    property alias edit: edit

    Component {
        id: contextMenuComponent

        // Menu element should be placed into Component
        // to crete every time new Menu element
        Menu {
            id: contextMenu

            PhoneInputMenuItem {
                enabled: edit.hasTextSelected()

                actionLabel: qsTrId("clipboard_cut") + Translator.translate
                shortcutLabel: "Ctrl+X"

                onTriggered: {
                    edit.cut();
                }
            }

            PhoneInputMenuItem {
                enabled: edit.hasTextSelected()

                actionLabel: qsTrId("clipboard_copy") + Translator.translate
                shortcutLabel: "Ctrl+C"

                onTriggered: {
                    edit.copy();
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

                actionLabel: qsTrId("clipboard_paste") + Translator.translate
                shortcutLabel: "Ctrl+V"

                onTriggered: {
                    edit.paste();
                }
            }

            onActiveFocusChanged: {
                if (!activeFocus) {
                    contextMenu.close();
                }
            }

            Component.onCompleted: {
                contextMenu.open();
            }
        }
    }

    Loader {
        id: loader
    }

    Rectangle {
        id: body

        width: 270 * SettingsState.scale
        height: 37 * SettingsState.scale

        color: "transparent"
        clip: true

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
                edit.lastSelectionBegin = edit.selectionStart
                edit.lastSelectionEnd = edit.selectionEnd

                loader.sourceComponent = contextMenuComponent;

                // restore selection
                edit.select(edit.lastSelectionBegin, edit.lastSelectionEnd);
            }
        }

        TextInput {
            id: edit

            anchors.fill: parent

            font.family: "Segoe UI"
            font.pixelSize: 32 * SettingsState.scale

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
        }
    }

    Rectangle {
        anchors.top: body.bottom
        anchors.topMargin: 5 * SettingsState.scale

        width: body.width
        height: 1 * SettingsState.scale

        color: ColorStorage.iconsAndTextPrimary
    }
}
