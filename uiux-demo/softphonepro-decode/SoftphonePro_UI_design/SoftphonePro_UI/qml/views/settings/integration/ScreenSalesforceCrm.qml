import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Dialogs 1.3
import Flux 1.0

import "../../uicontrols"

Flickable {
    id: root

    contentHeight: height
    boundsBehavior: Flickable.StopAtBounds
    readonly property int status: SettingsState.salesforceCrmAuthStatus
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

                height: description.height + description.anchors.topMargin + crmServerField.height + marginsValue + connectButton.height + marginsValue
                width: parent.width

                title: qsTrId("settings_salesforcecrm") + Translator.translate;

                Label {
                    id: description

                    anchors.top: parent.top
                    anchors.topMargin: marginsValue
                    anchors.left: parent.left
                    anchors.leftMargin: marginsValue
                    anchors.right: parent.right
                    anchors.rightMargin: marginsValue

                    text: qsTrId("settings_integration_salesforcecrm_description").arg(StringStorage.appTitle) + Translator.translate

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
                    id: crmAccountPrefix

                    anchors.right: crmServerField.left
                    anchors.verticalCenter: crmServerField.verticalCenter

                    text: "https://"
                    font.pixelSize: fontSize
                }

                Label {
                    id: crmServer

                    anchors.right: parent.right
                    anchors.rightMargin: marginsValue
                    anchors.verticalCenter: crmServerField.verticalCenter

                    text: ".my.salesforce.com"
                    font.pixelSize: fontSize
                }

                SettingsTextField {
                    id: crmServerField

                    anchors.top: description.bottom
                    anchors.topMargin: marginsValue
                    anchors.right: crmServer.left

                    width: 90
                    property string crmServer: SettingsState.salesforceCrmAccount.server

                    text: crmServer

                    onTextChanged: {
                        if (text != crmServer) {
                            ActionProvider.markCrmAccountUpdate(CrmType.Salesforce, CrmAccount.Server, text);
                        }
                    }

                    onCrmServerChanged: {
                        text = crmServer;
                    }
                }

                Label {
                    id: stateLabel

                    anchors.top: crmServerField.bottom
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

                    property bool isOpenUrl: true

                    onClicked: {
                        ActionProvider.tryAuthorizeSalesforceCrmAccount();
                        if(isOpenUrl) {
                            Qt.openUrlExternally(SettingsState.salesforceCrmAuthLink)
                        }
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
