import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Dialogs 1.3
import Flux 1.0

import "../../uicontrols"

ScrollView {
    id: root

    property int fontSize: 11
    property int marginValue: 20

    Flickable {
        id: flickable

        ScrollBar.vertical: ScrollBar {}

        contentHeight: height
        boundsBehavior: Flickable.StopAtBounds

        clip: true

        Rectangle {
            id: background

            anchors.fill: parent

            color: ColorStorage.settingsWindowBaseColor

            Rectangle {
                id: offset

                anchors.top: parent.top
                anchors.topMargin: marginValue
                anchors.left: parent.left
                anchors.leftMargin: marginValue
                anchors.right: parent.right
                anchors.rightMargin: marginValue

                height: groupbox.height

                color: ColorStorage.settingsWindowBaseColor

                SettingsGroupBox {
                    id: groupbox

                    width: parent.width
                    height: sourceCombobox.height + marginValue
                            + importSourceLoader.sourceHeight + marginValue
                            + officePBX.height + marginValue

                    title: qsTrId("settings_contacts_import") + Translator.translate

                    Row {
                        id: importSourceSelection

                        anchors.top: parent.top
                        anchors.topMargin: marginValue
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue
                        anchors.right: parent.right
                        anchors.rightMargin: marginValue

                        spacing: marginValue

                        Label {
                            anchors.verticalCenter: sourceCombobox.verticalCenter
                            text: qsTrId("settings_contacts_import_source") + Translator.translate
                            font.pixelSize: fontSize
                        }

                        SettingsComboBox {
                            id: sourceCombobox

                            width: 150

                            enabled: SettingsState.contactsImportStatus != ContactImportStatus.Processing

                            model: SettingsState.contactsImportTypeModel
                            textRole: "name"

                            font.pixelSize: fontSize

                            property int contactsImportTypeModelSelectedIdx: SettingsState.contactsImportTypeModelSelectedIdx

                            currentIndex: contactsImportTypeModelSelectedIdx

                            onCurrentIndexChanged:  {
                                if (currentIndex != contactsImportTypeModelSelectedIdx) {
                                    ActionProvider.markContactImportUpdate(AppConfig.Language,
                                                                       SettingsState.contactsImportTypeModel.getAssociatedValue(currentIndex));
                                }
                            }

                            onContactsImportTypeModelSelectedIdxChanged: {
                                currentIndex = contactsImportTypeModelSelectedIdx;
                            }
                        }
                    }

                    Component {
                        id: csvSourceComponent

                        Item {
                            height: description.height + description.anchors.topMargin +
                                    localSourceButton.height + sourceLocalLabel.anchors.topMargin +
                                    (stateLabel.verticalAlignment ? stateLabel.height + stateLabel.anchors.topMargin : 0)

                            Label {
                                id: description

                                anchors.top: parent.top
                                anchors.topMargin: marginValue
                                width: parent.width

                                text: qsTrId("settings_contacts_import_csv_description").arg(StringStorage.appTitle).arg(StringStorage.getHelpImportCSVContactsURL(SettingsState.languageIsoCode)) + Translator.translate

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
                                id: sourceLocalLabel

                                anchors.top: description.bottom
                                anchors.topMargin: marginValue
                                anchors.left: description.left

                                font.pixelSize: fontSize

                                text: qsTrId("settings_contacts_xml_file_local") + Translator.translate
                            }

                            SettingsTextField {
                                id: sourceLocalField

                                anchors.verticalCenter: sourceLocalLabel.verticalCenter
                                anchors.left: sourceLocalLabel.right
                                anchors.leftMargin: marginValue

                                width: 170
                                readOnly: true

                                text: SettingsState.contactsImportAccount ? SettingsState.contactsImportAccount.locationLocal : 0
                            }

                            SettingsButton {
                                id: localSourceButton

                                anchors.verticalCenter: sourceLocalField.verticalCenter
                                anchors.left: sourceLocalField.right
                                anchors.leftMargin: marginValue

                                enabled: SettingsState.contactsImportStatus != ContactImportStatus.Processing

                                text: qsTrId("settings_contacts_xml_file_local_button") + Translator.translate

                                width: importButton.width > implicitWidth ? importButton.width : implicitWidth

                                onClicked: {
                                    fileDialogLoader.sourceComponent = fileDialogComponent;
                                }
                            }

                            Item {
                                id: stateVisibility
                                visible: sourceLocalField.text
                            }

                            Label {
                                id: stateLabel

                                anchors.top: sourceLocalLabel.bottom
                                anchors.topMargin: visible ? marginValue : 0
                                anchors.left: parent.left

                                font.pixelSize: fontSize

                                visible: stateVisibility.visible

                                text: qsTrId("settings_contacts_import_state") + Translator.translate
                            }

                            Label {
                                id: stateDescriptionLabel

                                anchors.verticalCenter: stateLabel.verticalCenter
                                anchors.left: sourceLocalField.left

                                visible: stateVisibility.visible

                                font.pixelSize: fontSize

                                property int status: SettingsState.contactsImportStatus

                                text: {
                                    switch(status) {

                                    case ContactImportStatus.Awaiting:
                                        return qsTrId("settings_contacts_import_state_awaiting") + Translator.translate;

                                    case ContactImportStatus.Processing:
                                        return qsTrId("settings_contacts_import_state_processing") + Translator.translate;

                                    case ContactImportStatus.Ready:
                                        return qsTrId("settings_contacts_import_state_ready") + Translator.translate;

                                    case ContactImportStatus.FileOpenError:
                                        return qsTrId("settings_contacts_import_state_file_open_error") + Translator.translate;

                                    case ContactImportStatus.FormatError:
                                        return qsTrId("settings_contacts_import_state_format_error") + Translator.translate;

                                    case ContactImportStatus.UnknownError:
                                        return qsTrId("settings_contacts_import_state_unknown_error") + Translator.translate;
                                    }
                                }
                            }

                            BusyIndicator {
                                id: loadingIndicator

                                width: height
                                height: importButton.height

                                anchors.verticalCenter: importButton.verticalCenter
                                anchors.horizontalCenter: importButton.horizontalCenter

                                visible: SettingsState.contactsImportStatus == ContactImportStatus.Processing
                            }

                            SettingsButton {
                                id: importButton

                                anchors.verticalCenter: stateDescriptionLabel.verticalCenter
                                anchors.right: localSourceButton.right

                                visible: stateVisibility.visible && !loadingIndicator.visible
                                enabled: visible && SettingsState.contactsImportStatus != ContactImportStatus.Ready

                                text: qsTrId("settings_contacts_import_button") + Translator.translate

                                font.pixelSize: fontSize

                                onClicked: {
                                    ActionProvider.importContacts();
                                }
                            }
                        }
                    }

                    Loader {
                        id: importSourceLoader

                        anchors.top: importSourceSelection.top
                        anchors.topMargin: marginValue
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue
                        anchors.right: parent.right
                        anchors.rightMargin: marginValue

                        height: item ? item.height : 0

                        property int sourceWidth: (item !== null && typeof(item)!== 'undefined')? item.width : 0
                        property int sourceHeight: (item !== null && typeof(item)!== 'undefined')? item.height: 0

                        sourceComponent: csvSourceComponent
                    }

                    SettingsGroupBox {
                        id: officePBX

                        anchors.top: importSourceLoader.bottom
                        anchors.topMargin: marginValue
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue
                        anchors.right: parent.right
                        anchors.rightMargin: marginValue

                        height: callForwardUseLabel.height + marginValue
                                + callForwardUseDescLabel.height + marginValue / 2
                                + getContactInfoLabel.height + marginValue
                                + getContactInfoDescLabel.height + marginValue / 2
                                + accountCombobox.height + marginValue
                                + marginValue
                        width: parent.width

                        title: qsTrId("settings_contacts_xml_advanced") + Translator.translate

                        SettingsCheckBox {
                            id: callForwardUseCheckbox

                            anchors.top: parent.top
                            anchors.topMargin: marginValue
                            anchors.left: parent.left
                            anchors.leftMargin: marginValue

                            property bool useForCallTransfer: SettingsState.contactsImportAccount ?
                                                                  SettingsState.contactsImportAccount.useForCallTransfer : false

                            checked: useForCallTransfer

                            onCheckedChanged: {
                                if (checked != useForCallTransfer) {
                                    ActionProvider.markContactImportUpdate(ContactType.Csv, ContactAccount.UseForTransfer, checked);
                                }
                            }

                            onUseForCallTransferChanged: {
                                checked = useForCallTransfer;
                            }
                        }

                        Label {
                            id: callForwardUseLabel

                            anchors.left: callForwardUseCheckbox.right
                            anchors.leftMargin: marginValue
                            anchors.verticalCenter: callForwardUseCheckbox.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: marginValue

                            font.pixelSize: fontSize

                            text: qsTrId("dialog_new_contact_call_forward_use") + Translator.translate
                        }

                        Label {
                            id: callForwardUseDescLabel

                            anchors.top: callForwardUseLabel.bottom
                            anchors.topMargin: marginValue / 2
                            anchors.left: callForwardUseLabel.left
                            anchors.right: parent.right
                            anchors.rightMargin: marginValue

                            wrapMode: Text.WordWrap

                            font.pixelSize: fontSize

                            text: qsTrId("dialog_new_contact_call_forward_use_desc") + Translator.translate
                        }

                        SettingsCheckBox {
                            id: getContactInfoCheckbox

                            anchors.top: callForwardUseDescLabel.bottom
                            anchors.topMargin: marginValue
                            anchors.left: parent.left
                            anchors.leftMargin: marginValue

                            property bool subscribeForEvents: SettingsState.contactsImportAccount ?
                                                                  SettingsState.contactsImportAccount.subscribeForEvents : 0

                            checked: subscribeForEvents

                            onCheckedChanged: {
                                if (checked != subscribeForEvents) {
                                    ActionProvider.markContactImportUpdate(ContactType.Csv, ContactAccount.UseForPresense, checked);
                                }
                            }

                            onSubscribeForEventsChanged: {
                                checked = subscribeForEvents;
                            }
                        }

                        Label {
                            id: getContactInfoLabel

                            anchors.left: getContactInfoCheckbox.right
                            anchors.leftMargin: marginValue
                            anchors.verticalCenter: getContactInfoCheckbox.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: marginValue

                            font.pixelSize: fontSize

                            text: qsTrId("dialog_new_contact_get_contact_info") + Translator.translate
                        }

                        Label {
                            id: getContactInfoDescLabel

                            anchors.top: getContactInfoLabel.bottom
                            anchors.topMargin: marginValue / 2
                            anchors.left: getContactInfoLabel.left
                            anchors.right: parent.right
                            anchors.rightMargin: marginValue

                            wrapMode: Text.WordWrap
                            font.pixelSize: fontSize

                            text: qsTrId("dialog_new_contact_get_contact_info_desc") + Translator.translate
                        }

                        Label {
                            id: accountLabel

                            anchors.top: getContactInfoDescLabel.bottom
                            anchors.topMargin: marginValue
                            anchors.left: getContactInfoDescLabel.left

                            enabled: getContactInfoCheckbox.checked
                            font.pixelSize: fontSize

                            text: qsTrId("dialog_new_contact_account") + Translator.translate
                        }

                        Label {
                            id: accountLabelAsterisk

                            anchors.left: accountLabel.right
                            anchors.leftMargin: 1
                            anchors.baseline: accountLabel.baseline

                            enabled: getContactInfoCheckbox.checked
                            font.pixelSize: fontSize

                            text: "*"
                            color: "red"
                        }

                        SettingsComboBox {
                            id: accountCombobox

                            anchors.left: accountLabelAsterisk.right
                            anchors.leftMargin: marginValue
                            anchors.verticalCenter: accountLabel.verticalCenter

                            width: 120

                            enabled: getContactInfoCheckbox.checked

                            textRole: "name"
                            model: AppState.sipAccountModel

                            property int accountId: SettingsState.contactsImportAccount ?
                                                        SettingsState.contactsImportAccount.sipAccountId : 0

                            font.pixelSize: fontSize

                            onCurrentIndexChanged: {
                                if (currentIndex != accountId) {
                                    ActionProvider.markContactImportUpdate(ContactType.Csv, ContactAccount.PresenceSipAccount, currentIndex);
                                }
                            }

                            onAccountIdChanged: {
                                currentIndex = accountId;
                            }
                        }
                    }
                }
            }

            Component {
                id: fileDialogComponent

                FileDialog {
                    id: fileDialog

                    title: qsTrId("settings_contacts_xml_choose_file") + Translator.translate

                    folder: shortcuts.home

                    nameFilters: {
                        var i = SettingsState.contactsImportTypeModel.getItemAssociatedValue(sourceCombobox.currentIndex);

                        switch(i) {
                        case ContactType.Csv:
                            return [ "CSV files (*.csv)"];
                        }

                        return [];
                    }

                    onAccepted: {
                        fileDialogLoader.sourceComponent = null;
                        ActionProvider.markContactImportUpdate(ContactType.Csv, ContactAccount.Location, fileDialog.fileUrl);
                    }

                    onRejected: {
                        fileDialogLoader.sourceComponent = null;
                    }

                    Component.onCompleted: visible = true
                }
            }

            Loader {
                id: fileDialogLoader
            }
        }
    }
}
