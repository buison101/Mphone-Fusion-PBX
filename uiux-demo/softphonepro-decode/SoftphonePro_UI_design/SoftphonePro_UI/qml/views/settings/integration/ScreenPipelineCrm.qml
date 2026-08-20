import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Dialogs 1.3
import Flux 1.0

import "../../uicontrols"

Flickable {
    id: root

    contentHeight: height
    boundsBehavior: Flickable.StopAtBounds
    readonly property int status: SettingsState.pipelineCrmAuthStatus
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
                        + crmAuthKeyLField.height + crmAuthKeyLField.anchors.topMargin + appKeyField.height + marginsValue
                        + crmDigitsCountSpinbox.height + marginsValue
                width: parent.width

                title: qsTrId("settings_pipelinecrm") + Translator.translate

                Label {
                    id: description

                    anchors.top: parent.top
                    anchors.topMargin: marginsValue
                    anchors.left: parent.left
                    anchors.leftMargin: marginsValue
                    anchors.right: parent.right
                    anchors.rightMargin: marginsValue

                    text: qsTrId("settings_integration_pipelinecrm_description").arg(StringStorage.appTitle) + Translator.translate

                    wrapMode: Text.WordWrap
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

                    anchors.top: stateLabel.bottom
                    anchors.topMargin: marginsValue
                    anchors.right: parent.right
                    anchors.rightMargin: marginsValue

                    width: 180
                    property string crmAuthKey: SettingsState.pipelineCrmAccount.password

                    text: crmAuthKey
                    font.pixelSize: fontSize

                    onTextChanged: {
                        if (text != crmAuthKey) {
                            ActionProvider.markCrmAccountUpdate(CrmType.PipelineCrm, CrmAccount.Password, text);
                        }
                    }

                    onCrmAuthKeyChanged: {
                        text = crmAuthKey;
                    }
                }

                Label {
                    id: appKeyLabel

                    anchors.verticalCenter: appKeyField.verticalCenter
                    anchors.left: crmAuthKeyLabel.left

                    font.pixelSize: fontSize
                    text: qsTrId("settings_sip_account_app_key") + Translator.translate
                }

                SettingsTextField {
                    id: appKeyField

                    anchors.top: crmAuthKeyLField.bottom
                    anchors.topMargin: marginsValue
                    anchors.right: parent.right
                    anchors.rightMargin: marginsValue

                    width: 180

                    property string crmAppKey: SettingsState.pipelineCrmAccount.appKey

                    text: crmAppKey

                    onTextChanged: {
                        if (crmAppKey != text) {
                            ActionProvider.markCrmAccountUpdate(CrmType.PipelineCrm, CrmAccount.AppKey, text);
                        }
                    }

                    onCrmAppKeyChanged: {
                        text = crmAppKey
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
                        ActionProvider.tryAuthorizePipelineCrmAccount();
                        connectButton.enabled = false;
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

                    anchors.top: appKeyField.bottom
                    anchors.topMargin: marginsValue
                    anchors.right: appKeyField.right

                    height: 30
                    width: connectButton.width

                    to: SettingsState.pipelineCrmAccount.maxDigitsCount
                    from: SettingsState.crmAccountMinDigitsCount

                    property real digitsCount: SettingsState.pipelineCrmAccount.digitsCount

                    value: digitsCount

                    onValueChanged: {
                        if (value != digitsCount) {
                            ActionProvider.markCrmAccountUpdate(CrmType.PipelineCrm, CrmAccount.DigitsCount, value);
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
            connectButtonText = qsTrId("settings_connect_button") + Translator.translate
            accountStatusBusyIndicator.visible = true;
            stateDescriptionLabel.visible = false;
            crmAuthKeyLField.enabled = false;
            appKeyField.enabled = false;
            break;

        case OAuth2State.Authorized:
            accStatusText = qsTrId("settings_account_synced")
            connectButtonText = qsTrId("settings_disconnect_button")
            accountStatusBusyIndicator.visible = false;
            stateDescriptionLabel.visible = true;
            connectButton.enabled = true
            crmAuthKeyLField.enabled = false;
            appKeyField.enabled = false;
            break;

        default:
            accStatusText = qsTrId("settings_account_non_synced")
            connectButtonText = qsTrId("settings_connect_button")
            accountStatusBusyIndicator.visible = false;
            stateDescriptionLabel.visible = true;
            connectButton.enabled = true;
            crmAuthKeyLField.enabled = true;
            appKeyField.enabled = true;
            break;
        }

        stateDescriptionLabel.text = accStatusText + Translator.translate
        connectButton.text = connectButtonText + Translator.translate
    }
}

