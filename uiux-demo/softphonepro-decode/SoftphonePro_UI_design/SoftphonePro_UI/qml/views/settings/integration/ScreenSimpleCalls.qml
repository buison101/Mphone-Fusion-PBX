import QtQuick 2.15
import QtQuick.Controls 2.15
import Flux 1.0

import "../../uicontrols"


Flickable {
    id: root

    contentHeight: height
    boundsBehavior: Flickable.StopAtBounds

    property int marginsValue: 20
    property int fontSize: 11

    clip: true

    Rectangle {
        anchors.fill: parent
        color: ColorStorage.settingsWindowBaseColor

        Rectangle {
            id: bounds

            anchors.fill: parent
            anchors.topMargin: marginsValue
            anchors.leftMargin: marginsValue
            anchors.rightMargin: marginsValue

            color: ColorStorage.settingsWindowBaseColor

            SettingsGroupBox {
                id: bookPropertiesGroupbox

                anchors.top: parent.top
                anchors.left: parent.left

                height: {
                    var value = description.height + description.anchors.topMargin
                    value += turnOnSimpleCalls.visible ? turnOnSimpleCalls.height + turnOnSimpleCalls.anchors.topMargin : 0
                    value += activationError.visible ? activationError.height : 0
                    value += simpleCallsSettings.visible ? simpleCallsSettings.height + simpleCallsSettings.anchors.topMargin : 0
                    value += simpleCallsStatusLabel.visible ? simpleCallsStatusLabel.height + simpleCallsStatusLabel.anchors.topMargin : 0
                    value += activationCodeTextField.visible ? activationCodeTextField.height + activationCodeTextField.anchors.topMargin : 0
                    return value + marginsValue

                }
                width: bounds.width

                title: qsTrId("settings_crm") + Translator.translate

                Label {
                    id: description

                    anchors.top: parent.top
                    anchors.topMargin: marginsValue
                    anchors.left: parent.left
                    anchors.leftMargin: marginsValue

                    enabled: true

                    text: qsTrId("integration_crm_description").arg(StringStorage.simpleCallsDefaultURL).arg(StringStorage.simpleCallsSupportedSystemsURL) + Translator.translate
                    font.pixelSize: fontSize

                    onLinkActivated: Qt.openUrlExternally(link)

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                    }
                }
                Row {
                    id: turnOnSimpleCalls

                    anchors.top: description.bottom
                    anchors.topMargin: marginsValue
                    anchors.left: parent.left
                    anchors.leftMargin: marginsValue

                    spacing: 20

                    visible: SettingsState.simpleCallsActivated

                    function onActivationButtonPressed() {
                        ActionProvider.sendSimpleCallsActivationRequest(activationCodeTextField.text);
                        ActionProvider.notifyAboutSimpleCallsActivationStatus(SimpleCallsAccount.Activating);
                        activationCodeTextField.text = "";
                    }

                    SettingsTextField {
                        id: activationCodeTextField

                        implicitWidth: 100

                        property string activationCode: text

                        maximumLength: 6
                        validator: IntValidator {bottom: 0; top: 1000000}

                        visible: SettingsState.simpleCallsActivationStatus == SimpleCallsAccount.NotActivated

                        onTextChanged: {
                            if (activationCode != text) {
                                activationCode = text
                            }
                        }

                        Keys.onEnterPressed: {
                            turnOnSimpleCalls.onActivationButtonPressed()
                        }
                    }

                    Label {
                        id: integrationStatusLabel

                        anchors.verticalCenter: activationButton.verticalCenter

                        property int loginStatus: SettingsState.simpleCallsLoginStatus

                        text: qsTrId("simple_calls_logged_out_status") + Translator.translate
                        visible: SettingsState.simpleCallsActivationStatus == SimpleCallsAccount.Activated

                        onLoginStatusChanged: {
                            text = Qt.binding(function() {
                                return getActivationErrorDescription(loginStatus) + Translator.translate;
                            });
                        }

                        function getActivationErrorDescription(loginStatus) {
                            if (loginStatus === SimpleCallsAccount.LoggingIn) {
                                return qsTrId("simple_calls_logging_in_status");
                            }
                            if (loginStatus === SimpleCallsAccount.LoggedIn) {
                                return qsTrId("simple_calls_logged_in_status");
                            }
                            if (loginStatus === SimpleCallsAccount.LoggedOut) {
                                return qsTrId("simple_calls_logged_out_status");
                            }
                        }
                    }

                    SettingsButton {
                        id: activationButton

                        anchors.left: activationCodeTextField.right
                        anchors.leftMargin: marginsValue

                        height: activationCodeTextField.height

                        enabled: activationCodeTextField.activationCode.length == 6
                        visible: SettingsState.simpleCallsActivationStatus == SimpleCallsAccount.NotActivated

                        text: qsTrId("simple_calls_activation_button_activate_text") + Translator.translate

                        onClicked: {
                            turnOnSimpleCalls.onActivationButtonPressed()
                        }
                    }

                   SettingsButton {
                        id: resetActivationButton

                        anchors.left: integrationStatusLabel.right
                        anchors.leftMargin: marginsValue

                        enabled: true
                        visible: SettingsState.simpleCallsActivationStatus == SimpleCallsAccount.Activated &&
                                 SettingsState.simpleCallsLoginStatus != SimpleCallsAccount.LoggingIn

                        text: qsTrId("simple_calls_reset_activation_button_text") + Translator.translate

                        onClicked: {
                            ActionProvider.simpleCallsResetActivation()
                        }
                    }

                    BusyIndicator {
                        id: activationBusyIndicator

                        anchors.left: activationCodeTextField.visible ? activationCodeTextField.right : integrationStatusLabel.right
                        anchors.leftMargin: marginsValue

                        width: height
                        height: activationButton.height

                        visible: !activationButton.visible && !resetActivationButton.visible && root.visible
                        running: visible
                    }
                }
                Label {
                    id: activationError

                    anchors.top: turnOnSimpleCalls.bottom
                    anchors.topMargin: 30 * SettingsState.scale
                    anchors.left: turnOnSimpleCalls.left

                    property int errorCode: SettingsState.simpleCallsAuthErrorCode

                    text: ""
                    visible: errorCode != 0

                    onErrorCodeChanged: {
                        text = Qt.binding(function() {
                            return getActivationErrorDescription(errorCode) + Translator.translate;
                        });
                        visible = text != ""
                    }

                    function getActivationErrorDescription(code) {
                        if (code === 0) {
                            return "";
                        }
                        if (code === 1000) {
                            return qsTrId("simple_calls_activation_error_please_try_again");
                        }
                        if (code === 1001) {
                            return qsTrId("simple_calls_invalid_activation_code");
                        }
                        if (code === 1002) {
                            return qsTrId("simple_calls_activation_code_expired");
                        }
                        if (code === 3001) {
                            return qsTrId("simple_calls_invalid_login");
                        }
                        if (code === 3002) {
                            return qsTrId("simple_calls_invalid_password");
                        }
                        if (code === 3003) {
                            return qsTrId("simple_calls_on_login_internal_server_error");
                        }
                        if (code === 3004) {
                            return qsTrId("simple_calls_no_pbx_found");
                        }
                        if (code === 3005) {
                            return qsTrId("simple_calls_no_config_found");
                        }

                        return qsTrId("simple_calls_unknown_error")
                    }
                }

                SettingsGroupBox {
                    id: simpleCallsSettings

                    title: qsTrId("settings_window_title") + Translator.translate

                    anchors.top: activationError.bottom
                    anchors.topMargin: marginsValue
                    anchors.left: parent.left
                    anchors.leftMargin: marginsValue

                    visible: SettingsState.simpleCallsActivationStatus == SimpleCallsAccount.Activated

                    height: innerNumber.height + allowOutgoingCallsRow.height + sendSipAccountNumberRow.height + 80
                    width: parent.width - 15

                    Row {
                        id: innerNumber

                        anchors.top: parent.top
                        anchors.topMargin: marginsValue
                        anchors.left: parent.left
                        anchors.leftMargin: marginsValue

                        spacing: 20

                        Label {
                            anchors.verticalCenter: innerNumberInput.verticalCenter
                            text: qsTrId("settings_crm_simple_calls_inner_number") + Translator.translate
                            font.pixelSize: fontSize
                        }

                        TextField {
                            id: innerNumberInput

                            enabled: false

                            implicitWidth: 190

                            font.pixelSize: fontSize

                            text: SettingsState.simpleCallsExtensionNumber
                        }
                    }

                    Row {
                        id: allowOutgoingCallsRow

                        anchors.top: innerNumber.bottom
                        anchors.topMargin: marginsValue
                        anchors.left: parent.left
                        anchors.leftMargin: marginsValue

                        spacing: 20

                        CheckBox {
                            id: allowOutgoingCallsCheckbox

                            property bool allowOutgoingCalls: SettingsState.simpleCallsAccount.allowOutgoingCalls

                            checked: allowOutgoingCalls

                            enabled: false

                            onCheckedChanged: {
                                if (checked != allowOutgoingCalls) {
                                    ActionProvider.markSimpleCallsAccountUpdate(SimpleCallsAccount.AllowOutgoingCalls, checked);
                                }
                            }

                            onAllowOutgoingCallsChanged: {
                                checked = allowOutgoingCalls;
                            }
                        }

                        Label {
                            anchors.verticalCenter: allowOutgoingCallsCheckbox.verticalCenter
                            text: qsTrId("settings_crm_allow_outgoing_calls") + Translator.translate
                            font.pixelSize: fontSize
                        }
                    }

                    Row {
                        id: sendSipAccountNumberRow

                        anchors.top: allowOutgoingCallsRow.bottom
                        anchors.topMargin: marginsValue
                        anchors.left: parent.left
                        anchors.leftMargin: marginsValue

                        spacing: 20

                        CheckBox {
                            id: sendSipAccountNumberCheckbox

                            property bool sendAccountNumber: SettingsState.simpleCallsAccount.sendAccountNumber

                            checked: sendAccountNumber

                            enabled: false

                            onCheckedChanged: {
                                if (checked != sendAccountNumber) {
                                    ActionProvider.markSimpleCallsAccountUpdate(SimpleCallsAccount.SendAccountNumber, checked);
                                }
                            }

                            onSendAccountNumberChanged: {
                                checked = sendAccountNumber;
                            }
                        }

                        Label {
                            anchors.verticalCenter: sendSipAccountNumberCheckbox.verticalCenter
                            text: qsTrId("settings_crm_send_sip_account_number") + Translator.translate
                            font.pixelSize: fontSize
                        }
                    }
                }

                Label {
                    id: simpleCallsStatusLabel

                    anchors.left: turnOnSimpleCalls.left
                    anchors.verticalCenter: simpleCallsStatusField.verticalCenter

                    enabled: enabled
                    visible: SettingsState.simpleCallsActivationStatus == SimpleCallsAccount.Activated

                    text: qsTrId("settings_crm_simple_calls_status") + ":" + Translator.translate
                    font.pixelSize: fontSize
                }

                Label {
                    id: simpleCallsStatusField

                    anchors.top: simpleCallsSettings.bottom
                    anchors.topMargin: marginsValue
                    anchors.left: simpleCallsStatusLabel.right
                    anchors.leftMargin: marginsValue

                    enabled: true
                    visible: SettingsState.simpleCallsActivationStatus == SimpleCallsAccount.Activated

                    property var simpleCallsStatus: SettingsState.simpleCallsAccount.status
                    font.pixelSize: fontSize

                    onSimpleCallsStatusChanged: {
                        text = Qt.binding(function() {
                            return getStatusDescription(simpleCallsStatus) + Translator.translate;
                        });

                        if (simpleCallsStatus == SimpleCallsAccount.DisconnectedSameGUID) {
                            turnOnSimpleCallsCheckbox.enabled = false;
                        }
                    }

                    function getStatusDescription(status) {
                        if (status == SimpleCallsAccount.Connected) {
                            return qsTrId("settings_crm_simple_calls_status_connected");
                        }

                        if (status == SimpleCallsAccount.Disconnected) {
                            return qsTrId("settings_crm_simple_calls_status_disconnected");
                        }

                        if (status == SimpleCallsAccount.DisconnectedSameGUID) {
                            return qsTrId("settings_crm_simple_calls_status_disconnected_same_guid");
                        }

                        if (status == SimpleCallsAccount.LicenseExpired) {
                            return "Истек срок использования лицензионного ключа";
                        }

                        if (status == SimpleCallsAccount.ClientsNumExceeded) {
                            return "Превышено максимальное допустимое количество пользователей";
                        }

                        if (status == SimpleCallsAccount.LicenseUnableVerify) {
                            return "Ошибка проверки лицензионного ключа";
                        }

                        if (status == SimpleCallsAccount.InvalidLicenseKey) {
                            return "Лицензионный ключ недействителен";
                        }

                        if (status == SimpleCallsAccount.LicenseKeyTypeError) {
                            return "Лицензионный ключ не подходит для этого типа АТС-коннектора";
                        }

                        if (status == SimpleCallsAccount.LicenseKeyVersionError) {
                            return "Лицензионный ключ не подходит для этой версии АТС-коннектора";
                        }

                        if (status == SimpleCallsAccount.LicenseKeyInvalidCrm) {
                            return "Нет лицензии на подключение этой CRM системы";
                        }

                        if (status == SimpleCallsAccount.InvalidPassword) {
                            return "Ошибка авторизации";
                        }

                        if (status == SimpleCallsAccount.UnsupportedClientVersion) {
                            return "Неподдерживаемая версия клиента";
                        }

                        return qsTrId("settings_crm_simple_calls_status_disconnected");
                    }
                }

                SettingsButton {
                    id: simpleCallsCheckConnectionBtn

                    anchors.right: description.right
                    anchors.top: simpleCallsStatusLabel.bottom
                    anchors.topMargin: marginsValue


                    enabled: SettingsState.simpleCallsActivationStatus == SimpleCallsAccount.Activated
                    visible: !busyIndicator.visible && root.visible &&
                             SettingsState.simpleCallsActivationStatus == SimpleCallsAccount.Activated &&
                             SettingsState.simpleCallsLoginStatus != SimpleCallsAccount.LoggingIn

                    text: qsTrId("settings_crm_simple_calls_check_status") + Translator.translate

                    font.pixelSize: fontSize

                    onClicked: {
                        ActionProvider.checkSimpleCallsAccountRegistration();
                    }
                }

                BusyIndicator {
                    id: busyIndicator

                    anchors.verticalCenter: simpleCallsCheckConnectionBtn.verticalCenter
                    anchors.right: simpleCallsCheckConnectionBtn.right

                    width: height
                    height: simpleCallsCheckConnectionBtn.height

                    visible: SettingsState.showCheckSimpleCallsConnectionSpinner && root.visible
                    running: visible
                }
            }
        }
    }
}
