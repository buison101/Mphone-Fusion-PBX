import QtQuick 2.15
import QtQuick.Controls 2.15
import Flux 1.0

import "../uicontrols"

Flickable {
    id: flickable

    contentHeight: height
    boundsBehavior: Flickable.StopAtBounds

    property int fontSize: 11
    property int marginValue: 20

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
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right

                implicitWidth: parent.width

                height: description.height + marginValue
                        + numberComboboxLoader1.loaderHeight + marginValue
                        + numberComboboxLoader2.loaderHeight + marginValue
                        + numberComboboxLoader3.loaderHeight + marginValue
                        + waitTimeComponentLoader.loaderHeight + marginValue
                        + marginValue

                title: qsTrId("settings_call_forwarding_title") + Translator.translate

                Label {
                    id: description

                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.leftMargin: marginValue
                    anchors.right: parent.right
                    anchors.rightMargin: marginValue
                    anchors.topMargin: marginValue

                    text: qsTrId("settings_call_forwarding_description").arg(StringStorage.appTitle) + Translator.translate
                    font.pixelSize: fontSize

                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    anchors.top: description.bottom
                    anchors.topMargin: marginValue
                    anchors.left: description.left
                    anchors.right: description.right
                    anchors.bottom: parent.bottom

                    color: "transparent"

                    Component {
                        id: numberComboboxComponent

                        Item {
                            property alias idx: numberTextField.idx
                            property alias number: numberTextField.number
                            property alias text: numberTextField.text

                            width: numberLabel.width + numberTextField.width
                            height: numberTextField.height

                            function updateEditText() {
                                numberTextField.text = number;
                            }

                            Label {
                                id: numberLabel

                                anchors.top: parent.top
                                anchors.left: parent.left

                                font.pixelSize: fontSize
                                text: qsTrId("settings_call_forwarding_label") + " " + (parent.idx + 1) + Translator.translate
                            }

                            SettingsTextField {
                                id: numberTextField

                                anchors.left: numberLabel.right
                                anchors.leftMargin: marginValue
                                anchors.verticalCenter: numberLabel.verticalCenter

                                property int idx
                                property string number

                                implicitWidth: 150

                                onTextChanged: {
                                    ActionProvider.markCallForwardUpdate(CallForwardAccount.Number,
                                                                         {id: idx, number: text});
                                }
                            }
                        }
                    }

                    Loader {
                        id: numberComboboxLoader1

                        anchors.top: parent.top
                        anchors.left: parent.left

                        property int loaderHeight: (item !== null && typeof(item)!== 'undefined')? item.height: 0

                        sourceComponent: flickable.visible ? numberComboboxComponent : null

                        onLoaded: {
                            item.idx = 0;
                            item.number = SettingsState.callForwardAccounts[item.idx].number;
                            item.updateEditText();
                        }
                    }

                    Loader {
                        id: numberComboboxLoader2

                        anchors.top: numberComboboxLoader1.bottom
                        anchors.topMargin: marginValue
                        anchors.left: numberComboboxLoader1.left

                        property int loaderHeight: (item !== null && typeof(item)!== 'undefined')? item.height: 0

                        sourceComponent: flickable.visible ? numberComboboxComponent : null

                        onLoaded: {
                            item.idx = 1;
                            item.number = SettingsState.callForwardAccounts[item.idx].number;
                            item.updateEditText();
                        }
                    }

                    Loader {
                        id: numberComboboxLoader3

                        anchors.top: numberComboboxLoader2.bottom
                        anchors.topMargin: marginValue
                        anchors.left: numberComboboxLoader2.left


                        property int loaderHeight: (item !== null && typeof(item)!== 'undefined')? item.height: 0

                        sourceComponent: flickable.visible ? numberComboboxComponent : null

                        onLoaded: {
                            item.idx = 2;
                            item.number = SettingsState.callForwardAccounts[item.idx].number;
                            item.updateEditText();
                        }
                    }

                    Component {
                        id: waitTimeComponent

                        SettingsGroupBox {
                            height: nowaitTimeoutGroupButton.height + marginValue + waitTimeoutGroupButton.height + marginValue

                            title: qsTrId("settings_call_forwarding_wait_description") + Translator.translate

                            enabled: (numberComboboxLoader1.item && numberComboboxLoader1.item.text.length > 0) ||
                                     (numberComboboxLoader2.item && numberComboboxLoader2.item.text.length > 0) ||
                                     (numberComboboxLoader3.item && numberComboboxLoader3.item.text.length > 0)

                            Column {
                                id: waitTimeoutColumn

                                anchors.left: parent.left
                                anchors.leftMargin: marginValue
                                anchors.top: parent.top
                                anchors.topMargin: marginValue

                                ButtonGroup {
                                    id: waitTimeoutGroup
                                }

                                SettingsRadioButton {
                                    id: nowaitTimeoutGroupButton

                                    text: qsTrId("settings_call_forwarding_no_wait") + Translator.translate
                                    ButtonGroup.group: waitTimeoutGroup


                                    property string timeout: SettingsState.callForwardAccounts[0].waitTimeout
                                    checked: {
                                        return Number(timeout) == 0;
                                    }

                                    onCheckedChanged: {
                                        if (checked) {
                                            ActionProvider.markCallForwardUpdate(CallForwardAccount.WaitTimeoutSec,
                                                                                 {id: 0, timeout: ""});
                                        }
                                    }

                                    font.pixelSize: fontSize
                                }

                                Row {
                                    id: waitTimeoutGroupRow
                                    spacing: marginValue / 4

                                    SettingsRadioButton {
                                        id: waitTimeoutGroupButton

                                        text: qsTrId("settings_call_forwarding_no_wait_seconds") + Translator.translate
                                        ButtonGroup.group: waitTimeoutGroup

                                        checked: !nowaitTimeoutGroupButton.checked

                                        font.pixelSize: fontSize
                                    }

                                    SettingsTextField {
                                        width: 50
                                        enabled: waitTimeoutGroupButton.checked

                                        property string timeout: SettingsState.callForwardAccounts[0].waitTimeout

                                        text: Number(timeout) > 0 ? timeout : ""

                                        onTextChanged: {
                                            if (text != timeout) {
                                                ActionProvider.markCallForwardUpdate(CallForwardAccount.WaitTimeoutSec,
                                                                                     {id: 0, timeout: text});
                                            }
                                        }

                                        validator: RegExpValidator {
                                            regExp: /^[1-9][0-9]*$/
                                        }

                                        anchors.verticalCenter: label.verticalCenter
                                    }

                                    Label {
                                        id: label
                                        anchors.verticalCenter: waitTimeoutGroupButton.verticalCenter

                                        font.pixelSize: fontSize
                                        text: qsTrId("settings_call_forwarding_seconds") + Translator.translate
                                    }
                                }
                            }
                        }
                    }

                    Loader {
                        id: waitTimeComponentLoader
                        anchors.top: numberComboboxLoader3.bottom
                        anchors.topMargin: marginValue
                        anchors.left: numberComboboxLoader3.left
                        anchors.right: parent.right

                        property int loaderHeight: (item !== null && typeof(item)!== 'undefined')? item.height: 0

                        sourceComponent: flickable.visible ? waitTimeComponent : null
                    }
                }
            }
        }
    }
}
