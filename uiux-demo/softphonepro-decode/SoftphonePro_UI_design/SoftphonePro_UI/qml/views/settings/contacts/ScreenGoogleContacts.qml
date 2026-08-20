import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Dialogs 1.3
import Flux 1.0

import "../../dialogs"
import "../../uicontrols"

ScrollView {
    id: root

    property int fontSize: 11
    property int marginValue: 20

    Flickable {
        id: flickable

        ScrollBar.vertical: ScrollBar {}

        contentHeight: height
        boundsBehavior: Flickable.StopAtBounds

        clip: true

        Rectangle {
            anchors.fill: parent

            color: ColorStorage.settingsWindowBaseColor

            Rectangle {
                anchors.fill: parent
                anchors.topMargin: marginValue
                anchors.leftMargin: marginValue
                anchors.rightMargin: marginValue

                color: ColorStorage.settingsWindowBaseColor

                SettingsGroupBox {
                    id: bookPropertiesGroupbox

                    anchors.top: parent.top
                    anchors.left: parent.left

                    height: description.height + marginValue
                            + bookSourceNameField.height + marginValue
                            + bookConnectButton.height + marginValue
                            + bookUpdateTimeoutSpinbox.height + marginValue
                            + officePBX.height
                    width: parent.width

                    title: qsTrId("settings_contacts_google_contacts") + Translator.translate

                    Label {
                        id: description

                        anchors.top: parent.top
                        anchors.topMargin: marginValue
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue
                        anchors.right: parent.right
                        anchors.rightMargin: marginValue

                        text: qsTrId("settings_contacts_google_contacts_description").arg(StringStorage.appTitle).arg(StringStorage.getHelpImportGoogleContactsURL(SettingsState.languageIsoCode)) + Translator.translate

                        wrapMode: Text.WordWrap
                        font.pixelSize: fontSize

                        onLinkActivated: Qt.openUrlExternally(link)
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.NoButton
                            cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                        }
                    }

                    Label {
                        id: bookNameLabel

                        anchors.top: description.bottom
                        anchors.topMargin: marginValue
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue

                        font.pixelSize: fontSize
                        text: qsTrId("settings_contacts_google_contacts_book_name") + Translator.translate
                    }

                    SettingsTextField {
                        id: bookSourceNameField

                        anchors.verticalCenter: bookNameLabel.verticalCenter
                        anchors.left: bookNameLabel.right
                        anchors.leftMargin: 150
                        anchors.right: bookConnectButton.right

                        width: 170

                        property string name: SettingsState.googleContactsContactAccount ? SettingsState.googleContactsContactAccount.name : ""

                        text: name

                        onTextChanged: {
                            if (text != name) {
                                ActionProvider.markContactAccountUpdate(ContactType.GoogleContacts, ContactAccount.Name, text);
                            }
                        }

                        onNameChanged: {
                            text = name;
                        }
                    }

                    Label {
                        id: bookStateLabel

                        anchors.top: bookNameLabel.bottom
                        anchors.topMargin: marginValue
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue

                        font.pixelSize: fontSize
                        text: qsTrId("settings_contacts_google_contacts_book_state") + Translator.translate
                    }

                    Label {
                        id: bookState

                        anchors.verticalCenter: bookStateLabel.verticalCenter
                        anchors.right: bookConnectButton.left
                        anchors.rightMargin: marginValue
                        anchors.left: bookSourceNameField.left

                        width: 170

                        text: {
                            if (SettingsState.googleContactsAuthStatus == OAuth2State.Authorized) {
                                return qsTrId("settings_contacts_google_contacts_book_synced") + Translator.translate;
                            }

                            return qsTrId("settings_contacts_google_contacts_book_non_synced") + Translator.translate;
                        }

                        font.pixelSize: fontSize
                    }

                    SettingsButton {
                        id: bookConnectButton

                        anchors.verticalCenter: bookState.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: marginValue

                        text: {
                            if (SettingsState.googleContactsAuthStatus == OAuth2State.Authorized) {
                                return qsTrId("settings_disconnect_button") + Translator.translate;
                            }

                            return qsTrId("settings_connect_button") + Translator.translate;
                        }

                        onClicked: {
                            var authorize = SettingsState.googleContactsAuthStatus == OAuth2State.Authorized ? false : true;
                            ActionProvider.tryAuthorizeGoogleContactsAccount(authorize);
                        }
                    }

                    Label {
                        id: bookUpdateTimeoutLabel

                        anchors.top: bookStateLabel.bottom
                        anchors.topMargin: marginValue
                        anchors.left: bookStateLabel.left

                        text: qsTrId("settings_contacts_xml_reload_timeout") + Translator.translate
                        font.pixelSize: fontSize
                    }

                    SettingsSpinBox {
                        id: bookUpdateTimeoutSpinbox

                        anchors.verticalCenter: bookUpdateTimeoutLabel.verticalCenter
                        anchors.left: bookState.left

                        height: 30

                        from: 0
                        to: 100000

                        property int updateTimeout: SettingsState.googleContactsContactAccount ?
                                                         SettingsState.googleContactsContactAccount.updateTimeoutMinutes : 0

                        value: updateTimeout

                        onValueChanged: {
                            if (value != updateTimeout) {
                                ActionProvider.markContactAccountUpdate(ContactType.GoogleContacts, ContactAccount.UpdateTimeout, value);
                            }
                        }

                        onUpdateTimeoutChanged: {
                            value = updateTimeout;
                        }
                    }

                    SettingsGroupBox {
                        id: officePBX

                        anchors.top: bookUpdateTimeoutLabel.bottom
                        anchors.topMargin: marginValue
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue
                        anchors.right: parent.right
                        anchors.rightMargin: marginValue

                        height: callForwardUseCheckbox.height + marginValue
                                + callForwardUseDescLabel.height + marginValue / 2
                                + getContactInfoCheckbox.height + marginValue
                                + getContactInfoDescLabel.height + marginValue / 2
                                + accountCombobox.height + marginValue / 2
                                + marginValue
                        width: parent.width

                        title: qsTrId("settings_contacts_xml_advanced") + Translator.translate


                        SettingsCheckBox {
                            id: callForwardUseCheckbox

                            anchors.top: parent.top
                            anchors.topMargin: marginValue
                            anchors.left: parent.left
                            anchors.leftMargin: marginValue

                            property bool useForCallTransfer: SettingsState.googleContactsContactAccount ?
                                                                  SettingsState.googleContactsContactAccount.useForCallTransfer : false

                            checked: useForCallTransfer

                            onCheckedChanged: {
                                if (checked != useForCallTransfer) {
                                    ActionProvider.markContactAccountUpdate(ContactType.GoogleContacts, ContactAccount.UseForTransfer, checked);
                                }
                            }

                            onUseForCallTransferChanged: {
                                checked = useForCallTransfer;
                            }
                        }

                        Label {
                            id: callForwardUseLabel

                            anchors.left: callForwardUseCheckbox.right
                            anchors.leftMargin: marginValue
                            anchors.verticalCenter: callForwardUseCheckbox.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: marginValue

                            font.pixelSize: fontSize

                            text: qsTrId("dialog_new_contact_call_forward_use") + Translator.translate
                        }

                        Label {
                            id: callForwardUseDescLabel

                            anchors.top: callForwardUseLabel.bottom
                            anchors.topMargin: marginValue / 2
                            anchors.left: callForwardUseLabel.left
                            anchors.right: parent.right
                            anchors.rightMargin: marginValue

                            wrapMode: Text.WordWrap

                            font.pixelSize: fontSize

                            text: qsTrId("dialog_new_contact_call_forward_use_desc") + Translator.translate
                        }

                        SettingsCheckBox {
                            id: getContactInfoCheckbox

                            anchors.top: callForwardUseDescLabel.bottom
                            anchors.topMargin: marginValue
                            anchors.left: parent.left
                            anchors.leftMargin: marginValue

                            property bool subscribeForEvents: SettingsState.googleContactsContactAccount ?
                                                                  SettingsState.googleContactsContactAccount.subscribeForEvents : false

                            checked: subscribeForEvents

                            onCheckedChanged: {
                                if (checked != subscribeForEvents) {
                                    ActionProvider.markContactAccountUpdate(ContactType.GoogleContacts, ContactAccount.UseForPresense, checked);
                                }
                            }

                            onSubscribeForEventsChanged: {
                                checked = subscribeForEvents;
                            }
                        }

                        Label {
                            id: getContactInfoLabel

                            anchors.left: getContactInfoCheckbox.right
                            anchors.leftMargin: marginValue
                            anchors.verticalCenter: getContactInfoCheckbox.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: marginValue

                            font.pixelSize: fontSize

                            text: qsTrId("dialog_new_contact_get_contact_info") + Translator.translate
                        }

                        Label {
                            id: getContactInfoDescLabel

                            anchors.top: getContactInfoLabel.bottom
                            anchors.topMargin: marginValue / 2
                            anchors.left: getContactInfoLabel.left
                            anchors.right: parent.right
                            anchors.rightMargin: marginValue

                            wrapMode: Text.WordWrap
                            font.pixelSize: fontSize

                            text: qsTrId("dialog_new_contact_get_contact_info_desc") + Translator.translate
                        }

                        Label {
                            id: accountLabel

                            anchors.top: getContactInfoDescLabel.bottom
                            anchors.topMargin: marginValue
                            anchors.left: getContactInfoDescLabel.left

                            enabled: getContactInfoCheckbox.checked
                            font.pixelSize: fontSize

                            text: qsTrId("dialog_new_contact_account") + Translator.translate
                        }

                        Label {
                            id: accountLabelAsterisk

                            anchors.left: accountLabel.right
                            anchors.leftMargin: 1
                            anchors.baseline: accountLabel.baseline

                            enabled: getContactInfoCheckbox.checked
                            font.pixelSize: fontSize

                            text: "*"
                            color: "red"
                        }

                        SettingsComboBox {
                            id: accountCombobox

                            anchors.left: accountLabelAsterisk.right
                            anchors.leftMargin: marginValue
                            anchors.verticalCenter: accountLabel.verticalCenter

                            width: 120

                            enabled: getContactInfoCheckbox.checked

                            textRole: "name"
                            model: AppState.sipAccountModel

                            property int accountId: SettingsState.googleContactsContactAccount ?
                                                        SettingsState.googleContactsContactAccount.sipAccountId : 0

                            font.pixelSize: 11

                            onCurrentIndexChanged: {
                                if (currentIndex != accountId) {
                                    ActionProvider.markContactAccountUpdate(ContactType.GoogleContacts, ContactAccount.PresenceSipAccount, currentIndex);
                                }
                            }

                            onAccountIdChanged: {
                                currentIndex = accountId;
                            }
                        }
                    }
                }
            }

            OAuth2Dialog {
                id: googleContactsAuthDialog

                width: 360
                height: 200

                title: qsTrId("auth_dialog_title") + Translator.translate

                visible: SettingsState.showGoogleContactsAuthDialog
                showBusyIndicator: SettingsState.googleContactsAuthStatus == OAuth2State.AwaitUserCode

                // qml not update codeTextField.text: SettingsState.googleContactsUserCode after reload Google contacts
                property string googleContactsUserCode: SettingsState.googleContactsUserCode

                codeTextField.enabled: codeTextField.text != 0
                codeTextField.readOnly: true
                codeTextField.visible: SettingsState.googleContactsAuthStatus != OAuth2State.AwaitUserCode

                enableOkButton:  SettingsState.googleContactsAuthStatus == OAuth2State.Authorized ? true : false

                property int status: SettingsState.googleContactsAuthStatus
                onStatusChanged: {
                    var statusExtended = "";
                    var statusDescription = "";

                    switch (status) {
                    case OAuth2State.AwaitUserCode:
                        statusExtended = qsTrId("oauth2_description_await_user_code") + Translator.translate;
                        statusDescription = qsTrId("oauth2_status_await_user_code") + Translator.translate;
                        break;

                    case OAuth2State.FailedUserCode:
                        statusExtended = qsTrId("oauth2_description_failed_user_code") + Translator.translate;
                        statusDescription = qsTrId("oauth2_status_failed_user_code") + Translator.translate;
                        break;

                    case OAuth2State.AwaitUserAuthorization:
                        statusExtended = qsTrId("oauth2_google_contacts_auth_description").arg(SettingsState.googleContactsAuthLink) + Translator.translate;
                        statusDescription = qsTrId("oauth2_status_await_user_auth") + Translator.translate;
                        break;

                    case OAuth2State.Authorized:
                        statusExtended = qsTrId("oauth2_description_authorized") + Translator.translate;
                        statusDescription = qsTrId("oauth2_status_authorized") + Translator.translate;
                        break;

                    case OAuth2State.NonAuthorized:
                    case OAuth2State.FailedAuthorization:
                        statusExtended = qsTrId("oauth2_description_non_authorized") + Translator.translate;
                        statusDescription = qsTrId("oauth2_status_non_authorized") + Translator.translate;
                        break;
                    }

                    descriptionText = statusExtended;
                    statusText = statusDescription;
                }

                authLink: SettingsState.googleContactsAuthLink

                onAuthLinkChanged: {
                    if (status == OAuth2State.AwaitUserAuthorization) {
                        descriptionText = qsTrId("oauth2_google_contacts_auth_description").arg(SettingsState.googleContactsAuthLink) + Translator.translate;
                    }
                }

                onGoogleContactsUserCodeChanged: {
                    codeTextField.text = SettingsState.googleContactsUserCode
                }

                onOKAction: function func() {
                    ActionProvider.confirmAuthorizationGoogleContactsAccount(true);
                }

                onCancelAction: function func() {
                    ActionProvider.confirmAuthorizationGoogleContactsAccount(false);
                }
            }
        }
    }
}
