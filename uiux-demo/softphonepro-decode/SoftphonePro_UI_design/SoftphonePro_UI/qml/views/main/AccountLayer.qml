import QtQuick 2.15
import Flux 1.0

import "../uicontrols"

FocusScope {
    id: root

    property var resetFocus: function() {
        account.focus = true;
    }

    property var requestAccountFocus: function() {
        resetFocus();
        account.forceActiveFocus();
    }

    property var openDropdown: function() {
        if (account.dropdownVisible) {
                account.closeDropdown();
                account.forceActiveFocus();
        } else {
            account.openDropdown();
        }
    }

    property alias enableAccountSelection: account.enabled

    AccountButton {
        id: account

        Accessible.role: Accessible.Button
        Accessible.name: "AccountButton"

        anchors.right: parent.right
        anchors.rightMargin: 30

        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -2 * SettingsState.scale

        hoverWide: 160 * SettingsState.scale
        hoverHeigth: 26 * SettingsState.scale

        focus: true

        enabled: {
            return !AppState.instanceDisabled && visible && (!AppState.sipAccountsSettingsRestriction || accountsCount > 1 || (didsCount > 1));
        }

        showChevron: enabled

        selection: AppState.sipAccount
        selectionImage:  {
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

        selectionSize: 16 * SettingsState.scale
        selectionAlignment: Text.AlignRight

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
