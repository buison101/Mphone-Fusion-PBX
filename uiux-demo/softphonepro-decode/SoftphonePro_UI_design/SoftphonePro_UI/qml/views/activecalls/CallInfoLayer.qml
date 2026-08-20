import QtQuick 2.15
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.15
import Flux 1.0

import "../uicontrols" as SoftphonePro
import "../utils"

Item {
    implicitWidth: 332 * SettingsState.scale
    implicitHeight: 124 * SettingsState.scale

    property alias account: account.text
    property alias number: number.text
    property alias name: displayName.text
    property alias city: city.text
    property alias country: country.text
    property alias status: status.text
    property alias duration: duration.text
    property alias uneditedName: displayNameToolTipContent.text

    property alias accountElement: account
    property alias numberElement: number
    property alias nameElement: displayName
    property alias statusElement: status
    property alias durationElement: duration

    Column {
        anchors.fill: parent

        spacing: 5 * SettingsState.scale

        Rectangle {
            width: parent.width
            height: 30 * SettingsState.scale

            color: "transparent"

            Rectangle {
                anchors.left: parent.left
                anchors.right: accountLayout.left
                anchors.rightMargin: 20 * SettingsState.scale
                anchors.verticalCenter: accountLayout.verticalCenter
                anchors.horizontalCenterOffset: 2 * SettingsState.scale

                height: 1 * SettingsState.scale

                color: ColorStorage.textAndDisabledIconsGrey
            }

            RowLayout {
                id: accountLayout

                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter:  parent.horizontalCenter

                Text {
                    id: account

                    Layout.maximumWidth: 150 * SettingsState.scale
                    Layout.minimumWidth: 10 * SettingsState.scale

                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    elide: Text.ElideRight

                    font.pixelSize: 12 * SettingsState.scale
                    font.family: "Segoe UI"
                    font.weight: Font.DemiBold
                    color: ColorStorage.textAndDisabledIconsGrey

                    MouseArea {
                        hoverEnabled: true
                        anchors.fill: parent
                        ToolTip {
                            id: toolTip
                            visible: parent.containsMouse && content.text && account.implicitWidth > account.width
                            delay: 1000
                            timeout: 5000
                            clip: true
                            background: Rectangle {
                                id: background
                                color: ColorStorage.iconsAndTextPrimary
                            }
                            contentItem: Text {
                                id: content
                                text: account.text ? account.text : ""
                                color: ColorStorage.mainWindowBackground
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.left: accountLayout.right
                anchors.leftMargin: 20 * SettingsState.scale
                anchors.verticalCenter: accountLayout.verticalCenter
                anchors.horizontalCenterOffset: 2 * SettingsState.scale

                height: 1 * SettingsState.scale

                color: ColorStorage.textAndDisabledIconsGrey
            }
        }

        Component {
            id: numberMenuComponent

            // Menu element should be placed into Component
            // to crete every time new Menu element
            Menu {
                id: numberMenu

                background: Rectangle {
                    implicitWidth: 215 * SettingsState.scale
                    implicitHeight: 30 * SettingsState.scale

                    radius: 8 * SettingsState.scale

                    color: "transparent"

                    MenuShadow {
                        anchors.fill: parent

                        scale: SettingsState.scale

                        bodyColor: ColorStorage.surfaceSecondary
                        shadowColor: ColorStorage.menuShadowColor
                    }
                }

                SoftphonePro.PhoneInputMenuItem {
                    enabled: number.hasTextSelected()

                    colorDefault: ColorStorage.surfaceSecondary
                    colorOnHover: ColorStorage.mainWindowBackground

                    topMargin: 1
                    bottomMargin: 1

                    roundCorners: true

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
                    radius: 8 * SettingsState.scale
                    color: "transparent"

                    MenuShadow {
                        scale: SettingsState.scale
                        anchors.fill: parent
                        bodyColor: ColorStorage.surfaceSecondary
                        shadowColor: ColorStorage.menuShadowColor
                    }
                }

                SoftphonePro.PhoneInputMenuItem {
                    enabled: displayName.hasTextSelected()
                    scale: SettingsState.scale
                    colorDefault: ColorStorage.surfaceSecondary
                    colorOnHover: ColorStorage.mainWindowBackground

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
            height: 45 * SettingsState.scale

            color: "transparent"

            TextEdit {
                id: number

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: duration.bottom
                anchors.topMargin: 20 * SettingsState.scale

                selectByMouse: true
                selectionColor: ColorStorage.selectionInputColor
                selectedTextColor: ColorStorage.iconsAndTextPrimary
                readOnly: true

                font.pixelSize: 16 * SettingsState.scale
                font.family: "Segoe UI"
                font.weight: Font.Bold
                color: ColorStorage.iconsAndTextPrimary

                wrapMode: TextEdit.Wrap

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

            TextEdit {
                id: displayName

                anchors.left: parent.left
                anchors.leftMargin: -2 * SettingsState.scale
                anchors.right: parent.right
                anchors.rightMargin: -2 * SettingsState.scale
                anchors.top: number.bottom
                anchors.topMargin: -5 * SettingsState.scale

                horizontalAlignment: Text.AlignHCenter

                selectByMouse: true
                selectionColor: ColorStorage.selectionInputColor
                selectedTextColor: ColorStorage.iconsAndTextPrimary
                readOnly: true

                font.pixelSize: 16 * SettingsState.scale
                font.family: "Segoe UI"

                color: ColorStorage.iconsAndTextPrimary

                wrapMode: TextEdit.Wrap

                property int lastSelectionBegin: 0
                property int lastSelectionEnd: 0

                function hasTextSelected() {
                    return lastSelectionEnd > lastSelectionBegin;
                }

                MouseArea {
                    id: displayNameMouseArea

                    function elided(){return name !== uneditedName}

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

            Text {
                id: city

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: number.bottom
                anchors.topMargin: -2 * SettingsState.scale

                font.pixelSize: 12 * SettingsState.scale
                font.family: "Segoe UI"

                color: ColorStorage.iconsAndTextPrimary
            }

            Text {
                id: country

                anchors.left: city.right
                anchors.leftMargin: 5 * SettingsState.scale
                anchors.top: number.bottom
                anchors.topMargin: -2 * SettingsState.scale

                font.pixelSize: 12 * SettingsState.scale
                font.family: "Segoe UI"

                color: ColorStorage.iconsAndTextPrimary
            }

            Text {
                id: status

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenterOffset: 4 * SettingsState.scale
                anchors.top: parent.top
                font.pixelSize: 12 * SettingsState.scale
                font.family: "Segoe UI"

                color: ColorStorage.iconsAndTextPrimary
            }

            Text {
                id: duration

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: status.bottom
                anchors.bottomMargin: -6 * SettingsState.scale
                font.pixelSize: 16 * SettingsState.scale
                font.family: "Segoe UI"

                color: ColorStorage.iconsAndTextSecondary
            }
        }
    }
}
