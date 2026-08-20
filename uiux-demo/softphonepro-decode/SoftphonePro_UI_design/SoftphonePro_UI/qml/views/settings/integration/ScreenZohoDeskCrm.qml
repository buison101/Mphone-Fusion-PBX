import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Dialogs 1.3
import Flux 1.0

import "../../uicontrols"

Flickable {
    id: root
    contentHeight: height
    boundsBehavior: Flickable.StopAtBounds
    readonly property int status: SettingsState.zohoDeskCrmAuthStatus
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
                        + crmLoginField.height + marginValue
                        + crmServerField.height + marginValue
                        + connectButton.height + marginValue / 2
                        + crmDigitsCountSpinbox.height + marginValue + marginValue
                width: parent.width

                title: qsTrId("settings_zohodeskcrm") + Translator.translate;

                Label {
                    id: description

                    anchors.top: parent.top
                    anchors.topMargin: marginValue
                    anchors.left: parent.left
                    anchors.leftMargin: marginValue
                    anchors.right: parent.right
                    anchors.rightMargin: marginValue

                    text: qsTrId("settings_integration_zohodeskcrm_description").arg(StringStorage.appTitle) + Translator.translate

                    wrapMode: Text.WordWrap
                    font.pixelSize: fontSize
                }

                Label {
                    id: crmLoginLabel

                    anchors.left: description.left
                    anchors.verticalCenter: crmLoginField.verticalCenter

                    text: qsTrId("settings_crm_account") + Translator.translate
                    font.pixelSize: fontSize
                }

                SettingsTextField {
                    id: crmLoginField

                    anchors.top: description.bottom
                    anchors.topMargin: marginValue
                    anchors.right: parent.right
                    anchors.rightMargin: marginValue

                    width: 130
                    property string crmLogin: SettingsState.zohoDeskCrmAccount.login

                    text: crmLogin

                    onTextChanged: {
                        if (text != crmLogin) {
                            ActionProvider.markCrmAccountUpdate(CrmType.ZohoDesk, CrmAccount.Login, text);
                        }
                    }

                    onCrmLoginChanged: {
                        text = crmLogin;
                    }
                }

                Label {
                    id: crmServerLabel

                    anchors.left: crmLoginLabel.left
                    anchors.verticalCenter: crmServerField.verticalCenter

                    text: qsTrId("sip_accounts_table_server") + Translator.translate
                    font.pixelSize: 11
                }

                Label {
                    id: crmAccountPrefix

                    anchors.right: crmServerField.left
                    anchors.verticalCenter: crmServerField.verticalCenter

                    text: "zoho."
                    font.pixelSize: fontSize
                }

                SettingsTextField {
                    id: crmServerField

                    anchors.top: crmLoginField.bottom
                    anchors.topMargin: marginValue
                    anchors.right: parent.right
                    anchors.rightMargin: marginValue

                    width: 90

                    property string crmServer: SettingsState.zohoDeskCrmAccount.server

                    text: crmServer

                    onTextChanged: {
                        if (text != crmServer) {
                            ActionProvider.markCrmAccountUpdate(CrmType.ZohoDesk, CrmAccount.Server, text);
                        }
                    }

                    onCrmServerChanged: {
                        text = crmServer;
                    }
                }

                Label {
                    id: stateLabel

                    anchors.top: crmServerField.bottom
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

                    text:qsTrId("settings_account_non_synced") + Translator.translate;

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

                    anchors.verticalCenter: stateDescriptionLabel.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: marginValue

                    enabled: true

                    property bool isOpenUrl: true

                    onClicked: {
                        ActionProvider.tryAuthorizeZohoDeskCrmAccount();
                        if(isOpenUrl) {
                            Qt.openUrlExternally(SettingsState.zohoDeskCrmAuthLink)
                        }
                    }
                }

                Label {
                    id: crmDigitsCountLabel

                    anchors.left: description.left
                    anchors.verticalCenter: crmDigitsCountSpinbox.verticalCenter

                    text: qsTrId("settings_crm_digits_count") + Translator.translate
                    font.pixelSize: fontSize
                }

                SettingsSpinBox {
                    id: crmDigitsCountSpinbox

                    anchors.top: connectButton.bottom
                    anchors.topMargin: marginValue
                    anchors.right: crmServerField.right

                    height: 30
                    width: connectButton.width

                    to: SettingsState.zohoDeskCrmAccount.maxDigitsCount
                    from: SettingsState.crmAccountMinDigitsCount

                    property real digitsCount: SettingsState.zohoDeskCrmAccount.digitsCount

                    value: digitsCount

                    onValueChanged: {
                        if (value != digitsCount) {
                            ActionProvider.markCrmAccountUpdate(CrmType.ZohoDesk, CrmAccount.DigitsCount, value);
                        }
                    }

                    onDigitsCountChanged: {
                        value = digitsCount;
                    }
                }
            }
        }
    }
    onVisibleChanged: statusUpdateHandler()

    function statusUpdateHandler() {
        var connectButtonText, accStatusText
        switch (root.status) {
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
