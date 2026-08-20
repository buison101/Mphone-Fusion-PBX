import QtQuick 2.15
import QtQuick.Controls 2.15
import Flux 1.0

import "../../uicontrols"

Flickable {
    id: flickable

    contentHeight: height
    boundsBehavior: Flickable.StopAtBounds

    property int marginsValue: 20
    property int fontSize: 11

    clip: true

    enabled: !AppState.instanceDisabled

    Rectangle {
        anchors.fill: parent

        color: ColorStorage.settingsWindowBaseColor

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: marginsValue
            anchors.leftMargin: marginsValue
            anchors.rightMargin: marginsValue

            color: ColorStorage.settingsWindowBaseColor

            SettingsGroupBox {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right

                height: externalSystemsLabel.height + externalSystemsLabel.anchors.topMargin
                        + externalEventReceiverTable.height + externalEventReceiverTable.anchors.topMargin
                        + addHandler.height + addHandler.anchors.topMargin + marginsValue
                implicitWidth: parent.width

                title: qsTrId("settings_external_systems_title") + Translator.translate

                Label {
                    id: externalSystemsLabel

                    anchors.top: parent.top
                    anchors.topMargin: marginsValue
                    anchors.left: parent.left
                    anchors.leftMargin: marginsValue
                    anchors.right: parent.right
                    anchors.rightMargin: marginsValue

                    wrapMode: Text.WordWrap
                    font.pixelSize: fontSize

                    text: StringStorage.appTitle + " " + qsTrId("settings_external_systems_label") + Translator.translate
                }

                Rectangle {
                    id: background
                    anchors.fill: externalEventReceiverTable
                    color: "white"
                    z: 0
                }


                ScrollView {
                    id: externalEventReceiverTable

                    z: 1

                    anchors.top: externalSystemsLabel.bottom
                    anchors.topMargin: marginsValue
                    anchors.left: parent.left
                    anchors.leftMargin: marginsValue
                    anchors.right: parent.right
                    anchors.rightMargin: marginsValue


                    property var allExternalEventReceiversSelectedIndexes: SettingsState.allExternalEventReceiversSelectedIndexes

                    width: parent.width
                    height: flickable.height / 1.3

                    clip: true

                    ListView {
                        id: externalEventReceiverTableView

                        contentWidth: headerItem.width

                        flickableDirection: Flickable.HorizontalAndVerticalFlick

                        boundsBehavior: Flickable.StopAtBounds

                        anchors.fill: parent

                        header: Row {
                            function itemAt(index) { return repeater.itemAt(index) }
                            Repeater {
                                id: repeater
                                model: [
                                    "",
                                    qsTrId("settings_external_systems_table_event") + Translator.translate,
                                    qsTrId("settings_external_systems_table_action") + Translator.translate,
                                    qsTrId("settings_external_systems_table_link") + Translator.translate,
                                ]

                                property var widths: [
                                40,
                                150,
                                150,
                                1500
                                ]

                                Rectangle {
                                    height: label.height
                                    width: {
                                        if(repeater.widths[index] == -1) {
                                            return label.width
                                        }
                                        return repeater.widths[index]
                                    }
                                    Label {
                                        id: label
                                        text: modelData
                                        font.bold: true
                                        font.pixelSize: 11
                                        bottomPadding: 10
                                        topPadding: 10
                                        anchors.left: parent.left
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    color: "#E0E0E0"
                                }
                            }
                        }

                        model: SettingsState.allExternalEventReceiverModel
                        delegate: Column {
                            id: delegate
                            property int row: index

                            MouseArea {
                                id: mouseArea
                                width:  childrenRect.width
                                height: childrenRect.height

                                onClicked: {
                                    rowData.checkBoxElement.toggle()
                                }

                                Row {
                                    id: rowData
                                    property var checkBoxElement: null
                                    spacing: 0

                                    Repeater {
                                        model: 4
                                        Rectangle {
                                            id: rectangleRow
                                            property int column: index

                                            color: {
                                                if(mouseArea.containsPress) {
                                                    return "#E0E0E0"
                                                }
                                                return ColorStorage.white
                                            }

                                            width: externalEventReceiverTableView.headerItem.itemAt(column).width

                                            height: {
                                                if(outputText.enabled) {
                                                    textMetrics.height
                                                }
                                                return checkBox.height + 5
                                            }

                                            SettingsCheckBox {
                                                id: checkBox
                                                enabled: !outputText.enabled

                                                leftPadding: 10

                                                visible: {
                                                    if(enabled) {
                                                        rowData.checkBoxElement = checkBox
                                                    }
                                                    return enabled
                                                }
                                                anchors.centerIn: parent
                                                checked: false

                                                property var allExternalEventReceiversSelectedIndexes: SettingsState.allExternalEventReceiversSelectedIndexes

                                                onAllExternalEventReceiversSelectedIndexesChanged: {
                                                    checked = allExternalEventReceiversSelectedIndexes.indexOf(row) != -1;
                                                }

                                                onCheckedChanged: {
                                                    var found = allExternalEventReceiversSelectedIndexes.indexOf(row) != -1;

                                                    if (checked != found) {
                                                        ActionProvider.checkExternalEventReceiver(row, checked);
                                                    }
                                                }
                                            }

                                            Text {
                                                id: outputText

                                                enabled: column != 0
                                                visible: enabled

                                                text: {
                                                    if(column == 1) {
                                                        return event
                                                    }
                                                    if(column == 2) {
                                                        return action
                                                    }
                                                    if(column == 3) {
                                                        return link
                                                    }
                                                    return ""
                                                }

                                                anchors.fill: parent
                                                horizontalAlignment: Text.AlignLeft
                                                verticalAlignment: Text.AlignVCenter

                                                width: parent.width
                                                elide: Text.ElideRight
                                            }

                                            TextMetrics {
                                                id: textMetrics
                                                font: outputText.font
                                                text: outputText.text
                                            }
                                        }
                                    }
                                }
                            }
                            Rectangle {
                                color: "silver"
                                width: parent.width
                                height: 1
                            }
                        }
                    }
                }

                SettingsButton {
                    id: addHandler

                    anchors.top: externalEventReceiverTable.bottom
                    anchors.topMargin: marginsValue
                    anchors.left: externalEventReceiverTable.left

                    text: qsTrId("settings_external_systems_table_add_link") + Translator.translate

                    onClicked: {
                        ActionProvider.tryAddNewExternalEventReceiver();
                    }
                }

                SettingsButton {
                    id: editHandler

                    anchors.verticalCenter: addHandler.verticalCenter
                    anchors.left: addHandler.right
                    anchors.leftMargin: marginsValue

                    text: qsTrId("settings_external_systems_table_edit_link") + Translator.translate

                    property var allExternalEventReceiversSelectedIndexes: SettingsState.allExternalEventReceiversSelectedIndexes

                    onAllExternalEventReceiversSelectedIndexesChanged: {
                        enabled = allExternalEventReceiversSelectedIndexes.length == 1;
                    }

                    enabled: allExternalEventReceiversSelectedIndexes.length != 1;

                    onClicked: {
                        ActionProvider.editExternalEventReceiver(allExternalEventReceiversSelectedIndexes[0]);
                    }
                }

                SettingsButton {
                    id: removeHandler

                    anchors.verticalCenter: editHandler.verticalCenter
                    anchors.left: editHandler.right
                    anchors.leftMargin: marginsValue

                    property var allExternalEventReceiversSelectedIndexes: SettingsState.allExternalEventReceiversSelectedIndexes

                    onAllExternalEventReceiversSelectedIndexesChanged: {
                        enabled = allExternalEventReceiversSelectedIndexes.length != 0;
                    }

                    enabled: allExternalEventReceiversSelectedIndexes.length != 0;

                    text: qsTrId("settings_external_systems_table_remove_link") + Translator.translate

                    onClicked: {
                        ActionProvider.tryRemoveExternalEventReceivers();
                    }
                }
            }
        }
    }
}
