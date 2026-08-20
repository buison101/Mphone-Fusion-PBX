import QtQuick 2.15
import Flux 1.0

import "../uicontrols"
import "../errors"

FocusScope {
    id: root

    property bool isInputEmpty: phoneInput.edit.text == ""

    property var resetFocus: function() {
        phoneInput.focus = true;
    }

    property var requestInputFocus: function() {
        resetFocus();
        phoneInput.forceActiveFocus();
    }

    property var openAccountDropdown: function() {
        if (account.dropdownVisible) {
            account.closeDropdown();
            account.forceActiveFocus();
        } else {
            account.openDropdown();
        }
    }

    property var openStatusDropdown: function() {
        if (status.dropdownVisible) {
            status.closeDropdown();
            status.forceActiveFocus();
        } else {
            status.openDropdown();
        }
    }

    property var tryMakeCall: function() {
        if (!phoneInput.disableWorkFunction) {
            ActionProvider.makeCall(phoneInput.edit.text);
            phoneInput.secondsDisabledLeft = 0;
            phoneInput.disableWorkFunction = true;
        }
    }

    Row {
        id: statusAndAccountRow

        width: parent.width - 32 * SettingsState.scale

        height: 42 * SettingsState.scale
        anchors.top: parent.top
        anchors.topMargin: 8 * SettingsState.scale
        anchors.left: parent.left
        anchors.leftMargin: 16 * SettingsState.scale
        anchors.rightMargin: 16 * SettingsState.scale

        spacing: 0

        StatusButton {
            id: status

            Accessible.role: Accessible.Button
            Accessible.name: "StatusButton"

            anchors.verticalCenter: parent.verticalCenter
            selection: AppState.phoneStatus
            selectionImage: AppState.phoneStatusIcon
            selectionSize: 12 * SettingsState.scale

            focus: true

            enabled: !AppState.instanceDisabled && visible

            visible: !AppFeatures.hideStatusSettings

            hoverWide: visible ? (parent.width - 8 * SettingsState.scale) / 2  : 0
            hoverHeigth: visible ? 42 * SettingsState.scale : 0

            popupX: {
                var point = status.mapToItem(root, 0, 0);
                return mainWindow.x + 16 * SettingsState.scale;
            }

            popupY: {
                return mainWindow.y + 48 * SettingsState.scale;
            }

            doWorkOnListItemClick: function(idx) {
                ActionProvider.changePhoneStatus(idx, true, false);
            }

            KeyNavigation.tab: account

            KeyNavigation.backtab: phoneInput
        }

        AccountButton {
            id: account

            Accessible.role: Accessible.Button
            Accessible.name: "AccountButton"

            anchors.right:  status.visible ? parent.right: null
            anchors.centerIn: status.visible ? null : parent

            anchors.verticalCenter: parent.verticalCenter

            hoverWide: status.visible ? (parent.width - 8 * SettingsState.scale) / 2  : parent.width
            hoverHeigth: 42 * SettingsState.scale

            focus: true

            enabled: {
                return !AppState.instanceDisabled && visible && (!AppState.sipAccountsSettingsRestriction || accountsCount > 1 || (didsCount > 1));
            }

            showChevron: enabled

            selection: AppState.sipAccount + " " + AppState.didNameForDefaultAccount
            selectionImage: {
                switch(AppState.sipAccountStatus) {
                case RegistrationStatus.Unregistered:
                    return "qrc:/images/blank_circle_grey.svg";

                case RegistrationStatus.Registered:
                    return "qrc:/images/blank_circle_green.svg";

                case RegistrationStatus.RegisterError:
                    return "qrc:/images/blank_circle_red.svg";

                case RegistrationStatus.Connections:
                    return "qrc:/images/blank_circle_yellow.svg";
                }

                return "";
            }

            KeyNavigation.backtab: {
                if (!AppFeatures.hideStatusSettings) {
                    return status;
                }

                return phoneInput
            }

            selectionSize: 12 * SettingsState.scale
            selectionAlignment: Text.AlignLeft

            actionText: qsTrId("sip_account_combobox_action") + Translator.translate

            emptyDidsText: qsTrId("empty_dids_text") + Translator.translate

            viewElementWidth: 205 * SettingsState.scale

            sipModel: AppState.sipAccountModel

            showAction: !AppState.sipAccountsSettingsRestriction && !AppFeatures.hideSipAccounts

            doWorkOnListItemClick: function(idx) {
                ActionProvider.changeSipAccount(idx);
            }

            doWorkOnDidListItemClick: function(idx, accIdx) {
                ActionProvider.changeSipAccount(accIdx);
                ActionProvider.changeDid(idx, accIdx);
            }
            doWorkOnActionItemClick: function() {
                ActionProvider.showSettingsWindow(true);
                ActionProvider.tryCreateSipAccount();
            }
        }
    }

    PhoneInput {
        id: phoneInput

        Accessible.role: Accessible.Button
        Accessible.name: "PhoneInputLayer"

        anchors.top: statusAndAccountRow.bottom
        anchors.topMargin: 8 * SettingsState.scale
        anchors.left: parent.left
        anchors.leftMargin: 16 * SettingsState.scale

        textSize: 28 * SettingsState.scale
        focus: true
        errorLayerVisible: errorLayer.visible

        implicitWidth: parent.width - 32 * SettingsState.scale

        KeyNavigation.tab: status
        KeyNavigation.backtab: account

        Keys.onReturnPressed: {
            tryMakeCall();
        }

        Keys.onEnterPressed: {
            tryMakeCall();
        }

        property var timeNow: AppState.timeNow
        property int secondsDisabledMax: 2
        property int secondsDisabledLeft: 0
        property bool disableWorkFunction: false

        onTimeNowChanged: {
            if (secondsDisabledLeft == secondsDisabledMax) {
                return;
            }

            secondsDisabledLeft += 1;

            if (secondsDisabledLeft == secondsDisabledMax) {
                disableWorkFunction = false;
            }
        }

        onEnabledChanged: {
            if (!enabled) {
                return;
            }

            secondsDisabledLeft = 0;
            disableWorkFunction = true;
        }
    }

    Row {
        id: callForwardRow
        anchors.bottomMargin: 24 * SettingsState.scale
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        visible: callForward.text != "" && !errorLayer.visible
        width: callForward.contentWidth + 5 * SettingsState.scale + callForwardingLabel.width

        Text {
            id: callForwardingLabel
            text: qsTrId("call_forward_combobox_title") + Translator.translate
            color: ColorStorage.textAndDisabledIconsGrey
            font: 17 * SettingsState.scale
        }

        Text {
            id: callForward
            anchors.leftMargin: 5 * SettingsState.scale
            anchors.left: callForwardingLabel.right
            anchors.verticalCenter: callForwardingLabel
            text: AppState.callForward
            width: 120 * SettingsState.scale
            color: ColorStorage.iconsAndTextPrimary
            elide: Text.ElideRight
            font.pixelSize: 12 * SettingsState.scale
            font.bold: true
        }
    }

    Item {
        id: errorLayer

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 30 * SettingsState.scale

        visible: invalidAudioDeviceError.visible || sipRegError.visible || callMakeError.visible || licenseError.visible || updateAvailable.visible

        function clear() {
                errorLayer.visible = licenseError.show;
                sipRegError.visible = false;
                callMakeError.visible = false;
                updateAvailable.visible = false;
                invalidAudioDeviceError.visible = false;
                licenseError.visible = licenseError.show;
            }

        function openFirstError(from) {
            // add parameter from to avoid data race (if error just got fixed, 'show' could not change yet)
            if (licenseError.show && from != "license") {
                licenseError.visible = true;
                errorLayer.visible = true;
                return;
            } else if (sipRegError.show && from != "sipReg") {
                sipRegError.visible = true;
                errorLayer.visible = true;
                return;
            } else if (callMakeError.show && from != "callMake") {
                callMakeError.visible = true;
                errorLayer.visible = true;
                return;
            } else if (updateAvailable.show && from != "update") {
                updateAvailable.visible = true;
                errorLayer.visible = true;
                return;
            } else if (invalidAudioDeviceError.show && from != "invalidAudioDevice") {
                invalidAudioDeviceError.visible = true;
                errorLayer.visible = true;
            }
        }

        MainWindowError {
            id: sipRegError

            property bool show: AppState.showSipRegErrorWindow

            anchors.fill: parent
            info: qsTrId("telefony_provider_error") + ": SIP " + AppState.sipRegErrorCode + " - " + AppState.sipRegErrorDescription + Translator.translate

            visible: false

            onShowChanged: {
                if (show) {
                    errorLayer.visible = true;
                    sipRegError.visible = !licenseError.visible;
                    callMakeError.visible = false;
                    updateAvailable.visible = false;
                    invalidAudioDeviceError.visible = false;
                } else {
                    errorLayer.clear();
                    ActionProvider.dismissSipRegErrorWindow();
                    errorLayer.openFirstError("sipReg");
                }
            }

            doWorkOnButtonClick: function() {
                errorLayer.clear();
                ActionProvider.dismissSipRegErrorWindow();
            }

            doWorkOnErrorClick: function() {
                ActionProvider.showSipRegErrorDialog();
            }
        }

        MainWindowError {
            id: callMakeError

            property bool show: AppState.showCallMakeErrorWindow

            anchors.fill: parent
            info: qsTrId("telefony_provider_error") + ": SIP " + AppState.callMakeErrorCode + " - " + AppState.callMakeErrorText + Translator.translate

            visible: false

            onShowChanged: {
                if (show) {
                    errorLayer.visible = true;
                    callMakeError.visible = !licenseError.visible;
                    sipRegError.visible = false;
                    updateAvailable.visible = false;
                    invalidAudioDeviceError.visible = false;
                } else {
                    errorLayer.clear();
                    ActionProvider.dismissCallMakeErrorWindow();
                    errorLayer.openFirstError("callMake");
                }
            }

            doWorkOnButtonClick: function() {
                errorLayer.clear();
                ActionProvider.dismissCallMakeErrorWindow();
            }

            doWorkOnErrorClick: function() {
                ActionProvider.showCallMakeErrorDialog();
            }
        }

        MainWindowError {
            id: invalidAudioDeviceError

            property bool show: AppState.showInvalidAudioDeviceErrorWindow

            anchors.fill: parent
            info: AppState.callMakeAudioError == CallMakeAudioError.MicDisabledBySystem ? qsTrId("micro_disabled_by_system_title") + Translator.translate : qsTrId("audio_device_error_title") + Translator.translate

            visible: false

            onShowChanged: {
                if (show) {
                    errorLayer.visible = true;
                    invalidAudioDeviceError.visible = !licenseError.visible;
                    callMakeError.visible = false;
                    sipRegError.visible = false;
                    updateAvailable.visible = false;
                } else {
                    errorLayer.clear();
                    ActionProvider.dismissInvalidAudioDeviceErrorWindow();
                    errorLayer.openFirstError("invalidAudioDevice");
                }
            }

            doWorkOnButtonClick: function() {
                errorLayer.clear();
                ActionProvider.dismissInvalidAudioDeviceErrorWindow();
            }

            doWorkOnErrorClick: function() {
                ActionProvider.showInvalidAudioDeviceErrorDialog();
            }
        }

        MainWindowError {
            id: licenseError

            property bool show: AppState.showLicenseWindow && AppState.licenseInfo
                                && ((AppState.licenseInfo.state != License.Valid && AppState.licenseInfo.state != License.ExpireSoon)
                     || (SettingsState.displayLicenseWillExpireSoonWarning && AppState.licenseInfo.state == License.ExpireSoon))

            anchors.fill: parent
            info: AppState.licenseInfo ? AppState.licenseInfo.title : ""
            visible: false
            disableCloseButton: AppState.licenseInfo.state == License.DemoFinished || AppState.licenseInfo.state == License.Invalid || AppState.licenseInfo.state == License.Expired

            onShowChanged: {
                if (show) {
                    errorLayer.visible = true;
                    licenseError.visible = true;
                    sipRegError.visible = false;
                    callMakeError.visible = false;
                    updateAvailable.visible = false;
                    invalidAudioDeviceError.visible = false;
                } else {
                    errorLayer.clear();
                    ActionProvider.dismissLicenseWindow();
                    errorLayer.openFirstError("license");
                }
            }

            doWorkOnButtonClick: function(){
                errorLayer.clear();
                ActionProvider.dismissLicenseWindow();
            }

            doWorkOnErrorClick: function() {
                ActionProvider.showLicenseDialog();
            }
        }

        MainWindowError {
            id: updateAvailable

            property bool show: (AppState.updateInfo || AppState.showTeamUpdateWindow)
                     && (!AppFeatures.infoWindowOn || AppState.showTeamUpdateWindow)

            anchors.fill: parent
            info: qsTrId("update_window_has_new_version") + Translator.translate
            visible: false

            onShowChanged: {
                if (show) {
                    errorLayer.visible = true;
                    updateAvailable.visible = !licenseError.visible;
                    sipRegError.visible = false;
                    callMakeError.visible = false;
                    invalidAudioDeviceError.visible = false;
                } else {
                    errorLayer.clear();
                    ActionProvider.dismissUpdateWindow();
                    errorLayer.openFirstError("update");
                }
            }

            doWorkOnButtonClick: function() {
                errorLayer.clear();
                ActionProvider.dismissUpdateWindow();
            }

            doWorkOnErrorClick: function() {
                ActionProvider.showUpdateDialog();
            }
        }
    }
}
