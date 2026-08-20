import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import Flux 1.0

import "../uicontrols"

ApplicationWindow {
    id: root

    property var onOKAction: function func() {}
    property var onCancelAction: function func() {}

    title: qsTrId("dialog_new_external_event_receiver") + Translator.translate

    flags: {
        return AppFeatures.osType == OSType.Unix ?
                    (Qt.Window | Qt.CustomizeWindowHint | Qt.WindowTitleHint |
                     Qt.WindowSystemMenuHint | Qt.WindowCloseButtonHint | Qt.WindowStaysOnTopHint)
                  : (Qt.Window | Qt.CustomizeWindowHint | Qt.WindowTitleHint |
                     Qt.WindowSystemMenuHint | Qt.WindowCloseButtonHint)
    }

    minimumWidth: width
    minimumHeight: height

    maximumWidth: minimumWidth
    maximumHeight: minimumHeight

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
            root.onCancelAction();
        }
    }

    Rectangle {
        anchors.fill: parent

        color: ColorStorage.settingsWindowBaseColor
        clip: true

        Label {
            id: eventLabel

            anchors.top: parent.top
            anchors.topMargin: 20
            anchors.left: parent.left
            anchors.leftMargin: 20

            font.pixelSize: 11

            text: qsTrId("dialog_new_external_event_receiver_event") + Translator.translate
        }

        Component {
            id: eventComboboxComponent

            SettingsComboBox {
                id: eventCombobox

                width: parent ? parent.width : 0

                textRole: "name"
                model: SettingsState.externalEventReceiverEventModel

                property int externalEventReceiverEventModelIdx: SettingsState.externalEventReceiverEventModelIdx

                onExternalEventReceiverEventModelIdxChanged: {
                    currentIndex = externalEventReceiverEventModelIdx;
                }

                onCurrentIndexChanged: {
                    if (currentIndex != externalEventReceiverEventModelIdx) {
                        ActionProvider.markExternalEventReceiverUpdate(ExternalEventReceiver.EventType, currentIndex);
                    }
                }
            }
        }

        Loader {
            id: eventComboboxLoader

            anchors.verticalCenter: eventLabel.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 20

            width: 180

            sourceComponent: root.visible ? eventComboboxComponent : null
        }

        Label {
            id: accountLabel

            anchors.top: eventLabel.bottom
            anchors.topMargin: 20
            anchors.left: parent.left
            anchors.leftMargin: 20

            font.pixelSize: 11

            visible: {
                return eventComboboxLoader.item.model.getEventTypeInt(eventComboboxLoader.item.currentIndex) != ExternalEventType.StatusChanged;
            }

            text: qsTrId("dialog_new_external_event_receiver_sip_account") + Translator.translate
        }

        Component {
            id: accountComboboxComponent

            SettingsComboBox {
                id: accountCombobox

                width: parent ? parent.width : 0

                visible: accountLabel.visible

                textRole: "name"
                model: SettingsState.externalEventReceiverAccountModel

                property int externalEventReceiverAccountModelIdx: SettingsState.externalEventReceiverAccountModelIdx

                onExternalEventReceiverAccountModelIdxChanged: {
                    currentIndex = externalEventReceiverAccountModelIdx;
                }

                onCurrentIndexChanged: {
                    if (currentIndex != externalEventReceiverAccountModelIdx) {
                        ActionProvider.markExternalEventReceiverUpdate(ExternalEventReceiver.SipAccount, currentIndex);
                    }
                }
            }
        }

        Loader {
            id: accountComboboxLoader

            anchors.verticalCenter: accountLabel.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 20

            width: eventComboboxLoader.width

            sourceComponent: root.visible ? accountComboboxComponent : null
        }

        Label {
            id: actionLabel

            anchors.top: accountLabel.visible ? accountLabel.bottom : eventLabel.bottom
            anchors.topMargin: 20
            anchors.left: parent.left
            anchors.leftMargin: 20

            font.pixelSize: 11

            text: qsTrId("dialog_new_external_event_receiver_action") + Translator.translate
        }

        Component {
            id: actionComboboxComponent

            SettingsComboBox {
                id: actionCombobox

                width: parent ? parent.width : 0

                textRole: "name"
                model: SettingsState.externalEventReceiverActionModel

                property bool typeChanged: false
                property int externalEventReceiverActionModelIdx: SettingsState.externalEventReceiverActionModelIdx

                onExternalEventReceiverActionModelIdxChanged: {
                    currentIndex = externalEventReceiverActionModelIdx;
                }

                onCurrentIndexChanged: {
                    if (currentIndex != externalEventReceiverActionModelIdx) {
                        typeChanged = true;
                        ActionProvider.markExternalEventReceiverUpdate(ExternalEventReceiver.AppType, currentIndex);
                    }
                }
            }
        }

        Loader {
            id: actionComboboxLoader

            anchors.verticalCenter: actionLabel.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 20

            width: eventComboboxLoader.width

            sourceComponent: root.visible ? actionComboboxComponent : null
        }

        Label {
            id: titleLabel

            anchors.top:actionLabel.bottom
            anchors.topMargin: 40
            anchors.left: parent.left
            anchors.leftMargin: 20

            visible: eventComboboxLoader.item.model.getEventTypeInt(eventComboboxLoader.item.currentIndex) === ExternalEventType.ButtonClick
            font.pixelSize: 11

            text: qsTrId("dialog_new_external_event_receiver_title") + Translator.translate
        }

        Component {
            id: titleTexteditComponent

            SettingsTextField {
                id: titleTextedit

                property bool resetPositionOnCompleted: true
                property string externalEventReceiverTitle: SettingsState.externalEventReceiver ? SettingsState.externalEventReceiver.title : ""

                onExternalEventReceiverTitleChanged: {
                    text = externalEventReceiverTitle;
                }

                onTextChanged: {
                    if (text != externalEventReceiverTitle) {
                        ActionProvider.markExternalEventReceiverUpdate(ExternalEventReceiver.Title, text);
                    }
                }
            }
        }

        Loader {
            id: titleTexteditLoader

            visible: titleLabel.visible
            width: urlTexteditLoader.width
            anchors.verticalCenter: titleLabel.verticalCenter
            anchors.left: httpMethodLabel.right
            anchors.leftMargin: 27

            sourceComponent: root.visible ? titleTexteditComponent : null
        }

        Label {
            id: httpMethodLabel

            anchors.top: titleLabel.visible ? titleLabel.bottom : actionLabel.bottom
            anchors.topMargin: titleLabel.visible ? 20 : 40
            anchors.left: parent.left
            anchors.leftMargin: 20

            font.pixelSize: 11

            visible: {
                if (!actionComboboxLoader.sourceComponent || !actionComboboxLoader.item.model) {
                    return false;
                }

                return actionComboboxLoader.item.model.getAppTypeInt(actionComboboxLoader.item.currentIndex) != ExternalAppType.Local &&
                        actionComboboxLoader.item.model.getAppTypeInt(actionComboboxLoader.item.currentIndex) != ExternalAppType.CallRecordToWeb &&
                        actionComboboxLoader.item.model.getAppTypeInt(actionComboboxLoader.item.currentIndex) != ExternalAppType.VideoRecordToWeb;
                        eventComboboxLoader.item.model.getEventTypeInt(eventComboboxLoader.item.currentIndex) != ExternalEventType.StatusChanged;
            }

            text: qsTrId("dialog_new_external_event_receiver_http_method") + Translator.translate
        }

        SettingsComboBox {
            id: httpMethodCombobox

            anchors.verticalCenter: httpMethodLabel.verticalCenter
            anchors.left: httpMethodLabel.right
            anchors.leftMargin: 27

            width: urlTexteditLoader.width

            visible: httpMethodLabel.visible
            enabled: false

            textRole: "name"
            model: SettingsState.externalEventReceiverHttpModel
        }

        Label {
            id: urlLabel

            anchors.top: httpMethodLabel.visible ? httpMethodLabel.bottom : httpMethodLabel.top
            anchors.topMargin: httpMethodLabel.visible ? 20 : 0
            anchors.left: parent.left
            anchors.leftMargin: 20

            font.pixelSize: 11

            text: qsTrId("dialog_new_external_event_receiver_url") + Translator.translate
        }

        Component {
            id: urlTexteditComponent

            SettingsTextField {
                id: urlTextedit

                property bool resetPositionOnCompleted: true
                property string externalEventReceiverUrl: SettingsState.externalEventReceiver ? SettingsState.externalEventReceiver.url : ""

                onExternalEventReceiverUrlChanged: {
                    text = externalEventReceiverUrl;

                    if (actionComboboxLoader.sourceComponent && actionComboboxLoader.item.typeChanged) {
                        actionComboboxLoader.item.typeChanged = false;
                        urlTextedit.cursorPosition = 0;
                    }

                    if (resetPositionOnCompleted) {
                        urlTextedit.cursorPosition = 0;
                        resetPositionOnCompleted = false;
                    }
                }

                onTextChanged: {
                    if (text != externalEventReceiverUrl) {
                        ActionProvider.markExternalEventReceiverUpdate(ExternalEventReceiver.Link, text);
                    }
                }
            }
        }

        Loader {
            id: urlTexteditLoader

            anchors.verticalCenter: urlLabel.verticalCenter
            anchors.left: httpMethodLabel.right
            anchors.leftMargin: 27
            anchors.right: testButton.left
            anchors.rightMargin: 20

            sourceComponent: root.visible ? urlTexteditComponent : null
        }

        Row {
            id: statusChangeIntervalRow

            height: periodicallyCallSpinBox.height
            anchors.top: inputNameLabel.visible ? inputNameLabel.bottom : urlLabel.bottom
            anchors.topMargin: 20
            anchors.left: parent.left
            anchors.leftMargin: 20

            visible: eventComboboxLoader.item.model.getEventTypeInt(eventComboboxLoader.item.currentIndex) === ExternalEventType.StatusChanged;

            SettingsCheckBox {
                id: periodicallyCallChechBox

                property bool periodicallyCall: SettingsState.externalEventReceiver ? SettingsState.externalEventReceiver.periodicalSendPhoneStatusEnabled : false

                checked: periodicallyCall

                onCheckedChanged: {
                    if (checked != periodicallyCall) {
                        ActionProvider.markExternalEventReceiverUpdate(ExternalEventReceiver.PeriodicalSendPhoneStatusEnabled, checked);
                    }
                }

                onPeriodicallyCallChanged: {
                    checked = periodicallyCall;
                }
            }

            Label {
                id: periodicallyCallLabel

                anchors.left: periodicallyCallChechBox.right
                anchors.leftMargin: 2
                anchors.verticalCenter: periodicallyCallChechBox.verticalCenter
                text: qsTrId("external_app_status_change_periodically_call") + Translator.translate
                font.pixelSize: 11
            }

            SpinBox {
                id: periodicallyCallSpinBox

                anchors.left: periodicallyCallLabel.right
                anchors.leftMargin: 15
                anchors.verticalCenter: periodicallyCallChechBox.verticalCenter

                enabled: periodicallyCallChechBox.checked

                height: 30
                width: 110

                from: 1
                to: 600
                stepSize: 1

                value: SettingsState.externalEventReceiver ? SettingsState.externalEventReceiver.periodicalSendPhoneStatusInterval : 10

                onValueChanged: {
                    ActionProvider.markExternalEventReceiverUpdate(ExternalEventReceiver.PeriodicalSendPhoneStatusIntervalSec, value);
                }
            }

            Label {
                anchors.left: periodicallyCallSpinBox.right
                anchors.leftMargin: 15
                anchors.verticalCenter: periodicallyCallSpinBox.verticalCenter
                text: qsTrId("seconds") + Translator.translate
                font.pixelSize: 11
            }
        }

        Label {
            id: inputNameLabel

            anchors.top: urlLabel.visible ? urlLabel.bottom : urlLabel.top
            anchors.topMargin: urlLabel.visible ? 20 : 0
            anchors.left: parent.left
            anchors.leftMargin: 20

            font.pixelSize: 11

            visible: {
                var currentType = actionComboboxLoader.item.model.getAppTypeInt(actionComboboxLoader.item.currentIndex);

                return currentType === ExternalAppType.CallRecordToWeb
                     || currentType === ExternalAppType.VideoRecordToWeb
                     || currentType === ExternalAppType.WebCamImageToWeb
            }

            text: qsTrId("dialog_new_external_event_receiver_input_name") + Translator.translate
        }

        Component {
            id: inputNameTexteditComponent

            SettingsTextField {
                id: inputNameTextedit

                font.pixelSize: 11

                property bool resetPositionOnCompleted: true
                property string externalEventReceiverInputName: SettingsState.externalEventReceiver ?
                                                                SettingsState.externalEventReceiver.inputName : ""
                onExternalEventReceiverInputNameChanged: {
                    text = externalEventReceiverInputName;

                    if (actionComboboxLoader.sourceComponent && actionComboboxLoader.item.typeChanged) {
                        actionComboboxLoader.item.typeChanged = false;
                        inputNameTextedit.cursorPosition = 0;
                    }

                    if (resetPositionOnCompleted) {
                        inputNameTextedit.cursorPosition = 0;
                        resetPositionOnCompleted = false;
                    }
                }

                onTextChanged: {
                    if (text != externalEventReceiverInputName) {
                        ActionProvider.markExternalEventReceiverUpdate(ExternalEventReceiver.InputName, text);
                    }
                }
            }
        }

        Loader {
            id: inputNameTexteditLoader

            anchors.verticalCenter: inputNameLabel.verticalCenter
            anchors.left: inputNameLabel.right
            anchors.leftMargin: 20
            anchors.right: testButton.left
            anchors.rightMargin: 20

            visible: inputNameLabel.visible

            sourceComponent: root.visible ? inputNameTexteditComponent : null
        }

        SettingsButton {
            id: testButton

            anchors.verticalCenter: urlTexteditLoader.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 20

            enabled: {
                var currentType = actionComboboxLoader.item.model.getAppTypeInt(actionComboboxLoader.item.currentIndex);
                return currentType !== ExternalAppType.CallRecordToWeb && currentType !== ExternalAppType.VideoRecordToWeb;
            }

            text: qsTrId("dialog_new_external_event_receiver_test_button") + Translator.translate

            onClicked: {
                ActionProvider.testExternalEventReceiver();
            }
        }

        Label {
            id: argsTitleLabel

            anchors.top: statusChangeIntervalRow.visible ? statusChangeIntervalRow.bottom : urlTexteditLoader.bottom
            anchors.topMargin: 30
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.right: parent.right
            anchors.rightMargin: 20

            wrapMode: Text.WordWrap

            font.pixelSize: 11

            visible: !inputNameLabel.visible

            text: qsTrId("dialog_new_external_event_receiver_args_title") + ":" + Translator.translate
        }

        Label {
            id: argsDescriptionLabel

            anchors.top: argsTitleLabel.bottom
            anchors.topMargin: 20
            anchors.left: argsTitleLabel.left
            anchors.leftMargin: 60

            font.pixelSize: 11

            visible: !inputNameLabel.visible

            text: SettingsState.externalEventReceiverArgs
        }

        Label {
            id: argsDescriptionLabelDesc

            anchors.verticalCenter: argsDescriptionLabel.verticalCenter
            anchors.left: argsDescriptionLabel.right
            anchors.leftMargin: 30

            font.pixelSize: 11

            visible: !inputNameLabel.visible

            text: SettingsState.externalEventReceiverArgsDesc
        }

        SettingsButton {
            id: ok

            anchors.verticalCenter: cancel.verticalCenter
            anchors.right: cancel.left
            anchors.rightMargin: 10

            text: qsTrId("dialog_button_save") + Translator.translate

            onClicked: {
                onOkWithValidation();
            }

            function onOkWithValidation() {
                root.onOKAction();
            }
        }

        SettingsButton {
            id: cancel

            anchors.bottom: parent.bottom
            anchors.bottomMargin: 20
            anchors.right: parent.right
            anchors.rightMargin: 20

            text: qsTrId("dialog_button_cancel") + Translator.translate

            onClicked: {
                root.onCancelAction();
            }
        }
    }

    onClosing: {
        close.accepted = false;
        root.onCancelAction();
    }
}
