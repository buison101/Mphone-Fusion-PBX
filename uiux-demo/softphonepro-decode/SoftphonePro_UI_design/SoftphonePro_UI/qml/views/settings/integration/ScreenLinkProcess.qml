import QtQuick 2.15
import QtQuick.Controls 2.15
import Flux 1.0

import "../../uicontrols"

Flickable {
    id: flickable

    contentHeight: height
    boundsBehavior: Flickable.StopAtBounds

    clip: true

    property int marginsValue: 20
    property int fontSize: 11

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

                height: linkProcessLabel.height + linkProcessLabel.anchors.topMargin + linkProcessLabelList.height
                        + linkProcessLabelList.anchors.topMargin + linkProcessTable.height + linkProcessTable.anchors.topMargin + marginsValue
                implicitWidth: parent.width

                title: qsTrId("settings_link_process_title") + Translator.translate

                Label {
                    id: linkProcessLabel

                    anchors.top: parent.top
                    anchors.topMargin: marginsValue
                    anchors.left: parent.left
                    anchors.leftMargin: marginsValue
                    anchors.right: parent.right
                    anchors.rightMargin: marginsValue

                    font.pixelSize: fontSize

                    wrapMode: Text.WordWrap

                    text: StringStorage.appTitle + " " + qsTrId("settings_link_process_label") + ":" + Translator.translate
                }

                Label {
                    id: linkProcessLabelList

                    anchors.top: linkProcessLabel.bottom
                    anchors.topMargin: marginsValue
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.rightMargin: marginsValue

                    font.pixelSize: fontSize

                    wrapMode: Text.WordWrap
                    textFormat: Text.RichText

                    text: qsTrId("settings_link_process_label_list").arg(StringStorage.appName).arg(StringStorage.appTitle) + Translator.translate
                }

                Rectangle {
                    id: linkProcessTable

                    anchors.top: linkProcessLabelList.bottom
                    anchors.topMargin: marginsValue
                    anchors.rightMargin: marginsValue
                    anchors.leftMargin: marginsValue
                    anchors.bottomMargin: marginsValue
                    anchors.left: parent.left
                    anchors.right: parent.right

                    height: flickable.height / 2

                    visible: true

                    ScrollView {
                        anchors.fill: linkProcessTable
                        width: linkProcessTable.width
                        height: linkProcessTable.height

                        clip: true

                        ListView {
                            id: listView
                            anchors.fill: parent
                            interactive: true

                            boundsBehavior: Flickable.StopAtBounds

                            flickableDirection: Flickable.HorizontalAndVerticalFlick

                            contentWidth: headerItem.width

                            header: Row {
                                function itemAt(index) { return repeater.itemAt(index) }

                                Repeater {
                                    id: repeater
                                    model: [
                                        "",
                                        qsTrId("link_process_table_name") + Translator.translate,
                                        qsTrId("link_process_table_description") + Translator.translate
                                    ]

                                    property var widths: [40, 310, 330]

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

                            model: SettingsState.linkProcessModel
                            delegate: Column {
                                id: delegate
                                property int row: index

                                MouseArea {
                                    id: mouseArea
                                    width:  childrenRect.width
                                    height: childrenRect.height

                                    Row {
                                        id: rowData
                                        property var checkBoxElement: null
                                        spacing: 0

                                        Repeater {
                                            model: 3
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
                                                    return checkBox.height + 5
                                                }

                                                SettingsCheckBox {
                                                    id: checkBox

                                                    leftPadding: 10
                                                    enabled: false

                                                    visible: {
                                                        if(column == 0) {
                                                            return true
                                                        }
                                                        return false
                                                    }
                                                    anchors.centerIn: parent
                                                    checked: true
                                                    borderColor: ColorStorage.disabledButtonsGrey
                                                    overlayColor: ColorStorage.disabledButtonsGrey

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
                                                            return description
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
                }
            }
        }
    }
}
