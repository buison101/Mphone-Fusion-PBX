import QtQuick 2.15
import QtQuick.Controls 2.15
import Flux 1.0

import "../dialogs"
import "../uicontrols"

ScrollView {
    id: root

    property int fontSize: 11
    property int marginValue: 20

    Flickable {
        id: flickable

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AlwaysOn
        }

        contentHeight: sipAccount.height
        boundsBehavior: Flickable.StopAtBounds

        clip: true

        enabled: !AppState.instanceDisabled

        Rectangle {
            id: sipAccount

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            color: ColorStorage.settingsWindowBaseColor

            height: accountName.height + marginValue
                    + startupRegistration.height + marginValue
                    + sipConnection.height + marginValue
                    + dialingRules.height + marginValue
                    + firewallTraversalMethod.height + marginValue
                    + cloudPBXFeatures.height + marginValue
                    + sipMediaEncryptiontCombobox.height + marginValue
                    + sipTransportCombobox.height + marginValue
                    + sipPublicIpCombobox.height + marginValue
                    + sipLocalPortCombobox.height + marginValue
                    + sipRegTimeoutCombobox.height + marginValue
                    + sipKeepAliveTimeoutCombobox.height + marginValue
                    + rewriteIp.height + marginValue
                    + 3 * marginValue

            Rectangle {
                anchors.fill: parent
                anchors.topMargin: marginValue
                anchors.leftMargin: marginValue
                anchors.rightMargin: marginValue

                color: ColorStorage.settingsWindowBaseColor

                Row {
                    id: accountName

                    anchors.top: parent.top
                    anchors.left: parent.left

                    spacing: marginValue

                    Label {
                        id: accountNameLabel

                        anchors.verticalCenter: accountNameField.verticalCenter

                        text: qsTrId("settings_sip_account_name") + Translator.translate
                        font.pixelSize: fontSize
                    }

                    SettingsTextField {
                        id: accountNameField

                        implicitWidth: 150

                        property string name: SettingsState.sipAccount.name
                        text: name

                        validator: RegExpValidator {
                            regExp: /^[^\n]{0,23}$/
                        }

                        onTextChanged: {
                            if (text != name) {
                                ActionProvider.markSipAccountUpdate(SipAccount.Name, text);
                            }
                        }

                        onNameChanged: {
                            text = name;
                        }
                    }
                }

                Row {
                    id: startupRegistration

                    anchors.topMargin: marginValue
                    anchors.top: accountName.bottom
                    anchors.left: parent.left

                    spacing: marginValue

                    SettingsCheckBox {
                        id: startupRegistrationCheckbox

                        property bool registerOnStartup: SettingsState.sipAccount.registerOnStartup

                        checked: registerOnStartup

                        onCheckedChanged: {
                            if (checked != registerOnStartup) {
                                ActionProvider.markSipAccountUpdate(SipAccount.RegisterOnStartup, checked);
                            }
                        }

                        onRegisterOnStartupChanged: {
                            checked = registerOnStartup;
                        }
                    }

                    Label {
                        anchors.verticalCenter: startupRegistrationCheckbox.verticalCenter
                        text: qsTrId("settings_sip_account_reg_on_start") + Translator.translate
                        font.pixelSize: fontSize
                    }
                }

                SettingsGroupBox {
                    id: sipConnection

                    anchors.top: startupRegistration.bottom
                    anchors.topMargin: marginValue
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: sipServerField.height + marginValue
                            + sipLoginField.height + marginValue
                            + sipPasswordField.height + marginValue
                            + sipUserField.height + marginValue
                            + sipAuthNameField.height + marginValue
                            + sipDomainField.height + marginValue
                            + sipProxyField.height + marginValue + marginValue

                    title: qsTrId("settings_sip_account_connection_and_auth") + Translator.translate

                    Label {
                        id: sipServerLabel

                        anchors.verticalCenter: sipServerField.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue

                        text: qsTrId("settings_sip_account_server") + Translator.translate
                        font.pixelSize: fontSize
                    }

                    Label {
                        anchors.left: sipServerLabel.right
                        anchors.leftMargin: 1
                        anchors.baseline: sipServerField.baseline

                        text: "*"
                        color: "red"
                    }

                    SettingsTextField {
                        id: sipServerField

                        anchors.top: parent.top
                        anchors.topMargin: marginValue
                        anchors.left: sipServerLabel.right
                        anchors.leftMargin: marginValue * 4

                        width: 150

                        maximumLength: 256

                        property string server: SettingsState.sipAccount.server

                        text: server

                        onTextChanged: {
                            if (text != server) {
                                ActionProvider.markSipAccountUpdate(SipAccount.Server, text);
                            }
                        }

                        onServerChanged: {
                            text = server;
                        }
                    }

                    SettingsButton {
                        id: checkRegistrationButtom

                        anchors.baseline: sipServerField.baseline
                        anchors.left: sipShowPassword.left

                        text: qsTrId("settings_sip_account_check_connection") + Translator.translate

                        font.pixelSize: fontSize

                        onClicked: {
                            ActionProvider.checkSipAccountRegistration();
                        }
                    }

                    Label {
                        id: sipLoginLabel

                        anchors.verticalCenter: sipLoginField.verticalCenter
                        anchors.left: sipDomainLabel.left

                        text: qsTrId("settings_sip_account_login") + Translator.translate
                        font.pixelSize: fontSize
                    }

                    Label {
                        anchors.left: sipLoginLabel.right
                        anchors.leftMargin: 1
                        anchors.baseline: sipLoginField.baseline

                        text: "*"
                        font.pixelSize: fontSize
                        color: "red"
                    }

                    SettingsTextField {
                        id: sipLoginField

                        anchors.top: sipServerField.bottom
                        anchors.topMargin: marginValue
                        anchors.left: sipServerField.left

                        property string login: SettingsState.sipAccount.login

                        text: login

                        width: 150
                        maximumLength: 256

                        onTextChanged: {
                            if (text != login) {
                                ActionProvider.markSipAccountUpdate(SipAccount.Username, text);
                            }
                        }

                        onLoginChanged: {
                            text = login;
                        }
                    }

                    Label {
                        id: sipPasswordLabel

                        anchors.verticalCenter: sipPasswordField.verticalCenter
                        anchors.left: sipLoginLabel.left

                        text: qsTrId("settings_sip_account_password") + Translator.translate
                        font.pixelSize: fontSize
                    }

                    Label {
                        anchors.left: sipPasswordLabel.right
                        anchors.leftMargin: 1
                        anchors.baseline: sipPasswordField.baseline

                        text: "*"
                        font.pixelSize: fontSize
                        color: "red"
                    }

                    SettingsTextField {
                        id: sipPasswordField

                        anchors.top: sipLoginField.bottom
                        anchors.topMargin: marginValue
                        anchors.left: sipLoginField.left

                        property string password: SettingsState.sipAccount.password

                        text: password
                        echoMode: SettingsState.showSipAccountPassword ? TextInput.Normal : TextInput.Password

                        width: 150
                        maximumLength: 256

                        onTextChanged: {
                            if (text != password) {
                                ActionProvider.markSipAccountUpdate(SipAccount.Password, text);
                            }
                        }

                        onPasswordChanged: {
                            text = password;
                        }
                    }

                    SettingsButton {
                        id: sipShowPassword

                        anchors.verticalCenter: sipPasswordField.verticalCenter
                        anchors.left: sipPasswordField.right
                        anchors.leftMargin: 5

                        width: 20
                        height: 20

                        enabled: sipPasswordField.text.length > 0
                        visible: enabled

                        Image {
                            anchors.centerIn: parent

                            width: 16
                            height: 16

                            sourceSize.width: width
                            sourceSize.height: height

                            source: SettingsState.showSipAccountPassword ? "qrc:/images/eye_off.svg" : "qrc:/images/eye.svg"
                        }

                        onClicked: {
                            ActionProvider.showSipAccountPassword(!SettingsState.showSipAccountPassword);
                        }
                    }

                    Label {
                        id: sipUserLabel

                        anchors.verticalCenter: sipUserField.verticalCenter
                        anchors.left: sipProxyLabel.left

                        text: qsTrId("settings_sip_account_display_name") + Translator.translate
                        font.pixelSize: fontSize
                    }

                    SettingsTextField {
                        id: sipUserField

                        anchors.top: sipPasswordField.bottom
                        anchors.topMargin: marginValue
                        anchors.left: sipProxyField.left

                        property string user: SettingsState.sipAccount.user

                        text: user

                        width: 150
                        maximumLength: 256

                        onTextChanged: {
                            if (text != user) {
                                ActionProvider.markSipAccountUpdate(SipAccount.DisplayName, text);
                            }
                        }

                        onUserChanged: {
                            text = user;
                        }
                    }

                    Label {
                        id: sipAuthNameLabel

                        anchors.verticalCenter: sipAuthNameField.verticalCenter
                        anchors.left: sipServerLabel.left

                        text: qsTrId("settings_sip_account_authid") + Translator.translate
                        font.pixelSize: fontSize
                    }

                    SettingsTextField {
                        id: sipAuthNameField

                        anchors.top: sipUserField.bottom
                        anchors.topMargin: marginValue
                        anchors.left: sipServerField.left

                        property string authId: SettingsState.sipAccount.authId

                        text: authId
                        font.pixelSize: fontSize

                        width: 150
                        maximumLength: 256

                        onTextChanged: {
                            if (text != authId) {
                                ActionProvider.markSipAccountUpdate(SipAccount.AuthId, text);
                            }
                        }

                        onAuthIdChanged: {
                            text = authId;
                        }
                    }

                    Label {
                        id: sipDomainLabel

                        anchors.verticalCenter: sipDomainField.verticalCenter
                        anchors.left: sipUserLabel.left

                        text: qsTrId("settings_sip_account_domain") + Translator.translate
                        font.pixelSize: fontSize
                    }

                    SettingsTextField {
                        id: sipDomainField

                        anchors.top: sipAuthNameField.bottom
                        anchors.topMargin: marginValue
                        anchors.left: sipAuthNameField.left

                        property string domain: SettingsState.sipAccount.domain

                        text: domain
                        font.pixelSize: fontSize

                        width: 150
                        maximumLength: 256

                        onTextChanged: {
                            if (text != domain) {
                                ActionProvider.markSipAccountUpdate(SipAccount.Domain, text);
                            }
                        }

                        onDomainChanged: {
                            text = domain;
                        }
                    }

                    Label {
                        id: sipProxyLabel

                        anchors.verticalCenter: sipProxyField.verticalCenter
                        anchors.left: sipServerLabel.left

                        text: qsTrId("settings_sip_account_proxy") + Translator.translate
                        font.pixelSize: fontSize
                    }

                    SettingsTextField {
                        id: sipProxyField

                        anchors.top: sipDomainField.bottom
                        anchors.topMargin: marginValue
                        anchors.left: sipServerField.left

                        property string proxy: SettingsState.sipAccount.proxy

                        text: proxy

                        width: 150
                        maximumLength: 256

                        onTextChanged: {
                            if (text != proxy) {
                                ActionProvider.markSipAccountUpdate(SipAccount.Proxy, text);
                            }
                        }

                        onProxyChanged: {
                            text = proxy;
                        }
                    }
                }

                SettingsGroupBox {
                    id: cloudPBXFeatures

                    anchors.top: sipConnection.bottom
                    anchors.topMargin: marginValue
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: sipCallTransferButton.height + marginValue / 2
                            + sipCallTransferDtmfButton.height + marginValue / 2
                            + sipCallTransferDtmfPrefix.height + marginValue

                    title: qsTrId("settings_sip_account_cloud_pbx_features") + Translator.translate

                    Label {
                        id: sipCallTransferLabel

                        anchors.top: parent.top
                        anchors.topMargin: marginValue
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue

                        text: qsTrId("settings_sip_account_call_transfer") + Translator.translate
                        font.pixelSize: fontSize
                    }

                    ButtonGroup {
                        id: sipCallTransferGroup
                    }

                    SettingsRadioButton {
                        id: sipCallTransferButton

                        anchors.left: sipCallPickupField.left
                        anchors.verticalCenter: sipCallTransferLabel.verticalCenter

                        text: qsTrId("settings_sip_account_call_transfer_sip") + Translator.translate
                        ButtonGroup.group: sipCallTransferGroup

                        checked: mode == CallTransferMode.Sip

                        property int mode: SettingsState.sipAccount.callTransferMode
                        onModeChanged: {
                            if (mode == CallTransferMode.Sip) {
                                checked = true;
                            }
                        }

                        onCheckedChanged: {
                            if (checked && mode != CallTransferMode.Sip) {
                                ActionProvider.markSipAccountUpdate(SipAccount.CallTransferMode, CallTransferMode.Sip);
                            }
                        }

                        font.pixelSize: fontSize
                    }

                    Label {
                        id: callTransferSipMethodDefaultLabel
                        anchors {
                            verticalCenter: sipCallTransferButton.verticalCenter
                            left: sipCallTransferButton.right
                            leftMargin: marginValue
                        }

                        enabled: sipCallTransferButton.checked
                        text: qsTrId("settings_sip_account_call_transfer_sip_method_default_label") + Translator.translate + ":"
                        font.pixelSize: fontSize
                    }

                    SettingsComboBox {
                        anchors {
                            verticalCenter:  callTransferSipMethodDefaultLabel.verticalCenter
                            left: callTransferSipMethodDefaultLabel.right
                            leftMargin: marginValue
                        }

                        enabled: sipCallTransferButton.checked
                        model: [qsTrId("settings_sip_account_call_transfer_sip_transfer_method_transfer_now") + Translator.translate,
                            qsTrId("settings_sip_account_call_transfer_sip_transfer_method_call_first") + Translator.translate]
                        onActivated: function(index) {
                            ActionProvider.markSipAccountUpdate(SipAccount.CallTransferSipMethod, index);
                        }
                        currentIndex: SettingsState.sipAccount.callTransferSipMethod

                        font.pixelSize: fontSize
                    }

                    SettingsRadioButton {
                        id: sipCallTransferDtmfButton

                        anchors.top: sipCallTransferButton.bottom
                        anchors.left: sipCallTransferButton.left

                        text: qsTrId("settings_sip_account_call_transfer_sip_dtmf") + Translator.translate
                        ButtonGroup.group: sipCallTransferGroup

                        checked: mode == CallTransferMode.Dtmf

                        property int mode: SettingsState.sipAccount.callTransferMode
                        onModeChanged: {
                            if (mode == CallTransferMode.Dtmf) {
                                checked = true;
                            }
                        }

                        onCheckedChanged: {
                            if (checked && mode != CallTransferMode.Dtmf) {
                                ActionProvider.markSipAccountUpdate(SipAccount.CallTransferMode, CallTransferMode.Dtmf);
                            }
                        }

                        font.pixelSize: fontSize
                    }

                    SettingsTextField {
                        id: sipCallTransferDtmfPrefix

                        anchors.verticalCenter: sipCallTransferDtmfButton.verticalCenter
                        anchors.left: sipCallTransferDtmfButton.right
                        anchors.leftMargin: marginValue

                        width: 40
                        enabled: sipCallTransferDtmfButton.checked

                        property string callTransferDtmf: SettingsState.sipAccount.callTransferDtmfPrefix

                        text: callTransferDtmf

                        onTextChanged: {
                            if (text != callTransferDtmf) {
                                ActionProvider.markSipAccountUpdate(SipAccount.CallTransferDTMF, {idx: 0, dtmf: text});
                            }
                        }

                        onCallTransferDtmfChanged: {
                            text = callTransferDtmf;
                        }

                        validator: RegExpValidator {
                            regExp: /^[0-9#\*]*$/
                        }
                    }

                    Label {
                        id: sipCallTransferDtmfPrefixLabel

                        anchors.verticalCenter: sipCallTransferDtmfPrefix.verticalCenter
                        anchors.left: sipCallTransferDtmfPrefix.right
                        anchors.leftMargin: marginValue

                        enabled: sipCallTransferDtmfButton.checked

                        text: qsTrId("settings_sip_account_call_transfer_sip_number") + Translator.translate
                        font.pixelSize: fontSize
                    }

                    SettingsTextField {
                        id: sipCallTransferDtmfPostfix

                        anchors.verticalCenter: sipCallTransferDtmfPrefix.verticalCenter
                        anchors.left: sipCallTransferDtmfPrefixLabel.right
                        anchors.leftMargin: marginValue

                        width: sipCallTransferDtmfPrefix.width

                        enabled: sipCallTransferDtmfButton.checked

                        property string callTransferDtmf: SettingsState.sipAccount.callTransferDtmfPostfix

                        text: callTransferDtmf

                        onTextChanged: {
                            if (text != callTransferDtmf) {
                                ActionProvider.markSipAccountUpdate(SipAccount.CallTransferDTMF, {idx: 1, dtmf: text});
                            }
                        }

                        onCallTransferDtmfChanged: {
                            text = callTransferDtmf;
                        }

                        validator: RegExpValidator {
                            regExp: /^[0-9#\*]*$/
                        }
                    }

                    Label {
                        id: sipCallPickup

                        anchors.verticalCenter: sipCallPickupField.verticalCenter
                        anchors.left: sipCallTransferLabel.left

                        enabled: sipCallPickupField.enabled

                        text: qsTrId("settings_sip_account_call_pickup_dtmf") + Translator.translate
                        font.pixelSize: fontSize
                    }

                    SettingsTextField {
                        id: sipCallPickupField

                        anchors.top: sipCallTransferDtmfPostfix.bottom
                        anchors.topMargin: marginValue
                        anchors.left: sipCallPickup.right
                        anchors.leftMargin: marginValue

                        enabled: true

                        width: 90

                        property string callPickupDtmf: SettingsState.sipAccount.callPickupDtmf

                        text: callPickupDtmf

                        onTextChanged: {
                            if (text != callPickupDtmf) {
                                ActionProvider.markSipAccountUpdate(SipAccount.CallPickupDTMF, text);
                            }
                        }

                        onCallPickupDtmfChanged: {
                            text = callPickupDtmf;
                        }
                    }
                }


                SettingsGroupBox {
                    id: dialingRules

                    anchors.top: cloudPBXFeatures.bottom
                    anchors.topMargin: marginValue
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: sipCallDialnigExpressionField.height + marginValue

                    title: qsTrId("settings_sip_account_dialing_rules") + Translator.translate

                    Label {
                        id: sipCallDialnigExpression

                        anchors.verticalCenter: sipCallDialnigExpressionField.verticalCenter
                        anchors.leftMargin: marginValue
                        anchors.left: parent.left

                        enabled: sipCallDialnigExpressionField.enabled

                        text: qsTrId("settings_sip_account_call_dialing_expression") + Translator.translate
                        font.pixelSize: fontSize
                    }

                    SettingsTextField {
                        id: sipCallDialnigExpressionField

                        anchors.top: parent.top
                        anchors.left: sipCallDialnigExpression.right
                        anchors.leftMargin: marginValue
                        anchors.topMargin: marginValue / 2

                        enabled: true

                        width: 210

                        property string callDialingExpression: SettingsState.sipAccount.callDialingExpression

                        text: callDialingExpression

                        onTextChanged: {
                            if (text != callDialingExpression) {
                                ActionProvider.markSipAccountUpdate(SipAccount.CallDialingExpression, text);
                            }
                        }

                        onCallDialingExpressionChanged: {
                            text = callDialingExpression;
                        }
                    }
                }

                SettingsGroupBox {
                    id: firewallTraversalMethod

                    anchors.top: dialingRules.bottom
                    anchors.topMargin: marginValue
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: firewallTraversalSTUNButton.height + marginValue
                            + firewallTraversalLocalButton.height + marginValue
                            + firewallTraversalICEButton.height + marginValue + marginValue

                    title: qsTrId("settings_sip_account_firewall_traversal_method_title") + Translator.translate

                    ButtonGroup {
                        id: firewallTraversalMethodGroup
                    }

                    SettingsRadioButton {
                        id: firewallTraversalSTUNButton

                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue
                        anchors.topMargin: marginValue

                        text: qsTrId("settings_sip_account_firewall_traversal_method_stun") + Translator.translate
                        ButtonGroup.group: firewallTraversalMethodGroup

                        checked: mode == FirewallTraversalMethod.STUN

                        property int mode: SettingsState.sipAccount.firewallTraversalMethod
                        onModeChanged: {
                            if(mode == FirewallTraversalMethod.STUN) {
                                checked = true
                            }
                        }

                        onCheckedChanged: {
                            if (checked) {
                                ActionProvider.markSipAccountUpdate(SipAccount.FirewallTraversalMethod, FirewallTraversalMethod.STUN);
                            }
                        }

                        font.pixelSize: fontSize
                    }

                    SettingsRadioButton {
                        id: firewallTraversalICEButton

                        anchors.top: firewallTraversalSTUNButton.bottom
                        anchors.topMargin: marginValue
                        anchors.left: firewallTraversalSTUNButton.left

                        text: qsTrId("settings_sip_account_firewall_traversal_method_ise") + Translator.translate
                        ButtonGroup.group: firewallTraversalMethodGroup

                        checked: mode == FirewallTraversalMethod.ICE

                        property int mode: SettingsState.sipAccount.firewallTraversalMethod
                        onModeChanged: {
                            if(mode == FirewallTraversalMethod.ICE) {
                                checked = true
                            }
                        }

                        onCheckedChanged: {
                            if (checked) {
                                ActionProvider.markSipAccountUpdate(SipAccount.FirewallTraversalMethod, FirewallTraversalMethod.ICE);
                            }
                        }

                        font.pixelSize: fontSize
                    }

                    SettingsRadioButton {
                        id: firewallTraversalLocalButton

                        anchors.top: firewallTraversalICEButton.bottom
                        anchors.topMargin: marginValue
                        anchors.left: firewallTraversalICEButton.left

                        text: qsTrId("settings_sip_account_firewall_traversal_method_local") + Translator.translate
                        ButtonGroup.group: firewallTraversalMethodGroup

                        checked: mode == FirewallTraversalMethod.LOCAL

                        property int mode: SettingsState.sipAccount.firewallTraversalMethod
                        onModeChanged: {
                            if(mode == FirewallTraversalMethod.LOCAL) {
                                checked = true
                            }
                        }

                        onCheckedChanged: {
                            if (checked) {
                                ActionProvider.markSipAccountUpdate(SipAccount.FirewallTraversalMethod, FirewallTraversalMethod.LOCAL);
                            }
                        }

                        font.pixelSize: fontSize
                    }
                }

                Label {
                    id: sipMediaEncryptiontLabel

                    anchors.verticalCenter: sipMediaEncryptiontCombobox.verticalCenter

                    text: qsTrId("settings_sip_account_encryption") + Translator.translate
                    font.pixelSize: fontSize
                }

                SettingsComboBox {
                    id: sipMediaEncryptiontCombobox

                    anchors.top: firewallTraversalMethod.bottom
                    anchors.topMargin: marginValue
                    anchors.left: sipRegTimeoutLabel.right
                    anchors.leftMargin: marginValue

                    enabled: true

                    width: 150

                    font.pixelSize: fontSize

                    model: SettingsState.sipEncryptionModel
                    textRole: "name"

                    property int sipEncryptionModelSelectedIdx: SettingsState.sipEncryptionModelSelectedIdx

                    onSipEncryptionModelSelectedIdxChanged: {
                        sipMediaEncryptiontCombobox.currentIndex = sipEncryptionModelSelectedIdx;
                    }

                    onCurrentIndexChanged: {
                        if (currentIndex != sipEncryptionModelSelectedIdx) {
                            ActionProvider.markSipAccountUpdate(SipAccount.SRTP, currentIndex);
                        }
                    }
                }

                Label {
                    id: sipTransportLabel

                    anchors.verticalCenter: sipTransportCombobox.verticalCenter
                    anchors.left: sipMediaEncryptiontLabel.left

                    text: qsTrId("settings_sip_account_transport") + Translator.translate
                    font.pixelSize: fontSize
                }

                SettingsComboBox {
                    id: sipTransportCombobox

                    anchors.top: sipMediaEncryptiontCombobox.bottom
                    anchors.topMargin: marginValue
                    anchors.left: sipMediaEncryptiontCombobox.left

                    width: 150

                    model: SettingsState.sipTransportModel
                    textRole: "name"

                    font.pixelSize: fontSize

                    property int sipTransportModelSelectedIdx: SettingsState.sipTransportModelSelectedIdx

                    onSipTransportModelSelectedIdxChanged: {
                        sipTransportCombobox.currentIndex = sipTransportModelSelectedIdx;
                    }

                    onCurrentIndexChanged: {
                        if (currentIndex != sipTransportModelSelectedIdx) {
                            ActionProvider.markSipAccountUpdate(SipAccount.Transport, currentIndex);
                        }
                    }
                }

                Label {
                    id: sipPublicIpLabel

                    anchors.verticalCenter: sipPublicIpCombobox.verticalCenter
                    anchors.left: sipTransportLabel.left

                    text: qsTrId("settings_sip_account_public_ip") + Translator.translate
                    font.pixelSize: fontSize
                }

                SettingsComboBox {
                    id: sipPublicIpCombobox

                    anchors.top: sipTransportCombobox.bottom
                    anchors.topMargin: marginValue
                    anchors.left: sipMediaEncryptiontCombobox.left

                    width: 150

                    font.pixelSize: fontSize

                    model: SettingsState.sipPublicIpModel
                    textRole: "name"

                    editable: true
                    /*
                    // ipv4 validation
                    validator: RegExpValidator {
                        regExp: /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/
                    }
                    */
                    validator: RegExpValidator {
                        regExp: /^.{0,256}$/
                    }

                    property string publicIp: SettingsState.sipAccount.publicIp

                    onPublicIpChanged: {
                        if (publicIp.length > 0) {
                            editText = publicIp;
                        }
                    }

                    onEditTextChanged: {
                        if (editText != publicIp) {
                            ActionProvider.markSipAccountUpdate(SipAccount.PublicAddress, editText);
                        }
                    }
                }

                Label {
                    id: sipLocalPortLabel

                    anchors.verticalCenter: sipLocalPortCombobox.verticalCenter
                    anchors.left: sipPublicIpLabel.left

                    text: qsTrId("settings_sip_account_local_port") + Translator.translate
                    font.pixelSize: fontSize
                }

                SettingsComboBox {
                    id: sipLocalPortCombobox

                    anchors.top: sipPublicIpCombobox.bottom
                    anchors.topMargin: marginValue
                    anchors.left: sipMediaEncryptiontCombobox.left

                    width: 150

                    model: SettingsState.sipLocalPortModel
                    textRole: "name"

                    font.pixelSize: fontSize

                    editable: true
                    // tcp/udp port validation
                    validator: RegExpValidator {
                        regExp: /^([0-9]{1,4}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$/
                    }

                    property string localPort: SettingsState.sipAccount.localPort

                    onLocalPortChanged: {
                        if (localPort.length > 0) {
                            editText = localPort;
                        }
                    }

                    onEditTextChanged: {
                        if (editText != localPort) {
                            ActionProvider.markSipAccountUpdate(SipAccount.LocalPort, editText);
                        }
                    }
                }

                Label {
                    id: sipRegTimeoutLabel

                    anchors.verticalCenter: sipRegTimeoutCombobox.verticalCenter
                    anchors.left: sipPublicIpLabel.left

                    text: qsTrId("settings_sip_account_reg_timeout") + "." + Translator.translate
                    font.pixelSize: fontSize
                }

                SettingsTextField {
                    id: sipRegTimeoutCombobox

                    anchors.top: sipLocalPortCombobox.bottom
                    anchors.topMargin: marginValue
                    anchors.left: sipMediaEncryptiontCombobox.left

                    width: 150

                    //registration timeout validation
                    validator: RegExpValidator {
                        regExp: /^([1-9]{1,1}[0-9]*)$/
                    }

                    property string regTimeout: SettingsState.sipAccount.regTimeout

                    onRegTimeoutChanged: {
                        if (regTimeout.length > 0) {
                            text = regTimeout;
                        }
                    }

                    onTextChanged: {
                        if (text != regTimeout) {
                            ActionProvider.markSipAccountUpdate(SipAccount.RegisterTimeout, text);
                        }
                    }
                }

                Label {
                    id: sipKeepAliveTimeoutLabel

                    anchors.verticalCenter: sipKeepAliveTimeoutCombobox.verticalCenter
                    anchors.left: sipPublicIpLabel.left

                    text: qsTrId("settings_sip_account_keepalive_timeout") + "." + Translator.translate
                    font.pixelSize: fontSize
                }

                SettingsTextField {
                    id: sipKeepAliveTimeoutCombobox

                    anchors.top: sipRegTimeoutCombobox.bottom
                    anchors.topMargin: marginValue
                    anchors.left: sipMediaEncryptiontCombobox.left

                    width: 150

                    //registration timeout validation
                    validator: RegExpValidator {
                        regExp: /^([0-9]{1,1}[0-9]*)$/
                    }

                    property string keepAliveTimeout: SettingsState.sipAccount.keepaliveTimeout

                    onKeepAliveTimeoutChanged: {
                        if (keepAliveTimeout.length > 0) {
                            text = keepAliveTimeout;
                        }
                    }

                    onTextChanged: {
                        if (text != keepAliveTimeout) {
                            ActionProvider.markSipAccountUpdate(SipAccount.KeepAliveTimeout, text);
                        }
                    }
                }

                Row {
                    id: rewriteIp

                    anchors.top: sipKeepAliveTimeoutCombobox.bottom
                    anchors.topMargin: marginValue
                    anchors.left: parent.left

                    spacing: marginValue

                    SettingsCheckBox {
                        id: rewriteIpCheckbox

                        property bool retwriteIp: SettingsState.sipAccount.allowIpRewrite
                        checked: retwriteIp.valueOf()

                        onCheckedChanged: {
                            if (checked != retwriteIp) {
                                ActionProvider.markSipAccountUpdate(SipAccount.AllowIpRewrite, checked);
                            }
                        }
                    }

                    Label {
                        anchors.verticalCenter: rewriteIpCheckbox.verticalCenter
                        text: qsTrId("settings_sip_account_rewrite_ip") + Translator.translate
                        font.pixelSize: fontSize
                    }
                }
            }
        }

        InfoDialog {
            id: invalidSipServerDialog

            width: 450
            height: 115

            visible: SettingsState.showInvalidSipServerDialog
            message: {
                if (AppFeatures.telphinServers) {
                    return qsTrId("dialog_invalid_sip_server_tephin") + Translator.translate
                }

                return Translator.translate;
            }

            onOKAction: function() {
                ActionProvider.confirmInvalidSipServer();
            }
        }
    }
}
