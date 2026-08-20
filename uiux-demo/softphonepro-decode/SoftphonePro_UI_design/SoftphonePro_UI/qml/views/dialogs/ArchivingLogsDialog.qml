import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import Flux 1.0

import "../uicontrols"

ApplicationWindow {
    id: root

    property int finalWidth: copyMsg.width + 2 * Math.max(idField.width, okButton.width, cancelButton.width, copyButton.width)
    property int finalHeight: copyMsg.height + 2 * Math.max(idField.height, okButton.height, copyButton.height, cancelButton.height) + 10
    width: finalWidth
    height: finalHeight

    maximumWidth: width
    maximumHeight: height
    minimumWidth: width
    minimumHeight: height

    title: qsTrId("dialog_error_report") + Translator.translate

    flags: (Qt.Window | Qt.CustomizeWindowHint | Qt.WindowTitleHint |
                     Qt.WindowSystemMenuHint | Qt.WindowCloseButtonHint | Qt.WindowStaysOnTopHint)


    modality: Qt.WindowModal

    onVisibleChanged: {
        if (root.visible) {
            root.requestActivate();
        }
    }

    property bool instanceWillDestroy: AppState.instanceWillDestroy

    onInstanceWillDestroyChanged: {
        if (instanceWillDestroy) {
            root.destroy();
        }
    }

    Shortcut {
        enabled: visible
        sequence: "Esc"

        onActivated: {
            ActionProvider.sendingErrorReportCancel();
        }
    }

    FocusScope {
        anchors.fill: parent
        focus: true

        Rectangle {
            anchors.fill: parent

            color: ColorStorage.settingsWindowBaseColor
            clip: true

            Label {
                id: msg

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 10
                anchors.leftMargin: 30
                anchors.rightMargin: 30

                visible: !copyMsg.visible

                text: {
                    if (AppState.sendingErrorReportStatus == SendingErrorReportStatus.CreatingArchive) {
                        return qsTrId("dialog_generating_error_report") + Translator.translate;
                    }

                    else if (AppState.sendingErrorReportStatus == SendingErrorReportStatus.SendingReport ||
                            SendingErrorReportStatus.SuccessSending) {
                        return qsTrId("dialog_sending_support_info") + Translator.translate;
                    }
                }

                wrapMode: Text.WordWrap
            }

            Label {
                id: copyMsg

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: 10
                anchors.leftMargin: 30
                anchors.rightMargin: 30

                visible: AppState.sendingErrorReportStatus == SendingErrorReportStatus.SuccessReply

                text: qsTrId("dialog_copy_id_message") + Translator.translate
                horizontalAlignment: Text.AlignHCenter

                wrapMode: Text.WordWrap
            }

            TextField {
                id: idField

                anchors.top: copyMsg.bottom
                anchors.topMargin: 15
                anchors.right: parent.horizontalCenter
                anchors.rightMargin: 5
                width: 100
                height: 25

                visible: copyMsg.visible

                text: AppState.errorReportId
                readOnly: true
                selectByMouse: true
                selectionColor: ColorStorage.selectionInputColor
                selectedTextColor: ColorStorage.iconsAndTextPrimary
            }

            BusyIndicator {
                id: busyIndicator

                anchors.top: msg.bottom
                anchors.topMargin: 10
                anchors.horizontalCenter: parent.horizontalCenter

                width: 30
                height: width

                visible: msg.visible
                running: visible
            }

            SettingsButton {
                id: okButton

                anchors.horizontalCenter: idField.horizontalCenter
                anchors.top: idField.bottom
                anchors.topMargin: 15

                focus: true
                enabled: AppState.sendingErrorReportStatus == SendingErrorReportStatus.SuccessReply

                text: qsTrId("dialog_button_ok") + Translator.translate

                onClicked: {
                    ActionProvider.sendingErrorReportCancel();
                }

                Keys.onReturnPressed: {
                    ActionProvider.sendingErrorReportCancel();
                }

                Keys.onEnterPressed: {
                    ActionProvider.sendingErrorReportCancel();
                }
            }

            SettingsButton {
                id: cancelButton

                anchors.horizontalCenter: copyButton.horizontalCenter
                anchors.verticalCenter: okButton.verticalCenter

                focus: !okButton.focus

                enabled: !okButton.enabled

                text: qsTrId("dialog_button_cancel") + Translator.translate

                onClicked: {
                    ActionProvider.sendingErrorReportCancel();
                }

                Keys.onReturnPressed: {
                    ActionProvider.sendingErrorReportCancel();
                }

                Keys.onEnterPressed: {
                    ActionProvider.sendingErrorReportCancel();
                }
            }

            SettingsButton {
                id: copyButton

                anchors.verticalCenter: idField.verticalCenter
                anchors.left: parent.horizontalCenter
                anchors.leftMargin: 5
                width: 100

                visible: copyMsg.visible

                enabled: visible

                text: qsTrId("dialog_button_copy") + Translator.translate

                onClicked: {
                    idField.selectAll();
                    idField.copy();
                }

                Keys.onReturnPressed: {
                    idField.selectAll();
                    idField.copy();
                }

                Keys.onEnterPressed: {
                    idField.selectAll();
                    idField.copy();
                }
            }
        }
    }
    onClosing: {
        close.accepted = false;
        ActionProvider.sendingErrorReportCancel();
    }
}
