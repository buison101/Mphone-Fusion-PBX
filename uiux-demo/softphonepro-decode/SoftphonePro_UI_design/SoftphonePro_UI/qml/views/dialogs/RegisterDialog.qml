import QtQuick 2.15
import QtQuick.Controls 2.15
import Flux 1.0

import "../uicontrols"

ApplicationWindow {
    id: root

    property alias message: msg.text
    property alias code: regCode.text
    property alias description: regDescription.text

    property var onCloseAction: function func() {}

    title: StringStorage.appTitle

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

    onInstanceWillDestroyChanged: {
        if (instanceWillDestroy) {
            // to fix crashes on exit
            busyIndicator.destroy();

            root.destroy();
        }
    }

    Shortcut {
        enabled: parent.visible
        sequence: "Esc"

        onActivated: {
            root.onCloseAction();
        }
    }

    Rectangle {
        anchors.fill: parent

        color: ColorStorage.settingsWindowBaseColor
        clip: true

        Label {
            id: title

            anchors.top: parent.top
            anchors.topMargin: 7
            anchors.horizontalCenter: parent.horizontalCenter

            color: "black"

            text: qsTrId("register_dialog_check_connection_status") + Translator.translate
        }

        Label {
            id: msg

            anchors.top: title.bottom
            anchors.topMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter

            wrapMode: Text.WordWrap

            color: "black"
        }

        BusyIndicator {
            id: busyIndicator

            anchors.top: msg.bottom
            anchors.topMargin: 20
            anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined

            running: (SettingsState.registrationStatus == RegistrationStatus.Unregistered) && root.visible
        }

        Row {
            anchors.top: msg.bottom
            anchors.topMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter

            spacing: 10

            Label {
                id: regCode

                wrapMode: Text.WordWrap

                color: "black"
            }

            Label {
                id: regDescription

                wrapMode: Text.WordWrap

                color: "black"
            }
        }

        SettingsButton {
            id: close

            anchors.bottom: parent.bottom
            anchors.bottomMargin: 20
            anchors.horizontalCenter: parent.horizontalCenter

            text: qsTrId("dialog_button_close") + Translator.translate

            onClicked: {
                root.onCloseAction();
            }
        }
    }
}
