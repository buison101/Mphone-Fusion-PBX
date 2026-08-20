import QtQuick 2.15
import QtQuick.Controls 2.15
import Flux 1.0

import "../utils"

FocusScope {
    id: root

    implicitWidth: body.width
    implicitHeight: body.height

    focus: true

    property alias edit: edit
    property alias backspaceButton: removeText
    property bool fromClipboard: false
    property int textSize: 32 * SettingsState.scale
    property bool errorLayerVisible: false
    property bool contextMenuIsOpen: false

    function removeLastIndex(){
        edit.remove(edit.length -1, edit.length);
    }

    Component {
        id: contextMenuComponent

        // Menu element should be placed into Component
        // to crete every time new Menu element
        Menu {
            id: contextMenu
            closePolicy: Popup.NoAutoClose
            onActiveFocusChanged: {
                if (!activeFocus) {
                    contextMenu.close();
                    contextMenuIsOpen = false;
                }
            }

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
                roundTopCorners: true
                actionLabel: qsTrId("clipboard_cut") + Translator.translate
                shortcutLabel: "Ctrl+X"

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
                    if(!edit.hasTextSelected()){
                        edit.selectAll();
                    }

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
                bottomMargin: 1 * SettingsState.scale
                roundBottomCorners: true
                actionLabel: qsTrId("clipboard_paste") + Translator.translate
                shortcutLabel: "Ctrl+V"

                onTriggered: {
                    edit.paste();
                    root.forceActiveFocus();
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
        anchors.fill: parent
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton | Qt.LeftButton

            onPressed: {
                // destroy old Menu element if it exists
                loader.sourceComponent = null;
            }

            onReleased: {
                if (mouse.button == Qt.LeftButton) {
                    return;
                }
                // need to save selected text because it would
                // lost after mouse click
                edit.lastSelectionBegin = edit.selectionStart;
                edit.lastSelectionEnd = edit.selectionEnd;

                loader.sourceComponent = contextMenuComponent;

                // restore selection
                edit.select(edit.lastSelectionBegin, edit.lastSelectionEnd);
            }
        }

        Rectangle {
            id: body

            width: parent.width - 88 * SettingsState.scale

            height: root.errorLayerVisible ? 62 * SettingsState.scale : 83 * SettingsState.scale

            color: "transparent"
            clip: true

            anchors.centerIn: parent

            Text {
                id: inputLabel
                visible: edit.text == "" && !edit.activeFocus
                text: qsTrId("dialpad_input") + Translator.translate
                color: ColorStorage.additionalText
                anchors.centerIn: parent
                font.pixelSize: 16 * SettingsState.scale
            }

            TextInput {
                id: edit

                width: parent.width - 2 * SettingsState.scale

                anchors.centerIn: parent

                horizontalAlignment: TextInput.AlignHCenter

                property RegExpValidator inCallValidator: RegExpValidator{
                    regExp: /[*,#0-9()-–‒ ]*/
                }

                font.family: "Segoe UI"
                font.pixelSize: root.textSize
                font.bold: true

                color: ColorStorage.iconsAndTextPrimary

                selectByMouse: true
                selectionColor: ColorStorage.selectionInputColor
                selectedTextColor: ColorStorage.iconsAndTextPrimary
                focus: true

                validator: {
                    if (AppState.activeCall != null) {
                        return edit.inCallValidator;
                    }

                    return null;
                }

                text: AppState.dialText

                property int lastSelectionBegin: 0
                property int lastSelectionEnd: 0

                function hasTextSelected() {
                    return lastSelectionEnd > lastSelectionBegin;
                }

                onTextChanged: {
                    if (root.fromClipboard) {
                        // if number filled from clipboard
                        // do nothing with dialed number
                        return;
                    }
                    if (edit.text != AppState.dialText) {
                        // in case of dialing a number NOT via
                        // keypad but via keyboard or a clipboard menu
                        var maxDialTextLength = 255;

                        if (edit.text.length > maxDialTextLength) {
                            AppLogger.error("Exceeded the maximum line length of "
                                            + maxDialTextLength + " characters");
                            edit.text = edit.text.substring(0, maxDialTextLength);
                        }

                        if (edit.text.length > AppState.dialText.length &&
                                edit.text.length - AppState.dialText.length == 1) {
                            // if only one symbol was typed
                            var idx = getFirstDifferentSymbolIdx(edit.text, AppState.dialText);
                            ActionProvider.sendDialedSymbol(edit.text.charAt(idx), idx);
                        }
                        else {
                            ActionProvider.sendDialedString(edit.text);
                        }
                    }
                }

                function getFirstDifferentSymbolIdx(str1, str2) {
                    var bigger, smaller;

                    if (str1.length > str2.length) {
                        bigger = str1;
                        smaller = str2;
                    }
                    else {
                        bigger = str2;
                        smaller = str1;
                    }

                    var i;
                    for (i = 0; i < smaller.length; i += 1) {
                        if (smaller.charAt(i) != bigger.charAt(i)) {
                            return i;
                        }
                    }

                    return i;
                }
            }
        }

        SquareButton {
            id: removeText

            Accessible.role: Accessible.Button
            Accessible.name: "RemoveTextButton"

            anchors.verticalCenter: body.verticalCenter
            anchors.left: body.right
            anchors.leftMargin: 8 * SettingsState.scale

            enabled: edit.text != ""
            visible: enabled

            width: 29 * SettingsState.scale
            height: 24 * SettingsState.scale

            radius: 8 * SettingsState

            colorDefault: "transparent"

            imageWidth: 29 * SettingsState.scale
            imageHeight: 24 * SettingsState.scale

            imageColorDefault: ColorStorage.iconsAndTextSecondary
            imageColorOnHover: ColorStorage.grayNeutralOnHover
            imageColorOnPress: ColorStorage.grayNeutralOnPress
            imageColorOnDisabled: ColorStorage.disabledButtonsGrey

            imageDefault: "qrc:/images/remove_text.svg"

            doWorkOnButtonClick: function() {
                edit.remove(edit.length -1, edit.length);
            }
        }
    }
}
