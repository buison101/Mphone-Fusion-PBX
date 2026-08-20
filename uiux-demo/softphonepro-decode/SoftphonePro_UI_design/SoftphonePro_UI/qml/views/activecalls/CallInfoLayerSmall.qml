import QtQuick 2.15
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.15
import Flux 1.0

import "../uicontrols"
import "../utils"

Item {
    implicitWidth: 300 * SettingsState.scale
    implicitHeight: 35 * SettingsState.scale

    property alias number: number.text
    property alias name: displayName.text
    property alias status: status.text
    property alias duration: duration.text

    property alias numberElement: number
    property alias nameElement: displayName
    property alias uneditedName: displayNameToolTipContent.text
    property alias statusElement: status
    property alias durationElement: duration

    Column {
        anchors.fill: parent

        spacing: 5 * SettingsState.scale

        Component {
            id: numberMenuComponent

            // Menu element should be placed into Component
            // to crete every time new Menu element
            Menu {
                id: numberMenu

                background: Rectangle {
                    implicitWidth: 215 * SettingsState.scale
                    implicitHeight: 30 * SettingsState.scale
                    color: "transparent"

                    radius: 8 * SettingsState.scale

                    MenuShadow {
                        scale: SettingsState.scale
                        anchors.fill: parent
                        bodyColor: ColorStorage.surfaceSecondary
                        shadowColor: ColorStorage.menuShadowColor
                    }
                }

                PhoneInputMenuItem {
                    enabled: number.hasTextSelected()
                    scale: SettingsState.scale
                    colorDefault: ColorStorage.mainWindowBackground
                    colorOnHover: ColorStorage.surfaceSecondary

                    topMargin: 1
                    bottomMargin: 1

                    roundCorners: true

                    roundBottomCorners: true
                    roundTopCorners: true

                    actionLabel: qsTrId("clipboard_copy") + Translator.translate
                    shortcutLabel: "Ctrl+C"

                    onTriggered: {
                        number.copy();
                    }
                }

                onActiveFocusChanged: {
                    if (!activeFocus) {
                        numberMenu.close();
                    }
                }

                Component.onCompleted: {
                    numberMenu.open();
                }
            }
        }

        Loader {
            id: numberLoader
        }

        Component {
            id: nameMenuComponent

            // Menu element should be placed into Component
            // to crete every time new Menu element
            Menu {
                id: nameMenu

                background: Rectangle {
                    implicitWidth: 215 * SettingsState.scale
                    implicitHeight: 30 * SettingsState.scale
                    color: "transparent"
                    radius: 8 * SettingsState.scale

                    MenuShadow {
                        scale: SettingsState.scale
                        anchors.fill: parent
                        bodyColor: ColorStorage.surfaceSecondary
                        shadowColor: ColorStorage.menuShadowColor
                    }
                }

                PhoneInputMenuItem {
                    enabled: displayName.hasTextSelected()
                    scale: SettingsState.scale
                    colorDefault: ColorStorage.mainWindowBackground
                    colorOnHover: ColorStorage.surfaceSecondary

                    topMargin: 1
                    bottomMargin: 1

                    roundCorners: true

                    actionLabel: qsTrId("clipboard_copy") + Translator.translate
                    shortcutLabel: "Ctrl+C"

                    onTriggered: {
                        displayName.copy();
                    }
                }

                onActiveFocusChanged: {
                    if (!activeFocus) {
                        nameMenu.close();
                    }
                }

                Component.onCompleted: {
                    nameMenu.open();
                }
            }
        }

        Loader {
            id: nameLoader
        }

        Rectangle {
            width: parent.width
            height: 35 * SettingsState.scale

            color: "transparent"

            TextEdit {
                id: displayName

                anchors.left: parent.left
                anchors.top: parent.top
                anchors.right: status.visible ? status.left : parent.right
                anchors.rightMargin: 15 * SettingsState.scale

                selectByMouse: true
                selectionColor: ColorStorage.selectionInputColor
                selectedTextColor: ColorStorage.iconsAndTextPrimary
                readOnly: true

                font.pixelSize: 12 * SettingsState.scale
                font.family: "Segoe UI"
                font.weight: Font.Bold
                color: ColorStorage.iconsAndTextPrimary

                wrapMode: TextEdit.WordWrap

                property int lastSelectionBegin: 0
                property int lastSelectionEnd: 0

                function hasTextSelected() {
                    return lastSelectionEnd > lastSelectionBegin;
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton

                    onPressed: {
                        // destroy old Menu element if it exists
                        nameLoader.sourceComponent = null;
                    }

                    onReleased: {
                        // need to save selected text because it would
                        // lost after mouse click
                        displayName.lastSelectionBegin = displayName.selectionStart
                        displayName.lastSelectionEnd = displayName.selectionEnd

                        nameLoader.sourceComponent = nameMenuComponent;
                        nameLoader.item.x = parent.x + mouseX;
                        nameLoader.item.y = parent.y + mouseY;

                        // restore selection
                        displayName.select(displayName.lastSelectionBegin, displayName.lastSelectionEnd);
                    }
                }
            }

            TextEdit {
                id: number

                anchors.left: parent.left
                anchors.top: displayName.bottom
                anchors.topMargin: 5 * SettingsState.scale
                anchors.right: status.visible ? status.left : parent.right
                anchors.rightMargin: 5 * SettingsState.scale

                selectByMouse: true
                selectionColor: ColorStorage.selectionInputColor
                selectedTextColor: ColorStorage.iconsAndTextPrimary
                readOnly: true

                font.pixelSize: 12 * SettingsState.scale
                font.family: "Segoe UI"
                color: ColorStorage.iconsAndTextPrimary

                wrapMode: TextEdit.WrapAnywhere

                property int lastSelectionBegin: 0
                property int lastSelectionEnd: 0

                function hasTextSelected() {
                    return lastSelectionEnd > lastSelectionBegin;
                }

                MouseArea {
                    id: displayNameMouseArea

                    function elided(){return number.text !== uneditedName}

                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton

                    hoverEnabled: true

                    ToolTip {
                        id: displayNameToolTip

                        visible: displayNameMouseArea.containsMouse && displayNameToolTipContent.text && displayNameMouseArea.elided()
                        delay: 1000
                        timeout: 5000

                        contentItem: Text {
                            id: displayNameToolTipContent
                            color: ColorStorage.mainWindowBackground
                            wrapMode: Text.WordWrap
                        }

                        background: Rectangle {
                            color: ColorStorage.iconsAndTextPrimary
                        }
                    }

                    onPressed: {
                        // destroy old Menu element if it exists
                        numberLoader.sourceComponent = null;
                    }

                    onReleased: {
                        // need to save selected text because it would
                        // lost after mouse click
                        number.lastSelectionBegin = number.selectionStart
                        number.lastSelectionEnd = number.selectionEnd

                        numberLoader.sourceComponent = numberMenuComponent;
                        numberLoader.item.x = parent.x + mouseX;
                        numberLoader.item.y = parent.y + mouseY;

                        // restore selection
                        number.select(number.lastSelectionBegin, number.lastSelectionEnd);
                    }
                }
            }

            Text {
                id: status

                anchors.right: parent.right
                anchors.verticalCenter: displayName.verticalCenter
                anchors.verticalCenterOffset: 4 * SettingsState.scale

                font.pixelSize: 12 * SettingsState.scale
                font.family: "Segoe UI"

                color: ColorStorage.iconsAndTextSecondary
            }

            Text {
                id: duration

                anchors.right: parent.right
                anchors.verticalCenter: number.verticalCenter
                font.pixelSize: 16 * SettingsState.scale
                font.family: "Segoe UI"

                color: ColorStorage.iconsAndTextPrimary
            }
        }
    }
}
