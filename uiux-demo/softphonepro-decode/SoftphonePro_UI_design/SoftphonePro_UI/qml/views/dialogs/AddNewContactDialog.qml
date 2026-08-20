import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import Flux 1.0

import "../uicontrols"

ApplicationWindow {
    id: root

    property var onOKAction: function func() {}
    property var onCancelAction: function func() {}

    title: qsTrId("dialog_new_contact_title") + Translator.translate

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

    property bool enableContactNameAndPhoneEditing: {
        return SettingsState.contact.contactType == ContactType.Local ||
                SettingsState.contact.contactType == ContactType.Unknown;
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
            id: nameLabel

            anchors.top: parent.top
            anchors.topMargin: 20
            anchors.left: parent.left
            anchors.leftMargin: 20

            enabled: enableContactNameAndPhoneEditing

            font.pixelSize: 11

            text: qsTrId("dialog_new_contact_name") + Translator.translate
        }

        Label {
            anchors.left: nameLabel.right
            anchors.leftMargin: 1
            anchors.baseline: nameLabel.baseline

            enabled: enableContactNameAndPhoneEditing

            font.pixelSize: 11

            text: "*"
            color: "red"
        }

        SettingsTextField {
            id: nameField

            anchors.verticalCenter: nameLabel.verticalCenter
            anchors.left: phoneField1.left
            anchors.right: parent.right
            anchors.rightMargin: 20

            enabled: enableContactNameAndPhoneEditing

            property string name: SettingsState.contact.name

            text: name
            font.pixelSize: 11

            onTextChanged: {
                if (text != name) {
                    ActionProvider.markContactUpdate(Contact.Name, text);
                }
            }

            onNameChanged: {
                text = name;
            }

            Keys.onReturnPressed: {
                ok.onOkWithValidation();
            }

            Keys.onEnterPressed: {
                ok.onOkWithValidation();
            }
        }

        SettingsComboBox {
            id: phoneCombobox1

            anchors.top: nameLabel.bottom
            anchors.topMargin: 20
            anchors.left: nameLabel.left

            width: 90

            enabled: enableContactNameAndPhoneEditing

            textRole: "name"
            model: SettingsState.phoneTypeModel

            property int idx: 0
            property var type: SettingsState.contact.phoneTypes[idx]

            currentIndex: type

            onCurrentIndexChanged: {
                if (currentIndex != type) {
                    ActionProvider.markContactUpdate(Contact.PhoneType,
                                                     {id: idx, type: currentIndex});
                }
            }

            onTypeChanged: {
                currentIndex = type;
            }

            // hack to response on dynamic lang change
            property string lang: root.title

            onLangChanged: {
                var lastIdx = currentIndex;
                currentIndex = -1;
                currentIndex = lastIdx;
            }
        }

        SettingsTextField {
            id: phoneField1

            anchors.verticalCenter: phoneCombobox1.verticalCenter
            anchors.left: phoneCombobox1.right
            anchors.leftMargin: 20
            anchors.right: parent.right
            anchors.rightMargin: 20

            enabled: enableContactNameAndPhoneEditing

            property int idx: 0
            property string phone: SettingsState.contact.phoneNumbers[idx]

            text: phone
            font.pixelSize: 11

            onTextChanged: {
                if (text != phone) {
                    ActionProvider.markContactUpdate(Contact.PhoneNumber,
                                                     {id: idx, phone: text});
                }
            }

            onPhoneChanged: {
                text = phone;
            }

            Keys.onReturnPressed: {
                ok.onOkWithValidation();
            }

            Keys.onEnterPressed: {
                ok.onOkWithValidation();
            }
        }

        SettingsComboBox {
            id: phoneCombobox2

            anchors.top: phoneCombobox1.bottom
            anchors.topMargin: 20
            anchors.left: phoneCombobox1.left

            width: phoneCombobox1.width

            enabled: enableContactNameAndPhoneEditing

            textRole: "name"
            model: SettingsState.phoneTypeModel

            property int idx: 1
            property var type: SettingsState.contact.phoneTypes[idx]

            currentIndex: type

            onCurrentIndexChanged: {
                if (currentIndex != type) {
                    ActionProvider.markContactUpdate(Contact.PhoneType,
                                                     {id: idx, type: currentIndex});
                }
            }

            onTypeChanged: {
                currentIndex = type;
            }

            // hack to response on dynamic lang change
            property string lang: root.title

            onLangChanged: {
                var lastIdx = currentIndex;
                currentIndex = -1;
                currentIndex = lastIdx;
            }
        }

        SettingsTextField {
            id: phoneField2

            anchors.verticalCenter: phoneCombobox2.verticalCenter
            anchors.left: phoneCombobox2.right
            anchors.leftMargin: 20
            anchors.right: parent.right
            anchors.rightMargin: 20

            enabled: enableContactNameAndPhoneEditing

            property int idx: 1
            property string phone: SettingsState.contact.phoneNumbers[idx]

            text: phone
            font.pixelSize: 11

            onTextChanged: {
                if (text != phone) {
                    ActionProvider.markContactUpdate(Contact.PhoneNumber,
                                                     {id: idx, phone: text});
                }
            }

            onPhoneChanged: {
                text = phone;
            }

            Keys.onReturnPressed: {
                ok.onOkWithValidation();
            }

            Keys.onEnterPressed: {
                ok.onOkWithValidation();
            }
        }

        SettingsComboBox {
            id: phoneCombobox3

            anchors.top: phoneCombobox2.bottom
            anchors.topMargin: 20
            anchors.left: phoneCombobox2.left

            width: phoneCombobox1.width

            enabled: enableContactNameAndPhoneEditing

            textRole: "name"
            model: SettingsState.phoneTypeModel

            property int idx: 2
            property var type: SettingsState.contact.phoneTypes[idx]

            currentIndex: type

            onCurrentIndexChanged: {
                if (currentIndex != type) {
                    ActionProvider.markContactUpdate(Contact.PhoneType,
                                                     {id: idx, type: currentIndex});
                }
            }

            onTypeChanged: {
                currentIndex = type;
            }

            // hack to response on dynamic lang change
            property string lang: root.title

            onLangChanged: {
                var lastIdx = currentIndex;
                currentIndex = -1;
                currentIndex = lastIdx;
            }
        }

        SettingsTextField {
            id: phoneField3

            anchors.verticalCenter: phoneCombobox3.verticalCenter
            anchors.left: phoneCombobox3.right
            anchors.leftMargin: 20
            anchors.right: parent.right
            anchors.rightMargin: 20

            enabled: enableContactNameAndPhoneEditing

            property int idx: 2
            property string phone: SettingsState.contact.phoneNumbers[idx]

            text: phone
            font.pixelSize: 11

            onTextChanged: {
                if (text != phone) {
                    ActionProvider.markContactUpdate(Contact.PhoneNumber,
                                                     {id: idx, phone: text});
                }
            }

            onPhoneChanged: {
                text = phone;
            }

            Keys.onReturnPressed: {
                ok.onOkWithValidation();
            }

            Keys.onEnterPressed: {
                ok.onOkWithValidation();
            }
        }

        SettingsGroupBox {
            id: officePBX

            anchors.top: phoneCombobox3.bottom
            anchors.topMargin: 30
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.right: parent.right
            anchors.rightMargin: 20

            enabled: SettingsState.contact.contactType != ContactType.CiscoXml

            height: 305
            width: parent.width - 40

            title: qsTrId("dialog_new_contact_office_pbx_user") + Translator.translate


            SettingsCheckBox {
                id: callForwardUseCheckbox

                anchors.top: parent.top
                anchors.topMargin: 15
                anchors.left: parent.left
                anchors.leftMargin: 10

                property bool useForCallTransfer: SettingsState.contact.useForCallTransfer

                checked: useForCallTransfer

                onCheckedChanged: {
                    if (checked != useForCallTransfer) {
                        ActionProvider.markContactUpdate(Contact.CallTransfer, checked);
                    }
                }

                onUseForCallTransferChanged: {
                    checked = useForCallTransfer;
                }
            }

            Label {
                id: callForwardUseLabel

                anchors.left: callForwardUseCheckbox.right
                anchors.leftMargin: 10
                anchors.verticalCenter: callForwardUseCheckbox.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 10

                font.pixelSize: 11

                text: qsTrId("dialog_new_contact_call_forward_use") + Translator.translate
            }

            Label {
                id: callForwardUseDescLabel

                anchors.top: callForwardUseLabel.bottom
                anchors.topMargin: 10
                anchors.left: callForwardUseLabel.left
                anchors.right: parent.right
                anchors.rightMargin: 10

                wrapMode: Text.WordWrap

                font.pixelSize: 11

                text: qsTrId("dialog_new_contact_call_forward_use_desc") + Translator.translate
            }

            SettingsCheckBox {
                id: getContactInfoCheckbox

                anchors.top: callForwardUseDescLabel.bottom
                anchors.topMargin: 25
                anchors.left: parent.left
                anchors.leftMargin: 10

                property bool subscribeForEvents: SettingsState.contact.subscribeForEvents

                checked: subscribeForEvents

                onCheckedChanged: {
                    if (checked != subscribeForEvents) {
                        ActionProvider.markContactUpdate(Contact.Subscription, checked);
                    }
                }

                onSubscribeForEventsChanged: {
                    checked = subscribeForEvents;
                }
            }

            Label {
                id: getContactInfoLabel

                anchors.left: getContactInfoCheckbox.right
                anchors.leftMargin: 10
                anchors.verticalCenter: getContactInfoCheckbox.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 10

                font.pixelSize: 11

                text: qsTrId("dialog_new_contact_get_contact_info") + Translator.translate
            }

            Label {
                id: getContactInfoDescLabel

                anchors.top: getContactInfoLabel.bottom
                anchors.topMargin: 10
                anchors.left: getContactInfoLabel.left
                anchors.right: parent.right
                anchors.rightMargin: 10

                wrapMode: Text.WordWrap
                font.pixelSize: 11

                text: qsTrId("dialog_new_contact_get_contact_info_desc") + Translator.translate
            }

            Label {
                id: accountLabel

                anchors.top: getContactInfoDescLabel.bottom
                anchors.topMargin: 30
                anchors.left: getContactInfoDescLabel.left

                enabled: getContactInfoCheckbox.checked
                font.pixelSize: 11

                text: qsTrId("dialog_new_contact_account") + Translator.translate
            }

            Label {
                anchors.left: accountLabel.right
                anchors.leftMargin: 1
                anchors.baseline: accountLabel.baseline

                enabled: getContactInfoCheckbox.checked
                font.pixelSize: 11

                text: "*"
                color: "red"
            }

            SettingsComboBox {
                id: accountCombobox

                anchors.left: userField.left
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: accountLabel.verticalCenter

                enabled: getContactInfoCheckbox.checked

                textRole: "name"
                model: AppState.sipAccountModel

                property var contact: SettingsState.contact
                property int accountId: SettingsState.contact.accountId

                onContactChanged: {
                    if (contact && contact.accountId != -1) {
                        currentIndex = contact.accountId;
                    }
                    else {
                        currentIndex = 0;
                    }

                    ActionProvider.markContactUpdate(Contact.SipAccount, currentIndex);
                }

                onCurrentIndexChanged: {
                    if (currentIndex != accountId) {
                        ActionProvider.markContactUpdate(Contact.SipAccount, currentIndex);
                    }
                }
            }

            Label {
                id: userLabel

                anchors.top: accountLabel.bottom
                anchors.topMargin: 30
                anchors.left: getContactInfoDescLabel.left

                enabled: getContactInfoCheckbox.checked
                font.pixelSize: 11

                text: qsTrId("dialog_new_contact_user") + Translator.translate
            }

            Label {
                anchors.left: userLabel.right
                anchors.leftMargin: 1
                anchors.baseline: userLabel.baseline

                enabled: getContactInfoCheckbox.checked
                font.pixelSize: 11

                text: "*"
                color: "red"
            }

            SettingsTextField {
                id: userField

                enabled: getContactInfoCheckbox.checked

                anchors.verticalCenter: userLabel.verticalCenter
                anchors.left: userLabel.right
                anchors.leftMargin: 25
                anchors.right: parent.right
                anchors.rightMargin: 10

                property string user: SettingsState.contact.sipUser

                text: user
                font.pixelSize: 11

                onTextChanged: {
                    if (text != user) {
                        ActionProvider.markContactUpdate(Contact.SipUser, text);
                    }
                }

                onUserChanged: {
                    text = user;
                }

                Keys.onReturnPressed: {
                    ok.onOkWithValidation();
                }

                Keys.onEnterPressed: {
                    ok.onOkWithValidation();
                }
            }
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
                if (nameField.text.length == 0) {
                    infoDialog.visible = true;
                    infoDialog.requestActivate();
                    return;
                }

                root.onOKAction();
            }
        }

        SettingsButton {
            id: cancel

            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            anchors.right: officePBX.right

            text: qsTrId("dialog_button_cancel") + Translator.translate

            onClicked: {
                root.onCancelAction();
            }
        }
    }

    InfoDialog {
        id: infoDialog

        width: 363
        height: 115

        visible: false
        message: qsTrId("dialog_new_contact_empty_user") + Translator.translate

        onOKAction: function() {
            infoDialog.visible  = false;
        }
    }

    onClosing: {
        close.accepted = false;
        root.onCancelAction();
    }
}
