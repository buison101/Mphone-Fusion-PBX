import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQml.Models 2.15
import Flux 1.0

import "../uicontrols"
import "contacts" as Contacts
import "integration" as Integration

FocusScope {
    id: root

    Shortcut {
        enabled: visible
        sequence: "Esc"

        onActivated: {
            ActionProvider.saveSettingsUpdates(false);
        }
    }

    Rectangle {
        anchors.fill: parent
        color: ColorStorage.settingsWindowBaseColor

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            color: "transparent"

            Component {
                id: treeviewComponent

                Rectangle {
                    id: settingsBorder

                    color: "#999999"

                    TreeView {
                        id: settingItems

                        anchors.fill: parent
                        anchors.rightMargin: 1
                        anchors.bottomMargin: 1

                        focus: true

                        headerVisible: false

                        model: SettingsState.settingsOptionModel

                        KeyNavigation.tab: settingScreensFocusScope

                        contentItem.width: maxItemWidth

                        property var settingsOptionExpandedItems: SettingsState.settingsOptionExpandedItems
                        property var nextSettingsOptionIdx: SettingsState.nextSettingsOptionIdx
                        property bool showCreateSipAccountSettingScreen: SettingsState.showCreateSipAccountSettingScreen
                        property bool showAllSipAccountsSettingScreen: SettingsState.showAllSipAccountsSettingScreen

                        property int maxItemWidth: width

                        onSettingsOptionExpandedItemsChanged: {
                            expandItems(settingsOptionExpandedItems);
                        }

                        onExpanded: {
                            ActionProvider.expandSettingOption(index);
                        }

                        onCollapsed: {
                            ActionProvider.collapseSettingOption(index);
                        }

                        onNextSettingsOptionIdxChanged: {
                            // change settings screen from C++ code on sip account changes discard
                            if (nextSettingsOptionIdx.valid && settingItems.selection.model) {
                                settingItems.selection.setCurrentIndex(nextSettingsOptionIdx, ItemSelectionModel.SelectCurrent);
                            }
                        }

                        onShowCreateSipAccountSettingScreenChanged: {
                            // change settings screen from C++ code on sip account creation
                            settingScreens.currentIndex = settingScreens.sipAccountScreen;
                        }

                        onShowAllSipAccountsSettingScreenChanged: {
                            // change settings screen from C++ code on saved sip account change
                            settingItems.selection.setCurrentIndex(SettingsState.allSipAccountsSettingsOptionIdx, ItemSelectionModel.SelectCurrent);
                        }

                        function expandItems(items) {
                            for (var i = 0; i < items.length; ++i) {
                                settingItems.expand(items[i]);
                            }
                        }

                        property int integrationClipboardRowIdx: 0
                        property int integrationExcelAddinRowIdx: 0
                        property int integrationGoogleSheetsIdx: 0
                        property int integrationAmoCrmRowIdx: 0
                        property int integrationZendeskRowIdx: 0
                        property int integrationZohoCrmRowIdx: 0
                        property int integrationZohoDeskCrmRowIdx: 0
                        property int integrationHubspotCrmRowIdx: 0
                        property int integrationPipedriveCrmRowIdx: 0
                        property int integrationBitrix24CrmRowIdx: 0
                        property int integrationCrm1CRowIdx: 0
                        property int integrationNutshellCrmRowIdx: 0
                        property int integrationFreshdeskCrmRowIdx: 0
                        property int integrationMicrosoftDynamicsCrmRowIdx: 0
                        property int integrationSalesforceCrmRowIdx: 0
                        property int integrationClioRowIdx: 0
                        property int integrationCapsuleCrmRowIdx: 0
                        property int integrationSuiteCrmRowIdx: 0
                        property int integrationPipelineCrmRowIdx: 0
                        property int integrationLessAnnoyingCrmRowIdx: 0

                        property int integrationCrmRowIdx: 0
                        property int integrationLinkProcessRowIdx: 0
                        property int integrationExternalSystemsRowIdx: 0

                        property int contactsGoogleContactsRowIdx: 0
                        property int contactsXmlFileRowIdx: 1
                        property int contactsImportRowIdx: 2


                        Component.onCompleted:  {
                            // update indexes based on features
                            var idx = 0;

                            if (!AppFeatures.hideClipboard) {
                                integrationClipboardRowIdx = idx;
                                idx += 1;
                            }

                            if (!AppFeatures.hideExcelIntegration) {
                                integrationExcelAddinRowIdx = idx;
                                idx += 1;
                            }

                            if (!AppFeatures.hideGoogleSheets) {
                                integrationGoogleSheetsIdx = idx;
                                idx += 1;
                            }

                            if (!AppFeatures.hideCrm) {
                                if (!AppFeatures.hideRussianCrm) {
                                    integrationAmoCrmRowIdx = idx;
                                    idx += 1;
                                }

                                integrationZendeskRowIdx = idx;
                                idx += 1;

                                integrationZohoCrmRowIdx = idx;
                                idx += 1;

                                integrationZohoDeskCrmRowIdx = idx;
                                idx += 1;

                                integrationHubspotCrmRowIdx = idx;
                                idx += 1;

                                integrationPipedriveCrmRowIdx = idx;
                                idx += 1;

                                if (!AppFeatures.hideRussianCrm) {
                                    integrationBitrix24CrmRowIdx = idx;
                                    idx += 1;

                                    integrationCrm1CRowIdx = idx;
                                    idx += 1;
                                }

                                integrationNutshellCrmRowIdx = idx;
                                idx += 1;

                                integrationFreshdeskCrmRowIdx = idx;
                                idx += 1;

                                integrationMicrosoftDynamicsCrmRowIdx = idx;
                                idx += 1;

                                integrationSalesforceCrmRowIdx = idx;
                                idx +=1;

                                integrationClioRowIdx = idx;
                                idx +=1;

                                integrationCapsuleCrmRowIdx = idx;
                                idx +=1;

                                integrationSuiteCrmRowIdx = idx;
                                idx += 1;

                                integrationPipelineCrmRowIdx = idx;
                                idx += 1;

                                if (AppFeatures.lessAnnoyingCrm) {
                                    integrationLessAnnoyingCrmRowIdx = idx;
                                    idx += 1;
                                }
                            }

                            if (!AppFeatures.hideSimpleCalls) {
                                integrationCrmRowIdx = idx;
                                idx += 1;
                            }

                            if (!AppFeatures.hideProtocolHandlers) {
                                integrationLinkProcessRowIdx = idx;
                                idx += 1;
                            }

                            if (!AppFeatures.hideExternalAppIntegration) {
                                integrationExternalSystemsRowIdx = idx;
                                idx += 1;
                            }
                        }

                        function getSettingScreen(index, row) {
                            if (!index.valid) {
                                return settingScreens.generalScreen;
                            }

                            if (!index.parent.valid) {
                                // top level items
                                //switch(index.row) {
                                switch(row) {

                                case OptionsModel.General:
                                    return settingScreens.generalScreen;

                                case OptionsModel.Interface:
                                    return settingScreens.interfaceScreen;

                                case OptionsModel.Notifications: {
                                    if (!AppFeatures.hideEmailNotifications) {
                                        return settingScreens.notificationsScreen;
                                    } else {
                                        return null;
                                    }
                                }

                                case OptionsModel.CallForwarding: {
                                    if (!AppFeatures.hideCallForwarding){
                                         return settingScreens.forwardingScreen;
                                    } else {
                                        return null;
                                    }
                                }


                                case OptionsModel.Sip:
                                    return settingScreens.sipScreen;

                                case OptionsModel.AllSipAccounts:
                                    return settingScreens.allSipAccountsScreen;

                                case OptionsModel.AllMessageSettings:
                                    return settingScreens.messageSettingsScreen;

                                case OptionsModel.Prerecorded:
                                    return settingScreens.prerecordedAudioScreen;

                                case OptionsModel.License:
                                    return settingScreens.licenseScreen;
                                }
                            }
                            else {
                                if (index.parent.row == OptionsModel.AllSipAccounts - SettingsState.hidedSettingsBeforeSipAccountCount) {
                                    return settingScreens.sipAccountScreen;
                                }
                                else if (index.parent.row == OptionsModel.Contacts - SettingsState.hidedSettingsBeforeContactsCount) {
                                    if (index.row == contactsGoogleContactsRowIdx) {
                                        return settingScreens.contactsGoogleContacts;
                                    }
                                    else if (index.row == contactsXmlFileRowIdx) {
                                        return settingScreens.contactsXmlFile;
                                    }
                                    else if (index.row == contactsImportRowIdx) {
                                        return settingScreens.contactsImport;
                                    }
                                }
                                else if (index.parent.row == OptionsModel.Integration - SettingsState.hidedSettingsBeforeIntegrationCount) {
                                    if (index.row == integrationClipboardRowIdx && !AppFeatures.hideClipboard) {
                                        return settingScreens.integrationClipboardScreen;
                                    }
                                    else if (index.row == integrationExcelAddinRowIdx && !AppFeatures.hideExcelIntegration) {
                                        return settingScreens.integrationExcelAddinScreen;
                                    }
                                    else if (index.row == integrationGoogleSheetsIdx && !AppFeatures.hideGoogleSheets) {
                                        return settingScreens.integrationGoogleSheets;
                                    }
                                    else if (index.row == integrationAmoCrmRowIdx && !AppFeatures.hideRussianCrm && !AppFeatures.hideCrm) {
                                        return settingScreens.integrationAmoCrmScreen;
                                    }
                                    else if (index.row == integrationZendeskRowIdx && !AppFeatures.hideCrm) {
                                        return settingScreens.integrationZendeskScreen;
                                    }
                                    else if (index.row == integrationZohoCrmRowIdx && !AppFeatures.hideCrm) {
                                        return settingScreens.integrationZohoCrmScreen;
                                    }
                                    else if (index.row == integrationZohoDeskCrmRowIdx && !AppFeatures.hideCrm) {
                                        return settingScreens.integrationZohoDeskCrmScreen;
                                    }
                                    else if (index.row == integrationHubspotCrmRowIdx && !AppFeatures.hideCrm) {
                                        return settingScreens.integrationHubspotCrmScreen;
                                    }
                                    else if (index.row == integrationPipedriveCrmRowIdx && !AppFeatures.hideCrm) {
                                        return settingScreens.integrationPipedriveCrmScreen;
                                    }
                                    else if (index.row == integrationBitrix24CrmRowIdx && !AppFeatures.hideRussianCrm && !AppFeatures.hideCrm) {
                                        return settingScreens.integrationBitrix24CrmScreen;
                                    } 
                                    else if (index.row == integrationCrm1CRowIdx && !AppFeatures.hideRussianCrm && !AppFeatures.hideCrm) {
                                        return settingScreens.integrationCrm1CScreen;
                                    }
                                    else if (index.row == integrationNutshellCrmRowIdx && !AppFeatures.hideCrm) {
                                        return settingScreens.integrationNutshellCrmScreen;
                                    }
                                    else if (index.row == integrationFreshdeskCrmRowIdx && !AppFeatures.hideCrm) {
                                        return settingScreens.integrationFreshdeskCrmScreen;
                                    }
                                    else if (index.row == integrationMicrosoftDynamicsCrmRowIdx && !AppFeatures.hideCrm) {
                                        return settingScreens.integrationMicrosoftDynamicsCrmScreen;
                                    }
                                    else if (index.row == integrationSalesforceCrmRowIdx && !AppFeatures.hideCrm) {
                                        return settingScreens.integrationSalesforceCrmScreen;
                                    }
                                    else if (index.row == integrationClioRowIdx && !AppFeatures.hideCrm) {
                                        return settingScreens.integrationClioScreen;
                                    }
                                    else if (index.row == integrationCapsuleCrmRowIdx && !AppFeatures.hideCrm) {
                                        return settingScreens.integrationCapsuleCrmScreen;
                                    }
                                    else if (index.row == integrationSuiteCrmRowIdx && !AppFeatures.hideCrm) {
                                        return settingScreens.integrationSuiteCrmScreen;
                                    }
                                    else if (index.row == integrationPipelineCrmRowIdx && !AppFeatures.hideCrm) {
                                        return settingScreens.integrationPipelineCrmScreen;
                                    }
                                    else if (index.row == integrationLessAnnoyingCrmRowIdx && !AppFeatures.hideCrm) {
                                        return settingScreens.integrationLessAnnoyingCrmScreen;
                                    }
                                    else if (index.row == integrationCrmRowIdx && !AppFeatures.hideSimpleCalls) {
                                        return settingScreens.integrationCrmScreen;
                                    }
                                    else if (index.row == integrationLinkProcessRowIdx && !AppFeatures.hideProtocolHandlers) {
                                        return settingScreens.integrationLinkProcessScreen;
                                    }
                                    else if (index.row == integrationExternalSystemsRowIdx) {
                                        return settingScreens.integrationExternalSystemsScreen;
                                    }
                                }
                            }

                            return null;
                        }

                        TableViewColumn {
                            role: "name"
                            width: settingItems.maxItemWidth
                        }

                        itemDelegate: Rectangle {
                            height: 30
                            width: settingItems.maxItemWidth

                            color: "transparent"

                            property bool isSelected: styleData.selected

                            onIsSelectedChanged: {
                                if (isSelected && !styleData.hasActiveFocus) {
                                    forceActiveFocus();
                                }
                            }

                            MouseArea {
                                anchors.fill: parent

                                onClicked: {
                                    // if current screen is NOT Sip Account screen => just change current screen
                                    if (settingScreens.currentIndex != settingScreens.sipAccountScreen
                                            && !settingItems.showCreateSipAccountSettingScreen) {
                                        settingItems.selection.setCurrentIndex(styleData.index, ItemSelectionModel.SelectCurrent);
                                        return;
                                    }

                                    // else use confirm dialog to change current screen
                                    ActionProvider.tryDiscardSipAccountChanges(styleData.index);
                                }
                            }

                            Label {
                                id: optionLabel

                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left

                                text: styleData.value
                                font.pixelSize: 11
                            }
                        }

                        rowDelegate: Rectangle {
                            width: settingItems.maxItemWidth
                            height: 30

                            color: "transparent"

                            Rectangle {
                                anchors.fill: parent
                                anchors.rightMargin: 9
                                color: styleData.selected ? "lightsteelblue" : "transparent"
                            }
                        }

                        Rectangle{
                            height: settingItems.height + 2
                            width: 10

                            anchors.right:  parent.right
                            anchors.top:  parent.top
                            anchors.topMargin: -1
                            anchors.rightMargin: -1

                            color: "transparent"
                            border.color: "#999999"
                            border.width: 1
                        }

                        selection: ItemSelectionModel {
                            id: selectionModel

                            model: settingItems.model

                            onCurrentChanged: {
                                var optionIdx = SettingsState.settingsOptionModel.getOptionIdx(current.row);
                                var screenIdx = settingItems.getSettingScreen(current, optionIdx);

                                if (screenIdx == null) {
                                    return;
                                }

                                if (screenIdx == settingScreens.sipAccountScreen) {
                                    ActionProvider.editSipAccount(current.row);
                                }

                                settingScreens.currentIndex = screenIdx;
                            }
                        }
                    }
                }
            }

            Loader {
                id: treeviewLoader

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.bottom: settingScreensBorder.bottom

                width: 280

                property string lang: qsTrId("settings_window_title") + Translator.translate
                onLangChanged: {
                    treeviewLoader.sourceComponent = null;
                    treeviewLoader.sourceComponent = treeviewComponent;
                }
            }

            Rectangle {
                id: settingScreensBorder

                anchors.top: parent.top
                anchors.left: treeviewLoader.right
                anchors.right: parent.right
                anchors.bottom: cancelButton.top
                anchors.bottomMargin: 20 * SettingsState.settingsWindowHeightScale

                color: "#999999"

                FocusScope {
                    id: settingScreensFocusScope

                    anchors.fill: parent

                    StackLayout {
                        id: settingScreens

                        anchors.fill: parent
                        anchors.bottomMargin: 1

                        readonly property int generalScreen: 0
                        readonly property int interfaceScreen: 1
                        readonly property int notificationsScreen: 2
                        readonly property int forwardingScreen: 3
                        readonly property int sipScreen: 4
                        readonly property int allSipAccountsScreen: 5
                        readonly property int sipAccountScreen: 6
                        readonly property int messageSettingsScreen: 7
                        readonly property int contactsGoogleContacts: 8
                        readonly property int contactsXmlFile: 9
                        readonly property int contactsImport: 10
                        readonly property int integrationClipboardScreen: 11
                        readonly property int integrationExcelAddinScreen: 12
                        readonly property int integrationGoogleSheets: 13
                        readonly property int integrationAmoCrmScreen: 14
                        readonly property int integrationZendeskScreen: 15
                        readonly property int integrationZohoCrmScreen: 16
                        readonly property int integrationZohoDeskCrmScreen: 17
                        readonly property int integrationHubspotCrmScreen: 18
                        readonly property int integrationPipedriveCrmScreen: 19
                        readonly property int integrationBitrix24CrmScreen: 20
                        readonly property int integrationCrm1CScreen: 21
                        readonly property int integrationNutshellCrmScreen: 22
                        readonly property int integrationFreshdeskCrmScreen: 23
                        readonly property int integrationMicrosoftDynamicsCrmScreen: 24
                        readonly property int integrationSalesforceCrmScreen: 25
                        readonly property int integrationClioScreen: 26
                        readonly property int integrationCapsuleCrmScreen: 27
                        readonly property int integrationSuiteCrmScreen: 28
                        readonly property int integrationPipelineCrmScreen: 29
                        readonly property int integrationLessAnnoyingCrmScreen: 30
                        readonly property int integrationCrmScreen: 31
                        readonly property int integrationLinkProcessScreen: 32
                        readonly property int integrationExternalSystemsScreen: 33
                        readonly property int prerecordedAudioScreen: 34
                        readonly property int licenseScreen: 35

                        ScreenGeneral {}

                        ScreenInterface {}

                        Component {
                            id: notificationsComponent

                            ScreenNotifications {
                            }
                        }

                        Loader {
                            id: notificationsLoader

                            sourceComponent: !AppFeatures.hideEmailNotifications ? notificationsComponent : null
                        }

                        Component {
                            id: forwardingComponent

                            ScreenForwarding {
                            }
                        }

                        Loader {
                            id: forwardingLoader

                            sourceComponent: (!AppFeatures.hideCallForwarding) ? forwardingComponent : null
                        }

                        ScreenSipSettings {}

                        ScreenAllSipAccounts {}

                        ScreenSipAccount { }

                        Component {
                            id: screenMessageSettingsComponent

                            ScreenMessageSettings {
                            }
                        }

                        Loader {
                            id: screenMessageSettingsLoader

                            sourceComponent: !AppFeatures.hideMessagingWindow
                                             ? screenMessageSettingsComponent : null
                        }

                        Component {
                            id: contactsGoogleContactsComponent

                            Contacts.ScreenGoogleContacts {
                            }
                        }

                        Loader {
                            id: contactsGoogleContactsLoader

                            sourceComponent: !AppFeatures.hideContactsSettings ? contactsGoogleContactsComponent : null
                        }

                        Component {
                            id: contactsXmlFileComponent

                            Contacts.ScreenXmlFile {
                            }
                        }

                        Loader {
                            id: contactsXmlFileLoader

                            sourceComponent: !AppFeatures.hideContactsSettings ? contactsXmlFileComponent : null
                        }

                        Component {
                            id: contactsImportComponent

                            Contacts.ScreenImport {
                            }
                        }

                        Loader {
                            id: contactsImportLoader

                            sourceComponent: !AppFeatures.hideContactsSettings ? contactsImportComponent : null
                        }

                        Component {
                            id: integrationClipboardComponent

                            Integration.ScreenClipboard {
                            }
                        }

                        Loader {
                            id: integrationClipboardLoader

                            sourceComponent: !AppFeatures.hideClipboard  && !AppFeatures.hideIntegrations
                                             ? integrationClipboardComponent : null
                        }

                        Component {
                            id: integrationExcelAddinComponent

                            Integration.ScreenExcelAddin {
                            }
                        }

                        Loader {
                            id: integrationExcelAddinLoader

                            sourceComponent: !AppFeatures.hideExcelIntegration  && !AppFeatures.hideIntegrations
                                             ? integrationExcelAddinComponent : null
                        }

                        Component {
                            id: integrationGoogleSheetsComponent

                            Integration.ScreenGoogleSheets {
                            }
                        }

                        Loader {
                            id: integrationGoogleSheetsLoader

                            sourceComponent: !AppFeatures.hideGoogleSheets && !AppFeatures.hideIntegrations
                                             ? integrationGoogleSheetsComponent : null
                        }

                        Component {
                            id: integrationAmoCrmComponent

                            Integration.ScreenAmoCrm {
                            }
                        }

                        Loader {
                            id: integrationAmoCrmLoader

                            sourceComponent: !AppFeatures.hideRussianCrm && !AppFeatures.hideCrm
                                             && !AppFeatures.hideIntegrations ? integrationAmoCrmComponent : null
                        }

                        Component {
                            id: integrationZendeskComponent

                            Integration.ScreenZendesk {
                            }
                        }

                        Loader {
                            id: integrationZendeskLoader

                            sourceComponent: !AppFeatures.hideCrm && !AppFeatures.hideIntegrations
                                             ? integrationZendeskComponent : null
                        }

                        Component {
                            id: integrationZohoCrmComponent

                            Integration.ScreenZohoCrm {
                            }
                        }

                        Loader {
                            id: integrationZohoCrmLoader

                            sourceComponent: !AppFeatures.hideCrm && !AppFeatures.hideIntegrations
                                             ? integrationZohoCrmComponent : null
                        }

                        Component {
                            id: integrationZohoDeskCrmComponent

                            Integration.ScreenZohoDeskCrm {
                            }
                        }

                        Loader {
                            id: integrationZohoDeskCrmLoader

                            sourceComponent: !AppFeatures.hideCrm && !AppFeatures.hideIntegrations
                                             ? integrationZohoDeskCrmComponent : null
                        }

                        Component {
                            id: integrationHubspotCrmComponent

                            Integration.ScreenHubspotCrm {}
                        }

                        Loader {
                            id: integrationHubspotCrmLoader

                            sourceComponent: !AppFeatures.hideCrm && !AppFeatures.hideIntegrations
                                             ? integrationHubspotCrmComponent : null
                        }

                        Component {
                            id: integrationPipedriveCrmComponent

                            Integration.ScreenPipedriveCrm {}
                        }

                        Loader {
                            id: integrationPipedriveCrmLoader

                            sourceComponent: !AppFeatures.hideCrm && !AppFeatures.hideIntegrations
                                             ? integrationPipedriveCrmComponent : null
                        }

                        Component {
                            id: integrationBitrix24CrmComponent

                            Integration.ScreenBitrixCrm {}
                        }

                        Loader {
                            id: integrationBitrix24CrmLoader

                            sourceComponent: !AppFeatures.hideRussianCrm && !AppFeatures.hideCrm
                                             && !AppFeatures.hideIntegrations ? integrationBitrix24CrmComponent : null
                        }

                        Component {
                            id: integrationCrm1CComponent

                            Integration.Screen1CCrm {}
                        }

                        Loader {
                            id: integrationCrm1CLoader

                            sourceComponent: !AppFeatures.hideRussianCrm && !AppFeatures.hideCrm
                                             && !AppFeatures.hideIntegrations ? integrationCrm1CComponent : null
                        }

                        Component {
                            id: integrationNutshellCrmComponent

                            Integration.ScreenNutshellCrm {}
                        }

                        Loader {
                            id: integrationNutshellCrmLoader

                            sourceComponent: !AppFeatures.hideCrm && !AppFeatures.hideIntegrations
                                             ? integrationNutshellCrmComponent : null
                        }

                        Component {
                            id: integrationFreshdeskCrmComponent

                            Integration.ScreenFreshdeskCrm {}
                        }

                        Loader {
                            id: integrationFreshdeskCrmLoader

                            sourceComponent: !AppFeatures.hideCrm && !AppFeatures.hideIntegrations
                                             ? integrationFreshdeskCrmComponent : null
                        }

                        Component {
                            id: integrationMicrosoftDyanimcsCrmComponent

                            Integration.ScreenMicrosoftDynamicsCrm {}
                        }

                        Loader {
                            id: integrationMicrosoftDyanimcsCrmLoader

                            sourceComponent: !AppFeatures.hideCrm && !AppFeatures.hideIntegrations
                                             ? integrationMicrosoftDyanimcsCrmComponent : null
                        }

                        Component {
                            id: integrationSalesforceCrmComponent

                            Integration.ScreenSalesforceCrm {}
                        }

                        Loader {
                            id: integrationSalesforceCrmLoader

                            sourceComponent: !AppFeatures.hideCrm && !AppFeatures.hideIntegrations
                                             ? integrationSalesforceCrmComponent : null
                        }

                        Component {
                            id: integrationClioComponent

                            Integration.ScreenClio {}
                        }

                        Loader {
                            id: integrationClioLoader

                            sourceComponent: !AppFeatures.hideCrm && !AppFeatures.hideIntegrations
                                             ? integrationClioComponent : null
                        }

                        Component {
                            id: integrationCapsuleCrmComponent

                            Integration.ScreenCapsuleCrm {
                            }
                        }

                        Loader {
                            id: integrationCapsuleCrmLoader

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            sourceComponent: !AppFeatures.hideCrm && !AppFeatures.hideIntegrations
                                             ? integrationCapsuleCrmComponent : null
                        }

                        Component {
                            id: integrationSuiteCrmComponent

                            Integration.ScreenSuiteCrm {}
                        }

                        Loader {
                            id: integrationSuiteCrmLoader

                            sourceComponent: !AppFeatures.hideCrm && !AppFeatures.hideIntegrations
                                             ? integrationSuiteCrmComponent : null
                        }

                        Component {
                            id: integrationPipelineCrmComponent

                            Integration.ScreenPipelineCrm {}
                        }

                        Loader {
                            id: integrationPipelineCrmLoader

                            sourceComponent: !AppFeatures.hideCrm && !AppFeatures.hideIntegrations
                                             ? integrationPipelineCrmComponent : null
                        }
                        
                        Component {
                            id: integrationLessAnnoyingCrmComponent

                            Integration.ScreenLessAnnoyingCrm {}
                        }

                        Loader {
                            id: integrationLessAnnoyingCrmLoader

                            sourceComponent: !AppFeatures.hideCrm && !AppFeatures.hideIntegrations
                                             ? integrationLessAnnoyingCrmComponent : null
                        }

                        Component {
                            id: integrationCrmComponent

                            Integration.ScreenSimpleCalls {
                            }
                        }

                        Loader {
                            id: integrationCrmLoader

                            sourceComponent: !AppFeatures.hideSimpleCalls && !AppFeatures.hideIntegrations
                                             ? integrationCrmComponent : null
                        }
                        
                        Component {
                            id: integrationLinkProcessComponent

                            Integration.ScreenLinkProcess {}
                        }

                        Loader {
                            id: integrationLinkProcessLoader

                            sourceComponent: !AppFeatures.hideProtocolHandlers && !AppFeatures.hideIntegrations
                                             ? integrationLinkProcessComponent : null
                        }

                        Component {
                            id: integrationExternalSystemsComponent

                            Integration.ScreenExternalSystems {}
                        }

                        Loader {
                            id: integrationExternalSystemsLoader

                            sourceComponent: !AppFeatures.hideExternalAppIntegration && !AppFeatures.hideIntegrations
                                             ? integrationExternalSystemsComponent : null
                        }

                        Component {
                            id: prerecordedAudioComponent

                            ScreenPrerecordedAudio {}
                        }

                        Loader {
                            id: prerecordedAudioLoader

                            sourceComponent: !AppFeatures.hidePrerecordedAudio ? prerecordedAudioComponent : null
                        }

                        Component {
                            id: licenseComponent

                            ScreenLicense {
                            }
                        }

                        Loader {
                            id: licenseLoader

                            sourceComponent: !AppFeatures.hideLicense ? licenseComponent : null
                        } 
                    }
                }
            }

            SettingsButton {
                id: saveButton

                anchors.verticalCenter: cancelButton.verticalCenter
                anchors.right: cancelButton.left
                anchors.rightMargin: 20

                text: qsTrId("dialog_button_save") + Translator.translate

                font.pixelSize: 11

                onClicked: {
                    ActionProvider.saveSettingsUpdates(true);
                    if (!AppState.activeCall && AppState.isRingtoneCurrentlyPlaying) {
                        ActionProvider.stopPlayRingtone();
                    }
                }
            }

            SettingsButton {
                id: cancelButton

                anchors.bottom: parent.bottom
                anchors.bottomMargin: 20 * SettingsState.settingsWindowHeightScale
                anchors.right: parent.right
                anchors.rightMargin: 20

                text: qsTrId("dialog_button_cancel") + Translator.translate

                font.pixelSize: 11

                onClicked: {
                    ActionProvider.saveSettingsUpdates(false);
                    if (!AppState.activeCall && AppState.isRingtoneCurrentlyPlaying) {
                        ActionProvider.stopPlayRingtone();
                    }
                }
            }
        }
    }
}
