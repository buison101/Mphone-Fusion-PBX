import QtQuick 2.15
import QtQuick.Controls 2.15
import Flux 1.0

import "../uicontrols"

Flickable {
    id: flickable

    contentHeight: height

    boundsBehavior: Flickable.StopAtBounds

    clip: true

    enabled: !AppState.instanceDisabled

    Rectangle {
        id: sipAccounts

        anchors.fill: parent

        color: ColorStorage.settingsWindowBaseColor

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 20 * SettingsState.settingsWindowHeightScale
            anchors.leftMargin: 20
            anchors.rightMargin: 20

            color: ColorStorage.settingsWindowBaseColor

            Rectangle {
                id: sipAccountsTable
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                width: parent.width
                height: 600 * SettingsState.settingsWindowHeightScale
                visible: true
                clip: true

                ListView {
                    id: listView
                    anchors.fill: parent
                    clip: true
                    interactive: true

                    contentWidth: headerItem.width

                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.HorizontalAndVerticalFlick

                    ScrollBar.vertical: ScrollBar {}
                    ScrollBar.horizontal: ScrollBar {}

                    header: Row {
                        function itemAt(index) { return repeater.itemAt(index) }
                        Repeater {
                            id: repeater
                            model: [
                                "",
                                qsTrId("sip_accounts_table_name") + Translator.translate,
                                qsTrId("sip_accounts_table_server") + Translator.translate,
                                qsTrId("sip_accounts_table_user") + Translator.translate,
                                qsTrId("sip_accounts_table_reg_on_start") + Translator.translate,
                                qsTrId("sip_accounts_table_status") + Translator.translate
                            ]

                            property var widths: [
                            40,
                            150,
                            130,
                            150,
                            110,
                            152]

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
                                    bottomPadding: 10 * SettingsState.settingsWindowHeightScale
                                    topPadding: 10 * SettingsState.settingsWindowHeightScale
                                    anchors.left: parent.left
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                color: "#E0E0E0"
                            }
                        }
                    }

                    model: SettingsState.allSipAccountsModel
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

                                Repeater {
                                    model: 6
                                    Rectangle {
                                        id: rectangleRow

                                        property int column: index

                                        color: {
                                            if(mouseArea.containsPress) {
                                                return "#E0E0E0"
                                            }
                                            return ColorStorage.white
                                        }

                                        width: listView.headerItem.itemAt(column).width

                                        height: {
                                            if(outputText.enabled) {
                                                textMetrics.height
                                            }
                                            return checkBox.height + 5 * SettingsState.settingsWindowHeightScale
                                        }

                                        SettingsCheckBox {
                                            id: checkBox

                                            leftPadding: 10
                                            enabled: !outputText.enabled

                                            visible: {
                                                if(enabled) {
                                                    rowData.checkBoxElement = checkBox
                                                }
                                                return enabled
                                            }

                                            anchors.centerIn: parent
                                            checked: false

                                            property var allSipAccountsSelectedIndexes: SettingsState.allSipAccountsSelectedIndexes

                                            onAllSipAccountsSelectedIndexesChanged: {
                                                checked = allSipAccountsSelectedIndexes.indexOf(delegate.row) != -1;
                                            }

                                            onCheckedChanged: {
                                                var found = allSipAccountsSelectedIndexes.indexOf(delegate.row) != -1;

                                                if (checked != found) {
                                                    ActionProvider.checkSipAccount(delegate.row, checked);
                                                }
                                            }
                                        }

                                        Text {
                                            id: outputText

                                            enabled: column != 0
                                            visible: enabled

                                            text: {
                                                if(column == 1) {
                                                    return name
                                                }
                                                if(column == 2) {
                                                    return server
                                                }
                                                if(column == 3) {
                                                    return user
                                                }
                                                if(column == 4) {
                                                    return register
                                                }
                                                if(column == 5) {
                                                    return status
                                                }
                                                return ""
                                            }

                                            horizontalAlignment: Text.AlignLeft
                                            verticalAlignment: Text.AlignVCenter

                                            anchors.top: parent.top
                                            anchors.left: parent.left
                                            anchors.bottom: parent.bottom

                                            width: parent.width - 15
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
                id: addSipAccount

                anchors.top: sipAccountsTable.bottom
                anchors.topMargin: 10 * SettingsState.settingsWindowHeightScale
                anchors.left: parent.left

                text: qsTrId("sip_accounts_table_add_account") + Translator.translate

                onClicked: {
                    ActionProvider.tryCreateSipAccount();
                }
            }

            SettingsButton {
                id: removeSipAccount

                anchors.verticalCenter: addSipAccount.verticalCenter
                anchors.left: addSipAccount.right
                anchors.leftMargin: 20

                property var allSipAccountsSelectedIndexes: SettingsState.allSipAccountsSelectedIndexes

                onAllSipAccountsSelectedIndexesChanged: {
                    enabled = allSipAccountsSelectedIndexes.length != 0;
                }

                enabled: allSipAccountsSelectedIndexes.length != 0;

                text: qsTrId("sip_accounts_table_remove_account") + Translator.translate

                onClicked: {
                    ActionProvider.tryRemoveSipAccounts();
                }
            }
        }
    }
}
