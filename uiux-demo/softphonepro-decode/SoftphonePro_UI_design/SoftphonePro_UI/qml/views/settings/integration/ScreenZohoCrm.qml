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
    readonly property int status: SettingsState.zohoCrmAuthStatus
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
                        + connectButton.height + marginValue / 2
                        + crmDigitsCountSpinbox.height + marginValue + marginValue
                width: parent.width

                title: qsTrId("settings_zohocrm") + Translator.translate

                Label {
                    id: description

                    anchors.top: parent.top
                    anchors.topMargin: marginValue
                    anchors.left: parent.left
                    anchors.leftMargin: marginValue
                    anchors.right: parent.right
                    anchors.rightMargin: marginValue

                    text: qsTrId("settings_integration_zohocrm_description").arg(StringStorage.appTitle) + Translator.translate

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

                    text: "zoho."
                    font.pixelSize: fontSize
                }

                SettingsTextField {
                    id: crmServerField

                    anchors.top: description.bottom
                    anchors.topMargin: marginValue
                    anchors.right: parent.right
                    anchors.rightMargin: marginValue

                    width: 90

                    enabled: SettingsState.zohoCrmAccount.password == ""

                    property string crmDomain: SettingsState.zohoCrmAccount.server

                    text: crmDomain

                    onTextChanged: {
                        if (text != crmDomain) {
                            ActionProvider.markCrmAccountUpdate(CrmType.ZohoCrm, CrmAccount.Server, text);
                        }
                    }

                    onCrmDomainChanged: {
                        text = crmDomain;
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

                    text: {
                        if (SettingsState.zohoCrmAccount.password != "") {
                            return qsTrId("settings_account_synced") + Translator.translate;
                        }

                        return qsTrId("settings_account_non_synced") + Translator.translate;
                    }

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

                    text: {
                        if (SettingsState.zohoCrmAccount.password != "") {
                            return qsTrId("settings_disconnect_button") + Translator.translate;
                        }

                        return qsTrId("settings_connect_button") + Translator.translate;
                    }

                    onClicked: {
                        ActionProvider.tryAuthorizeZohoCrmAccount();
                        if(isOpenUrl) {
                            Qt.openUrlExternally(SettingsState.zohoCrmAuthLink)
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
                    anchors.right: connectButton.right

                    height: 30
                    width: connectButton.width

                    to: SettingsState.zohoCrmAccount.maxDigitsCount
                    from: SettingsState.crmAccountMinDigitsCount

                    property real digitsCount: SettingsState.zohoCrmAccount.digitsCount

                    value: digitsCount

                    onValueChanged: {
                        if (value != digitsCount) {
                            ActionProvider.markCrmAccountUpdate(CrmType.ZohoCrm, CrmAccount.DigitsCount, value);
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
