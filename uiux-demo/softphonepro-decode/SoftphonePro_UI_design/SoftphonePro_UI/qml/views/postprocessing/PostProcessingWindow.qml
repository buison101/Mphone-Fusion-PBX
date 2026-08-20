import QtQuick 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.15
import Flux 1.0

import "../uicontrols" as SoftphonePro
import "../utils"

FocusScope {
    id: root

    property bool postProcessingWindowVisible

    onPostProcessingWindowVisibleChanged: {
        if (postProcessingWindowVisible) {
            focusReceiver.forceActiveFocus();
        }
    }

    implicitWidth: 230 * SettingsState.scale

    implicitHeight: 18 * SettingsState.scale
                    + title.height + title.anchors.topMargin
                    + duration.height + duration.anchors.topMargin
                    + (callTagDropdown.visible ? callTagDropdown.height + callTagDropdown.anchors.topMargin : 0)
                    + (viewBody.visible ? viewBody.height + viewBody.anchors.topMargin : 0)
                    + (dateTimePicker.visible ? dateTimePicker.height + dateTimePicker.anchors.topMargin : 0)
                    + (notesColumn.visible ? notesColumn.height + notesColumn.anchors.topMargin : 0)
                    + closeButton.height + closeButton.anchors.bottomMargin

    focus: true

    Formatter {
        id: fmt
    }

    MouseArea {
        anchors.fill: parent

        onPressed: {
            focusReceiver.focus = true;
            root.forceActiveFocus();
        }
    }

    Rectangle {
        anchors.fill: parent

        color: ColorStorage.secondaryWindowBackground

        Item {
            id: focusReceiver
            focus: true

            KeyNavigation.tab: viewCallTagButtons
        }

        Text {
            id: title

            anchors.top: parent.top
            anchors.topMargin: 15 * SettingsState.scale
            anchors.horizontalCenter: parent.horizontalCenter

            font.pixelSize: 16  * SettingsState.scale
            font.family: "Segoe UI"
            font.bold: true

            color: ColorStorage.iconsAndTextPrimary

            text: qsTrId("post_processing_window_title") + Translator.translate
        }

        TextEdit {
            id: duration

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: title.bottom
            anchors.topMargin: 7 * SettingsState.scale

            height: 30 * SettingsState.scale

            selectByMouse: true
            readOnly: true

            font.pixelSize: 16 * SettingsState.scale
            font.family: "Segoe UI"

            color: ColorStorage.iconsAndTextPrimary

            text: fmt.formatDuration(AppState.timeNow - AppState.postProcessingWindowOpenTime)
        }

        Rectangle {
            id: viewBody

            radius: 8 * SettingsState.scale
            width: viewCallTagButtons.implicitWidth
            height: viewCallTagButtons.implicitHeight

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: duration.bottom
            anchors.topMargin: 8 * SettingsState.scale

            visible: AppState.displayFirstNTagsAsButtons > 0

            focus: true

            ListView {
                id: viewCallTagButtons

                property int itemWidth: root.width - 32 * SettingsState.scale
                property int itemHeight: 40 * SettingsState.scale

                implicitWidth: itemWidth
                implicitHeight: AppState.displayFirstNTagsAsButtons * itemHeight

                model: AppState.callTagsButtonsModel

                focus:true

                KeyNavigation.backtab: closeButton
                KeyNavigation.tab: callTagDropdown

                layer.enabled: true
                layer.effect: OpacityMask {
                    source: delegateBody
                    maskSource: Rectangle {
                        width: viewBody.width
                        height: viewBody.height - 2 * SettingsState.scale
                        anchors.top: viewBody.top
                        radius: 8 * SettingsState.scale
                    }
                }

                Keys.onUpPressed: {
                    viewCallTagButtons.decrementCurrentIndex();
                }

                Keys.onDownPressed: {
                    viewCallTagButtons.incrementCurrentIndex();
                }

                Shortcut {
                    enabled: viewCallTagButtons.activeFocus
                    sequence: "Shift+Tab"

                    onActivated: {
                        closeButton.forceActiveFocus();
                    }
                }

                delegate: Rectangle {
                    id: delegateBody

                    readonly property string colorDefault: ColorStorage.mainWindowBackground
                    readonly property string colorOnHover: ColorStorage.surfaceSecondary

                    width: viewCallTagButtons.itemWidth
                    height: viewCallTagButtons.itemHeight

                    color: colorDefault

                    onActiveFocusChanged: {
                        color = activeFocus ? colorOnHover : colorDefault
                    }

                    Keys.onReturnPressed: {
                        ActionProvider.setCallTagIdx(viewCallTagButtons.currentIndex, type);
                    }

                    Shortcut {
                        enabled: true
                        sequence: index + 1

                        onActivated: {
                            ActionProvider.setCallTagIdx(viewCallTagButtons.currentIndex, type);
                        }
                    }

                    MouseArea {
                        anchors.fill: delegateBody
                        hoverEnabled: true

                        onEntered: {
                            viewCallTagButtons.currentIndex = index;
                            delegateBody.forceActiveFocus();
                        }

                        onExited: {
                            if (!parent.activeFocus) {
                                parent.color = parent.colorDefault;
                            }
                        }

                        onReleased: {
                            if (!containsMouse) {
                                return;
                            }

                            ActionProvider.setCallTagIdx(viewCallTagButtons.currentIndex, type);
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"

                        Text {
                            id: description

                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left:  parent.left
                            anchors.leftMargin: 15 * SettingsState.scale

                            font.family: "Segoe UI"
                            font.pixelSize: 13 * SettingsState.scale

                            elide: Text.ElideRight

                            text: name
                            visible: viewCallTagButtons.visible
                        }

                        Image {
                            id: check
                            anchors.right: parent.right
                            anchors.rightMargin: 10 * SettingsState.scale
                            anchors.verticalCenter: description.verticalCenter

                            width: 24 * SettingsState.scale
                            height: 24 * SettingsState.scale

                            visible: selected

                            source: selected ? "qrc:/images/check.svg" : ""
                        }
                        IconShader {
                            anchors.centerIn: check
                            visible: selected
                            imageSrcComponent: check
                            imgColor: ColorStorage.additionalText
                            imageWidth: check.width
                            imageHeight: check.height
                        }
                    }
                }
            }
        }

        SoftphonePro.CallTagsPopup {
            id: callTagDropdown

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: viewBody.visible ? viewBody.bottom : duration.bottom
            anchors.topMargin: (viewBody.visible ? 18 : 8) * SettingsState.scale

            enabled: true

            viewModel: AppState.callTagsModel

            visible: AppState.callTagsDropdownVisible && AppState.showPostProcessingWindow && listViewCount > 1

            hoverWide: root.width - 32 * SettingsState.scale

            title: qsTrId("disposition_codes_title") + Translator.translate
            selection: AppState.callTagsSelectedName

            selectionSize: 13 * SettingsState.scale

            KeyNavigation.backtab: viewCallTagButtons
            Keys.onTabPressed: {
                if (dateTimePicker.visible) {
                    dateTimePicker.focusFromTagDropdown = true;
                    dateTimePicker.forceActiveFocus();
                } else if (notesColumn.visible) {
                    notesField.forceActiveFocus();
                } else {
                    closeButton.forceActiveFocus();
                }
            }

            doWorkOnListItemClick: function(idx) {
                ActionProvider.setCallTagIdx(idx, modelType);
            }

            popupX: {
                return postProcessingWindow.x + 16 * SettingsState.scale;
            }

            popupY: {
                return postProcessingWindow.y + title.height + title.anchors.topMargin + duration.height + duration.anchors.topMargin
                        + (viewCallTagButtons.visible ? viewCallTagButtons.height + viewCallTagButtons.anchors.topMargin + 9 * SettingsState.scale : 0)
                                                       + callTagDropdown.anchors.topMargin;
            }
        }

        SoftphonePro.DateTimePicker {
            id: dateTimePicker

            anchors.top: callTagDropdown.visible ? callTagDropdown.bottom : (viewBody.visible ? viewBody.bottom : duration.bottom)
            anchors.topMargin: callTagDropdown.visible ? 18 * SettingsState.scale : viewBody.visible ? 18 * SettingsState.scale : 8 * SettingsState.scale
            anchors.horizontalCenter: parent.horizontalCenter

            enabled: true

            visible: AppState.showPostProcessingWindow && SettingsState.acwReminderEnabled

            hoverWide: root.width - 32 * SettingsState.scale

            title: qsTrId("acw_reminder_title") + Translator.translate

            selectionSize: 13 * SettingsState.scale

            popupX: {
                return postProcessingWindow.x + 16 * SettingsState.scale;
            }

            popupY: {
                return postProcessingWindow.y + title.height + title.anchors.topMargin + duration.height + duration.anchors.topMargin
                        + (viewCallTagButtons.visible ? viewCallTagButtons.height + viewCallTagButtons.anchors.topMargin : 0)
                        + (callTagDropdown.visible ? callTagDropdown.anchors.topMargin + callTagDropdown.height : 0)
                        + 9 * SettingsState.scale;
            }

            backtabRefocus: function() {
                if (callTagDropdown.visible) {
                    callTagDropdown.forceActiveFocus();
                } else if (viewCallTagButtons.visible) {
                    viewCallTagButtons.forceActiveFocus();
                } else {
                    closeButton.forceActiveFocus();
                }
            }
            tabRefocus: function() {
                if (notesColumn.visible) {
                    notesField.forceActiveFocus();
                } else {
                    closeButton.forceActiveFocus();
                }
            }

            onVisibleChanged: {
                if (SettingsState.acwNotesEnabled) {
                    notesField.forceActiveFocus();
                } else if (AppState.callTagsDropdownVisible) {
                    callTagDropdown.forceActiveFocus();
                } else if (viewCallTagButtons.visible) {
                    viewCallTagButtons.forceActiveFocus();
                } else {
                     closeButton.forceActiveFocus();
                }
            }
        }

        Rectangle {
            id: notesColumn
            anchors.top: dateTimePicker.visible ? dateTimePicker.bottom : callTagDropdown.visible ? callTagDropdown.bottom : viewBody.visible ? viewBody.bottom : duration.bottom
            anchors.topMargin: {
                if (dateTimePicker.visible || callTagDropdown.visible || viewBody.visible) {
                    return 18 * SettingsState.scale;
                } else {
                    return 8 * SettingsState.scale;
                }
            }
            anchors.horizontalCenter: parent.horizontalCenter

            radius: 8 * SettingsState.scale

            width: root.width - 32 * SettingsState.scale

            height: 90 * SettingsState.scale

            visible: AppState.showPostProcessingWindow && SettingsState.acwNotesEnabled
            color: ColorStorage.mainWindowBackground

            onVisibleChanged: {
                notesField.text = "";
            }

            Text {
                id: notesTitle

                anchors.left: parent.left
                anchors.leftMargin: 10 * SettingsState.scale
                anchors.top: parent.top
                anchors.topMargin: 5 * SettingsState.scale

                enabled: false
                visible: notesField.visible && notesField.text == "" && !notesField.activeFocus

                font.family: "Segoe UI"
                font.pixelSize: 14 * SettingsState.scale

                text: qsTrId("acw_notes_title") + Translator.translate

                color: root.enabled ? ColorStorage.additionalText : ColorStorage.disabledButtonsGrey
            }


            TextArea {
                id: notesField

                anchors.fill: parent

                focus: true

                wrapMode: Text.Wrap
                selectByMouse: true

                font.pixelSize: 14 * SettingsState.scale

                color: ColorStorage.iconsAndTextPrimary

                background: Rectangle {
                    color: "transparent"
                    radius: 8 * SettingsState.scale
                    border.color: notesField.activeFocus ? ColorStorage.grayNeutralOnPress : "transparent"
                    border.width: 1 * SettingsState.scale
                }

                Keys.onTabPressed: {
                    closeButton.forceActiveFocus();
                }

                Keys.onBacktabPressed: {
                    if (dateTimePicker.visible) {
                        dateTimePicker.focusFromTagDropdown = false;
                        dateTimePicker.forceActiveFocus();
                    } else if (callTagDropdown.visible) {
                        callTagDropdown.forceActiveFocus();
                    } else if (viewCallTagButtons.visible) {
                        viewCallTagButtons.forceActiveFocus();
                    } else {
                        closeButton.forceActiveFocus();
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    visible: false
                }
            }
        }

        SoftphonePro.SquareButton {
            id: closeButton

            scale: SettingsState.scale

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 18 * scale

            width: root.width - 32 * scale
            height: 32 * scale

            radius: 8 * scale

            colorDefault: ColorStorage.red
            colorOnHover: ColorStorage.redOnHover
            colorOnPress: ColorStorage.redOnPress

            Text {
                id: name

                anchors.centerIn: parent

                visible: true

                font.pixelSize: 14 * closeButton.scale
                font.family: "Segoe UI"

                color: ColorStorage.white
                text: qsTrId("app_general_complete_title") + Translator.translate
            }

            doWorkOnButtonClick: function() {
                dateTimePicker.selectedDate.setHours(dateTimePicker.hours)
                dateTimePicker.selectedDate.setMinutes(dateTimePicker.minutes)

                ActionProvider.tryToFinishPostProcessing(AppState.callTag, dateTimePicker.selectedDate, notesField.text);
            }

            Keys.onBacktabPressed: {
                if (notesColumn.visible) {
                    notesField.forceActiveFocus();
                } else if (dateTimePicker.visible) {
                    dateTimePicker.focusFromTagDropdown = false;
                    dateTimePicker.forceActiveFocus();
                } else if (callTagDropdown.visible) {
                    callTagDropdown.forceActiveFocus();
                } else {
                    viewCallTagButtons.forceActiveFocus();
                }
            }
            KeyNavigation.tab: viewCallTagButtons.visible ? viewCallTagButtons :  callTagDropdown.visible ? callTagDropdown : dateTimePicker.visible ? dateTimePicker : notesField.visible ? notesField : closeButton
        }
    }
}
