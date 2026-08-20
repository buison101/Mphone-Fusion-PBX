import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Dialogs 1.3
import Flux 1.0

import "../../uicontrols"

Flickable {
    id: root

    contentHeight: height
    boundsBehavior: Flickable.StopAtBounds
    readonly property int status: SettingsState.freshdeskCrmAuthStatus
    property int marginsValue: 20
    property int fontSize: 11
    onStatusChanged: statusUpdateHandler()

    clip: true

    Rectangle {
        anchors.fill: parent

        color: ColorStorage.settingsWindowBaseColor

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: marginsValue
            anchors.leftMargin: marginsValue
            anchors.rightMargin: marginsValue

            color: ColorStorage.settingsWindowBaseColor

            SettingsGroupBox {
                id: bookPropertiesGroupbox

                anchors.top: parent.top
                anchors.left: parent.left

                height: description.height + description.anchors.topMargin + connectButton.height + marginsValue / 2
                        + crmServerField.height + crmServerField.anchors.topMargin
                        + crmAuthKeyLField.height + crmAuthKeyLField.anchors.topMargin
                width: parent.width

                title: qsTrId("settings_freshdeskcrm") + Translator.translate

                Label {
                    id: description

                    anchors.top: parent.top
                    anchors.topMargin: marginsValue
                    anchors.left: parent.left
                    anchors.leftMargin: marginsValue
                    anchors.right: parent.right
                    anchors.rightMargin: marginsValue

                    text: qsTrId("settings_integration_freshdeskcrm_description").arg(StringStorage.appTitle) + Translator.translate

                    wrapMode: Text.WordWrap
                    font.pixelSize: fontSize
                }

                Label {
                    id: crmServerLabel

                    anchors.left: description.left
                    anchors.verticalCenter: crmServerField.verticalCenter

                    text: qsTrId("settings_crm_account") + Translator.translate
                    font.pixelSize: fontSize
                }

                Label {
                    id: crmServerPrefix

                    anchors.right: crmServerField.left
                    anchors.verticalCenter: crmServerField.verticalCenter

                    text: "https://"
                    font.pixelSize: fontSize
                }

                SettingsTextField {
                    id: crmServerField

                    anchors.top: stateLabel.bottom
                    anchors.topMargin: marginsValue
                    anchors.right: crmUrlLabel.left
                    anchors.left: crmAuthKeyLField.left

                    width: 100
                    property string crmServer: SettingsState.freshdeskCrmAccount.server

                    text: crmServer
                    font.pixelSize: fontSize

                    onTextChanged: {
                        if (text != crmServer) {
                            ActionProvider.markCrmAccountUpdate(CrmType.Freshdesk, CrmAccount.Server, text);
                        }
                    }

                    onCrmServerChanged: {
                        text = crmServer;
                    }
                }

                Label {
                    id: crmUrlLabel

                    anchors.verticalCenter: crmServerField.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: marginsValue

                    text: ".freshdesk.com"
                    font.pixelSize: fontSize
                }

                Label {
                    id: crmAuthKeyLabel

                    anchors.left: description.left
                    anchors.verticalCenter: crmAuthKeyLField.verticalCenter

                    text: qsTrId("settings_crm1c_auth_key") + Translator.translate
                    font.pixelSize: fontSize
                }

                SettingsTextField {
                    id: crmAuthKeyLField

                    anchors.top: crmServerField.bottom
                    anchors.topMargin: marginsValue
                    anchors.right: parent.right
                    anchors.rightMargin: marginsValue

                    width: 180
                    property string crmAuthKey: SettingsState.freshdeskCrmAccount.password

                    text: crmAuthKey
                    font.pixelSize: fontSize

                    onTextChanged: {
                        if (text != crmAuthKey) {
                            ActionProvider.markCrmAccountUpdate(CrmType.Freshdesk, CrmAccount.Password, text);
                        }
                    }

                    onCrmAuthKeyChanged: {
                        text = crmAuthKey;
                    }
                }

                Label {
                    id: stateLabel

                    anchors.top: description.bottom
                    anchors.topMargin: marginsValue
                    anchors.left: parent.left
                    anchors.leftMargin: marginsValue

                    font.pixelSize: fontSize
                    text: qsTrId("settings_account_state") + Translator.translate
                }

                Label {
                    id: stateDescriptionLabel

                    anchors.verticalCenter: stateLabel.verticalCenter
                    anchors.right: connectButton.left
                    anchors.rightMargin: marginsValue

                    width: 170

                    horizontalAlignment: Text.AlignRight

                    text:qsTrId("settings_account_non_synced") + Translator.translate;

                    font.pixelSize: fontSize
                }

                Item {
                    id: accountStatusBusyIndicator
                    width: connectButton.height
                    height: connectButton.height
                    anchors.rightMargin: marginsValue
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
                    anchors.rightMargin: marginsValue

                    enabled: true

                    onClicked: {
                        ActionProvider.tryAuthorizeFreshdeskCrmAccount();
                        connectButton.enabled = false;
                    }

                    font.pixelSize: fontSize
                }
            }
        }
    }
    onVisibleChanged: statusUpdateHandler()

    function statusUpdateHandler() {
        var connectButtonText, accStatusText
        switch (root.status) {
        case OAuth2State.AwaitUserAuthorization:
            connectButtonText = qsTrId("settings_connect_button") + Translator.translate
            accountStatusBusyIndicator.visible = true;
            stateDescriptionLabel.visible = false;
            crmAuthKeyLField.enabled = false;
            crmServerField.enabled = false;
            break;

        case OAuth2State.Authorized:
            accStatusText = qsTrId("settings_account_synced")
            connectButtonText = qsTrId("settings_disconnect_button")
            accountStatusBusyIndicator.visible = false;
            stateDescriptionLabel.visible = true;
            connectButton.enabled = true
            crmAuthKeyLField.enabled = false;
            crmServerField.enabled = false;
            break;

        default:
            accStatusText = qsTrId("settings_account_non_synced")
            connectButtonText = qsTrId("settings_connect_button")
            accountStatusBusyIndicator.visible = false;
            stateDescriptionLabel.visible = true;
            connectButton.enabled = true;
            crmAuthKeyLField.enabled = true;
            crmServerField.enabled = true;
            break;
        }

        stateDescriptionLabel.text = accStatusText + Translator.translate
        connectButton.text = connectButtonText + Translator.translate
    }
}
