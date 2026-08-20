import QtQuick 2.15
import QtQuick.Controls 2.15
import Flux 1.0

import "../../uicontrols"

Flickable {
    id: flickable

    contentHeight: height
    boundsBehavior: Flickable.StopAtBounds

    property int fontSize: 11
    property int marginValue: 20

    clip: true

    Rectangle {
        id: integrationCrm

        anchors.fill: parent

        color: ColorStorage.settingsWindowBaseColor

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: marginValue
            anchors.leftMargin: marginValue
            anchors.rightMargin: marginValue

            color: ColorStorage.settingsWindowBaseColor

            SettingsGroupBox {
                id: clipboardGroupbox

                anchors.top: parent.top

                width: parent.width
                height: {
                    var heightValue =  description.height + clipboardCheckbox.height
                            + copyNumberOnAnswerLoader.sourceHeight + (3 * marginValue)

                    return heightValue + marginValue
                }

                title: qsTrId("settings_clipboard") + Translator.translate

                Label {
                    id: description

                    anchors.top: parent.top
                    anchors.topMargin: marginValue
                    anchors.left: parent.left
                    anchors.leftMargin: marginValue
                    anchors.right: parent.right
                    anchors.rightMargin: marginValue

                    wrapMode: Text.WordWrap

                    text: qsTrId("integration_clipboard_description") + Translator.translate
                    font.pixelSize: fontSize
                }

                Row {
                    id: clipboardSettings

                    anchors.top: description.bottom
                    anchors.topMargin: marginValue
                    anchors.left: description.left

                    spacing: marginValue

                    SettingsCheckBox {
                        id: clipboardCheckbox

                        property bool clipboardIntegrationEnable: SettingsState.clipboardIntegrationEnable

                        checked: clipboardIntegrationEnable

                        onCheckedChanged: {
                            if (checked != clipboardIntegrationEnable) {
                                ActionProvider.markAppConfigUpdate(AppConfig.ClipboardIntegration, checked);
                            }
                        }

                        onClipboardIntegrationEnableChanged: {
                            checked = clipboardIntegrationEnable;
                        }
                    }

                    Label {
                        anchors.verticalCenter: clipboardCheckbox.verticalCenter
                        text: qsTrId("settings_clipboard_enable") + Translator.translate
                        font.pixelSize: fontSize
                    }
                }

                Component {
                    id: copyNumberOnAnswerComponent

                    Row {
                        id: copyNumberOnAnswerSettings

                        spacing: marginValue

                        SettingsCheckBox {
                            id: copyNumberOnAnswerCheckbox

                            property bool clipboardIntegrationCopyIncomingNumber: SettingsState.clipboardIntegrationCopyIncomingNumber

                            checked: clipboardIntegrationCopyIncomingNumber

                            onCheckedChanged: {
                                if (checked != clipboardIntegrationCopyIncomingNumber) {
                                    ActionProvider.markAppConfigUpdate(AppConfig.ClipboardCopyNumberOnIncomingAnswer, checked);
                                }
                            }

                            onClipboardIntegrationCopyIncomingNumberChanged: {
                                checked = clipboardIntegrationCopyIncomingNumber;
                            }
                        }

                        Label {
                            anchors.verticalCenter: copyNumberOnAnswerCheckbox.verticalCenter
                            text: qsTrId("settings_clipboard_copy_number_on_incoming_call_answer") + Translator.translate
                            font.pixelSize: fontSize
                        }
                    }
                }

                Loader {
                    id: copyNumberOnAnswerLoader

                    anchors.top: clipboardSettings.bottom
                    anchors.topMargin: marginValue
                    anchors.left: clipboardSettings.left

                    property int sourceWidth: (item !== null && typeof(item)!== 'undefined')? item.width : 0
                    property int sourceHeight: (item !== null && typeof(item)!== 'undefined')? item.height: 0

                    sourceComponent: copyNumberOnAnswerComponent
                }
            }
        }
    }
}

