import QtQuick 2.15
import QtQuick.Controls 2.15
import Flux 1.0

import "../../uicontrols"

Flickable {
    id: root
    contentHeight: height
    boundsBehavior: Flickable.StopAtBounds
    clip: true

    property int fontSize: 11
    property int marginValue: 20

    readonly property int status: SettingsState.pipedriveCrmAuthStatus
    onStatusChanged: statusUpdateHandler()

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
                height: root.status == OAuth2State.Authorized ? 200 : 300
                width: parent.width
                title: qsTrId("settings_pipedrivecrm") + Translator.translate

                Column {
                    anchors {
                        fill: parent
                        topMargin: marginValue
                        leftMargin: marginValue
                        rightMargin: marginValue
                        bottomMargin: marginValue
                    }
                    spacing: marginValue

                    Label {
                        id: descriptionLabel
                        width: parent.width
                        text: qsTrId("settings_integration_pipedrive_description").arg(StringStorage.appTitle) + Translator.translate
                        wrapMode: Text.WordWrap
                        font.pixelSize: fontSize
                    }

                    Row {
                        width: parent.width
                        spacing: 7

                        Label {
                            id: accountStatusStaticLabel
                            height: parent.height
                            verticalAlignment: Text.AlignVCenter
                            text: qsTrId("settings_account_state") + Translator.translate
                            font.pixelSize: fontSize
                        }

                        Label {
                            id: accountStatusLabel
                            width: parent.width - accountStatusStaticLabel.width - connectButton.width - parent.spacing * 2
                            height: parent.height
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignRight
                            font.pixelSize: fontSize
                        }

                        Item {
                            id: accountStatusBusyIndicator
                            width: parent.width - accountStatusStaticLabel.width - connectButton.width - parent.spacing * 2
                            height: parent.height

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

                            onClicked: {
                                ActionProvider.tryAuthorizePipedriveCrmAccount()
                                if(isOpenUrl) {
                                    Qt.openUrlExternally(SettingsState.pipedriveCrmAuthLink)
                                }
                            }
                        }
                    }

                    Row {
                        width: parent.width

                        Label {
                            width: parent.width - crmDigitsCountSpinBox.width
                            height: parent.height
                            verticalAlignment: Text.AlignVCenter
                            text: qsTrId("settings_crm_digits_count") + Translator.translate
                            font.pixelSize: fontSize
                        }

                        SettingsSpinBox {
                            id: crmDigitsCountSpinBox
                            to: SettingsState.pipedriveCrmAccount.maxDigitsCount
                            from: SettingsState.crmAccountMinDigitsCount
                            value: digitsCount

                            height: 30
                            width: connectButton.width

                            property real digitsCount: SettingsState.pipedriveCrmAccount.digitsCount

                            onValueChanged: {
                                if (value != digitsCount) {
                                    ActionProvider.markCrmAccountUpdate(CrmType.PipedriveCrm, CrmAccount.DigitsCount, value);
                                }
                            }

                            onDigitsCountChanged: {
                                value = digitsCount;
                            }
                        }
                    }

                    Label {
                        width: parent.width
                        text: qsTrId("settings_integration_pipedrive_instruction").arg(qsTrId("settings_connect_button") + Translator.translate)
                        wrapMode: Text.WordWrap
                        font.pixelSize: fontSize
                        visible: root.status != OAuth2State.Authorized
                    }

                    Row {
                        width: parent.width
                        spacing: 7
                        visible: root.status != OAuth2State.Authorized

                        Label {
                            height: 31
                            verticalAlignment: Text.AlignVCenter
                            text: "ID:"
                            font.pixelSize: fontSize + 2
                        }

                        GroupBox {
                            id: idGroupBox

                            height: 31

                            TextEdit {
                                id: idLabel
                                anchors.centerIn: parent
                                readOnly: true
                                text: SettingsState.uniqueId
                                font.pixelSize: fontSize + 3
                            }
                        }

                        SettingsButton {
                            text: qsTrId("dialog_button_copy") + Translator.translate

                            onClicked: {
                                idLabel.selectAll()
                                idLabel.copy()
                                idLabel.deselect()
                            }
                        }
                    }
                }
            }
        }
    }

    onVisibleChanged: statusUpdateHandler()

    function statusUpdateHandler() {
        var accStatusText, connectButtonText

        switch (root.status) {
        case OAuth2State.AwaitUserCode:
        case OAuth2State.AwaitUserAuthorization:
            connectButtonText = qsTrId("dialog_button_cancel") + Translator.translate
            accountStatusBusyIndicator.visible = true;
            accountStatusLabel.visible = false;
            connectButton.isOpenUrl = false;
            break;

        case OAuth2State.Authorized:
            accStatusText = qsTrId("settings_account_synced")
            connectButtonText = qsTrId("settings_disconnect_button")
            accountStatusBusyIndicator.visible = false;
            accountStatusLabel.visible = true;
            connectButton.isOpenUrl = false;
            break;

        default:
            accStatusText = qsTrId("settings_account_non_synced")
            connectButtonText = qsTrId("settings_connect_button")
            accountStatusBusyIndicator.visible = false;
            accountStatusLabel.visible = true;
            connectButton.isOpenUrl = true;
            break;
        }

        accountStatusLabel.text = accStatusText + Translator.translate
        connectButton.text = connectButtonText + Translator.translate
    }
}

