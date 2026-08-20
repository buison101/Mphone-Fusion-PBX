import QtQuick 2.15
import QtQuick.Controls 2.15
import Flux 1.0

import "../uicontrols"

Flickable {
    id: root

    boundsBehavior: Flickable.StopAtBounds

    contentHeight: height
    clip: true

    property bool instanceWillDestroy: AppState.instanceWillDestroy
    property int marginValue: 20
    property int fontSize: 11

    onInstanceWillDestroyChanged: {
        if (instanceWillDestroy) {
            // to fix crashes on exit
            busyIndicator.destroy();
        }
    }

    Rectangle {
        id: content

        anchors.fill: parent
        color: ColorStorage.settingsWindowBaseColor

        Rectangle {
            id: border

            anchors.fill: parent
            anchors.topMargin: marginValue
            anchors.leftMargin: marginValue
            anchors.rightMargin: marginValue

            color: ColorStorage.settingsWindowBaseColor

            SettingsGroupBox {
                id: groupBox

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right

                height: keyLabel.height + keyLabel.anchors.topMargin + stateLabel.height + stateLabel.anchors.topMargin
                        + expirationInfoLabel.height + expirationInfoLabel.anchors.topMargin + marginValue

                title: qsTrId("settings_license") + Translator.translate

                Label {
                    id: keyLabel

                    anchors.top: parent.top
                    anchors.topMargin: marginValue
                    anchors.left: parent.left
                    anchors.leftMargin: marginValue

                    text: qsTrId("settings_license_key") + Translator.translate
                    font.pixelSize: fontSize
                }

                SettingsTextField {
                    id: keyField

                    anchors.verticalCenter: keyLabel.verticalCenter
                    anchors.left: keyLabel.right
                    anchors.leftMargin: marginValue

                    implicitWidth: 190

                    enabled: false

                    echoMode: SettingsState.showLicenseKey && SettingsState.displayLicenseKeyOnSettingsWindow
                                                            ? TextInput.Normal : TextInput.Password
                    text: SettingsState.licenseKey
                }

                Label {
                    id: stateLabel

                    anchors.top: keyField.bottom
                    anchors.topMargin: marginValue
                    anchors.left: keyField.left
                    anchors.right: checkButton.right

                    font.pixelSize: fontSize
                    wrapMode: Text.WordWrap

                    text: AppState.licenseInfo ? AppState.licenseInfo.subdescription : ""
                }

                Label {
                    id: expirationInfoLabel

                    anchors.top: stateLabel.bottom
                    anchors.topMargin: marginValue / 2
                    anchors.left: keyField.left
                    anchors.right: checkButton.right

                    font.pixelSize: fontSize
                    wrapMode: Text.WordWrap

                    visible: AppState.licenseInfo && (AppState.licenseInfo.state == License.Valid ||
                                                      AppState.licenseInfo.state == License.ExpireSoon)

                    text: AppState.licenseInfo ? AppState.licenseInfo.expirationInfo : ""
                }

                Button {
                    id: showButton

                    anchors.verticalCenter: keyField.verticalCenter
                    anchors.left: keyField.right
                    anchors.leftMargin: marginValue

                    width: 20
                    height: 20

                    enabled: keyField.text.length > 0 && SettingsState.displayLicenseKeyOnSettingsWindow
                    visible: enabled

                    font.pixelSize: fontSize

                    Image {
                        anchors.centerIn: parent

                        width: 16
                        height: 16

                        sourceSize.width: width
                        sourceSize.height: height

                        source: SettingsState.showLicenseKey ? "qrc:/images/eye_off.svg" : "qrc:/images/eye.svg"
                    }

                    onClicked: {
                        ActionProvider.showLicenseKey(!SettingsState.showLicenseKey);
                    }
                }

                SettingsButton {
                    id: checkButton

                    anchors.verticalCenter: showButton.verticalCenter
                    anchors.left: showButton.visible ? showButton.right : keyField.right
                    anchors.leftMargin: marginValue

                    visible: SettingsState.showSetLicenseButton
                    enabled: visible

                    text: qsTrId("settings_license_set_key") + Translator.translate

                    onClicked: {
                        ActionProvider.setLicenseKey();
                    }
                }

                BusyIndicator {
                    id: busyIndicator

                    anchors.verticalCenter: showButton.verticalCenter
                    anchors.left: showButton.visible ? showButton.right : keyField.right
                    anchors.leftMargin: marginValue

                    width: height
                    height: checkButton.height

                    visible: !checkButton.visible && root.visible
                    running: visible
                }
            }
        }
    }
}
