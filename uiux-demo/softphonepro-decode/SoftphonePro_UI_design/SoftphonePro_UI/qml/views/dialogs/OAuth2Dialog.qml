import QtQuick 2.15
import QtQuick.Controls 2.15
import Flux 1.0

import "../uicontrols"

ApplicationWindow {
    id: root

    property var onOKAction: function func() {}
    property var onCancelAction: function func() {}

    flags: {
        return AppFeatures.osType == OSType.Unix ?
                    (Qt.Window | Qt.CustomizeWindowHint | Qt.WindowTitleHint | Qt.WindowStaysOnTopHint)
                  : (Qt.Window | Qt.CustomizeWindowHint | Qt.WindowTitleHint)
    }

    minimumWidth: width
    minimumHeight: height

    maximumWidth: minimumWidth
    maximumHeight: minimumHeight

    modality: Qt.WindowModal

    onVisibleChanged: {
        if (root.visible) {
            root.requestActivate();
        }
    }

    property bool instanceWillDestroy: AppState.instanceWillDestroy

    property alias statusText: authStatus.text
    property alias descriptionText: description.text
    property string authLink: ""

    property alias showBusyIndicator: busyIndicator.visible
    property alias enableOkButton: ok.enabled
    property alias enableCancelButton: cancel.enabled

    property alias codeTextField: authCodeField
    property alias okButtonText: ok.text

    onInstanceWillDestroyChanged: {
        if (instanceWillDestroy) {
            // to fix crashes on exit
            busyIndicator.destroy();

            root.destroy();
        }
    }

    Shortcut {
        enabled: visible
        sequence: "Esc"

        onActivated: {
            root.onCancelAction();
        }
    }

    Rectangle {
        anchors.fill: parent

        color: ColorStorage.settingsWindowBaseColor
        clip: true

        Label {
            id: description

            anchors.top: parent.top
            anchors.topMargin: 15
            anchors.left:  parent.left
            anchors.leftMargin: 20
            anchors.right: parent.right
            anchors.rightMargin: 20

            wrapMode: Text.WordWrap
            font.pixelSize: 11

            onLinkActivated: Qt.openUrlExternally(authLink)

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
        }

        Label {
            id: authCodeLabel

            anchors.top: description.bottom
            anchors.topMargin: 25
            anchors.left: parent.left
            anchors.leftMargin: 20

            text: qsTrId("google_contacts_auth_dialog_auth_code") + Translator.translate
            font.pixelSize: 11
        }

        TextField {
            id: authCodeField

            selectByMouse: true
            selectionColor: ColorStorage.selectionInputColor
            selectedTextColor: ColorStorage.iconsAndTextPrimary
            anchors.verticalCenter: authCodeLabel.verticalCenter
            anchors.left: authCodeLabel.right
            anchors.leftMargin: 20
            anchors.right: parent.right
            anchors.rightMargin: 20
        }

        BusyIndicator {
            id: busyIndicator

            anchors.centerIn: authCodeField

            width: 30
            height: width

            visible: false
            running: visible
        }

        Label {
            id: authStatusLabel

            anchors.top: authCodeLabel.bottom
            anchors.topMargin: 20
            anchors.left: parent.left
            anchors.leftMargin: 20

            text: qsTrId("google_contacts_auth_dialog_auth_status") + Translator.translate
            font.pixelSize: 11
        }

        Label {
            id: authStatus

            anchors.verticalCenter: authStatusLabel.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 20

            font.pixelSize: 11
        }

        SettingsButton {
            id: ok

            anchors.verticalCenter: cancel.verticalCenter
            anchors.right: cancel.left
            anchors.rightMargin: 10

            text: qsTrId("dialog_button_save") + Translator.translate

            onClicked: {
                root.onOKAction();
                if (text == (qsTrId("dialog_button_save") + Translator.translate)) {
                    authCodeField.text = ""
                }
            }
        }

        SettingsButton {
            id: cancel

            anchors.bottom: parent.bottom
            anchors.bottomMargin: 20
            anchors.right: parent.right
            anchors.rightMargin: 20

            text: qsTrId("dialog_button_cancel") + Translator.translate

            onClicked: {
                root.onCancelAction();
            }
        }
    }
}
