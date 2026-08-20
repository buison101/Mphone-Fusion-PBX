import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Dialogs 1.3
import Flux 1.0

import "../../uicontrols"

ScrollView {
    id: root

    property int fontSize: 11
    property int marginValue: 20

    contentItem: Flickable {
        id: flickable

        ScrollBar.vertical: ScrollBar {}

        contentHeight: height
        boundsBehavior: Flickable.StopAtBounds

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
                            + bookSourceNameField.height + marginValue / 2
                            + bookSourceGroupLocalButton.height + marginValue
                            + bookSourceLocalField.height + marginValue
                            + bookUpdateTimeoutSpinbox.height + marginValue
                            + officePBX.height + marginValue
                    width: parent.width

                    title: qsTrId("settings_contacts_xml_file") + Translator.translate

                    Label {
                        id: description

                        anchors.top: parent.top
                        anchors.topMargin: marginValue
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue
                        anchors.right: parent.right
                        anchors.rightMargin: marginValue

                        text: qsTrId("settings_contacts_xml_file_description").arg(StringStorage.appTitle).arg(StringStorage.getHelpImportXMLContactsURL(SettingsState.languageIsoCode)) + Translator.translate

                        wrapMode: Text.WordWrap
                        font.pixelSize: fontSize

                        onLinkActivated: Qt.openUrlExternally(link)

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.NoButton
                            cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                        }
                    }

                    ButtonGroup {
                        id: bookSourceGroup
                    }

                    Label {
                        id: bookNameLabel

                        anchors.top: description.bottom
                        anchors.topMargin: marginValue
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue

                        font.pixelSize: fontSize
                        text: qsTrId("settings_contacts_xml_file_book_name") + Translator.translate
                    }

                    SettingsTextField {
                        id: bookSourceNameField

                        anchors.verticalCenter: bookNameLabel.verticalCenter
                        anchors.left: bookSourceGroupLocalButton.right
                        anchors.leftMargin: marginValue

                        width: 150

                        property string name: SettingsState.xmlFileContactAccount ? SettingsState.xmlFileContactAccount.name : ""

                        text: name

                        onTextChanged: {
                            if (text != name) {
                                ActionProvider.markContactAccountUpdate(ContactType.CiscoXml, ContactAccount.Name, text);
                            }
                        }

                        onNameChanged: {
                            text = name;
                        }
                    }

                    SettingsRadioButton {
                        id: bookSourceGroupLocalButton

                        anchors.top: bookNameLabel.bottom
                        anchors.topMargin: marginValue
                        anchors.left: bookNameLabel.left

                        text: qsTrId("settings_contacts_xml_file_local") + Translator.translate
                        ButtonGroup.group: bookSourceGroup

                        property bool selected: SettingsState.xmlFileContactAccount &&
                                                SettingsState.xmlFileContactAccount.locationType == ContactAccount.LocationLocal

                        checked: selected

                        onSelectedChanged: {
                            checked = selected;
                        }

                        onCheckedChanged: {
                            if (checked != selected) {
                                ActionProvider.markContactAccountUpdate(ContactType.CiscoXml, ContactAccount.LocationType,
                                                                        checked ? ContactAccount.LocationLocal : ContactAccount.LocationHTTP);
                            }
                        }

                        font.pixelSize: fontSize
                    }

                    SettingsTextField {
                        id: bookSourceLocalField

                        anchors.verticalCenter: bookSourceGroupLocalButton.verticalCenter
                        anchors.left: bookSourceNameField.left

                        enabled: bookSourceGroupLocalButton.checked
                        width: bookSourceNameField.width
                        readOnly: true

                        property int locationType: SettingsState.xmlFileContactAccount ? SettingsState.xmlFileContactAccount.locationType : ContactAccount.LocationUnknown
                        property string location: SettingsState.xmlFileContactAccount ? SettingsState.xmlFileContactAccount.locationLocal : ""

                        onTextChanged: {
                            if (text != location) {
                                ActionProvider.markContactAccountUpdate(ContactType.CiscoXml, ContactAccount.Location, text);
                                bookSourceLocalField.cursorPosition = 0;
                            }
                        }

                        onLocationChanged: {
                            text = location;
                        }

                        onVisibleChanged:  {
                            if (visible) {
                                bookSourceLocalField.cursorPosition = 0;
                            }
                        }
                    }

                    SettingsButton {
                        id: localSourceButton

                        anchors.verticalCenter: bookSourceLocalField.verticalCenter
                        anchors.left: bookSourceLocalField.right
                        anchors.leftMargin: marginValue

                        enabled: bookSourceGroupLocalButton.checked

                        text: qsTrId("settings_contacts_xml_file_local_button") + Translator.translate

                        onClicked: {
                            fileDialogLoader.sourceComponent = fileDialogComponent;
                        }
                    }

                    SettingsRadioButton {
                        id: bookSourceGroupHttpButton

                        text: qsTrId("settings_contacts_xml_file_http") + Translator.translate
                        ButtonGroup.group: bookSourceGroup

                        anchors.top: bookSourceGroupLocalButton.bottom
                        anchors.topMargin: marginValue / 2
                        anchors.left: bookSourceGroupLocalButton.left

                        checked: SettingsState.xmlFileContactAccount && !bookSourceGroupLocalButton.checked

                        font.pixelSize: fontSize
                    }

                    SettingsTextField {
                        width: bookSourceNameField.width

                        enabled: bookSourceGroupHttpButton.checked

                        anchors.verticalCenter: bookSourceGroupHttpButton.verticalCenter
                        anchors.left: bookSourceLocalField.left

                        property int locationType: SettingsState.xmlFileContactAccount ? SettingsState.xmlFileContactAccount.locationType : ContactAccount.LocationUnknown
                        property string location: SettingsState.xmlFileContactAccount ? SettingsState.xmlFileContactAccount.locationHttp : ""

                        onTextChanged: {
                            if (text != location) {
                                ActionProvider.markContactAccountUpdate(ContactType.CiscoXml, ContactAccount.Location, text);
                            }
                        }

                        onLocationChanged: {
                            text = location;
                        }

                        onVisibleChanged:  {
                            if (visible) {
                                bookSourceLocalField.cursorPosition = 0;
                            }
                        }
                    }

                    Label {
                        id: bookUpdateTimeoutLabel

                        anchors.top: bookSourceGroupHttpButton.bottom
                        anchors.topMargin: marginValue
                        anchors.left: bookSourceGroupLocalButton.left

                        text: qsTrId("settings_contacts_xml_reload_timeout") + Translator.translate
                        font.pixelSize: fontSize
                    }

                    SettingsSpinBox {
                        id: bookUpdateTimeoutSpinbox

                        anchors.verticalCenter: bookUpdateTimeoutLabel.verticalCenter
                        anchors.left: bookSourceLocalField.left

                        height: 30
                        width: 150

                        from: 0
                        to: 100000

                        property int updateTimeout: SettingsState.xmlFileContactAccount ? SettingsState.xmlFileContactAccount.updateTimeoutMinutes : 0

                        value: updateTimeout

                        onValueChanged: {
                            if (value != updateTimeout) {
                                ActionProvider.markContactAccountUpdate(ContactType.CiscoXml, ContactAccount.UpdateTimeout, value);
                            }
                        }

                        onUpdateTimeoutChanged: {
                            value = updateTimeout;
                        }
                    }

                    SettingsGroupBox {
                        id: officePBX

                        anchors.top: bookUpdateTimeoutLabel.bottom
                        anchors.topMargin: marginValue
                        anchors.left: parent.left
                        anchors.leftMargin: marginValue
                        anchors.right: parent.right
                        anchors.rightMargin: marginValue

                        height: callForwardUseLabel.height + marginValue
                                + callForwardUseDescLabel.height + marginValue / 2
                                + getContactInfoLabel.height + marginValue
                                + getContactInfoDescLabel.height + marginValue / 2
                                + accountCombobox.height + marginValue + marginValue
                        width: parent.width

                        title: qsTrId("settings_contacts_xml_advanced") + Translator.translate


                        SettingsCheckBox {
                            id: callForwardUseCheckbox

                            anchors.top: parent.top
                            anchors.topMargin: marginValue
                            anchors.left: parent.left
                            anchors.leftMargin: marginValue

                            property bool useForCallTransfer: SettingsState.xmlFileContactAccount ? SettingsState.xmlFileContactAccount.useForCallTransfer : false

                            checked: useForCallTransfer

                            onCheckedChanged: {
                                if (checked != useForCallTransfer) {
                                    ActionProvider.markContactAccountUpdate(ContactType.CiscoXml, ContactAccount.UseForTransfer, checked);
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

                            property bool subscribeForEvents: SettingsState.xmlFileContactAccount ? SettingsState.xmlFileContactAccount.subscribeForEvents : false

                            checked: subscribeForEvents

                            onCheckedChanged: {
                                if (checked != subscribeForEvents) {
                                    ActionProvider.markContactAccountUpdate(ContactType.CiscoXml, ContactAccount.UseForPresense, checked);
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

                            property int accountId: SettingsState.xmlFileContactAccount ? SettingsState.xmlFileContactAccount.sipAccountId : 0

                            font.pixelSize: fontSize

                            onCurrentIndexChanged: {
                                if (currentIndex != accountId) {
                                    ActionProvider.markContactAccountUpdate(ContactType.CiscoXml, ContactAccount.PresenceSipAccount, currentIndex);
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
                    nameFilters: [ "Xml files (*.xml)"]

                    onAccepted: {
                        fileDialogLoader.sourceComponent = null;
                        ActionProvider.markContactAccountUpdate(ContactType.CiscoXml, ContactAccount.Location, fileDialog.fileUrl);
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
