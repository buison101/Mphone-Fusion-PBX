import QtQuick 2.15
import QtQuick.Controls 2.15
import Flux 1.0

import "../uicontrols"

Flickable {
    id: flickable

    contentHeight: height
    boundsBehavior: Flickable.StopAtBounds

    property int maringsValue: 20
    property int fontSize: 11
    property int textFieldHeight: 25

    clip: true

    enabled: !AppState.instanceDisabled

    Rectangle {
        anchors.fill: parent

        color: ColorStorage.settingsWindowBaseColor

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: maringsValue
            anchors.leftMargin: maringsValue
            anchors.rightMargin: maringsValue

            color: ColorStorage.settingsWindowBaseColor

            SettingsGroupBox {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right

                height: description.height + maringsValue + 3 * (textFieldHeight + maringsValue) + maringsValue
                implicitWidth: parent.width

                title: qsTrId("settings_notifications_email_title") + Translator.translate

                Label {
                    id: description

                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.leftMargin: maringsValue
                    anchors.right: parent.right
                    anchors.rightMargin: maringsValue
                    anchors.topMargin: maringsValue

                    text: qsTrId("settings_notifications_email_description").arg(StringStorage.appTitle) + Translator.translate
                    font.pixelSize: fontSize

                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    anchors.top: description.bottom
                    anchors.left: description.left
                    anchors.right: description.right
                    anchors.bottom: parent.bottom

                    color: "transparent"

                    Component {
                        id: emailComboboxComponent

                        Item {
                            property alias idx: emailTextField.idx
                            property alias address: emailTextField.address

                            width: emailLabel.width + emailTextField.width
                            height: emailTextField.height

                            function updateEditText() {
                                emailTextField.text = address;
                            }

                            Label {
                                id: emailLabel

                                anchors.top: parent.top
                                anchors.left: parent.left

                                font.pixelSize: fontSize
                                text: qsTrId("settings_notifications_email_label") + " " + (parent.idx + 1) + Translator.translate
                            }

                            SettingsTextField {
                                id: emailTextField

                                anchors.left: emailLabel.right
                                anchors.leftMargin: maringsValue
                                anchors.verticalCenter: emailLabel.verticalCenter

                                property int idx
                                property string address

                                implicitWidth: 150
                                font.pixelSize: fontSize

                                onTextChanged: {
                                    ActionProvider.markEmailNotifyUpdate(EmailNotifyAccount.Address,
                                                                         {id: idx, address: text});
                                }
                            }
                        }
                    }

                    Loader {
                        id: emailComboboxLoader1

                        anchors.top: parent.top
                        anchors.topMargin: maringsValue
                        anchors.left: parent.left

                        sourceComponent: flickable.visible ? emailComboboxComponent : null

                        onLoaded: {
                            item.idx = 0;
                            item.address = SettingsState.emailNotifyAccounts[item.idx].address;
                            item.updateEditText();
                        }
                    }

                    Loader {
                        id: emailComboboxLoader2

                        anchors.top: emailComboboxLoader1.bottom
                        anchors.topMargin: maringsValue
                        anchors.left: emailComboboxLoader1.left

                        sourceComponent: flickable.visible ? emailComboboxComponent : null

                        onLoaded: {
                            item.idx = 1;
                            item.address = SettingsState.emailNotifyAccounts[item.idx].address;
                            item.updateEditText();
                        }
                    }

                    Loader {
                        id: emailComboboxLoader3

                        anchors.top: emailComboboxLoader2.bottom
                        anchors.topMargin: maringsValue
                        anchors.left: emailComboboxLoader2.left

                        sourceComponent: flickable.visible ? emailComboboxComponent : null

                        onLoaded: {
                            item.idx = 2;
                            item.address = SettingsState.emailNotifyAccounts[item.idx].address;
                            item.updateEditText();
                        }
                    }
                }
            }
        }
    }
}
