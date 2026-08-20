import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Dialogs 1.3
import Flux 1.0

import "../../dialogs"
import "../../uicontrols"

Flickable {
    id: flickable

    contentHeight: height
    boundsBehavior: Flickable.StopAtBounds
    readonly property int status: SettingsState.suiteCrmAuthStatus
    onStatusChanged: statusUpdateHandler()

    property int fontSize: 11
    property int marginValue: 20

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
                        + crmServerField.height + marginValue
                        + connectButton.height + marginValue
                        + loginField.height + marginValue
                        + passwordField.height + marginValue
                        + clientIdField.height + marginValue
                        + clientSecretField.height + marginValue / 2
                width: parent.width

                title: qsTrId("settings_suitecrm") + Translator.translate

                Label {
                    id: description

                    anchors.top: parent.top
                    anchors.topMargin: marginValue
                    anchors.left: parent.left
                    anchors.leftMargin: marginValue
                    anchors.right: parent.right
                    anchors.rightMargin: marginValue

                    text: qsTrId("settings_integration_suitecrm_description").arg(StringStorage.appTitle) + Translator.translate

                    wrapMode: Text.WordWrap
                    font.pixelSize: fontSize
                }

                Label {
                    id: crmServerLabel

                    anchors.left: description.left
                    anchors.verticalCenter: crmServerField.verticalCenter

                    text: qsTrId("sip_accounts_table_server") + Translator.translate
                    font.pixelSize: fontSize
                }

                Label {
                    id: crmAccountPrefix

                    anchors.right: crmServerField.left
                    anchors.verticalCenter: crmServerField.verticalCenter

                    font.pixelSize: fontSize
                }

                SettingsTextField {
                    id: crmServerField

                    anchors.top: description.bottom
                    anchors.topMargin: marginValue
                    anchors.right: parent.right
                    anchors.rightMargin: marginValue

                    width: connectButton.width * 2

                    property string crmDomain: SettingsState.suiteCrmAccount.server

                    text: crmDomain

                    onTextChanged: {
                        if (text != crmDomain) {
                            ActionProvider.markCrmAccountUpdate(CrmType.SuiteCrm, CrmAccount.Server, text);
                        }
                    }

                    onCrmDomainChanged: {
                        text = crmDomain;
                    }
                }

                Label {
                    id: clientIdLabel

                    anchors.verticalCenter: clientIdField.verticalCenter
                    anchors.left: crmServerLabel.left

                    font.pixelSize: fontSize
                    text: qsTrId("settings_client_id") + Translator.translate
                }

                SettingsTextField {
                    id: clientIdField

                    anchors.top: crmServerField.bottom
                    anchors.topMargin: marginValue / 2
                    anchors.right: parent.right
                    anchors.rightMargin: marginValue

                    width: crmServerField.width

                    property string crmClientId: SettingsState.suiteCrmAccount.clientId

                    text: crmClientId

                    onTextChanged: {
                        if (crmClientId != text) {
                            ActionProvider.markCrmAccountUpdate(CrmType.SuiteCrm, CrmAccount.ClientId, text);
                        }
                    }

                    onCrmClientIdChanged: {
                        text = crmClientId
                    }
                }

                Label {
                    id: clientSecretLabel

                    anchors.verticalCenter: clientSecretField.verticalCenter
                    anchors.left: clientIdLabel.left

                    font.pixelSize: fontSize
                    text: qsTrId("settings_client_secret") + Translator.translate
                }

                SettingsTextField {
                    id: clientSecretField

                    anchors.top: clientIdField.bottom
                    anchors.topMargin: marginValue / 2
                    anchors.right: parent.right
                    anchors.rightMargin: marginValue

                    width: clientIdField.width

                    echoMode: "Password"

                    property string crmClientSecret: SettingsState.suiteCrmAccount.clientSecret

                    text: crmClientSecret

                    onTextChanged: {
                        if (crmClientSecret != text) {
                            ActionProvider.markCrmAccountUpdate(CrmType.SuiteCrm, CrmAccount.ClientSecret, text);
                        }
                    }

                    onCrmClientSecretChanged: {
                        text = crmClientSecret
                    }
                }

                Label {
                    id: loginLabel

                    anchors.verticalCenter: loginField.verticalCenter
                    anchors.left: clientIdLabel.left

                    font.pixelSize: fontSize
                    text: qsTrId("settings_sip_account_login") + Translator.translate
                }

                SettingsTextField {
                    id: loginField

                    anchors.top: clientSecretField.bottom
                    anchors.topMargin: marginValue / 2
                    anchors.right: parent.right
                    anchors.rightMargin: marginValue

                    width: connectButton.width

                    property string crmLogin: SettingsState.suiteCrmAccount.login

                    text: crmLogin

                    onTextChanged: {
                        if (crmLogin != text) {
                            ActionProvider.markCrmAccountUpdate(CrmType.SuiteCrm, CrmAccount.Login, text);
                        }
                    }

                    onCrmLoginChanged: {
                        text = crmLogin
                    }
                }

                Label {
                    id: passwordLabel

                    anchors.verticalCenter: passwordField.verticalCenter
                    anchors.left: loginLabel.left

                    font.pixelSize: fontSize
                    text: qsTrId("settings_sip_account_password") + Translator.translate
                }

                SettingsTextField {
                    id: passwordField

                    anchors.top: loginField.bottom
                    anchors.topMargin: marginValue / 2
                    anchors.right: parent.right
                    anchors.rightMargin: marginValue

                    echoMode: "Password"

                    width: loginField.width

                    property string crmPassword: SettingsState.suiteCrmAccount.password

                    text: crmPassword

                    onTextChanged: {
                        if (crmPassword != text) {
                            ActionProvider.markCrmAccountUpdate(CrmType.SuiteCrm, CrmAccount.Password, text);
                        }
                    }

                    onCrmPasswordChanged: {
                        text = crmPassword
                    }
                }

                Label {
                    id: stateLabel

                    anchors.top: passwordField.bottom
                    anchors.topMargin: marginValue
                    anchors.left: parent.left
                    anchors.leftMargin: marginValue

                    font.pixelSize: fontSize
                    text: qsTrId("settings_account_state") + Translator.translate
                }

                Label {
                    id: stateDescriptionLabel

                    anchors.verticalCenter: stateLabel.verticalCenter
                    anchors.right: connectButton.left
                    anchors.rightMargin: marginValue

                    width: 170

                    horizontalAlignment: Text.AlignRight

                    text: qsTrId("settings_account_non_synced") + Translator.translate;

                    font.pixelSize: fontSize
                }

                Item {
                    id: accountStatusBusyIndicator
                    width: connectButton.height
                    height: connectButton.height
                    anchors.rightMargin: marginValue
                    anchors.right: connectButton.left
                    anchors.top: connectButton.top
                    visible: false

                    BusyIndicator {
                        width: height
                        height: parent.height
                        anchors {
                            verticalCenter: parent.verticalCenter
                            right: parent.right
                        }
                    }
                }

                SettingsButton {
                    id: connectButton

                    property bool isOpenUrl: true
                    anchors.verticalCenter: stateDescriptionLabel.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: marginValue

                    enabled: true

                    text: qsTrId("settings_connect_button") + Translator.translate;

                    onClicked: {
                        ActionProvider.tryAuthorizeSuiteCrmAccount();
                    }
                }


            }
        }
    }
    onVisibleChanged: statusUpdateHandler()

    function statusUpdateHandler() {
        var connectButtonText, accStatusText
        switch (flickable.status) {
        case OAuth2State.AwaitUserAuthorization:
            connectButtonText = qsTrId("dialog_button_cancel") + Translator.translate
            accountStatusBusyIndicator.visible = true;
            stateDescriptionLabel.visible = false;
            connectButton.isOpenUrl = false;
            break;

        case OAuth2State.Authorized:
            accStatusText = qsTrId("settings_account_synced")
            connectButtonText = qsTrId("settings_disconnect_button")
            accountStatusBusyIndicator.visible = false;
            stateDescriptionLabel.visible = true;
            connectButton.isOpenUrl = false;
            break;

        default:
            accStatusText = qsTrId("settings_account_non_synced")
            connectButtonText = qsTrId("settings_connect_button")
            accountStatusBusyIndicator.visible = false;
            stateDescriptionLabel.visible = true;
            connectButton.isOpenUrl = true;
            break;
        }

        stateDescriptionLabel.text = accStatusText + Translator.translate
        connectButton.text = connectButtonText + Translator.translate
        }
}

