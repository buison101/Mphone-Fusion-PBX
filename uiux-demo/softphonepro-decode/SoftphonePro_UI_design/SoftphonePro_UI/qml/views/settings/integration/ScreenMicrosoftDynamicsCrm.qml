import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Dialogs 1.3
import Flux 1.0

import "../../uicontrols"

Flickable {
    id: root

    contentHeight: height
    boundsBehavior: Flickable.StopAtBounds
    readonly property int status: SettingsState.microsoftDynamicsCrmAuthStatus
    property int marginValue: 20
    property int fontSize: 11
    onStatusChanged: statusUpdateHandler()

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

                height: description.height + description.anchors.topMargin + crmServerField.height + crmServerField.anchors.topMargin
                + connectButton.height + marginValue / 2 + crmDigitsCountSpinbox.height + crmDigitsCountSpinbox.anchors.topMargin + marginValue / 2
                width: parent.width

                title: qsTrId("settings_microsoftdynamicscrm") + Translator.translate;

                Label {
                    id: description

                    anchors.top: parent.top
                    anchors.topMargin: marginValue
                    anchors.left: parent.left
                    anchors.leftMargin: marginValue
                    anchors.right: parent.right
                    anchors.rightMargin: marginValue

                    text: qsTrId("settings_integration_microsoftdynamicscrm_description").arg(StringStorage.appTitle) + Translator.translate

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

                    anchors.top: description.bottom
                    anchors.topMargin: marginValue
                    anchors.right: crmServerPostfix.left

                    width: 180
                    property string crmServer: SettingsState.microsoftDynamicsCrmAccount.server

                    text: crmLogin

                    onTextChanged: {
                        if (text != crmServer) {
                            ActionProvider.markCrmAccountUpdate(CrmType.MicrosoftDynamics, CrmAccount.Server, text);
                        }
                    }

                    onCrmServerChanged: {
                        text = crmServer;
                    }
                }

                Label {
                    id: crmServerPostfix

                    anchors.verticalCenter: crmServerField.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: marginValue

                    text: "/api/data/"
                    font.pixelSize: fontSize
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
                        ActionProvider.sendMicrosoftDynamicsData();
                        ActionProvider.tryAuthorizeMicrosoftDynamicsCrmAccount();
                    }

                    font.pixelSize: fontSize
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
                    anchors.topMargin: marginValue / 2
                    anchors.right: parent.right
                    anchors.rightMargin: marginValue

                    width: connectButton.width

                    to: SettingsState.microsoftDynamicsCrmAccount.maxDigitsCount
                    from: SettingsState.crmAccountMinDigitsCount

                    property real digitsCount: SettingsState.microsoftDynamicsCrmAccount.digitsCount

                    value: digitsCount

                    onValueChanged: {
                        if (value != digitsCount) {
                            ActionProvider.markCrmAccountUpdate(CrmType.MicrosoftDynamics, CrmAccount.DigitsCount, value);
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
