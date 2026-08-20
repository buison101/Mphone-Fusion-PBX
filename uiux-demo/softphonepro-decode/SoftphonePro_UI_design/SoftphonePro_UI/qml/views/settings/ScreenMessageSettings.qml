import QtQuick 2.15
import QtQuick.Controls 2.15
import Flux 1.0

import "../uicontrols"

ScrollView {
    id: root

    property int fontSize: 11
    property int marginValue: 20

    contentItem: Flickable {
        id: flickable

        contentHeight: 770
        boundsBehavior: Flickable.StopAtBounds

        clip: true

        enabled: !AppState.instanceDisabled

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

                    height: {
                        var heightValue = descriptionLabel.height + marginValue + messagingEnableSettings.height
                            + standartMessageSettings.height + messagingProtocolTypeSettings.height + marginValue
                        if(messagingProtocolTypeSettings.visible) {
                            heightValue += messagingProtocolTypeSettings.height - 5
                        }
                        if(httpapiMessagingSettings.visible) {
                            heightValue += messagingHttpApiUrlField.height + marginValue / 2
                            heightValue += messagingHttpApiSecurityTokenField.height + marginValue / 2
                        }
                        return heightValue + marginValue / 2
                    }
                    width: parent.width

                    title: qsTrId("settings_all_message_settings") + Translator.translate

                    Label {
                        id: descriptionLabel
                        anchors.top: parent.top
                        anchors.topMargin: marginValue
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue
                        anchors.right: parent.right
                        anchors.rightMargin: marginValue

                        text: qsTrId("settings_messaging_description").arg(StringStorage.getHelpMessagingGatewayURL(SettingsState.languageIsoCode)) + Translator.translate

                        onLinkActivated: Qt.openUrlExternally(link)

                        wrapMode: Text.WordWrap
                        textFormat: Text.RichText

                        font.pixelSize: fontSize

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.NoButton
                            cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                        }
                    }

                    Row {
                        id: messagingEnableSettings
                        anchors.top: descriptionLabel.bottom
                        anchors.topMargin: marginValue
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue
                        visible: !AppFeatures.hideMessagingWindow

                        spacing: marginValue

                        SettingsCheckBox {
                            id: messagingEnableCheckBox

                            property bool messagingEnable: SettingsState.messagingEnable

                            checked: messagingEnable

                            onCheckedChanged: {
                                if (checked != messagingEnable) {
                                    ActionProvider.markAppConfigUpdate(AppConfig.MessagingEnabled, checked);
                                }
                            }

                            onMessagingEnableChanged: {
                                checked = messagingEnable;
                            }
                        }

                        Label {
                            anchors.verticalCenter: messagingEnableCheckBox.verticalCenter
                            text: qsTrId("settings_enable_messaging") + Translator.translate
                            font.pixelSize: fontSize
                        }

                    }
                    Column{
                        id:labelsColumn

                        anchors.top: messagingEnableSettings.bottom
                        anchors.topMargin: marginValue
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue
                        anchors.right: parent.right
                        anchors.rightMargin: marginValue
                        visible: !AppFeatures.hideMessagingWindow && messagingEnableCheckBox.checked
                        enabled: visible

                        spacing: 8

                        Row {
                            id: messagingProtocolTypeSettings

                            anchors.left: parent.left
                            anchors.right: parent.right

                            height:  visible ? 30 : 0

                            visible: !AppFeatures.hideMessagingWindow && messagingEnableCheckBox.checked

                            Label {
                                id: messagingProtocolTypeLabel
                                text: qsTrId("settings_messaging_protocol_type") + Translator.translate
                                font.pixelSize: fontSize
                            }

                            SettingsComboBox {
                                id: messagingProtocolTypeComboBox

                                anchors.right: parent.right
                                anchors.verticalCenter: messagingProtocolTypeLabel.verticalCenter

                                visible: !AppFeatures.hideMessagingWindow && messagingEnableCheckBox.checked
                                enabled: visible

                                width: 130

                                model: SettingsState.messagingProtocolModel
                                textRole: "name"

                                property int messagingProtocolModelSelectedIdx: SettingsState.messagingProtocolModelSelectedIdx

                                currentIndex: messagingProtocolModelSelectedIdx

                                onCurrentIndexChanged:  {
                                    if (currentIndex != onCurrentIndexChanged) {
                                        ActionProvider.markAppConfigUpdate(AppConfig.MessagingProtocol, currentIndex);
                                    }
                                }

                                onMessagingProtocolModelSelectedIdxChanged: {
                                    currentIndex = messagingProtocolModelSelectedIdx;
                                }
                            }
                        }

                        Row {
                            id: standartMessageSettings

                            anchors.left: parent.left
                            anchors.right: parent.right

                            height:  visible ? 30 : 0

                            Label {
                                id: messageMaximumLengthLabel
                                text: qsTrId("settings_message_maximum_length") + Translator.translate
                                font.pixelSize: fontSize
                            }

                            SettingsSpinBox {
                                id: messageMaximumLengthSpinBox

                                anchors.right: parent.right
                                anchors.verticalCenter: messageMaximumLengthLabel.verticalCenter

                                visible: !AppFeatures.hideMessagingWindow && messagingEnableCheckBox.checked
                                enabled: visible

                                property real messageMaximumLength: SettingsState.messageMaximumLength

                                height: 30
                                width: 130
                                value: messageMaximumLength

                                from: SettingsState.messageSpinBoxMinimumValue
                                to: SettingsState.messageSpinBoxMaximumValue

                                onValueChanged: {
                                    if (value != messageMaximumLength) {
                                        ActionProvider.markAppConfigUpdate(AppConfig.MessageMaximumLength, value);
                                    }
                                }

                                onMessageMaximumLengthChanged: {
                                    value = messageMaximumLength;
                                }
                            }
                        }

                        Row {
                            id: httpapiMessagingSettings

                            anchors.left: parent.left
                            anchors.right: parent.right

                            height:  visible ? 30 : 0
                            visible: !AppFeatures.hideMessagingWindow && messagingEnableCheckBox.checked && (messagingProtocolTypeComboBox.messagingProtocolModelSelectedIdx == MessageServiceType.HttpApi)

                            Label {
                                id: messagingHttpapiUrlLabel
                                text: qsTrId("settings_messaging_httpapi_url") + Translator.translate
                                font.pixelSize: fontSize
                            }

                            SettingsTextField {
                                id: messagingHttpApiUrlField

                                anchors.right: parent.right
                                anchors.verticalCenter: messagingHttpapiUrlLabel.verticalCenter

                                width: 180
                                property string messagingHttpApiUrl: SettingsState.messagingHttpApiUrl

                                text: messagingHttpApiUrl
                                font.pixelSize: fontSize

                                onTextChanged: {
                                    if (text != messagingHttpApiUrl) {
                                        ActionProvider.markAppConfigUpdate(AppConfig.MessagingHttpApiUrl, text);
                                    }
                                }

                                onMessagingHttpApiUrlChanged: {
                                    text = messagingHttpApiUrl;
                                }
                            }
                        }

                        Row {
                            anchors.left: parent.left
                            anchors.right: parent.right

                            height:  visible ? 30 : 0
                            visible: !AppFeatures.hideMessagingWindow && messagingEnableCheckBox.checked && (messagingProtocolTypeComboBox.messagingProtocolModelSelectedIdx == MessageServiceType.HttpApi)

                            Label {
                                id: messagingSecurityTokenLabel
                                text: qsTrId("settings_messaging_security_token") + Translator.translate
                                font.pixelSize: fontSize
                            }

                            SettingsTextField {
                                id: messagingHttpApiSecurityTokenField

                                anchors.right: parent.right
                                anchors.verticalCenter: messagingSecurityTokenLabel.verticalCenter

                                width: 180
                                property string messagingHttpApiSecurityToken: SettingsState.messagingHttpApiSecurityToken

                                text: messagingHttpApiSecurityToken
                                font.pixelSize: fontSize

                                onTextChanged: {
                                    if (text != messagingHttpApiSecurityToken) {
                                        ActionProvider.markAppConfigUpdate(AppConfig.MessagingHttpApiSecurityToken, text);
                                    }
                                }

                                onMessagingHttpApiSecurityTokenChanged: {
                                    text = messagingHttpApiSecurityToken;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
