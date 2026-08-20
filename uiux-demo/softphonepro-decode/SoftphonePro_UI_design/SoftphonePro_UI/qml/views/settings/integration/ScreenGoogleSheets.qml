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
        id: integrationExcelAddin

        anchors.fill: parent

        color: ColorStorage.settingsWindowBaseColor

        Rectangle {
            anchors {
                fill: parent
                topMargin: marginValue
                leftMargin: marginValue
                rightMargin: marginValue
            }

            color: ColorStorage.settingsWindowBaseColor

            SettingsGroupBox {
                id: excelAddinGroupbox

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }

                implicitWidth: parent.width
                height: description.height + marginValue
                        + descriptionList.height + marginValue / 2
                        + downloadSettings.height + marginValue + marginValue

                title: qsTrId("settings_googlesheets") + Translator.translate;

                Label {
                    id: description

                    anchors {
                        top: parent.top
                        topMargin: marginValue
                        left: parent.left
                        leftMargin: marginValue
                        right: parent.right
                        rightMargin: marginValue
                    }

                    font.pixelSize: fontSize

                    wrapMode: Text.WordWrap

                    text: qsTrId("settings_googlesheets_description").arg(StringStorage.appTitle) + Translator.translate
                }

                Label {
                    id: descriptionList

                    anchors {
                        top: description.bottom
                        topMargin: marginValue / 2
                        left: parent.left
                        right: parent.right
                        rightMargin: marginValue
                    }

                    font.pixelSize: fontSize

                    wrapMode: Text.WordWrap
                    textFormat: Text.RichText

                    text: qsTrId("settings_googlesheets_list") + Translator.translate
                }

                Row {
                    id: downloadSettings

                    anchors {
                        top: descriptionList.bottom
                        topMargin: marginValue
                        left: description.left
                    }

                    spacing: marginValue

                    SettingsButton {
                        id: downloadButton

                        text: qsTrId("settings_googlesheets_download_button") + Translator.translate

                        onClicked: {
                            Qt.openUrlExternally(StringStorage.googleSoftphoneProExtensionURL);
                        }
                    }
                }
            }
        }
    }
}

