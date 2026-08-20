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
            anchors.fill: parent
            anchors.topMargin: marginValue
            anchors.leftMargin: marginValue
            anchors.rightMargin: marginValue

            color: ColorStorage.settingsWindowBaseColor

            SettingsGroupBox {
                id: excelAddinGroupbox

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right

                implicitWidth: parent.width
                height: description.height + marginValue
                        + descriptionList.height + marginValue
                        + descriptionSupport.height + marginValue
                        + downloadSettings.height + marginValue

                title: qsTrId("settings_excel_addin") + Translator.translate;

                Label {
                    id: description

                    anchors.top: parent.top
                    anchors.topMargin: marginValue
                    anchors.left: parent.left
                    anchors.leftMargin: marginValue
                    anchors.right: parent.right
                    anchors.rightMargin: marginValue

                    font.pixelSize: fontSize

                    wrapMode: Text.WordWrap

                    text: qsTrId("settings_excel_addin_description").arg(StringStorage.appTitle) + Translator.translate
                }

                Label {
                    id: descriptionList

                    anchors.top: description.bottom
                    anchors.topMargin: marginValue / 2
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.rightMargin: marginValue

                    font.pixelSize: fontSize

                    wrapMode: Text.WordWrap
                    textFormat: Text.RichText

                    text: qsTrId("settings_excel_addin_list").arg(StringStorage.appTitle) + Translator.translate
                }


                Label {
                    id: descriptionSupport

                    anchors.top: descriptionList.bottom
                    anchors.topMargin: marginValue / 2
                    anchors.left: parent.left
                    anchors.leftMargin: marginValue
                    anchors.right: parent.right
                    anchors.rightMargin: marginValue

                    wrapMode: Text.WordWrap

                    text: qsTrId("settings_excel_addin_support") + Translator.translate
                    font.pixelSize: fontSize
                }

                Row {
                    id: downloadSettings

                    anchors.top: descriptionSupport.bottom
                    anchors.topMargin: marginValue
                    anchors.left: description.left

                    spacing: marginValue

                    SettingsButton {
                        id: downloadButton

                        text: qsTrId("settings_excel_addin_download_button") + Translator.translate

                        onClicked: {
                            Qt.openUrlExternally(StringStorage.softphoneProExcelDownloadURL);
                        }
                    }
                }
            }
        }
    }
}

