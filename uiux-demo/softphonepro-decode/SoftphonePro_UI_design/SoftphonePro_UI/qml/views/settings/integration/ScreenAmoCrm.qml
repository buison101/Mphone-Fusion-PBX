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
    readonly property int status: SettingsState.amoCrmAuthStatus
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
                        + crmAccountField.height + marginValue
                        + connectButton.height + marginValue / 2
                        + crmDigitsCountSpinbox.height + marginValue + marginValue
                width: parent.width

                title: qsTrId("settings_amocrm") + Translator.translate

                Label {
                    id: description

                    anchors.top: parent.top
                    anchors.topMargin: marginValue
                    anchors.left: parent.left
                    anchors.leftMargin: marginValue
                    anchors.right: parent.right
                    anchors.rightMargin: marginValue

                    text: qsTrId("settings_amocrm_description").arg(StringStorage.appTitle) + Translator.translate

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
                    id: crmAccountLabel

                    anchors.left: description.left
                    anchors.verticalCenter: crmAccountField.verticalCenter

                    text: qsTrId("settings_crm_account") + Translator.translate
                    font.pixelSize: fontSize
                }

                Label {
                    id: crmAccountPrefix

                    anchors.right: crmAccountField.left
                    anchors.verticalCenter: crmAccountField.verticalCenter

                    text: "https://"
                    font.pixelSize: fontSize
                }

                SettingsTextField {
                    id: crmAccountField

                    anchors.top: description.bottom
                    anchors.topMargin: marginValue
                    anchors.right: crmServer.left

                    width: 90

                    property string crmAccount: SettingsState.amoCrmAccount.account

                    text: crmAccount

                    onTextChanged: {
                        if (text != crmAccount) {
                            ActionProvider.markCrmAccountUpdate(CrmType.AmoCRM, CrmAccount.Account, text);
                        }
                    }

                    onCrmAccountChanged: {
                        text = crmAccount;
                    }
                }

                Label {
                    id: crmServer

                    anchors.right: parent.right
                    anchors.rightMargin: marginValue
                    anchors.verticalCenter: crmAccountField.verticalCenter

                    text: ".amocrm.ru"
                    font.pixelSize: fontSize
                }

                Label {
                    id: stateLabel

                    anchors.top: crmAccountField.bottom
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

                    enabled: SettingsState.amoCrmAccount.account != ""

                    text: qsTrId("settings_connect_button") + Translator.translate;

                    onClicked: {
                        ActionProvider.tryAuthorizeAmoCrmAccount();
                        if(isOpenUrl) {
                            Qt.openUrlExternally(SettingsState.amoCrmAuthLink)
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

                    to: SettingsState.amoCrmAccount.maxDigitsCount
                    from: SettingsState.crmAccountMinDigitsCount

                    property real digitsCount: SettingsState.amoCrmAccount.digitsCount

                    value: digitsCount

                    onValueChanged: {
                        if (value != digitsCount) {
                            ActionProvider.markCrmAccountUpdate(CrmType.AmoCRM, CrmAccount.DigitsCount, value);
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
